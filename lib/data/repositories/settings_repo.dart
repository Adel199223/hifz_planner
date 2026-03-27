import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../services/onboarding_defaults.dart';
import '../services/scheduling/beginner_plan_binding.dart';
import '../services/scheduling/planning_projection_engine.dart';
import '../services/scheduling/scheduling_preferences_codec.dart';
import '../time/local_day_time.dart';

typedef AppSettingsData = AppSetting;

enum StarterPlanHealth {
  healthy,
  needsStructuredPrefsRepair,
  needsLegacyStarterTrapRepair,
}

extension StarterPlanHealthX on StarterPlanHealth {
  bool get needsRepair => this != StarterPlanHealth.healthy;
}

class SettingsRepo {
  SettingsRepo(this._db);

  final AppDatabase _db;
  final PlanningProjectionEngine _projectionEngine = PlanningProjectionEngine();

  Future<AppSettingsData> getSettings({int? todayDayOverride}) async {
    await _db.ensureSingletonRows();
    await _applyDuePendingCalibration(todayDayOverride: todayDayOverride);
    return (_db.select(_db.appSettings)..where((tbl) => tbl.id.equals(1)))
        .getSingle();
  }

  Future<bool> updateSettings({
    String? profile,
    int? forceRevisionOnly,
    int? dailyMinutesDefault,
    String? minutesByWeekdayJson,
    int? maxNewPagesPerDay,
    int? maxNewUnitsPerDay,
    double? avgNewMinutesPerAyah,
    double? avgReviewMinutesPerAyah,
    int? requirePageMetadata,
    String? typicalGradeDistributionJson,
    String? schedulingPrefsJson,
    String? schedulingOverridesJson,
    int? updatedAtDay,
  }) async {
    await _db.ensureSingletonRows();
    final rows = await (_db.update(_db.appSettings)
          ..where((tbl) => tbl.id.equals(1)))
        .write(
      AppSettingsCompanion(
        profile: profile == null ? const Value.absent() : Value(profile),
        forceRevisionOnly: forceRevisionOnly == null
            ? const Value.absent()
            : Value(forceRevisionOnly),
        dailyMinutesDefault: dailyMinutesDefault == null
            ? const Value.absent()
            : Value(dailyMinutesDefault),
        minutesByWeekdayJson: minutesByWeekdayJson == null
            ? const Value.absent()
            : Value(minutesByWeekdayJson),
        maxNewPagesPerDay: maxNewPagesPerDay == null
            ? const Value.absent()
            : Value(maxNewPagesPerDay),
        maxNewUnitsPerDay: maxNewUnitsPerDay == null
            ? const Value.absent()
            : Value(maxNewUnitsPerDay),
        avgNewMinutesPerAyah: avgNewMinutesPerAyah == null
            ? const Value.absent()
            : Value(avgNewMinutesPerAyah),
        avgReviewMinutesPerAyah: avgReviewMinutesPerAyah == null
            ? const Value.absent()
            : Value(avgReviewMinutesPerAyah),
        requirePageMetadata: requirePageMetadata == null
            ? const Value.absent()
            : Value(requirePageMetadata),
        typicalGradeDistributionJson: typicalGradeDistributionJson == null
            ? const Value.absent()
            : Value(typicalGradeDistributionJson),
        schedulingPrefsJson: schedulingPrefsJson == null
            ? const Value.absent()
            : Value(schedulingPrefsJson),
        schedulingOverridesJson: schedulingOverridesJson == null
            ? const Value.absent()
            : Value(schedulingOverridesJson),
        updatedAtDay: Value(
          updatedAtDay ?? localDayIndex(DateTime.now().toLocal()),
        ),
      ),
    );
    return rows > 0;
  }

  Future<SchedulingPreferencesV1> getSchedulingPreferences({
    int? todayDayOverride,
  }) async {
    final settings = await getSettings(todayDayOverride: todayDayOverride);
    return _projectionEngine.preferencesFromSettings(settings);
  }

  Future<SchedulingOverridesV1> getSchedulingOverrides({
    int? todayDayOverride,
  }) async {
    final settings = await getSettings(todayDayOverride: todayDayOverride);
    return _projectionEngine.overridesFromSettings(settings);
  }

  BeginnerPlanBinding beginnerPlanBindingFromSettings(AppSettingsData settings) {
    return BeginnerPlanBinding.fromSettings(
      settings: settings,
      projectionEngine: _projectionEngine,
    );
  }

  bool hasStructuredSchedulingPreferences(AppSettingsData settings) {
    final raw = settings.schedulingPrefsJson;
    return raw != null && raw.trim().isNotEmpty;
  }

  StarterPlanHealth assessStarterPlanHealth(AppSettingsData settings) {
    if (!hasStructuredSchedulingPreferences(settings)) {
      return StarterPlanHealth.needsStructuredPrefsRepair;
    }
    if (_looksLikeLegacyStarterTrap(settings)) {
      return StarterPlanHealth.needsLegacyStarterTrapRepair;
    }
    return StarterPlanHealth.healthy;
  }

