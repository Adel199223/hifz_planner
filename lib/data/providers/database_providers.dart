import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../repositories/bookmark_repo.dart';
import '../repositories/note_repo.dart';
import '../repositories/quran_repo.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final quranRepoProvider = Provider<QuranRepo>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return QuranRepo(db);
});

final bookmarkRepoProvider = Provider<BookmarkRepo>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BookmarkRepo(db);
});

final noteRepoProvider = Provider<NoteRepo>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return NoteRepo(db);
});
