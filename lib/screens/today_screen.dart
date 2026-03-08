import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;

import '../app/app_preferences.dart';
import '../data/database/app_database.dart';
import '../data/providers/database_providers.dart';
import '../data/repositories/schedule_repo.dart';
import '../data/services/daily_planner.dart';
import '../data/services/planner_feedback.dart';
import '../data/services/scheduling/weekly_plan_generator.dart';
import '../data/time/local_day_time.dart';
import '../l10n/app_strings.dart';
import '../ui/planner/recovery_wizard_dialog.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _isLoading = true;
  bool _isSeedingDebugUnit = false;
  bool _allowStage4NewOverride = false;
  String? _errorMessage;
  TodayPlan? _plan;
  List<Stage4DueItem> _remainingStage4Due = const <Stage4DueItem>[];
  List<DueUnitRow> _remainingReviews = const <DueUnitRow>[];
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
      final plan = await ref
          .read(dailyPlannerProvider)
          .planToday(
            todayDay: todayDay,
            allowStage4Override: _allowStage4NewOverride,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _plan = plan;
        _remainingStage4Due = List<Stage4DueItem>.from(plan.plannedStage4Due);
        _remainingReviews = List<DueUnitRow>.from(plan.plannedReviews);
        _remainingNewUnits = List<MemUnitData>.from(plan.plannedNewUnits);
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
      final db = ref.read(appDatabaseProvider);
      final reviewLogRepo = ref.read(reviewLogRepoProvider);
      final scheduleRepo = ref.read(scheduleRepoProvider);

      await db.transaction(() async {
        await reviewLogRepo.insert(
          unitId: unitId,
          tsDay: tsDay,
          tsSeconds: tsSeconds,
          gradeQ: gradeQ,
          durationSeconds: null,
          mistakesCount: null,
        );
        final updated = await scheduleRepo.applyReviewWithScheduler(
          unitId: unitId,
          todayDay: tsDay,
          gradeQ: gradeQ,
        );
        if (!updated) {
          throw StateError('Schedule state not found for unit $unitId');
        }
      });

      if (!mounted) {
        return;
      }

      setState(() {
        onSuccessRemove();
        _busyUnitIds.remove(unitId);
      });
      _showSnackBar(strings.gradeSaved);
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
    messenger.showSnackBar(SnackBar(content: Text(message)));
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

  Widget _buildReviewSection(AppStrings strings) {
    return Card(
      key: const ValueKey('today_reviews_section'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.plannedReviews,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_remainingReviews.isEmpty)
              Text(strings.noPlannedReviewsLeft)
            else
              Column(
                children: [
                  for (final dueRow in _remainingReviews) ...[
                    _buildReviewRow(dueRow, strings),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
          ],
        ),
      ),
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
    final needsStrengthening =
        item.lifecycle.stage4Status == 'failed' ||
        item.lifecycle.stage4Status == 'needs_reinforcement' ||
        item.lifecycle.stage4StrengtheningRoute != null;
    if (needsStrengthening) {
      return '/companion/chain?unitId=${item.unit.id}&mode=new';
    }
    return '/companion/chain?unitId=${item.unit.id}&mode=stage4';
  }

  String _reviewRouteForUnit(int unitId) {
    return '/companion/chain?unitId=$unitId&mode=review';
  }

  String _newRouteForUnit(MemUnitData unit) {
    return '/companion/chain?unitId=${unit.id}&mode=new';
  }

  bool get _hasRemainingWork =>
      _remainingStage4Due.isNotEmpty ||
      _remainingReviews.isNotEmpty ||
      _remainingNewUnits.isNotEmpty;

  bool _shouldShowEmptyState(TodayPlan plan) {
    return !_hasRemainingWork &&
        plan.minutesPlannedReviews == 0 &&
        plan.minutesPlannedNew == 0;
  }

  Widget _buildCoachingCard(AppStrings strings, TodayPlan plan) {
    final content = _resolveCoachingContent(strings);
    final feedback = PlannerFeedbackSnapshot.fromTodayPlan(plan);
    final extraModes = _buildOtherPracticeModes(strings, content);
    return Card(
      key: const ValueKey('today_coaching_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.todayDoThisNext,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Text(
              content.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            _buildHealthBadge(
              key: const ValueKey('today_plan_health_badge'),
              strings: strings,
              health: feedback.health,
            ),
            const SizedBox(height: 12),
            _buildTodayExplanationPacket(strings, feedback),
            if (plan.recoveryMode) ...[
              const SizedBox(height: 10),
              Text(
                strings.recoveryModeActive,
                key: const ValueKey('today_recovery_mode_badge'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(strings.todayRecoveryModeHint),
            ],
            if (plan.message != null) ...[
              const SizedBox(height: 10),
              Text(
                plan.message!,
                key: const ValueKey('today_coaching_plan_note'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              strings.todayWhyItMatters,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(content.reason),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('today_coaching_primary_action'),
              onPressed: () {
                context.go(content.primaryRoute);
              },
              child: Text(content.primaryActionLabel),
            ),
            if (extraModes != null) ...[
              const SizedBox(height: 14),
              extraModes,
            ],
            const SizedBox(height: 14),
            DecoratedBox(
              key: const ValueKey('today_short_day_hint'),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.todayShortDayTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(content.shortDayHint),
                    if (feedback.minimumDayRecommended) ...[
                      const SizedBox(height: 8),
                      Text(strings.todayMinimumDayHint),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        key: const ValueKey('today_minimum_day_button'),
                        onPressed: () {
                          context.go(content.primaryRoute);
                        },
                        child: Text(strings.todayMinimumDayAction),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(strings.todayRecoveryEntryHint),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const ValueKey('today_recovery_entry'),
              onPressed: () {
                context.go('/plan');
              },
              child: Text(strings.todayOpenMyPlan),
            ),
            if (feedback.recoverySuggested) ...[
              const SizedBox(height: 8),
              TextButton(
                key: const ValueKey('today_recovery_wizard_button'),
                onPressed: () {
                  _openRecoveryWizard(strings, content);
                },
                child: Text(strings.recoveryAssistantTitle),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildOtherPracticeModes(
    AppStrings strings,
    _TodayCoachingContent content,
  ) {
    final shortcuts = <_TodayPracticeShortcut>[];

    if (content.primaryMode != _TodayPracticeMode.delayedCheck &&
        _remainingStage4Due.isNotEmpty) {
      shortcuts.add(
        _TodayPracticeShortcut(
          key: const ValueKey('today_other_practice_mode_stage4'),
          label: strings.doDelayedCheck,
          route: _stage4RouteForItem(_remainingStage4Due.first),
        ),
      );
    }
    if (content.primaryMode != _TodayPracticeMode.review &&
        _remainingReviews.isNotEmpty) {
      shortcuts.add(
        _TodayPracticeShortcut(
          key: const ValueKey('today_other_practice_mode_review'),
          label: strings.continueReviewPractice,
          route: _reviewRouteForUnit(_remainingReviews.first.unit.id),
        ),
      );
    }
    if (content.primaryMode != _TodayPracticeMode.newPractice &&
        _remainingNewUnits.isNotEmpty) {
      shortcuts.add(
        _TodayPracticeShortcut(
          key: const ValueKey('today_other_practice_mode_new'),
          label: strings.startNewPractice,
          route: _newRouteForUnit(_remainingNewUnits.first),
        ),
      );
    }

    if (shortcuts.isEmpty) {
      return null;
    }

    return DecoratedBox(
      key: const ValueKey('today_other_practice_modes'),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.todayOtherPracticeModesTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(strings.todayOtherPracticeModesHint),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final shortcut in shortcuts)
                  OutlinedButton(
                    key: shortcut.key,
                    onPressed: () {
                      context.go(shortcut.route);
                    },
                    child: Text(shortcut.label),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openRecoveryWizard(AppStrings strings, _TodayCoachingContent content) {
    showPlannerRecoveryWizard(
      context: context,
      strings: strings,
      onOpenMyPlan: () {
        context.go('/plan');
      },
      onMinimumDay: () {
        context.go(content.primaryRoute);
      },
    );
  }

  Widget _buildTodayExplanationPacket(
    AppStrings strings,
    PlannerFeedbackSnapshot feedback,
  ) {
    final lines = <String>[
      _localizedHealthSummary(strings, feedback.health),
      if (feedback.newWorkPaused) strings.todayNewWorkPausedExplanation,
      if (!feedback.newWorkPaused && feedback.newWorkReduced)
        strings.todayNewWorkReducedExplanation,
      if (feedback.backlogBurnDownSuggested) strings.planBacklogBurnDownHint,
    ];

    return DecoratedBox(
      key: const ValueKey('today_explanation_packet'),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.planHealthTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < lines.length; i++) ...[
              Text(lines[i]),
              if (i != lines.length - 1) const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHealthBadge({
    required Key key,
    required AppStrings strings,
    required PlannerHealthState health,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (health) {
      PlannerHealthState.onTrack => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      PlannerHealthState.tight => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      PlannerHealthState.overloaded => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
    };

    return DecoratedBox(
      key: key,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '${strings.planHealthTitle}: ${_localizedHealthLabel(strings, health)}',
          style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  String _localizedHealthLabel(AppStrings strings, PlannerHealthState health) {
    return switch (health) {
      PlannerHealthState.onTrack => strings.planHealthOnTrack,
      PlannerHealthState.tight => strings.planHealthTight,
      PlannerHealthState.overloaded => strings.planHealthOverloaded,
    };
  }

  String _localizedHealthSummary(
    AppStrings strings,
    PlannerHealthState health,
  ) {
    return switch (health) {
      PlannerHealthState.onTrack => strings.planHealthOnTrackSummary,
      PlannerHealthState.tight => strings.planHealthTightSummary,
      PlannerHealthState.overloaded => strings.planHealthOverloadedSummary,
    };
  }

  _TodayCoachingContent _resolveCoachingContent(AppStrings strings) {
    if (_remainingStage4Due.isNotEmpty) {
      final firstStage4 = _remainingStage4Due.first;
      return _TodayCoachingContent(
        title: strings.todayFocusStage4Title,
        reason: strings.todayFocusStage4Reason,
        shortDayHint: strings.todayFocusStage4ShortDay,
        primaryActionLabel: strings.todayFocusStage4Action,
        primaryRoute: _stage4RouteForItem(firstStage4),
        primaryMode: _TodayPracticeMode.delayedCheck,
      );
    }
    if (_remainingReviews.isNotEmpty) {
      final firstReview = _remainingReviews.first;
      return _TodayCoachingContent(
        title: strings.todayFocusReviewTitle,
        reason: strings.todayFocusReviewReason,
        shortDayHint: strings.todayFocusReviewShortDay,
        primaryActionLabel: strings.todayFocusReviewAction,
        primaryRoute: _reviewRouteForUnit(firstReview.unit.id),
        primaryMode: _TodayPracticeMode.review,
      );
    }
    final firstNew = _remainingNewUnits.first;
    return _TodayCoachingContent(
      title: strings.todayFocusNewTitle,
      reason: strings.todayFocusNewReason,
      shortDayHint: strings.todayFocusNewShortDay,
      primaryActionLabel: strings.todayFocusNewAction,
      primaryRoute: _newRouteForUnit(firstNew),
      primaryMode: _TodayPracticeMode.newPractice,
    );
  }

  Widget _buildNoWorkStateCard(AppStrings strings, TodayPlan plan) {
    if (_shouldShowEmptyState(plan)) {
      return Card(
        key: const ValueKey('today_empty_state'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.todayEmptyTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(strings.todayEmptyMessage),
              const SizedBox(height: 12),
              FilledButton(
                key: const ValueKey('today_empty_open_plan'),
                onPressed: () {
                  context.go('/plan');
                },
                child: Text(strings.todayOpenMyPlan),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      key: const ValueKey('today_completion_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.todayCompletionTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(strings.todayCompletionMessage),
          ],
        ),
      ),
    );
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
              strings.todayStage4Explanation,
              key: const ValueKey('today_stage4_explanation'),
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
            if (plan.stage4CatchUpMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                plan.stage4CatchUpMessage!,
                key: const ValueKey('today_stage4_catchup_message'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
                              child: Text(strings.doDelayedCheck),
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

  Widget _buildReviewRow(DueUnitRow dueRow, AppStrings strings) {
    final unit = dueRow.unit;
    final unitId = unit.id;
    final busy = _busyUnitIds.contains(unitId);

    return DecoratedBox(
      key: ValueKey('today_review_row_$unitId'),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
            Text(strings.dueDayLabel(dueRow.schedule.dueDay)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: ValueKey('today_open_companion_review_$unitId'),
                  onPressed: () {
                    context.go('/companion/chain?unitId=$unitId&mode=review');
                  },
                  child: Text(strings.continueReviewPractice),
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

  Widget _buildNewMemorizationSection(AppStrings strings) {
    return Card(
      key: const ValueKey('today_new_section'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.newMemorization,
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
            if (_remainingNewUnits.isEmpty)
              Text(strings.noPlannedNewUnitsLeft)
            else
              Column(
                children: [
                  for (final unit in _remainingNewUnits) ...[
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
      final unitKey =
          'debug_seed:p${page ?? 0}:s${start.surah}a${start.ayah}'
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
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                    context.go('/companion/chain?unitId=$unitId&mode=new');
                  },
                  child: Text(strings.startNewPractice),
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

    if (_isLoading) {
      return const SafeArea(
        key: ValueKey('today_screen_root'),
        child: Center(
          child: CircularProgressIndicator(key: ValueKey('today_loading')),
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
            if (plan != null) ...[
              const SizedBox(height: 12),
              if (_hasRemainingWork)
                _buildCoachingCard(strings, plan)
              else
                _buildNoWorkStateCard(strings, plan),
              const SizedBox(height: 12),
              _buildSessionSection(strings, plan),
              const SizedBox(height: 12),
            ],
            _buildStage4DueSection(strings),
            const SizedBox(height: 16),
            _buildReviewSection(strings),
            const SizedBox(height: 16),
            _buildNewMemorizationSection(strings),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionSection(AppStrings strings, TodayPlan plan) {
    return Card(
      key: const ValueKey('today_sessions_section'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.todaySessions,
              style: Theme.of(context).textTheme.titleLarge,
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
        ),
      ),
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
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
            Text(
              isTimed && minuteOfDay != null
                  ? _formatMinuteOfDay(minuteOfDay)
                  : strings.untimedSessionLabel,
            ),
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
  const _GradeOption({required this.label, required this.q});

  final String label;
  final int q;
}

class _TodayCoachingContent {
  const _TodayCoachingContent({
    required this.title,
    required this.reason,
    required this.shortDayHint,
    required this.primaryActionLabel,
    required this.primaryRoute,
    required this.primaryMode,
  });

  final String title;
  final String reason;
  final String shortDayHint;
  final String primaryActionLabel;
  final String primaryRoute;
  final _TodayPracticeMode primaryMode;
}

enum _TodayPracticeMode { newPractice, review, delayedCheck }

class _TodayPracticeShortcut {
  const _TodayPracticeShortcut({
    required this.key,
    required this.label,
    required this.route,
  });

  final Key key;
  final String label;
  final String route;
}
