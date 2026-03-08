import 'dart:convert';

import '../../database/app_database.dart';
import '../../repositories/quran_repo.dart';
import '../../repositories/schedule_repo.dart';
import '../../repositories/settings_repo.dart';
import '../onboarding_defaults.dart';
import 'availability_interpreter.dart';
import 'daily_content_allocator.dart';
import 'planner_quality_signal.dart';
import 'scheduling_preferences_codec.dart';
import 'weekly_plan_generator.dart';

class PlanningProjectionEngine {
  PlanningProjectionEngine({
    AvailabilityInterpreter availabilityInterpreter =
        const AvailabilityInterpreter(),
    DailyContentAllocator dailyContentAllocator = const DailyContentAllocator(),
    WeeklyPlanGenerator? weeklyPlanGenerator,
  }) : _availabilityInterpreter = availabilityInterpreter,
       _dailyContentAllocator = dailyContentAllocator,
       _weeklyPlanGenerator =
           weeklyPlanGenerator ??
           WeeklyPlanGenerator(
             availabilityInterpreter: availabilityInterpreter,
             dailyContentAllocator: dailyContentAllocator,
           );

  final AvailabilityInterpreter _availabilityInterpreter;
  final DailyContentAllocator _dailyContentAllocator;
  final WeeklyPlanGenerator _weeklyPlanGenerator;

  SchedulingPreferencesV1 preferencesFromSettings(AppSettingsData settings) {
    final decoded = SchedulingPreferencesV1.decodeOrDefaults(
      settings.schedulingPrefsJson,
    );
    if (settings.schedulingPrefsJson != null &&
        settings.schedulingPrefsJson!.trim().isNotEmpty) {
      return decoded;
    }

    final weekdayLegacy = _decodeLegacyWeekdayMinutes(
      settings.minutesByWeekdayJson,
      fallbackMinutes: settings.dailyMinutesDefault,
    );
    return SchedulingPreferencesV1.defaults.copyWith(
      minutesPerDayDefault: settings.dailyMinutesDefault,
      minutesPerWeekDefault: settings.dailyMinutesDefault * 7,
      minutesByWeekday: weekdayLegacy,
      exactTimesEnabled: false,
      timingStrategy: TimingStrategy.untimed,
    );
  }

  SchedulingOverridesV1 overridesFromSettings(AppSettingsData settings) {
    return SchedulingOverridesV1.decodeOrDefaults(
      settings.schedulingOverridesJson,
    );
  }

  double reviewBudgetRatio(String profile) {
    return switch (profile) {
      'support' => 0.80,
      'standard' => 0.70,
      'accelerated' => 0.60,
      _ => 0.70,
    };
  }

  PlannerQualitySignal qualitySignalFromSettings(AppSettingsData settings) {
    return plannerQualitySignalFromGradeDistributionJson(
      settings.typicalGradeDistributionJson,
    );
  }

  DailyContentAllocation allocateDailyContent({
    required double dailyMinutes,
    required double dueReviewMinutes,
    required String profile,
    required bool forceRevisionOnly,
    double mandatoryStage4Minutes = 0,
    double optionalCatchUpMinutes = 0,
    PlannerQualitySignal qualitySignal = const PlannerQualitySignal.neutral(),
  }) {
    return _dailyContentAllocator.allocate(
      dailyMinutes: dailyMinutes,
      dueReviewMinutes: dueReviewMinutes,
      baseReviewRatio: reviewBudgetRatio(profile),
      forceRevisionOnly: forceRevisionOnly,
      mandatoryStage4Minutes: mandatoryStage4Minutes,
      optionalCatchUpMinutes: optionalCatchUpMinutes,
      qualitySignal: qualitySignal,
    );
  }

  Future<WeeklyPlan> generateWeeklyPlan({
    required int startDay,
    int horizonDays = 7,
    required AppSettingsData settings,
    required ScheduleRepo scheduleRepo,
    required QuranRepo quranRepo,
    SchedulingPreferencesV1? preferences,
    SchedulingOverridesV1? overrides,
  }) async {
    final effectivePreferences =
        preferences ?? preferencesFromSettings(settings);
    final effectiveOverrides = overrides ?? overridesFromSettings(settings);
    final qualitySignal = qualitySignalFromSettings(settings);
    final dueReviewMinutesByDay = await estimateDueReviewMinutesForHorizon(
      startDay: startDay,
      horizonDays: horizonDays,
      scheduleRepo: scheduleRepo,
      quranRepo: quranRepo,
      avgReviewMinutesPerAyah: settings.avgReviewMinutesPerAyah,
    );

    return _weeklyPlanGenerator.generate(
      startDay: startDay,
      horizonDays: horizonDays,
      preferences: effectivePreferences,
      overrides: effectiveOverrides,
      dueReviewMinutesByDay: dueReviewMinutesByDay,
      reviewBudgetRatio: reviewBudgetRatio(settings.profile),
      forceRevisionOnly: settings.forceRevisionOnly == 1,
      qualitySignal: qualitySignal,
    );
  }

