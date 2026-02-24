import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/time/local_day_time.dart';

void main() {
  test('localDayIndex increments across adjacent local dates', () {
    final endOfDay = DateTime(2026, 2, 20, 23, 59, 59);
    final nextDay = DateTime(2026, 2, 21, 0, 0, 0);

    final delta = localDayIndex(nextDay) - localDayIndex(endOfDay);
    expect(delta, 1);
  });

  test('nowLocalSecondsSinceMidnight returns total elapsed seconds', () {
    final timestamp = DateTime(2026, 2, 20, 1, 2, 3);
    expect(nowLocalSecondsSinceMidnight(timestamp), 3723);
  });

  test('materializeLocalDayMinute returns exact local wall minute when valid',
      () {
    final day = localDayIndex(DateTime(2026, 2, 20));
    final materialized = materializeLocalDayMinute(
      dayIndex: day,
      minuteOfDay: 9 * 60 + 45,
    );
    expect(materialized.hour, 9);
    expect(materialized.minute, 45);
  });

  test('materializeLocalDayMinute skips nonexistent DST minutes when present',
      () {
    final transition = _findSpringForwardTransition();
    if (transition == null) {
      return;
    }

    final missingMinute = _findFirstNonexistentMinute(transition);
    if (missingMinute == null) {
      return;
    }

    final materialized = materializeLocalDayMinute(
      dayIndex: localDayIndex(transition),
      minuteOfDay: missingMinute,
    );
    final materializedMinute = materialized.hour * 60 + materialized.minute;

    expect(materializedMinute, greaterThan(missingMinute));
    expect(materialized.year, transition.year);
    expect(materialized.month, transition.month);
    expect(materialized.day, transition.day);
  });

  test(
      'materializeLocalDayMinute chooses first occurrence on repeated DST minutes when present',
      () {
    final transition = _findFallBackTransition();
    if (transition == null) {
      return;
    }

    final repeatedMinute = 90; // 01:30 local wall time.
    final materialized = materializeLocalDayMinute(
      dayIndex: localDayIndex(transition),
      minuteOfDay: repeatedMinute,
    );

    final hour = repeatedMinute ~/ 60;
    final minute = repeatedMinute % 60;
    final expectedFirstOccurrence = DateTime(
      transition.year,
      transition.month,
      transition.day,
      hour,
      minute,
    );

    expect(materialized.hour, hour);
    expect(materialized.minute, minute);
    expect(materialized.timeZoneOffset, expectedFirstOccurrence.timeZoneOffset);
  });
}

DateTime? _findSpringForwardTransition() {
  final now = DateTime.now().toLocal();
  final startYear = now.year - 5;
  final endYear = now.year + 5;

  for (var year = startYear; year <= endYear; year++) {
    for (var month = 1; month <= 12; month++) {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      for (var day = 1; day <= daysInMonth; day++) {
        final before = DateTime(year, month, day, 1, 59).timeZoneOffset;
        final after = DateTime(year, month, day, 3, 0).timeZoneOffset;
        if (after > before) {
          return DateTime(year, month, day);
        }
      }
    }
  }

  return null;
}

DateTime? _findFallBackTransition() {
  final now = DateTime.now().toLocal();
  final startYear = now.year - 5;
  final endYear = now.year + 5;

  for (var year = startYear; year <= endYear; year++) {
    for (var month = 1; month <= 12; month++) {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      for (var day = 1; day <= daysInMonth; day++) {
        final before = DateTime(year, month, day, 1, 59).timeZoneOffset;
        final after = DateTime(year, month, day, 3, 0).timeZoneOffset;
        if (after < before) {
          return DateTime(year, month, day);
        }
      }
    }
  }

  return null;
}

int? _findFirstNonexistentMinute(DateTime transitionDay) {
  for (var minute = 0; minute < 1440; minute++) {
    final hour = minute ~/ 60;
    final minutePart = minute % 60;
    final candidate = DateTime(
      transitionDay.year,
      transitionDay.month,
      transitionDay.day,
      hour,
      minutePart,
    );
    if (candidate.hour != hour || candidate.minute != minutePart) {
      return minute;
    }
  }
  return null;
}
