import 'dart:convert';

import '../../time/local_day_time.dart';

enum AvailabilityModel {
  minutesPerDay(code: 'minutes_per_day'),
  minutesPerWeek(code: 'minutes_per_week'),
  specificHours(code: 'specific_hours');

  const AvailabilityModel({required this.code});

  final String code;

  static AvailabilityModel fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) {
        return value;
      }
    }
    return AvailabilityModel.minutesPerDay;
  }
}

enum TimingStrategy {
  untimed(code: 'untimed'),
  fixedTimes(code: 'fixed_times'),
  autoPlacement(code: 'auto_placement');

  const TimingStrategy({required this.code});

  final String code;

  static TimingStrategy fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) {
        return value;
      }
    }
    return TimingStrategy.untimed;
  }
}

class TimeWindow {
  const TimeWindow({
    required this.startMinute,
    required this.endMinute,
  });

  final int startMinute;
  final int endMinute;

  int get lengthMinutes => endMinute - startMinute;

  bool get isValid =>
      startMinute >= 0 &&
      endMinute <= _minutesPerDay &&
      endMinute > startMinute;

  TimeWindow normalized() {
    final normalizedStart = startMinute.clamp(0, _minutesPerDay - 1);
    final normalizedEnd = endMinute.clamp(1, _minutesPerDay);
    if (normalizedEnd <= normalizedStart) {
      return TimeWindow(
        startMinute: normalizedStart,
        endMinute: (normalizedStart + 1).clamp(1, _minutesPerDay),
      );
    }
    return TimeWindow(
      startMinute: normalizedStart,
      endMinute: normalizedEnd,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object>{
      'startMinute': startMinute,
      'endMinute': endMinute,
    };
  }

  static TimeWindow? fromJsonObject(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final start = raw['startMinute'];
    final end = raw['endMinute'];
    if (start is! num || end is! num) {
      return null;
    }
    return TimeWindow(
      startMinute: start.toInt(),
      endMinute: end.toInt(),
    ).normalized();
  }
}

class SchedulingDayOverrideV1 {
  const SchedulingDayOverrideV1({
    required this.dayIndex,
    this.skipDay,
    this.revisionOnly,
    this.overrideMinutes,
    this.sessionATimeMinute,
    this.sessionBTimeMinute,
  });

  final int dayIndex;
  final bool? skipDay;
  final bool? revisionOnly;
  final int? overrideMinutes;
  final int? sessionATimeMinute;
  final int? sessionBTimeMinute;

  SchedulingDayOverrideV1 copyWith({
    bool? skipDay,
    bool? revisionOnly,
    int? overrideMinutes,
    int? sessionATimeMinute,
    int? sessionBTimeMinute,
  }) {
    return SchedulingDayOverrideV1(
      dayIndex: dayIndex,
      skipDay: skipDay ?? this.skipDay,
      revisionOnly: revisionOnly ?? this.revisionOnly,
      overrideMinutes: overrideMinutes ?? this.overrideMinutes,
      sessionATimeMinute: sessionATimeMinute ?? this.sessionATimeMinute,
      sessionBTimeMinute: sessionBTimeMinute ?? this.sessionBTimeMinute,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'dayIndex': dayIndex,
      'skipDay': skipDay,
      'revisionOnly': revisionOnly,
      'overrideMinutes': overrideMinutes,
      'sessionATimeMinute': sessionATimeMinute,
      'sessionBTimeMinute': sessionBTimeMinute,
    };
  }

  static SchedulingDayOverrideV1? fromJsonObject(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final dayIndex = raw['dayIndex'];
    if (dayIndex is! num) {
      return null;
    }
    final skipDay = raw['skipDay'];
    final revisionOnly = raw['revisionOnly'];
    final overrideMinutes = raw['overrideMinutes'];
    final sessionATimeMinute = raw['sessionATimeMinute'];
    final sessionBTimeMinute = raw['sessionBTimeMinute'];

    return SchedulingDayOverrideV1(
      dayIndex: dayIndex.toInt(),
      skipDay: skipDay is bool ? skipDay : null,
      revisionOnly: revisionOnly is bool ? revisionOnly : null,
      overrideMinutes: overrideMinutes is num ? overrideMinutes.toInt() : null,
      sessionATimeMinute:
          sessionATimeMinute is num ? sessionATimeMinute.toInt() : null,
      sessionBTimeMinute:
          sessionBTimeMinute is num ? sessionBTimeMinute.toInt() : null,
    );
  }
}

class SchedulingOverridesV1 {
  const SchedulingOverridesV1({
    required this.overridesByDay,
  });

