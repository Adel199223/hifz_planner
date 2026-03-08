import 'daily_planner.dart';
import 'planner_feedback.dart';
import 'scheduling/weekly_plan_generator.dart';

enum GoalFocus { steadyProgress, protectRetention, recoveryAndStabilize }

class GoalProgressSnapshot {
  const GoalProgressSnapshot({
    required this.focus,
    this.completedPracticeDaysLast7,
    this.completedDelayedChecksLast7,
    this.completedReviewsLast7,
    this.completedNewPracticeLast7,
    this.recentQualityBand,
  });

  final GoalFocus focus;
  final int? completedPracticeDaysLast7;
  final int? completedDelayedChecksLast7;
  final int? completedReviewsLast7;
  final int? completedNewPracticeLast7;
  final String? recentQualityBand;

  bool get isSteadyProgress => focus == GoalFocus.steadyProgress;
  bool get isProtectRetention => focus == GoalFocus.protectRetention;
  bool get isRecoveryAndStabilize => focus == GoalFocus.recoveryAndStabilize;
}

class GoalProgressSnapshotService {
  const GoalProgressSnapshotService();

  GoalProgressSnapshot fromTodayPlan(TodayPlan plan) {
    return fromFeedback(PlannerFeedbackSnapshot.fromTodayPlan(plan));
  }

  GoalProgressSnapshot fromWeeklyPlan(WeeklyPlan? plan) {
    return fromFeedback(PlannerFeedbackSnapshot.fromWeeklyPlan(plan));
  }

  GoalProgressSnapshot fromFeedback(PlannerFeedbackSnapshot feedback) {
    return GoalProgressSnapshot(focus: _deriveFocus(feedback));
  }

  GoalFocus _deriveFocus(PlannerFeedbackSnapshot feedback) {
    if (feedback.isOverloaded || feedback.recoveryDayCount > 0) {
      return GoalFocus.recoveryAndStabilize;
    }
    if (feedback.isTight || feedback.newWorkPaused || feedback.newWorkReduced) {
      return GoalFocus.protectRetention;
    }
    return GoalFocus.steadyProgress;
  }
}
