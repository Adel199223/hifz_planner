import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../services/companion/companion_models.dart' as companion_models;
import '../time/local_day_time.dart';

class CompanionRepo {
  CompanionRepo(this._db);

  final AppDatabase _db;

  Future<int> startChainSession({
    required int unitId,
    required int targetVerseCount,
    required int createdAtDay,
    required int startedAtSeconds,
  }) {
    return _db.into(_db.companionChainSession).insert(
          CompanionChainSessionCompanion.insert(
            unitId: unitId,
            targetVerseCount: targetVerseCount,
            passedVerseCount: const Value(0),
            chainResult: 'partial',
            retrievalStrength: const Value(0.0),
            createdAtDay: createdAtDay,
            updatedAtDay: createdAtDay,
            startedAtSeconds: Value(startedAtSeconds),
          ),
        );
  }

  Future<void> completeChainSession({
    required int sessionId,
    required int passedVerseCount,
    required String chainResult,
    required double retrievalStrength,
    required int updatedAtDay,
    required int endedAtSeconds,
  }) async {
    await (_db.update(_db.companionChainSession)
          ..where((tbl) => tbl.id.equals(sessionId)))
        .write(
      CompanionChainSessionCompanion(
        passedVerseCount: Value(passedVerseCount),
        chainResult: Value(chainResult),
        retrievalStrength: Value(retrievalStrength),
        endedAtSeconds: Value(endedAtSeconds),
        updatedAtDay: Value(updatedAtDay),
      ),
    );
  }

  Future<int> insertVerseAttempt({
    required int sessionId,
    required int unitId,
    required int verseOrder,
    required int surah,
    required int ayah,
    required int attemptIndex,
    required String stageCode,
    String attemptType = 'probe',
    required String hintLevel,
    int assistedFlag = 0,
    required int latencyToStartMs,
    required int stopsCount,
    required int selfCorrectionsCount,
    required String evaluatorMode,
    required int evaluatorPassed,
    required double? evaluatorConfidence,
    String? autoCheckType,
    String? autoCheckResult,
    required int revealedAfterAttempt,
    required double retrievalStrength,
    int timeOnVerseMs = 0,
    int timeOnChunkMs = 0,
    String? telemetryJson,
    required int attemptDay,
    required int attemptSeconds,
  }) {
    return _db.into(_db.companionVerseAttempt).insert(
          CompanionVerseAttemptCompanion.insert(
            sessionId: sessionId,
            unitId: unitId,
            verseOrder: verseOrder,
            surah: surah,
            ayah: ayah,
            attemptIndex: attemptIndex,
            stageCode: Value(stageCode),
            attemptType: Value(attemptType),
            hintLevel: hintLevel,
            assistedFlag: Value(assistedFlag),
            latencyToStartMs: Value(latencyToStartMs),
            stopsCount: Value(stopsCount),
            selfCorrectionsCount: Value(selfCorrectionsCount),
            evaluatorMode: evaluatorMode,
            evaluatorPassed: evaluatorPassed,
            evaluatorConfidence: Value(evaluatorConfidence),
            autoCheckType: Value(autoCheckType),
            autoCheckResult: Value(autoCheckResult),
            revealedAfterAttempt: revealedAfterAttempt,
            retrievalStrength: retrievalStrength,
            timeOnVerseMs: Value(timeOnVerseMs),
            timeOnChunkMs: Value(timeOnChunkMs),
            telemetryJson: Value(telemetryJson),
            attemptDay: attemptDay,
            attemptSeconds: Value(attemptSeconds),
          ),
        );
  }