  bool shouldPlanCoerceRevisionOnlyOff(AppSettingsData settings) {
    return _looksLikeLegacyStarterTrap(settings);
  }

  Future<bool> saveSchedulingPreferences({
    required SchedulingPreferencesV1 preferences,
    SchedulingOverridesV1 overrides = SchedulingOverridesV1.empty,
    StarterPlanSource starterPlanSource = StarterPlanSource.userSaved,
    int? updatedAtDay,
  }) {
    return updateSettings(
      schedulingPrefsJson: _projectionEngine.encodePreferences(
        preferences.copyWith(starterPlanSource: starterPlanSource),
      ),
      schedulingOverridesJson: _projectionEngine.encodeOverrides(overrides),
      updatedAtDay: updatedAtDay,
    );
  }

  Future<bool> saveBeginnerPlan({
    required BeginnerPlanBinding binding,
    required SchedulingOverridesV1 overrides,
    StarterPlanSource starterPlanSource = StarterPlanSource.userSaved,
    String? profile,
    int? forceRevisionOnly,
    int? maxNewPagesPerDay,
    int? maxNewUnitsPerDay,
    double? avgNewMinutesPerAyah,
    double? avgReviewMinutesPerAyah,
    int? requirePageMetadata,
    int? updatedAtDay,
  }) {
    return updateSettings(
      profile: profile,
      forceRevisionOnly: forceRevisionOnly,
      dailyMinutesDefault: binding.dailyMinutesDefault,
      minutesByWeekdayJson: binding.legacyWeekdayJson,
      maxNewPagesPerDay: maxNewPagesPerDay,
      maxNewUnitsPerDay: maxNewUnitsPerDay,
      avgNewMinutesPerAyah: avgNewMinutesPerAyah,
      avgReviewMinutesPerAyah: avgReviewMinutesPerAyah,
      requirePageMetadata: requirePageMetadata,
      schedulingPrefsJson: _projectionEngine.encodePreferences(
        binding.preferences.copyWith(starterPlanSource: starterPlanSource),
      ),
      schedulingOverridesJson: _projectionEngine.encodeOverrides(overrides),
      updatedAtDay: updatedAtDay,
    );
  }

  Future<bool> ensureExistingUnitsRepairPlan({
    int? todayDayOverride,
    int? updatedAtDay,
  }) async {
    final settings = await getSettings(todayDayOverride: todayDayOverride);
    final starterPlanHealth = assessStarterPlanHealth(settings);
    if (starterPlanHealth == StarterPlanHealth.healthy) {
      return false;
    }

    var binding = beginnerPlanBindingFromSettings(settings);
    if (binding.weeklyMinutes <= 0 || binding.dailyMinutesDefault <= 0) {
      binding = BeginnerPlanBinding.fromWeekdayMinutes(
        weekdayMinutesByKey: splitWeeklyMinutesEvenly(
          SchedulingPreferencesV1.defaults.minutesPerWeekDefault,
        ),
        basePreferences: SchedulingPreferencesV1.defaults,
      );
    }
    final overrides = await getSchedulingOverrides(
      todayDayOverride: todayDayOverride,
    );
    final normalizedProfile = settings.profile.trim().isEmpty
        ? 'standard'
        : settings.profile.trim();
    final clearsLegacyTrap = _looksLikeLegacyStarterTrap(settings);

    return saveBeginnerPlan(
      binding: binding,
      overrides: overrides,
      starterPlanSource: StarterPlanSource.guidedSetupNormalized,
      profile: normalizedProfile,
      forceRevisionOnly: clearsLegacyTrap ? 0 : settings.forceRevisionOnly,
      maxNewPagesPerDay: settings.maxNewPagesPerDay,
      maxNewUnitsPerDay: settings.maxNewUnitsPerDay,
      avgNewMinutesPerAyah: settings.avgNewMinutesPerAyah,
      avgReviewMinutesPerAyah: settings.avgReviewMinutesPerAyah,
      requirePageMetadata: settings.requirePageMetadata,
      updatedAtDay: updatedAtDay,
    );
  }

