import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/time/local_day_time.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('creates all core and memorization tables', () async {
    final result = await db.customSelect('''
      SELECT name FROM sqlite_master
      WHERE type = 'table'
    ''').get();

    final tableNames = result.map((row) => row.read<String>('name')).toSet();

    expect(tableNames.contains('ayah'), isTrue);
    expect(tableNames.contains('bookmark'), isTrue);
    expect(tableNames.contains('note'), isTrue);
    expect(tableNames.contains('mem_unit'), isTrue);
    expect(tableNames.contains('schedule_state'), isTrue);
    expect(tableNames.contains('review_log'), isTrue);
    expect(tableNames.contains('app_settings'), isTrue);
    expect(tableNames.contains('mem_progress'), isTrue);
    expect(tableNames.contains('calibration_sample'), isTrue);
    expect(tableNames.contains('pending_calibration_update'), isTrue);
    expect(tableNames.contains('companion_chain_session'), isTrue);
    expect(tableNames.contains('companion_verse_attempt'), isTrue);
    expect(tableNames.contains('companion_unit_state'), isTrue);
    expect(tableNames.contains('companion_stage_event'), isTrue);
    expect(tableNames.contains('companion_step_proficiency'), isTrue);
    expect(tableNames.contains('companion_lifecycle_state'), isTrue);
    expect(tableNames.contains('companion_stage4_session'), isTrue);
  });

  test('enforces unique(surah, ayah) on ayah table', () async {
    await db.into(db.ayah).insert(
          AyahCompanion.insert(
            surah: 1,
            ayah: 1,
            textUthmani: 'In the name of Allah',
          ),
        );

    await expectLater(
      db.into(db.ayah).insert(
            AyahCompanion.insert(
              surah: 1,
              ayah: 1,
              textUthmani: 'Duplicate ayah should fail',
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('enforces unique(unit_key) on mem_unit table', () async {
    await db.into(db.memUnit).insert(
          MemUnitCompanion.insert(
            kind: 'ayah_range',
            unitKey: 'surah:1-ayah:1',
            createdAtDay: 20000,
            updatedAtDay: 20000,
          ),
        );

    await expectLater(
      db.into(db.memUnit).insert(
            MemUnitCompanion.insert(
              kind: 'ayah_range',
              unitKey: 'surah:1-ayah:1',
              createdAtDay: 20001,
              updatedAtDay: 20001,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('initializes singleton app_settings and mem_progress rows', () async {
    final settings = await (db.select(db.appSettings)
          ..where((tbl) => tbl.id.equals(1)))
        .getSingle();
    final progress = await (db.select(db.memProgress)
          ..where((tbl) => tbl.id.equals(1)))
        .getSingle();

    expect(settings.id, 1);
    expect(settings.profile, 'standard');
    expect(settings.forceRevisionOnly, 1);
    expect(settings.dailyMinutesDefault, 45);
    expect(settings.maxNewPagesPerDay, 1);
    expect(settings.maxNewUnitsPerDay, 8);
    expect(settings.avgNewMinutesPerAyah, 2.0);
    expect(settings.avgReviewMinutesPerAyah, 0.8);
    expect(settings.requirePageMetadata, 1);
    expect(settings.typicalGradeDistributionJson, isNull);
    expect(settings.updatedAtDay, localDayIndex(DateTime.now().toLocal()));

    expect(progress.id, 1);
    expect(progress.nextSurah, 1);
    expect(progress.nextAyah, 1);
    expect(progress.updatedAtDay, localDayIndex(DateTime.now().toLocal()));
  });

  test('creates required memorization indexes', () async {
    final result = await db.customSelect('''
      SELECT name FROM sqlite_master
      WHERE type = 'index'
    ''').get();
    final indexNames = result.map((row) => row.read<String>('name')).toSet();

    expect(indexNames.contains('idx_schedule_state_due_day'), isTrue);
    expect(indexNames.contains('idx_schedule_state_is_suspended'), isTrue);
    expect(indexNames.contains('idx_review_log_unit_id_ts_day'), isTrue);
    expect(indexNames.contains('idx_calibration_sample_kind_day_id'), isTrue);
    expect(
      indexNames.contains(
        'idx_companion_chain_session_unit_id_created_day',
      ),
      isTrue,
    );
    expect(
      indexNames.contains(
        'idx_companion_verse_attempt_session_verse_attempt',
      ),
      isTrue,
    );
    expect(
      indexNames.contains(
        'idx_companion_verse_attempt_session_stage_verse_attempt',
      ),
      isTrue,
    );
    expect(
      indexNames.contains('idx_companion_verse_attempt_unit_day'),
      isTrue,
    );
    expect(indexNames.contains('idx_companion_step_proficiency_unit'), isTrue);
    expect(indexNames.contains('idx_companion_unit_state_unit_id'), isTrue);
    expect(
        indexNames.contains('idx_companion_stage_event_session_created'), isTrue);
    expect(indexNames.contains('idx_companion_lifecycle_state_stage4_next_due'),
        isTrue);
    expect(indexNames.contains('idx_companion_lifecycle_state_stage4_retry_due'),
        isTrue);
    expect(
        indexNames.contains('idx_companion_stage4_session_unit_started_day'),
        isTrue);
    expect(
        indexNames.contains('idx_companion_stage4_session_chain_session'),
        isTrue);
  });

  test('app_settings includes typical_grade_distribution_json column',
      () async {
    final rows = await db
        .customSelect(
          "PRAGMA table_info('app_settings')",
        )
        .get();
    final names = rows.map((row) => row.read<String>('name')).toSet();

    expect(names.contains('typical_grade_distribution_json'), isTrue);
    expect(names.contains('scheduling_prefs_json'), isTrue);
    expect(names.contains('scheduling_overrides_json'), isTrue);
  });

  test('companion_verse_attempt includes stage_code column', () async {
    final rows = await db
        .customSelect(
          "PRAGMA table_info('companion_verse_attempt')",
        )
        .get();
    final names = rows.map((row) => row.read<String>('name')).toSet();

    expect(names.contains('stage_code'), isTrue);
  });

  test('companion_verse_attempt includes Stage-1 telemetry columns', () async {
    final rows = await db
        .customSelect(
          "PRAGMA table_info('companion_verse_attempt')",
        )
        .get();
    final names = rows.map((row) => row.read<String>('name')).toSet();

    expect(names.contains('attempt_type'), isTrue);
    expect(names.contains('assisted_flag'), isTrue);
    expect(names.contains('auto_check_type'), isTrue);
    expect(names.contains('auto_check_result'), isTrue);
    expect(names.contains('time_on_verse_ms'), isTrue);
    expect(names.contains('time_on_chunk_ms'), isTrue);
    expect(names.contains('telemetry_json'), isTrue);
  });

  test('stage-4 lifecycle tables include expected columns', () async {
    final lifecycleRows = await db
        .customSelect("PRAGMA table_info('companion_lifecycle_state')")
        .get();
    final lifecycleNames =
        lifecycleRows.map((row) => row.read<String>('name')).toSet();
    expect(lifecycleNames.contains('stage4_status'), isTrue);
    expect(lifecycleNames.contains('stage4_next_day_due_day'), isTrue);
    expect(lifecycleNames.contains('stage4_retry_due_day'), isTrue);
    expect(lifecycleNames.contains('stage4_unresolved_targets_json'), isTrue);
    expect(lifecycleNames.contains('new_override_count'), isTrue);

    final sessionRows = await db
        .customSelect("PRAGMA table_info('companion_stage4_session')")
        .get();
    final sessionNames =
        sessionRows.map((row) => row.read<String>('name')).toSet();
    expect(sessionNames.contains('due_kind'), isTrue);
    expect(sessionNames.contains('outcome'), isTrue);
    expect(sessionNames.contains('counted_pass_rate'), isTrue);
    expect(sessionNames.contains('unresolved_targets_json'), isTrue);
    expect(sessionNames.contains('telemetry_json'), isTrue);
  });

  test('deleting mem_unit cascades schedule_state and review_log rows',
      () async {
    final unitId = await db.into(db.memUnit).insert(
          MemUnitCompanion.insert(
            kind: 'ayah_range',
            unitKey: 'unit:to-delete',
            createdAtDay: 22000,
            updatedAtDay: 22000,
          ),
        );

    await db.into(db.scheduleState).insert(
          ScheduleStateCompanion.insert(
            unitId: Value(unitId),
            ef: 2.5,
            reps: 0,
            intervalDays: 0,
            dueDay: 22000,
            lapseCount: 0,
          ),
        );
    await db.into(db.reviewLog).insert(
          ReviewLogCompanion.insert(
            unitId: unitId,
            tsDay: 22000,
            gradeQ: 5,
          ),
        );

    await (db.delete(db.memUnit)..where((tbl) => tbl.id.equals(unitId))).go();

    final scheduleRows = await (db.select(db.scheduleState)
          ..where((tbl) => tbl.unitId.equals(unitId)))
        .get();
    final reviewRows = await (db.select(db.reviewLog)
          ..where((tbl) => tbl.unitId.equals(unitId)))
        .get();

    expect(scheduleRows, isEmpty);
    expect(reviewRows, isEmpty);
  });
}
