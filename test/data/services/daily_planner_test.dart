import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/mem_unit_repo.dart';
import 'package:hifz_planner/data/repositories/progress_repo.dart';
import 'package:hifz_planner/data/repositories/quran_repo.dart';
import 'package:hifz_planner/data/repositories/schedule_repo.dart';
import 'package:hifz_planner/data/repositories/settings_repo.dart';
import 'package:hifz_planner/data/services/daily_planner.dart';
import 'package:hifz_planner/data/services/new_unit_generator.dart';

void main() {
  late AppDatabase db;
  late QuranRepo quranRepo;
  late MemUnitRepo memUnitRepo;
  late ScheduleRepo scheduleRepo;
  late SettingsRepo settingsRepo;
  late ProgressRepo progressRepo;
  late NewUnitGenerator newUnitGenerator;
  late DailyPlanner dailyPlanner;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    quranRepo = QuranRepo(db);
    memUnitRepo = MemUnitRepo(db);
    scheduleRepo = ScheduleRepo(db);
    settingsRepo = SettingsRepo(db);
    progressRepo = ProgressRepo(db);
    newUnitGenerator = NewUnitGenerator(quranRepo, memUnitRepo, scheduleRepo);
    dailyPlanner = DailyPlanner(
      db,
      settingsRepo,
      progressRepo,
      scheduleRepo,
      quranRepo,
      memUnitRepo,
      newUnitGenerator,
    );

    await _seedAyahs(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('uses mon..sun weekday override when present', () async {
    final monday = _findDayForWeekday(DateTime.monday);
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 10,
      minutesByWeekdayJson: '{"mon":4}',
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    await _seedDueUnits(
      memUnitRepo,
      db,
      todayDay: monday,
      count: 5,
    );

    final plan = await dailyPlanner.planToday(todayDay: monday);

    expect(plan.plannedReviews.length, 2);
    expect(plan.minutesPlannedReviews, 2.0);
  });

  test('falls back to daily_minutes_default when weekday json is invalid',
      () async {
    final monday = _findDayForWeekday(DateTime.monday);
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 10,
      minutesByWeekdayJson: '{bad-json',
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    await _seedDueUnits(
      memUnitRepo,
      db,
      todayDay: monday,
      count: 5,
    );

    final plan = await dailyPlanner.planToday(todayDay: monday);

    expect(plan.plannedReviews.length, 5);
  });

  test('review budget ratio follows support/standard/accelerated constants',
      () async {
    const todayDay = 100;
    await _seedDueUnits(
      memUnitRepo,
      db,
      todayDay: todayDay,
      count: 10,
    );

    await _configureSettings(
      settingsRepo,
      profile: 'support',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 10,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    final supportPlan = await dailyPlanner.planToday(todayDay: todayDay);
    expect(supportPlan.plannedReviews.length, 8);

    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 10,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    final standardPlan = await dailyPlanner.planToday(todayDay: todayDay);
    expect(standardPlan.plannedReviews.length, 7);

    await _configureSettings(
      settingsRepo,
      profile: 'accelerated',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 10,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    final acceleratedPlan = await dailyPlanner.planToday(todayDay: todayDay);
    expect(acceleratedPlan.plannedReviews.length, 6);
  });

  test('sorts due rows by overdue desc, reps asc, lapse_count desc', () async {
    const todayDay = 10;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 100,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );

    await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'u-a',
      dueDay: 8,
      reps: 2,
      lapseCount: 0,
    );
    await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'u-b',
      dueDay: 9,
      reps: 0,
      lapseCount: 0,
    );
    await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'u-c',
      dueDay: 9,
      reps: 0,
      lapseCount: 3,
    );

    final plan = await dailyPlanner.planToday(todayDay: todayDay);

    expect(
      plan.plannedReviews.map((row) => row.unit.unitKey).toList(),
      ['u-a', 'u-c', 'u-b'],
    );
  });

  test('plannedReviews uses budgeted subset when due load exceeds budget',
      () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 4,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    await _seedDueUnits(
      memUnitRepo,
      db,
      todayDay: todayDay,
      count: 5,
    );

    final plan = await dailyPlanner.planToday(todayDay: todayDay);

    expect(plan.plannedReviews.length, 2);
    expect(plan.revisionOnly, isFalse);
  });

  test('sets revisionOnly=true and skips new units on forced overload',
      () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 1,
      dailyMinutesDefault: 4,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 5,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    await _seedDueUnits(
      memUnitRepo,
      db,
      todayDay: todayDay,
      count: 5,
    );

    final plan = await dailyPlanner.planToday(todayDay: todayDay);

    expect(plan.revisionOnly, isTrue);
    expect(plan.plannedNewUnits, isEmpty);
    expect(plan.minutesPlannedNew, 0);
  });

  test('when not forced, overload still allows new-unit generation', () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 4,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 5,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 0,
    );
    await _seedDueUnits(
      memUnitRepo,
      db,
      todayDay: todayDay,
      count: 5,
    );

    final plan = await dailyPlanner.planToday(todayDay: todayDay);

    expect(plan.revisionOnly, isFalse);
    expect(plan.plannedReviews.length, 2);
    expect(plan.plannedNewUnits, isNotEmpty);
    expect(plan.minutesPlannedNew, greaterThan(0));
  });

  test('metadata guard blocks new units when cursor ayah page metadata missing',
      () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 30,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 5,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 1,
    );

    await (db.update(db.ayah)
          ..where((tbl) => tbl.surah.equals(1) & tbl.ayah.equals(1)))
        .write(const AyahCompanion(pageMadina: Value(null)));

    final plan = await dailyPlanner.planToday(todayDay: todayDay);

    expect(plan.plannedNewUnits, isEmpty);
    expect(plan.minutesPlannedNew, 0);
    expect(plan.message, 'Import page metadata first');
  });

  test('metadata guard blocks when next-20 page coverage is below 90%',
      () async {
    const todayDay = 100;
    await _configureSettings(
      settingsRepo,
      profile: 'standard',
      forceRevisionOnly: 0,
      dailyMinutesDefault: 30,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 5,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      requirePageMetadata: 1,
    );

    for (final ayah in [2, 3, 4]) {
      await (db.update(db.ayah)
            ..where((tbl) => tbl.surah.equals(1) & tbl.ayah.equals(ayah)))
          .write(const AyahCompanion(pageMadina: Value(null)));
    }

    final plan = await dailyPlanner.planToday(todayDay: todayDay);

    expect(plan.plannedNewUnits, isEmpty);
    expect(plan.minutesPlannedNew, 0);
    expect(plan.message, 'Import page metadata first');
  });
}

