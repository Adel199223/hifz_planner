import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/services/daily_planner.dart';
import 'package:hifz_planner/screens/today_path.dart';

void main() {
  test('computes mode and new state from current planner truth', () {
    final greenPath = TodayPath.from(
      plan: _plan(newAvailability: TodayNewAvailability.available),
      remainingStage4Due: const <Stage4DueItem>[],
      remainingReviews: const <PlannedReviewRow>[],
      remainingNewUnits: <MemUnitData>[_unit(10)],
    );
    expect(greenPath.mode, TodayPathMode.green);
    expect(greenPath.newState, TodayNewState.unlocked);

    final protectPath = TodayPath.from(
      plan: _plan(
        reviewPressure: 1.0,
        newAvailability: TodayNewAvailability.blockedReviewHealth,
      ),
      remainingStage4Due: const <Stage4DueItem>[],
      remainingReviews: const <PlannedReviewRow>[],
      remainingNewUnits: <MemUnitData>[_unit(11)],
    );
    expect(protectPath.mode, TodayPathMode.protect);
    expect(protectPath.newState, TodayNewState.lockedReviewHealth);

    final recoveryPath = TodayPath.from(
      plan: _plan(
        reviewPressure: 1.6,
        recoveryMode: true,
        revisionOnly: true,
        newAvailability: TodayNewAvailability.blockedReviewHealth,
      ),
      remainingStage4Due: const <Stage4DueItem>[],
      remainingReviews: const <PlannedReviewRow>[],
      remainingNewUnits: <MemUnitData>[_unit(12)],
    );
    expect(recoveryPath.mode, TodayPathMode.recovery);
    expect(recoveryPath.newState, TodayNewState.lockedReviewHealth);

    final stage4LockedPath = TodayPath.from(
      plan: _plan(
        stage4BlocksNewByDefault: true,
        newAvailability: TodayNewAvailability.blockedStage4,
      ),
      remainingStage4Due: <Stage4DueItem>[_stage4Due(20)],
      remainingReviews: const <PlannedReviewRow>[],
      remainingNewUnits: <MemUnitData>[_unit(13)],
    );
    expect(stage4LockedPath.mode, TodayPathMode.protect);
    expect(stage4LockedPath.newState, TodayNewState.lockedStage4);

    final setupLockedPath = TodayPath.from(
      plan: _plan(
        newAvailability: TodayNewAvailability.blockedSetup,
        notice: TodayPlanNotice.finishSetup,
      ),
      remainingStage4Due: const <Stage4DueItem>[],
      remainingReviews: const <PlannedReviewRow>[],
      remainingNewUnits: const <MemUnitData>[],
    );
    expect(setupLockedPath.newState, TodayNewState.lockedSetup);

    final noneAvailablePath = TodayPath.from(
      plan: _plan(newAvailability: TodayNewAvailability.noneAvailable),
      remainingStage4Due: const <Stage4DueItem>[],
      remainingReviews: const <PlannedReviewRow>[],
      remainingNewUnits: const <MemUnitData>[],
    );
    expect(noneAvailablePath.newState, TodayNewState.noneAvailable);
  });

  test('review pressure alone does not hide planned new units', () {
    final path = TodayPath.from(
      plan: _plan(
        reviewPressure: 1.0,
        plannedNewUnits: <MemUnitData>[_unit(40)],
        newAvailability: TodayNewAvailability.available,
      ),
      remainingStage4Due: const <Stage4DueItem>[],
      remainingReviews: const <PlannedReviewRow>[],
      remainingNewUnits: <MemUnitData>[_unit(40)],
    );

    expect(path.mode, TodayPathMode.protect);
    expect(path.newState, TodayNewState.unlocked);
    expect(path.optionalNew.map((unit) => unit.id), <int>[40]);
  });

  test('groups reviews by planner-assigned adaptive buckets', () {
    final path = TodayPath.from(
      plan: _plan(),
      remainingStage4Due: const <Stage4DueItem>[],
      remainingReviews: <PlannedReviewRow>[
        _review(1,
            bucket: AdaptiveQueueBucket.lockIn,
            reason: AdaptiveReviewReason.needsLockIn),
        _review(2,
            bucket: AdaptiveQueueBucket.weakSpot,
            reason: AdaptiveReviewReason.shakyRecently),
        _review(3,
            bucket: AdaptiveQueueBucket.recentReview,
            reason: AdaptiveReviewReason.recentCheckIn),
        _review(4,
            bucket: AdaptiveQueueBucket.maintenance,
            reason: AdaptiveReviewReason.maintenanceDue),
      ],
      remainingNewUnits: const <MemUnitData>[],
    );

    expect(path.lockInReviews.map((row) => row.unit.id).toList(), <int>[1]);
    expect(path.weakSpots.map((row) => row.unit.id).toList(), <int>[2]);
    expect(path.recentReviews.map((row) => row.unit.id).toList(), <int>[3]);
    expect(
      path.maintenanceReviews.map((row) => row.unit.id).toList(),
      <int>[4],
    );
    expect(path.warmUp?.unit.id, 1);
  });

  test(
      'next step prioritizes mandatory stage-4, lock-in, weak spot, recent review, maintenance, new, then resume',
      () {
    final stage4Path = TodayPath.from(
      plan: _plan(),
      remainingStage4Due: <Stage4DueItem>[_stage4Due(30)],
      remainingReviews: <PlannedReviewRow>[
        _review(1,
            bucket: AdaptiveQueueBucket.lockIn,
            reason: AdaptiveReviewReason.needsLockIn),
      ],
      remainingNewUnits: <MemUnitData>[_unit(31)],
    );
    expect(stage4Path.nextStep.kind, TodayNextStepKind.stage4Due);

    final lockInPath = TodayPath.from(
      plan: _plan(),
      remainingStage4Due: const <Stage4DueItem>[],
      remainingReviews: <PlannedReviewRow>[
        _review(2,
            bucket: AdaptiveQueueBucket.lockIn,
            reason: AdaptiveReviewReason.needsLockIn),
        _review(3,
            bucket: AdaptiveQueueBucket.weakSpot,
            reason: AdaptiveReviewReason.shakyRecently),
      ],
      remainingNewUnits: <MemUnitData>[_unit(32)],
    );
    expect(lockInPath.nextStep.kind, TodayNextStepKind.dueReview);
    expect(lockInPath.nextStep.reviewRow?.unit.id, 2);

    final weakSpotPath = TodayPath.from(
      plan: _plan(),
      remainingStage4Due: const <Stage4DueItem>[],
      remainingReviews: <PlannedReviewRow>[
        _review(4,
            bucket: AdaptiveQueueBucket.weakSpot,
            reason: AdaptiveReviewReason.shakyRecently),
      ],
      remainingNewUnits: <MemUnitData>[_unit(33)],
    );
    expect(weakSpotPath.nextStep.kind, TodayNextStepKind.weakSpot);
    expect(weakSpotPath.nextStep.reviewRow?.unit.id, 4);

    final recentPath = TodayPath.from(
      plan: _plan(),
      remainingStage4Due: const <Stage4DueItem>[],
      remainingReviews: <PlannedReviewRow>[
        _review(5,
            bucket: AdaptiveQueueBucket.recentReview,
            reason: AdaptiveReviewReason.recentCheckIn),
      ],
      remainingNewUnits: <MemUnitData>[_unit(34)],
    );
    expect(recentPath.nextStep.kind, TodayNextStepKind.dueReview);
    expect(recentPath.nextStep.reviewRow?.unit.id, 5);

    final maintenancePath = TodayPath.from(
      plan: _plan(),
      remainingStage4Due: const <Stage4DueItem>[],
      remainingReviews: <PlannedReviewRow>[
        _review(6,
            bucket: AdaptiveQueueBucket.maintenance,
            reason: AdaptiveReviewReason.maintenanceDue),
      ],
      remainingNewUnits: <MemUnitData>[_unit(35)],
    );
    expect(maintenancePath.nextStep.kind, TodayNextStepKind.dueReview);
    expect(maintenancePath.nextStep.reviewRow?.unit.id, 6);

    final newPath = TodayPath.from(
      plan: _plan(),
      remainingStage4Due: const <Stage4DueItem>[],
      remainingReviews: const <PlannedReviewRow>[],
      remainingNewUnits: <MemUnitData>[_unit(36)],
    );
    expect(newPath.nextStep.kind, TodayNextStepKind.newUnit);

    final resumePath = TodayPath.from(
      plan: _plan(),
      remainingStage4Due: const <Stage4DueItem>[],
      remainingReviews: const <PlannedReviewRow>[],
      remainingNewUnits: const <MemUnitData>[],
    );
    expect(resumePath.nextStep.kind, TodayNextStepKind.resume);
  });
}

