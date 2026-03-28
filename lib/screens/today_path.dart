import '../data/database/app_database.dart';
import '../data/services/daily_planner.dart';

enum TodayPathMode { green, protect, recovery }

enum TodayNextStepKind { stage4Due, dueReview, weakSpot, newUnit, resume }

enum TodayNewState {
  unlocked,
  lockedStage4,
  lockedReviewHealth,
  lockedSetup,
  noneAvailable,
}

enum TodayQueueSectionKind {
  lockIn,
  weakSpots,
  recentReview,
  maintenanceReview,
  optionalNew,
}

class TodayNextStep {
  const TodayNextStep._({
    required this.kind,
    this.stage4Item,
    this.reviewRow,
    this.newUnit,
  });

  const TodayNextStep.stage4Due(Stage4DueItem item)
      : this._(
          kind: TodayNextStepKind.stage4Due,
          stage4Item: item,
        );

  const TodayNextStep.dueReview(PlannedReviewRow row)
      : this._(
          kind: TodayNextStepKind.dueReview,
          reviewRow: row,
        );

  const TodayNextStep.weakSpot(PlannedReviewRow row)
      : this._(
          kind: TodayNextStepKind.weakSpot,
          reviewRow: row,
        );

  const TodayNextStep.newUnit(MemUnitData unit)
      : this._(
          kind: TodayNextStepKind.newUnit,
          newUnit: unit,
        );

  const TodayNextStep.resume()
      : this._(
          kind: TodayNextStepKind.resume,
        );

  final TodayNextStepKind kind;
  final Stage4DueItem? stage4Item;
  final PlannedReviewRow? reviewRow;
  final MemUnitData? newUnit;
}

class TodayPath {
  const TodayPath({
    required this.mode,
    required this.newState,
    required this.lockInReviews,
    required this.weakSpots,
    required this.recentReviews,
    required this.maintenanceReviews,
    required this.optionalNew,
    required this.nextStep,
  });

  static const double protectReviewPressureThreshold = 0.9;

  final TodayPathMode mode;
  final TodayNewState newState;
  final List<PlannedReviewRow> lockInReviews;
  final List<PlannedReviewRow> weakSpots;
  final List<PlannedReviewRow> recentReviews;
  final List<PlannedReviewRow> maintenanceReviews;
  final List<MemUnitData> optionalNew;
  final TodayNextStep nextStep;

  bool get newUnlocked => newState == TodayNewState.unlocked;

  PlannedReviewRow? get warmUp =>
      lockInReviews.isEmpty ? null : lockInReviews.first;

  bool isWarmUpReview(PlannedReviewRow? row) {
    if (row == null) {
      return false;
    }
    return row.bucket == AdaptiveQueueBucket.lockIn;
  }

  static TodayPath from({
    required TodayPlan plan,
    required List<Stage4DueItem> remainingStage4Due,
    required List<PlannedReviewRow> remainingReviews,
    required List<MemUnitData> remainingNewUnits,
  }) {
    final mode = _resolveMode(plan);
    final newState = _resolveNewState(
      plan: plan,
      remainingNewUnits: remainingNewUnits,
    );

    final lockInReviews = <PlannedReviewRow>[];
    final weakSpots = <PlannedReviewRow>[];
    final recentReviews = <PlannedReviewRow>[];
    final maintenanceReviews = <PlannedReviewRow>[];

    for (final row in remainingReviews) {
      switch (row.bucket) {
        case AdaptiveQueueBucket.lockIn:
          lockInReviews.add(row);
          break;
        case AdaptiveQueueBucket.weakSpot:
          weakSpots.add(row);
          break;
        case AdaptiveQueueBucket.recentReview:
          recentReviews.add(row);
          break;
        case AdaptiveQueueBucket.maintenance:
          maintenanceReviews.add(row);
          break;
      }
    }

    final optionalNew = newState == TodayNewState.unlocked
        ? List<MemUnitData>.unmodifiable(remainingNewUnits)
        : const <MemUnitData>[];

    Stage4DueItem? mandatoryStage4;
    for (final item in remainingStage4Due) {
      if (item.mandatory) {
        mandatoryStage4 = item;
        break;
      }
    }

    final TodayNextStep nextStep;
    if (mandatoryStage4 != null) {
      nextStep = TodayNextStep.stage4Due(mandatoryStage4);
    } else if (lockInReviews.isNotEmpty) {
      nextStep = TodayNextStep.dueReview(lockInReviews.first);
    } else if (weakSpots.isNotEmpty) {
      nextStep = TodayNextStep.weakSpot(weakSpots.first);
    } else if (recentReviews.isNotEmpty) {
      nextStep = TodayNextStep.dueReview(recentReviews.first);
    } else if (maintenanceReviews.isNotEmpty) {
      nextStep = TodayNextStep.dueReview(maintenanceReviews.first);
    } else if (optionalNew.isNotEmpty) {
      nextStep = TodayNextStep.newUnit(optionalNew.first);
    } else {
      nextStep = const TodayNextStep.resume();
    }

    return TodayPath(
      mode: mode,
      newState: newState,
      lockInReviews: List<PlannedReviewRow>.unmodifiable(lockInReviews),
      weakSpots: List<PlannedReviewRow>.unmodifiable(weakSpots),
      recentReviews: List<PlannedReviewRow>.unmodifiable(recentReviews),
      maintenanceReviews:
          List<PlannedReviewRow>.unmodifiable(maintenanceReviews),
      optionalNew: optionalNew,
      nextStep: nextStep,
    );
  }

  static TodayPathMode _resolveMode(TodayPlan plan) {
    if (plan.recoveryMode) {
      return TodayPathMode.recovery;
    }
    if (plan.stage4BlocksNewByDefault ||
        plan.newAvailability == TodayNewAvailability.blockedReviewHealth ||
        plan.reviewPressure > protectReviewPressureThreshold ||
        plan.revisionOnly) {
      return TodayPathMode.protect;
    }
    return TodayPathMode.green;
  }

  static TodayNewState _resolveNewState({
    required TodayPlan plan,
    required List<MemUnitData> remainingNewUnits,
  }) {
    return switch (plan.newAvailability) {
      TodayNewAvailability.available => remainingNewUnits.isNotEmpty
          ? TodayNewState.unlocked
          : TodayNewState.noneAvailable,
      TodayNewAvailability.blockedStage4 => TodayNewState.lockedStage4,
      TodayNewAvailability.blockedSetup => TodayNewState.lockedSetup,
      TodayNewAvailability.blockedReviewHealth =>
        TodayNewState.lockedReviewHealth,
      TodayNewAvailability.noneAvailable => TodayNewState.noneAvailable,
    };
  }
}