  Future<void> upsertStepProficiency({
    required int unitId,
    required int surah,
    required int ayah,
    required double proficiencyEma,
    required String lastHintLevel,
    required double? lastEvaluatorConfidence,
    required int? lastLatencyToStartMs,
    required int attemptsCount,
    required int passesCount,
    required int lastUpdatedDay,
    required int lastSessionId,
  }) async {
    await _db.into(_db.companionStepProficiency).insert(
          CompanionStepProficiencyCompanion.insert(
            unitId: unitId,
            surah: surah,
            ayah: ayah,
            proficiencyEma: Value(proficiencyEma),
            lastHintLevel: Value(lastHintLevel),
            lastEvaluatorConfidence: Value(lastEvaluatorConfidence),
            lastLatencyToStartMs: Value(lastLatencyToStartMs),
            attemptsCount: Value(attemptsCount),
            passesCount: Value(passesCount),
            lastUpdatedDay: lastUpdatedDay,
            lastSessionId: Value(lastSessionId),
          ),
          onConflict: DoUpdate(
            (_) => CompanionStepProficiencyCompanion(
              proficiencyEma: Value(proficiencyEma),
              lastHintLevel: Value(lastHintLevel),
              lastEvaluatorConfidence: Value(lastEvaluatorConfidence),
              lastLatencyToStartMs: Value(lastLatencyToStartMs),
              attemptsCount: Value(attemptsCount),
              passesCount: Value(passesCount),
              lastUpdatedDay: Value(lastUpdatedDay),
              lastSessionId: Value(lastSessionId),
            ),
            target: <Column<Object>>[
              _db.companionStepProficiency.unitId,
              _db.companionStepProficiency.surah,
              _db.companionStepProficiency.ayah,
            ],
          ),
        );
  }

