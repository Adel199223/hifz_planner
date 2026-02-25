import '../../database/app_database.dart';
import '../../repositories/calibration_repo.dart';
import '../../time/local_day_time.dart';
import 'companion_models.dart';

class CompanionCalibrationBridge {
  CompanionCalibrationBridge(this._calibrationRepo);

  final CalibrationRepo _calibrationRepo;

  Future<void> onChainCompleted({
    required ChainResultSummary summary,
    required int ayahCount,
    required List<CompanionVerseAttemptData> attempts,
    DateTime? nowLocal,
  }) async {
    if (ayahCount <= 0) {
      return;
    }

    final hasStage4LifecycleAttempts = attempts.any(_isStage4LifecycleAttempt);

    final stageOneAttempts = attempts
        .where(
          (attempt) => attempt.stageCode == CompanionStage.guidedVisible.code,
        )
        .toList(growable: false);
    final stage1DurationMs = stageOneAttempts.fold<int>(
      0,
      (maxValue, attempt) =>
          attempt.timeOnChunkMs > maxValue ? attempt.timeOnChunkMs : maxValue,
    );
    if (!hasStage4LifecycleAttempts && stage1DurationMs > 0) {
      final newDurationSeconds = (stage1DurationMs / 1000).round().clamp(1, 86400);
      await _calibrationRepo.insertSample(
        sampleKind: 'new_memorization',
        durationSeconds: newDurationSeconds,
        ayahCount: ayahCount,
        createdAtDay: localDayIndex((nowLocal ?? DateTime.now()).toLocal()),
        createdAtSeconds:
            nowLocalSecondsSinceMidnight((nowLocal ?? DateTime.now()).toLocal()),
      );
    }

    final stageThreePassedAttempts = attempts
        .where(
          (attempt) =>
              attempt.stageCode == CompanionStage.hiddenReveal.code &&
              !_isStage4LifecycleAttempt(attempt) &&
              attempt.attemptType != 'encode_echo' &&
              attempt.evaluatorPassed == 1,
        )
        .toList(growable: false);

    final stage4PassedAttempts = attempts
        .where(
          (attempt) =>
              _isStage4LifecycleAttempt(attempt) &&
              attempt.attemptType != 'encode_echo' &&
              attempt.evaluatorPassed == 1,
        )
        .toList(growable: false);

    final preferredAttempts = hasStage4LifecycleAttempts
        ? stage4PassedAttempts
        : (stageThreePassedAttempts.isNotEmpty
            ? stageThreePassedAttempts
            : attempts
                .where(
                  (attempt) =>
                      !_isStage4LifecycleAttempt(attempt) &&
                      attempt.attemptType != 'encode_echo' &&
                      attempt.evaluatorPassed == 1,
                )
                .toList(
                  growable: false,
                ));

    final averageStrength = preferredAttempts.isEmpty
        ? summary.averageRetrievalStrength
        : preferredAttempts
                .map((attempt) => attempt.retrievalStrength)
                .reduce((a, b) => a + b) /
            preferredAttempts.length;

    final derivedMinutesPerAyah =
        (1.4 - (averageStrength * 0.6)).clamp(0.6, 2.2);
    final durationSeconds = (derivedMinutesPerAyah * ayahCount * 60).round();

    final effectiveNow = (nowLocal ?? DateTime.now()).toLocal();

    await _calibrationRepo.insertSample(
      sampleKind: 'review',
      durationSeconds: durationSeconds,
      ayahCount: ayahCount,
      createdAtDay: localDayIndex(effectiveNow),
      createdAtSeconds: nowLocalSecondsSinceMidnight(effectiveNow),
    );
  }

  bool _isStage4LifecycleAttempt(CompanionVerseAttemptData attempt) {
    final telemetry = attempt.telemetryJson;
    if (telemetry == null || telemetry.trim().isEmpty) {
      return false;
    }
    return telemetry.contains('"lifecycle_stage":"stage4"') ||
        telemetry.contains('"lifecycle_stage": "stage4"');
  }
}
