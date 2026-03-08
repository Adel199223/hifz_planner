import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/schedule_repo.dart';
import 'package:hifz_planner/data/services/daily_planner.dart';
import 'package:hifz_planner/data/services/goal_progress_snapshot_service.dart';
import 'package:hifz_planner/data/services/scheduling/weekly_plan_generator.dart';

void main() {
  const service = GoalProgressSnapshotService();

  test('weekly snapshot defaults to steady progress when plan is empty', () {
    final snapshot = service.fromWeeklyPlan(null);

    expect(snapshot.focus, GoalFocus.steadyProgress);
    expect(snapshot.completedPracticeDaysLast7, isNull);
    expect(snapshot.completedReviewsLast7, isNull);
  });

  test('today snapshot protects retention when review pressure is tight', () {
    final snapshot = service.fromTodayPlan(
      const TodayPlan(
        plannedReviews: <DueUnitRow>[],
        plannedNewUnits: <MemUnitData>[],
        plannedStage4Due: <Stage4DueItem>[],
        revisionOnly: false,
        minutesPlannedReviews: 25,
        minutesPlannedNew: 10,
        stage4BlocksNewByDefault: false,
        stage4QualitySnapshot: Stage4QualitySnapshot(),
        reviewPressure: 1.0,
        recoveryMode: false,
      ),
    );

    expect(snapshot.focus, GoalFocus.protectRetention);
  });

  test('today snapshot stabilizes when stage-4 pressure blocks new work', () {
    final snapshot = service.fromTodayPlan(
      TodayPlan(
        plannedReviews: const <DueUnitRow>[],
        plannedNewUnits: const <MemUnitData>[],
        plannedStage4Due: <Stage4DueItem>[_stage4DueItem()],
        revisionOnly: true,
        minutesPlannedReviews: 15,
        minutesPlannedNew: 0,
        stage4BlocksNewByDefault: true,
        stage4QualitySnapshot: const Stage4QualitySnapshot(),
        reviewPressure: 1.3,
        recoveryMode: false,
      ),
    );

    expect(snapshot.focus, GoalFocus.recoveryAndStabilize);
  });

  test('weekly snapshot stabilizes when recovery days are present', () {
    final snapshot = service.fromWeeklyPlan(
      WeeklyPlan(
        startDay: 100,
        days: const <WeeklyPlanDay>[
          WeeklyPlanDay(
            dayIndex: 100,
            weekday: DateTime.monday,
            enabledStudyDay: true,
            skipDay: false,
            revisionOnlyDay: false,
            totalPlannedMinutes: 45,
            reviewPressure: 1.4,
            recoveryMode: true,
            sessions: <PlannedSession>[
              PlannedSession(
                sessionLabel: 'Session A',
                focus: PlannedSessionFocus.reviewOnly,
                plannedMinutes: 45,
                plannedReviewMinutes: 45,
                plannedNewMinutes: 0,
                isTimed: false,
                startMinuteOfDay: null,
                status: PlannedSessionStatus.dueSoon,
              ),
            ],
          ),
        ],
      ),
    );

    expect(snapshot.focus, GoalFocus.recoveryAndStabilize);
  });
}

Stage4DueItem _stage4DueItem() {
  return Stage4DueItem(
    unit: const MemUnitData(
      id: 1,
      kind: 'page_segment',
      pageMadina: 1,
      startSurah: 1,
      startAyah: 1,
      endSurah: 1,
      endAyah: 5,
      unitKey: 'u1',
      createdAtDay: 1,
      updatedAtDay: 1,
    ),
    lifecycle: const CompanionLifecycleStateData(
      unitId: 1,
      lifecycleTier: 'ready',
      stage4Status: 'needs_reinforcement',
      stage4MissedCount: 0,
      newOverrideCount: 0,
      updatedAtDay: 1,
      updatedAtSeconds: 1,
    ),
    dueKind: 'next_day_required',
    dueDay: 1,
    mandatory: true,
    overdueDays: 1,
    unresolvedTargetsCount: 2,
  );
}