Future<void> _configureSettings(
  SettingsRepo settingsRepo, {
  required String profile,
  required int forceRevisionOnly,
  required int dailyMinutesDefault,
  String? minutesByWeekdayJson,
  required int maxNewPagesPerDay,
  required int maxNewUnitsPerDay,
  required double avgNewMinutesPerAyah,
  required double avgReviewMinutesPerAyah,
  required int requirePageMetadata,
}) async {
  await settingsRepo.updateSettings(
    profile: profile,
    forceRevisionOnly: forceRevisionOnly,
    dailyMinutesDefault: dailyMinutesDefault,
    minutesByWeekdayJson: minutesByWeekdayJson,
    maxNewPagesPerDay: maxNewPagesPerDay,
    maxNewUnitsPerDay: maxNewUnitsPerDay,
    avgNewMinutesPerAyah: avgNewMinutesPerAyah,
    avgReviewMinutesPerAyah: avgReviewMinutesPerAyah,
    requirePageMetadata: requirePageMetadata,
  );
}

Future<void> _seedDueUnits(
  MemUnitRepo memUnitRepo,
  AppDatabase db, {
  required int todayDay,
  required int count,
}) async {
  for (var i = 0; i < count; i++) {
    await _seedDueUnit(
      memUnitRepo,
      db,
      unitKey: 'due-$i',
      dueDay: todayDay - 1,
      reps: i % 3,
      lapseCount: i % 2,
      startAyah: i + 1,
      endAyah: i + 1,
    );
  }
}

Future<void> _seedDueUnit(
  MemUnitRepo memUnitRepo,
  AppDatabase db, {
  required String unitKey,
  required int dueDay,
  required int reps,
  required int lapseCount,
  int startAyah = 1,
  int endAyah = 1,
}) async {
  final unitId = await memUnitRepo.create(
    MemUnitCompanion.insert(
      kind: 'ayah_range',
      unitKey: unitKey,
      startSurah: const Value(1),
      startAyah: Value(startAyah),
      endSurah: const Value(1),
      endAyah: Value(endAyah),
      createdAtDay: 100,
      updatedAtDay: 100,
    ),
  );

  await db.into(db.scheduleState).insert(
        ScheduleStateCompanion.insert(
          unitId: Value(unitId),
          ef: 2.5,
          reps: reps,
          intervalDays: reps == 0 ? 0 : 1,
          dueDay: dueDay,
          lapseCount: lapseCount,
        ),
      );
}

Future<void> _seedAyahs(AppDatabase db) async {
  final rows = <AyahCompanion>[];
  for (var ayah = 1; ayah <= 25; ayah++) {
    final page = ((ayah - 1) ~/ 5) + 1;
    rows.add(
      AyahCompanion.insert(
        surah: 1,
        ayah: ayah,
        textUthmani: 'ayah-$ayah',
        pageMadina: Value(page),
      ),
    );
  }
  await db.batch((batch) {
    batch.insertAll(db.ayah, rows);
  });
}

int _findDayForWeekday(int weekday) {
  for (var day = 0; day < 14; day++) {
    final date = DateTime(1970, 1, 1).add(Duration(days: day));
    if (date.weekday == weekday) {
      return day;
    }
  }
  throw StateError('Weekday $weekday not found in search window');
}
