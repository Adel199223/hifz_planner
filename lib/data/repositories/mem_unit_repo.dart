import 'package:drift/drift.dart';

import '../database/app_database.dart';

class MemUnitRepo {
  MemUnitRepo(this._db);

  final AppDatabase _db;

  Future<int> create(MemUnitCompanion unit) {
    return _db.into(_db.memUnit).insert(unit);
  }

  Future<MemUnitData?> get(int id) {
    final query = _db.select(_db.memUnit)..where((tbl) => tbl.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<List<MemUnitData>> list() {
    final query = _db.select(_db.memUnit)
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]);
    return query.get();
  }

  Future<MemUnitData> ensureUniqueByUnitKey(MemUnitCompanion unit) {
    if (!unit.unitKey.present) {
      throw ArgumentError.value(
        unit.unitKey,
        'unit.unitKey',
        'unitKey must be present',
      );
    }

    final unitKey = unit.unitKey.value;

    return _db.transaction(() async {
      final existing = await (_db.select(_db.memUnit)
            ..where((tbl) => tbl.unitKey.equals(unitKey))
            ..limit(1))
          .getSingleOrNull();

      if (existing != null) {
        return existing;
      }

      final insertedId = await create(unit);
      final inserted = await get(insertedId);
      if (inserted == null) {
        throw StateError(
          'Failed to read mem_unit row after insert for unit_key=$unitKey',
        );
      }
      return inserted;
    });
  }
}
