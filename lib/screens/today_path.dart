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

enum TodayQueueSectionKind { warmUp, dueReview, weakSpots, optionalNew }

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
    required this.warmUp,
    required this.dueReviews,
    required this.weakSpots,
    required this.optionalNew,
    required this.nextStep,
  });

  static const double protectReviewPressureThreshold = 0.9;
  static const double weakSpotThreshold = 0.35;
  final TodayPathMode mode;
  final TodayNewState newState;
  final PlannedReviewRow? warmUp;
  final List<PlannedReviewRow> dueReviews;
  final List<PlannedReviewRow> weakSpots;
  final List<MemUnitData> optionalNew;
  final TodayNextStep nextStep;

  bool get newUnlocked => newState == TodayNewState.unlocked;

  bool isWarmUpReview(PlannedReviewRow? row) {
    if (row == null || warmUp == null) {
      return false;
    }
    return row.unit.id == warmUp!.unit.id;
  }

  factory TodayPath.from({
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

    PlannedReviewRow? warmUp;
    for (final row in remainingReviews) {
      if (row.reinforcementWeight < weakSpotThreshold) {
        warmUp = row;
        break;
      }
    }
    warmUp ??= remainingReviews.isEmpty ? null : remainingReviews.first;

    final warmUpUnitId = warmUp?.unit.id;
    final weakSpots = <PlannedReviewRow>[];
    final dueReviews = <PlannedReviewRow>[];

    for (final row in remainingReviews) {
      if (row.unit.id == warmUpUnitId) {
        continue;
      }
      if (row.reinforcementWeight >= weakSpotThreshold) {
        weakSpots.add(row);
      } else {
        dueReviews.add(row);
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

    final reviewLead = warmUp ?? (dueReviews.isEmpty ? null : dueReviews.first);

    final TodayNextStep nextStep;
    if (mandatoryStage4 != null) {
      nextStep = TodayNextStep.stage4Due(mandatoryStage4);
    } else if (reviewLead != null) {
      nextStep = TodayNextStep.dueReview(reviewLead);
    } else if (weakSpots.isNotEmpty) {
      nextStep = TodayNextStep.weakSpot(weakSpots.first);
    } else if (optionalNew.isNotEmpty) {
      nextStep = TodayNextStep.newUnit(optionalNew.first);
    } else {
      nextStep = const TodayNextStep.resume();
    }

    return TodayPath(
      mode: mode,
      newState: newState,
      warmUp: warmUp,
      dueReviews: List<PlannedReviewRow>.unmodifiable(dueReviews),
      weakSpots: List<PlannedReviewRow>.unmodifiable(weakSpots),
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
