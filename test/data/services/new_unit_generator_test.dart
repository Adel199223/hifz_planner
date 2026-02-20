import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/mem_unit_repo.dart';
import 'package:hifz_planner/data/repositories/progress_repo.dart';
import 'package:hifz_planner/data/repositories/quran_repo.dart';
import 'package:hifz_planner/data/repositories/schedule_repo.dart';
import 'package:hifz_planner/data/repositories/settings_repo.dart';
import 'package:hifz_planner/data/services/new_unit_generator.dart';

void main() {
  late AppDatabase db;
  late QuranRepo quranRepo;
  late MemUnitRepo memUnitRepo;
  late ScheduleRepo scheduleRepo;
  late SettingsRepo settingsRepo;
  late ProgressRepo progressRepo;
  late NewUnitGenerator generator;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    quranRepo = QuranRepo(db);
    memUnitRepo = MemUnitRepo(db);
    scheduleRepo = ScheduleRepo(db);
    settingsRepo = SettingsRepo(db);
    progressRepo = ProgressRepo(db);
    generator = NewUnitGenerator(quranRepo, memUnitRepo, scheduleRepo);

    await _seedAyahs(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('generates deterministic page_segment unit within one page', () async {
    await settingsRepo.updateSettings(
      maxNewUnitsPerDay: 5,
      maxNewPagesPerDay: 5,
      avgNewMinutesPerAyah: 1.0,
    );
    final settings = await settingsRepo.getSettings();
    final cursor = await progressRepo.getCursor();

    final result = await generator.generate(
      todayDay: 100,
      cursor: cursor,
      remainingMinutes: 3,
      settings: settings,
      initialEf: 2.5,
    );

    expect(result.createdUnits.length, 1);
    final first = result.createdUnits.first;
    expect(first.kind, 'page_segment');
    expect(first.pageMadina, 1);
    expect(first.startSurah, 1);
    expect(first.startAyah, 1);
    expect(first.endSurah, 1);
    expect(first.endAyah, 3);
    expect(first.unitKey, 'page_segment:p1:s1a1-s1a3');
    expect(result.minutesPlannedNew, 3);
    expect(result.nextSurah, 1);
    expect(result.nextAyah, 4);
    expect(result.cursorAtEnd, isFalse);
  });

  test('enforces max_new_units_per_day cap', () async {
    await settingsRepo.updateSettings(
      maxNewUnitsPerDay: 1,
      maxNewPagesPerDay: 10,
      avgNewMinutesPerAyah: 1.0,
    );
    final settings = await settingsRepo.getSettings();
    final cursor = await progressRepo.getCursor();

    final result = await generator.generate(
      todayDay: 100,
      cursor: cursor,
      remainingMinutes: 20,
      settings: settings,
      initialEf: 2.5,
    );

    expect(result.createdUnits.length, 1);
  });

  test('enforces max_new_pages_per_day cap using distinct pages', () async {
    await settingsRepo.updateSettings(
      maxNewUnitsPerDay: 10,
      maxNewPagesPerDay: 1,
      avgNewMinutesPerAyah: 1.0,
    );
    final settings = await settingsRepo.getSettings();
    final cursor = await progressRepo.getCursor();

    final result = await generator.generate(
      todayDay: 100,
      cursor: cursor,
      remainingMinutes: 20,
      settings: settings,
      initialEf: 2.5,
    );

    expect(result.createdUnits.length, 1);
    expect(result.createdUnits.first.pageMadina, 1);
    expect(result.nextSurah, 1);
    expect(result.nextAyah, 4);
  });

  test('stops when remaining minutes are insufficient for one ayah', () async {
    await settingsRepo.updateSettings(
      maxNewUnitsPerDay: 10,
      maxNewPagesPerDay: 10,
      avgNewMinutesPerAyah: 1.0,
    );
    final settings = await settingsRepo.getSettings();
    final cursor = await progressRepo.getCursor();

    final result = await generator.generate(
      todayDay: 100,
      cursor: cursor,
      remainingMinutes: 0.5,
      settings: settings,
      initialEf: 2.5,
    );

    expect(result.createdUnits, isEmpty);
    expect(result.minutesPlannedNew, 0);
    expect(result.nextSurah, cursor.nextSurah);
    expect(result.nextAyah, cursor.nextAyah);
    expect(result.cursorAtEnd, isFalse);
  });

  test('seeds schedule_state with profile EF defaults and due_day=today',
      () async {
    await settingsRepo.updateSettings(
      maxNewUnitsPerDay: 10,
      maxNewPagesPerDay: 10,
      avgNewMinutesPerAyah: 1.0,
    );
    final settings = await settingsRepo.getSettings();
    final cursor = await progressRepo.getCursor();

    final result = await generator.generate(
      todayDay: 150,
      cursor: cursor,
      remainingMinutes: 1,
      settings: settings,
      initialEf: 2.6,
    );

    expect(result.createdUnits.length, 1);
    final row = await (db.select(db.scheduleState)
          ..where((tbl) => tbl.unitId.equals(result.createdUnits.first.id)))
        .getSingle();

    expect(row.ef, 2.6);
    expect(row.reps, 0);
    expect(row.intervalDays, 0);
    expect(row.dueDay, 150);
    expect(row.lapseCount, 0);
    expect(row.lastGradeQ, isNull);
  });

  test('clamps cursor to last ayah when generation reaches end of data',
      () async {
    await progressRepo.updateCursor(nextSurah: 1, nextAyah: 7);
    await settingsRepo.updateSettings(
      maxNewUnitsPerDay: 10,
      maxNewPagesPerDay: 10,
      avgNewMinutesPerAyah: 1.0,
    );
    final settings = await settingsRepo.getSettings();
    final cursor = await progressRepo.getCursor();

    final result = await generator.generate(
      todayDay: 200,
      cursor: cursor,
      remainingMinutes: 20,
      settings: settings,
      initialEf: 2.5,
    );

    expect(result.createdUnits, isNotEmpty);
    expect(result.cursorAtEnd, isTrue);
    expect(result.nextSurah, 1);
    expect(result.nextAyah, 10);
  });
}

Future<void> _seedAyahs(AppDatabase db) async {
  final rows = <AyahCompanion>[];
  for (var ayah = 1; ayah <= 10; ayah++) {
    final page = switch (ayah) {
      <= 3 => 1,
      <= 6 => 2,
      <= 9 => 3,
      _ => 4,
    };
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