  Future<bool> ensureZeroUnitStarterPlan({
    int? todayDayOverride,
    int? updatedAtDay,
  }) async {
    final settings = await getSettings(todayDayOverride: todayDayOverride);
    final hasStructuredPrefs = hasStructuredSchedulingPreferences(settings);
    var binding = beginnerPlanBindingFromSettings(settings);
    if (binding.weeklyMinutes <= 0 || binding.dailyMinutesDefault <= 0) {
      binding = BeginnerPlanBinding.fromWeekdayMinutes(
        weekdayMinutesByKey: splitWeeklyMinutesEvenly(
          SchedulingPreferencesV1.defaults.minutesPerWeekDefault,
        ),
        basePreferences: SchedulingPreferencesV1.defaults,
      );
    }

    final preferences = binding.preferences.copyWith(
      revisionOnlyWeekdays: const <int>{},
    );
    final overrides = await getSchedulingOverrides(
      todayDayOverride: todayDayOverride,
    );
    final normalizedProfile = settings.profile.trim().isEmpty
        ? 'standard'
        : settings.profile;
    const normalizedMaxNewPages = 1;
    const normalizedMaxNewUnits = 1;
    final needsNormalization = !hasStructuredPrefs ||
        binding.weeklyMinutes <= 0 ||
        binding.dailyMinutesDefault <= 0 ||
        settings.forceRevisionOnly == 1 ||
        settings.maxNewPagesPerDay != normalizedMaxNewPages ||
        settings.maxNewUnitsPerDay != normalizedMaxNewUnits ||
        settings.profile.trim().isEmpty ||
        preferences.revisionOnlyWeekdays.isNotEmpty;

    if (!needsNormalization) {
      return false;
    }

    return saveBeginnerPlan(
      binding: binding.copyWith(preferences: preferences),
      overrides: overrides,
      starterPlanSource: StarterPlanSource.guidedSetupNormalized,
      profile: normalizedProfile,
      forceRevisionOnly: 0,
      maxNewPagesPerDay: normalizedMaxNewPages,
      maxNewUnitsPerDay: normalizedMaxNewUnits,
      avgNewMinutesPerAyah: settings.avgNewMinutesPerAyah > 0
          ? settings.avgNewMinutesPerAyah
          : 2.0,
      avgReviewMinutesPerAyah: settings.avgReviewMinutesPerAyah > 0
          ? settings.avgReviewMinutesPerAyah
          : 0.8,
      requirePageMetadata: settings.requirePageMetadata,
      updatedAtDay: updatedAtDay,
    );
  }

  bool _looksLikeLegacyStarterTrap(AppSettingsData settings) {
    final normalizedProfile = settings.profile.trim().isEmpty
        ? 'standard'
        : settings.profile.trim();
    final preferences = _projectionEngine.preferencesFromSettings(settings);
    final overrides = _projectionEngine.overridesFromSettings(settings);
    if (preferences.starterPlanSource != StarterPlanSource.legacyUnknown) {
      return false;
    }
    final matchesDefaultStarterSchedule = preferences
            .copyWith(starterPlanSource: StarterPlanSource.legacyUnknown)
            .encode() ==
        SchedulingPreferencesV1.defaults.encode();

    // Treat starter-plan health as a structural plan-shape question.
    // Calibration or metadata drift should not hide the legacy revision-only
    // starter trap for existing learners.
    return normalizedProfile == 'standard' &&
        settings.forceRevisionOnly == 1 &&
        settings.maxNewPagesPerDay == 1 &&
        settings.maxNewUnitsPerDay == 8 &&
        matchesDefaultStarterSchedule &&
        overrides.overridesByDay.isEmpty;
  }

  Future<void> upsertPendingCalibrationUpdate({
    double? avgNewMinutesPerAyah,
    double? avgReviewMinutesPerAyah,
    String? typicalGradeDistributionJson,
    required int effectiveDay,
    int? createdAtDay,
  }) async {
    final nowDay = createdAtDay ?? localDayIndex(DateTime.now().toLocal());
    await _db.into(_db.pendingCalibrationUpdate).insert(
          PendingCalibrationUpdateCompanion.insert(
            id: const Value(1),
            avgNewMinutesPerAyah: Value(avgNewMinutesPerAyah),
            avgReviewMinutesPerAyah: Value(avgReviewMinutesPerAyah),
            typicalGradeDistributionJson: Value(typicalGradeDistributionJson),
            effectiveDay: effectiveDay,
            createdAtDay: nowDay,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<PendingCalibrationUpdateData?> getPendingCalibrationUpdate() {
    return (_db.select(_db.pendingCalibrationUpdate)
          ..where((tbl) => tbl.id.equals(1))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> clearPendingCalibrationUpdate() async {
    await (_db.delete(_db.pendingCalibrationUpdate)
          ..where((tbl) => tbl.id.equals(1)))
        .go();
  }

  Future<void> _applyDuePendingCalibration({int? todayDayOverride}) async {
    final todayDay =
        todayDayOverride ?? localDayIndex(DateTime.now().toLocal());
    await _db.transaction(() async {
      final pending = await (_db.select(_db.pendingCalibrationUpdate)
            ..where((tbl) => tbl.id.equals(1))
            ..limit(1))
          .getSingleOrNull();
      if (pending == null || pending.effectiveDay > todayDay) {
        return;
      }

      await (_db.update(_db.appSettings)..where((tbl) => tbl.id.equals(1)))
          .write(
        AppSettingsCompanion(
          avgNewMinutesPerAyah: pending.avgNewMinutesPerAyah == null
              ? const Value.absent()
              : Value(pending.avgNewMinutesPerAyah!),
          avgReviewMinutesPerAyah: pending.avgReviewMinutesPerAyah == null
              ? const Value.absent()
              : Value(pending.avgReviewMinutesPerAyah!),
          typicalGradeDistributionJson:
              pending.typicalGradeDistributionJson == null
                  ? const Value.absent()
                  : Value(pending.typicalGradeDistributionJson),
          updatedAtDay: Value(pending.effectiveDay),
        ),
      );

      await (_db.delete(_db.pendingCalibrationUpdate)
            ..where((tbl) => tbl.id.equals(1)))
          .go();
    });
  }
}
