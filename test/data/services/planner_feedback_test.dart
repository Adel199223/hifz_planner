import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/schedule_repo.dart';
import 'package:hifz_planner/data/services/daily_planner.dart';
import 'package:hifz_planner/data/services/planner_feedback.dart';
import 'package:hifz_planner/data/services/scheduling/weekly_plan_generator.dart';

void main() {
  test('today feedback becomes overloaded when stage-4 blocks new work', () {
    final snapshot = PlannerFeedbackSnapshot.fromTodayPlan(
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

    expect(snapshot.health, PlannerHealthState.overloaded);
    expect(snapshot.newWorkPaused, isTrue);
    expect(snapshot.backlogBurnDownSuggested, isTrue);
    expect(snapshot.hasStage4Pressure, isTrue);
  });

  test('today feedback becomes tight when review pressure rises', () {
    final snapshot = PlannerFeedbackSnapshot.fromTodayPlan(
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

    expect(snapshot.health, PlannerHealthState.tight);
    expect(snapshot.newWorkReduced, isTrue);
    expect(snapshot.minimumDayRecommended, isTrue);
  });

  test('weekly feedback becomes overloaded when a recovery day exists', () {
    final snapshot = PlannerFeedbackSnapshot.fromWeeklyPlan(
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

    expect(snapshot.health, PlannerHealthState.overloaded);
    expect(snapshot.recoverySuggested, isTrue);
    expect(snapshot.backlogBurnDownSuggested, isTrue);
  });

  test('weekly feedback stays on track when pressure is light', () {
    final snapshot = PlannerFeedbackSnapshot.fromWeeklyPlan(
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
            reviewPressure: 0.4,
            recoveryMode: false,
            sessions: <PlannedSession>[
              PlannedSession(
                sessionLabel: 'Session A',
                focus: PlannedSessionFocus.newAndReview,
                plannedMinutes: 45,
                plannedReviewMinutes: 20,
                plannedNewMinutes: 25,
                isTimed: false,
                startMinuteOfDay: null,
                status: PlannedSessionStatus.pending,
              ),
            ],
          ),
        ],
      ),
    );

    expect(snapshot.health, PlannerHealthState.onTrack);
    expect(snapshot.minimumDayRecommended, isFalse);
    expect(snapshot.backlogBurnDownSuggested, isFalse);
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
