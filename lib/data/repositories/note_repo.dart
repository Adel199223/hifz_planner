import 'package:drift/drift.dart';

import '../database/app_database.dart';

class NoteRepo {
  NoteRepo(this._db);

  final AppDatabase _db;

  Future<int> createNote({
    required int surah,
    required int ayah,
    String? title,
    required String body,
  }) {
    return _db.into(_db.note).insert(
          NoteCompanion.insert(
            surah: surah,
            ayah: ayah,
            body: body,
            title: Value(title),
          ),
        );
  }

  Future<NoteData?> getNote(int id) {
    final query = _db.select(_db.note)..where((tbl) => tbl.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<List<NoteData>> getNotesForAyah({
    required int surah,
    required int ayah,
  }) {
    final query = _db.select(_db.note)
      ..where((tbl) => tbl.surah.equals(surah) & tbl.ayah.equals(ayah))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]);
    return query.get();
  }

  Stream<List<NoteData>> watchNotesForAyah({
    required int surah,
    required int ayah,
  }) {
    final query = _db.select(_db.note)
      ..where((tbl) => tbl.surah.equals(surah) & tbl.ayah.equals(ayah))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]);
    return query.watch();
  }

  Future<bool> updateNote({
    required int id,
    String? title,
    required String body,
  }) async {
    final rows = await (_db.update(_db.note)..where((tbl) => tbl.id.equals(id)))
        .write(
      NoteCompanion(
        title: Value(title),
        body: Value(body),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return rows > 0;
  }

  Future<int> deleteNote(int id) {
    return (_db.delete(_db.note)..where((tbl) => tbl.id.equals(id))).go();
  }
}
