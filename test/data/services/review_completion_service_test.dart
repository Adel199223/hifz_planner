import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/companion_repo.dart';
import 'package:hifz_planner/data/repositories/review_log_repo.dart';
import 'package:hifz_planner/data/repositories/schedule_repo.dart';
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
    expect(result.lifecycleTierAfter, isNull);
    expect(result.lifecycleTransition, ReviewLifecycleTransition.unchanged);

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
}

Future<int> _seedReviewUnit(
  AppDatabase db, {
  required String unitKey,
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
          reps: 0,
          intervalDays: 0,
          dueDay: 99,
          lapseCount: 0,
        ),
      );

  return unitId;
}

Future<void> _seedLifecycleState(
  CompanionRepo companionRepo, {
  required int unitId,
  required String lifecycleTier,
}) {
  return companionRepo.upsertLifecycleState(
    unitId: unitId,
    lifecycleTier: Value(lifecycleTier),
    stage4Status: const Value('passed'),
    stage4LastCompletedDay: const Value(99),
    updatedAtDay: 99,
    updatedAtSeconds: 200,
  );
}
