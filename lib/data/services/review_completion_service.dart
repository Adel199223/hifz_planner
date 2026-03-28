import 'package:drift/drift.dart' show Value;

import '../database/app_database.dart';
import '../repositories/companion_repo.dart';
import '../repositories/review_log_repo.dart';
import '../repositories/schedule_repo.dart';
import 'adaptive_queue_policy.dart';

enum ReviewLifecycleTransition {
  unchanged,
  promotedToMaintained,
  demotedToStable,
  demotedToReady,
}

class ReviewCompletionResult {
  const ReviewCompletionResult({
    required this.scheduleUpdated,
    required this.lifecycleTierBefore,
    required this.lifecycleTierAfter,
    required this.lifecycleTransition,
  });

  final bool scheduleUpdated;
  final String? lifecycleTierBefore;
  final String? lifecycleTierAfter;
  final ReviewLifecycleTransition lifecycleTransition;

  bool get promotedToMaintained =>
      lifecycleTransition == ReviewLifecycleTransition.promotedToMaintained;

  bool get lifecycleChanged =>
      lifecycleTransition != ReviewLifecycleTransition.unchanged;
}

class ReviewCompletionService {
  ReviewCompletionService(
    this._db,
    this._reviewLogRepo,
    this._scheduleRepo,
    this._companionRepo,
  );

  final AppDatabase _db;
  final ReviewLogRepo _reviewLogRepo;
  final ScheduleRepo _scheduleRepo;
  final CompanionRepo _companionRepo;
  static const AdaptiveQueuePolicy _adaptiveQueuePolicy = AdaptiveQueuePolicy();

  Future<ReviewCompletionResult> completeScheduledReview({
    required int unitId,
    required int gradeQ,
    required int completedDay,
    required int completedSeconds,
    AdaptiveLastErrorType? taggedErrorType,
    int? durationSeconds,
    int? mistakesCount,
  }) {
    return _db.transaction(() async {
      await _reviewLogRepo.insert(
        unitId: unitId,
        tsDay: completedDay,
        tsSeconds: completedSeconds,
        gradeQ: gradeQ,
        durationSeconds: durationSeconds,
        mistakesCount: mistakesCount,
      );

      final scheduleUpdated = await _scheduleRepo.applyReviewWithScheduler(
        unitId: unitId,
        todayDay: completedDay,
        gradeQ: gradeQ,
      );
      if (!scheduleUpdated) {
        throw StateError('Schedule state not found for unit $unitId');
      }
      final updatedSchedule = await _scheduleRepo.getScheduleState(unitId);
      if (updatedSchedule == null) {
        throw StateError('Updated schedule state not found for unit $unitId');
      }

      final lifecycle = await _companionRepo.getLifecycleState(unitId);
      final adaptiveStates =
          await _companionRepo.getAdaptiveStatesByUnitIds(<int>[unitId]);
      final adaptiveState =
          adaptiveStates[unitId] ?? const AdaptiveUnitMemoryState();
      final adaptiveUpdate = _adaptiveQueuePolicy.applyReviewGrade(
        state: adaptiveState,
        gradeQ: gradeQ,
        taggedErrorType: taggedErrorType,
      );
      final lifecycleTierBefore = lifecycle?.lifecycleTier;
      final lifecycleTierAfter =
          _adaptiveQueuePolicy.hasRealCompanionHistory(lifecycle)
              ? _resolveLifecycleTierAfterReview(
                  lifecycleTierBefore,
                  gradeQ,
                )
              : _adaptiveQueuePolicy.adoptedLifecycleTierAfterScheduledReview(
                  updatedSchedule: updatedSchedule,
                  gradeQ: gradeQ,
                  existingLifecycle: lifecycle,
                );
      final lifecycleTransition = _resolveLifecycleTransition(
        before: lifecycleTierBefore,
        after: lifecycleTierAfter,
      );

      if (lifecycle != null) {
        await _companionRepo.upsertLifecycleState(
          unitId: unitId,
          lifecycleTier: lifecycleTierAfter != lifecycleTierBefore
              ? Value(lifecycleTierAfter!)
              : const Value.absent(),
          updatedAtDay: completedDay,
          updatedAtSeconds: completedSeconds,
        );
      } else {
        await _companionRepo.upsertLifecycleState(
          unitId: unitId,
          lifecycleTier: Value(lifecycleTierAfter!),
          updatedAtDay: completedDay,
          updatedAtSeconds: completedSeconds,
        );
      }
      await _companionRepo.writeAdaptiveState(
        unitId: unitId,
        weakSpotScore: adaptiveUpdate.weakSpotScore,
        recentStruggleCount: adaptiveUpdate.recentStruggleCount,
        lastErrorType: _companionRepo.encodeAdaptiveLastErrorType(
          adaptiveUpdate.lastErrorType,
        ),
        updatedAtDay: completedDay,
        updatedAtSeconds: completedSeconds,
      );

      return ReviewCompletionResult(
        scheduleUpdated: scheduleUpdated,
        lifecycleTierBefore: lifecycleTierBefore,
        lifecycleTierAfter: lifecycleTierAfter,
        lifecycleTransition: lifecycleTransition,
      );
    });
  }

  String? _resolveLifecycleTierAfterReview(
    String? currentTier,
    int gradeQ,
  ) {
    return switch (currentTier) {
      'stable' => gradeQ >= 3 ? 'maintained' : 'ready',
      'maintained' => gradeQ >= 4
          ? 'maintained'
          : gradeQ == 3
              ? 'stable'
              : 'ready',
      _ => currentTier,
    };
  }

  ReviewLifecycleTransition _resolveLifecycleTransition({
    required String? before,
    required String? after,
  }) {
    if (before == after) {
      return ReviewLifecycleTransition.unchanged;
    }
    if (before == 'stable' && after == 'maintained') {
      return ReviewLifecycleTransition.promotedToMaintained;
    }
    if (before == 'maintained' && after == 'stable') {
      return ReviewLifecycleTransition.demotedToStable;
    }
    if ((before == 'stable' || before == 'maintained') && after == 'ready') {
      return ReviewLifecycleTransition.demotedToReady;
    }
    return ReviewLifecycleTransition.unchanged;
  }
}
