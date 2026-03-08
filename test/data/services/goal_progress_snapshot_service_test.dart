import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/schedule_repo.dart';
import 'package:hifz_planner/data/services/daily_planner.dart';
import 'package:hifz_planner/data/services/goal_progress_snapshot_service.dart';
import 'package:hifz_planner/data/services/scheduling/weekly_plan_generator.dart';

void main() {
  late AppDatabase db;
  late GoalProgressSnapshotService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = GoalProgressSnapshotService(db);
  });

  tearDown(() async {
    await db.close();
  });

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

  test('buildWeeklySnapshot reports no-history learners calmly', () async {
    final snapshot = await service.buildWeeklySnapshot(
      plan: null,
      todayDay: 50,
    );

    expect(snapshot.focus, GoalFocus.steadyProgress);
    expect(snapshot.completedPracticeDaysLast7, 0);
    expect(snapshot.completedDelayedChecksLast7, 0);
    expect(snapshot.completedReviewsLast7, 0);
    expect(snapshot.completedNewPracticeLast7, 0);
    expect(snapshot.recentQualityBand, isNull);
    expect(snapshot.hasRecentHistory, isFalse);
  });

  test('buildWeeklySnapshot recognizes steady recent practice', () async {
    await _seedMeaningfulProgress(
      db,
      days: const <int>[44, 45, 46, 47],
      reviewGrades: const <int>[5, 4, 5, 4],
      stage4Outcomes: const <String>['pass'],
    );

    final snapshot = await service.buildWeeklySnapshot(
      plan: null,
      todayDay: 50,
    );

    expect(snapshot.completedPracticeDaysLast7, 4);
    expect(snapshot.completedReviewsLast7, 4);
    expect(snapshot.completedDelayedChecksLast7, 1);
    expect(snapshot.completedNewPracticeLast7, 4);
    expect(snapshot.recentQualityBand, GoalProgressQualityBand.steady);
    expect(snapshot.hasRecentHistory, isTrue);
  });

  test('buildWeeklySnapshot recognizes retention-heavy recent work', () async {
    await _seedMeaningfulProgress(
      db,
      days: const <int>[47, 48],
      reviewGrades: const <int>[4, 3, 2, 3, 4],
      stage4Outcomes: const <String>['partial', 'pass', 'fail'],
    );

    final snapshot = await service.buildWeeklySnapshot(
      plan: _protectRetentionPlan(),
      todayDay: 50,
    );

    expect(snapshot.focus, GoalFocus.protectRetention);
    expect(snapshot.completedPracticeDaysLast7, 2);
    expect(snapshot.completedDelayedChecksLast7, 3);
    expect(snapshot.completedReviewsLast7, 5);
    expect(snapshot.recentQualityBand, GoalProgressQualityBand.mixed);
  });

  test(
    'buildWeeklySnapshot keeps recovery learners in stabilize posture',
    () async {
      await _seedMeaningfulProgress(
        db,
        days: const <int>[49],
        reviewGrades: const <int>[2, 0, 2],
        stage4Outcomes: const <String>['fail'],
      );

      final snapshot = await service.buildWeeklySnapshot(
        plan: _recoveryPlan(),
        todayDay: 50,
      );

      expect(snapshot.focus, GoalFocus.recoveryAndStabilize);
      expect(snapshot.completedPracticeDaysLast7, 1);
      expect(snapshot.recentQualityBand, GoalProgressQualityBand.strained);
    },
  );

  test('buildWeeklySnapshot derives recent quality band from grades', () async {
    await _seedMeaningfulProgress(
      db,
      days: const <int>[48, 49],
      reviewGrades: const <int>[5, 2, 0, 2],
    );

    final snapshot = await service.buildWeeklySnapshot(
      plan: null,
      todayDay: 50,
    );

    expect(snapshot.recentQualityBand, GoalProgressQualityBand.strained);
  });

  test('coachingFromWeeklyPlan stays steady for stable recent work', () {
    final advice = service.coachingFromWeeklyPlan(
      null,
      snapshot: const GoalProgressSnapshot(
        focus: GoalFocus.steadyProgress,
        completedPracticeDaysLast7: 4,
        completedDelayedChecksLast7: 0,
        completedReviewsLast7: 3,
        completedNewPracticeLast7: 3,
        recentQualityBand: GoalProgressQualityBand.steady,
      ),
    );

    expect(advice.recommendation, GoalCoachingRecommendation.staySteady);
  });

  test(
    'coachingFromTodayPlan recommends minimum day on a sparse tight day',
    () {
      final advice = service.coachingFromTodayPlan(
        const TodayPlan(
          plannedReviews: <DueUnitRow>[],
          plannedNewUnits: <MemUnitData>[],
          plannedStage4Due: <Stage4DueItem>[],
          revisionOnly: false,
          minutesPlannedReviews: 20,
          minutesPlannedNew: 10,
          stage4BlocksNewByDefault: false,
          stage4QualitySnapshot: Stage4QualitySnapshot(),
          reviewPressure: 0.95,
          recoveryMode: false,
        ),
        snapshot: const GoalProgressSnapshot(
          focus: GoalFocus.protectRetention,
          completedPracticeDaysLast7: 1,
          completedDelayedChecksLast7: 0,
          completedReviewsLast7: 1,
          completedNewPracticeLast7: 0,
          recentQualityBand: GoalProgressQualityBand.mixed,
        ),
      );

      expect(advice.recommendation, GoalCoachingRecommendation.useMinimumDay);
    },
  );

  test(
    'coachingFromWeeklyPlan protects retention when recent quality strains',
    () {
      final advice = service.coachingFromWeeklyPlan(
        _protectRetentionPlan(),
        snapshot: const GoalProgressSnapshot(
          focus: GoalFocus.protectRetention,
          completedPracticeDaysLast7: 3,
          completedDelayedChecksLast7: 2,
          completedReviewsLast7: 5,
          completedNewPracticeLast7: 2,
          recentQualityBand: GoalProgressQualityBand.strained,
        ),
      );

      expect(
        advice.recommendation,
        GoalCoachingRecommendation.protectRetention,
      );
    },
  );

  test(
    'coachingFromWeeklyPlan asks to lighten setup when recovery stays strained',
    () {
      final advice = service.coachingFromWeeklyPlan(
        _recoveryPlan(),
        snapshot: const GoalProgressSnapshot(
          focus: GoalFocus.recoveryAndStabilize,
          completedPracticeDaysLast7: 1,
          completedDelayedChecksLast7: 2,
          completedReviewsLast7: 3,
          completedNewPracticeLast7: 1,
          recentQualityBand: GoalProgressQualityBand.strained,
        ),
      );

      expect(advice.recommendation, GoalCoachingRecommendation.lightenSetup);
    },
  );
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

