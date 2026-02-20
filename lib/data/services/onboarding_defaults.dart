import 'dart:convert';

enum OnboardingFluency {
  fluent,
  developing,
  support,
}

const List<String> onboardingWeekdayKeys = <String>[
  'mon',
  'tue',
  'wed',
  'thu',
  'fri',
  'sat',
  'sun',
];

Map<String, int> splitWeeklyMinutesEvenly(int weeklyMinutes) {
  if (weeklyMinutes < 0) {
    throw ArgumentError.value(
      weeklyMinutes,
      'weeklyMinutes',
      'weeklyMinutes must be non-negative',
    );
  }

  final base = weeklyMinutes ~/ onboardingWeekdayKeys.length;
  var remainder = weeklyMinutes % onboardingWeekdayKeys.length;
  final result = <String, int>{};
  for (final key in onboardingWeekdayKeys) {
    final extra = remainder > 0 ? 1 : 0;
    result[key] = base + extra;
    if (remainder > 0) {
      remainder -= 1;
    }
  }
  return result;
}

({double avgNew, double avgReview}) defaultsForFluency(
  OnboardingFluency fluency,
) {
  return switch (fluency) {
    OnboardingFluency.fluent => (avgNew: 1.6, avgReview: 0.6),
    OnboardingFluency.developing => (avgNew: 2.0, avgReview: 0.8),
    OnboardingFluency.support => (avgNew: 2.4, avgReview: 1.0),
  };
}

int deriveDailyDefault(Map<String, int> weekdayMinutes) {
  _validateWeekdayMap(weekdayMinutes);
  final total = weekdayMinutes.values.fold<int>(0, (sum, value) => sum + value);
  return (total / onboardingWeekdayKeys.length).round();
}

String encodeWeekdayMinutesJson(Map<String, int> weekdayMinutes) {
  _validateWeekdayMap(weekdayMinutes);
  final ordered = <String, int>{
    for (final key in onboardingWeekdayKeys) key: weekdayMinutes[key]!,
  };
  return jsonEncode(ordered);
}

Map<String, int> decodeWeekdayMinutesJson(String jsonText) {
  final decoded = jsonDecode(jsonText);
  if (decoded is! Map) {
    throw const FormatException('Expected object JSON for weekday minutes.');
  }

  final result = <String, int>{};
  for (final key in onboardingWeekdayKeys) {
    final value = decoded[key];
    if (value is! num || value < 0 || value.toInt() != value) {
      throw FormatException('Invalid value for key "$key".');
    }
    result[key] = value.toInt();
  }

  final extraKeys = decoded.keys
      .where((key) => !onboardingWeekdayKeys.contains(key))
      .toList();
  if (extraKeys.isNotEmpty) {
    throw FormatException('Unexpected weekday keys: ${extraKeys.join(', ')}');
  }

  return result;
}

void _validateWeekdayMap(Map<String, int> weekdayMinutes) {
  final keys = weekdayMinutes.keys.toSet();
  final expected = onboardingWeekdayKeys.toSet();
  if (keys.length != expected.length || !keys.containsAll(expected)) {
    throw FormatException(
      'Weekday minutes must contain exactly: ${onboardingWeekdayKeys.join(', ')}',
    );
  }

  for (final entry in weekdayMinutes.entries) {
    if (entry.value < 0) {
      throw FormatException('Minute values must be non-negative.');
    }
  }
}
