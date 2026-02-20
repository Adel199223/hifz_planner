import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/database/app_database.dart';
import '../data/providers/database_providers.dart';
import '../data/repositories/schedule_repo.dart';
import '../data/services/daily_planner.dart';
import '../data/time/local_day_time.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  static const List<_GradeOption> _gradeOptions = <_GradeOption>[
    _GradeOption(label: 'Good', q: 5),
    _GradeOption(label: 'Medium', q: 4),
    _GradeOption(label: 'Hard', q: 3),
    _GradeOption(label: 'Very hard', q: 2),
    _GradeOption(label: 'Fail', q: 0),
  ];

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
        _errorMessage = 'Failed to load today plan.';
      });
    }
  }

  Future<void> _submitGrade({
    required int unitId,
    required int gradeQ,
    required VoidCallback onSuccessRemove,
  }) async {
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
      _showSnackBar('Grade saved.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyUnitIds.remove(unitId);
      });
      _showSnackBar('Failed to save grade.');
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

  String _formatUnitHeader(MemUnitData unit) {
    final parts = <String>[unit.kind];
    if (unit.pageMadina != null) {
      parts.add('Page ${unit.pageMadina}');
    }
    return parts.join(' • ');
  }

  String _formatRange(MemUnitData unit) {
    final startSurah = unit.startSurah;
    final startAyah = unit.startAyah;
    final endSurah = unit.endSurah;
    final endAyah = unit.endAyah;

    if (startSurah == null ||
        startAyah == null ||
        endSurah == null ||
        endAyah == null) {
      return 'Range unavailable';
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
    required int unitId,
    required bool busy,
    required String keyPrefix,
    required ValueChanged<int> onGrade,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in _gradeOptions)
          OutlinedButton(
            key: ValueKey('${keyPrefix}_${unitId}_q${option.q}'),
            onPressed: busy ? null : () => onGrade(option.q),
            child: Text(option.label),
          ),
      ],
    );
  }

  Widget _buildReviewSection() {
    return Card(
      key: const ValueKey('today_reviews_section'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Planned Reviews',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_remainingReviews.isEmpty)
              const Text('No planned reviews left.')
            else
              Column(
                children: [
                  for (final dueRow in _remainingReviews) ...[
                    _buildReviewRow(dueRow),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewRow(DueUnitRow dueRow) {
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
              _formatUnitHeader(unit),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(_formatRange(unit)),
            const SizedBox(height: 4),
            Text('Due day ${dueRow.schedule.dueDay}'),
            const SizedBox(height: 10),
            _buildGradeButtons(
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

  Widget _buildNewMemorizationSection() {
    return Card(
      key: const ValueKey('today_new_section'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Memorization',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_remainingNewUnits.isEmpty)
              const Text('No planned new units left.')
            else
              Column(
                children: [
                  for (final unit in _remainingNewUnits) ...[
                    _buildNewUnitRow(unit),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewUnitRow(MemUnitData unit) {
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
              _formatUnitHeader(unit),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(_formatRange(unit)),
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
                  child: const Text('Open in Reader'),
                ),
              ],
            ),
            if (pageMissing) ...[
              const SizedBox(height: 6),
              const Text('Page metadata required to open in Reader.'),
            ],
            const SizedBox(height: 10),
            Text(
              'Self-check grade',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            _buildGradeButtons(
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
                child: const Text('Retry'),
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
              'Today',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (plan != null) ...[
              Text(
                'Planned review minutes: ${plan.minutesPlannedReviews.toStringAsFixed(1)}',
              ),
              Text(
                'Planned new minutes: ${plan.minutesPlannedNew.toStringAsFixed(1)}',
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
            _buildReviewSection(),
            const SizedBox(height: 16),
            _buildNewMemorizationSection(),
          ],
        ),
      ),
    );
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