  final Map<int, SchedulingDayOverrideV1> overridesByDay;

  static const SchedulingOverridesV1 empty = SchedulingOverridesV1(
    overridesByDay: <int, SchedulingDayOverrideV1>{},
  );

  SchedulingDayOverrideV1? operator [](int dayIndex) =>
      overridesByDay[dayIndex];

  SchedulingOverridesV1 copyWithOverride(SchedulingDayOverrideV1 override) {
    final next = <int, SchedulingDayOverrideV1>{...overridesByDay};
    next[override.dayIndex] = override;
    return SchedulingOverridesV1(overridesByDay: next);
  }

  SchedulingOverridesV1 removeOverride(int dayIndex) {
    final next = <int, SchedulingDayOverrideV1>{...overridesByDay};
    next.remove(dayIndex);
    return SchedulingOverridesV1(overridesByDay: next);
  }

  bool get isEmpty => overridesByDay.isEmpty;

  Map<String, Object?> toJson() {
    final sorted = overridesByDay.keys.toList()..sort();
    return <String, Object?>{
      'version': 1,
      'dayOverrides': [for (final key in sorted) overridesByDay[key]!.toJson()],
    };
  }

  String encode() => jsonEncode(toJson());

  static SchedulingOverridesV1 decodeOrDefaults(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) {
      return empty;
    }
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) {
        return empty;
      }
      final rawOverrides = decoded['dayOverrides'];
      if (rawOverrides is! List) {
        return empty;
      }

      final overrides = <int, SchedulingDayOverrideV1>{};
      for (final item in rawOverrides) {
        final parsed = SchedulingDayOverrideV1.fromJsonObject(item);
        if (parsed == null) {
          continue;
        }
        overrides[parsed.dayIndex] = parsed;
      }
      return SchedulingOverridesV1(overridesByDay: overrides);
    } catch (_) {
      return empty;
    }
  }
}

class SchedulingPreferencesV1 {
  const SchedulingPreferencesV1({
    this.version = 1,
    this.sessionsPerDay = 2,
    this.exactTimesEnabled = false,
    this.sessionATimeMinute,
    this.sessionBTimeMinute,
    this.enabledWeekdays = const <int>{1, 2, 3, 4, 5, 6, 7},
    this.revisionOnlyWeekdays = const <int>{},
    this.advancedModeEnabled = false,
    this.availabilityModel = AvailabilityModel.minutesPerDay,
    this.minutesPerDayDefault = 45,
    this.minutesPerWeekDefault = 315,
    this.minutesByWeekday = const <int, int>{
      1: 45,
      2: 45,
      3: 45,
      4: 45,
      5: 45,
      6: 45,
      7: 45,
    },
    this.windowsByWeekday = const <int, List<TimeWindow>>{},
    this.timingStrategy = TimingStrategy.untimed,
    this.flexOutsideWindows = false,
  });

  final int version;
  final int sessionsPerDay;
  final bool exactTimesEnabled;
  final int? sessionATimeMinute;
  final int? sessionBTimeMinute;
  final Set<int> enabledWeekdays;
  final Set<int> revisionOnlyWeekdays;
  final bool advancedModeEnabled;
  final AvailabilityModel availabilityModel;
  final int minutesPerDayDefault;
  final int minutesPerWeekDefault;
  final Map<int, int> minutesByWeekday;
  final Map<int, List<TimeWindow>> windowsByWeekday;
  final TimingStrategy timingStrategy;
  final bool flexOutsideWindows;

  static const SchedulingPreferencesV1 defaults = SchedulingPreferencesV1();

