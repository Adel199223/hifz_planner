import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../services/spaced_repetition_scheduler.dart';

class DueUnitRow {
  const DueUnitRow({
    required this.unit,
    required this.schedule,
  });

  final MemUnitData unit;
  final ScheduleStateData schedule;
}

class ScheduleRepo {
  ScheduleRepo(this._db);

  final AppDatabase _db;

  Future<List<DueUnitRow>> getDueUnits(int todayDay) async {
    final query = _db.select(_db.scheduleState).join([
      innerJoin(
        _db.memUnit,
        _db.memUnit.id.equalsExp(_db.scheduleState.unitId),
      ),
    ])
      ..where(
        _db.scheduleState.dueDay.isSmallerOrEqualValue(todayDay) &
            _db.scheduleState.isSuspended.equals(0),
      )
      ..orderBy([
        OrderingTerm.asc(_db.scheduleState.dueDay),
        OrderingTerm.asc(_db.scheduleState.unitId),
      ]);

    final rows = await query.get();
    return rows
        .map(
          (row) => DueUnitRow(
            unit: row.readTable(_db.memUnit),
            schedule: row.readTable(_db.scheduleState),
          ),
        )
        .toList();
  }

  Future<void> upsertInitialStateForNewUnit({
    required int unitId,
    required int dueDay,
    double ef = 2.5,
    int reps = 0,
    int intervalDays = 0,
  }) async {
    await _db.into(_db.scheduleState).insert(
          ScheduleStateCompanion.insert(
            unitId: Value(unitId),
            ef: ef,
            reps: reps,
            intervalDays: intervalDays,
            dueDay: dueDay,
            lapseCount: 0,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<bool> updateAfterReview({
    required int unitId,
    required double ef,
    required int reps,
    required int intervalDays,
    required int dueDay,
    required int reviewDay,
    required int gradeQ,
    required int lapseCount,
  }) async {
    final rows = await (_db.update(_db.scheduleState)
          ..where((tbl) => tbl.unitId.equals(unitId)))
        .write(
      ScheduleStateCompanion(
        ef: Value(ef),
        reps: Value(reps),
        intervalDays: Value(intervalDays),
        dueDay: Value(dueDay),
        lastReviewDay: Value(reviewDay),
        lastGradeQ: Value(gradeQ),
        lapseCount: Value(lapseCount),
      ),
    );
    return rows > 0;
  }

  Future<bool> suspend({
    required int unitId,
    required int suspendedAtDay,
  }) async {
    final rows = await (_db.update(_db.scheduleState)
          ..where((tbl) => tbl.unitId.equals(unitId)))
        .write(
      ScheduleStateCompanion(
        isSuspended: const Value(1),
        suspendedAtDay: Value(suspendedAtDay),
      ),
    );
    return rows > 0;
  }

  Future<bool> resume(int unitId) async {
    final rows = await (_db.update(_db.scheduleState)
          ..where((tbl) => tbl.unitId.equals(unitId)))
        .write(
      const ScheduleStateCompanion(
        isSuspended: Value(0),
        suspendedAtDay: Value(null),
      ),
    );
    return rows > 0;
  }

  Future<bool> applyReviewWithScheduler({
    required int unitId,
    required int todayDay,
    required int gradeQ,
  }) async {
    final current = await (_db.select(_db.scheduleState)
          ..where((tbl) => tbl.unitId.equals(unitId))
          ..limit(1))
        .getSingleOrNull();

    if (current == null) {
      return false;
    }

    final computed = computeNextSchedule(
      currentState: _toSchedulerInput(current),
      todayDay: todayDay,
      gradeQ: gradeQ,
    );

    return updateAfterReview(
      unitId: unitId,
      ef: computed.ef,
      reps: computed.reps,
      intervalDays: computed.intervalDays,
      dueDay: computed.dueDay,
      reviewDay: computed.lastReviewDay,
      gradeQ: computed.lastGradeQ,
      lapseCount: computed.lapseCount,
    );
  }

  SchedulerStateInput _toSchedulerInput(ScheduleStateData row) {
    return SchedulerStateInput(
      ef: row.ef,
      reps: row.reps,
      intervalDays: row.intervalDays,
      dueDay: row.dueDay,
      lapseCount: row.lapseCount,
    );
  }
}
