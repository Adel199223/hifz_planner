import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/review_log_repo.dart';

void main() {
  late AppDatabase db;
  late ReviewLogRepo repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ReviewLogRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> createUnit(String key) {
    return db.into(db.memUnit).insert(
          MemUnitCompanion.insert(
            kind: 'ayah_range',
            unitKey: key,
            createdAtDay: 20000,
            updatedAtDay: 20000,
          ),
        );
  }

  test('insert creates review log rows', () async {
    final unitId = await createUnit('review:insert');
    final insertedId = await repo.insert(
      unitId: unitId,
      tsDay: 21000,
      tsSeconds: 100,
      gradeQ: 5,
      durationSeconds: 45,
      mistakesCount: 0,
    );

    final row = await (db.select(db.reviewLog)
          ..where((tbl) => tbl.id.equals(insertedId)))
        .getSingle();

    expect(row.unitId, unitId);
    expect(row.tsDay, 21000);
    expect(row.tsSeconds, 100);
    expect(row.gradeQ, 5);
    expect(row.durationSeconds, 45);
    expect(row.mistakesCount, 0);
  });

  test('getHistoryForUnit orders by ts_day desc, ts_seconds desc, id desc',
      () async {
    final unitId = await createUnit('review:history');

    final id1 = await repo.insert(
      unitId: unitId,
      tsDay: 100,
      tsSeconds: 30,
      gradeQ: 5,
    );
    final id2 = await repo.insert(
      unitId: unitId,
      tsDay: 101,
      tsSeconds: 5,
      gradeQ: 4,
    );
    final id3 = await repo.insert(
      unitId: unitId,
      tsDay: 101,
      tsSeconds: 5,
      gradeQ: 3,
    );
    final id4 = await repo.insert(
      unitId: unitId,
      tsDay: 101,
      tsSeconds: 15,
      gradeQ: 2,
    );
    final id5 = await repo.insert(
      unitId: unitId,
      tsDay: 101,
      gradeQ: 0,
    );

    final history = await repo.getHistoryForUnit(unitId);

    expect(
      history.map((row) => row.id).toList(),
      [id4, id3, id2, id5, id1],
    );

    final limited = await repo.getHistoryForUnit(unitId, limit: 3);
    expect(limited.map((row) => row.id).toList(), [id4, id3, id2]);
  });
}
