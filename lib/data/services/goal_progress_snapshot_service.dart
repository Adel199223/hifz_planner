import 'package:drift/drift.dart';

import 'daily_planner.dart';
import '../database/app_database.dart';
import 'planner_feedback.dart';
import 'scheduling/weekly_plan_generator.dart';

enum GoalFocus { steadyProgress, protectRetention, recoveryAndStabilize }

enum GoalProgressQualityBand { steady, mixed, strained }

enum GoalProgressSurfaceState {
  noMeaningfulHistory,
  sparseRecentActivity,
  steadyProgress,
  protectRetention,
  recoverySafely,
}

enum GoalCoachingRecommendation {
  staySteady,
  useMinimumDay,
  protectRetention,
  lightenSetup,
}

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
  int get practiceDaysLast7 => completedPracticeDaysLast7 ?? 0;
  int get delayedChecksLast7 => completedDelayedChecksLast7 ?? 0;
  int get reviewsLast7 => completedReviewsLast7 ?? 0;
  int get newPracticeLast7 => completedNewPracticeLast7 ?? 0;
  int get totalCompletedWorkLast7 =>
      delayedChecksLast7 + reviewsLast7 + newPracticeLast7;
  bool get hasRecentHistory =>
      practiceDaysLast7 > 0 ||
      delayedChecksLast7 > 0 ||
      reviewsLast7 > 0 ||
      newPracticeLast7 > 0;
  bool get hasMeaningfulHistory =>
      practiceDaysLast7 >= 2 || totalCompletedWorkLast7 >= 3;
  bool get isSparseRecentActivity => hasRecentHistory && !hasMeaningfulHistory;
  GoalProgressSurfaceState get surfaceState {
    if (focus == GoalFocus.recoveryAndStabilize) {
      return GoalProgressSurfaceState.recoverySafely;
    }
    if (!hasRecentHistory) {
      return GoalProgressSurfaceState.noMeaningfulHistory;
    }
    if (isSparseRecentActivity) {
      return GoalProgressSurfaceState.sparseRecentActivity;
    }
    if (focus == GoalFocus.protectRetention) {
      return GoalProgressSurfaceState.protectRetention;
    }
    return GoalProgressSurfaceState.steadyProgress;
  }
}

class GoalCoachingAdvice {
  const GoalCoachingAdvice({required this.recommendation});

  final GoalCoachingRecommendation recommendation;

  bool get isStaySteady =>
      recommendation == GoalCoachingRecommendation.staySteady;
  bool get isUseMinimumDay =>
      recommendation == GoalCoachingRecommendation.useMinimumDay;
  bool get isProtectRetention =>
      recommendation == GoalCoachingRecommendation.protectRetention;
  bool get isLightenSetup =>
      recommendation == GoalCoachingRecommendation.lightenSetup;
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

  GoalCoachingAdvice coachingFromTodayPlan(
    TodayPlan plan, {
    GoalProgressSnapshot? snapshot,
  }) {
    final feedback = PlannerFeedbackSnapshot.fromTodayPlan(plan);
    final resolvedSnapshot = snapshot ?? fromFeedback(feedback);
    return _coachingFromFeedback(
      feedback: feedback,
      snapshot: resolvedSnapshot,
    );
  }

  GoalCoachingAdvice coachingFromWeeklyPlan(
    WeeklyPlan? plan, {
    GoalProgressSnapshot? snapshot,
  }) {
    final feedback = PlannerFeedbackSnapshot.fromWeeklyPlan(plan);
    final resolvedSnapshot = snapshot ?? fromFeedback(feedback);
    return _coachingFromFeedback(
      feedback: feedback,
      snapshot: resolvedSnapshot,
    );
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
    final reviewLogs =
        await ((_db.select(_db.reviewLog)..where(
              (tbl) =>
                  tbl.tsDay.isBiggerOrEqualValue(fromDay) &
                  tbl.tsDay.isSmallerOrEqualValue(todayDay),
            ))
            .get());
    final completedStage4Sessions =
        await ((_db.select(_db.companionStage4Session)..where(
              (tbl) =>
                  tbl.endedDay.isNotNull() &
                  tbl.endedDay.isBiggerOrEqualValue(fromDay) &
                  tbl.endedDay.isSmallerOrEqualValue(todayDay) &
                  tbl.outcome.isNotNull() &
                  tbl.outcome.equals('abandoned').not(),
            ))
            .get());
    final completedChainSessions =
        await ((_db.select(_db.companionChainSession)..where(
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

  GoalCoachingAdvice _coachingFromFeedback({
    required PlannerFeedbackSnapshot feedback,
    required GoalProgressSnapshot snapshot,
  }) {
    final activeDays = snapshot.completedPracticeDaysLast7 ?? 0;
    final delayedChecks = snapshot.completedDelayedChecksLast7 ?? 0;
    final reviews = snapshot.completedReviewsLast7 ?? 0;
    final strainedQuality =
        snapshot.recentQualityBand == GoalProgressQualityBand.strained;
    final sparseHistory = !snapshot.hasRecentHistory || activeDays <= 1;
    final retentionHeavy =
        delayedChecks >= 2 ||
        reviews >= 4 ||
        feedback.newWorkPaused ||
        feedback.newWorkReduced ||
        feedback.reviewOnlyMode ||
        strainedQuality;

    if (feedback.isOverloaded) {
      if (strainedQuality ||
          feedback.recoveryDayCount > 0 ||
          delayedChecks >= 2 ||
          sparseHistory) {
        return const GoalCoachingAdvice(
          recommendation: GoalCoachingRecommendation.lightenSetup,
        );
      }
      return const GoalCoachingAdvice(
        recommendation: GoalCoachingRecommendation.useMinimumDay,
      );
    }

    if (feedback.minimumDayRecommended && sparseHistory) {
      return const GoalCoachingAdvice(
        recommendation: GoalCoachingRecommendation.useMinimumDay,
      );
    }

    if (feedback.isTight || retentionHeavy) {
      return const GoalCoachingAdvice(
        recommendation: GoalCoachingRecommendation.protectRetention,
      );
    }

    return const GoalCoachingAdvice(
      recommendation: GoalCoachingRecommendation.staySteady,
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
