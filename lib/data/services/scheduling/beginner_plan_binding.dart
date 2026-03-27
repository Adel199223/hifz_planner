import '../../database/app_database.dart';
import '../onboarding_defaults.dart';
import 'planning_projection_engine.dart';
import 'scheduling_preferences_codec.dart';

class BeginnerPlanBinding {
  const BeginnerPlanBinding({
    required this.weekdayMinutesByKey,
    required this.weeklyMinutes,
    required this.dailyMinutesDefault,
    required this.legacyWeekdayJson,
    required this.preferences,
  });

  factory BeginnerPlanBinding.fromWeekdayMinutes({
    required Map<String, int> weekdayMinutesByKey,
    required SchedulingPreferencesV1 basePreferences,
  }) {
    final normalizedLegacy = _normalizeLegacyWeekdayMinutes(weekdayMinutesByKey);
    final weeklyMinutes = normalizedLegacy.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final dailyMinutesDefault = deriveDailyDefault(normalizedLegacy);
    final preferences = basePreferences.copyWith(
      minutesPerDayDefault: dailyMinutesDefault,
      minutesPerWeekDefault: weeklyMinutes,
      minutesByWeekday: _preferencesWeekdayMinutes(normalizedLegacy),
    );

    return BeginnerPlanBinding(
      weekdayMinutesByKey: normalizedLegacy,
      weeklyMinutes: weeklyMinutes,
      dailyMinutesDefault: dailyMinutesDefault,
      legacyWeekdayJson: encodeWeekdayMinutesJson(normalizedLegacy),
      preferences: preferences,
    );
  }

  factory BeginnerPlanBinding.fromSettings({
    required AppSetting settings,
    required PlanningProjectionEngine projectionEngine,
  }) {
    final basePreferences = projectionEngine.preferencesFromSettings(settings);
    final legacyWeekdayMinutes = <String, int>{
      for (final key in onboardingWeekdayKeys)
        key: basePreferences.minutesByWeekday[_weekdayForLegacyKey(key)] ??
            basePreferences.minutesPerDayDefault,
    };
    return BeginnerPlanBinding.fromWeekdayMinutes(
      weekdayMinutesByKey: legacyWeekdayMinutes,
      basePreferences: basePreferences,
    );
  }

  final Map<String, int> weekdayMinutesByKey;
  final int weeklyMinutes;
  final int dailyMinutesDefault;
  final String legacyWeekdayJson;
  final SchedulingPreferencesV1 preferences;

  BeginnerPlanBinding copyWith({
    Map<String, int>? weekdayMinutesByKey,
    int? weeklyMinutes,
    int? dailyMinutesDefault,
    String? legacyWeekdayJson,
    SchedulingPreferencesV1? preferences,
  }) {
    return BeginnerPlanBinding(
      weekdayMinutesByKey: weekdayMinutesByKey ?? this.weekdayMinutesByKey,
      weeklyMinutes: weeklyMinutes ?? this.weeklyMinutes,
      dailyMinutesDefault: dailyMinutesDefault ?? this.dailyMinutesDefault,
      legacyWeekdayJson: legacyWeekdayJson ?? this.legacyWeekdayJson,
      preferences: preferences ?? this.preferences,
    );
  }

  static Map<String, int> _normalizeLegacyWeekdayMinutes(
    Map<String, int> weekdayMinutesByKey,
  ) {
    return <String, int>{
      for (final key in onboardingWeekdayKeys)
        key: (weekdayMinutesByKey[key] ?? 0).clamp(0, 1000000),
    };
  }

  static Map<int, int> _preferencesWeekdayMinutes(
    Map<String, int> legacyWeekdayMinutes,
  ) {
    return <int, int>{
      for (final key in onboardingWeekdayKeys)
        _weekdayForLegacyKey(key): legacyWeekdayMinutes[key] ?? 0,
    };
  }

  static int _weekdayForLegacyKey(String key) {
    return switch (key) {
      'mon' => DateTime.monday,
      'tue' => DateTime.tuesday,
      'wed' => DateTime.wednesday,
      'thu' => DateTime.thursday,
      'fri' => DateTime.friday,
      'sat' => DateTime.saturday,
      'sun' => DateTime.sunday,
      _ => DateTime.monday,
    };
  }
}
