import 'package:drift/drift.dart';

import '../database/app_database.dart';

class QuranRepo {
  QuranRepo(this._db);

  final AppDatabase _db;

  Future<List<AyahData>> getAyahsBySurah(int surah) {
    final query = _db.select(_db.ayah)
      ..where((tbl) => tbl.surah.equals(surah))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.ayah)]);
    return query.get();
  }

  Future<List<AyahData>> searchAyahs(String query, {int limit = 50}) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return Future.value(const <AyahData>[]);
    }

    final escaped = normalized
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
    final pattern = '%$escaped%';

    final selectQuery = _db.select(_db.ayah)
      ..where((tbl) => tbl.textUthmani.like(pattern, escape: '\\'))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.surah),
        (tbl) => OrderingTerm.asc(tbl.ayah),
      ])
      ..limit(limit);

    return selectQuery.get();
  }

  Future<AyahData?> getAyah(int surah, int ayah) {
    final query = _db.select(_db.ayah)
      ..where((tbl) => tbl.surah.equals(surah) & tbl.ayah.equals(ayah));
    return query.getSingleOrNull();
  }
}
