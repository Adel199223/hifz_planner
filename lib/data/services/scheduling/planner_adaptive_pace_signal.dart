import '../../database/app_database.dart';
import 'planner_quality_signal.dart';

enum PlannerAdaptivePaceBand {
  unknown,
  aligned,
  slightlySlower,
  muchSlower,
  slightlyFaster,
}

class PlannerAdaptivePaceSignal {
  const PlannerAdaptivePaceSignal({
    required this.band,
    required this.newSampleCount,
    required this.reviewSampleCount,
    required this.medianNewMinutesPerAyah,
    required this.medianReviewMinutesPerAyah,
    required this.newPaceRatio,
    required this.reviewPaceRatio,
    required this.reviewDemandMultiplier,
    required this.newBudgetMultiplier,
  });

  const PlannerAdaptivePaceSignal.neutral()
      : band = PlannerAdaptivePaceBand.unknown,
        newSampleCount = 0,
        reviewSampleCount = 0,
        medianNewMinutesPerAyah = null,
        medianReviewMinutesPerAyah = null,
        newPaceRatio = null,
        reviewPaceRatio = null,
        reviewDemandMultiplier = 1.0,
        newBudgetMultiplier = 1.0;

  final PlannerAdaptivePaceBand band;
  final int newSampleCount;
  final int reviewSampleCount;
  final double? medianNewMinutesPerAyah;
  final double? medianReviewMinutesPerAyah;
  final double? newPaceRatio;
  final double? reviewPaceRatio;
  final double reviewDemandMultiplier;
  final double newBudgetMultiplier;

  bool get hasEvidence => band != PlannerAdaptivePaceBand.unknown;
}

PlannerAdaptivePaceSignal plannerAdaptivePaceSignalFromSamples({
  required List<CalibrationSampleData> newSamples,
  required List<CalibrationSampleData> reviewSamples,
  required double activeNewMinutesPerAyah,
  required double activeReviewMinutesPerAyah,
}) {
  final medianNew = _medianMinutesPerAyah(newSamples);
  final medianReview = _medianMinutesPerAyah(reviewSamples);

  final hasNewEvidence = newSamples.length >= 3 &&
      medianNew != null &&
      activeNewMinutesPerAyah > 0;
  final hasReviewEvidence = reviewSamples.length >= 3 &&
      medianReview != null &&
      activeReviewMinutesPerAyah > 0;

  if (!hasNewEvidence && !hasReviewEvidence) {
    return const PlannerAdaptivePaceSignal.neutral();
  }

  final newRatio = hasNewEvidence ? medianNew / activeNewMinutesPerAyah : null;
  final reviewRatio =
      hasReviewEvidence ? medianReview / activeReviewMinutesPerAyah : null;
  final slowestRatio = <double>[
    if (newRatio != null) newRatio,
    if (reviewRatio != null) reviewRatio,
  ].fold<double>(1.0, (current, value) => value > current ? value : current);

  final newComfortablyFaster = newRatio != null && newRatio <= 0.85;
  final reviewComfortablyFaster = reviewRatio == null || reviewRatio <= 0.90;

  if (slowestRatio >= 1.50) {
    return PlannerAdaptivePaceSignal(
      band: PlannerAdaptivePaceBand.muchSlower,
      newSampleCount: newSamples.length,
      reviewSampleCount: reviewSamples.length,
      medianNewMinutesPerAyah: medianNew,
      medianReviewMinutesPerAyah: medianReview,
      newPaceRatio: newRatio,
      reviewPaceRatio: reviewRatio,
      reviewDemandMultiplier: 1.10,
      newBudgetMultiplier: 0.82,
    );
  }

  if (slowestRatio >= 1.15) {
    return PlannerAdaptivePaceSignal(
      band: PlannerAdaptivePaceBand.slightlySlower,
      newSampleCount: newSamples.length,
      reviewSampleCount: reviewSamples.length,
      medianNewMinutesPerAyah: medianNew,
      medianReviewMinutesPerAyah: medianReview,
      newPaceRatio: newRatio,
      reviewPaceRatio: reviewRatio,
      reviewDemandMultiplier: 1.05,
      newBudgetMultiplier: 0.92,
    );
  }

  if (newComfortablyFaster && reviewComfortablyFaster) {
    return PlannerAdaptivePaceSignal(
      band: PlannerAdaptivePaceBand.slightlyFaster,
      newSampleCount: newSamples.length,
      reviewSampleCount: reviewSamples.length,
      medianNewMinutesPerAyah: medianNew,
      medianReviewMinutesPerAyah: medianReview,
      newPaceRatio: newRatio,
      reviewPaceRatio: reviewRatio,
      reviewDemandMultiplier: 0.98,
      newBudgetMultiplier: 1.05,
    );
  }

  return PlannerAdaptivePaceSignal(
    band: PlannerAdaptivePaceBand.aligned,
    newSampleCount: newSamples.length,
    reviewSampleCount: reviewSamples.length,
    medianNewMinutesPerAyah: medianNew,
    medianReviewMinutesPerAyah: medianReview,
    newPaceRatio: newRatio,
    reviewPaceRatio: reviewRatio,
    reviewDemandMultiplier: 1.0,
    newBudgetMultiplier: 1.0,
  );
}

PlannerQualitySignal mergePlannerQualitySignals({
  required PlannerQualitySignal baseSignal,
  PlannerAdaptivePaceSignal adaptiveSignal =
      const PlannerAdaptivePaceSignal.neutral(),
}) {
  if (!adaptiveSignal.hasEvidence) {
    return baseSignal;
  }

  return PlannerQualitySignal(
    band: baseSignal.band,
    averageQ: baseSignal.averageQ,
    struggleRatio: baseSignal.struggleRatio,
    reviewDemandMultiplier: (baseSignal.reviewDemandMultiplier *
            adaptiveSignal.reviewDemandMultiplier)
        .clamp(0.85, 1.35),
    newBudgetMultiplier:
        (baseSignal.newBudgetMultiplier * adaptiveSignal.newBudgetMultiplier)
            .clamp(0.60, 1.15),
    hasDistribution: baseSignal.hasDistribution,
  );
}

double? _medianMinutesPerAyah(List<CalibrationSampleData> samples) {
  if (samples.isEmpty) {
    return null;
  }

  final values = samples
      .map((sample) => (sample.durationSeconds / 60.0) / sample.ayahCount)
      .toList()
    ..sort();
  final middle = values.length ~/ 2;
  if (values.length.isOdd) {
    return values[middle];
  }
  return (values[middle - 1] + values[middle]) / 2.0;
}
