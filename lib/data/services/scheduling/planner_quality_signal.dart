import 'dart:convert';

enum PlannerQualitySignalBand { unknown, supportive, steady, cautious, fragile }

class PlannerQualitySignal {
  const PlannerQualitySignal({
    required this.band,
    required this.averageQ,
    required this.struggleRatio,
    required this.reviewDemandMultiplier,
    required this.newBudgetMultiplier,
    required this.hasDistribution,
  });

  const PlannerQualitySignal.neutral()
    : band = PlannerQualitySignalBand.unknown,
      averageQ = 4.0,
      struggleRatio = 0.0,
      reviewDemandMultiplier = 1.0,
      newBudgetMultiplier = 1.0,
      hasDistribution = false;

  final PlannerQualitySignalBand band;
  final double averageQ;
  final double struggleRatio;
  final double reviewDemandMultiplier;
  final double newBudgetMultiplier;
  final bool hasDistribution;
}

PlannerQualitySignal plannerQualitySignalFromGradeDistributionJson(
  String? rawJson,
) {
  if (rawJson == null || rawJson.trim().isEmpty) {
    return const PlannerQualitySignal.neutral();
  }

  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      return const PlannerQualitySignal.neutral();
    }

    const gradeOrder = <int>[5, 4, 3, 2, 0];
    final distribution = <int, int>{};
    for (final grade in gradeOrder) {
      final rawValue = decoded['$grade'] ?? decoded[grade];
      if (rawValue is! num) {
        return const PlannerQualitySignal.neutral();
      }
      final value = rawValue.toInt();
      if (value < 0 || value > 100) {
        return const PlannerQualitySignal.neutral();
      }
      distribution[grade] = value;
    }

    final total = distribution.values.fold<int>(0, (sum, value) => sum + value);
    if (total != 100) {
      return const PlannerQualitySignal.neutral();
    }

    final averageQ =
        distribution.entries.fold<double>(
          0,
          (sum, entry) => sum + (entry.key * entry.value),
        ) /
        100.0;
    final struggleRatio =
        ((distribution[2] ?? 0) + (distribution[0] ?? 0)) / 100.0;

    if (averageQ >= 4.2 && struggleRatio <= 0.10) {
      return PlannerQualitySignal(
        band: PlannerQualitySignalBand.supportive,
        averageQ: averageQ,
        struggleRatio: struggleRatio,
        reviewDemandMultiplier: 0.92,
        newBudgetMultiplier: 1.08,
        hasDistribution: true,
      );
    }

    if (averageQ >= 3.6 && struggleRatio <= 0.20) {
      return PlannerQualitySignal(
        band: PlannerQualitySignalBand.steady,
        averageQ: averageQ,
        struggleRatio: struggleRatio,
        reviewDemandMultiplier: 1.0,
        newBudgetMultiplier: 1.0,
        hasDistribution: true,
      );
    }

    if (averageQ >= 3.0) {
      return PlannerQualitySignal(
        band: PlannerQualitySignalBand.cautious,
        averageQ: averageQ,
        struggleRatio: struggleRatio,
        reviewDemandMultiplier: 1.10,
        newBudgetMultiplier: 0.90,
        hasDistribution: true,
      );
    }

    return PlannerQualitySignal(
      band: PlannerQualitySignalBand.fragile,
      averageQ: averageQ,
      struggleRatio: struggleRatio,
      reviewDemandMultiplier: 1.22,
      newBudgetMultiplier: 0.75,
      hasDistribution: true,
    );
  } catch (_) {
    return const PlannerQualitySignal.neutral();
  }
}