  Future<Map<int, double>> estimateDueReviewMinutesForHorizon({
    required int startDay,
    required int horizonDays,
    required ScheduleRepo scheduleRepo,
    required QuranRepo quranRepo,
    required double avgReviewMinutesPerAyah,
  }) async {
    final byDay = <int, double>{};
    final ayahCountCache = <int, int>{};

    for (var offset = 0; offset < horizonDays; offset++) {
      final day = startDay + offset;
      final dueRows = await scheduleRepo.getDueUnits(day);
      final estimate = await estimateReviewMinutesForRows(
        dueRows: dueRows,
        quranRepo: quranRepo,
        avgReviewMinutesPerAyah: avgReviewMinutesPerAyah,
        ayahCountCache: ayahCountCache,
      );
      byDay[day] = estimate;
    }

    return byDay;
  }

  Future<double> estimateReviewMinutesForRows({
    required List<DueUnitRow> dueRows,
    required QuranRepo quranRepo,
    required double avgReviewMinutesPerAyah,
    Map<int, int>? ayahCountCache,
  }) async {
    final cache = ayahCountCache ?? <int, int>{};
    var total = 0.0;
    for (final due in dueRows) {
      final unitId = due.unit.id;
      final cachedCount = cache[unitId];
      final ayahCount =
          cachedCount ?? await estimateAyahCountForUnit(due.unit, quranRepo);
      cache[unitId] = ayahCount;
      total += ayahCount * avgReviewMinutesPerAyah;
    }
    return total;
  }

  Future<int> estimateAyahCountForUnit(
    MemUnitData unit,
    QuranRepo quranRepo,
  ) async {
    final startSurah = unit.startSurah;
    final startAyah = unit.startAyah;
    final endSurah = unit.endSurah;
    final endAyah = unit.endAyah;

    if (startSurah == null ||
        startAyah == null ||
        endSurah == null ||
        endAyah == null) {
      return 1;
    }

    final startsAfterEnd =
        (startSurah > endSurah) ||
        (startSurah == endSurah && startAyah > endAyah);
    if (startsAfterEnd) {
      return 1;
    }

    final count = await quranRepo.countAyahsInRange(
      startSurah: startSurah,
      startAyah: startAyah,
      endSurah: endSurah,
      endAyah: endAyah,
    );

    return count > 0 ? count : 1;
  }

  Map<int, int> resolveMinutesForHorizon({
    required int startDay,
    required int horizonDays,
    required SchedulingPreferencesV1 preferences,
    required SchedulingOverridesV1 overrides,
  }) {
    return _availabilityInterpreter.resolveTargetMinutesForHorizon(
      startDay: startDay,
      horizonDays: horizonDays,
      preferences: preferences,
      overrides: overrides,
    );
  }

  int resolveMinutesForDay({
    required int dayIndex,
    required SchedulingPreferencesV1 preferences,
    required SchedulingOverridesV1 overrides,
  }) {
    final minutesByDay = resolveMinutesForHorizon(
      startDay: dayIndex,
      horizonDays: 1,
      preferences: preferences,
      overrides: overrides,
    );
    return minutesByDay[dayIndex] ?? 0;
  }

  String encodePreferences(SchedulingPreferencesV1 preferences) {
    return preferences.encode();
  }

  String encodeOverrides(SchedulingOverridesV1 overrides) {
    return overrides.encode();
  }

  Map<int, int> _decodeLegacyWeekdayMinutes(
    String? rawJson, {
    required int fallbackMinutes,
  }) {
    final fallback = <int, int>{
      DateTime.monday: fallbackMinutes,
      DateTime.tuesday: fallbackMinutes,
      DateTime.wednesday: fallbackMinutes,
      DateTime.thursday: fallbackMinutes,
      DateTime.friday: fallbackMinutes,
      DateTime.saturday: fallbackMinutes,
      DateTime.sunday: fallbackMinutes,
    };
    if (rawJson == null || rawJson.trim().isEmpty) {
      return fallback;
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) {
        return fallback;
      }

      final byWeekday = <int, int>{...fallback};
      for (final key in onboardingWeekdayKeys) {
        final value = decoded[key];
        final weekday = _weekdayFromLegacyKey(key);
        if (weekday == null) {
          continue;
        }
        if (value is num) {
          byWeekday[weekday] = value.toInt();
        }
      }
      return byWeekday;
    } catch (_) {
      return fallback;
    }
  }

  int? _weekdayFromLegacyKey(String key) {
    return switch (key) {
      'mon' => DateTime.monday,
      'tue' => DateTime.tuesday,
      'wed' => DateTime.wednesday,
      'thu' => DateTime.thursday,
      'fri' => DateTime.friday,
      'sat' => DateTime.saturday,
      'sun' => DateTime.sunday,
      _ => null,
    };
  }
}
