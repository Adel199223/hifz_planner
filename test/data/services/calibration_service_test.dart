import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/calibration_repo.dart';
import 'package:hifz_planner/data/repositories/settings_repo.dart';
import 'package:hifz_planner/data/services/calibration_service.dart';
import 'package:hifz_planner/data/time/local_day_time.dart';

void main() {
  late AppDatabase db;
  late CalibrationRepo calibrationRepo;
  late SettingsRepo settingsRepo;
  late CalibrationService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    calibrationRepo = CalibrationRepo(db);
    settingsRepo = SettingsRepo(db);
    service = CalibrationService(calibrationRepo, settingsRepo);
  });

  tearDown(() async {
    await db.close();
  });

  test('medianMinutesPerAyah handles odd/even counts and outlier robustness',
      () async {
    await calibrationRepo.insertSample(
      sampleKind: 'new_memorization',
      durationSeconds: 60,
      ayahCount: 1,
      createdAtDay: 1,
    );
    await calibrationRepo.insertSample(
      sampleKind: 'new_memorization',
      durationSeconds: 180,
      ayahCount: 1,
      createdAtDay: 2,
    );
    await calibrationRepo.insertSample(
      sampleKind: 'new_memorization',
      durationSeconds: 120,
      ayahCount: 1,
      createdAtDay: 3,
    );
    var samples = await calibrationRepo.getRecentSamples(
      sampleKind: 'new_memorization',
      limit: 30,
    );
    expect(medianMinutesPerAyah(samples), 2.0);

    await calibrationRepo.insertSample(
      sampleKind: 'new_memorization',
      durationSeconds: 240,
      ayahCount: 1,
      createdAtDay: 4,
    );
    samples = await calibrationRepo.getRecentSamples(
      sampleKind: 'new_memorization',
      limit: 30,
    );
    expect(medianMinutesPerAyah(samples), 2.5);

    await calibrationRepo.insertSample(
      sampleKind: 'new_memorization',
      durationSeconds: 3600,
      ayahCount: 1,
      createdAtDay: 5,
    );
    samples = await calibrationRepo.getRecentSamples(
      sampleKind: 'new_memorization',
      limit: 30,
    );
    expect(medianMinutesPerAyah(samples), 3.0);
  });

  test('getPreview uses only most recent 30 entries per type', () async {
    for (var i = 1; i <= 35; i++) {
      await calibrationRepo.insertSample(
        sampleKind: 'new_memorization',
        durationSeconds: i * 60,
        ayahCount: 1,
        createdAtDay: i,
      );
    }

    final preview = await service.getPreview(limitPerType: 30);

    expect(preview.newSampleCount, 30);
    expect(preview.medianNewMinutesPerAyah, 20.5);
    expect(preview.reviewSampleCount, 0);
    expect(preview.medianReviewMinutesPerAyah, isNull);
  });

  test('applyCalibration validates grade distribution structure', () async {
    await service.logSample(
      kind: CalibrationSampleKind.newMemorization,
      durationMinutes: 2,
      ayahCount: 1,
      nowLocal: DateTime(2026, 1, 1, 10),
    );

    expect(
      () => service.applyCalibration(
        timing: CalibrationApplyTiming.immediate,
        gradeDistributionPercent: {5: 100},
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => service.applyCalibration(
        timing: CalibrationApplyTiming.immediate,
        gradeDistributionPercent: {5: 50, 4: 25, 3: 15, 2: 7, 0: 1},
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('immediate apply updates settings and clears pending update', () async {
    final now = DateTime(2026, 1, 1, 10, 0, 0);
    final today = localDayIndex(now);

    await settingsRepo.upsertPendingCalibrationUpdate(
      avgNewMinutesPerAyah: 9.9,
      avgReviewMinutesPerAyah: 9.9,
      effectiveDay: today,
      createdAtDay: today - 1,
    );
    await service.logSample(
      kind: CalibrationSampleKind.newMemorization,
      durationMinutes: 2,
      ayahCount: 1,
      nowLocal: now,
    );
    await service.logSample(
      kind: CalibrationSampleKind.review,
      durationMinutes: 1,
      ayahCount: 2,
      nowLocal: now,
    );

    await service.applyCalibration(
      timing: CalibrationApplyTiming.immediate,
      gradeDistributionPercent: {5: 40, 4: 30, 3: 20, 2: 8, 0: 2},
      nowLocal: now,
    );

    final settings = await settingsRepo.getSettings(todayDayOverride: today);
    final pending = await settingsRepo.getPendingCalibrationUpdate();
    final distribution = jsonDecode(settings.typicalGradeDistributionJson!);

    expect(settings.avgNewMinutesPerAyah, 2.0);
    expect(settings.avgReviewMinutesPerAyah, 0.5);
    expect(distribution['5'], 40);
    expect(distribution['0'], 2);
    expect(settings.updatedAtDay, today);
    expect(pending, isNull);
  });

  test('tomorrow apply queues pending update without changing current settings',
      () async {
    final now = DateTime(2026, 1, 2, 10, 0, 0);
    final today = localDayIndex(now);

    await settingsRepo.updateSettings(
      avgNewMinutesPerAyah: 2.2,
      avgReviewMinutesPerAyah: 0.9,
      updatedAtDay: today,
    );
    await service.logSample(
      kind: CalibrationSampleKind.newMemorization,
      durationMinutes: 1.5,
      ayahCount: 1,
      nowLocal: now,
    );
    await service.logSample(
      kind: CalibrationSampleKind.review,
      durationMinutes: 0.7,
      ayahCount: 1,
      nowLocal: now,
    );

    await service.applyCalibration(
      timing: CalibrationApplyTiming.tomorrow,
      nowLocal: now,
    );

    final settings = await settingsRepo.getSettings(todayDayOverride: today);
    final pending = await settingsRepo.getPendingCalibrationUpdate();

    expect(settings.avgNewMinutesPerAyah, 2.2);
    expect(settings.avgReviewMinutesPerAyah, 0.9);
    expect(pending, isNotNull);
    expect(pending!.effectiveDay, today + 1);
    expect(pending.avgNewMinutesPerAyah, 1.5);
    expect(pending.avgReviewMinutesPerAyah, 0.7);
  });
}
