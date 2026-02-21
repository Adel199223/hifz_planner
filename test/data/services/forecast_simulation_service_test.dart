import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/progress_repo.dart';
import 'package:hifz_planner/data/repositories/quran_repo.dart';
import 'package:hifz_planner/data/repositories/schedule_repo.dart';
import 'package:hifz_planner/data/repositories/settings_repo.dart';
import 'package:hifz_planner/data/services/forecast_simulation_service.dart';

void main() {
  late AppDatabase db;
  late SettingsRepo settingsRepo;
  late ProgressRepo progressRepo;
  late ScheduleRepo scheduleRepo;
  late QuranRepo quranRepo;
  late ForecastSimulationService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settingsRepo = SettingsRepo(db);
    progressRepo = ProgressRepo(db);
    scheduleRepo = ScheduleRepo(db);
    quranRepo = QuranRepo(db);
    service = ForecastSimulationService(
      db,
      settingsRepo,
      progressRepo,
      scheduleRepo,
      quranRepo,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('simulate does not mutate persisted state', () async {
    await _seedLinearAyahs(db, ayahCount: 12, includePageMetadata: true);
    await _configureSettings(
      settingsRepo,
      forceRevisionOnly: 0,
      requirePageMetadata: 0,
      maxNewPagesPerDay: 5,
      maxNewUnitsPerDay: 8,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      dailyMinutesDefault: 60,
    );
    await _insertDueCustomUnits(db, count: 12, dueDay: 0);

    final beforeCursor = await progressRepo.getCursor();
    final beforeMemUnitCount = await _tableCount(db, 'mem_unit');
    final beforeSchedule = await _scheduleSnapshot(db);

    await service.simulate(
      startDayOverride: 100,
      maxSimulationDays: 14,
      targetSurah: 1,
      targetAyah: 12,
    );

    final afterCursor = await progressRepo.getCursor();
    final afterMemUnitCount = await _tableCount(db, 'mem_unit');
    final afterSchedule = await _scheduleSnapshot(db);

    expect(afterCursor.nextSurah, beforeCursor.nextSurah);
    expect(afterCursor.nextAyah, beforeCursor.nextAyah);
    expect(afterMemUnitCount, beforeMemUnitCount);
    expect(afterSchedule, beforeSchedule);
  });

  test('simulate returns completion date for reachable small target', () async {
    await _seedLinearAyahs(db, ayahCount: 10, includePageMetadata: true);
    await _configureSettings(
      settingsRepo,
      forceRevisionOnly: 0,
      requirePageMetadata: 0,
      maxNewPagesPerDay: 10,
      maxNewUnitsPerDay: 10,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      dailyMinutesDefault: 60,
    );

    final result = await service.simulate(
      startDayOverride: 100,
      maxSimulationDays: 30,
      targetSurah: 1,
      targetAyah: 10,
    );

    expect(result.estimatedCompletionDate, isNotNull);
    expect(result.weeklyPoints, isNotEmpty);
    expect(result.weeklyMinutesCurve.length, result.weeklyPoints.length);
    expect(result.revisionOnlyRatioCurve.length, result.weeklyPoints.length);
    expect(result.avgNewPagesPerDayCurve.length, result.weeklyPoints.length);
  });

  test('simulate respects weekday minutes override', () async {
    await _seedLinearAyahs(db, ayahCount: 1, includePageMetadata: true);
    await _configureSettings(
      settingsRepo,
      forceRevisionOnly: 0,
      requirePageMetadata: 0,
      maxNewPagesPerDay: 1,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      dailyMinutesDefault: 10,
      minutesByWeekdayJson: '{"mon":100}',
    );
    await _insertDueCustomUnits(db, count: 400, dueDay: 0);

    final monday = _findDayForWeekday(DateTime.monday);
    final result = await service.simulate(
      startDayOverride: monday,
      maxSimulationDays: 7,
      targetSurah: 1,
      targetAyah: 2,
    );

    expect(result.weeklyPoints, isNotEmpty);
    expect(result.weeklyPoints.first.weeklyMinutes, closeTo(112.0, 1e-9));
  });

  test('simulate revision-only ratio reflects forced overload', () async {
    await _seedLinearAyahs(db, ayahCount: 12, includePageMetadata: true);
    await _configureSettings(
      settingsRepo,
      forceRevisionOnly: 1,
      requirePageMetadata: 0,
      maxNewPagesPerDay: 10,
      maxNewUnitsPerDay: 10,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      dailyMinutesDefault: 10,
    );
    await _insertDueCustomUnits(db, count: 40, dueDay: 0);

    final result = await service.simulate(
      startDayOverride: 200,
      maxSimulationDays: 7,
      targetSurah: 1,
      targetAyah: 12,
    );

    expect(result.estimatedCompletionDate, isNull);
    expect(result.revisionOnlyRatioCurve, isNotEmpty);
    expect(result.revisionOnlyRatioCurve.first, closeTo(1.0, 1e-9));
  });

  test('simulate returns null completion with reason when horizon exceeded',
      () async {
    await _seedLinearAyahs(db, ayahCount: 10, includePageMetadata: true);
    await _configureSettings(
      settingsRepo,
      forceRevisionOnly: 0,
      requirePageMetadata: 0,
      maxNewPagesPerDay: 1,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      dailyMinutesDefault: 45,
    );

    final result = await service.simulate(
      startDayOverride: 50,
      maxSimulationDays: 5,
      targetSurah: 1,
      targetAyah: 10,
    );

    expect(result.estimatedCompletionDate, isNull);
    expect(result.incompleteReason, isNotNull);
    expect(result.incompleteReason, contains('horizon'));
  });

  test(
      'simulate chooses distribution cycle strategy when grade distribution exists',
      () async {
    await _seedLinearAyahs(db, ayahCount: 1, includePageMetadata: true);
    await _configureSettings(
      settingsRepo,
      forceRevisionOnly: 0,
      requirePageMetadata: 0,
      maxNewPagesPerDay: 1,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      dailyMinutesDefault: 10,
      typicalGradeDistributionJson: '{"5":40,"4":30,"3":20,"2":8,"0":2}',
    );

    final result = await service.simulate(
      startDayOverride: 1,
      maxSimulationDays: 1,
      targetSurah: 1,
      targetAyah: 2,
    );

    expect(result.gradeStrategyUsed, ForecastGradeStrategy.distributionCycle);
  });

  test('simulate falls back to default strategy without distribution',
      () async {
    await _seedLinearAyahs(db, ayahCount: 1, includePageMetadata: true);
    await _configureSettings(
      settingsRepo,
      forceRevisionOnly: 0,
      requirePageMetadata: 0,
      maxNewPagesPerDay: 1,
      maxNewUnitsPerDay: 0,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      dailyMinutesDefault: 10,
      typicalGradeDistributionJson: '{"5":50}',
    );

    final result = await service.simulate(
      startDayOverride: 1,
      maxSimulationDays: 1,
      targetSurah: 1,
      targetAyah: 2,
    );

    expect(result.gradeStrategyUsed, ForecastGradeStrategy.defaultFallback);
  });
}

Future<void> _configureSettings(
  SettingsRepo settingsRepo, {
  required int forceRevisionOnly,
  required int requirePageMetadata,
  required int maxNewPagesPerDay,
  required int maxNewUnitsPerDay,
  required double avgNewMinutesPerAyah,
  required double avgReviewMinutesPerAyah,
  required int dailyMinutesDefault,
  String? minutesByWeekdayJson,
  String? typicalGradeDistributionJson,
}) async {
  await settingsRepo.updateSettings(
    profile: 'standard',
    forceRevisionOnly: forceRevisionOnly,
    requirePageMetadata: requirePageMetadata,
    maxNewPagesPerDay: maxNewPagesPerDay,
    maxNewUnitsPerDay: maxNewUnitsPerDay,
    avgNewMinutesPerAyah: avgNewMinutesPerAyah,
    avgReviewMinutesPerAyah: avgReviewMinutesPerAyah,
    dailyMinutesDefault: dailyMinutesDefault,
    minutesByWeekdayJson: minutesByWeekdayJson,
    typicalGradeDistributionJson: typicalGradeDistributionJson,
  );
}

Future<void> _seedLinearAyahs(
  AppDatabase db, {
  required int ayahCount,
  required bool includePageMetadata,
}) async {
  final rows = <AyahCompanion>[];
  for (var ayah = 1; ayah <= ayahCount; ayah++) {
    rows.add(
      AyahCompanion.insert(
        surah: 1,
        ayah: ayah,
        textUthmani: 'ayah-$ayah',
        pageMadina: includePageMetadata
            ? Value(((ayah - 1) ~/ 3) + 1)
            : const Value.absent(),
      ),
    );
  }

  await db.batch((batch) {
    batch.insertAll(db.ayah, rows);
  });
}

Future<void> _insertDueCustomUnits(
  AppDatabase db, {
  required int count,
  required int dueDay,
}) async {
  for (var i = 0; i < count; i++) {
    final unitId = await db.into(db.memUnit).insert(
          MemUnitCompanion.insert(
            kind: 'custom',
            unitKey: 'due-custom-$i',
            createdAtDay: 1,
            updatedAtDay: 1,
          ),
        );

    await db.into(db.scheduleState).insert(
          ScheduleStateCompanion.insert(
            unitId: Value(unitId),
            ef: 2.5,
            reps: 0,
            intervalDays: 0,
            dueDay: dueDay,
            lapseCount: 0,
          ),
        );
  }
}

Future<int> _tableCount(AppDatabase db, String table) async {
  final row =
      await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
  return row.read<int>('c');
}

Future<List<String>> _scheduleSnapshot(AppDatabase db) async {
  final rows = await (db.select(db.scheduleState)
        ..orderBy([
          (tbl) => OrderingTerm.asc(tbl.unitId),
        ]))
      .get();

  return rows
      .map(
        (row) =>
            '${row.unitId}|${row.ef}|${row.reps}|${row.intervalDays}|${row.dueDay}|${row.lastReviewDay}|${row.lastGradeQ}|${row.lapseCount}|${row.isSuspended}|${row.suspendedAtDay}',
      )
      .toList(growable: false);
}

int _findDayForWeekday(int weekday) {
  for (var day = 0; day < 14; day++) {
    final date = DateTime(1970, 1, 1).add(Duration(days: day));
    if (date.weekday == weekday) {
      return day;
    }
  }
  throw StateError('Weekday $weekday not found in 14-day search window.');
}
