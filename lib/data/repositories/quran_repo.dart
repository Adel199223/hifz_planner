import 'package:drift/drift.dart';

import '../database/app_database.dart';

class QuranRepo {
  QuranRepo(this._db);

  final AppDatabase _db;

  Future<List<int>> getPagesAvailable() async {
    final query = _db.selectOnly(
      _db.ayah,
      distinct: true,
    )
      ..addColumns([_db.ayah.pageMadina])
      ..where(_db.ayah.pageMadina.isNotNull())
      ..orderBy([OrderingTerm.asc(_db.ayah.pageMadina)]);

    final rows = await query.get();
    return rows
        .map((row) => row.read(_db.ayah.pageMadina))
        .whereType<int>()
        .toList();
  }

  Future<List<AyahData>> getAyahsBySurah(int surah) {
    final query = _db.select(_db.ayah)
      ..where((tbl) => tbl.surah.equals(surah))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.ayah)]);
    return query.get();
  }

  Future<List<AyahData>> getAyahsByPage(int page) {
    final query = _db.select(_db.ayah)
      ..where((tbl) => tbl.pageMadina.equals(page))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.surah),
        (tbl) => OrderingTerm.asc(tbl.ayah),
      ]);
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
      ..where((tbl) => tbl.textUthmani.like(pattern, escapeChar: '\\'))
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

  Future<List<AyahData>> getAyahsFromCursor({
    required int startSurah,
    required int startAyah,
    int? limit,
  }) {
    final query = _db.select(_db.ayah)
      ..where(
        (tbl) =>
            tbl.surah.isBiggerThanValue(startSurah) |
            (tbl.surah.equals(startSurah) &
                tbl.ayah.isBiggerOrEqualValue(startAyah)),
      )
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.surah),
        (tbl) => OrderingTerm.asc(tbl.ayah),
      ]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.get();
  }

  Future<int> countAyahsInRange({
    required int startSurah,
    required int startAyah,
    required int endSurah,
    required int endAyah,
  }) async {
    final startsAfterEnd = (startSurah > endSurah) ||
        (startSurah == endSurah && startAyah > endAyah);
    if (startsAfterEnd) {
      return 0;
    }

    final countExp = _db.ayah.id.count();
    final query = _db.selectOnly(_db.ayah)
      ..addColumns([countExp])
      ..where(
        (_db.ayah.surah.isBiggerThanValue(startSurah) |
                (_db.ayah.surah.equals(startSurah) &
                    _db.ayah.ayah.isBiggerOrEqualValue(startAyah))) &
            (_db.ayah.surah.isSmallerThanValue(endSurah) |
                (_db.ayah.surah.equals(endSurah) &
                    _db.ayah.ayah.isSmallerOrEqualValue(endAyah))),
      );

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<AyahData?> getLastAyah() {
    final query = _db.select(_db.ayah)
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.surah),
        (tbl) => OrderingTerm.desc(tbl.ayah),
      ])
      ..limit(1);
    return query.getSingleOrNull();
  }
}
