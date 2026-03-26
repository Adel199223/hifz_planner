import 'package:drift/drift.dart';

import 'app_database_connection_factory.dart';
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
        const CustomExpression<bool>(
          "kind IN ('ayah_range', 'page_segment', 'custom')",
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
      .check(const CustomExpression<bool>('last_grade_q IN (5, 4, 3, 2, 0)'))();

  IntColumn get lapseCount => integer().named('lapse_count')();

  IntColumn get isSuspended => integer()
      .named('is_suspended')
      .withDefault(const Constant(0))
      .check(const CustomExpression<bool>('is_suspended IN (0, 1)'))();

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

  IntColumn get gradeQ => integer()
      .named('grade_q')
      .check(const CustomExpression<bool>('grade_q IN (5, 4, 3, 2, 0)'))();

  IntColumn get durationSeconds =>
      integer().named('duration_seconds').nullable()();

  IntColumn get mistakesCount => integer().named('mistakes_count').nullable()();
}

class AppSettings extends Table {
  @override
  String get tableName => 'app_settings';

  IntColumn get id => integer().check(const CustomExpression<bool>('id = 1'))();

  TextColumn get profile => text().check(
        const CustomExpression<bool>(
          "profile IN ('support', 'standard', 'accelerated')",
        ),
      )();

  IntColumn get forceRevisionOnly => integer()
      .named('force_revision_only')
      .check(const CustomExpression<bool>('force_revision_only IN (0, 1)'))();

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
      .check(const CustomExpression<bool>('require_page_metadata IN (0, 1)'))();

  TextColumn get typicalGradeDistributionJson =>
      text().named('typical_grade_distribution_json').nullable()();

  TextColumn get schedulingPrefsJson =>
      text().named('scheduling_prefs_json').nullable()();

  TextColumn get schedulingOverridesJson =>
      text().named('scheduling_overrides_json').nullable()();

  IntColumn get updatedAtDay => integer().named('updated_at_day')();

  @override
  Set<Column> get primaryKey => {id};
}

class CalibrationSample extends Table {
  @override
  String get tableName => 'calibration_sample';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get sampleKind => text().named('sample_kind').check(
        const CustomExpression<bool>(
          "sample_kind IN ('new_memorization', 'review')",
        ),
      )();

  IntColumn get durationSeconds => integer()
      .named('duration_seconds')
      .check(const CustomExpression<bool>('duration_seconds > 0'))();

  IntColumn get ayahCount => integer()
      .named('ayah_count')
      .check(const CustomExpression<bool>('ayah_count > 0'))();

  IntColumn get createdAtDay => integer().named('created_at_day')();

  IntColumn get createdAtSeconds =>
      integer().named('created_at_seconds').nullable()();
}

class PendingCalibrationUpdate extends Table {
  @override
  String get tableName => 'pending_calibration_update';

