import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../repositories/bookmark_repo.dart';
import '../repositories/note_repo.dart';
import '../repositories/quran_repo.dart';
import '../services/page_metadata_importer_service.dart';
import '../services/quran_text_importer_service.dart';

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

final quranTextImporterServiceProvider = Provider<QuranTextImporterService>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return QuranTextImporterService(db);
});

final pageMetadataImporterServiceProvider =
    Provider<PageMetadataImporterService>(
  (ref) {
    final db = ref.watch(appDatabaseProvider);
    return PageMetadataImporterService(db);
  },
);
