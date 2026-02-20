import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../time/local_day_time.dart';

class ProgressRepo {
  ProgressRepo(this._db);

  final AppDatabase _db;

  Future<MemProgressData> getCursor() async {
    await _db.ensureSingletonRows();
    return (_db.select(_db.memProgress)..where((tbl) => tbl.id.equals(1)))
        .getSingle();
  }

  Future<bool> updateCursor({
    required int nextSurah,
    required int nextAyah,
    int? updatedAtDay,
  }) async {
    await _db.ensureSingletonRows();
    final rows = await (_db.update(_db.memProgress)
          ..where((tbl) => tbl.id.equals(1)))
        .write(
      MemProgressCompanion(
        nextSurah: Value(nextSurah),
        nextAyah: Value(nextAyah),
        updatedAtDay: Value(
          updatedAtDay ?? localDayIndex(DateTime.now().toLocal()),
        ),
      ),
    );
    return rows > 0;
  }
}
