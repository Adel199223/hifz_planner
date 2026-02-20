import 'dart:convert';

import '../database/app_database.dart';
import '../repositories/calibration_repo.dart';
import '../repositories/settings_repo.dart';
import '../time/local_day_time.dart';

enum CalibrationSampleKind {
  newMemorization,
  review,
}

enum CalibrationApplyTiming {
  immediate,
  tomorrow,
}

class CalibrationPreview {
  const CalibrationPreview({
    required this.newSampleCount,
    required this.reviewSampleCount,
    required this.medianNewMinutesPerAyah,
    required this.medianReviewMinutesPerAyah,
  });

  final int newSampleCount;
  final int reviewSampleCount;
  final double? medianNewMinutesPerAyah;
  final double? medianReviewMinutesPerAyah;
}

class CalibrationService {
  CalibrationService(this._calibrationRepo, this._settingsRepo);

  final CalibrationRepo _calibrationRepo;
  final SettingsRepo _settingsRepo;

  Future<int> logSample({
    required CalibrationSampleKind kind,
    required double durationMinutes,
    required int ayahCount,
    DateTime? nowLocal,
  }) async {
    if (durationMinutes <= 0) {
      throw ArgumentError.value(
        durationMinutes,
        'durationMinutes',
        'Duration must be positive.',
      );
    }
    if (ayahCount <= 0) {
      throw ArgumentError.value(
        ayahCount,
        'ayahCount',
        'Ayah count must be positive.',
      );
    }

    final effectiveNow = (nowLocal ?? DateTime.now()).toLocal();
    final durationSeconds = (durationMinutes * 60).round();

    return _calibrationRepo.insertSample(
      sampleKind: _sampleKindToDb(kind),
      durationSeconds: durationSeconds,
      ayahCount: ayahCount,
      createdAtDay: localDayIndex(effectiveNow),
      createdAtSeconds: nowLocalSecondsSinceMidnight(effectiveNow),
    );
  }

  Future<CalibrationPreview> getPreview({int limitPerType = 30}) async {
    final newSamples = await _calibrationRepo.getRecentSamples(
      sampleKind: _sampleKindToDb(CalibrationSampleKind.newMemorization),
      limit: limitPerType,
    );
    final reviewSamples = await _calibrationRepo.getRecentSamples(
      sampleKind: _sampleKindToDb(CalibrationSampleKind.review),
      limit: limitPerType,
    );

    return CalibrationPreview(
      newSampleCount: newSamples.length,
      reviewSampleCount: reviewSamples.length,
      medianNewMinutesPerAyah: medianMinutesPerAyah(newSamples),
      medianReviewMinutesPerAyah: medianMinutesPerAyah(reviewSamples),
    );
  }

  Future<void> applyCalibration({
    required CalibrationApplyTiming timing,
    Map<int, int>? gradeDistributionPercent,
    int limitPerType = 30,
    DateTime? nowLocal,
  }) async {
    final preview = await getPreview(limitPerType: limitPerType);
    final gradeDistributionJson =
        _encodeGradeDistributionOrNull(gradeDistributionPercent);

    if (preview.medianNewMinutesPerAyah == null &&
        preview.medianReviewMinutesPerAyah == null &&
        gradeDistributionJson == null) {
      throw StateError('No calibration values available to apply.');
    }

    final effectiveNow = (nowLocal ?? DateTime.now()).toLocal();
    final todayDay = localDayIndex(effectiveNow);

    if (timing == CalibrationApplyTiming.immediate) {
      await _settingsRepo.updateSettings(
        avgNewMinutesPerAyah: preview.medianNewMinutesPerAyah,
        avgReviewMinutesPerAyah: preview.medianReviewMinutesPerAyah,
        typicalGradeDistributionJson: gradeDistributionJson,
        updatedAtDay: todayDay,
      );
      await _settingsRepo.clearPendingCalibrationUpdate();
      return;
    }

    await _settingsRepo.upsertPendingCalibrationUpdate(
      avgNewMinutesPerAyah: preview.medianNewMinutesPerAyah,
      avgReviewMinutesPerAyah: preview.medianReviewMinutesPerAyah,
      typicalGradeDistributionJson: gradeDistributionJson,
      effectiveDay: todayDay + 1,
      createdAtDay: todayDay,
    );
  }

  String? _encodeGradeDistributionOrNull(Map<int, int>? distribution) {
    if (distribution == null) {
      return null;
    }

    const keys = {5, 4, 3, 2, 0};
    if (!distribution.keys.toSet().containsAll(keys) ||
        distribution.length != keys.length) {
      throw ArgumentError(
        'Grade distribution must include exactly q grades: 5,4,3,2,0.',
      );
    }

    final total = distribution.values.fold<int>(0, (sum, value) {
      if (value < 0 || value > 100) {
        throw ArgumentError(
          'Grade distribution percentages must be between 0 and 100.',
        );
      }
      return sum + value;
    });

    if (total != 100) {
      throw ArgumentError(
        'Grade distribution percentages must sum to 100.',
      );
    }

    final encoded = <String, int>{
      '5': distribution[5]!,
      '4': distribution[4]!,
      '3': distribution[3]!,
      '2': distribution[2]!,
      '0': distribution[0]!,
    };
    return jsonEncode(encoded);
  }
}

double? medianMinutesPerAyah(List<CalibrationSampleData> samples) {
  if (samples.isEmpty) {
    return null;
  }

  final values = samples
      .map(
        (sample) => (sample.durationSeconds / 60.0) / sample.ayahCount,
      )
      .toList()
    ..sort();

  final middle = values.length ~/ 2;
  if (values.length.isOdd) {
    return values[middle];
  }
  return (values[middle - 1] + values[middle]) / 2.0;
}

String _sampleKindToDb(CalibrationSampleKind kind) {
  return switch (kind) {
    CalibrationSampleKind.newMemorization => 'new_memorization',
    CalibrationSampleKind.review => 'review',
  };
}
