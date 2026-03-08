import 'dart:math' as math;

enum DailyAllocationLearnerMode {
  easy,
  normal,
  intensive,
  recovery,
  revisionOnly,
}

enum DailyAllocationHealth { onTrack, tight, overloaded }

class DailyContentAllocation {
  const DailyContentAllocation({
    required this.dailyMinutes,
    required this.mandatoryStage4Minutes,
    required this.criticalReviewMinutes,
    required this.optionalCatchUpMinutes,
    required this.reviewCapacityMinutes,
    required this.newBudgetMinutes,
    required this.reviewPressure,
    required this.weightedStress,
    required this.recoveryMode,
    required this.newReductionFraction,
    required this.dueOverflow,
    required this.learnerMode,
    required this.health,
    required this.minimumViableNewMinutes,
    required this.newAssignmentsAllowed,
    required this.minimumDaySuggested,
  });

  final double dailyMinutes;
  final double mandatoryStage4Minutes;
  final double criticalReviewMinutes;
  final double optionalCatchUpMinutes;
  final double reviewCapacityMinutes;
  final double newBudgetMinutes;
  final double reviewPressure;
  final double weightedStress;
  final bool recoveryMode;
  final double newReductionFraction;
  final bool dueOverflow;
  final DailyAllocationLearnerMode learnerMode;
  final DailyAllocationHealth health;
  final double minimumViableNewMinutes;
  final bool newAssignmentsAllowed;
  final bool minimumDaySuggested;
}

class DailyContentAllocator {
  const DailyContentAllocator();

  DailyContentAllocation allocate({
    required double dailyMinutes,
    required double dueReviewMinutes,
    required double baseReviewRatio,
    required bool forceRevisionOnly,
    double mandatoryStage4Minutes = 0,
    double optionalCatchUpMinutes = 0,
  }) {
    final normalizedDailyMinutes = dailyMinutes < 0 ? 0.0 : dailyMinutes;
    final normalizedMandatoryStage4 = mandatoryStage4Minutes < 0
        ? 0.0
        : mandatoryStage4Minutes;
    final normalizedCriticalReview = dueReviewMinutes < 0
        ? 0.0
        : dueReviewMinutes;
    final normalizedOptionalCatchUp = optionalCatchUpMinutes < 0
        ? 0.0
        : optionalCatchUpMinutes;

    if (dailyMinutes <= 0) {
      return DailyContentAllocation(
        dailyMinutes: 0,
        mandatoryStage4Minutes: normalizedMandatoryStage4,
        criticalReviewMinutes: normalizedCriticalReview,
        optionalCatchUpMinutes: normalizedOptionalCatchUp,
        reviewCapacityMinutes: 0,
        newBudgetMinutes: 0,
        reviewPressure: 0,
        weightedStress: 0,
        recoveryMode: true,
        newReductionFraction: 1,
        dueOverflow: false,
        learnerMode: DailyAllocationLearnerMode.revisionOnly,
        health: DailyAllocationHealth.overloaded,
        minimumViableNewMinutes: 0,
        newAssignmentsAllowed: false,
        minimumDaySuggested: false,
      );
    }

    final safeReviewRatio = baseReviewRatio.clamp(0.05, 0.95);
    final retentionCapacityMinutes = math.max(
      1.0,
      normalizedDailyMinutes * safeReviewRatio,
    );
    final baseNewBudget = (normalizedDailyMinutes - retentionCapacityMinutes)
        .clamp(0.0, normalizedDailyMinutes);

    final weightedDemand =
        (normalizedMandatoryStage4 * 1.25) +
        (normalizedCriticalReview * 1.10) +
        (normalizedOptionalCatchUp * 0.35);
    final weightedStress = weightedDemand <= 0
        ? 0.0
        : weightedDemand / retentionCapacityMinutes;

    var health = switch (weightedStress) {
      > 1.2 => DailyAllocationHealth.overloaded,
      >= 0.9 => DailyAllocationHealth.tight,
      _ => DailyAllocationHealth.onTrack,
    };

    if (health == DailyAllocationHealth.onTrack &&
        (normalizedMandatoryStage4 > 0 || normalizedOptionalCatchUp > 0)) {
      health = DailyAllocationHealth.tight;
    }

    var reductionFraction = switch (health) {
      DailyAllocationHealth.onTrack => 0.0,
      DailyAllocationHealth.tight => weightedStress >= 1.0 ? 0.50 : 0.25,
      DailyAllocationHealth.overloaded => 1.0,
    };
    if ((normalizedMandatoryStage4 > 0 || normalizedOptionalCatchUp > 0) &&
        reductionFraction < 0.25) {
      reductionFraction = 0.25;
    }

    final minimumViableNewMinutes = math.min(
      baseNewBudget,
      math.max(2.0, math.min(6.0, normalizedDailyMinutes * 0.10)),
    );

    var newBudgetMinutes = forceRevisionOnly
        ? 0.0
        : baseNewBudget * (1.0 - reductionFraction);
    if (!forceRevisionOnly && newBudgetMinutes < minimumViableNewMinutes) {
      newBudgetMinutes = 0.0;
    }

    var reviewCapacityMinutes = normalizedDailyMinutes - newBudgetMinutes;
    var dueOverflow =
        (normalizedMandatoryStage4 +
            normalizedCriticalReview +
            normalizedOptionalCatchUp) >
        reviewCapacityMinutes + 1e-9;
    if (forceRevisionOnly || health == DailyAllocationHealth.overloaded) {
      newBudgetMinutes = 0.0;
      reviewCapacityMinutes = normalizedDailyMinutes;
      dueOverflow =
          (normalizedMandatoryStage4 +
              normalizedCriticalReview +
              normalizedOptionalCatchUp) >
          reviewCapacityMinutes + 1e-9;
    }

    final recoveryMode =
        forceRevisionOnly || health == DailyAllocationHealth.overloaded;
    final learnerMode = forceRevisionOnly
        ? DailyAllocationLearnerMode.revisionOnly
        : recoveryMode
        ? DailyAllocationLearnerMode.recovery
        : _baselineModeForRatio(safeReviewRatio);

    return DailyContentAllocation(
      dailyMinutes: normalizedDailyMinutes,
      mandatoryStage4Minutes: normalizedMandatoryStage4,
      criticalReviewMinutes: normalizedCriticalReview,
      optionalCatchUpMinutes: normalizedOptionalCatchUp,
      reviewCapacityMinutes: reviewCapacityMinutes,
      newBudgetMinutes: newBudgetMinutes,
      reviewPressure: weightedStress,
      weightedStress: weightedStress,
      recoveryMode: recoveryMode,
      newReductionFraction: reductionFraction,
      dueOverflow: dueOverflow,
      learnerMode: learnerMode,
      health: health,
      minimumViableNewMinutes: minimumViableNewMinutes,
      newAssignmentsAllowed: newBudgetMinutes > 0,
      minimumDaySuggested:
          health != DailyAllocationHealth.onTrack ||
          normalizedMandatoryStage4 > 0 ||
          normalizedOptionalCatchUp > 0,
    );
  }

  DailyAllocationLearnerMode _baselineModeForRatio(double safeReviewRatio) {
    if (safeReviewRatio >= 0.76) {
      return DailyAllocationLearnerMode.easy;
    }
    if (safeReviewRatio >= 0.66) {
      return DailyAllocationLearnerMode.normal;
    }
    return DailyAllocationLearnerMode.intensive;
  }
}
