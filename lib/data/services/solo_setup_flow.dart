import '../repositories/mem_unit_repo.dart';
import '../repositories/settings_repo.dart';
import '../time/local_day_time.dart';
import 'daily_planner.dart';
import 'page_metadata_importer_service.dart';
import 'quran_data_readiness.dart';
import 'quran_text_importer_service.dart';

enum GuidedSetupStepKind {
  importText,
  importPageMetadata,
  saveStarterPlan,
  createStarterUnit,
  complete,
}

class GuidedSetupProgress {
  const GuidedSetupProgress({
    required this.step,
    this.processed = 0,
    this.total = 0,
  });

  final GuidedSetupStepKind step;
  final int processed;
  final int total;

  double? get fraction {
    if (total <= 0) {
      return null;
    }
    return processed / total;
  }
}

class SoloSetupReadiness {
  const SoloSetupReadiness({
    required this.quranData,
    required this.starterPlanHealth,
    required this.hasAnyMemUnits,
  });

  final QuranDataReadiness quranData;
  final StarterPlanHealth starterPlanHealth;
  final bool hasAnyMemUnits;

  bool get hasStarterPlan => starterPlanHealth == StarterPlanHealth.healthy;
  bool get needsStarterPlanRepair => starterPlanHealth.needsRepair;

  bool get needsGuidedSetup =>
      quranData.needsAnySetup || needsStarterPlanRepair || !hasAnyMemUnits;
}

class GuidedSetupOutcome {
  const GuidedSetupOutcome({
    required this.readiness,
    required this.starterUnitStatus,
    this.companionRoute,
  });

  final SoloSetupReadiness readiness;
  final StarterUnitCreationStatus? starterUnitStatus;
  final String? companionRoute;
}

typedef GuidedSetupProgressCallback = void Function(
  GuidedSetupProgress progress,
);

class GuidedSetupFlowService {
  GuidedSetupFlowService(
    this._quranDataReadinessService,
    this._settingsRepo,
    this._memUnitRepo,
    this._dailyPlanner,
    this._quranTextImporterService,
    this._pageMetadataImporterService,
  );

  final QuranDataReadinessService _quranDataReadinessService;
  final SettingsRepo _settingsRepo;
  final MemUnitRepo _memUnitRepo;
  final DailyPlanner _dailyPlanner;
  final QuranTextImporterService _quranTextImporterService;
  final PageMetadataImporterService _pageMetadataImporterService;

  Future<SoloSetupReadiness> load({int? todayDayOverride}) async {
    final quranData = await _quranDataReadinessService.load();
    final settings =
        await _settingsRepo.getSettings(todayDayOverride: todayDayOverride);
    final starterPlanHealth = _settingsRepo.assessStarterPlanHealth(settings);
    final hasAnyMemUnits = await _memUnitRepo.hasAnyUnits();
    return SoloSetupReadiness(
      quranData: quranData,
      starterPlanHealth: starterPlanHealth,
      hasAnyMemUnits: hasAnyMemUnits,
    );
  }

  Future<GuidedSetupOutcome> run({
    int? todayDayOverride,
    GuidedSetupProgressCallback? onProgress,
  }) async {
    final todayDay =
        todayDayOverride ?? localDayIndex(DateTime.now().toLocal());
    var readiness = await load(todayDayOverride: todayDay);

    if (readiness.quranData.needsTextImport) {
      await _quranTextImporterService.importFromAsset(
        force: false,
        onProgress: (progress) {
          onProgress?.call(
            GuidedSetupProgress(
              step: GuidedSetupStepKind.importText,
              processed: progress.processed,
              total: progress.total,
            ),
          );
        },
      );
      readiness = await load(todayDayOverride: todayDay);
    }

    if (readiness.quranData.needsPageMetadataImport) {
      await _pageMetadataImporterService.importFromAsset(
        onProgress: (progress) {
          onProgress?.call(
            GuidedSetupProgress(
              step: GuidedSetupStepKind.importPageMetadata,
              processed: progress.processed,
              total: progress.total,
            ),
          );
        },
      );
      readiness = await load(todayDayOverride: todayDay);
    }

    if (readiness.needsStarterPlanRepair || !readiness.hasAnyMemUnits) {
      onProgress?.call(
        const GuidedSetupProgress(
          step: GuidedSetupStepKind.saveStarterPlan,
        ),
      );
      if (!readiness.hasAnyMemUnits) {
        await _settingsRepo.ensureZeroUnitStarterPlan(
          todayDayOverride: todayDay,
          updatedAtDay: todayDay,
        );
      } else {
        await _settingsRepo.ensureExistingUnitsRepairPlan(
          todayDayOverride: todayDay,
          updatedAtDay: todayDay,
        );
      }
      readiness = await load(todayDayOverride: todayDay);
    }

    StarterUnitCreationStatus? starterUnitStatus;
    String? companionRoute;
    if (!readiness.hasAnyMemUnits) {
      onProgress?.call(
        const GuidedSetupProgress(
          step: GuidedSetupStepKind.createStarterUnit,
        ),
      );
      final plan = await _dailyPlanner.planToday(
        todayDay: todayDay,
        materializeNewUnits: false,
      );
      final result = await _dailyPlanner.createStarterUnitForToday(
        todayDay: todayDay,
        plan: plan,
      );
      starterUnitStatus = result.status;
      if (result.createdUnit != null) {
        companionRoute =
            '/companion/chain?unitId=${result.createdUnit!.id}&mode=new';
      }
      readiness = await load(todayDayOverride: todayDay);
    }

    onProgress?.call(
      const GuidedSetupProgress(step: GuidedSetupStepKind.complete),
    );

    return GuidedSetupOutcome(
      readiness: readiness,
      starterUnitStatus: starterUnitStatus,
      companionRoute: companionRoute,
    );
  }
}
