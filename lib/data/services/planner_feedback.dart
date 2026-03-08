import 'daily_planner.dart';
import 'scheduling/weekly_plan_generator.dart';

enum PlannerHealthState { onTrack, tight, overloaded }

class PlannerFeedbackSnapshot {
  const PlannerFeedbackSnapshot({
    required this.health,
    required this.backlogBurnDownSuggested,
    required this.minimumDayRecommended,
    required this.recoverySuggested,
    required this.newWorkPaused,
    required this.newWorkReduced,
    required this.hasStage4Pressure,
    required this.reviewOnlyMode,
    required this.reviewPressure,
    required this.recoveryDayCount,
    required this.dueSoonSessionCount,
  });

  final PlannerHealthState health;
  final bool backlogBurnDownSuggested;
  final bool minimumDayRecommended;
  final bool recoverySuggested;
  final bool newWorkPaused;
  final bool newWorkReduced;
  final bool hasStage4Pressure;
  final bool reviewOnlyMode;
  final double reviewPressure;
  final int recoveryDayCount;
  final int dueSoonSessionCount;

  bool get isOnTrack => health == PlannerHealthState.onTrack;
  bool get isTight => health == PlannerHealthState.tight;
  bool get isOverloaded => health == PlannerHealthState.overloaded;

  factory PlannerFeedbackSnapshot.fromTodayPlan(TodayPlan plan) {
    final hasStage4Pressure = plan.plannedStage4Due.isNotEmpty;
    final reviewPressure = plan.reviewPressure;
    final newWorkPaused =
        plan.stage4BlocksNewByDefault ||
        (plan.plannedNewUnits.isEmpty &&
            (plan.plannedReviews.isNotEmpty || hasStage4Pressure));
    final newWorkReduced =
        !newWorkPaused && (reviewPressure >= 0.9 || hasStage4Pressure);

    final health = switch ((plan.recoveryMode, plan.stage4BlocksNewByDefault)) {
      (true, _) || (_, true) => PlannerHealthState.overloaded,
      _ when reviewPressure > 1.2 => PlannerHealthState.overloaded,
      _ when reviewPressure >= 0.9 || hasStage4Pressure =>
        PlannerHealthState.tight,
      _ => PlannerHealthState.onTrack,
    };

    return PlannerFeedbackSnapshot(
      health: health,
      backlogBurnDownSuggested:
          health != PlannerHealthState.onTrack &&
          (plan.plannedReviews.isNotEmpty || hasStage4Pressure),
      minimumDayRecommended:
          health != PlannerHealthState.onTrack || hasStage4Pressure,
      recoverySuggested:
          health == PlannerHealthState.overloaded || reviewPressure >= 1.0,
      newWorkPaused: newWorkPaused,
      newWorkReduced: newWorkReduced,
      hasStage4Pressure: hasStage4Pressure,
      reviewOnlyMode: plan.revisionOnly,
      reviewPressure: reviewPressure,
      recoveryDayCount: plan.recoveryMode ? 1 : 0,
      dueSoonSessionCount: plan.sessions
          .where((session) => session.status == PlannedSessionStatus.dueSoon)
          .length,
    );
  }

  factory PlannerFeedbackSnapshot.fromWeeklyPlan(WeeklyPlan? plan) {
    if (plan == null || plan.days.isEmpty) {
      return const PlannerFeedbackSnapshot(
        health: PlannerHealthState.onTrack,
        backlogBurnDownSuggested: false,
        minimumDayRecommended: false,
        recoverySuggested: false,
        newWorkPaused: false,
        newWorkReduced: false,
        hasStage4Pressure: false,
        reviewOnlyMode: false,
        reviewPressure: 0,
        recoveryDayCount: 0,
        dueSoonSessionCount: 0,
      );
    }

    var maxReviewPressure = 0.0;
    var recoveryDayCount = 0;
    var dueSoonSessionCount = 0;
    var reviewOnlyDays = 0;

    for (final day in plan.days) {
      if (day.reviewPressure > maxReviewPressure) {
        maxReviewPressure = day.reviewPressure;
      }
      if (day.recoveryMode) {
        recoveryDayCount += 1;
      }
      if (day.revisionOnlyDay) {
        reviewOnlyDays += 1;
      }
      dueSoonSessionCount += day.sessions
          .where((session) => session.status == PlannedSessionStatus.dueSoon)
          .length;
    }

    final health = switch ((
      recoveryDayCount > 0,
      maxReviewPressure,
      dueSoonSessionCount > 0,
      reviewOnlyDays > 0,
    )) {
      (true, _, _, _) => PlannerHealthState.overloaded,
      (_, > 1.2, _, _) => PlannerHealthState.overloaded,
      (_, _, true, _) || (_, _, _, true) => PlannerHealthState.tight,
      (_, >= 0.9, _, _) => PlannerHealthState.tight,
      _ => PlannerHealthState.onTrack,
    };

    final newWorkPaused =
        reviewOnlyDays == plan.days.length &&
        plan.days.where((day) => day.enabledStudyDay).isNotEmpty;

    return PlannerFeedbackSnapshot(
      health: health,
      backlogBurnDownSuggested:
          health != PlannerHealthState.onTrack &&
          (dueSoonSessionCount > 0 ||
              reviewOnlyDays > 0 ||
              recoveryDayCount > 0),
      minimumDayRecommended: health != PlannerHealthState.onTrack,
      recoverySuggested:
          health == PlannerHealthState.overloaded || reviewOnlyDays > 0,
      newWorkPaused: newWorkPaused,
      newWorkReduced: !newWorkPaused && health == PlannerHealthState.tight,
      hasStage4Pressure: false,
      reviewOnlyMode: reviewOnlyDays > 0,
      reviewPressure: maxReviewPressure,
      recoveryDayCount: recoveryDayCount,
      dueSoonSessionCount: dueSoonSessionCount,
    );
  }
}
