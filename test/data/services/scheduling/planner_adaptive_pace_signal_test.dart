import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/services/scheduling/planner_adaptive_pace_signal.dart';

void main() {
  test('returns neutral when evidence is too small', () {
    final signal = plannerAdaptivePaceSignalFromSamples(
      newSamples: const <CalibrationSampleData>[],
      reviewSamples: const <CalibrationSampleData>[],
      activeNewMinutesPerAyah: 1.0,
      activeReviewMinutesPerAyah: 1.0,
    );

    expect(signal.band, PlannerAdaptivePaceBand.unknown);
    expect(signal.newBudgetMultiplier, 1.0);
    expect(signal.reviewDemandMultiplier, 1.0);
  });

  test('marks the planner much slower when recent new pace is far slower', () {
    final signal = plannerAdaptivePaceSignalFromSamples(
      newSamples: [
        _sample('new_memorization', seconds: 120, ayahs: 1, day: 1),
        _sample('new_memorization', seconds: 120, ayahs: 1, day: 2),
        _sample('new_memorization', seconds: 120, ayahs: 1, day: 3),
      ],
      reviewSamples: const <CalibrationSampleData>[],
      activeNewMinutesPerAyah: 1.0,
      activeReviewMinutesPerAyah: 1.0,
    );

    expect(signal.band, PlannerAdaptivePaceBand.muchSlower);
    expect(signal.newBudgetMultiplier, 0.82);
    expect(signal.reviewDemandMultiplier, 1.10);
  });

  test('marks the planner slightly faster only with consistent evidence', () {
    final signal = plannerAdaptivePaceSignalFromSamples(
      newSamples: [
        _sample('new_memorization', seconds: 45, ayahs: 1, day: 1),
        _sample('new_memorization', seconds: 48, ayahs: 1, day: 2),
        _sample('new_memorization', seconds: 50, ayahs: 1, day: 3),
      ],
      reviewSamples: [
        _sample('review', seconds: 40, ayahs: 1, day: 1),
        _sample('review', seconds: 42, ayahs: 1, day: 2),
        _sample('review', seconds: 44, ayahs: 1, day: 3),
      ],
      activeNewMinutesPerAyah: 1.0,
      activeReviewMinutesPerAyah: 1.0,
    );

    expect(signal.band, PlannerAdaptivePaceBand.slightlyFaster);
    expect(signal.newBudgetMultiplier, 1.05);
    expect(signal.reviewDemandMultiplier, 0.98);
  });
}

CalibrationSampleData _sample(
  String kind, {
  required int seconds,
  required int ayahs,
  required int day,
}) {
  return CalibrationSampleData(
    id: day,
    sampleKind: kind,
    durationSeconds: seconds,
    ayahCount: ayahs,
    createdAtDay: day,
    createdAtSeconds: null,
  );
}
