import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/settings_repo.dart';
import 'package:hifz_planner/data/time/local_day_time.dart';

void main() {
  late AppDatabase db;
  late SettingsRepo repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = SettingsRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('getSettings returns seeded singleton row', () async {
    final settings = await repo.getSettings();

    expect(settings.id, 1);
    expect(settings.profile, 'standard');
    expect(settings.forceRevisionOnly, 1);
    expect(settings.dailyMinutesDefault, 45);
    expect(settings.minutesByWeekdayJson, isNull);
    expect(settings.maxNewPagesPerDay, 1);
    expect(settings.maxNewUnitsPerDay, 8);
    expect(settings.avgNewMinutesPerAyah, 2.0);
    expect(settings.avgReviewMinutesPerAyah, 0.8);
    expect(settings.requirePageMetadata, 1);
    expect(settings.typicalGradeDistributionJson, isNull);
  });

  test('updateSettings partially updates fields and updates updated_at_day',
      () async {
    final updated = await repo.updateSettings(
      profile: 'accelerated',
      dailyMinutesDefault: 70,
      maxNewUnitsPerDay: 12,
      updatedAtDay: 25000,
    );

    final settings = await repo.getSettings();

    expect(updated, isTrue);
    expect(settings.profile, 'accelerated');
    expect(settings.dailyMinutesDefault, 70);
    expect(settings.maxNewUnitsPerDay, 12);
    expect(settings.maxNewPagesPerDay, 1);
    expect(settings.updatedAtDay, 25000);

    await repo.updateSettings(maxNewPagesPerDay: 2);
    final currentDay = localDayIndex(DateTime.now().toLocal());
    final refreshed = await repo.getSettings();

    expect(refreshed.maxNewPagesPerDay, 2);
    expect(refreshed.updatedAtDay, currentDay);
  });

  test('getSettings auto-applies due pending calibration updates', () async {
    await repo.upsertPendingCalibrationUpdate(
      avgNewMinutesPerAyah: 1.7,
      avgReviewMinutesPerAyah: 0.6,
      typicalGradeDistributionJson: '{"5":40,"4":30,"3":20,"2":8,"0":2}',
      effectiveDay: 12000,
      createdAtDay: 11999,
    );

    final settings = await repo.getSettings(todayDayOverride: 12000);
    final pending = await repo.getPendingCalibrationUpdate();

    expect(settings.avgNewMinutesPerAyah, 1.7);
    expect(settings.avgReviewMinutesPerAyah, 0.6);
    expect(
      settings.typicalGradeDistributionJson,
      '{"5":40,"4":30,"3":20,"2":8,"0":2}',
    );
    expect(settings.updatedAtDay, 12000);
    expect(pending, isNull);
  });

  test('future pending calibration update does not apply early', () async {
    await repo.updateSettings(
      avgNewMinutesPerAyah: 2.2,
      avgReviewMinutesPerAyah: 0.9,
      typicalGradeDistributionJson: '{"5":30,"4":30,"3":20,"2":10,"0":10}',
      updatedAtDay: 10000,
    );
    await repo.upsertPendingCalibrationUpdate(
      avgNewMinutesPerAyah: 1.5,
      avgReviewMinutesPerAyah: 0.5,
      typicalGradeDistributionJson: '{"5":50,"4":25,"3":15,"2":7,"0":3}',
      effectiveDay: 20000,
      createdAtDay: 15000,
    );

    final settings = await repo.getSettings(todayDayOverride: 19999);
    final pending = await repo.getPendingCalibrationUpdate();

    expect(settings.avgNewMinutesPerAyah, 2.2);
    expect(settings.avgReviewMinutesPerAyah, 0.9);
    expect(
      settings.typicalGradeDistributionJson,
      '{"5":30,"4":30,"3":20,"2":10,"0":10}',
    );
    expect(pending, isNotNull);
    expect(pending!.effectiveDay, 20000);
  });
}