WeeklyPlan _protectRetentionPlan() {
  return WeeklyPlan(
    startDay: 50,
    days: const <WeeklyPlanDay>[
      WeeklyPlanDay(
        dayIndex: 50,
        weekday: DateTime.monday,
        enabledStudyDay: true,
        skipDay: false,
        revisionOnlyDay: false,
        totalPlannedMinutes: 40,
        reviewPressure: 0.92,
        recoveryMode: false,
        sessions: <PlannedSession>[
          PlannedSession(
            sessionLabel: 'Session A',
            focus: PlannedSessionFocus.reviewOnly,
            plannedMinutes: 40,
            plannedReviewMinutes: 30,
            plannedNewMinutes: 0,
            isTimed: false,
            startMinuteOfDay: null,
            status: PlannedSessionStatus.dueSoon,
          ),
        ],
      ),
    ],
  );
}

WeeklyPlan _recoveryPlan() {
  return WeeklyPlan(
    startDay: 50,
    days: const <WeeklyPlanDay>[
      WeeklyPlanDay(
        dayIndex: 50,
        weekday: DateTime.monday,
        enabledStudyDay: true,
        skipDay: false,
        revisionOnlyDay: true,
        totalPlannedMinutes: 20,
        reviewPressure: 1.3,
        recoveryMode: true,
        sessions: <PlannedSession>[
          PlannedSession(
            sessionLabel: 'Session A',
            focus: PlannedSessionFocus.reviewOnly,
            plannedMinutes: 20,
            plannedReviewMinutes: 20,
            plannedNewMinutes: 0,
            isTimed: false,
            startMinuteOfDay: null,
            status: PlannedSessionStatus.dueSoon,
          ),
        ],
      ),
    ],
  );
}

