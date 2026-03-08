import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/scheduling/scheduling_preferences_codec.dart';

void main() {
  test('preferences encode/decode round trip preserves key fields', () {
    final prefs = SchedulingPreferencesV1.defaults.copyWith(
      sessionsPerDay: 1,
      exactTimesEnabled: true,
      sessionATimeMinute: 420,
      sessionBTimeMinute: 1080,
      advancedModeEnabled: true,
      availabilityModel: AvailabilityModel.minutesPerWeek,
      minutesPerWeekDefault: 280,
      timingStrategy: TimingStrategy.fixedTimes,
    );

    final decoded = SchedulingPreferencesV1.decodeOrDefaults(prefs.encode());

    expect(decoded.sessionsPerDay, 1);
    expect(decoded.exactTimesEnabled, isTrue);
    expect(decoded.sessionATimeMinute, 420);
    expect(decoded.sessionBTimeMinute, 1080);
    expect(decoded.advancedModeEnabled, isTrue);
    expect(decoded.availabilityModel, AvailabilityModel.minutesPerWeek);
    expect(decoded.minutesPerWeekDefault, 280);
    expect(decoded.timingStrategy, TimingStrategy.fixedTimes);
  });

  test('decode fallback returns defaults on invalid json', () {
    final decoded = SchedulingPreferencesV1.decodeOrDefaults('{bad-json');
    expect(decoded.sessionsPerDay,
        SchedulingPreferencesV1.defaults.sessionsPerDay);
    expect(decoded.enabledWeekdays,
        SchedulingPreferencesV1.defaults.enabledWeekdays);
  });

  test('overrides encode/decode round trip works', () {
    final overrides = SchedulingOverridesV1(
      overridesByDay: <int, SchedulingDayOverrideV1>{
        123: const SchedulingDayOverrideV1(
          dayIndex: 123,
          skipDay: true,
          sessionATimeMinute: 300,
        ),
      },
    );

    final decoded = SchedulingOverridesV1.decodeOrDefaults(overrides.encode());

    expect(decoded[123], isNotNull);
    expect(decoded[123]!.skipDay, isTrue);
    expect(decoded[123]!.sessionATimeMinute, 300);
  });
}
