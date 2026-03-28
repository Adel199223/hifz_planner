import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/companion_repo.dart';
import 'package:hifz_planner/data/repositories/review_log_repo.dart';
import 'package:hifz_planner/data/repositories/schedule_repo.dart';
import 'package:hifz_planner/data/services/adaptive_queue_policy.dart';
import 'package:hifz_planner/data/services/review_completion_service.dart';

void main() {
  late AppDatabase db;
  late ReviewCompletionService reviewCompletionService;
  late CompanionRepo companionRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    reviewCompletionService = ReviewCompletionService(
      db,
      ReviewLogRepo(db),
      ScheduleRepo(db),
      CompanionRepo(db),
    );
    companionRepo = CompanionRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('completeScheduledReview writes review log and advances schedule',
      () async {
    final unitId = await _seedReviewUnit(db, unitKey: 'review-complete-a');

    final result = await reviewCompletionService.completeScheduledReview(
      unitId: unitId,
      gradeQ: 5,
      completedDay: 100,
      completedSeconds: 320,
    );

    expect(result.scheduleUpdated, isTrue);
    expect(result.promotedToMaintained, isFalse);
    expect(result.lifecycleTierBefore, isNull);
    expect(result.lifecycleTierAfter, 'ready');
    expect(result.lifecycleTransition, ReviewLifecycleTransition.unchanged);
    final lifecycle = await companionRepo.getLifecycleState(unitId);
    final adaptiveState =
        (await companionRepo.getAdaptiveStatesByUnitIds(<int>[unitId]))[unitId];
    expect(lifecycle, isNotNull);
    expect(lifecycle!.lifecycleTier, 'ready');
    expect(adaptiveState, isNotNull);
    expect(adaptiveState!.weakSpotScore, 0.0);
    expect(adaptiveState.recentStruggleCount, 0);
    expect(adaptiveState.lastErrorType, isNull);

    final logs = await (db.select(db.reviewLog)
          ..where((tbl) => tbl.unitId.equals(unitId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
        .get();
    expect(logs, hasLength(1));
    expect(logs.single.gradeQ, 5);
    expect(logs.single.tsDay, 100);
    expect(logs.single.tsSeconds, 320);

    final schedule = await (db.select(db.scheduleState)
          ..where((tbl) => tbl.unitId.equals(unitId)))
        .getSingle();
    expect(schedule.lastGradeQ, 5);
    expect(schedule.lastReviewDay, 100);
    expect(schedule.dueDay, 101);
  });

  test('promotes stable lifecycle units to maintained on successful review',
      () async {
    final unitId = await _seedReviewUnit(db, unitKey: 'review-complete-b');
    await _seedLifecycleState(
      companionRepo,
      unitId: unitId,
      lifecycleTier: 'stable',
    );

    final result = await reviewCompletionService.completeScheduledReview(
      unitId: unitId,
      gradeQ: 4,
      completedDay: 100,
      completedSeconds: 400,
    );

    expect(result.scheduleUpdated, isTrue);
    expect(result.promotedToMaintained, isTrue);
    expect(result.lifecycleTierBefore, 'stable');
    expect(result.lifecycleTierAfter, 'maintained');
    expect(result.lifecycleTransition,
        ReviewLifecycleTransition.promotedToMaintained);

    final lifecycle = await companionRepo.getLifecycleState(unitId);
    expect(lifecycle, isNotNull);
    expect(lifecycle!.lifecycleTier, 'maintained');
    expect(lifecycle.stage4Status, 'passed');
    expect(lifecycle.updatedAtDay, 100);
    expect(lifecycle.updatedAtSeconds, 400);
  });

  test('keeps maintained lifecycle units on strong scheduled reviews',
      () async {
    final unitId = await _seedReviewUnit(db, unitKey: 'review-complete-c');
    await _seedLifecycleState(
      companionRepo,
      unitId: unitId,
      lifecycleTier: 'maintained',
    );

    final result = await reviewCompletionService.completeScheduledReview(
      unitId: unitId,
      gradeQ: 4,
      completedDay: 100,
      completedSeconds: 500,
    );

    expect(result.scheduleUpdated, isTrue);
    expect(result.promotedToMaintained, isFalse);
    expect(result.lifecycleTierBefore, 'maintained');
    expect(result.lifecycleTierAfter, 'maintained');
    expect(result.lifecycleTransition, ReviewLifecycleTransition.unchanged);

    final lifecycle = await companionRepo.getLifecycleState(unitId);
    expect(lifecycle, isNotNull);
    expect(lifecycle!.lifecycleTier, 'maintained');
    expect(lifecycle.stage4Status, 'passed');
  });

  test('demotes maintained lifecycle units to stable on q=3 review', () async {
    final unitId = await _seedReviewUnit(db, unitKey: 'review-complete-d');
    await _seedLifecycleState(
      companionRepo,
      unitId: unitId,
      lifecycleTier: 'maintained',
    );

    final result = await reviewCompletionService.completeScheduledReview(
      unitId: unitId,
      gradeQ: 3,
      completedDay: 100,
      completedSeconds: 520,
    );

    expect(result.scheduleUpdated, isTrue);
    expect(result.lifecycleTierBefore, 'maintained');
    expect(result.lifecycleTierAfter, 'stable');
    expect(
        result.lifecycleTransition, ReviewLifecycleTransition.demotedToStable);

    final lifecycle = await companionRepo.getLifecycleState(unitId);
    expect(lifecycle, isNotNull);
    expect(lifecycle!.lifecycleTier, 'stable');
    expect(lifecycle.stage4Status, 'passed');
  });

  test('demotes stable lifecycle units to ready on failing review', () async {
    final unitId = await _seedReviewUnit(db, unitKey: 'review-complete-e');
    await _seedLifecycleState(
      companionRepo,
      unitId: unitId,
      lifecycleTier: 'stable',
    );

    final result = await reviewCompletionService.completeScheduledReview(
      unitId: unitId,
      gradeQ: 0,
      completedDay: 100,
      completedSeconds: 540,
    );

    expect(result.scheduleUpdated, isTrue);
    expect(result.lifecycleTierBefore, 'stable');
    expect(result.lifecycleTierAfter, 'ready');
    expect(
        result.lifecycleTransition, ReviewLifecycleTransition.demotedToReady);

    final lifecycle = await companionRepo.getLifecycleState(unitId);
    expect(lifecycle, isNotNull);
    expect(lifecycle!.lifecycleTier, 'ready');
    expect(lifecycle.stage4Status, 'passed');
  });

  test('ready lifecycle units do not auto-promote on scheduled reviews',
      () async {
    final unitId = await _seedReviewUnit(db, unitKey: 'review-complete-f');
    await _seedLifecycleState(
      companionRepo,
      unitId: unitId,
      lifecycleTier: 'ready',
    );

    final result = await reviewCompletionService.completeScheduledReview(
      unitId: unitId,
      gradeQ: 5,
      completedDay: 100,
      completedSeconds: 560,
    );

    expect(result.scheduleUpdated, isTrue);
    expect(result.lifecycleTierBefore, 'ready');
    expect(result.lifecycleTierAfter, 'ready');
    expect(result.lifecycleTransition, ReviewLifecycleTransition.unchanged);

    final lifecycle = await companionRepo.getLifecycleState(unitId);
    expect(lifecycle, isNotNull);
    expect(lifecycle!.lifecycleTier, 'ready');
    expect(lifecycle.stage4Status, 'passed');
  });

  test('q5 strongly lowers weak spot pressure and clears last error', () async {
    final unitId = await _seedReviewUnit(db, unitKey: 'adaptive-q5');
    await _seedLifecycleState(
      companionRepo,
      unitId: unitId,
      lifecycleTier: 'ready',
      weakSpotScore: 0.80,
      recentStruggleCount: 3,
      lastErrorType: 'hesitation',
    );

    await reviewCompletionService.completeScheduledReview(
      unitId: unitId,
      gradeQ: 5,
      completedDay: 100,
      completedSeconds: 580,
    );

    final lifecycle = await companionRepo.getLifecycleState(unitId);
    final adaptiveState =
        (await companionRepo.getAdaptiveStatesByUnitIds(<int>[unitId]))[unitId];
    expect(lifecycle, isNotNull);
    expect(adaptiveState, isNotNull);
    expect(adaptiveState!.weakSpotScore, closeTo(0.45, 0.0001));
    expect(adaptiveState.recentStruggleCount, 1);
    expect(adaptiveState.lastErrorType, isNull);
  });

  test('q4 moderately lowers weak spot pressure and clears last error',
      () async {
    final unitId = await _seedReviewUnit(db, unitKey: 'adaptive-q4');
    await _seedLifecycleState(
      companionRepo,
      unitId: unitId,
      lifecycleTier: 'ready',
      weakSpotScore: 0.30,
      recentStruggleCount: 1,
      lastErrorType: 'wrong_recall',
    );

    await reviewCompletionService.completeScheduledReview(
      unitId: unitId,
      gradeQ: 4,
      completedDay: 100,
      completedSeconds: 600,
    );

    final lifecycle = await companionRepo.getLifecycleState(unitId);
    final adaptiveState =
        (await companionRepo.getAdaptiveStatesByUnitIds(<int>[unitId]))[unitId];
    expect(lifecycle, isNotNull);
    expect(adaptiveState, isNotNull);
    expect(adaptiveState!.weakSpotScore, closeTo(0.10, 0.0001));
    expect(adaptiveState.recentStruggleCount, 0);
    expect(adaptiveState.lastErrorType, isNull);
  });

  test('q3 keeps a cautious struggle count while easing weak spot score',
      () async {
    final unitId = await _seedReviewUnit(db, unitKey: 'adaptive-q3');
    await _seedLifecycleState(
      companionRepo,
      unitId: unitId,
      lifecycleTier: 'ready',
      weakSpotScore: 0.20,
      recentStruggleCount: 2,
      lastErrorType: 'wrong_recall',
    );

    await reviewCompletionService.completeScheduledReview(
      unitId: unitId,
      gradeQ: 3,
      completedDay: 100,
      completedSeconds: 620,
    );

    final lifecycle = await companionRepo.getLifecycleState(unitId);
    final adaptiveState =
        (await companionRepo.getAdaptiveStatesByUnitIds(<int>[unitId]))[unitId];
    expect(lifecycle, isNotNull);
    expect(adaptiveState, isNotNull);
    expect(adaptiveState!.weakSpotScore, closeTo(0.15, 0.0001));
    expect(adaptiveState.recentStruggleCount, 2);
    expect(adaptiveState.lastErrorType, isNull);
  });

  test('q2 raises weak spot pressure and records hesitation', () async {
    final unitId = await _seedReviewUnit(db, unitKey: 'adaptive-q2');
    await _seedLifecycleState(
      companionRepo,
      unitId: unitId,
      lifecycleTier: 'ready',
      weakSpotScore: 0.10,
      recentStruggleCount: 0,
    );

    await reviewCompletionService.completeScheduledReview(
      unitId: unitId,
      gradeQ: 2,
      completedDay: 100,
      completedSeconds: 640,
    );

    final lifecycle = await companionRepo.getLifecycleState(unitId);
    final adaptiveState =
        (await companionRepo.getAdaptiveStatesByUnitIds(<int>[unitId]))[unitId];
    expect(lifecycle, isNotNull);
    expect(adaptiveState, isNotNull);
    expect(adaptiveState!.weakSpotScore, closeTo(0.30, 0.0001));
    expect(adaptiveState.recentStruggleCount, 1);
    expect(adaptiveState.lastErrorType, AdaptiveLastErrorType.hesitation);
  });

  test('q0 sharply raises weak spot pressure and records wrong recall',
      () async {
    final unitId = await _seedReviewUnit(db, unitKey: 'adaptive-q0');
    await _seedLifecycleState(
      companionRepo,
      unitId: unitId,
      lifecycleTier: 'ready',
      weakSpotScore: 0.80,
      recentStruggleCount: 1,
    );

    await reviewCompletionService.completeScheduledReview(
      unitId: unitId,
      gradeQ: 0,
      completedDay: 100,
      completedSeconds: 660,
    );

    final lifecycle = await companionRepo.getLifecycleState(unitId);
    final adaptiveState =
        (await companionRepo.getAdaptiveStatesByUnitIds(<int>[unitId]))[unitId];
    expect(lifecycle, isNotNull);
    expect(adaptiveState, isNotNull);
    expect(adaptiveState!.weakSpotScore, 1.0);
    expect(adaptiveState.recentStruggleCount, 3);
    expect(adaptiveState.lastErrorType, AdaptiveLastErrorType.wrongRecall);
  });

  test('q2 can store explicit similar-verse confusion', () async {
    final unitId = await _seedReviewUnit(
      db,
      unitKey: 'adaptive-q2-similar-confusion',
    );
    await _seedLifecycleState(
      companionRepo,
      unitId: unitId,
      lifecycleTier: 'ready',
      weakSpotScore: 0.10,
      recentStruggleCount: 0,
    );

    await reviewCompletionService.completeScheduledReview(
      unitId: unitId,
      gradeQ: 2,
      taggedErrorType: AdaptiveLastErrorType.similarConfusion,
      completedDay: 100,
      completedSeconds: 670,
    );

    final adaptiveState =
        (await companionRepo.getAdaptiveStatesByUnitIds(<int>[unitId]))[unitId];
    expect(adaptiveState, isNotNull);
    expect(adaptiveState!.lastErrorType,
        AdaptiveLastErrorType.similarConfusion);
  });

  test('q2 can store explicit weak lock-in', () async {
    final unitId = await _seedReviewUnit(
      db,
      unitKey: 'adaptive-q2-weak-lock-in',
    );
    await _seedLifecycleState(
      companionRepo,
      unitId: unitId,
      lifecycleTier: 'ready',
      weakSpotScore: 0.10,
      recentStruggleCount: 0,
    );

    await reviewCompletionService.completeScheduledReview(
      unitId: unitId,
      gradeQ: 2,
      taggedErrorType: AdaptiveLastErrorType.weakLockIn,
      completedDay: 100,
      completedSeconds: 675,
    );

    final adaptiveState =
        (await companionRepo.getAdaptiveStatesByUnitIds(<int>[unitId]))[unitId];
    expect(adaptiveState, isNotNull);
    expect(adaptiveState!.lastErrorType, AdaptiveLastErrorType.weakLockIn);
  });

  test('q0 can store explicit similar-verse confusion', () async {
    final unitId = await _seedReviewUnit(
      db,
      unitKey: 'adaptive-q0-similar-confusion',
    );
    await _seedLifecycleState(
      companionRepo,
      unitId: unitId,
      lifecycleTier: 'ready',
      weakSpotScore: 0.60,
      recentStruggleCount: 1,
    );

    await reviewCompletionService.completeScheduledReview(
      unitId: unitId,
      gradeQ: 0,
      taggedErrorType: AdaptiveLastErrorType.similarConfusion,
      completedDay: 100,
      completedSeconds: 678,
    );

    final adaptiveState =
        (await companionRepo.getAdaptiveStatesByUnitIds(<int>[unitId]))[unitId];
    expect(adaptiveState, isNotNull);
    expect(adaptiveState!.lastErrorType,
        AdaptiveLastErrorType.similarConfusion);
  });

  test('first-time q3 review seeds a ready lifecycle row for adaptive state',
      () async {
    final unitId = await _seedReviewUnit(db, unitKey: 'adaptive-first-q3');

    final result = await reviewCompletionService.completeScheduledReview(
      unitId: unitId,
      gradeQ: 3,
      completedDay: 100,
      completedSeconds: 680,
    );

    expect(result.lifecycleTierBefore, isNull);
    expect(result.lifecycleTierAfter, 'ready');
    expect(result.lifecycleTransition, ReviewLifecycleTransition.unchanged);

    final lifecycle = await companionRepo.getLifecycleState(unitId);
    final adaptiveState =
        (await companionRepo.getAdaptiveStatesByUnitIds(<int>[unitId]))[unitId];
    expect(lifecycle, isNotNull);
    expect(lifecycle!.lifecycleTier, 'ready');
    expect(adaptiveState, isNotNull);
    expect(adaptiveState!.weakSpotScore, 0.0);
    expect(adaptiveState.recentStruggleCount, 0);
    expect(adaptiveState.lastErrorType, isNull);
  });

  test('mature schedule-only unit adopts stable on a strong scheduled review',
      () async {
    final unitId = await _seedReviewUnit(
      db,
      unitKey: 'legacy-mature-q4',
      reps: 3,
      intervalDays: 10,
      lastReviewDay: 90,
      lastGradeQ: 4,
    );

    final result = await reviewCompletionService.completeScheduledReview(
      unitId: unitId,
      gradeQ: 4,
      completedDay: 100,
      completedSeconds: 700,
    );

    final lifecycle = await companionRepo.getLifecycleState(unitId);
    expect(result.lifecycleTierBefore, isNull);
    expect(result.lifecycleTierAfter, 'stable');
    expect(result.lifecycleTransition, ReviewLifecycleTransition.unchanged);
    expect(lifecycle, isNotNull);
    expect(lifecycle!.lifecycleTier, 'stable');
  });

  test('mature schedule-only unit still returns to ready on weak review',
      () async {
    final unitId = await _seedReviewUnit(
      db,
      unitKey: 'legacy-mature-q2',
      reps: 3,
      intervalDays: 10,
      lastReviewDay: 90,
      lastGradeQ: 4,
    );

    final result = await reviewCompletionService.completeScheduledReview(
      unitId: unitId,
      gradeQ: 2,
      completedDay: 100,
      completedSeconds: 720,
    );

    final lifecycle = await companionRepo.getLifecycleState(unitId);
    expect(result.lifecycleTierBefore, isNull);
    expect(result.lifecycleTierAfter, 'ready');
    expect(result.lifecycleTransition, ReviewLifecycleTransition.unchanged);
    expect(lifecycle, isNotNull);
    expect(lifecycle!.lifecycleTier, 'ready');
  });

  test(
      'fake-ready legacy row without stage4 history adopts stable on strong review',
      () async {
    final unitId = await _seedReviewUnit(
      db,
      unitKey: 'legacy-fake-ready-q5',
      reps: 3,
      intervalDays: 10,
      lastReviewDay: 90,
      lastGradeQ: 4,
    );
    await _seedLifecycleState(
      companionRepo,
      unitId: unitId,
      lifecycleTier: 'ready',
      stage4Status: 'none',
      stage4LastCompletedDay: null,
    );

    final result = await reviewCompletionService.completeScheduledReview(
      unitId: unitId,
      gradeQ: 5,
      completedDay: 100,
      completedSeconds: 740,
    );

    final lifecycle = await companionRepo.getLifecycleState(unitId);
    expect(result.lifecycleTierBefore, 'ready');
    expect(result.lifecycleTierAfter, 'stable');
    expect(result.lifecycleTransition, ReviewLifecycleTransition.unchanged);
    expect(lifecycle, isNotNull);
    expect(lifecycle!.lifecycleTier, 'stable');
    expect(lifecycle.stage4Status, 'none');
  });
}

Future<int> _seedReviewUnit(
  AppDatabase db, {
  required String unitKey,
  int reps = 0,
  int intervalDays = 0,
  int dueDay = 99,
  int lapseCount = 0,
  int? lastReviewDay,
  int? lastGradeQ,
}) async {
  final unitId = await db.into(db.memUnit).insert(
        MemUnitCompanion.insert(
          kind: 'ayah_range',
          unitKey: unitKey,
          startSurah: const Value(1),
          startAyah: const Value(1),
          endSurah: const Value(1),
          endAyah: const Value(1),
          createdAtDay: 100,
          updatedAtDay: 100,
        ),
      );

  await db.into(db.scheduleState).insert(
        ScheduleStateCompanion.insert(
          unitId: Value(unitId),
          ef: 2.5,
          reps: reps,
          intervalDays: intervalDays,
          dueDay: dueDay,
          lastReviewDay: Value(lastReviewDay),
          lastGradeQ: Value(lastGradeQ),
          lapseCount: lapseCount,
        ),
      );

  return unitId;
}

Future<void> _seedLifecycleState(
  CompanionRepo companionRepo, {
  required int unitId,
  required String lifecycleTier,
  double weakSpotScore = 0.0,
  int recentStruggleCount = 0,
  String? lastErrorType,
  String stage4Status = 'passed',
  int? stage4LastCompletedDay = 99,
}) async {
  await companionRepo.upsertLifecycleState(
    unitId: unitId,
    lifecycleTier: Value(lifecycleTier),
    stage4Status: Value(stage4Status),
    stage4LastCompletedDay: Value(stage4LastCompletedDay),
    updatedAtDay: 99,
    updatedAtSeconds: 200,
  );
  await companionRepo.writeAdaptiveState(
    unitId: unitId,
    weakSpotScore: weakSpotScore,
    recentStruggleCount: recentStruggleCount,
    lastErrorType: lastErrorType,
    updatedAtDay: 99,
    updatedAtSeconds: 200,
    seedLifecycleTier: lifecycleTier,
  );
}
