import 'package:drift/drift.dart';

import '../database/app_database.dart';

class ReviewLogRepo {
  ReviewLogRepo(this._db);

  final AppDatabase _db;

  Future<int> insert({
    required int unitId,
    required int tsDay,
    int? tsSeconds,
    required int gradeQ,
    int? durationSeconds,
    int? mistakesCount,
  }) {
    return _db.into(_db.reviewLog).insert(
          ReviewLogCompanion.insert(
            unitId: unitId,
            tsDay: tsDay,
            gradeQ: gradeQ,
            tsSeconds: Value(tsSeconds),
            durationSeconds: Value(durationSeconds),
            mistakesCount: Value(mistakesCount),
          ),
        );
  }

  Future<List<ReviewLogData>> getHistoryForUnit(int unitId, {int? limit}) {
    final query = _db.select(_db.reviewLog)
      ..where((tbl) => tbl.unitId.equals(unitId))
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.tsDay),
        (tbl) => OrderingTerm.desc(tbl.tsSeconds),
        (tbl) => OrderingTerm.desc(tbl.id),
      ]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.get();
  }
}
