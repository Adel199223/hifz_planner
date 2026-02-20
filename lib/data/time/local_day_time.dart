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
