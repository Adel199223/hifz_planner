final DateTime _localEpochStart = DateTime(1970, 1, 1);

int localDayIndex(DateTime nowLocal) {
  final localDate = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
  return localDate.difference(_localEpochStart).inDays;
}

int nowLocalSecondsSinceMidnight(DateTime nowLocal) {
  return (nowLocal.hour * Duration.secondsPerHour) +
      (nowLocal.minute * Duration.secondsPerMinute) +
      nowLocal.second;
}

DateTime localDateForDayIndex(int dayIndex) {
  return DateTime(1970, 1, 1).add(Duration(days: dayIndex));
}

DateTime materializeLocalDayMinute({
  required int dayIndex,
  required int minuteOfDay,
}) {
  final clampedMinute = minuteOfDay.clamp(0, 1439);
  final date = localDateForDayIndex(dayIndex);

  for (var minute = clampedMinute; minute < 1440; minute++) {
    final hour = minute ~/ 60;
    final minutePart = minute % 60;
    final candidate = DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minutePart,
    );

    final sameDay = candidate.year == date.year &&
        candidate.month == date.month &&
        candidate.day == date.day;
    final exactWallTime =
        candidate.hour == hour && candidate.minute == minutePart;
    if (sameDay && exactWallTime) {
      return candidate;
    }
  }

  return DateTime(date.year, date.month, date.day, 23, 59);
}