  SchedulingPreferencesV1 copyWith({
    int? sessionsPerDay,
    bool? exactTimesEnabled,
    int? sessionATimeMinute,
    int? sessionBTimeMinute,
    Set<int>? enabledWeekdays,
    Set<int>? revisionOnlyWeekdays,
    bool? advancedModeEnabled,
    AvailabilityModel? availabilityModel,
    int? minutesPerDayDefault,
    int? minutesPerWeekDefault,
    Map<int, int>? minutesByWeekday,
    Map<int, List<TimeWindow>>? windowsByWeekday,
    TimingStrategy? timingStrategy,
    bool? flexOutsideWindows,
  }) {
    return SchedulingPreferencesV1(
      version: version,
      sessionsPerDay: sessionsPerDay ?? this.sessionsPerDay,
      exactTimesEnabled: exactTimesEnabled ?? this.exactTimesEnabled,
      sessionATimeMinute: sessionATimeMinute ?? this.sessionATimeMinute,
      sessionBTimeMinute: sessionBTimeMinute ?? this.sessionBTimeMinute,
      enabledWeekdays: enabledWeekdays ?? this.enabledWeekdays,
      revisionOnlyWeekdays: revisionOnlyWeekdays ?? this.revisionOnlyWeekdays,
      advancedModeEnabled: advancedModeEnabled ?? this.advancedModeEnabled,
      availabilityModel: availabilityModel ?? this.availabilityModel,
      minutesPerDayDefault: minutesPerDayDefault ?? this.minutesPerDayDefault,
      minutesPerWeekDefault:
          minutesPerWeekDefault ?? this.minutesPerWeekDefault,
      minutesByWeekday: minutesByWeekday ?? this.minutesByWeekday,
      windowsByWeekday: windowsByWeekday ?? this.windowsByWeekday,
      timingStrategy: timingStrategy ?? this.timingStrategy,
      flexOutsideWindows: flexOutsideWindows ?? this.flexOutsideWindows,
    );
  }

  Map<String, Object?> toJson() {
    final encodedMinutesByWeekday = <String, int>{
      for (final key in _weekdayOrder)
        '$key':
            (minutesByWeekday[key] ?? minutesPerDayDefault).clamp(0, 1000000),
    };
    final encodedWindowsByWeekday = <String, List<Map<String, Object?>>>{
      for (final key in _weekdayOrder)
        '$key': [
          for (final window in windowsByWeekday[key] ?? const <TimeWindow>[])
            window.normalized().toJson()
        ],
    };

    return <String, Object?>{
      'version': version,
      'sessionsPerDay': sessionsPerDay,
      'exactTimesEnabled': exactTimesEnabled,
      'sessionATimeMinute': sessionATimeMinute,
      'sessionBTimeMinute': sessionBTimeMinute,
      'enabledWeekdays': enabledWeekdays.toList()..sort(),
      'revisionOnlyWeekdays': revisionOnlyWeekdays.toList()..sort(),
      'advancedModeEnabled': advancedModeEnabled,
      'availabilityModel': availabilityModel.code,
      'minutesPerDayDefault': minutesPerDayDefault,
      'minutesPerWeekDefault': minutesPerWeekDefault,
      'minutesByWeekday': encodedMinutesByWeekday,
      'windowsByWeekday': encodedWindowsByWeekday,
      'timingStrategy': timingStrategy.code,
      'flexOutsideWindows': flexOutsideWindows,
    };
  }

  String encode() => jsonEncode(toJson());

  static SchedulingPreferencesV1 decodeOrDefaults(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) {
      return defaults;
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) {
        return defaults;
      }

      final sessionsPerDay = (decoded['sessionsPerDay'] is num)
          ? (decoded['sessionsPerDay'] as num).toInt().clamp(1, 2)
          : defaults.sessionsPerDay;
      final exactTimesEnabled = decoded['exactTimesEnabled'] is bool
          ? decoded['exactTimesEnabled'] as bool
          : defaults.exactTimesEnabled;
      final sessionATimeMinute =
          _parseMinute(decoded['sessionATimeMinute'])?.clamp(0, 1439);
      final sessionBTimeMinute =
          _parseMinute(decoded['sessionBTimeMinute'])?.clamp(0, 1439);

      final enabledWeekdays = _parseWeekdaySet(decoded['enabledWeekdays']);
      final revisionOnlyWeekdays =
          _parseWeekdaySet(decoded['revisionOnlyWeekdays']);
      final advancedModeEnabled = decoded['advancedModeEnabled'] is bool
          ? decoded['advancedModeEnabled'] as bool
          : defaults.advancedModeEnabled;
      final availabilityModel =
          AvailabilityModel.fromCode(decoded['availabilityModel'] as String?);
      final minutesPerDayDefault = (decoded['minutesPerDayDefault'] is num)
          ? (decoded['minutesPerDayDefault'] as num).toInt().clamp(0, 1000000)
          : defaults.minutesPerDayDefault;
      final minutesPerWeekDefault = (decoded['minutesPerWeekDefault'] is num)
          ? (decoded['minutesPerWeekDefault'] as num).toInt().clamp(0, 1000000)
          : defaults.minutesPerWeekDefault;

