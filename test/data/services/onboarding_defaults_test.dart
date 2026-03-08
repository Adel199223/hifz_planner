import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/onboarding_defaults.dart';

void main() {
  test(
      'splitWeeklyMinutesEvenly distributes with deterministic remainder order',
      () {
    final result = splitWeeklyMinutesEvenly(10);

    expect(
      result,
      {
        'mon': 2,
        'tue': 2,
        'wed': 2,
        'thu': 1,
        'fri': 1,
        'sat': 1,
        'sun': 1,
      },
    );
  });

  test('defaultsForFluency returns configured new/review minute pairs', () {
    final fluent = defaultsForFluency(OnboardingFluency.fluent);
    final developing = defaultsForFluency(OnboardingFluency.developing);
    final support = defaultsForFluency(OnboardingFluency.support);

    expect((fluent.avgNew, fluent.avgReview), (1.6, 0.6));
    expect((developing.avgNew, developing.avgReview), (2.0, 0.8));
    expect((support.avgNew, support.avgReview), (2.4, 1.0));
  });

  test('guided plan presets map to learner-friendly planner defaults', () {
    final easy = defaultsForGuidedPlanPreset(GuidedPlanPreset.easy);
    final normal = defaultsForGuidedPlanPreset(GuidedPlanPreset.normal);
    final intensive =
        defaultsForGuidedPlanPreset(GuidedPlanPreset.intensive);

    expect(
      (
        easy.profile,
        easy.forceRevisionOnly,
        easy.maxNewPagesPerDay,
        easy.maxNewUnitsPerDay,
      ),
      ('support', true, 1, 6),
    );
    expect(
      (
        normal.profile,
        normal.forceRevisionOnly,
        normal.maxNewPagesPerDay,
        normal.maxNewUnitsPerDay,
      ),
      ('standard', true, 1, 8),
    );
    expect(
      (
        intensive.profile,
        intensive.forceRevisionOnly,
        intensive.maxNewPagesPerDay,
        intensive.maxNewUnitsPerDay,
      ),
      ('accelerated', false, 2, 12),
    );
  });

  test('infer guided preset reconstructs the closest preset mode', () {
    expect(
      inferGuidedPlanPreset(
        profile: 'support',
        forceRevisionOnly: true,
        maxNewPagesPerDay: 1,
        maxNewUnitsPerDay: 6,
      ),
      GuidedPlanPreset.easy,
    );
    expect(
      inferGuidedPlanPreset(
        profile: 'standard',
        forceRevisionOnly: true,
        maxNewPagesPerDay: 1,
        maxNewUnitsPerDay: 8,
      ),
      GuidedPlanPreset.normal,
    );
    expect(
      inferGuidedPlanPreset(
        profile: 'accelerated',
        forceRevisionOnly: false,
        maxNewPagesPerDay: 2,
        maxNewUnitsPerDay: 12,
      ),
      GuidedPlanPreset.intensive,
    );
  });

  test('deriveDailyDefault uses rounded average across weekdays', () {
    final weekday = {
      'mon': 10,
      'tue': 10,
      'wed': 10,
      'thu': 10,
      'fri': 10,
      'sat': 10,
      'sun': 16,
    };

    expect(deriveDailyDefault(weekday), 11);
  });

  test('encode/decode weekday json keeps strict mon..sun shape', () {
    final source = {
      'mon': 30,
      'tue': 20,
      'wed': 20,
      'thu': 20,
      'fri': 20,
      'sat': 40,
      'sun': 40,
    };

    final json = encodeWeekdayMinutesJson(source);
    final decoded = decodeWeekdayMinutesJson(json);

    expect(decoded, source);
    expect(
      () => decodeWeekdayMinutesJson('{"mon":10}'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => decodeWeekdayMinutesJson(
        '{"mon":1,"tue":1,"wed":1,"thu":1,"fri":1,"sat":1,"sun":1,"x":1}',
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
