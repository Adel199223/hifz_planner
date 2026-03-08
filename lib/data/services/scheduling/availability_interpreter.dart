import 'dart:math' as math;

import 'scheduling_preferences_codec.dart';

class DayAvailabilityResolution {
  const DayAvailabilityResolution({
    required this.dayIndex,
    required this.weekday,
    required this.enabledStudyDay,
    required this.skipDay,
    required this.revisionOnlyDay,
    required this.targetMinutes,
    required this.windows,
  });

  final int dayIndex;
  final int weekday;
  final bool enabledStudyDay;
  final bool skipDay;
  final bool revisionOnlyDay;
  final int targetMinutes;
  final List<TimeWindow> windows;
}

class AvailabilityInterpreter {
  const AvailabilityInterpreter();

  Map<int, int> resolveTargetMinutesForHorizon({
    required int startDay,
    required int horizonDays,
    required SchedulingPreferencesV1 preferences,
    required SchedulingOverridesV1 overrides,
  }) {
    final days = <int>[for (var i = 0; i < horizonDays; i++) startDay + i];

    return switch (preferences.availabilityModel) {
      AvailabilityModel.minutesPerWeek => _resolveMinutesPerWeek(
          days: days,
          preferences: preferences,
          overrides: overrides,
        ),
      AvailabilityModel.minutesPerDay ||
      AvailabilityModel.specificHours =>
        _resolveMinutesPerDayLike(
          days: days,
          preferences: preferences,
          overrides: overrides,
        ),
    };
  }

  DayAvailabilityResolution resolveDay({
    required int dayIndex,
    required SchedulingPreferencesV1 preferences,
    required SchedulingOverridesV1 overrides,
    required Map<int, int> minutesByDay,
  }) {
    final weekday = weekdayFromDayIndex(dayIndex);
    final override = overrides[dayIndex];
    final enabledWeekday = preferences.enabledWeekdays.contains(weekday);
    final isSkipped = override?.skipDay == true;
    final enabledStudyDay = enabledWeekday && !isSkipped;

    final revisionOnly = override?.revisionOnly ??
        preferences.revisionOnlyWeekdays.contains(weekday);

    final targetMinutes = enabledStudyDay
        ? (minutesByDay[dayIndex] ??
            _minutesForWeekday(
              preferences: preferences,
              weekday: weekday,
            ))
        : 0;

    final windows =
        preferences.availabilityModel == AvailabilityModel.specificHours
            ? List<TimeWindow>.from(
                preferences.windowsByWeekday[weekday] ?? const <TimeWindow>[])
            : const <TimeWindow>[];

    return DayAvailabilityResolution(
      dayIndex: dayIndex,
      weekday: weekday,
      enabledStudyDay: enabledStudyDay,
      skipDay: isSkipped,
      revisionOnlyDay: revisionOnly,
      targetMinutes: targetMinutes,
      windows: windows,
    );
  }

  Map<int, int> _resolveMinutesPerWeek({
    required List<int> days,
    required SchedulingPreferencesV1 preferences,
    required SchedulingOverridesV1 overrides,
  }) {
    final activeDays = <int>[];
    for (final day in days) {
      final weekday = weekdayFromDayIndex(day);
      if (!preferences.enabledWeekdays.contains(weekday)) {
        continue;
      }
      if (overrides[day]?.skipDay == true) {
        continue;
      }
      activeDays.add(day);
    }

    final minutesByDay = <int, int>{
      for (final day in days) day: 0,
    };

    if (activeDays.isNotEmpty && preferences.minutesPerWeekDefault > 0) {
      final base = preferences.minutesPerWeekDefault ~/ activeDays.length;
      var remainder = preferences.minutesPerWeekDefault % activeDays.length;
      for (final day in activeDays) {
        final add = remainder > 0 ? 1 : 0;
        minutesByDay[day] = base + add;
        if (remainder > 0) {
          remainder -= 1;
        }
      }
    }

    _applyExplicitMinuteOverrides(
      minutesByDay: minutesByDay,
      days: days,
      overrides: overrides,
    );
    return minutesByDay;
  }

  Map<int, int> _resolveMinutesPerDayLike({
    required List<int> days,
    required SchedulingPreferencesV1 preferences,
    required SchedulingOverridesV1 overrides,
  }) {
    final minutesByDay = <int, int>{
      for (final day in days)
        day: _baseDailyMinutesForDay(
          dayIndex: day,
          preferences: preferences,
        ),
    };

    final skippedDays = <int>[];
    var lostMinutes = 0;
    final activeDays = <int>[];

    for (final day in days) {
      final weekday = weekdayFromDayIndex(day);
      if (!preferences.enabledWeekdays.contains(weekday)) {
        minutesByDay[day] = 0;
        continue;
      }

      if (overrides[day]?.skipDay == true) {
        skippedDays.add(day);
        lostMinutes += minutesByDay[day] ?? 0;
        minutesByDay[day] = 0;
      } else {
        activeDays.add(day);
      }
    }

    if (lostMinutes > 0 && activeDays.isNotEmpty) {
      final base = lostMinutes ~/ activeDays.length;
      var remainder = lostMinutes % activeDays.length;
      for (final day in activeDays) {
        final add = base + (remainder > 0 ? 1 : 0);
        minutesByDay[day] = (minutesByDay[day] ?? 0) + add;
        if (remainder > 0) {
          remainder -= 1;
        }
      }
    }

    _applyExplicitMinuteOverrides(
      minutesByDay: minutesByDay,
      days: days,
      overrides: overrides,
    );

    return minutesByDay;
  }

  int _baseDailyMinutesForDay({
    required int dayIndex,
    required SchedulingPreferencesV1 preferences,
  }) {
    final weekday = weekdayFromDayIndex(dayIndex);
    final enabledWeekday = preferences.enabledWeekdays.contains(weekday);
    if (!enabledWeekday) {
      return 0;
    }

    return _minutesForWeekday(preferences: preferences, weekday: weekday);
  }

  void _applyExplicitMinuteOverrides({
    required Map<int, int> minutesByDay,
    required List<int> days,
    required SchedulingOverridesV1 overrides,
  }) {
    for (final day in days) {
      final override = overrides[day];
      if (override == null) {
        continue;
      }
      if (override.skipDay == true) {
        minutesByDay[day] = 0;
        continue;
      }
      final explicitMinutes = override.overrideMinutes;
      if (explicitMinutes != null) {
        minutesByDay[day] = math.max(0, explicitMinutes);
      }
    }
  }

  int _minutesForWeekday({
    required SchedulingPreferencesV1 preferences,
    required int weekday,
  }) {
    return preferences.minutesByWeekday[weekday] ??
        preferences.minutesPerDayDefault;
  }
}