  IntColumn get id => integer().check(const CustomExpression<bool>('id = 1'))();

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

class CompanionChainSession extends Table {
  @override
  String get tableName => 'companion_chain_session';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get unitId => integer()
      .named('unit_id')
      .references(MemUnit, #id, onDelete: KeyAction.cascade)();

  IntColumn get targetVerseCount => integer()
      .named('target_verse_count')
      .check(const CustomExpression<bool>('target_verse_count > 0'))();

  IntColumn get passedVerseCount =>
      integer().named('passed_verse_count').withDefault(const Constant(0))();

  TextColumn get chainResult => text().named('chain_result').check(
        const CustomExpression<bool>(
            "chain_result IN ('completed', 'partial', 'abandoned')"),
      )();

  RealColumn get retrievalStrength =>
      real().named('retrieval_strength').withDefault(const Constant(0.0))();

  IntColumn get startedAtSeconds =>
      integer().named('started_at_seconds').nullable()();

  IntColumn get endedAtSeconds =>
      integer().named('ended_at_seconds').nullable()();

  IntColumn get createdAtDay => integer().named('created_at_day')();

  IntColumn get updatedAtDay => integer().named('updated_at_day')();
}

class CompanionVerseAttempt extends Table {
  @override
  String get tableName => 'companion_verse_attempt';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get sessionId => integer()
      .named('session_id')
      .references(CompanionChainSession, #id, onDelete: KeyAction.cascade)();

  IntColumn get unitId => integer()
      .named('unit_id')
      .references(MemUnit, #id, onDelete: KeyAction.cascade)();

  IntColumn get verseOrder => integer().named('verse_order')();

  IntColumn get surah => integer()();

  IntColumn get ayah => integer()();

  IntColumn get attemptIndex => integer()
      .named('attempt_index')
      .check(const CustomExpression<bool>('attempt_index > 0'))();

  TextColumn get stageCode => text()
      .named('stage_code')
      .withDefault(
        const Constant('hidden_reveal'),
      )
      .check(
        const CustomExpression<bool>(
          "stage_code IN ('guided_visible', 'cued_recall', 'hidden_reveal')",
        ),
      )();

  TextColumn get attemptType => text()
      .named('attempt_type')
      .withDefault(
        const Constant('probe'),
      )
      .check(
        const CustomExpression<bool>(
          "attempt_type IN ('encode_echo', 'probe', 'spaced_reprobe', 'checkpoint')",
        ),
      )();

  TextColumn get hintLevel => text().named('hint_level').check(
        const CustomExpression<bool>(
          "hint_level IN ('h0', 'letters', 'first_word', 'meaning_cue', 'chunk_text', 'full_text')",
        ),
      )();

  IntColumn get assistedFlag => integer()
      .named('assisted_flag')
      .withDefault(const Constant(0))
      .check(const CustomExpression<bool>('assisted_flag IN (0, 1)'))();

  IntColumn get latencyToStartMs =>
      integer().named('latency_to_start_ms').withDefault(const Constant(0))();

  IntColumn get stopsCount =>
      integer().named('stops_count').withDefault(const Constant(0))();

  IntColumn get selfCorrectionsCount => integer()
      .named('self_corrections_count')
      .withDefault(const Constant(0))();

  TextColumn get evaluatorMode => text().named('evaluator_mode').check(
        const CustomExpression<bool>(
            "evaluator_mode IN ('manual_fallback', 'asr')"),
      )();

  IntColumn get evaluatorPassed => integer()
      .named('evaluator_passed')
      .check(const CustomExpression<bool>('evaluator_passed IN (0, 1)'))();

  RealColumn get evaluatorConfidence =>
      real().named('evaluator_confidence').nullable()();

  TextColumn get autoCheckType =>
      text().named('auto_check_type').nullable().check(
            const CustomExpression<bool>(
              "auto_check_type IN ('next_word_mcq', 'one_word_cloze', 'ordering')",
            ),
          )();

  TextColumn get autoCheckResult =>
      text().named('auto_check_result').nullable().check(
            const CustomExpression<bool>(
              "auto_check_result IN ('pass', 'fail')",
            ),
          )();

  IntColumn get revealedAfterAttempt =>
      integer().named('revealed_after_attempt').check(
          const CustomExpression<bool>('revealed_after_attempt IN (0, 1)'))();

  RealColumn get retrievalStrength => real().named('retrieval_strength')();

  IntColumn get timeOnVerseMs =>
      integer().named('time_on_verse_ms').withDefault(const Constant(0))();

  IntColumn get timeOnChunkMs =>
      integer().named('time_on_chunk_ms').withDefault(const Constant(0))();

  TextColumn get telemetryJson => text().named('telemetry_json').nullable()();

  IntColumn get attemptDay => integer().named('attempt_day')();

  IntColumn get attemptSeconds =>
      integer().named('attempt_seconds').nullable()();
}

class CompanionUnitState extends Table {
  @override
  String get tableName => 'companion_unit_state';

  IntColumn get unitId => integer()
      .named('unit_id')
      .references(MemUnit, #id, onDelete: KeyAction.cascade)();

  IntColumn get unlockedStage => integer().named('unlocked_stage').check(
        const CustomExpression<bool>(
            'unlocked_stage >= 1 AND unlocked_stage <= 3'),
      )();

  IntColumn get updatedAtDay => integer().named('updated_at_day')();

  IntColumn get updatedAtSeconds => integer().named('updated_at_seconds')();

  @override
  Set<Column> get primaryKey => {unitId};
}

class CompanionStageEvent extends Table {
  @override
  String get tableName => 'companion_stage_event';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get sessionId => integer()
      .named('session_id')
      .references(CompanionChainSession, #id, onDelete: KeyAction.cascade)();

  IntColumn get unitId => integer()
      .named('unit_id')
      .references(MemUnit, #id, onDelete: KeyAction.cascade)();

  IntColumn get fromStage => integer().named('from_stage').check(
        const CustomExpression<bool>('from_stage >= 1 AND from_stage <= 3'),
      )();

  IntColumn get toStage => integer()
      .named('to_stage')
      .check(const CustomExpression<bool>('to_stage >= 1 AND to_stage <= 3'))();

  TextColumn get eventType => text().named('event_type').check(
        const CustomExpression<bool>(
            "event_type IN ('auto_unlock', 'user_skip', 'resume_stage')"),
      )();

  IntColumn get triggerVerseOrder =>
      integer().named('trigger_verse_order').nullable()();

  IntColumn get createdDay => integer().named('created_day')();

  IntColumn get createdSeconds => integer().named('created_seconds')();
}

class CompanionStepProficiency extends Table {
  @override
  String get tableName => 'companion_step_proficiency';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get unitId => integer()
      .named('unit_id')
      .references(MemUnit, #id, onDelete: KeyAction.cascade)();

  IntColumn get surah => integer()();

  IntColumn get ayah => integer()();

  RealColumn get proficiencyEma =>
      real().named('proficiency_ema').withDefault(const Constant(0.0))();

  TextColumn get lastHintLevel =>
      text().named('last_hint_level').nullable().check(
            const CustomExpression<bool>(
              "last_hint_level IN ('h0', 'letters', 'first_word', 'meaning_cue', 'chunk_text', 'full_text')",
            ),
          )();

  RealColumn get lastEvaluatorConfidence =>
      real().named('last_evaluator_confidence').nullable()();

  IntColumn get lastLatencyToStartMs =>
      integer().named('last_latency_to_start_ms').nullable()();

  IntColumn get attemptsCount =>
      integer().named('attempts_count').withDefault(const Constant(0))();

  IntColumn get passesCount =>
      integer().named('passes_count').withDefault(const Constant(0))();

  IntColumn get lastUpdatedDay => integer().named('last_updated_day')();

  IntColumn get lastSessionId => integer()
      .named('last_session_id')
      .nullable()
      .references(CompanionChainSession, #id)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {unitId, surah, ayah},
      ];
}

class CompanionLifecycleState extends Table {
  @override
  String get tableName => 'companion_lifecycle_state';

  IntColumn get unitId => integer()
      .named('unit_id')
      .references(MemUnit, #id, onDelete: KeyAction.cascade)();

  TextColumn get lifecycleTier => text()
      .named('lifecycle_tier')
      .withDefault(const Constant('emerging'))
      .check(
        const CustomExpression<bool>(
          "lifecycle_tier IN ('emerging', 'ready', 'stable', 'maintained')",
        ),
      )();

  TextColumn get stage4Status => text()
      .named('stage4_status')
      .withDefault(const Constant('none'))
      .check(
        const CustomExpression<bool>(
          "stage4_status IN ('none', 'pending', 'due', 'in_progress', 'passed', 'partial', 'failed', 'needs_reinforcement')",
        ),
      )();

  IntColumn get stage4PreSleepDueDay =>
      integer().named('stage4_pre_sleep_due_day').nullable()();

  IntColumn get stage4NextDayDueDay =>
      integer().named('stage4_next_day_due_day').nullable()();

  IntColumn get stage4RetryDueDay =>
      integer().named('stage4_retry_due_day').nullable()();

  TextColumn get stage4UnresolvedTargetsJson =>
      text().named('stage4_unresolved_targets_json').nullable()();

  TextColumn get stage4RiskJson => text().named('stage4_risk_json').nullable()();

  TextColumn get stage4StrengtheningRoute =>
      text().named('stage4_strengthening_route').nullable().check(
            const CustomExpression<bool>(
              "stage4_strengthening_route IS NULL OR stage4_strengthening_route IN ('targeted_stage3', 'broad_stage3')",
            ),
          )();

  TextColumn get stage4LastOutcome => text().named('stage4_last_outcome').nullable().check(
            const CustomExpression<bool>(
              "stage4_last_outcome IS NULL OR stage4_last_outcome IN ('pass', 'partial', 'fail', 'abandoned')",
            ),
          )();

  IntColumn get stage4LastSessionId =>
      integer().named('stage4_last_session_id').nullable()();

  IntColumn get stage4LastCompletedDay =>
      integer().named('stage4_last_completed_day').nullable()();

  IntColumn get stage4MissedCount =>
      integer().named('stage4_missed_count').withDefault(const Constant(0))();

  IntColumn get lastNewOverrideDay =>
      integer().named('last_new_override_day').nullable()();

  IntColumn get newOverrideCount =>
      integer().named('new_override_count').withDefault(const Constant(0))();

  IntColumn get updatedAtDay => integer().named('updated_at_day')();

  IntColumn get updatedAtSeconds => integer().named('updated_at_seconds')();

  @override
  Set<Column> get primaryKey => {unitId};
}

class CompanionStage4Session extends Table {
  @override
  String get tableName => 'companion_stage4_session';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get unitId => integer()
      .named('unit_id')
      .references(MemUnit, #id, onDelete: KeyAction.cascade)();

  IntColumn get chainSessionId =>
      integer().named('chain_session_id').nullable().references(
            CompanionChainSession,
            #id,
            onDelete: KeyAction.setNull,
          )();

  TextColumn get dueKind => text().named('due_kind').check(
        const CustomExpression<bool>(
          "due_kind IN ('pre_sleep_optional', 'next_day_required', 'retry_required')",
        ),
      )();

  TextColumn get outcome => text().named('outcome').nullable().check(
        const CustomExpression<bool>(
          "outcome IS NULL OR outcome IN ('pass', 'partial', 'fail', 'abandoned')",
        ),
      )();

  IntColumn get startedDay => integer().named('started_day')();

  IntColumn get startedSeconds => integer().named('started_seconds').nullable()();

  IntColumn get endedDay => integer().named('ended_day').nullable()();

  IntColumn get endedSeconds => integer().named('ended_seconds').nullable()();

  RealColumn get countedPassRate =>
      real().named('counted_pass_rate').withDefault(const Constant(0.0))();

  IntColumn get randomStartPasses =>
      integer().named('random_start_passes').withDefault(const Constant(0))();

  IntColumn get linkingPasses =>
      integer().named('linking_passes').withDefault(const Constant(0))();

  IntColumn get discriminationPasses =>
      integer().named('discrimination_passes').withDefault(const Constant(0))();

  TextColumn get unresolvedTargetsJson =>
      text().named('unresolved_targets_json').nullable()();

  TextColumn get telemetryJson => text().named('telemetry_json').nullable()();
}

class MemProgress extends Table {
  @override
  String get tableName => 'mem_progress';

  IntColumn get id => integer().check(const CustomExpression<bool>('id = 1'))();

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
    CompanionChainSession,
    CompanionVerseAttempt,
    CompanionUnitState,
    CompanionStageEvent,
    CompanionStepProficiency,
    CompanionLifecycleState,
    CompanionStage4Session,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? openAppDatabaseConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createMemorizationIndexes();
          await _createCalibrationIndexes();
          await _createCompanionIndexes();
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
          if (from < 4) {
            if (from >= 2) {
              await m.addColumn(
                appSettings,
                appSettings.schedulingPrefsJson,
              );
              await m.addColumn(
                appSettings,
                appSettings.schedulingOverridesJson,
              );
            }
            await m.createTable(companionChainSession);
            await m.createTable(companionVerseAttempt);
            await m.createTable(companionStepProficiency);
          }
          if (from < 5) {
            if (from >= 4) {
              await m.addColumn(
                companionVerseAttempt,
                companionVerseAttempt.stageCode,
              );
            }
            await m.createTable(companionUnitState);
            await m.createTable(companionStageEvent);
          }
          if (from < 6) {
            if (from >= 4) {
              await m.addColumn(
                companionVerseAttempt,
                companionVerseAttempt.attemptType as GeneratedColumn<Object>,
              );
              await m.addColumn(
                companionVerseAttempt,
                companionVerseAttempt.assistedFlag as GeneratedColumn<Object>,
              );
              await m.addColumn(
                companionVerseAttempt,
                companionVerseAttempt.autoCheckType as GeneratedColumn<Object>,
              );
              await m.addColumn(
                companionVerseAttempt,
                companionVerseAttempt.autoCheckResult
                    as GeneratedColumn<Object>,
              );
              await m.addColumn(
                companionVerseAttempt,
                companionVerseAttempt.timeOnVerseMs as GeneratedColumn<Object>,
              );
              await m.addColumn(
                companionVerseAttempt,
                companionVerseAttempt.timeOnChunkMs as GeneratedColumn<Object>,
              );
              await m.addColumn(
                companionVerseAttempt,
                companionVerseAttempt.telemetryJson as GeneratedColumn<Object>,
              );
            }
          }
          if (from < 7) {
            await m.createTable(companionLifecycleState);
            await m.createTable(companionStage4Session);
          }
          await _createMemorizationIndexes();
          await _createCalibrationIndexes();
          await _createCompanionIndexes();
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

  Future<void> _createCompanionIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_companion_chain_session_unit_id_created_day '
      'ON companion_chain_session(unit_id, created_at_day)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_companion_verse_attempt_session_verse_attempt '
      'ON companion_verse_attempt(session_id, verse_order, attempt_index)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_companion_verse_attempt_session_stage_verse_attempt '
      'ON companion_verse_attempt(session_id, stage_code, verse_order, attempt_index)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_companion_verse_attempt_session_attempt_type '
      'ON companion_verse_attempt(session_id, attempt_type, verse_order, attempt_index)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_companion_verse_attempt_unit_day '
      'ON companion_verse_attempt(unit_id, attempt_day)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_companion_step_proficiency_unit '
      'ON companion_step_proficiency(unit_id, surah, ayah)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_companion_unit_state_unit_id '
      'ON companion_unit_state(unit_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_companion_stage_event_session_created '
      'ON companion_stage_event(session_id, created_day, id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_companion_lifecycle_state_stage4_next_due '
      'ON companion_lifecycle_state(stage4_status, stage4_next_day_due_day, unit_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_companion_lifecycle_state_stage4_retry_due '
      'ON companion_lifecycle_state(stage4_status, stage4_retry_due_day, unit_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_companion_stage4_session_unit_started_day '
      'ON companion_stage4_session(unit_id, started_day, id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_companion_stage4_session_chain_session '
      'ON companion_stage4_session(chain_session_id)',
    );
  }
}


