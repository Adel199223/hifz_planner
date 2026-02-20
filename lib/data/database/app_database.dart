import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../time/local_day_time.dart';

part 'app_database.g.dart';

class Ayah extends Table {
  @override
  String get tableName => 'ayah';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get surah => integer()();

  IntColumn get ayah => integer()();

  TextColumn get textUthmani => text().named('text_uthmani')();

  IntColumn get pageMadina => integer().named('page_madina').nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {surah, ayah},
      ];
}

class Bookmark extends Table {
  @override
  String get tableName => 'bookmark';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get surah => integer()();

  IntColumn get ayah => integer()();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
}

class Note extends Table {
  @override
  String get tableName => 'note';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get surah => integer()();

  IntColumn get ayah => integer()();

  TextColumn get title => text().nullable()();

  TextColumn get body => text()();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();
}

class MemUnit extends Table {
  @override
  String get tableName => 'mem_unit';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get kind => text().check(
        kind.isIn(
          const ['ayah_range', 'page_segment', 'custom'],
        ),
      )();

  IntColumn get pageMadina => integer().named('page_madina').nullable()();

  IntColumn get startSurah => integer().named('start_surah').nullable()();

  IntColumn get startAyah => integer().named('start_ayah').nullable()();

  IntColumn get endSurah => integer().named('end_surah').nullable()();

  IntColumn get endAyah => integer().named('end_ayah').nullable()();

  IntColumn get startWord => integer().named('start_word').nullable()();

  IntColumn get endWord => integer().named('end_word').nullable()();

  TextColumn get title => text().nullable()();

  TextColumn get locatorJson => text().named('locator_json').nullable()();

  TextColumn get unitKey => text().named('unit_key')();

  IntColumn get createdAtDay => integer().named('created_at_day')();

  IntColumn get updatedAtDay => integer().named('updated_at_day')();

  @override
  List<Set<Column>> get uniqueKeys => [
        {unitKey},
      ];
}

class ScheduleState extends Table {
  @override
  String get tableName => 'schedule_state';

  IntColumn get unitId => integer()
      .named('unit_id')
      .references(MemUnit, #id, onDelete: KeyAction.cascade)();

  RealColumn get ef => real()();

  IntColumn get reps => integer()();

  IntColumn get intervalDays => integer().named('interval_days')();

  IntColumn get dueDay => integer().named('due_day')();

  IntColumn get lastReviewDay =>
      integer().named('last_review_day').nullable()();

  IntColumn get lastGradeQ => integer()
      .named('last_grade_q')
      .nullable()
      .check(lastGradeQ.isIn(const [5, 4, 3, 2, 0]))();

  IntColumn get lapseCount => integer().named('lapse_count')();

  IntColumn get isSuspended => integer()
      .named('is_suspended')
      .withDefault(const Constant(0))
      .check(isSuspended.isIn(const [0, 1]))();

  IntColumn get suspendedAtDay =>
      integer().named('suspended_at_day').nullable()();

  @override
  Set<Column> get primaryKey => {unitId};
}

class ReviewLog extends Table {
  @override
  String get tableName => 'review_log';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get unitId => integer()
      .named('unit_id')
      .references(MemUnit, #id, onDelete: KeyAction.cascade)();

  IntColumn get tsDay => integer().named('ts_day')();

  IntColumn get tsSeconds => integer().named('ts_seconds').nullable()();

  IntColumn get gradeQ =>
      integer().named('grade_q').check(gradeQ.isIn(const [5, 4, 3, 2, 0]))();

  IntColumn get durationSeconds =>
      integer().named('duration_seconds').nullable()();

  IntColumn get mistakesCount => integer().named('mistakes_count').nullable()();
}

class AppSettings extends Table {
  @override
  String get tableName => 'app_settings';

  IntColumn get id => integer().check(id.equals(1))();

  TextColumn get profile => text().check(
        profile.isIn(
          const ['support', 'standard', 'accelerated'],
        ),
      )();

  IntColumn get forceRevisionOnly => integer()
      .named('force_revision_only')
      .check(forceRevisionOnly.isIn(const [0, 1]))();

  IntColumn get dailyMinutesDefault =>
      integer().named('daily_minutes_default')();

  TextColumn get minutesByWeekdayJson =>
      text().named('minutes_by_weekday_json').nullable()();

  IntColumn get maxNewPagesPerDay => integer().named('max_new_pages_per_day')();

  IntColumn get maxNewUnitsPerDay => integer().named('max_new_units_per_day')();

  RealColumn get avgNewMinutesPerAyah =>
      real().named('avg_new_minutes_per_ayah')();

