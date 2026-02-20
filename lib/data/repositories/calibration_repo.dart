import 'package:drift/drift.dart';

import '../database/app_database.dart';

class CalibrationRepo {
  CalibrationRepo(this._db);

  final AppDatabase _db;

  Future<int> insertSample({
    required String sampleKind,
    required int durationSeconds,
    required int ayahCount,
    required int createdAtDay,
    int? createdAtSeconds,
  }) {
    return _db.into(_db.calibrationSample).insert(
          CalibrationSampleCompanion.insert(
            sampleKind: sampleKind,
            durationSeconds: durationSeconds,
            ayahCount: ayahCount,
            createdAtDay: createdAtDay,
            createdAtSeconds: Value(createdAtSeconds),
          ),
        );
  }

  Future<List<CalibrationSampleData>> getRecentSamples({
    required String sampleKind,
    int limit = 30,
  }) {
    final query = _db.select(_db.calibrationSample)
      ..where((tbl) => tbl.sampleKind.equals(sampleKind))
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.createdAtDay),
        (tbl) => OrderingTerm.desc(tbl.createdAtSeconds),
        (tbl) => OrderingTerm.desc(tbl.id),
      ])
      ..limit(limit);

    return query.get();
  }
}
