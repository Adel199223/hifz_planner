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
}
