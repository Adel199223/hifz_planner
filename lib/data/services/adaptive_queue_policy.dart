import '../database/app_database.dart';

enum AdaptiveLastErrorType {
  wrongRecall('wrong_recall'),
  hesitation('hesitation'),
  weakLockIn('weak_lock_in'),
  similarConfusion('similar_confusion');

  const AdaptiveLastErrorType(this.dbValue);

  final String dbValue;

  static AdaptiveLastErrorType? fromDbValue(String? value) {
    if (value == null) {
      return null;
    }
    for (final type in values) {
      if (type.dbValue == value) {
        return type;
      }
    }
    return null;
  }
}

class AdaptiveUnitMemoryState {
  const AdaptiveUnitMemoryState({
    this.weakSpotScore = 0.0,
    this.recentStruggleCount = 0,
    this.lastErrorType,
  });

  final double weakSpotScore;
  final int recentStruggleCount;
  final AdaptiveLastErrorType? lastErrorType;
}

class AdaptiveQueueUpdate {
  const AdaptiveQueueUpdate({
    required this.weakSpotScore,
    required this.recentStruggleCount,
    required this.lastErrorType,
  });

  final double weakSpotScore;
  final int recentStruggleCount;
  final AdaptiveLastErrorType? lastErrorType;
}

class AdaptiveQueuePolicy {
  const AdaptiveQueuePolicy();

  bool scheduleLooksStarterLevel(ScheduleStateData schedule) {
    return schedule.reps <= 1 || schedule.intervalDays <= 1;
  }

  bool hasRealCompanionHistory(CompanionLifecycleStateData? lifecycle) {
    if (lifecycle == null) {
      return false;
    }
    if (lifecycle.stage4Status != 'none') {
      return true;
    }
    if (lifecycle.stage4LastCompletedDay != null ||
        lifecycle.stage4LastSessionId != null) {
      return true;
    }
    if (lifecycle.stage4PreSleepDueDay != null ||
        lifecycle.stage4NextDayDueDay != null ||
        lifecycle.stage4RetryDueDay != null) {
      return true;
    }
    return false;
  }

  String effectiveLifecycleTierForQueue({
    required ScheduleStateData schedule,
    required CompanionLifecycleStateData? lifecycle,
  }) {
    final rawTier = lifecycle?.lifecycleTier;
    if (hasRealCompanionHistory(lifecycle)) {
      return rawTier ?? 'emerging';
    }
    if (scheduleLooksStarterLevel(schedule)) {
      return rawTier ?? 'emerging';
    }
    if (rawTier == null || rawTier == 'emerging' || rawTier == 'ready') {
      return 'stable';
    }
    return rawTier;
  }

  String adoptedLifecycleTierAfterScheduledReview({
    required ScheduleStateData updatedSchedule,
    required int gradeQ,
    required CompanionLifecycleStateData? existingLifecycle,
  }) {
    if (hasRealCompanionHistory(existingLifecycle)) {
      return existingLifecycle?.lifecycleTier ?? 'ready';
    }
    if (gradeQ <= 2 || scheduleLooksStarterLevel(updatedSchedule)) {
      return 'ready';
    }
    return 'stable';
  }

  AdaptiveQueueUpdate applyReviewGrade({
    required AdaptiveUnitMemoryState state,
    required int gradeQ,
    AdaptiveLastErrorType? taggedErrorType,
  }) {
    return switch (gradeQ) {
      5 => AdaptiveQueueUpdate(
          weakSpotScore: _clampWeakSpotScore(state.weakSpotScore - 0.35),
          recentStruggleCount:
              _clampStruggleCount(state.recentStruggleCount - 2),
          lastErrorType: null,
        ),
      4 => AdaptiveQueueUpdate(
          weakSpotScore: _clampWeakSpotScore(state.weakSpotScore - 0.20),
          recentStruggleCount:
              _clampStruggleCount(state.recentStruggleCount - 1),
          lastErrorType: null,
        ),
      3 => AdaptiveQueueUpdate(
          weakSpotScore: _clampWeakSpotScore(state.weakSpotScore - 0.05),
          recentStruggleCount: _clampStruggleCount(state.recentStruggleCount),
          lastErrorType: null,
        ),
      2 => AdaptiveQueueUpdate(
          weakSpotScore: _clampWeakSpotScore(state.weakSpotScore + 0.20),
          recentStruggleCount:
              _clampStruggleCount(state.recentStruggleCount + 1),
          lastErrorType: taggedErrorType ?? AdaptiveLastErrorType.hesitation,
        ),
      0 => AdaptiveQueueUpdate(
          weakSpotScore: _clampWeakSpotScore(state.weakSpotScore + 0.35),
          recentStruggleCount:
              _clampStruggleCount(state.recentStruggleCount + 2),
          lastErrorType: taggedErrorType ?? AdaptiveLastErrorType.wrongRecall,
        ),
      _ => throw ArgumentError.value(
          gradeQ,
          'gradeQ',
          'Unsupported review grade. Expected one of 5, 4, 3, 2, or 0.',
        ),
    };
  }

  double _clampWeakSpotScore(double value) => value.clamp(0.0, 1.0).toDouble();

  int _clampStruggleCount(int value) => value < 0 ? 0 : value;

  int weakSpotPriorityRank({
    required ScheduleStateData schedule,
    required AdaptiveUnitMemoryState state,
  }) {
    final lastErrorType = state.lastErrorType;
    if (lastErrorType == AdaptiveLastErrorType.similarConfusion) {
      return 0;
    }
    if (lastErrorType == AdaptiveLastErrorType.wrongRecall &&
        state.recentStruggleCount >= 2) {
      return 1;
    }
    if (lastErrorType == AdaptiveLastErrorType.weakLockIn &&
        (schedule.intervalDays <= 3 || schedule.reps <= 2)) {
      return 2;
    }
    if (lastErrorType == AdaptiveLastErrorType.wrongRecall) {
      return 3;
    }
    if (lastErrorType == AdaptiveLastErrorType.hesitation) {
      return 4;
    }
    return 5;
  }
}
