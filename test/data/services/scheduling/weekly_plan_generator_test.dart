import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/scheduling/scheduling_preferences_codec.dart';
import 'package:hifz_planner/data/services/scheduling/weekly_plan_generator.dart';

void main() {
  const generator = WeeklyPlanGenerator();

  test('default day generates two sessions when minutes are sufficient', () {
    final prefs = SchedulingPreferencesV1.defaults.copyWith(
      sessionsPerDay: 2,
      minutesPerDayDefault: 60,
      minutesByWeekday: const <int, int>{
        DateTime.monday: 60,
        DateTime.tuesday: 60,
        DateTime.wednesday: 60,
        DateTime.thursday: 60,
        DateTime.friday: 60,
        DateTime.saturday: 60,
        DateTime.sunday: 60,
      },
    );

    final plan = generator.generate(
      startDay: 4,
      horizonDays: 1,
      preferences: prefs,
      overrides: SchedulingOverridesV1.empty,
      dueReviewMinutesByDay: const <int, double>{4: 20},
      reviewBudgetRatio: 0.7,
      forceRevisionOnly: false,
    );

    expect(plan.days.single.sessions.length, 2);
    expect(plan.days.single.sessions.first.plannedMinutes, 30);
    expect(plan.days.single.sessions.last.plannedMinutes, 30);
  });

  test('daily minutes under 24 auto-collapses to one session', () {
    final prefs = SchedulingPreferencesV1.defaults.copyWith(
      sessionsPerDay: 2,
      minutesPerDayDefault: 20,
      minutesByWeekday: const <int, int>{
        DateTime.monday: 20,
        DateTime.tuesday: 20,
        DateTime.wednesday: 20,
        DateTime.thursday: 20,
        DateTime.friday: 20,
        DateTime.saturday: 20,
        DateTime.sunday: 20,
      },
    );

    final plan = generator.generate(
      startDay: 4,
      horizonDays: 1,
      preferences: prefs,
      overrides: SchedulingOverridesV1.empty,
      dueReviewMinutesByDay: const <int, double>{4: 5},
      reviewBudgetRatio: 0.7,
      forceRevisionOnly: false,
    );

    expect(plan.days.single.sessions.length, 1);
    expect(plan.days.single.sessions.single.plannedMinutes, 20);
  });

  test('fixed times clamp to nearest window when flexOutsideWindows=false', () {
    final prefs = SchedulingPreferencesV1.defaults.copyWith(
      exactTimesEnabled: true,
      timingStrategy: TimingStrategy.fixedTimes,
      availabilityModel: AvailabilityModel.specificHours,
      minutesPerDayDefault: 50,
      minutesByWeekday: const <int, int>{
        DateTime.monday: 50,
        DateTime.tuesday: 50,
        DateTime.wednesday: 50,
        DateTime.thursday: 50,
        DateTime.friday: 50,
        DateTime.saturday: 50,
        DateTime.sunday: 50,
      },
      sessionATimeMinute: 5 * 60,
      sessionBTimeMinute: 23 * 60,
      windowsByWeekday: const <int, List<TimeWindow>>{
        DateTime.monday: <TimeWindow>[
          TimeWindow(startMinute: 8 * 60, endMinute: 10 * 60),
        ],
      },
      flexOutsideWindows: false,
    );

    final plan = generator.generate(
      startDay: 4,
      horizonDays: 1,
      preferences: prefs,
      overrides: SchedulingOverridesV1.empty,
      dueReviewMinutesByDay: const <int, double>{4: 10},
      reviewBudgetRatio: 0.7,
      forceRevisionOnly: false,
    );

    final sessions = plan.days.single.sessions;
    expect(sessions.length, 2);
    expect(sessions.first.isTimed, isTrue);
    expect(sessions.first.startMinuteOfDay, 8 * 60);
    expect(sessions.last.startMinuteOfDay, anyOf(8 * 60, (10 * 60) - 1));
  });
}
