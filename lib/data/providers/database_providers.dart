import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../repositories/bookmark_repo.dart';
import '../repositories/mem_unit_repo.dart';
import '../repositories/note_repo.dart';
import '../repositories/progress_repo.dart';
import '../repositories/quran_repo.dart';
import '../repositories/review_log_repo.dart';
import '../repositories/schedule_repo.dart';
import '../repositories/settings_repo.dart';
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

final memUnitRepoProvider = Provider<MemUnitRepo>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return MemUnitRepo(db);
});

final scheduleRepoProvider = Provider<ScheduleRepo>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ScheduleRepo(db);
});

final reviewLogRepoProvider = Provider<ReviewLogRepo>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReviewLogRepo(db);
});

final settingsRepoProvider = Provider<SettingsRepo>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SettingsRepo(db);
});

final progressRepoProvider = Provider<ProgressRepo>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ProgressRepo(db);
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