      final minutesByWeekday = _parseMinutesByWeekday(
        decoded['minutesByWeekday'],
        fallback: minutesPerDayDefault,
      );
      final windowsByWeekday =
          _parseWindowsByWeekday(decoded['windowsByWeekday']);

      final timingStrategy =
          TimingStrategy.fromCode(decoded['timingStrategy'] as String?);
      final flexOutsideWindows = decoded['flexOutsideWindows'] is bool
          ? decoded['flexOutsideWindows'] as bool
          : defaults.flexOutsideWindows;

      return SchedulingPreferencesV1(
        sessionsPerDay: sessionsPerDay,
        exactTimesEnabled: exactTimesEnabled,
        sessionATimeMinute: sessionATimeMinute,
        sessionBTimeMinute: sessionBTimeMinute,
        enabledWeekdays: enabledWeekdays.isEmpty
            ? defaults.enabledWeekdays
            : enabledWeekdays,
        revisionOnlyWeekdays: revisionOnlyWeekdays,
        advancedModeEnabled: advancedModeEnabled,
        availabilityModel: availabilityModel,
        minutesPerDayDefault: minutesPerDayDefault,
        minutesPerWeekDefault: minutesPerWeekDefault,
        minutesByWeekday: minutesByWeekday,
        windowsByWeekday: windowsByWeekday,
        timingStrategy: timingStrategy,
        flexOutsideWindows: flexOutsideWindows,
      );
    } catch (_) {
      return defaults;
    }
  }
}

int weekdayFromDayIndex(int dayIndex) {
  final date = DateTime(1970, 1, 1).add(Duration(days: dayIndex));
  return date.weekday;
}

int dayIndexFromLocalDate(DateTime nowLocal) {
  return localDayIndex(nowLocal);
}

int? _parseMinute(Object? raw) {
  if (raw is! num) {
    return null;
  }
  return raw.toInt();
}

Set<int> _parseWeekdaySet(Object? raw) {
  if (raw is! List) {
    return <int>{};
  }
  final parsed = <int>{};
  for (final value in raw) {
    if (value is num) {
      final weekday = value.toInt();
      if (_weekdayOrder.contains(weekday)) {
        parsed.add(weekday);
      }
    }
  }
  return parsed;
}

Map<int, int> _parseMinutesByWeekday(
  Object? raw, {
  required int fallback,
}) {
  final result = <int, int>{
    for (final weekday in _weekdayOrder) weekday: fallback,
  };
  if (raw is! Map) {
    return result;
  }

  for (final entry in raw.entries) {
    final keyValue = entry.key;
    final minuteValue = entry.value;
    final weekday = int.tryParse('$keyValue');
    if (weekday == null || !_weekdayOrder.contains(weekday)) {
      continue;
    }
    if (minuteValue is num) {
      result[weekday] = minuteValue.toInt().clamp(0, 1000000);
    }
  }
  return result;
}

Map<int, List<TimeWindow>> _parseWindowsByWeekday(Object? raw) {
  final result = <int, List<TimeWindow>>{};
  if (raw is! Map) {
    return result;
  }

  for (final entry in raw.entries) {
    final keyValue = entry.key;
    final weekday = int.tryParse('$keyValue');
    if (weekday == null || !_weekdayOrder.contains(weekday)) {
      continue;
    }

    final value = entry.value;
    if (value is! List) {
      continue;
    }

    final windows = <TimeWindow>[];
    for (final item in value) {
      final parsed = TimeWindow.fromJsonObject(item);
      if (parsed == null || !parsed.isValid) {
        continue;
      }
      windows.add(parsed);
    }
    if (windows.isNotEmpty) {
      result[weekday] = windows;
    }
  }

  return result;
}

const int _minutesPerDay = 1440;
const List<int> _weekdayOrder = <int>[1, 2, 3, 4, 5, 6, 7];
