import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/calibration_repo.dart';

void main() {
  late AppDatabase db;
  late CalibrationRepo repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = CalibrationRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('insertSample persists calibration sample row', () async {
    final id = await repo.insertSample(
      sampleKind: 'new_memorization',
      durationSeconds: 180,
      ayahCount: 3,
      createdAtDay: 100,
      createdAtSeconds: 3600,
    );

    final row = await (db.select(db.calibrationSample)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();

    expect(row.sampleKind, 'new_memorization');
    expect(row.durationSeconds, 180);
    expect(row.ayahCount, 3);
    expect(row.createdAtDay, 100);
    expect(row.createdAtSeconds, 3600);
  });

  test('getRecentSamples filters by kind and applies ordering/limit', () async {
    for (var i = 0; i < 5; i++) {
      await repo.insertSample(
        sampleKind: 'new_memorization',
        durationSeconds: 60 * (i + 1),
        ayahCount: 1,
        createdAtDay: 200 + i,
        createdAtSeconds: i,
      );
    }
    await repo.insertSample(
      sampleKind: 'review',
      durationSeconds: 300,
      ayahCount: 2,
      createdAtDay: 999,
      createdAtSeconds: 10,
    );

    final recent = await repo.getRecentSamples(
      sampleKind: 'new_memorization',
      limit: 3,
    );

    expect(recent.length, 3);
    expect(recent.every((row) => row.sampleKind == 'new_memorization'), isTrue);
    expect(recent.map((row) => row.createdAtDay).toList(), [204, 203, 202]);
  });
}
