import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/calibration_repo.dart';
import 'package:hifz_planner/data/services/companion/companion_calibration_bridge.dart';
import 'package:hifz_planner/data/services/companion/companion_models.dart';

void main() {
  late AppDatabase db;
  late CompanionCalibrationBridge bridge;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    bridge = CompanionCalibrationBridge(CalibrationRepo(db));
  });

  tearDown(() async {
    await db.close();
  });

  test('writes derived review calibration sample on chain completion',
      () async {
    await bridge.onChainCompleted(
      summary: const ChainResultSummary(
        sessionId: 1,
        resultKind: ChainResultKind.completed,
        totalVerses: 4,
        passedVerses: 4,
        averageHintLevel: 1.5,
        averageRetrievalStrength: 0.75,
      ),
      ayahCount: 4,
      attempts: const <CompanionVerseAttemptData>[],
      nowLocal: DateTime(2026, 2, 24, 8, 30),
    );

    final rows = await (db.select(db.calibrationSample)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
        .get();

    expect(rows.length, 1);
    expect(rows.single.sampleKind, 'review');
    expect(rows.single.ayahCount, 4);
    expect(rows.single.durationSeconds, 228);
  });

  test('writes new_memorization sample from Stage-1 chunk duration', () async {
    final unitId = await db.into(db.memUnit).insert(
          MemUnitCompanion.insert(
            kind: 'ayah_range',
            unitKey: 'bridge-stage1-time',
            startSurah: const Value(1),
            startAyah: const Value(1),
            endSurah: const Value(1),
            endAyah: const Value(2),
            createdAtDay: 100,
            updatedAtDay: 100,
          ),
        );
    final sessionId = await db.into(db.companionChainSession).insert(
          CompanionChainSessionCompanion.insert(
            unitId: unitId,
            targetVerseCount: 2,
            passedVerseCount: const Value(2),
            chainResult: 'completed',
            retrievalStrength: const Value(0.6),
            createdAtDay: 100,
            updatedAtDay: 100,
            startedAtSeconds: const Value(20),
            endedAtSeconds: const Value(200),
          ),
        );

    await db.into(db.companionVerseAttempt).insert(
          CompanionVerseAttemptCompanion.insert(
            sessionId: sessionId,
            unitId: unitId,
            verseOrder: 0,
            surah: 1,
            ayah: 1,
            attemptIndex: 1,
            stageCode: Value(CompanionStage.guidedVisible.code),
            attemptType: const Value('encode_echo'),
            hintLevel: HintLevel.h0.code,
            evaluatorMode: EvaluatorMode.manualFallback.code,
            evaluatorPassed: 1,
            revealedAfterAttempt: 0,
            retrievalStrength: 0.0,
            timeOnChunkMs: const Value(45000),
            attemptDay: 100,
            attemptSeconds: const Value(40),
          ),
        );
    await db.into(db.companionVerseAttempt).insert(
          CompanionVerseAttemptCompanion.insert(
            sessionId: sessionId,
            unitId: unitId,
            verseOrder: 1,
            surah: 1,
            ayah: 2,
            attemptIndex: 2,
            stageCode: Value(CompanionStage.hiddenReveal.code),
            attemptType: const Value('probe'),
            hintLevel: HintLevel.h0.code,
            evaluatorMode: EvaluatorMode.manualFallback.code,
            evaluatorPassed: 1,
            revealedAfterAttempt: 1,
            retrievalStrength: 0.3,
            attemptDay: 100,
            attemptSeconds: const Value(60),
          ),
        );

    final attempts = await (db.select(db.companionVerseAttempt)
          ..where((tbl) => tbl.sessionId.equals(sessionId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
        .get();

    await bridge.onChainCompleted(
      summary: const ChainResultSummary(
        sessionId: 1,
        resultKind: ChainResultKind.completed,
        totalVerses: 2,
        passedVerses: 2,
        averageHintLevel: 1.0,
        averageRetrievalStrength: 0.9,
      ),
      ayahCount: 2,
      attempts: attempts,
      nowLocal: DateTime(2026, 2, 24, 8, 30),
    );

    final rows = await (db.select(db.calibrationSample)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
        .get();

    expect(rows.length, 2);
    expect(rows.first.sampleKind, 'new_memorization');
    expect(rows.first.durationSeconds, 45);

    expect(rows.last.sampleKind, 'review');
    expect(rows.last.durationSeconds, 146);
  });

  test('prefers hidden stage passed attempts for derived pace', () async {
    final unitId = await db.into(db.memUnit).insert(
          MemUnitCompanion.insert(
            kind: 'ayah_range',
            unitKey: 'bridge-u1',
            startSurah: const Value(1),
            startAyah: const Value(1),
            endSurah: const Value(1),
            endAyah: const Value(1),
            createdAtDay: 100,
            updatedAtDay: 100,
          ),
        );
    final sessionId = await db.into(db.companionChainSession).insert(
          CompanionChainSessionCompanion.insert(
            unitId: unitId,
            targetVerseCount: 2,
            passedVerseCount: const Value(2),
            chainResult: 'completed',
            retrievalStrength: const Value(0.5),
            createdAtDay: 100,
            updatedAtDay: 100,
            startedAtSeconds: const Value(20),
            endedAtSeconds: const Value(80),
          ),
        );

    await db.into(db.companionVerseAttempt).insert(
          CompanionVerseAttemptCompanion.insert(
            sessionId: sessionId,
            unitId: unitId,
            verseOrder: 0,
            surah: 1,
            ayah: 1,
            attemptIndex: 1,
            stageCode: Value(CompanionStage.cuedRecall.code),
            hintLevel: HintLevel.firstWord.code,
            evaluatorMode: EvaluatorMode.manualFallback.code,
            evaluatorPassed: 1,
            revealedAfterAttempt: 0,
            retrievalStrength: 0.2,
            attemptDay: 100,
            attemptSeconds: const Value(40),
          ),
        );
    await db.into(db.companionVerseAttempt).insert(
          CompanionVerseAttemptCompanion.insert(
            sessionId: sessionId,
            unitId: unitId,
            verseOrder: 1,
            surah: 1,
            ayah: 2,
            attemptIndex: 1,
            stageCode: Value(CompanionStage.hiddenReveal.code),
            hintLevel: HintLevel.h0.code,
            evaluatorMode: EvaluatorMode.manualFallback.code,
            evaluatorPassed: 1,
            revealedAfterAttempt: 1,
            retrievalStrength: 0.9,
            attemptDay: 100,
            attemptSeconds: const Value(50),
          ),
        );

    final attempts = await (db.select(db.companionVerseAttempt)
          ..where((tbl) => tbl.sessionId.equals(sessionId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
        .get();

    await bridge.onChainCompleted(
      summary: const ChainResultSummary(
        sessionId: 1,
        resultKind: ChainResultKind.completed,
        totalVerses: 2,
        passedVerses: 2,
        averageHintLevel: 1.0,
        averageRetrievalStrength: 0.2,
      ),
      ayahCount: 2,
      attempts: attempts,
      nowLocal: DateTime(2026, 2, 24, 8, 30),
    );

    final rows = await (db.select(db.calibrationSample)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
        .get();

    expect(rows.length, 1);
    expect(rows.single.durationSeconds, 103);
  });

  test('treats lifecycle stage4 attempts as review quality and skips stage1 new-time sample',
      () async {
    final unitId = await db.into(db.memUnit).insert(
          MemUnitCompanion.insert(
            kind: 'ayah_range',
            unitKey: 'bridge-stage4-quality',
            startSurah: const Value(1),
            startAyah: const Value(1),
            endSurah: const Value(1),
            endAyah: const Value(2),
            createdAtDay: 100,
            updatedAtDay: 100,
          ),
        );
    final sessionId = await db.into(db.companionChainSession).insert(
          CompanionChainSessionCompanion.insert(
            unitId: unitId,
            targetVerseCount: 2,
            passedVerseCount: const Value(2),
            chainResult: 'completed',
            retrievalStrength: const Value(0.4),
            createdAtDay: 100,
            updatedAtDay: 100,
            startedAtSeconds: const Value(20),
            endedAtSeconds: const Value(160),
          ),
        );

    await db.into(db.companionVerseAttempt).insert(
          CompanionVerseAttemptCompanion.insert(
            sessionId: sessionId,
            unitId: unitId,
            verseOrder: 0,
            surah: 1,
            ayah: 1,
            attemptIndex: 1,
            stageCode: Value(CompanionStage.guidedVisible.code),
            attemptType: const Value('encode_echo'),
            hintLevel: HintLevel.h0.code,
            evaluatorMode: EvaluatorMode.manualFallback.code,
            evaluatorPassed: 1,
            revealedAfterAttempt: 0,
            retrievalStrength: 0.0,
            timeOnChunkMs: const Value(60000),
            attemptDay: 100,
            attemptSeconds: const Value(40),
          ),
        );
    await db.into(db.companionVerseAttempt).insert(
          CompanionVerseAttemptCompanion.insert(
            sessionId: sessionId,
            unitId: unitId,
            verseOrder: 1,
            surah: 1,
            ayah: 2,
            attemptIndex: 2,
            stageCode: Value(CompanionStage.hiddenReveal.code),
            attemptType: const Value('checkpoint'),
            hintLevel: HintLevel.h0.code,
            evaluatorMode: EvaluatorMode.manualFallback.code,
            evaluatorPassed: 1,
            revealedAfterAttempt: 1,
            retrievalStrength: 0.5,
            telemetryJson: const Value('{"lifecycle_stage":"stage4"}'),
            attemptDay: 100,
            attemptSeconds: const Value(90),
          ),
        );

    final attempts = await (db.select(db.companionVerseAttempt)
          ..where((tbl) => tbl.sessionId.equals(sessionId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
        .get();

    await bridge.onChainCompleted(
      summary: const ChainResultSummary(
        sessionId: 1,
        resultKind: ChainResultKind.completed,
        totalVerses: 2,
        passedVerses: 2,
        averageHintLevel: 1.0,
        averageRetrievalStrength: 0.1,
      ),
      ayahCount: 2,
      attempts: attempts,
      nowLocal: DateTime(2026, 2, 24, 8, 30),
    );

    final rows = await (db.select(db.calibrationSample)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
        .get();

    expect(rows.length, 1);
    expect(rows.single.sampleKind, 'review');
    expect(rows.single.durationSeconds, 132);
  });
}