Future<void> _seedMeaningfulProgress(
  AppDatabase db, {
  required List<int> days,
  List<int> reviewGrades = const <int>[],
  List<String> stage4Outcomes = const <String>[],
}) async {
  var unitSeed = 1;
  for (final day in days) {
    final unitId = await db
        .into(db.memUnit)
        .insert(
          MemUnitCompanion.insert(
            kind: 'ayah_range',
            pageMadina: const Value(1),
            startSurah: const Value(1),
            startAyah: Value(unitSeed),
            endSurah: const Value(1),
            endAyah: Value(unitSeed),
            unitKey: 'goal-progress-$unitSeed',
            createdAtDay: day,
            updatedAtDay: day,
          ),
        );
    await db
        .into(db.companionChainSession)
        .insert(
          CompanionChainSessionCompanion.insert(
            unitId: unitId,
            targetVerseCount: 1,
            passedVerseCount: const Value(1),
            chainResult: 'completed',
            retrievalStrength: const Value(0.85),
            createdAtDay: day,
            updatedAtDay: day,
            startedAtSeconds: const Value(100),
            endedAtSeconds: const Value(200),
          ),
        );
    unitSeed++;
  }

  if (reviewGrades.isNotEmpty) {
    final sourceDays = days.isNotEmpty ? days : <int>[50];
    final reviewUnitId = await db
        .into(db.memUnit)
        .insert(
          MemUnitCompanion.insert(
            kind: 'ayah_range',
            pageMadina: const Value(1),
            startSurah: const Value(1),
            startAyah: Value(unitSeed),
            endSurah: const Value(1),
            endAyah: Value(unitSeed),
            unitKey: 'goal-progress-review-$unitSeed',
            createdAtDay: days.isEmpty ? 50 : days.first,
            updatedAtDay: days.isEmpty ? 50 : days.first,
          ),
        );
    for (var i = 0; i < reviewGrades.length; i++) {
      final day = sourceDays[i % sourceDays.length];
      await db
          .into(db.reviewLog)
          .insert(
            ReviewLogCompanion.insert(
              unitId: reviewUnitId,
              tsDay: day,
              tsSeconds: Value(200 + i),
              gradeQ: reviewGrades[i],
            ),
          );
    }
  }

  if (stage4Outcomes.isNotEmpty) {
    final sourceDays = days.isNotEmpty ? days : <int>[50];
    final stage4UnitId = await db
        .into(db.memUnit)
        .insert(
          MemUnitCompanion.insert(
            kind: 'ayah_range',
            pageMadina: const Value(2),
            startSurah: const Value(1),
            startAyah: Value(unitSeed + 10),
            endSurah: const Value(1),
            endAyah: Value(unitSeed + 10),
            unitKey: 'goal-progress-stage4-$unitSeed',
            createdAtDay: days.isEmpty ? 50 : days.first,
            updatedAtDay: days.isEmpty ? 50 : days.first,
          ),
        );
    for (var i = 0; i < stage4Outcomes.length; i++) {
      final day = sourceDays[i % sourceDays.length];
      await db
          .into(db.companionStage4Session)
          .insert(
            CompanionStage4SessionCompanion.insert(
              unitId: stage4UnitId,
              dueKind: 'next_day_required',
              startedDay: day,
              startedSeconds: const Value(300),
              endedDay: Value(day),
              endedSeconds: const Value(360),
              outcome: Value(stage4Outcomes[i]),
            ),
          );
    }
  }
}
