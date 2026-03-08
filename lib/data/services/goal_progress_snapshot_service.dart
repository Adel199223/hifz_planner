import 'package:drift/drift.dart';

import 'daily_planner.dart';
import '../database/app_database.dart';
import 'planner_feedback.dart';
import 'scheduling/weekly_plan_generator.dart';

enum GoalFocus { steadyProgress, protectRetention, recoveryAndStabilize }

enum GoalProgressQualityBand { steady, mixed, strained }

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
  final GoalProgressQualityBand? recentQualityBand;

  bool get isSteadyProgress => focus == GoalFocus.steadyProgress;
  bool get isProtectRetention => focus == GoalFocus.protectRetention;
  bool get isRecoveryAndStabilize => focus == GoalFocus.recoveryAndStabilize;
  bool get hasRecentHistory =>
      (completedPracticeDaysLast7 ?? 0) > 0 ||
      (completedDelayedChecksLast7 ?? 0) > 0 ||
      (completedReviewsLast7 ?? 0) > 0 ||
      (completedNewPracticeLast7 ?? 0) > 0;
}

class GoalProgressSnapshotService {
  GoalProgressSnapshotService(this._db);

  final AppDatabase _db;

  GoalProgressSnapshot fromTodayPlan(TodayPlan plan) {
    return fromFeedback(PlannerFeedbackSnapshot.fromTodayPlan(plan));
  }

  GoalProgressSnapshot fromWeeklyPlan(WeeklyPlan? plan) {
    return fromFeedback(PlannerFeedbackSnapshot.fromWeeklyPlan(plan));
  }

  GoalProgressSnapshot fromFeedback(PlannerFeedbackSnapshot feedback) {
    return GoalProgressSnapshot(focus: _deriveFocus(feedback));
  }

  Future<GoalProgressSnapshot> buildTodaySnapshot({
    required TodayPlan plan,
    required int todayDay,
  }) {
    return _buildSnapshot(
      feedback: PlannerFeedbackSnapshot.fromTodayPlan(plan),
      todayDay: todayDay,
    );
  }

  Future<GoalProgressSnapshot> buildWeeklySnapshot({
    required WeeklyPlan? plan,
    required int todayDay,
  }) {
    return _buildSnapshot(
      feedback: PlannerFeedbackSnapshot.fromWeeklyPlan(plan),
      todayDay: todayDay,
    );
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

  Future<GoalProgressSnapshot> _buildSnapshot({
    required PlannerFeedbackSnapshot feedback,
    required int todayDay,
  }) async {
    final fromDay = todayDay - 6;
    final reviewLogs = await ((_db.select(
      _db.reviewLog,
    )..where(
            (tbl) =>
                tbl.tsDay.isBiggerOrEqualValue(fromDay) &
                tbl.tsDay.isSmallerOrEqualValue(todayDay),
          ))
        .get());
    final completedStage4Sessions =
        await ((_db.select(_db.companionStage4Session)
              ..where(
                (tbl) =>
                    tbl.endedDay.isNotNull() &
                    tbl.endedDay.isBiggerOrEqualValue(fromDay) &
                    tbl.endedDay.isSmallerOrEqualValue(todayDay) &
                    tbl.outcome.isNotNull() &
                    tbl.outcome.equals('abandoned').not(),
              ))
            .get());
    final completedChainSessions = await ((_db.select(_db.companionChainSession)
          ..where(
            (tbl) =>
                tbl.updatedAtDay.isBiggerOrEqualValue(fromDay) &
                tbl.updatedAtDay.isSmallerOrEqualValue(todayDay) &
                tbl.chainResult.equals('completed') &
                tbl.endedAtSeconds.isNotNull(),
          ))
        .get());

    final stage4LinkedChainIds = completedStage4Sessions
        .map((session) => session.chainSessionId)
        .whereType<int>()
        .toSet();
    final practiceSessions = completedChainSessions
        .where((session) => !stage4LinkedChainIds.contains(session.id))
        .toList(growable: false);

    final activeDays = <int>{
      ...reviewLogs.map((log) => log.tsDay),
      ...practiceSessions.map((session) => session.updatedAtDay),
      ...completedStage4Sessions
          .map((session) => session.endedDay)
          .whereType<int>(),
    };

    return GoalProgressSnapshot(
      focus: _deriveFocus(feedback),
      completedPracticeDaysLast7: activeDays.length,
      completedDelayedChecksLast7: completedStage4Sessions.length,
      completedReviewsLast7: reviewLogs.length,
      // The current persisted data does not separate new-vs-review practice
      // for non-stage4 chain sessions, so this is a best-effort practice
      // completion count until a future schema change makes mode explicit.
      completedNewPracticeLast7: practiceSessions.length,
      recentQualityBand: _deriveRecentQualityBand(reviewLogs),
    );
  }

  GoalProgressQualityBand? _deriveRecentQualityBand(
    List<ReviewLogData> reviewLogs,
  ) {
    if (reviewLogs.isEmpty) {
      return null;
    }

    final total = reviewLogs.length;
    final strongCount = reviewLogs.where((log) => log.gradeQ >= 4).length;
    final strainedCount = reviewLogs.where((log) => log.gradeQ <= 2).length;
    final failedCount = reviewLogs.where((log) => log.gradeQ == 0).length;

    final strongRatio = strongCount / total;
    final strainedRatio = strainedCount / total;
    final failedRatio = failedCount / total;

    if (strainedRatio >= 0.4 || failedRatio >= 0.2) {
      return GoalProgressQualityBand.strained;
    }
    if (strongRatio >= 0.65) {
      return GoalProgressQualityBand.steady;
    }
    return GoalProgressQualityBand.mixed;
  }
}