  Future<CompanionStepProficiencyData?> getStepProficiency({
    required int unitId,
    required int surah,
    required int ayah,
  }) {
    return (_db.select(_db.companionStepProficiency)
          ..where((tbl) =>
              tbl.unitId.equals(unitId) &
              tbl.surah.equals(surah) &
              tbl.ayah.equals(ayah))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<CompanionVerseAttemptData>> getAttemptsForSession(int sessionId) {
    return (_db.select(_db.companionVerseAttempt)
          ..where((tbl) => tbl.sessionId.equals(sessionId))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.verseOrder),
            (tbl) => OrderingTerm.asc(tbl.attemptIndex),
            (tbl) => OrderingTerm.asc(tbl.id),
          ]))
        .get();
  }

  Future<companion_models.CompanionUnitState> getOrCreateUnitState(
    int unitId, {
    DateTime? nowLocal,
  }) async {
    final existing = await (_db.select(_db.companionUnitState)
          ..where((tbl) => tbl.unitId.equals(unitId))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) {
      return companion_models.CompanionUnitState(
        unitId: existing.unitId,
        unlockedStage: companion_models.CompanionStage.fromStageNumber(
          existing.unlockedStage,
        ),
        updatedAtDay: existing.updatedAtDay,
        updatedAtSeconds: existing.updatedAtSeconds,
      );
    }

    final effectiveNow = (nowLocal ?? DateTime.now()).toLocal();
    final day = localDayIndex(effectiveNow);
    final seconds = nowLocalSecondsSinceMidnight(effectiveNow);

    try {
      await _db.into(_db.companionUnitState).insert(
            CompanionUnitStateCompanion.insert(
              unitId: Value(unitId),
              unlockedStage:
                  companion_models.CompanionStage.guidedVisible.stageNumber,
              updatedAtDay: day,
              updatedAtSeconds: seconds,
            ),
          );
    } catch (_) {
      // A parallel writer may insert before us; re-read below.
    }

    final created = await (_db.select(_db.companionUnitState)
          ..where((tbl) => tbl.unitId.equals(unitId))
          ..limit(1))
        .getSingleOrNull();
    if (created == null) {
      throw StateError('Failed to get/create companion unit state for $unitId');
    }

    return companion_models.CompanionUnitState(
      unitId: created.unitId,
      unlockedStage:
          companion_models.CompanionStage.fromStageNumber(created.unlockedStage),
      updatedAtDay: created.updatedAtDay,
      updatedAtSeconds: created.updatedAtSeconds,
    );
  }

  Future<void> updateUnlockedStage({
    required int unitId,
    required companion_models.CompanionStage stage,
    required int updatedAtDay,
    required int updatedAtSeconds,
  }) async {
    await _db.into(_db.companionUnitState).insert(
          CompanionUnitStateCompanion.insert(
            unitId: Value(unitId),
            unlockedStage: stage.stageNumber,
            updatedAtDay: updatedAtDay,
            updatedAtSeconds: updatedAtSeconds,
          ),
          onConflict: DoUpdate(
            (_) => CompanionUnitStateCompanion(
              unlockedStage: Value(stage.stageNumber),
              updatedAtDay: Value(updatedAtDay),
              updatedAtSeconds: Value(updatedAtSeconds),
            ),
            target: <Column<Object>>[_db.companionUnitState.unitId],
          ),
        );
  }

  Future<int> insertStageEvent({
    required int sessionId,
    required int unitId,
    required companion_models.CompanionStage fromStage,
    required companion_models.CompanionStage toStage,
    required String eventType,
    required int? triggerVerseOrder,
    required int createdDay,
    required int createdSeconds,
  }) {
    return _db.into(_db.companionStageEvent).insert(
          CompanionStageEventCompanion.insert(
            sessionId: sessionId,
            unitId: unitId,
            fromStage: fromStage.stageNumber,
            toStage: toStage.stageNumber,
            eventType: eventType,
            triggerVerseOrder: Value(triggerVerseOrder),
            createdDay: createdDay,
            createdSeconds: createdSeconds,
          ),
        );
  }

  Future<List<CompanionStageEventData>> getStageEventsForSession(int sessionId) {
    return (_db.select(_db.companionStageEvent)
          ..where((tbl) => tbl.sessionId.equals(sessionId))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.createdDay),
            (tbl) => OrderingTerm.asc(tbl.id),
          ]))
        .get();
  }

  Future<CompanionChainSessionData?> getChainSession(int sessionId) {
    return (_db.select(_db.companionChainSession)
          ..where((tbl) => tbl.id.equals(sessionId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<CompanionLifecycleStateData?> getLifecycleState(int unitId) {
    return (_db.select(_db.companionLifecycleState)
          ..where((tbl) => tbl.unitId.equals(unitId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> upsertLifecycleState({
    required int unitId,
    Value<String> lifecycleTier = const Value.absent(),
    Value<String> stage4Status = const Value.absent(),
    Value<int?> stage4PreSleepDueDay = const Value.absent(),
    Value<int?> stage4NextDayDueDay = const Value.absent(),
    Value<int?> stage4RetryDueDay = const Value.absent(),
    Value<String?> stage4UnresolvedTargetsJson = const Value.absent(),
    Value<String?> stage4RiskJson = const Value.absent(),
    Value<String?> stage4StrengtheningRoute = const Value.absent(),
    Value<String?> stage4LastOutcome = const Value.absent(),
    Value<int?> stage4LastSessionId = const Value.absent(),
    Value<int?> stage4LastCompletedDay = const Value.absent(),
    Value<int> stage4MissedCount = const Value.absent(),
    Value<int?> lastNewOverrideDay = const Value.absent(),
    Value<int> newOverrideCount = const Value.absent(),
    required int updatedAtDay,
    required int updatedAtSeconds,
  }) async {
    await _db.into(_db.companionLifecycleState).insert(
          CompanionLifecycleStateCompanion.insert(
            unitId: Value(unitId),
            lifecycleTier: lifecycleTier,
            stage4Status: stage4Status,
            stage4PreSleepDueDay: stage4PreSleepDueDay,
            stage4NextDayDueDay: stage4NextDayDueDay,
            stage4RetryDueDay: stage4RetryDueDay,
            stage4UnresolvedTargetsJson: stage4UnresolvedTargetsJson,
            stage4RiskJson: stage4RiskJson,
            stage4StrengtheningRoute: stage4StrengtheningRoute,
            stage4LastOutcome: stage4LastOutcome,
            stage4LastSessionId: stage4LastSessionId,
            stage4LastCompletedDay: stage4LastCompletedDay,
            stage4MissedCount: stage4MissedCount,
            lastNewOverrideDay: lastNewOverrideDay,
            newOverrideCount: newOverrideCount,
            updatedAtDay: updatedAtDay,
            updatedAtSeconds: updatedAtSeconds,
          ),
          onConflict: DoUpdate(
            (_) => CompanionLifecycleStateCompanion(
              lifecycleTier: lifecycleTier,
              stage4Status: stage4Status,
              stage4PreSleepDueDay: stage4PreSleepDueDay,
              stage4NextDayDueDay: stage4NextDayDueDay,
              stage4RetryDueDay: stage4RetryDueDay,
              stage4UnresolvedTargetsJson: stage4UnresolvedTargetsJson,
              stage4RiskJson: stage4RiskJson,
              stage4StrengtheningRoute: stage4StrengtheningRoute,
              stage4LastOutcome: stage4LastOutcome,
              stage4LastSessionId: stage4LastSessionId,
              stage4LastCompletedDay: stage4LastCompletedDay,
              stage4MissedCount: stage4MissedCount,
              lastNewOverrideDay: lastNewOverrideDay,
              newOverrideCount: newOverrideCount,
              updatedAtDay: Value(updatedAtDay),
              updatedAtSeconds: Value(updatedAtSeconds),
            ),
            target: <Column<Object>>[_db.companionLifecycleState.unitId],
          ),
        );
  }

  Future<List<CompanionLifecycleStateData>> getDueLifecycleStates({
    required int todayDay,
  }) {
    final pendingOrDue = _db.companionLifecycleState.stage4Status.equals('due') |
        _db.companionLifecycleState.stage4Status.equals('pending') |
        _db.companionLifecycleState.stage4Status.equals('partial') |
        _db.companionLifecycleState.stage4Status.equals('failed');
    final nextDayDue = _db.companionLifecycleState.stage4NextDayDueDay
            .isNotNull() &
        _db.companionLifecycleState.stage4NextDayDueDay
            .isSmallerOrEqualValue(todayDay);
    final retryDue = _db.companionLifecycleState.stage4RetryDueDay.isNotNull() &
        _db.companionLifecycleState.stage4RetryDueDay
            .isSmallerOrEqualValue(todayDay);
    final preSleepDue =
        _db.companionLifecycleState.stage4PreSleepDueDay.isNotNull() &
            _db.companionLifecycleState.stage4PreSleepDueDay
                .isSmallerOrEqualValue(todayDay);

    return (_db.select(_db.companionLifecycleState)
          ..where((tbl) => pendingOrDue & (nextDayDue | retryDue | preSleepDue)))
        .get();
  }

  Future<void> recordNewOverride({
    required int unitId,
    required int todayDay,
    required int updatedAtSeconds,
  }) async {
    final existing = await getLifecycleState(unitId);
    final nextCount = (existing?.newOverrideCount ?? 0) + 1;
    await upsertLifecycleState(
      unitId: unitId,
      lastNewOverrideDay: Value(todayDay),
      newOverrideCount: Value(nextCount),
      updatedAtDay: todayDay,
      updatedAtSeconds: updatedAtSeconds,
    );
  }

  Future<int> startStage4Session({
    required int unitId,
    int? chainSessionId,
    required String dueKind,
    required int startedDay,
    required int startedSeconds,
    String? unresolvedTargetsJson,
    String? telemetryJson,
  }) {
    return _db.into(_db.companionStage4Session).insert(
          CompanionStage4SessionCompanion.insert(
            unitId: unitId,
            chainSessionId: Value(chainSessionId),
            dueKind: dueKind,
            startedDay: startedDay,
            startedSeconds: Value(startedSeconds),
            unresolvedTargetsJson: Value(unresolvedTargetsJson),
            telemetryJson: Value(telemetryJson),
          ),
        );
  }

  Future<void> completeStage4Session({
    required int sessionId,
    required String outcome,
    required int endedDay,
    required int endedSeconds,
    required double countedPassRate,
    required int randomStartPasses,
    required int linkingPasses,
    required int discriminationPasses,
    String? unresolvedTargetsJson,
    String? telemetryJson,
  }) async {
    await (_db.update(_db.companionStage4Session)
          ..where((tbl) => tbl.id.equals(sessionId)))
        .write(
      CompanionStage4SessionCompanion(
        outcome: Value(outcome),
        endedDay: Value(endedDay),
        endedSeconds: Value(endedSeconds),
        countedPassRate: Value(countedPassRate),
        randomStartPasses: Value(randomStartPasses),
        linkingPasses: Value(linkingPasses),
        discriminationPasses: Value(discriminationPasses),
        unresolvedTargetsJson: Value(unresolvedTargetsJson),
        telemetryJson: Value(telemetryJson),
      ),
    );
  }

  Future<List<CompanionStage4SessionData>> getStage4SessionsForUnit(
    int unitId,
  ) {
    return (_db.select(_db.companionStage4Session)
          ..where((tbl) => tbl.unitId.equals(unitId))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.startedDay),
            (tbl) => OrderingTerm.asc(tbl.id),
          ]))
        .get();
  }

  Future<CompanionStage4SessionData?> getLatestStage4SessionForUnit(
    int unitId,
  ) {
    return (_db.select(_db.companionStage4Session)
          ..where((tbl) => tbl.unitId.equals(unitId))
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.startedDay),
            (tbl) => OrderingTerm.desc(tbl.id),
          ])
          ..limit(1))
        .getSingleOrNull();
  }
}
