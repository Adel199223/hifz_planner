import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/schedule_repo.dart';

void main() {
  late AppDatabase db;
  late ScheduleRepo repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ScheduleRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> createUnit(String unitKey) {
    return db.into(db.memUnit).insert(
          MemUnitCompanion.insert(
            kind: 'ayah_range',
            unitKey: unitKey,
            createdAtDay: 20000,
            updatedAtDay: 20000,
          ),
        );
  }

  test('upsertInitialStateForNewUnit inserts once and does not reset state',
      () async {
    final unitId = await createUnit('schedule:upsert');
    await repo.upsertInitialStateForNewUnit(
      unitId: unitId,
      dueDay: 100,
    );

    await repo.updateAfterReview(
      unitId: unitId,
      ef: 2.9,
      reps: 2,
      intervalDays: 7,
      dueDay: 110,
      reviewDay: 103,
      gradeQ: 4,
      lapseCount: 1,
    );

    await repo.upsertInitialStateForNewUnit(
      unitId: unitId,
      dueDay: 999,
      ef: 1.1,
      reps: 0,
      intervalDays: 0,
    );

    final row = await (db.select(db.scheduleState)
          ..where((tbl) => tbl.unitId.equals(unitId)))
        .getSingle();

    expect(row.ef, 2.9);
    expect(row.reps, 2);
    expect(row.intervalDays, 7);
    expect(row.dueDay, 110);
    expect(row.lastReviewDay, 103);
    expect(row.lastGradeQ, 4);
    expect(row.lapseCount, 1);
  });

  test('getDueUnits returns due unsuspended rows sorted by due_day and unit_id',
      () async {
    final unitId1 = await createUnit('schedule:due:1');
    final unitId2 = await createUnit('schedule:due:2');
    final unitId3 = await createUnit('schedule:due:3');
    final unitId4 = await createUnit('schedule:due:4');

    await db.into(db.scheduleState).insert(
          ScheduleStateCompanion.insert(
            unitId: Value(unitId1),
            ef: 2.5,
            reps: 1,
            intervalDays: 1,
            dueDay: 5,
            lapseCount: 0,
          ),
        );
    await db.into(db.scheduleState).insert(
          ScheduleStateCompanion.insert(
            unitId: Value(unitId2),
            ef: 2.5,
            reps: 1,
            intervalDays: 1,
            dueDay: 3,
            lapseCount: 0,
            isSuspended: const Value(1),
          ),
        );
    await db.into(db.scheduleState).insert(
          ScheduleStateCompanion.insert(
            unitId: Value(unitId3),
            ef: 2.5,
            reps: 1,
            intervalDays: 1,
            dueDay: 3,
            lapseCount: 0,
          ),
        );
    await db.into(db.scheduleState).insert(
          ScheduleStateCompanion.insert(
            unitId: Value(unitId4),
            ef: 2.5,
            reps: 1,
            intervalDays: 1,
            dueDay: 7,
            lapseCount: 0,
          ),
        );

    final dueRows = await repo.getDueUnits(5);

    expect(
        dueRows.map((row) => row.schedule.unitId).toList(), [unitId3, unitId1]);
    expect(dueRows.map((row) => row.unit.id).toList(), [unitId3, unitId1]);
    expect(dueRows.every((row) => row.schedule.isSuspended == 0), isTrue);
  });

  test('updateAfterReview writes computed scheduling fields', () async {
    final unitId = await createUnit('schedule:update');
    await repo.upsertInitialStateForNewUnit(unitId: unitId, dueDay: 200);

    final updated = await repo.updateAfterReview(
      unitId: unitId,
      ef: 2.2,
      reps: 4,
      intervalDays: 16,
      dueDay: 216,
      reviewDay: 200,
      gradeQ: 3,
      lapseCount: 2,
    );

    final row = await (db.select(db.scheduleState)
          ..where((tbl) => tbl.unitId.equals(unitId)))
        .getSingle();

    expect(updated, isTrue);
    expect(row.ef, 2.2);
    expect(row.reps, 4);
    expect(row.intervalDays, 16);
    expect(row.dueDay, 216);
    expect(row.lastReviewDay, 200);
    expect(row.lastGradeQ, 3);
    expect(row.lapseCount, 2);
  });

  test('suspend and resume toggle suspension flags', () async {
    final unitId = await createUnit('schedule:suspend');
    await repo.upsertInitialStateForNewUnit(unitId: unitId, dueDay: 300);

    final suspended = await repo.suspend(
      unitId: unitId,
      suspendedAtDay: 301,
    );
    var row = await (db.select(db.scheduleState)
          ..where((tbl) => tbl.unitId.equals(unitId)))
        .getSingle();

    expect(suspended, isTrue);
    expect(row.isSuspended, 1);
    expect(row.suspendedAtDay, 301);

    final resumed = await repo.resume(unitId);
    row = await (db.select(db.scheduleState)
          ..where((tbl) => tbl.unitId.equals(unitId)))
        .getSingle();

    expect(resumed, isTrue);
    expect(row.isSuspended, 0);
    expect(row.suspendedAtDay, isNull);
  });

  test('applyReviewWithScheduler computes and persists next state', () async {
    final unitId = await createUnit('schedule:apply-wrapper');
    await repo.upsertInitialStateForNewUnit(
      unitId: unitId,
      dueDay: 10,
      ef: 2.5,
      reps: 0,
      intervalDays: 0,
    );

    final updated = await repo.applyReviewWithScheduler(
      unitId: unitId,
      todayDay: 50,
      gradeQ: 5,
    );
    final row = await (db.select(db.scheduleState)
          ..where((tbl) => tbl.unitId.equals(unitId)))
        .getSingle();

    expect(updated, isTrue);
    expect(row.ef, 2.6);
    expect(row.reps, 1);
    expect(row.intervalDays, 1);
    expect(row.dueDay, 51);
    expect(row.lastReviewDay, 50);
    expect(row.lastGradeQ, 5);
    expect(row.lapseCount, 0);
  });

  test('applyReviewWithScheduler returns false when state row is missing',
      () async {
    final unitId = await createUnit('schedule:no-state');

    final updated = await repo.applyReviewWithScheduler(
      unitId: unitId,
      todayDay: 50,
      gradeQ: 5,
    );

    expect(updated, isFalse);
  });
}
