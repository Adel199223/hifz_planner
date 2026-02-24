class DailyContentAllocation {
  const DailyContentAllocation({
    required this.dailyMinutes,
    required this.reviewCapacityMinutes,
    required this.newBudgetMinutes,
    required this.reviewPressure,
    required this.recoveryMode,
    required this.newReductionFraction,
    required this.dueOverflow,
  });

  final double dailyMinutes;
  final double reviewCapacityMinutes;
  final double newBudgetMinutes;
  final double reviewPressure;
  final bool recoveryMode;
  final double newReductionFraction;
  final bool dueOverflow;
}

class DailyContentAllocator {
  const DailyContentAllocator();

  DailyContentAllocation allocate({
    required double dailyMinutes,
    required double dueReviewMinutes,
    required double baseReviewRatio,
    required bool forceRevisionOnly,
  }) {
    if (dailyMinutes <= 0) {
      return const DailyContentAllocation(
        dailyMinutes: 0,
        reviewCapacityMinutes: 0,
        newBudgetMinutes: 0,
        reviewPressure: 0,
        recoveryMode: true,
        newReductionFraction: 1,
        dueOverflow: false,
      );
    }

    final safeReviewRatio = baseReviewRatio.clamp(0.05, 0.95);
    final baseReviewBudget = dailyMinutes * safeReviewRatio;
    final baseNewBudget =
        (dailyMinutes - baseReviewBudget).clamp(0, dailyMinutes);

    final reviewPressure = dueReviewMinutes <= 0
        ? 0.0
        : dueReviewMinutes / (baseReviewBudget <= 0 ? 1.0 : baseReviewBudget);

    final reductionFraction = switch (reviewPressure) {
      <= 0.9 => 0.0,
      <= 1.2 => 0.25,
      <= 1.5 => 0.50,
      _ => 1.0,
    };

    var newBudgetMinutes = baseNewBudget * (1.0 - reductionFraction);
    var reviewCapacityMinutes = dailyMinutes - newBudgetMinutes;
    var recoveryMode = reductionFraction >= 1.0;

    var dueOverflow = dueReviewMinutes > reviewCapacityMinutes + 1e-9;
    if (forceRevisionOnly && dueOverflow) {
      newBudgetMinutes = 0;
      reviewCapacityMinutes = dailyMinutes;
      recoveryMode = true;
      dueOverflow = dueReviewMinutes > reviewCapacityMinutes + 1e-9;
    }

    return DailyContentAllocation(
      dailyMinutes: dailyMinutes,
      reviewCapacityMinutes: reviewCapacityMinutes,
      newBudgetMinutes: newBudgetMinutes,
      reviewPressure: reviewPressure,
      recoveryMode: recoveryMode,
      newReductionFraction: reductionFraction,
      dueOverflow: dueOverflow,
    );
  }
}