  RealColumn get avgReviewMinutesPerAyah =>
      real().named('avg_review_minutes_per_ayah')();

  IntColumn get requirePageMetadata => integer()
      .named('require_page_metadata')
      .withDefault(const Constant(1))
      .check(requirePageMetadata.isIn(const [0, 1]))();

  TextColumn get typicalGradeDistributionJson =>
      text().named('typical_grade_distribution_json').nullable()();

  IntColumn get updatedAtDay => integer().named('updated_at_day')();

  @override
  Set<Column> get primaryKey => {id};
}

class CalibrationSample extends Table {
  @override
  String get tableName => 'calibration_sample';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get sampleKind => text().named('sample_kind').check(
        sampleKind.isIn(
          const ['new_memorization', 'review'],
        ),
      )();

  IntColumn get durationSeconds => integer()
      .named('duration_seconds')
      .check(durationSeconds.isBiggerThanValue(0))();

  IntColumn get ayahCount =>
      integer().named('ayah_count').check(ayahCount.isBiggerThanValue(0))();

  IntColumn get createdAtDay => integer().named('created_at_day')();

  IntColumn get createdAtSeconds =>
      integer().named('created_at_seconds').nullable()();
}

class PendingCalibrationUpdate extends Table {
  @override
  String get tableName => 'pending_calibration_update';

  IntColumn get id => integer().check(id.equals(1))();

  RealColumn get avgNewMinutesPerAyah =>
      real().named('avg_new_minutes_per_ayah').nullable()();

  RealColumn get avgReviewMinutesPerAyah =>
      real().named('avg_review_minutes_per_ayah').nullable()();

  TextColumn get typicalGradeDistributionJson =>
      text().named('typical_grade_distribution_json').nullable()();

  IntColumn get effectiveDay => integer().named('effective_day')();

  IntColumn get createdAtDay => integer().named('created_at_day')();

  @override
  Set<Column> get primaryKey => {id};
}

class MemProgress extends Table {
  @override
  String get tableName => 'mem_progress';

  IntColumn get id => integer().check(id.equals(1))();

  IntColumn get nextSurah => integer().named('next_surah')();

  IntColumn get nextAyah => integer().named('next_ayah')();

  IntColumn get updatedAtDay => integer().named('updated_at_day')();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Ayah,
    Bookmark,
    Note,
    MemUnit,
    ScheduleState,
    ReviewLog,
    AppSettings,
    MemProgress,
    CalibrationSample,
    PendingCalibrationUpdate,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createMemorizationIndexes();
          await _createCalibrationIndexes();
          await ensureSingletonRows();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(memUnit);
            await m.createTable(scheduleState);
            await m.createTable(reviewLog);
            await m.createTable(appSettings);
            await m.createTable(memProgress);
          }
          if (from < 3) {
            if (from == 2) {
              await m.addColumn(
                appSettings,
                appSettings.typicalGradeDistributionJson,
              );
            }
            await m.createTable(calibrationSample);
            await m.createTable(pendingCalibrationUpdate);
          }
          await _createMemorizationIndexes();
          await _createCalibrationIndexes();
          await ensureSingletonRows();
        },
        beforeOpen: (OpeningDetails details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
          await ensureSingletonRows();
        },
      );

  Future<void> ensureSingletonRows({DateTime? nowLocal}) async {
    final day = localDayIndex((nowLocal ?? DateTime.now()).toLocal());

    await into(appSettings).insert(
      AppSettingsCompanion.insert(
        id: const Value(1),
        profile: 'standard',
        forceRevisionOnly: 1,
        dailyMinutesDefault: 45,
        maxNewPagesPerDay: 1,
        maxNewUnitsPerDay: 8,
        avgNewMinutesPerAyah: 2.0,
        avgReviewMinutesPerAyah: 0.8,
        updatedAtDay: day,
      ),
      mode: InsertMode.insertOrIgnore,
    );

    await into(memProgress).insert(
      MemProgressCompanion.insert(
        id: const Value(1),
        nextSurah: 1,
        nextAyah: 1,
        updatedAtDay: day,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> _createMemorizationIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_schedule_state_due_day '
      'ON schedule_state(due_day)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_schedule_state_is_suspended '
      'ON schedule_state(is_suspended)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_review_log_unit_id_ts_day '
      'ON review_log(unit_id, ts_day)',
    );
  }

  Future<void> _createCalibrationIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_calibration_sample_kind_day_id '
      'ON calibration_sample(sample_kind, created_at_day, id)',
    );
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'hifz_planner.sqlite');
}
