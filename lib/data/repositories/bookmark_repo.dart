import 'package:drift/drift.dart';

import '../database/app_database.dart';

class BookmarkRepo {
  BookmarkRepo(this._db);

  final AppDatabase _db;

  Future<BookmarkData?> getBookmarkByAyah({
    required int surah,
    required int ayah,
  }) {
    final query = _db.select(_db.bookmark)
      ..where((tbl) => tbl.surah.equals(surah) & tbl.ayah.equals(ayah))
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<int> addBookmark({
    required int surah,
    required int ayah,
  }) {
    return _db.into(_db.bookmark).insert(
          BookmarkCompanion.insert(
            surah: surah,
            ayah: ayah,
          ),
        );
  }

  Future<List<BookmarkData>> getBookmarks() {
    final query = _db.select(_db.bookmark)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);
    return query.get();
  }

  Stream<List<BookmarkData>> watchBookmarks() {
    final query = _db.select(_db.bookmark)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);
    return query.watch();
  }

  Future<int> removeBookmark(int id) {
    return (_db.delete(_db.bookmark)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> removeBookmarkByAyah({
    required int surah,
    required int ayah,
  }) {
    return (_db.delete(_db.bookmark)
          ..where((tbl) => tbl.surah.equals(surah) & tbl.ayah.equals(ayah)))
        .go();
  }
}
