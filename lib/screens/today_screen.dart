import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_preferences.dart';
import '../data/database/app_database.dart';
import '../data/providers/database_providers.dart';
import '../data/repositories/schedule_repo.dart';
import '../data/services/daily_planner.dart';
import '../data/time/local_day_time.dart';
import '../l10n/app_strings.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  TodayPlan? _plan;
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
      final plan =
          await ref.read(dailyPlannerProvider).planToday(todayDay: todayDay);
      if (!mounted) {
        return;
      }
      setState(() {
        _plan = plan;
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
    messenger.showSnackBar(
      SnackBar(content: Text(message)),
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

  Widget _buildReviewRow(DueUnitRow dueRow, AppStrings strings) {
    final unit = dueRow.unit;
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
            Text(strings.dueDayLabel(dueRow.schedule.dueDay)),
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
            if (plan != null) ...[
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
              if (plan.message != null) ...[
                const SizedBox(height: 6),
                Text(
                  plan.message!,
                  key: const ValueKey('today_plan_message'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
            _buildReviewSection(strings),
            const SizedBox(height: 16),
            _buildNewMemorizationSection(strings),
          ],
        ),
      ),
    );
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
