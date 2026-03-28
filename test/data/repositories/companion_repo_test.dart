import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/companion_repo.dart';
import 'package:hifz_planner/data/services/adaptive_queue_policy.dart';
import 'package:hifz_planner/data/services/companion/companion_models.dart';

void main() {
  late AppDatabase db;
  late CompanionRepo repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = CompanionRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> createUnit() {
    return db.into(db.memUnit).insert(
          MemUnitCompanion.insert(
            kind: 'ayah_range',
            unitKey: 'companion-unit-1',
            startSurah: const Value(1),
            startAyah: const Value(1),
            endSurah: const Value(1),
            endAyah: const Value(1),
            createdAtDay: 100,
            updatedAtDay: 100,
          ),
        );
  }

  test('persists chain session and attempt telemetry', () async {
    final unitId = await createUnit();
    final sessionId = await repo.startChainSession(
      unitId: unitId,
      targetVerseCount: 1,
      createdAtDay: 100,
      startedAtSeconds: 300,
    );

    await repo.insertVerseAttempt(
      sessionId: sessionId,
      unitId: unitId,
      verseOrder: 0,
      surah: 1,
      ayah: 1,
      attemptIndex: 1,
      stageCode: CompanionStage.hiddenReveal.code,
      attemptType: 'checkpoint',
      hintLevel: 'letters',
      assistedFlag: 1,
      latencyToStartMs: 900,
      stopsCount: 1,
      selfCorrectionsCount: 1,
      evaluatorMode: 'manual_fallback',
      evaluatorPassed: 1,
      evaluatorConfidence: 0.7,
      autoCheckType: 'next_word_mcq',
      autoCheckResult: 'pass',
      revealedAfterAttempt: 1,
      retrievalStrength: 0.8,
      timeOnVerseMs: 32000,
      timeOnChunkMs: 64000,
      telemetryJson: '{"stage1_mode":"checkpoint"}',
      attemptDay: 100,
      attemptSeconds: 340,
    );

    await repo.completeChainSession(
      sessionId: sessionId,
      passedVerseCount: 1,
      chainResult: 'completed',
      retrievalStrength: 0.8,
      updatedAtDay: 100,
      endedAtSeconds: 400,
    );

    final session = await repo.getChainSession(sessionId);
    final attempts = await repo.getAttemptsForSession(sessionId);

    expect(session, isNotNull);
    expect(session!.chainResult, 'completed');
    expect(session.passedVerseCount, 1);
    expect(attempts.length, 1);
    expect(attempts.single.hintLevel, 'letters');
    expect(attempts.single.stageCode, CompanionStage.hiddenReveal.code);
    expect(attempts.single.attemptType, 'checkpoint');
    expect(attempts.single.assistedFlag, 1);
    expect(attempts.single.autoCheckType, 'next_word_mcq');
    expect(attempts.single.autoCheckResult, 'pass');
    expect(attempts.single.timeOnVerseMs, 32000);
    expect(attempts.single.timeOnChunkMs, 64000);
    expect(attempts.single.telemetryJson, '{"stage1_mode":"checkpoint"}');
    expect(attempts.single.retrievalStrength, 0.8);
  });

  test('persists Stage-2 telemetry payload in telemetry_json', () async {
    final unitId = await createUnit();
    final sessionId = await repo.startChainSession(
      unitId: unitId,
      targetVerseCount: 1,
      createdAtDay: 100,
      startedAtSeconds: 360,
    );

    await repo.insertVerseAttempt(
      sessionId: sessionId,
      unitId: unitId,
      verseOrder: 0,
      surah: 1,
      ayah: 1,
      attemptIndex: 1,
      stageCode: CompanionStage.cuedRecall.code,
      attemptType: 'probe',
      hintLevel: HintLevel.letters.code,
      assistedFlag: 0,
      latencyToStartMs: 600,
      stopsCount: 0,
      selfCorrectionsCount: 0,
      evaluatorMode: EvaluatorMode.manualFallback.code,
      evaluatorPassed: 1,
      evaluatorConfidence: 0.8,
      autoCheckType: 'one_word_cloze',
      autoCheckResult: 'pass',
      revealedAfterAttempt: 0,
      retrievalStrength: 0.6,
      timeOnVerseMs: 18000,
      timeOnChunkMs: 42000,
      telemetryJson:
          '{"stage2_mode":"linking","stage2_step":"linking","weak_target":true}',
      attemptDay: 100,
      attemptSeconds: 390,
    );

    final attempts = await repo.getAttemptsForSession(sessionId);
    expect(attempts.length, 1);
    expect(attempts.single.stageCode, CompanionStage.cuedRecall.code);
    expect(attempts.single.telemetryJson, contains('"stage2_mode":"linking"'));
    expect(attempts.single.telemetryJson, contains('"weak_target":true'));
  });

  test('upsertStepProficiency updates same unit/surah/ayah row', () async {
    final unitId = await createUnit();
    final sessionId = await repo.startChainSession(
      unitId: unitId,
      targetVerseCount: 1,
      createdAtDay: 100,
      startedAtSeconds: 1000,
    );

    await repo.upsertStepProficiency(
      unitId: unitId,
      surah: 1,
      ayah: 1,
      proficiencyEma: 0.4,
      lastHintLevel: 'letters',
      lastEvaluatorConfidence: 0.6,
      lastLatencyToStartMs: 700,
      attemptsCount: 1,
      passesCount: 0,
      lastUpdatedDay: 100,
      lastSessionId: sessionId,
    );

    await repo.upsertStepProficiency(
      unitId: unitId,
      surah: 1,
      ayah: 1,
      proficiencyEma: 0.7,
      lastHintLevel: 'first_word',
      lastEvaluatorConfidence: 0.9,
      lastLatencyToStartMs: 500,
      attemptsCount: 2,
      passesCount: 1,
      lastUpdatedDay: 101,
      lastSessionId: sessionId,
    );

    final row = await repo.getStepProficiency(
      unitId: unitId,
      surah: 1,
      ayah: 1,
    );

    expect(row, isNotNull);
    expect(row!.proficiencyEma, 0.7);
    expect(row.attemptsCount, 2);
    expect(row.passesCount, 1);
    expect(row.lastHintLevel, 'first_word');
  });

  test('companion_unit_state get/create and update persist unlocked stage',
      () async {
    final unitId = await createUnit();

    final initial = await repo.getOrCreateUnitState(
      unitId,
      nowLocal: DateTime.utc(2026, 2, 24, 8, 30),
    );
    expect(initial.unitId, unitId);
    expect(initial.unlockedStage, CompanionStage.guidedVisible);

    await repo.updateUnlockedStage(
      unitId: unitId,
      stage: CompanionStage.cuedRecall,
      updatedAtDay: 12345,
      updatedAtSeconds: 500,
    );

    final updated = await repo.getOrCreateUnitState(unitId);
    expect(updated.unlockedStage, CompanionStage.cuedRecall);
    expect(updated.updatedAtDay, 12345);
    expect(updated.updatedAtSeconds, 500);
  });

  test('companion_stage_event inserts and orders by created day and id',
      () async {
    final unitId = await createUnit();
    final sessionId = await repo.startChainSession(
      unitId: unitId,
      targetVerseCount: 2,
      createdAtDay: 100,
      startedAtSeconds: 120,
    );

    await repo.insertStageEvent(
      sessionId: sessionId,
      unitId: unitId,
      fromStage: CompanionStage.guidedVisible,
      toStage: CompanionStage.cuedRecall,
      eventType: 'auto_unlock',
      triggerVerseOrder: 0,
      createdDay: 100,
      createdSeconds: 140,
    );
    await repo.insertStageEvent(
      sessionId: sessionId,
      unitId: unitId,
      fromStage: CompanionStage.cuedRecall,
      toStage: CompanionStage.hiddenReveal,
      eventType: 'user_skip',
      triggerVerseOrder: 1,
      createdDay: 101,
      createdSeconds: 150,
    );

    final events = await repo.getStageEventsForSession(sessionId);
    expect(events.length, 2);
    expect(events.first.eventType, 'auto_unlock');
    expect(events.first.fromStage, 1);
    expect(events.first.toStage, 2);
    expect(events.last.eventType, 'user_skip');
    expect(events.last.fromStage, 2);
    expect(events.last.toStage, 3);
  });

  test('upserts lifecycle state and returns due stage-4 rows', () async {
    final unitIdA = await createUnit();
    final unitIdB = await db.into(db.memUnit).insert(
          MemUnitCompanion.insert(
            kind: 'ayah_range',
            unitKey: 'companion-unit-2',
            startSurah: const Value(1),
            startAyah: const Value(2),
            endSurah: const Value(1),
            endAyah: const Value(2),
            createdAtDay: 100,
            updatedAtDay: 100,
          ),
        );

    await repo.upsertLifecycleState(
      unitId: unitIdA,
      lifecycleTier: const Value('ready'),
      stage4Status: const Value('pending'),
      stage4NextDayDueDay: const Value(105),
      stage4UnresolvedTargetsJson: const Value('[0]'),
      updatedAtDay: 104,
      updatedAtSeconds: 400,
    );
    await repo.upsertLifecycleState(
      unitId: unitIdB,
      lifecycleTier: const Value('stable'),
      stage4Status: const Value('passed'),
      stage4NextDayDueDay: const Value(106),
      updatedAtDay: 104,
      updatedAtSeconds: 401,
    );

    final stateA = await repo.getLifecycleState(unitIdA);
    expect(stateA, isNotNull);
    expect(stateA!.lifecycleTier, 'ready');
    expect(stateA.stage4Status, 'pending');
    expect(stateA.stage4UnresolvedTargetsJson, '[0]');

    final due = await repo.getDueLifecycleStates(todayDay: 105);
    expect(due.map((row) => row.unitId).toSet(), contains(unitIdA));
    expect(due.map((row) => row.unitId).toSet(), isNot(contains(unitIdB)));
  });

  test('getAdaptiveStatesByUnitIds keeps lastErrorType null for healthy rows',
      () async {
    final unitId = await createUnit();

    await repo.writeAdaptiveState(
      unitId: unitId,
      weakSpotScore: 0.15,
      recentStruggleCount: 0,
      lastErrorType: null,
      updatedAtDay: 105,
      updatedAtSeconds: 450,
    );

    final states = await repo.getAdaptiveStatesByUnitIds(<int>[unitId]);

    expect(states[unitId], isNotNull);
    expect(states[unitId]!.weakSpotScore, 0.15);
    expect(states[unitId]!.recentStruggleCount, 0);
    expect(states[unitId]!.lastErrorType, isNull);
  });

  test('getAdaptiveStatesByUnitIds decodes hesitation lastErrorType',
      () async {
    final unitId = await createUnit();

    await repo.writeAdaptiveState(
      unitId: unitId,
      weakSpotScore: 0.45,
      recentStruggleCount: 1,
      lastErrorType: AdaptiveLastErrorType.hesitation.dbValue,
      updatedAtDay: 106,
      updatedAtSeconds: 500,
    );

    final states = await repo.getAdaptiveStatesByUnitIds(<int>[unitId]);

    expect(states[unitId], isNotNull);
    expect(
      states[unitId]!.lastErrorType,
      AdaptiveLastErrorType.hesitation,
    );
  });

  test('getAdaptiveStatesByUnitIds decodes wrongRecall lastErrorType',
      () async {
    final unitId = await createUnit();

    await repo.writeAdaptiveState(
      unitId: unitId,
      weakSpotScore: 0.7,
      recentStruggleCount: 2,
      lastErrorType: AdaptiveLastErrorType.wrongRecall.dbValue,
      updatedAtDay: 107,
      updatedAtSeconds: 550,
    );

    final states = await repo.getAdaptiveStatesByUnitIds(<int>[unitId]);

    expect(states[unitId], isNotNull);
    expect(
      states[unitId]!.lastErrorType,
      AdaptiveLastErrorType.wrongRecall,
    );
  });

  test('persists stage-4 session outcome and telemetry', () async {
    final unitId = await createUnit();

    final stage4SessionId = await repo.startStage4Session(
      unitId: unitId,
      chainSessionId: null,
      dueKind: 'next_day_required',
      startedDay: 110,
      startedSeconds: 120,
      unresolvedTargetsJson: '[1]',
      telemetryJson: '{"stage4_phase":"verification"}',
    );

    await repo.completeStage4Session(
      sessionId: stage4SessionId,
      outcome: 'partial',
      endedDay: 110,
      endedSeconds: 180,
      countedPassRate: 0.66,
      randomStartPasses: 1,
      linkingPasses: 1,
      discriminationPasses: 0,
      unresolvedTargetsJson: '[1]',
      telemetryJson:
          '{"stage4_phase":"budget_fallback","lifecycle_hook":"stage4_retry"}',
    );

    final latest = await repo.getLatestStage4SessionForUnit(unitId);
    expect(latest, isNotNull);
    expect(latest!.id, stage4SessionId);
    expect(latest.dueKind, 'next_day_required');
    expect(latest.outcome, 'partial');
    expect(latest.countedPassRate, 0.66);
    expect(latest.randomStartPasses, 1);
    expect(latest.linkingPasses, 1);
    expect(latest.unresolvedTargetsJson, '[1]');
    expect(latest.telemetryJson, contains('"stage4_retry"'));
  });
}