TodayPlan _plan({
  bool recoveryMode = false,
  bool stage4BlocksNewByDefault = false,
  bool revisionOnly = false,
  double reviewPressure = 0.0,
  List<MemUnitData> plannedNewUnits = const <MemUnitData>[],
  TodayNewAvailability newAvailability = TodayNewAvailability.noneAvailable,
  TodayPlanNotice? notice,
}) {
  return TodayPlan(
    plannedReviews: const <PlannedReviewRow>[],
    plannedNewUnits: plannedNewUnits,
    plannedStage4Due: const <Stage4DueItem>[],
    revisionOnly: revisionOnly,
    minutesPlannedReviews: 0,
    minutesPlannedNew: 0,
    stage4BlocksNewByDefault: stage4BlocksNewByDefault,
    stage4QualitySnapshot: const Stage4QualitySnapshot(),
    reviewPressure: reviewPressure,
    recoveryMode: recoveryMode,
    newAvailability: newAvailability,
    notice: notice,
  );
}

PlannedReviewRow _review(
  int id, {
  required AdaptiveQueueBucket bucket,
  required AdaptiveReviewReason reason,
  double reinforcementWeight = 0.0,
}) {
  return PlannedReviewRow(
    unit: _unit(id),
    schedule: ScheduleStateData(
      unitId: id,
      ef: 2.5,
      reps: 3,
      intervalDays: 10,
      dueDay: 100,
      lastReviewDay: 95,
      lastGradeQ: 4,
      lapseCount: 0,
      isSuspended: 0,
    ),
    lifecycleTier: 'stable',
    reinforcementWeight: reinforcementWeight,
    bucket: bucket,
    reason: reason,
  );
}

Stage4DueItem _stage4Due(int id, {bool mandatory = true}) {
  return Stage4DueItem(
    unit: _unit(id),
    lifecycle: CompanionLifecycleStateData(
      unitId: id,
      lifecycleTier: 'ready',
      stage4Status: mandatory ? 'pending' : 'passed',
      stage4MissedCount: 0,
      newOverrideCount: 0,
      updatedAtDay: 100,
      updatedAtSeconds: 120,
    ),
    dueKind: 'next_day_required',
    dueDay: 100,
    mandatory: mandatory,
    overdueDays: 0,
    unresolvedTargetsCount: 1,
  );
}

MemUnitData _unit(int id) {
  return MemUnitData(
    id: id,
    kind: 'page_segment',
    pageMadina: 1,
    startSurah: 1,
    startAyah: id,
    endSurah: 1,
    endAyah: id,
    unitKey: 'unit-$id',
    createdAtDay: 100,
    updatedAtDay: 100,
  );
}
