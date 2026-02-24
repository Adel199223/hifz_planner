import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/scheduling/availability_interpreter.dart';
import 'package:hifz_planner/data/services/scheduling/scheduling_preferences_codec.dart';

void main() {
  const interpreter = AvailabilityInterpreter();

  test('minutes-per-week distributes evenly across enabled days', () {
    final prefs = SchedulingPreferencesV1.defaults.copyWith(
      availabilityModel: AvailabilityModel.minutesPerWeek,
      minutesPerWeekDefault: 210,
      enabledWeekdays: const <int>{
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
      },
    );

    final map = interpreter.resolveTargetMinutesForHorizon(
      startDay: 4, // Monday
      horizonDays: 7,
      preferences: prefs,
      overrides: SchedulingOverridesV1.empty,
    );

    expect(map[4], 70);
    expect(map[5], 70);
    expect(map[6], 70);
    expect(map[7], 0);
  });

  test('skip day rebalance redistributes minutes to remaining study days', () {
    final prefs = SchedulingPreferencesV1.defaults.copyWith(
      availabilityModel: AvailabilityModel.minutesPerDay,
      minutesPerDayDefault: 60,
      minutesByWeekday: const <int, int>{
        DateTime.monday: 60,
        DateTime.tuesday: 60,
        DateTime.wednesday: 60,
        DateTime.thursday: 0,
        DateTime.friday: 0,
        DateTime.saturday: 0,
        DateTime.sunday: 0,
      },
      enabledWeekdays: const <int>{
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
      },
    );

    final overrides = SchedulingOverridesV1(
      overridesByDay: <int, SchedulingDayOverrideV1>{
        5: const SchedulingDayOverrideV1(dayIndex: 5, skipDay: true),
      },
    );

    final map = interpreter.resolveTargetMinutesForHorizon(
      startDay: 4,
      horizonDays: 3,
      preferences: prefs,
      overrides: overrides,
    );

    expect(map[4], 90);
    expect(map[5], 0);
    expect(map[6], 90);
  });
}
