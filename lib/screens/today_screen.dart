import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;

import '../app/app_preferences.dart';
import '../data/database/app_database.dart';
import '../data/providers/database_providers.dart';
import '../data/services/daily_planner.dart';
import '../data/services/review_completion_service.dart';
import '../data/services/solo_setup_flow.dart';
import '../data/services/scheduling/weekly_plan_generator.dart';
import '../data/time/local_day_time.dart';
import '../l10n/app_strings.dart';
import 'today_path.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _isLoading = true;
  bool _isSeedingDebugUnit = false;
  bool _isRunningGuidedSetup = false;
  bool _allowStage4NewOverride = false;
  bool _zeroUnitFirstRunMode = false;
  String? _errorMessage;
  TodayPlan? _plan;
  double? _guidedSetupProgressFraction;
  GuidedSetupStepKind? _guidedSetupStep;
  String? _guidedSetupCompanionRoute;
  List<Stage4DueItem> _remainingStage4Due = const <Stage4DueItem>[];
  List<PlannedReviewRow> _remainingReviews = const <PlannedReviewRow>[];
  List<MemUnitData> _remainingNewUnits = const <MemUnitData>[];
  final Set<int> _busyUnitIds = <int>{};

  @override
  void initState() {
    super.initState();
    _loadTodayPlan();
  }

  Future<void> _loadTodayPlan() async {
    final strings = AppStrings.of(ref.read(appPreferencesProvider).language);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final todayDay = localDayIndex(DateTime.now().toLocal());

    try {
      final setupReadiness = await ref
          .read(guidedSetupFlowServiceProvider)
          .load(todayDayOverride: todayDay);
      final planner = ref.read(dailyPlannerProvider);
      final plan = await planner.planToday(
        todayDay: todayDay,
        allowStage4Override: _allowStage4NewOverride,
        materializeNewUnits: setupReadiness.hasAnyMemUnits,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _plan = plan;
        _remainingStage4Due = List<Stage4DueItem>.from(plan.plannedStage4Due);
        _remainingReviews = List<PlannedReviewRow>.from(plan.plannedReviews);
        _remainingNewUnits = List<MemUnitData>.from(plan.plannedNewUnits);
        _zeroUnitFirstRunMode = !setupReadiness.hasAnyMemUnits;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = strings.failedToLoadTodayPlan;
      });
    }
  }

  Future<bool> _confirmStage4Override(AppStrings strings) async {
    final decision = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.stage4OverrideDialogTitle),
          content: Text(strings.stage4OverrideDialogMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              key: const ValueKey('today_stage4_override_confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.stage4OverrideDialogConfirm),
            ),
          ],
        );
      },
    );
    return decision == true;
  }

  Future<void> _handleStage4Override() async {
    final strings = AppStrings.of(ref.read(appPreferencesProvider).language);
    final confirmed = await _confirmStage4Override(strings);
    if (!confirmed) {
      return;
    }

    final now = DateTime.now().toLocal();
    final todayDay = localDayIndex(now);
    final seconds = nowLocalSecondsSinceMidnight(now);
    final companionRepo = ref.read(companionRepoProvider);

    try {
      final mandatoryUnitIds = _remainingStage4Due
          .where((item) => item.mandatory)
          .map((item) => item.unit.id)
          .toSet();
      for (final unitId in mandatoryUnitIds) {
        await companionRepo.recordNewOverride(
          unitId: unitId,
          todayDay: todayDay,
          updatedAtSeconds: seconds,
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _allowStage4NewOverride = true;
      });
      await _loadTodayPlan();
      if (!mounted) {
        return;
      }
      _showSnackBar(strings.stage4OverrideApplied);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnackBar(strings.stage4OverrideFailed);
    }
  }

  Future<void> _submitGrade({
    required int unitId,
    required int gradeQ,
    required VoidCallback onSuccessRemove,
  }) async {
    final strings = AppStrings.of(ref.read(appPreferencesProvider).language);

    if (_busyUnitIds.contains(unitId)) {
      return;
    }

    setState(() {
      _busyUnitIds.add(unitId);
    });

    final nowLocal = DateTime.now().toLocal();
    final tsDay = localDayIndex(nowLocal);
    final tsSeconds = nowLocalSecondsSinceMidnight(nowLocal);

    try {
      final result = await ref
          .read(reviewCompletionServiceProvider)
          .completeScheduledReview(
            unitId: unitId,
            gradeQ: gradeQ,
            completedDay: tsDay,
            completedSeconds: tsSeconds,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        onSuccessRemove();
        _busyUnitIds.remove(unitId);
      });
      _showSnackBar(_reviewCompletionMessage(strings, result));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyUnitIds.remove(unitId);
      });
      _showSnackBar(strings.failedToSaveGrade);
    }
  }

  bool _canOpenInReader(MemUnitData unit) {
    return unit.pageMadina != null &&
        unit.startSurah != null &&
        unit.startAyah != null &&
        unit.endSurah != null &&
        unit.endAyah != null;
  }

  String _buildReaderRoute(MemUnitData unit) {
    final uri = Uri(
      path: '/reader',
      queryParameters: {
        'mode': 'page',
        'page': unit.pageMadina!.toString(),
        'targetSurah': unit.startSurah!.toString(),
        'targetAyah': unit.startAyah!.toString(),
        'highlightStartSurah': unit.startSurah!.toString(),
        'highlightStartAyah': unit.startAyah!.toString(),
        'highlightEndSurah': unit.endSurah!.toString(),
        'highlightEndAyah': unit.endAyah!.toString(),
      },
    );
    return uri.toString();
  }

  String _buildReviewRoute(int unitId) {
    return '/companion/chain?unitId=$unitId&mode=review';
  }

  String _buildNewRoute(int unitId) {
    return '/companion/chain?unitId=$unitId&mode=new';
  }

  String _formatUnitHeader(MemUnitData unit, AppStrings strings) {
    final parts = <String>[unit.kind];
    if (unit.pageMadina != null) {
      parts.add(strings.pageLabel(unit.pageMadina!));
    }
    return parts.join(' • ');
  }

  String _formatRange(MemUnitData unit, AppStrings strings) {
    final startSurah = unit.startSurah;
    final startAyah = unit.startAyah;
    final endSurah = unit.endSurah;
    final endAyah = unit.endAyah;

    if (startSurah == null ||
        startAyah == null ||
        endSurah == null ||
        endAyah == null) {
      return strings.rangeUnavailable;
    }
    return '$startSurah:$startAyah - $endSurah:$endAyah';
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _runGuidedSetup() async {
    if (_isRunningGuidedSetup || _isSeedingDebugUnit) {
      return;
    }

    final strings = AppStrings.of(ref.read(appPreferencesProvider).language);
    setState(() {
      _isRunningGuidedSetup = true;
      _guidedSetupCompanionRoute = null;
      _guidedSetupProgressFraction = null;
      _guidedSetupStep = null;
    });

    try {
      final outcome = await ref.read(guidedSetupFlowServiceProvider).run(
            onProgress: (progress) {
              if (!mounted) {
                return;
              }
              setState(() {
                _guidedSetupStep = progress.step;
                _guidedSetupProgressFraction = progress.fraction;
              });
            },
          );

      ref.invalidate(quranDataReadinessProvider);
      ref.invalidate(soloSetupReadinessProvider);
      final keepFocusedHandoff =
          _zeroUnitFirstRunMode && outcome.companionRoute != null;
      if (!keepFocusedHandoff) {
        await _loadTodayPlan();
      }

      if (!mounted) {
        return;
      }

      final message = outcome.companionRoute != null
          ? strings.guidedSetupStarterUnitReady
          : outcome.readiness.needsGuidedSetup
              ? strings.guidedSetupNeedsAttention
              : strings.guidedSetupComplete;
      setState(() {
        _guidedSetupCompanionRoute = outcome.companionRoute;
        _guidedSetupStep = GuidedSetupStepKind.complete;
        _guidedSetupProgressFraction = 1;
        if (keepFocusedHandoff) {
          _zeroUnitFirstRunMode = true;
        } else {
          _zeroUnitFirstRunMode = !outcome.readiness.hasAnyMemUnits;
        }
      });
      _showSnackBar(message);
    } catch (_) {
      if (mounted) {
        _showSnackBar(strings.guidedSetupFailed);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRunningGuidedSetup = false;
        });
      }
    }
  }

  String _guidedSetupStepLabel(
    AppStrings strings,
    GuidedSetupProgress progress,
  ) {
    return switch (progress.step) {
      GuidedSetupStepKind.importText => strings.guidedSetupStepImportText(
          progress.processed,
          progress.total,
        ),
      GuidedSetupStepKind.importPageMetadata =>
        strings.guidedSetupStepImportPageMetadata(
          progress.processed,
          progress.total,
        ),
      GuidedSetupStepKind.saveStarterPlan => strings.guidedSetupStepSaveStarterPlan,
      GuidedSetupStepKind.createStarterUnit =>
        strings.guidedSetupStepCreateStarterUnit,
      GuidedSetupStepKind.complete => strings.guidedSetupStepComplete,
    };
  }

  String _guidedSetupSummary(
    AppStrings strings,
    SoloSetupReadiness readiness,
  ) {
    return strings.guidedSetupMissingSummary(
      needsTextImport: readiness.quranData.needsTextImport,
      needsPageMetadataImport: readiness.quranData.needsPageMetadataImport,
      needsStarterPlan: readiness.needsStarterPlanRepair,
      needsStarterUnit: !readiness.hasAnyMemUnits,
    );
  }

  String? _planNoticeText(AppStrings strings, TodayPlan plan) {
    return switch (plan.notice) {
      TodayPlanNotice.noStudySessions => strings.todayPlanNoticeNoStudySessions,
      TodayPlanNotice.holiday => strings.todayPlanNoticeHoliday,
      TodayPlanNotice.finishSetup => strings.todayPlanNoticeFinishSetup,
      null => null,
    };
  }

  Widget _buildStorageWarningCard(
    AppStrings strings,
    AsyncValue<dynamic> storageStatus,
  ) {
    return storageStatus.when(
      data: (value) {
        final warning = strings.storageStatusWarning(value);
        if (warning == null || value.isPersistent || !value.isWeb) {
          return const SizedBox.shrink();
        }
        return Card(
          key: const ValueKey('today_storage_warning'),
          child: Semantics(
            container: true,
            label: strings.todayStorageWarningSemanticsLabel,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.todayStorageWarningTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(warning),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _buildGuidedSetupCard(
    AppStrings strings,
    AsyncValue<SoloSetupReadiness> readiness,
  ) {
    return readiness.when(
      data: (value) {
        if (!value.needsGuidedSetup && _guidedSetupCompanionRoute == null) {
          return const SizedBox.shrink();
        }
        return Card(
          key: const ValueKey('today_guided_setup_card'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.guidedSetupTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _guidedSetupCompanionRoute != null
                      ? strings.guidedSetupStarterUnitReady
                      : _guidedSetupSummary(strings, value),
                  key: const ValueKey('today_guided_setup_message'),
                ),
                if (_isRunningGuidedSetup ||
                    _guidedSetupProgressFraction != null) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _guidedSetupProgressFraction,
                  ),
                ],
                if (_guidedSetupStep != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _guidedSetupStepLabel(
                      strings,
                      GuidedSetupProgress(
                        step: _guidedSetupStep!,
                        processed: ((_guidedSetupProgressFraction ?? 0) * 100)
                            .round(),
                        total: _guidedSetupProgressFraction == null ? 0 : 100,
                      ),
                    ),
                    key: const ValueKey('today_guided_setup_status'),
                  ),
                ],
                const SizedBox(height: 12),
                if (_guidedSetupCompanionRoute != null)
                  FilledButton.icon(
                    key: const ValueKey('today_open_companion_after_setup'),
                    onPressed: () {
                      context.go(_guidedSetupCompanionRoute!);
                    },
                    icon: const Icon(Icons.play_circle_outline),
                    label: Text(strings.guidedSetupOpenCompanionAction),
                  )
                else
                  FilledButton.icon(
                    key: const ValueKey('today_guided_setup_button'),
                    onPressed: (_isRunningGuidedSetup || _isSeedingDebugUnit)
                        ? null
                        : _runGuidedSetup,
                    icon: const Icon(Icons.auto_fix_high_outlined),
                    label: Text(strings.guidedSetupAction),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => Card(
        key: const ValueKey('today_guided_setup_card'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(strings.guidedSetupInProgress),
        ),
      ),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  String _reviewCompletionMessage(
    AppStrings strings,
    ReviewCompletionResult result,
  ) {
    final lifecycleMessage = _reviewLifecycleMessage(strings, result);
    if (lifecycleMessage == null) {
      return strings.gradeSaved;
    }
    return '${strings.gradeSaved} $lifecycleMessage';
  }

  String? _reviewLifecycleMessage(
    AppStrings strings,
    ReviewCompletionResult result,
  ) {
    return switch (result.lifecycleTransition) {
      ReviewLifecycleTransition.promotedToMaintained =>
        strings.reviewLifecyclePromotedToMaintained,
      ReviewLifecycleTransition.demotedToStable =>
        strings.reviewLifecycleDemotedToStable,
      ReviewLifecycleTransition.demotedToReady =>
        strings.reviewLifecycleDemotedToReady,
      ReviewLifecycleTransition.unchanged => null,
    };
  }

  Widget _buildLifecycleBadge({
    required int unitId,
    required String lifecycleTier,
    required AppStrings strings,
  }) {
    return DecoratedBox(
      key: ValueKey('today_review_lifecycle_badge_$unitId'),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          strings.lifecycleTierLabel(lifecycleTier),
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }

  Widget _buildGradeButtons({
    required AppStrings strings,
    required int unitId,
    required bool busy,
    required String keyPrefix,
    required ValueChanged<int> onGrade,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in _gradeOptions(strings))
          OutlinedButton(
            key: ValueKey('${keyPrefix}_${unitId}_q${option.q}'),
            onPressed: busy ? null : () => onGrade(option.q),
            child: Text(option.label),
          ),
      ],
    );
  }

  String _pathModeLabel(AppStrings strings, TodayPathMode mode) {
    return switch (mode) {
      TodayPathMode.green => strings.todayPathModeGreen,
      TodayPathMode.protect => strings.todayPathModeProtect,
      TodayPathMode.recovery => strings.todayPathModeRecovery,
    };
  }

  String _pathModeBody(AppStrings strings, TodayPathMode mode) {
    return switch (mode) {
      TodayPathMode.green => strings.todayPathModeGreenBody,
      TodayPathMode.protect => strings.todayPathModeProtectBody,
      TodayPathMode.recovery => strings.todayPathModeRecoveryBody,
    };
  }

  String _newStateMessage(AppStrings strings, TodayNewState state) {
    return switch (state) {
      TodayNewState.unlocked => strings.todayNewUnlockedMessage,
      TodayNewState.lockedStage4 => strings.todayNewLockedStage4Message,
      TodayNewState.lockedReviewHealth =>
        strings.todayNewLockedReviewHealthMessage,
      TodayNewState.lockedSetup => strings.todayNewLockedSetupMessage,
      TodayNewState.noneAvailable => strings.todayNewNoneAvailableMessage,
    };
  }

  String _nextStepLabel(AppStrings strings, TodayPath path) {
    final nextStep = path.nextStep;
    return switch (nextStep.kind) {
      TodayNextStepKind.stage4Due => strings.stage4DueSectionTitle,
      TodayNextStepKind.dueReview => path.isWarmUpReview(nextStep.reviewRow)
          ? strings.warmUpSectionTitle
          : strings.dueReviewSectionTitle,
      TodayNextStepKind.weakSpot => strings.weakSpotsSectionTitle,
      TodayNextStepKind.newUnit => strings.optionalNewSectionTitle,
      TodayNextStepKind.resume => strings.myQuranResumeTitle,
    };
  }

  String _nextStepRoute(TodayPath path) {
    final nextStep = path.nextStep;
    return switch (nextStep.kind) {
      TodayNextStepKind.stage4Due => _stage4RouteForItem(nextStep.stage4Item!),
      TodayNextStepKind.dueReview =>
        _buildReviewRoute(nextStep.reviewRow!.unit.id),
      TodayNextStepKind.weakSpot =>
        _buildReviewRoute(nextStep.reviewRow!.unit.id),
      TodayNextStepKind.newUnit => _buildNewRoute(nextStep.newUnit!.id),
      TodayNextStepKind.resume => '/my-quran',
    };
  }

  String _nextStepActionLabel(AppStrings strings, TodayPath path) {
    return switch (path.nextStep.kind) {
      TodayNextStepKind.stage4Due => strings.stage4OpenAction,
      TodayNextStepKind.resume => strings.resume,
      _ => strings.openCompanionChain,
    };
  }

  Widget _buildNextStepCard(AppStrings strings, TodayPath path) {
    final nextStep = path.nextStep;

    return Card(
      key: const ValueKey('today_next_step_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.todayNextStepTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              _nextStepLabel(strings, path),
              key: const ValueKey('today_next_step_label'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (nextStep.stage4Item != null) ...[
              Text(
                _formatUnitHeader(nextStep.stage4Item!.unit, strings),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(_formatRange(nextStep.stage4Item!.unit, strings)),
              const SizedBox(height: 4),
              Text(
                strings.stage4DueItemSummary(
                  _stage4DueKindLabel(nextStep.stage4Item!.dueKind, strings),
                  nextStep.stage4Item!.overdueDays,
                  nextStep.stage4Item!.unresolvedTargetsCount,
                ),
              ),
              const SizedBox(height: 12),
            ] else if (nextStep.reviewRow != null) ...[
              Text(
                _formatUnitHeader(nextStep.reviewRow!.unit, strings),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(_formatRange(nextStep.reviewRow!.unit, strings)),
              const SizedBox(height: 12),
            ] else if (nextStep.newUnit != null) ...[
              Text(
                _formatUnitHeader(nextStep.newUnit!, strings),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(_formatRange(nextStep.newUnit!, strings)),
              const SizedBox(height: 12),
            ] else ...[
              Text(strings.todayNextStepResumeBody),
              const SizedBox(height: 12),
            ],
            FilledButton(
              key: ValueKey('today_next_step_button_${nextStep.kind.name}'),
              onPressed: () {
                context.go(_nextStepRoute(path));
              },
              child: Text(_nextStepActionLabel(strings, path)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathModeCard(
    AppStrings strings,
    TodayPlan plan,
    TodayPath path,
  ) {
    final isLocked = !path.newUnlocked;

    return Card(
      key: const ValueKey('today_path_mode_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.todayPathModeTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              key: const ValueKey('today_path_mode_value'),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  _pathModeLabel(strings, path.mode),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(_pathModeBody(strings, path.mode)),
            const SizedBox(height: 8),
            Text(
              strings.todayPathLength(
                (plan.minutesPlannedReviews + plan.minutesPlannedNew)
                    .toStringAsFixed(1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _newStateMessage(strings, path.newState),
              key: const ValueKey('today_new_state_message'),
              style: TextStyle(
                color: isLocked
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSection(AppStrings strings, TodayPath path) {
    final hasReviews = path.warmUp != null ||
        path.dueReviews.isNotEmpty ||
        path.weakSpots.isNotEmpty;

    return Card(
      key: const ValueKey('today_reviews_section'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.todayReviewQueueTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (!hasReviews)
              Text(strings.noPlannedReviewsLeft)
            else ...[
              if (path.warmUp != null)
                _buildReviewSubsection(
                  strings: strings,
                  keyName: 'today_warmup_section',
                  title: strings.warmUpSectionTitle,
                  rows: <PlannedReviewRow>[path.warmUp!],
                ),
              if (path.dueReviews.isNotEmpty) ...[
                if (path.warmUp != null) const SizedBox(height: 16),
                _buildReviewSubsection(
                  strings: strings,
                  keyName: 'today_due_review_section',
                  title: strings.dueReviewSectionTitle,
                  rows: path.dueReviews,
                ),
              ],
              if (path.weakSpots.isNotEmpty) ...[
                if (path.warmUp != null || path.dueReviews.isNotEmpty)
                  const SizedBox(height: 16),
                _buildReviewSubsection(
                  strings: strings,
                  keyName: 'today_weak_spots_section',
                  title: strings.weakSpotsSectionTitle,
                  rows: path.weakSpots,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSubsection({
    required AppStrings strings,
    required String keyName,
    required String title,
    required List<PlannedReviewRow> rows,
  }) {
    return Column(
      key: ValueKey(keyName),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == rows.length - 1 ? 0 : 12),
            child: _buildReviewRow(rows[i], strings),
          ),
      ],
    );
  }

  String _stage4DueKindLabel(String dueKind, AppStrings strings) {
    return switch (dueKind) {
      'next_day_required' => strings.stage4DueKindNextDayRequired,
      'retry_required' => strings.stage4DueKindRetryRequired,
      'pre_sleep_optional' => strings.stage4DueKindPreSleepOptional,
      _ => strings.stage4DueKindNextDayRequired,
    };
  }

  String _stage4RouteForItem(Stage4DueItem item) {
    final needsStrengthening = item.lifecycle.stage4Status == 'failed' ||
        item.lifecycle.stage4Status == 'needs_reinforcement' ||
        item.lifecycle.stage4StrengtheningRoute != null;
    if (needsStrengthening) {
      return '/companion/chain?unitId=${item.unit.id}&mode=new';
    }
    return '/companion/chain?unitId=${item.unit.id}&mode=stage4';
  }

  Widget _buildStage4DueSection(AppStrings strings) {
    final plan = _plan;
    if (plan == null) {
      return const SizedBox.shrink();
    }

    return Card(
      key: const ValueKey('today_stage4_section'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.stage4DueSectionTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              strings.stage4TierSummary(
                plan.stage4QualitySnapshot.emergingCount,
                plan.stage4QualitySnapshot.readyCount,
                plan.stage4QualitySnapshot.stableCount,
                plan.stage4QualitySnapshot.maintainedCount,
              ),
            ),
            if (plan.showStage4CatchUpMessage) ...[
              const SizedBox(height: 8),
              Text(
                strings.todayStage4CatchUpMessage,
                key: const ValueKey('today_stage4_catchup_message'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            if (plan.stage4BlocksNewByDefault) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                key: const ValueKey('today_stage4_override_new_button'),
                onPressed: _handleStage4Override,
                child: Text(strings.stage4OverrideNewAction),
              ),
            ],
            const SizedBox(height: 10),
            if (_remainingStage4Due.isEmpty)
              Text(strings.stage4NoDueItems)
            else
              Column(
                children: [
                  for (final item in _remainingStage4Due) ...[
                    DecoratedBox(
                      key: ValueKey('today_stage4_row_${item.unit.id}'),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatUnitHeader(item.unit, strings),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(_formatRange(item.unit, strings)),
                            const SizedBox(height: 4),
                            Text(
                              strings.stage4DueItemSummary(
                                _stage4DueKindLabel(item.dueKind, strings),
                                item.overdueDays,
                                item.unresolvedTargetsCount,
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              key: ValueKey(
                                'today_open_companion_stage4_${item.unit.id}',
                              ),
                              onPressed: () {
                                context.go(_stage4RouteForItem(item));
                              },
                              child: Text(strings.stage4OpenAction),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewRow(PlannedReviewRow reviewRow, AppStrings strings) {
    final unit = reviewRow.unit;
    final unitId = unit.id;
    final busy = _busyUnitIds.contains(unitId);

    return DecoratedBox(
      key: ValueKey('today_review_row_$unitId'),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatUnitHeader(unit, strings),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(_formatRange(unit, strings)),
            const SizedBox(height: 4),
            _buildLifecycleBadge(
              unitId: unitId,
              lifecycleTier: reviewRow.lifecycleTier,
              strings: strings,
            ),
            const SizedBox(height: 6),
            Text(strings.dueDayLabel(reviewRow.schedule.dueDay)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: ValueKey('today_open_companion_review_$unitId'),
                  onPressed: () {
                    context.go(_buildReviewRoute(unitId));
                  },
                  child: Text(strings.openCompanionChain),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildGradeButtons(
              strings: strings,
              unitId: unitId,
              busy: busy,
              keyPrefix: 'today_review_grade',
              onGrade: (gradeQ) {
                _submitGrade(
                  unitId: unitId,
                  gradeQ: gradeQ,
                  onSuccessRemove: () {
                    _remainingReviews.removeWhere(
                      (row) => row.unit.id == unitId,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewMemorizationSection(AppStrings strings, TodayPath path) {
    return Card(
      key: const ValueKey('today_new_section'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.optionalNewSectionTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const ValueKey('today_debug_seed_new_unit'),
                onPressed: _isSeedingDebugUnit ? null : _seedDebugNewUnit,
                icon: const Icon(Icons.bug_report_outlined),
                label: Text(
                  _isSeedingDebugUnit
                      ? 'Debug: Generating...'
                      : 'Debug: Generate test new unit',
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (path.optionalNew.isEmpty)
              Text(_newStateMessage(strings, path.newState))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.todayNewUnlockedMessage),
                  const SizedBox(height: 12),
                  for (final unit in path.optionalNew) ...[
                    _buildNewUnitRow(unit, strings),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedDebugNewUnit() async {
    if (_isSeedingDebugUnit) {
      return;
    }

    // Debug-only seeding helper. Release-visible first-run onboarding is owned
    // by the guided setup flow above, not by this shortcut.
    setState(() {
      _isSeedingDebugUnit = true;
    });

    final now = DateTime.now().toLocal();
    final todayDay = localDayIndex(now);

    try {
      final db = ref.read(appDatabaseProvider);
      final quranRepo = ref.read(quranRepoProvider);
      final memUnitRepo = ref.read(memUnitRepoProvider);
      final scheduleRepo = ref.read(scheduleRepoProvider);
      final progressRepo = ref.read(progressRepoProvider);

      final cursor = await progressRepo.getCursor();
      final ayahWindow = await quranRepo.getAyahsFromCursor(
        startSurah: cursor.nextSurah,
        startAyah: cursor.nextAyah,
        limit: 8,
      );

      if (ayahWindow.isEmpty) {
        _showSnackBar('Debug: No ayahs available from current cursor.');
        return;
      }

      final anchor = ayahWindow.first;
      final unitAyahs = _takeDebugUnitAyahs(ayahWindow, anchor.pageMadina);
      final start = unitAyahs.first;
      final end = unitAyahs.last;
      final page = anchor.pageMadina;
      final unitKey = 'debug_seed:p${page ?? 0}:s${start.surah}a${start.ayah}'
          '-s${end.surah}a${end.ayah}:${now.millisecondsSinceEpoch}';

      MemUnitData? seededUnit;

      await db.transaction(() async {
        final unitId = await memUnitRepo.create(
          MemUnitCompanion.insert(
            kind: 'page_segment',
            pageMadina: page == null ? const Value.absent() : Value(page),
            startSurah: Value(start.surah),
            startAyah: Value(start.ayah),
            endSurah: Value(end.surah),
            endAyah: Value(end.ayah),
            unitKey: unitKey,
            createdAtDay: todayDay,
            updatedAtDay: todayDay,
          ),
        );

        await scheduleRepo.upsertInitialStateForNewUnit(
          unitId: unitId,
          dueDay: todayDay,
          ef: 2.5,
          reps: 0,
          intervalDays: 0,
        );
        seededUnit = await memUnitRepo.get(unitId);

        final nextAyah = await quranRepo.getAyahsFromCursor(
          startSurah: end.surah,
          startAyah: end.ayah + 1,
          limit: 1,
        );
        if (nextAyah.isNotEmpty) {
          await progressRepo.updateCursor(
            nextSurah: nextAyah.first.surah,
            nextAyah: nextAyah.first.ayah,
            updatedAtDay: todayDay,
          );
        }
      });

      if (seededUnit != null && mounted) {
        setState(() {
          _remainingNewUnits = <MemUnitData>[
            ..._remainingNewUnits,
            seededUnit!,
          ];
        });
      }
      _showSnackBar('Debug: Added one test new memorization unit.');
    } catch (error) {
      _showSnackBar('Debug: Failed to add test unit ($error).');
    } finally {
      if (mounted) {
        setState(() {
          _isSeedingDebugUnit = false;
        });
      }
    }
  }

  List<AyahData> _takeDebugUnitAyahs(List<AyahData> ayahs, int? pageMadina) {
    if (ayahs.isEmpty) {
      return const <AyahData>[];
    }

    if (pageMadina == null) {
      final limit = ayahs.length < 4 ? ayahs.length : 4;
      return ayahs.take(limit).toList(growable: false);
    }

    final pageAyahs = <AyahData>[];
    for (final ayah in ayahs) {
      if (ayah.pageMadina != pageMadina) {
        break;
      }
      pageAyahs.add(ayah);
    }
    return pageAyahs.isEmpty ? <AyahData>[ayahs.first] : pageAyahs;
  }

  Widget _buildNewUnitRow(MemUnitData unit, AppStrings strings) {
    final unitId = unit.id;
    final busy = _busyUnitIds.contains(unitId);
    final canOpenInReader = _canOpenInReader(unit);
    final pageMissing = unit.pageMadina == null;

    return DecoratedBox(
      key: ValueKey('today_new_row_$unitId'),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatUnitHeader(unit, strings),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(_formatRange(unit, strings)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: ValueKey('today_open_reader_$unitId'),
                  onPressed: canOpenInReader
                      ? () {
                          context.go(_buildReaderRoute(unit));
                        }
                      : null,
                  child: Text(strings.openInReader),
                ),
                OutlinedButton(
                  key: ValueKey('today_open_companion_new_$unitId'),
                  onPressed: () {
                    context.go(_buildNewRoute(unitId));
                  },
                  child: Text(strings.openCompanionChain),
                ),
              ],
            ),
            if (pageMissing) ...[
              const SizedBox(height: 6),
              Text(strings.pageMetadataRequiredToOpenInReader),
            ],
            const SizedBox(height: 10),
            Text(
              strings.selfCheckGrade,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            _buildGradeButtons(
              strings: strings,
              unitId: unitId,
              busy: busy,
              keyPrefix: 'today_new_grade',
              onGrade: (gradeQ) {
                _submitGrade(
                  unitId: unitId,
                  gradeQ: gradeQ,
                  onSuccessRemove: () {
                    _remainingNewUnits.removeWhere((row) => row.id == unitId);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPreferencesProvider);
    final strings = AppStrings.of(prefs.language);
    final storageStatus = ref.watch(databaseStorageStatusProvider);
    final setupReadiness = ref.watch(soloSetupReadinessProvider);

    if (_isLoading) {
      return const SafeArea(
        key: ValueKey('today_screen_root'),
        child: Center(
          child: CircularProgressIndicator(
            key: ValueKey('today_loading'),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SafeArea(
        key: const ValueKey('today_screen_root'),
        child: Center(
          key: const ValueKey('today_error'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const ValueKey('today_retry_button'),
                onPressed: _loadTodayPlan,
                child: Text(strings.retry),
              ),
            ],
          ),
        ),
      );
    }

    final plan = _plan;
    final path = plan == null
        ? null
        : TodayPath.from(
            plan: plan,
            remainingStage4Due: _remainingStage4Due,
            remainingReviews: _remainingReviews,
            remainingNewUnits: _remainingNewUnits,
          );
    final showNormalPlanSections =
        plan != null && path != null && !_zeroUnitFirstRunMode;
    final storageWarningCard = _buildStorageWarningCard(strings, storageStatus);
    final guidedSetupCard = _buildGuidedSetupCard(strings, setupReadiness);

    return SafeArea(
      key: const ValueKey('today_screen_root'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.todayTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            storageWarningCard,
            if (storageWarningCard is! SizedBox) ...[
              const SizedBox(height: 12),
            ],
            guidedSetupCard,
            if (guidedSetupCard is! SizedBox) ...[
              const SizedBox(height: 12),
            ],
            if (plan != null && path != null && !_zeroUnitFirstRunMode) ...[
              _buildNextStepCard(strings, path),
              const SizedBox(height: 12),
              _buildPathModeCard(strings, plan, path),
              const SizedBox(height: 12),
            ],
            if (showNormalPlanSections) _buildStage4DueSection(strings),
            if (plan != null && path != null && !_zeroUnitFirstRunMode) ...[
              const SizedBox(height: 16),
              _buildReviewSection(strings, path),
              const SizedBox(height: 16),
              _buildNewMemorizationSection(strings, path),
              const SizedBox(height: 16),
              _buildSummarySection(strings, plan),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(AppStrings strings, TodayPlan plan) {
    return Card(
      key: const ValueKey('today_summary_section'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.todaySummaryTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              strings.plannedReviewMinutes(
                plan.minutesPlannedReviews.toStringAsFixed(1),
              ),
            ),
            Text(
              strings.plannedNewMinutes(
                plan.minutesPlannedNew.toStringAsFixed(1),
              ),
            ),
            Text(
              strings.reviewPressureLabel(
                plan.reviewPressure.toStringAsFixed(2),
              ),
            ),
            if (plan.recoveryMode)
              Text(
                strings.recoveryModeActive,
                key: const ValueKey('today_recovery_mode_badge'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (_planNoticeText(strings, plan) != null) ...[
              const SizedBox(height: 6),
              Text(
                _planNoticeText(strings, plan)!,
                key: const ValueKey('today_plan_message'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildSessionList(strings, plan),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList(AppStrings strings, TodayPlan plan) {
    return Column(
      key: const ValueKey('today_sessions_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.todaySessions,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        if (plan.sessions.isEmpty)
          Text(strings.noSessionsPlanned)
        else
          Column(
            children: [
              for (var i = 0; i < plan.sessions.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == plan.sessions.length - 1 ? 0 : 8,
                  ),
                  child: _buildSessionRow(plan.sessions[i], strings, i),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildSessionRow(
    PlannedSession session,
    AppStrings strings,
    int index,
  ) {
    final sessionLabel = session.sessionLabel;
    final focusCode = session.focus.code;
    final focus = focusCode == 'review_only'
        ? strings.reviewOnlyFocus
        : strings.newAndReviewFocus;
    final statusCode = session.status.code;
    final status = statusCode == 'due_soon'
        ? strings.sessionStatusDueSoon
        : strings.sessionStatusPending;
    final minutes = session.plannedMinutes;
    final isTimed = session.isTimed;
    final minuteOfDay = session.startMinuteOfDay;

    return DecoratedBox(
      key: ValueKey('today_session_$index'),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$sessionLabel • $focus',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Text(strings.sessionMinutes(minutes)),
            const SizedBox(width: 8),
            Text(isTimed && minuteOfDay != null
                ? _formatMinuteOfDay(minuteOfDay)
                : strings.untimedSessionLabel),
            const SizedBox(width: 8),
            Text(status),
          ],
        ),
      ),
    );
  }

  String _formatMinuteOfDay(int minuteOfDay) {
    final hour = (minuteOfDay ~/ 60).toString().padLeft(2, '0');
    final minute = (minuteOfDay % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  List<_GradeOption> _gradeOptions(AppStrings strings) {
    return <_GradeOption>[
      _GradeOption(label: strings.gradeGood, q: 5),
      _GradeOption(label: strings.gradeMedium, q: 4),
      _GradeOption(label: strings.gradeHard, q: 3),
      _GradeOption(label: strings.gradeVeryHard, q: 2),
      _GradeOption(label: strings.gradeFail, q: 0),
    ];
  }
}

class _GradeOption {
  const _GradeOption({
    required this.label,
    required this.q,
  });

  final String label;
  final int q;
}
