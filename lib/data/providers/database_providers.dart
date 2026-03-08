import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../repositories/bookmark_repo.dart';
import '../repositories/calibration_repo.dart';
import '../repositories/companion_repo.dart';
import '../repositories/mem_unit_repo.dart';
import '../repositories/note_repo.dart';
import '../repositories/progress_repo.dart';
import '../repositories/quran_repo.dart';
import '../repositories/review_log_repo.dart';
import '../repositories/schedule_repo.dart';
import '../repositories/settings_repo.dart';
import '../services/calibration_service.dart';
import '../services/companion/companion_calibration_bridge.dart';
import '../services/companion/progressive_reveal_chain_engine.dart';
import '../services/companion/stage1_auto_check_engine.dart';
import '../services/companion/verse_evaluator.dart';
import '../services/daily_planner.dart';
import '../services/forecast_simulation_service.dart';
import '../services/goal_progress_snapshot_service.dart';
import '../services/new_unit_generator.dart';
import '../services/page_metadata_importer_service.dart';
import '../services/qurancom_api.dart';
import '../services/qurancom_chapters_service.dart';
import '../services/scheduling/planning_projection_engine.dart';
import '../services/quran_text_importer_service.dart';
import '../services/surah_metadata_service.dart';
import '../services/tajweed_tags_service.dart';
import '../../ui/qcf/qcf_font_manager.dart';
export 'audio_providers.dart';

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

final companionRepoProvider = Provider<CompanionRepo>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CompanionRepo(db);
});

final reviewLogRepoProvider = Provider<ReviewLogRepo>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReviewLogRepo(db);
});

final calibrationRepoProvider = Provider<CalibrationRepo>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CalibrationRepo(db);
});

final settingsRepoProvider = Provider<SettingsRepo>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SettingsRepo(db);
});

final progressRepoProvider = Provider<ProgressRepo>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ProgressRepo(db);
});

final newUnitGeneratorProvider = Provider<NewUnitGenerator>((ref) {
  final quranRepo = ref.watch(quranRepoProvider);
  final memUnitRepo = ref.watch(memUnitRepoProvider);
  final scheduleRepo = ref.watch(scheduleRepoProvider);
  return NewUnitGenerator(quranRepo, memUnitRepo, scheduleRepo);
});

final planningProjectionEngineProvider = Provider<PlanningProjectionEngine>((
  ref,
) {
  return PlanningProjectionEngine();
});

final dailyPlannerProvider = Provider<DailyPlanner>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final calibrationRepo = ref.watch(calibrationRepoProvider);
  final settingsRepo = ref.watch(settingsRepoProvider);
  final progressRepo = ref.watch(progressRepoProvider);
  final scheduleRepo = ref.watch(scheduleRepoProvider);
  final quranRepo = ref.watch(quranRepoProvider);
  final companionRepo = ref.watch(companionRepoProvider);
  final newUnitGenerator = ref.watch(newUnitGeneratorProvider);
  final planningProjectionEngine = ref.watch(planningProjectionEngineProvider);
  return DailyPlanner(
    db,
    calibrationRepo,
    settingsRepo,
    progressRepo,
    scheduleRepo,
    quranRepo,
    companionRepo,
    newUnitGenerator,
    planningProjectionEngine,
  );
});

final calibrationServiceProvider = Provider<CalibrationService>((ref) {
  final calibrationRepo = ref.watch(calibrationRepoProvider);
  final settingsRepo = ref.watch(settingsRepoProvider);
  return CalibrationService(calibrationRepo, settingsRepo);
});

final forecastSimulationServiceProvider = Provider<ForecastSimulationService>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  final calibrationRepo = ref.watch(calibrationRepoProvider);
  final settingsRepo = ref.watch(settingsRepoProvider);
  final progressRepo = ref.watch(progressRepoProvider);
  final scheduleRepo = ref.watch(scheduleRepoProvider);
  final quranRepo = ref.watch(quranRepoProvider);
  final planningProjectionEngine = ref.watch(planningProjectionEngineProvider);
  return ForecastSimulationService(
    db,
    calibrationRepo,
    settingsRepo,
    progressRepo,
    scheduleRepo,
    quranRepo,
    planningProjectionEngine,
  );
});

final goalProgressSnapshotServiceProvider =
    Provider<GoalProgressSnapshotService>((ref) {
      return const GoalProgressSnapshotService();
    });

final companionCalibrationBridgeProvider = Provider<CompanionCalibrationBridge>(
  (ref) {
    final calibrationRepo = ref.watch(calibrationRepoProvider);
    return CompanionCalibrationBridge(calibrationRepo);
  },
);

final manualFallbackVerseEvaluatorProvider = Provider<VerseEvaluator>((ref) {
  return const ManualFallbackVerseEvaluator();
});

final stage1AutoCheckEngineProvider = Provider<Stage1AutoCheckEngine>((ref) {
  return const Stage1AutoCheckEngine();
});

final progressiveRevealChainEngineProvider =
    Provider<ProgressiveRevealChainEngine>((ref) {
      final companionRepo = ref.watch(companionRepoProvider);
      final calibrationBridge = ref.watch(companionCalibrationBridgeProvider);
      final autoCheckEngine = ref.watch(stage1AutoCheckEngineProvider);
      return ProgressiveRevealChainEngine(
        companionRepo,
        calibrationBridge,
        autoCheckEngine: autoCheckEngine,
      );
    });

final quranTextImporterServiceProvider = Provider<QuranTextImporterService>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return QuranTextImporterService(db);
});

final pageMetadataImporterServiceProvider =
    Provider<PageMetadataImporterService>((ref) {
      final db = ref.watch(appDatabaseProvider);
      return PageMetadataImporterService(db);
    });

final tajweedTagsServiceProvider = Provider<TajweedTagsService>((ref) {
  return TajweedTagsService();
});

final surahMetadataServiceProvider = Provider<SurahMetadataService>((ref) {
  return SurahMetadataService();
});

final quranComApiProvider = Provider<QuranComApi>((ref) {
  return QuranComApi();
});

final quranComChaptersServiceProvider = Provider<QuranComChaptersService>((
  ref,
) {
  return QuranComChaptersService();
});

final qcfFontManagerProvider = Provider<QcfFontManager>((ref) {
  return QcfFontManager();
});
