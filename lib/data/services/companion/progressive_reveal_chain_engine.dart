import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../database/app_database.dart'
    show CompanionLifecycleStateData, CompanionStepProficiencyData;
import '../../repositories/companion_repo.dart';
import '../../time/local_day_time.dart';
import 'companion_calibration_bridge.dart';
import 'companion_models.dart';
import 'stage1_auto_check_engine.dart';
import 'verse_evaluator.dart';

class ChainAttemptUpdate {
  const ChainAttemptUpdate({
    required this.state,
    required this.telemetry,
    this.summary,
  });

  final ChainRunState state;
  final VerseAttemptTelemetry telemetry;
  final ChainResultSummary? summary;
}

class ProgressiveRevealChainEngine {
  ProgressiveRevealChainEngine(
    this._companionRepo,
    this._calibrationBridge, {
    Stage1AutoCheckEngine autoCheckEngine = const Stage1AutoCheckEngine(),
  }) : _autoCheckEngine = autoCheckEngine;

  final CompanionRepo _companionRepo;
  final CompanionCalibrationBridge _calibrationBridge;
  final Stage1AutoCheckEngine _autoCheckEngine;

  Future<ChainRunState> startSession({
    required int unitId,
    required List<ChainVerse> verses,
    required CompanionLaunchMode launchMode,
    CompanionStage? unlockedStage,
    ProgressiveRevealChainConfig config = const ProgressiveRevealChainConfig(),
    double? avgNewMinutesPerAyah,
    DateTime? nowLocal,
  }) async {
    if (verses.isEmpty) {
      throw ArgumentError.value(
        verses,
        'verses',
        'At least one verse is required.',
      );
    }

    final effectiveNow = (nowLocal ?? DateTime.now()).toLocal();
    final createdAtDay = localDayIndex(effectiveNow);
    final createdAtSeconds = nowLocalSecondsSinceMidnight(effectiveNow);

    final isNewMode = launchMode == CompanionLaunchMode.newMemorization;
    final isReviewMode = launchMode == CompanionLaunchMode.review;
    final isStage4Mode = launchMode == CompanionLaunchMode.stage4Consolidation;

    final persistedUnitState = isNewMode
        ? await _companionRepo.getOrCreateUnitState(
            unitId,
            nowLocal: effectiveNow,
          )
        : null;

    final resolvedUnlockedStage = isReviewMode || isStage4Mode
        ? CompanionStage.hiddenReveal
        : _maxStage(
            persistedUnitState!.unlockedStage,
            unlockedStage ?? persistedUnitState.unlockedStage,
          );
    final activeStage = isReviewMode || isStage4Mode
        ? CompanionStage.hiddenReveal
        : resolvedUnlockedStage;

    final sessionId = await _companionRepo.startChainSession(
      unitId: unitId,
      targetVerseCount: verses.length,
      createdAtDay: createdAtDay,
      startedAtSeconds: createdAtSeconds,
    );

    if (isNewMode && activeStage != CompanionStage.guidedVisible) {
      await _companionRepo.insertStageEvent(
        sessionId: sessionId,
        unitId: unitId,
        fromStage: activeStage,
        toStage: activeStage,
        eventType: 'resume_stage',
        triggerVerseOrder: null,
        createdDay: createdAtDay,
        createdSeconds: createdAtSeconds,
      );
    }

    final stageOneCleared = activeStage.stageNumber > 1;
    final stageTwoCleared = activeStage.stageNumber > 2;
    final seededReviewProficiencies = isReviewMode
        ? await Future.wait(
            verses.map(
              (verse) => _companionRepo.getStepProficiency(
                unitId: unitId,
                surah: verse.surah,
                ayah: verse.ayah,
              ),
            ),
          )
        : null;
    final verseStates = <ChainVerseState>[
      for (var i = 0; i < verses.length; i++)
        _seedInitialVerseState(
          verse: verses[i],
          stageOneCleared: stageOneCleared,
          stageTwoCleared: stageTwoCleared,
          reviewProficiency: seededReviewProficiencies?[i],
          reviewConfig: config.stage3,
        ),
    ];

    final nowEpochMs = effectiveNow.millisecondsSinceEpoch;
    final resolvedAvg =
        avgNewMinutesPerAyah == null || avgNewMinutesPerAyah <= 0
            ? config.defaultAvgNewMinutesPerAyah
            : avgNewMinutesPerAyah;
    final stage1BudgetMs = config.stage1.stage1ChunkBudgetMs(
      ayahCount: verseStates.length,
      avgNewMinutesPerAyah: resolvedAvg,
    );
    final perVerseCapMs = config.stage1.perVerseCapMs(
      ayahCount: verseStates.length,
      stage1ChunkBudgetMs: stage1BudgetMs,
    );
    final stage1Runtime =
        isNewMode && activeStage == CompanionStage.guidedVisible
            ? Stage1Runtime(
                config: config.stage1,
                phase: Stage1Phase.acquisition,
                mode: Stage1Mode.modelEcho,
                startedAtEpochMs: nowEpochMs,
                lastActionAtEpochMs: nowEpochMs,
                chunkElapsedMs: 0,
                stage1BudgetMs: stage1BudgetMs,
                perVerseCapMs: perVerseCapMs,
                adaptiveSpacingMs: config.stage1.minSpacingMs,
                adaptiveEchoLoopCap: config.stage1.echoDefaultLoops.clamp(
                  config.stage1.echoMinLoops,
                  config.stage1.echoMaxLoops,
                ),
                hintsUnlockedForCurrentProbe: false,
                currentProbeAttemptCount: 0,
                totalRetrievalAttempts: 0,
                totalRetrievalPasses: 0,
                budgetExceeded: false,
                remediationRequiresCheckpoint: false,
                remediationRounds: 0,
                checkpointTargets: const <int>[],
                checkpointCursor: 0,
                remediationTargets: const <int>[],
                remediationCursor: 0,
                cumulativeTargets: const <int>[],
                cumulativeCursor: 0,
                lastCheckpointOutcome: null,
                activeAutoCheckPrompt: null,
              )
            : null;

    var initialState = ChainRunState(
      sessionId: sessionId,
      unitId: unitId,
      launchMode: launchMode,
      activeStage: activeStage,
      unlockedStage: resolvedUnlockedStage,
      verses: verseStates,
      currentVerseIndex:
          _firstUnpassedIndexForStage(verseStates, activeStage) ?? 0,
      currentHintLevel: _defaultHintForStage(activeStage),
      returnVerseIndex: null,
      completed: false,
      resultKind: ChainResultKind.partial,
      stage1: stage1Runtime,
      stage2: null,
      stage3: null,
      stage4: null,
      review: null,
      stage3WeakPreludeTargets: const <int>[],
      stage3WeakPreludeCursor: 0,
      resolvedAvgNewMinutesPerAyah: resolvedAvg,
    );

    if (isNewMode && activeStage == CompanionStage.cuedRecall) {
      initialState = _initializeStage2Runtime(
        state: initialState,
        config: config,
        nowEpochMs: nowEpochMs,
      );
    }

    if (isNewMode && activeStage == CompanionStage.hiddenReveal) {
      initialState = _initializeStage3Runtime(
        state: initialState,
        config: config,
        nowEpochMs: nowEpochMs,
        weakPreludeTargets: initialState.stage3WeakPreludeTargets,
      );
    }

    if (isStage4Mode && activeStage == CompanionStage.hiddenReveal) {
      initialState = await _initializeStage4Runtime(
        state: initialState,
        config: config,
        nowEpochMs: nowEpochMs,
        nowLocal: effectiveNow,
      );
    }

    if (isReviewMode && activeStage == CompanionStage.hiddenReveal) {
      initialState = _initializeReviewRuntime(
        state: initialState,
        config: config,
        nowEpochMs: nowEpochMs,
      );
    }

    return initialState;
  }

  ChainRunState requestHint(ChainRunState state) {
    if (state.completed) {
      return state;
    }

    final stage1 = state.stage1;
    if (stage1 != null &&
        state.activeStage == CompanionStage.guidedVisible &&
        stage1.autoCheckRequiredForCurrentMode &&
        !stage1.hintsUnlockedForCurrentProbe) {
      return state;
    }

    final baseline = _defaultHintForStage(state.activeStage);
    final current = state.currentHintLevel.order < baseline.order
        ? baseline
        : state.currentHintLevel;
    return state.copyWith(
      currentHintLevel: current.next(),
    );
  }

  Future<ChainRunState> skipCurrentStage({
    required ChainRunState state,
    DateTime? nowLocal,
  }) async {
    if (state.completed || state.activeStage == CompanionStage.hiddenReveal) {
      return state;
    }

    final nextStage = state.activeStage.next();
    if (nextStage == null) {
      return state;
    }

    final effectiveNow = (nowLocal ?? DateTime.now()).toLocal();
    final unresolvedBeforeSkip = <int>[
      for (var i = 0; i < state.verses.length; i++)
        if (!state.verses[i].passedForStage(state.activeStage)) i,
    ];
    final updatedVerses = <ChainVerseState>[
      for (final verse in state.verses)
        verse.passedForStage(state.activeStage)
            ? verse.copyWith(
                stage1: verse.stage1.copyWith(
                  weak: state.activeStage == CompanionStage.guidedVisible
                      ? (verse.stage1.weak ||
                          !verse.stage1.hasAnyH0Success ||
                          !verse.stage1.spacedConfirmed)
                      : verse.stage1.weak,
                ),
                stage2: state.activeStage == CompanionStage.cuedRecall
                    ? verse.stage2.copyWith(
                        weakTarget: verse.stage2.weakTarget,
                      )
                    : verse.stage2,
              )
            : verse.markPassedForStage(state.activeStage).copyWith(
                  stage1: verse.stage1.copyWith(
                    weak: state.activeStage == CompanionStage.guidedVisible
                        ? (verse.stage1.weak ||
                            !verse.stage1.hasAnyH0Success ||
                            !verse.stage1.spacedConfirmed)
                        : verse.stage1.weak,
                  ),
                  stage2: state.activeStage == CompanionStage.cuedRecall
                      ? verse.stage2.copyWith(
                          weakTarget: true,
                          remediationNeeded: true,
                        )
                      : verse.stage2,
                ),
    ];

    final weakPreludeTargets = state.activeStage == CompanionStage.cuedRecall
        ? unresolvedBeforeSkip
        : state.stage3WeakPreludeTargets;

    if (!state.isReviewMode) {
      final unlocked = _maxStage(state.unlockedStage, nextStage);
      await _companionRepo.updateUnlockedStage(
        unitId: state.unitId,
        stage: unlocked,
        updatedAtDay: localDayIndex(effectiveNow),
        updatedAtSeconds: nowLocalSecondsSinceMidnight(effectiveNow),
      );
    }

    await _companionRepo.insertStageEvent(
      sessionId: state.sessionId,
      unitId: state.unitId,
      fromStage: state.activeStage,
      toStage: nextStage,
      eventType: 'user_skip',
      triggerVerseOrder: state.currentVerseIndex,
      createdDay: localDayIndex(effectiveNow),
      createdSeconds: nowLocalSecondsSinceMidnight(effectiveNow),
    );

    var skippedState = state.copyWith(
      activeStage: nextStage,
      unlockedStage: _maxStage(state.unlockedStage, nextStage),
      verses: updatedVerses,
      currentVerseIndex:
          _firstUnpassedIndexForStage(updatedVerses, nextStage) ?? 0,
      currentHintLevel: nextStage == CompanionStage.hiddenReveal &&
              weakPreludeTargets.isNotEmpty
          ? HintLevel.letters
          : _defaultHintForStage(nextStage),
      returnVerseIndex: null,
      stage1: state.stage1?.copyWith(phase: Stage1Phase.skipped),
      stage2: state.activeStage == CompanionStage.cuedRecall
          ? state.stage2?.copyWith(phase: Stage2Phase.skipped)
          : state.stage2,
      stage3: state.activeStage == CompanionStage.hiddenReveal
          ? state.stage3?.copyWith(phase: Stage3Phase.skipped)
          : state.stage3,
      stage3WeakPreludeTargets: weakPreludeTargets,
      stage3WeakPreludeCursor: 0,
    );

    final nowEpochMs = effectiveNow.millisecondsSinceEpoch;
    if (nextStage == CompanionStage.hiddenReveal &&
        !skippedState.isReviewMode) {
      skippedState = _initializeStage3Runtime(
        state: skippedState,
        config: const ProgressiveRevealChainConfig(),
        nowEpochMs: nowEpochMs,
        weakPreludeTargets: weakPreludeTargets,
      );
    }

    return skippedState;
  }

  Future<ChainAttemptUpdate> submitCorrectionExposure({
    required ChainRunState state,
    int latencyToStartMs = 0,
    int stopsCount = 0,
    int selfCorrectionsCount = 0,
    ProgressiveRevealChainConfig config = const ProgressiveRevealChainConfig(),
    DateTime? nowLocal,
  }) async {
    final stage1Correction = state.stage1 != null &&
        state.activeStage == CompanionStage.guidedVisible &&
        state.stage1!.mode == Stage1Mode.correction;
    final stage2Correction = state.stage2 != null &&
        state.activeStage == CompanionStage.cuedRecall &&
        state.stage2!.mode == Stage2Mode.correction;
    final stage3Correction = state.stage3 != null &&
        state.activeStage == CompanionStage.hiddenReveal &&
        state.stage3!.mode == Stage3Mode.correction &&
        !state.isReviewMode;
    final stage4Correction = state.stage4 != null &&
        state.activeStage == CompanionStage.hiddenReveal &&
        state.stage4!.mode == Stage4Mode.correction &&
        !state.isReviewMode;
    final reviewCorrection = state.review != null &&
        state.activeStage == CompanionStage.hiddenReveal &&
        state.review!.mode == ReviewMode.correction &&
        state.isReviewMode;

    if (state.completed ||
        (!stage1Correction &&
            !stage2Correction &&
            !stage3Correction &&
            !stage4Correction &&
            !reviewCorrection)) {
      throw StateError('Correction exposure is not available in this state.');
    }

    if (stage2Correction) {
      final effectiveNow = (nowLocal ?? DateTime.now()).toLocal();
      final touched = _touchStage2Clock(
        state: state,
        nowLocal: effectiveNow,
      );
      var runtime = touched.runtime!;
      final verses = [...touched.verses];
      final currentIndex = state.currentVerseIndex;
      final current = verses[currentIndex];
      final updatedVerse = current.copyWith(
        attemptCount: current.attemptCount + 1,
        stage2: current.stage2.copyWith(
          correctionRequired: false,
        ),
      );
      verses[currentIndex] = updatedVerse;

      await _persistAttempt(
        state: state.copyWith(
          verses: verses,
          stage2: runtime,
        ),
        verseIndex: currentIndex,
        verse: updatedVerse,
        stageCode: state.activeStage.code,
        attemptType: 'encode_echo',
        hintLevel: _stage2EffectiveBaselineHint(updatedVerse.stage2),
        assistedFlag: 0,
        evaluatorMode: EvaluatorMode.manualFallback,
        evaluatorPassed: 1,
        evaluatorConfidence: null,
        autoCheckType: null,
        autoCheckResult: null,
        retrievalStrength: 0.0,
        latencyToStartMs: latencyToStartMs,
        stopsCount: stopsCount,
        selfCorrectionsCount: selfCorrectionsCount,
        nowLocal: effectiveNow,
        telemetryExtras: <String, Object?>{
          'stage2_mode': Stage2Mode.correction.code,
          'stage2_phase': runtime.phase.code,
          'stage2_step': 'correction',
          'correction_exposure': true,
        },
      );

      final nextMode = switch (runtime.phase) {
        Stage2Phase.checkpoint => Stage2Mode.checkpoint,
        Stage2Phase.remediation => Stage2Mode.remediation,
        _ => _stage2ModeForVerse(
            verse: updatedVerse,
            runtime: runtime.copyWith(mode: Stage2Mode.minimalCueRecall),
          ),
      };

      runtime = runtime.copyWith(
        mode: nextMode,
        activeAutoCheckPrompt: nextMode == Stage2Mode.correction
            ? null
            : _buildStage2AutoCheckPrompt(
                state: state.copyWith(verses: verses),
                verses: verses,
                verseIndex: currentIndex,
                mode: nextMode,
              ),
      );

      final nextState = state.copyWith(
        verses: verses,
        stage2: runtime,
        currentHintLevel: _stage2EffectiveBaselineHint(updatedVerse.stage2),
      );
      final budgetAdvance = await _maybeAdvanceStage2AfterBudget(
        state: nextState,
        config: config,
        nowLocal: effectiveNow,
      );
      if (budgetAdvance != null) {
        return budgetAdvance;
      }

      return ChainAttemptUpdate(
        state: nextState,
        telemetry: VerseAttemptTelemetry(
          stage: state.activeStage,
          hintLevel: _stage2EffectiveBaselineHint(updatedVerse.stage2),
          latencyToStartMs: latencyToStartMs,
          stopsCount: stopsCount,
          selfCorrectionsCount: selfCorrectionsCount,
          evaluatorPassed: true,
          evaluatorConfidence: null,
          evaluatorMode: EvaluatorMode.manualFallback,
          revealedAfterAttempt: false,
          retrievalStrength: 0.0,
          attemptType: 'encode_echo',
          assisted: false,
          autoCheckType: null,
          autoCheckResult: null,
          timeOnVerseMs: updatedVerse.stage2.timeOnVerseMs,
          timeOnChunkMs: runtime.chunkElapsedMs,
          stage2Mode: Stage2Mode.correction,
          stage2Phase: runtime.phase,
        ),
      );
    }

    if (stage4Correction) {
      final effectiveNow = (nowLocal ?? DateTime.now()).toLocal();
      final touched = _touchStage4Clock(
        state: state,
        nowLocal: effectiveNow,
      );
      var runtime = touched.runtime!;
      final verses = [...touched.verses];
      final currentIndex = state.currentVerseIndex;
      final current = verses[currentIndex];
      final updatedVerse = current.copyWith(
        attemptCount: current.attemptCount + 1,
        stage4: current.stage4.copyWith(
          correctionRequired: false,
        ),
      );
      verses[currentIndex] = updatedVerse;

      await _persistAttempt(
        state: state.copyWith(
          verses: verses,
          stage4: runtime,
        ),
        verseIndex: currentIndex,
        verse: updatedVerse,
        stageCode: state.activeStage.code,
        attemptType: 'encode_echo',
        hintLevel: _stage4EffectiveBaselineHint(updatedVerse.stage4),
        assistedFlag: 0,
        evaluatorMode: EvaluatorMode.manualFallback,
        evaluatorPassed: 1,
        evaluatorConfidence: null,
        autoCheckType: null,
        autoCheckResult: null,
        retrievalStrength: 0.0,
        latencyToStartMs: latencyToStartMs,
        stopsCount: stopsCount,
        selfCorrectionsCount: selfCorrectionsCount,
        nowLocal: effectiveNow,
        telemetryExtras: <String, Object?>{
          'lifecycle_stage': 'stage4',
          'stage4_mode': Stage4Mode.correction.code,
          'stage4_phase': runtime.phase.code,
          'stage4_step': 'correction_exposure',
          'correction_exposure': true,
          'stage3_step': 'correction_exposure',
        },
      );

      final nextMode = switch (runtime.phase) {
        Stage4Phase.checkpoint => Stage4Mode.checkpoint,
        Stage4Phase.remediation => Stage4Mode.remediation,
        _ => _stage4ModeForVerse(
            verse: updatedVerse,
            runtime: runtime.copyWith(mode: Stage4Mode.coldStart),
          ),
      };

      runtime = runtime.copyWith(
        mode: nextMode,
        activeAutoCheckPrompt: nextMode == Stage4Mode.correction
            ? null
            : _buildStage4AutoCheckPrompt(
                state: state.copyWith(verses: verses),
                verses: verses,
                verseIndex: currentIndex,
                mode: nextMode,
              ),
      );

      final nextState = state.copyWith(
        verses: verses,
        stage4: runtime,
        currentHintLevel: _stage4EffectiveBaselineHint(updatedVerse.stage4),
      );
      final budgetAdvance = await _maybeAdvanceStage4AfterBudget(
        state: nextState,
        config: config,
        nowLocal: effectiveNow,
      );
      if (budgetAdvance != null) {
        return budgetAdvance;
      }

      return ChainAttemptUpdate(
        state: nextState,
        telemetry: VerseAttemptTelemetry(
          stage: state.activeStage,
          hintLevel: _stage4EffectiveBaselineHint(updatedVerse.stage4),
          latencyToStartMs: latencyToStartMs,
          stopsCount: stopsCount,
          selfCorrectionsCount: selfCorrectionsCount,
          evaluatorPassed: true,
          evaluatorConfidence: null,
          evaluatorMode: EvaluatorMode.manualFallback,
          revealedAfterAttempt: false,
          retrievalStrength: 0.0,
          attemptType: 'encode_echo',
          assisted: false,
          autoCheckType: null,
          autoCheckResult: null,
          timeOnVerseMs: updatedVerse.stage4.timeOnVerseMs,
          timeOnChunkMs: runtime.chunkElapsedMs,
          stage4Mode: Stage4Mode.correction,
          stage4Phase: runtime.phase,
        ),
      );
    }

    if (stage3Correction) {
      final effectiveNow = (nowLocal ?? DateTime.now()).toLocal();
      final touched = _touchStage3Clock(
        state: state,
        nowLocal: effectiveNow,
      );
      var runtime = touched.runtime!;
      final verses = [...touched.verses];
      final currentIndex = state.currentVerseIndex;
      final current = verses[currentIndex];
      final updatedVerse = current.copyWith(
        attemptCount: current.attemptCount + 1,
        stage3: current.stage3.copyWith(
          correctionRequired: false,
        ),
      );
      verses[currentIndex] = updatedVerse;

      await _persistAttempt(
        state: state.copyWith(
          verses: verses,
          stage3: runtime,
        ),
        verseIndex: currentIndex,
        verse: updatedVerse,
        stageCode: state.activeStage.code,
        attemptType: 'encode_echo',
        hintLevel: _stage3EffectiveBaselineHint(
          updatedVerse.stage3,
          capAtH1: state.stage3WeakPreludeTargets.isNotEmpty,
        ),
        assistedFlag: 0,
        evaluatorMode: EvaluatorMode.manualFallback,
        evaluatorPassed: 1,
        evaluatorConfidence: null,
        autoCheckType: null,
        autoCheckResult: null,
        retrievalStrength: 0.0,
        latencyToStartMs: latencyToStartMs,
        stopsCount: stopsCount,
        selfCorrectionsCount: selfCorrectionsCount,
        nowLocal: effectiveNow,
        telemetryExtras: <String, Object?>{
          'stage3_mode': Stage3Mode.correction.code,
          'stage3_phase': runtime.phase.code,
          'stage3_step': 'correction_exposure',
          'correction_exposure': true,
        },
      );

      final nextMode = switch (runtime.phase) {
        Stage3Phase.checkpoint => Stage3Mode.checkpoint,
        Stage3Phase.remediation => Stage3Mode.remediation,
        _ => _stage3ModeForVerse(
            state: state.copyWith(verses: verses, stage3: runtime),
            verse: updatedVerse,
            runtime: runtime.copyWith(mode: Stage3Mode.hiddenRecall),
          ),
      };

      runtime = runtime.copyWith(
        mode: nextMode,
        activeAutoCheckPrompt: nextMode == Stage3Mode.correction
            ? null
            : _buildStage3AutoCheckPrompt(
                state: state.copyWith(verses: verses),
                verses: verses,
                verseIndex: currentIndex,
                mode: nextMode,
              ),
      );

      final nextState = state.copyWith(
        verses: verses,
        stage3: runtime,
        currentHintLevel: _stage3EffectiveBaselineHint(
          updatedVerse.stage3,
          capAtH1: state.stage3WeakPreludeTargets.isNotEmpty,
        ),
      );
      final budgetAdvance = await _maybeAdvanceStage3AfterBudget(
        state: nextState,
        config: config,
        nowLocal: effectiveNow,
      );
      if (budgetAdvance != null) {
        return budgetAdvance;
      }

      return ChainAttemptUpdate(
        state: nextState,
        telemetry: VerseAttemptTelemetry(
          stage: state.activeStage,
          hintLevel: _stage3EffectiveBaselineHint(
            updatedVerse.stage3,
            capAtH1: state.stage3WeakPreludeTargets.isNotEmpty,
          ),
          latencyToStartMs: latencyToStartMs,
          stopsCount: stopsCount,
          selfCorrectionsCount: selfCorrectionsCount,
          evaluatorPassed: true,
          evaluatorConfidence: null,
          evaluatorMode: EvaluatorMode.manualFallback,
          revealedAfterAttempt: false,
          retrievalStrength: 0.0,
          attemptType: 'encode_echo',
          assisted: false,
          autoCheckType: null,
          autoCheckResult: null,
          timeOnVerseMs: updatedVerse.stage3.timeOnVerseMs,
          timeOnChunkMs: runtime.chunkElapsedMs,
          stage3Mode: Stage3Mode.correction,
          stage3Phase: runtime.phase,
        ),
      );
    }

    if (reviewCorrection) {
      return _submitReviewCorrectionExposure(
        state: state,
        latencyToStartMs: latencyToStartMs,
        stopsCount: stopsCount,
        selfCorrectionsCount: selfCorrectionsCount,
        nowLocal: nowLocal,
      );
    }

    final effectiveNow = (nowLocal ?? DateTime.now()).toLocal();
    final touched = _touchStage1Clock(
      state: state,
      nowLocal: effectiveNow,
    );
    var runtime = touched.runtime!;
    final verses = [...touched.verses];
    final currentIndex = state.currentVerseIndex;
    final current = verses[currentIndex];
    final updatedVerse = current.copyWith(
      attemptCount: current.attemptCount + 1,
      stage1: current.stage1.copyWith(
        correctionRequired: false,
        seenModelExposure: true,
        modelEchoExposures: current.stage1.modelEchoExposures + 1,
      ),
    );
    verses[currentIndex] = updatedVerse;

    await _persistAttempt(
      state: state.copyWith(
        verses: verses,
        stage1: runtime,
      ),
      verseIndex: currentIndex,
      verse: updatedVerse,
      stageCode: state.activeStage.code,
      attemptType: 'encode_echo',
      hintLevel: HintLevel.h0,
      assistedFlag: 0,
      evaluatorMode: EvaluatorMode.manualFallback,
      evaluatorPassed: 1,
      evaluatorConfidence: null,
      autoCheckType: null,
      autoCheckResult: null,
      retrievalStrength: 0.0,
      latencyToStartMs: latencyToStartMs,
      stopsCount: stopsCount,
      selfCorrectionsCount: selfCorrectionsCount,
      nowLocal: effectiveNow,
      telemetryExtras: <String, Object?>{
        'stage1_mode': Stage1Mode.correction.code,
        'correction_exposure': true,
      },
    );

    final nextMode = switch (runtime.phase) {
      Stage1Phase.checkpoint => Stage1Mode.checkpoint,
      Stage1Phase.cumulativeCheck => Stage1Mode.cumulativeCheck,
      Stage1Phase.spacedConfirmation => updatedVerse.stage1.hasAnyH0Success &&
              !updatedVerse.stage1.spacedConfirmed
          ? Stage1Mode.spacedReprobe
          : Stage1Mode.coldProbe,
      _ => Stage1Mode.coldProbe,
    };

    runtime = runtime.copyWith(
      mode: nextMode,
      hintsUnlockedForCurrentProbe: true,
      currentProbeAttemptCount: 1,
      activeAutoCheckPrompt: _buildAutoCheckPrompt(
        state: state.copyWith(verses: verses),
        verses: verses,
        verseIndex: currentIndex,
        runtime: runtime,
        mode: nextMode,
      ),
    );

    return ChainAttemptUpdate(
      state: state.copyWith(
        verses: verses,
        stage1: runtime,
        currentHintLevel: HintLevel.h0,
      ),
      telemetry: VerseAttemptTelemetry(
        stage: state.activeStage,
        hintLevel: HintLevel.h0,
        latencyToStartMs: latencyToStartMs,
        stopsCount: stopsCount,
        selfCorrectionsCount: selfCorrectionsCount,
        evaluatorPassed: true,
        evaluatorConfidence: null,
        evaluatorMode: EvaluatorMode.manualFallback,
        revealedAfterAttempt: false,
        retrievalStrength: 0.0,
        attemptType: 'encode_echo',
        assisted: false,
        autoCheckType: null,
        autoCheckResult: null,
        timeOnVerseMs: updatedVerse.stage1.timeOnVerseMs,
        timeOnChunkMs: runtime.chunkElapsedMs,
        stage1Mode: Stage1Mode.correction,
      ),
    );
  }

  Future<ChainAttemptUpdate> submitAttempt({
    required ChainRunState state,
    required VerseEvaluator evaluator,
    required bool manualFallbackPass,
    String? selectedAutoCheckOptionId,
    double? asrConfidence,
    int latencyToStartMs = 0,
    int stopsCount = 0,
    int selfCorrectionsCount = 0,
    int audioPlays = 0,
    int loopCount = 0,
    double playbackSpeed = 1.0,
    ProgressiveRevealChainConfig config = const ProgressiveRevealChainConfig(),
    DateTime? nowLocal,
  }) async {
    if (state.completed) {
      throw StateError('Cannot submit attempts for completed chain session.');
    }

    if (state.activeStage == CompanionStage.guidedVisible &&
        state.stage1 != null &&
        !state.isReviewMode) {
      return _submitStage1Attempt(
        state: state,
        evaluator: evaluator,
        manualFallbackPass: manualFallbackPass,
        selectedAutoCheckOptionId: selectedAutoCheckOptionId,
        asrConfidence: asrConfidence,
        latencyToStartMs: latencyToStartMs,
        stopsCount: stopsCount,
        selfCorrectionsCount: selfCorrectionsCount,
        audioPlays: audioPlays,
        loopCount: loopCount,
        playbackSpeed: playbackSpeed,
        config: config,
        nowLocal: nowLocal,
      );
    }

    if (state.activeStage == CompanionStage.cuedRecall &&
        state.stage2 != null &&
        !state.isReviewMode) {
      return _submitStage2Attempt(
        state: state,
        evaluator: evaluator,
        manualFallbackPass: manualFallbackPass,
        selectedAutoCheckOptionId: selectedAutoCheckOptionId,
        asrConfidence: asrConfidence,
        latencyToStartMs: latencyToStartMs,
        stopsCount: stopsCount,
        selfCorrectionsCount: selfCorrectionsCount,
        audioPlays: audioPlays,
        loopCount: loopCount,
        playbackSpeed: playbackSpeed,
        config: config,
        nowLocal: nowLocal,
      );
    }

    if (state.activeStage == CompanionStage.hiddenReveal &&
        state.stage4 != null &&
        !state.isReviewMode) {
      return _submitStage4Attempt(
        state: state,
        evaluator: evaluator,
        manualFallbackPass: manualFallbackPass,
        selectedAutoCheckOptionId: selectedAutoCheckOptionId,
        asrConfidence: asrConfidence,
        latencyToStartMs: latencyToStartMs,
        stopsCount: stopsCount,
        selfCorrectionsCount: selfCorrectionsCount,
        audioPlays: audioPlays,
        loopCount: loopCount,
        playbackSpeed: playbackSpeed,
        config: config,
        nowLocal: nowLocal,
      );
    }

    if (state.activeStage == CompanionStage.hiddenReveal &&
        state.review != null &&
        state.isReviewMode) {
      return _submitReviewAttempt(
        state: state,
        evaluator: evaluator,
        manualFallbackPass: manualFallbackPass,
        selectedAutoCheckOptionId: selectedAutoCheckOptionId,
        asrConfidence: asrConfidence,
        latencyToStartMs: latencyToStartMs,
        stopsCount: stopsCount,
        selfCorrectionsCount: selfCorrectionsCount,
        audioPlays: audioPlays,
        loopCount: loopCount,
        playbackSpeed: playbackSpeed,
        config: config,
        nowLocal: nowLocal,
      );
    }

    if (state.activeStage == CompanionStage.hiddenReveal &&
        state.stage3 != null &&
        !state.isReviewMode) {
      return _submitStage3Attempt(
        state: state,
        evaluator: evaluator,
        manualFallbackPass: manualFallbackPass,
        selectedAutoCheckOptionId: selectedAutoCheckOptionId,
        asrConfidence: asrConfidence,
        latencyToStartMs: latencyToStartMs,
        stopsCount: stopsCount,
        selfCorrectionsCount: selfCorrectionsCount,
        audioPlays: audioPlays,
        loopCount: loopCount,
        playbackSpeed: playbackSpeed,
        config: config,
        nowLocal: nowLocal,
      );
    }

    throw StateError('No active runtime is available for this chain session.');
  }

  Future<ChainAttemptUpdate> _submitStage1Attempt({
    required ChainRunState state,
    required VerseEvaluator evaluator,
    required bool manualFallbackPass,
    required String? selectedAutoCheckOptionId,
    required double? asrConfidence,
    required int latencyToStartMs,
    required int stopsCount,
    required int selfCorrectionsCount,
    required int audioPlays,
    required int loopCount,
    required double playbackSpeed,
    required ProgressiveRevealChainConfig config,
    required DateTime? nowLocal,
  }) async {
    final effectiveNow = (nowLocal ?? DateTime.now()).toLocal();
    final touched = _touchStage1Clock(
      state: state,
      nowLocal: effectiveNow,
    );
    var runtime = touched.runtime!;
    var verses = [...touched.verses];
    final currentIndex = state.currentVerseIndex;
    final currentVerse = verses[currentIndex];

    if (runtime.mode == Stage1Mode.correction ||
        currentVerse.stage1.correctionRequired) {
      throw StateError(
          'Correction playback is required before next cold attempt.');
    }

    if (runtime.mode == Stage1Mode.modelEcho) {
      final nextVerse = currentVerse.copyWith(
        attemptCount: currentVerse.attemptCount + 1,
        stage1: currentVerse.stage1.copyWith(
          modelEchoLoops: currentVerse.stage1.modelEchoLoops + 1,
          modelEchoExposures: currentVerse.stage1.modelEchoExposures + 1,
          seenModelExposure: true,
        ),
      );
      verses[currentIndex] = nextVerse;

      await _persistAttempt(
        state: state.copyWith(verses: verses, stage1: runtime),
        verseIndex: currentIndex,
        verse: nextVerse,
        stageCode: state.activeStage.code,
        attemptType: 'encode_echo',
        hintLevel: HintLevel.h0,
        assistedFlag: 0,
        evaluatorMode: EvaluatorMode.manualFallback,
        evaluatorPassed: 1,
        evaluatorConfidence: asrConfidence,
        autoCheckType: null,
        autoCheckResult: null,
        retrievalStrength: 0.0,
        latencyToStartMs: latencyToStartMs,
        stopsCount: stopsCount,
        selfCorrectionsCount: selfCorrectionsCount,
        nowLocal: effectiveNow,
        telemetryExtras: <String, Object?>{
          'stage1_mode': Stage1Mode.modelEcho.code,
          'audio_plays': audioPlays,
          'loop_count': loopCount,
          'speed': playbackSpeed,
        },
      );

      final shouldProbe = runtime.phase == Stage1Phase.remediation ||
          nextVerse.stage1.modelEchoLoops >= runtime.adaptiveEchoLoopCap ||
          nextVerse.stage1.timeOnVerseMs >= runtime.perVerseCapMs;
      final nextMode = shouldProbe
          ? (nextVerse.stage1.hasAnyH0Success &&
                  !nextVerse.stage1.spacedConfirmed
              ? Stage1Mode.spacedReprobe
              : Stage1Mode.coldProbe)
          : Stage1Mode.modelEcho;
      runtime = runtime.copyWith(
        mode: nextMode,
        activeAutoCheckPrompt: shouldProbe
            ? _buildAutoCheckPrompt(
                state: state.copyWith(verses: verses),
                verses: verses,
                verseIndex: currentIndex,
                runtime: runtime,
                mode: nextMode,
              )
            : null,
        hintsUnlockedForCurrentProbe: false,
        currentProbeAttemptCount: 0,
      );

      final budgetAdvance = await _maybeAdvanceStage1AfterBudget(
        state: state.copyWith(
          verses: verses,
          stage1: runtime,
          currentHintLevel: HintLevel.h0,
        ),
        config: config,
        nowLocal: effectiveNow,
      );
      if (budgetAdvance != null) {
        return budgetAdvance;
      }

      return ChainAttemptUpdate(
        state: state.copyWith(
          verses: verses,
          stage1: runtime,
          currentHintLevel: HintLevel.h0,
        ),
        telemetry: VerseAttemptTelemetry(
          stage: state.activeStage,
          hintLevel: HintLevel.h0,
          latencyToStartMs: latencyToStartMs,
          stopsCount: stopsCount,
          selfCorrectionsCount: selfCorrectionsCount,
          evaluatorPassed: true,
          evaluatorConfidence: asrConfidence,
          evaluatorMode: EvaluatorMode.manualFallback,
          revealedAfterAttempt: false,
          retrievalStrength: 0.0,
          attemptType: 'encode_echo',
          assisted: false,
          timeOnVerseMs: nextVerse.stage1.timeOnVerseMs,
          timeOnChunkMs: runtime.chunkElapsedMs,
          stage1Mode: Stage1Mode.modelEcho,
        ),
      );
    }

    final evaluation = await evaluator.evaluate(
      VerseEvaluationRequest(
        verse: currentVerse.verse,
        manualFallbackPass: manualFallbackPass,
        asrConfidence: asrConfidence,
      ),
    );
    final attemptMode = runtime.mode;
    final attemptType = _attemptTypeForStage1Mode(attemptMode);
    final autoCheckRequired = runtime.autoCheckRequiredForCurrentMode;
    final autoPrompt = runtime.activeAutoCheckPrompt ??
        _buildAutoCheckPrompt(
          state: state.copyWith(verses: verses),
          verses: verses,
          verseIndex: currentIndex,
          runtime: runtime,
          mode: attemptMode,
        );
    if (autoCheckRequired &&
        (selectedAutoCheckOptionId == null ||
            selectedAutoCheckOptionId.trim().isEmpty)) {
      throw StateError(
          'Auto-check option is required for Stage-1 cold attempts.');
    }
    final autoEval = autoCheckRequired
        ? _autoCheckEngine.evaluate(
            prompt: autoPrompt,
            selectedOptionId: selectedAutoCheckOptionId,
          )
        : const Stage1AutoCheckEvaluation(
            passed: true,
            selectedOptionId: null,
            normalizedSelected: '',
          );

    final passed = evaluation.passed && autoEval.passed;
    final assisted = state.currentHintLevel != HintLevel.h0;
    final h0UnassistedPass =
        passed && !assisted && state.currentHintLevel == HintLevel.h0;
    var stats = currentVerse.stage1;

    var spacedConfirmed = stats.spacedConfirmed;
    var spacedH0 = stats.spacedH0Successes;
    var lastH0SuccessAtMs = stats.lastH0SuccessAtMs;
    var firstH0SuccessAtMs = stats.firstColdSuccessAtMs;
    if (h0UnassistedPass) {
      firstH0SuccessAtMs ??= runtime.lastActionAtEpochMs;
      if (lastH0SuccessAtMs != null &&
          runtime.lastActionAtEpochMs - lastH0SuccessAtMs >=
              runtime.adaptiveSpacingMs) {
        spacedConfirmed = true;
        spacedH0 += 1;
      }
      lastH0SuccessAtMs = runtime.lastActionAtEpochMs;
    }

    final coldWindow = <Stage1ColdWindowEntry>[
      ...stats.coldWindow,
      Stage1ColdWindowEntry(
        timestampMs: runtime.lastActionAtEpochMs,
        passed: passed,
        hintLevel: state.currentHintLevel,
        assisted: assisted,
      ),
    ];
    final cappedColdWindow = coldWindow.length <= runtime.config.coldWindowSize
        ? coldWindow
        : coldWindow.sublist(
            coldWindow.length - runtime.config.coldWindowSize,
          );
    stats = stats.copyWith(
      modelEchoLoops: 0,
      coldAttempts: stats.coldAttempts + 1,
      h0Successes: h0UnassistedPass ? stats.h0Successes + 1 : stats.h0Successes,
      assistedSuccesses: passed && assisted
          ? stats.assistedSuccesses + 1
          : stats.assistedSuccesses,
      spacedConfirmed: spacedConfirmed,
      spacedH0Successes: spacedH0,
      firstColdSuccessAtMs: firstH0SuccessAtMs,
      lastH0SuccessAtMs: lastH0SuccessAtMs,
      correctionRequired: !passed,
      weak: stats.weak || (!passed && stats.coldAttempts >= 1),
      checkpointAttempted: runtime.mode == Stage1Mode.checkpoint
          ? true
          : stats.checkpointAttempted,
      checkpointPassed: runtime.mode == Stage1Mode.checkpoint
          ? h0UnassistedPass
          : stats.checkpointPassed,
      checkpointAttempts: runtime.mode == Stage1Mode.checkpoint
          ? stats.checkpointAttempts + 1
          : stats.checkpointAttempts,
      cumulativeAttempted: runtime.mode == Stage1Mode.cumulativeCheck
          ? true
          : stats.cumulativeAttempted,
      cumulativePassed: runtime.mode == Stage1Mode.cumulativeCheck
          ? h0UnassistedPass
          : stats.cumulativePassed,
      coldWindow: cappedColdWindow,
    );
    final retrievalStrength = computeRetrievalStrength(
      passed: passed,
      hintLevel: state.currentHintLevel,
      latencyToStartMs: latencyToStartMs,
      stopsCount: stopsCount,
      selfCorrectionsCount: selfCorrectionsCount,
      confidence: evaluation.confidence,
    );
    final updatedVerse = currentVerse.copyWith(
      attemptCount: currentVerse.attemptCount + 1,
      stage1: stats,
      highestHintLevel:
          state.currentHintLevel.order > currentVerse.highestHintLevel.order
              ? state.currentHintLevel
              : currentVerse.highestHintLevel,
      proficiency: _nextProficiency(
        oldValue: currentVerse.proficiency,
        observedValue: retrievalStrength,
        alpha: config.proficiencyEmaAlpha,
      ),
    );
    verses[currentIndex] = updatedVerse;

    await _persistAttempt(
      state: state.copyWith(verses: verses, stage1: runtime),
      verseIndex: currentIndex,
      verse: updatedVerse,
      stageCode: state.activeStage.code,
      attemptType: attemptType,
      hintLevel: state.currentHintLevel,
      assistedFlag: assisted ? 1 : 0,
      evaluatorMode: evaluation.mode,
      evaluatorPassed: passed ? 1 : 0,
      evaluatorConfidence: evaluation.confidence,
      autoCheckType: autoCheckRequired ? autoPrompt.type.code : null,
      autoCheckResult:
          autoCheckRequired ? (autoEval.passed ? 'pass' : 'fail') : null,
      retrievalStrength: retrievalStrength,
      latencyToStartMs: latencyToStartMs,
      stopsCount: stopsCount,
      selfCorrectionsCount: selfCorrectionsCount,
      nowLocal: effectiveNow,
      telemetryExtras: <String, Object?>{
        'stage1_mode': runtime.mode.code,
        'manual_pass': evaluation.passed,
        'auto_pass': autoEval.passed,
        'h0_unassisted_pass': h0UnassistedPass,
      },
    );
    await _upsertProficiency(
      state: state,
      verse: updatedVerse,
      hintLevel: state.currentHintLevel,
      retrievalStrength: retrievalStrength,
      evaluatorConfidence: evaluation.confidence,
      latencyToStartMs: latencyToStartMs,
      evaluatorPassed: passed,
      nowLocal: effectiveNow,
    );

    runtime = _retuneStage1Runtime(
      runtime.copyWith(
        totalRetrievalAttempts: runtime.totalRetrievalAttempts + 1,
        totalRetrievalPasses:
            runtime.totalRetrievalPasses + (h0UnassistedPass ? 1 : 0),
        currentProbeAttemptCount: runtime.currentProbeAttemptCount + 1,
        hintsUnlockedForCurrentProbe: true,
      ),
    );
    if (!passed) {
      runtime = runtime.copyWith(
        mode: Stage1Mode.correction,
        activeAutoCheckPrompt: null,
      );
      final budgetAdvance = await _maybeAdvanceStage1AfterBudget(
        state: state.copyWith(
          verses: verses,
          stage1: runtime,
          currentHintLevel: HintLevel.h0,
        ),
        config: config,
        nowLocal: effectiveNow,
      );
      if (budgetAdvance != null) {
        return budgetAdvance;
      }
      return ChainAttemptUpdate(
        state: state.copyWith(
          verses: verses,
          stage1: runtime,
          currentHintLevel: HintLevel.h0,
        ),
        telemetry: VerseAttemptTelemetry(
          stage: state.activeStage,
          hintLevel: state.currentHintLevel,
          latencyToStartMs: latencyToStartMs,
          stopsCount: stopsCount,
          selfCorrectionsCount: selfCorrectionsCount,
          evaluatorPassed: false,
          evaluatorConfidence: evaluation.confidence,
          evaluatorMode: evaluation.mode,
          revealedAfterAttempt: false,
          retrievalStrength: retrievalStrength,
          attemptType: attemptType,
          assisted: assisted,
          autoCheckType: autoCheckRequired ? autoPrompt.type.code : null,
          autoCheckResult:
              autoCheckRequired ? (autoEval.passed ? 'pass' : 'fail') : null,
          timeOnVerseMs: updatedVerse.stage1.timeOnVerseMs,
          timeOnChunkMs: runtime.chunkElapsedMs,
          stage1Mode: attemptMode,
          correctionRequiredAfterAttempt: true,
        ),
      );
    }

    final afterPass = await _advanceStage1AfterPass(
      state: state.copyWith(
        verses: verses,
        stage1: runtime,
        currentHintLevel: HintLevel.h0,
      ),
      passedVerseIndex: currentIndex,
      h0UnassistedPass: h0UnassistedPass,
      config: config,
      nowLocal: effectiveNow,
    );
    final budgetAdvance = await _maybeAdvanceStage1AfterBudget(
      state: afterPass,
      config: config,
      nowLocal: effectiveNow,
    );
    if (budgetAdvance != null) {
      return budgetAdvance;
    }

    return ChainAttemptUpdate(
      state: afterPass,
      telemetry: VerseAttemptTelemetry(
        stage: state.activeStage,
        hintLevel: state.currentHintLevel,
        latencyToStartMs: latencyToStartMs,
        stopsCount: stopsCount,
        selfCorrectionsCount: selfCorrectionsCount,
        evaluatorPassed: true,
        evaluatorConfidence: evaluation.confidence,
        evaluatorMode: evaluation.mode,
        revealedAfterAttempt: false,
        retrievalStrength: retrievalStrength,
        attemptType: attemptType,
        assisted: assisted,
        autoCheckType: autoCheckRequired ? autoPrompt.type.code : null,
        autoCheckResult:
            autoCheckRequired ? (autoEval.passed ? 'pass' : 'fail') : null,
        timeOnVerseMs: updatedVerse.stage1.timeOnVerseMs,
        timeOnChunkMs:
            afterPass.stage1?.chunkElapsedMs ?? runtime.chunkElapsedMs,
        stage1Mode: attemptMode,
      ),
    );
  }

  Future<ChainAttemptUpdate> _submitStage2Attempt({
    required ChainRunState state,
    required VerseEvaluator evaluator,
    required bool manualFallbackPass,
    required String? selectedAutoCheckOptionId,
    required double? asrConfidence,
    required int latencyToStartMs,
    required int stopsCount,
    required int selfCorrectionsCount,
    required int audioPlays,
    required int loopCount,
    required double playbackSpeed,
    required ProgressiveRevealChainConfig config,
    required DateTime? nowLocal,
  }) async {
    final effectiveNow = (nowLocal ?? DateTime.now()).toLocal();
    final touched = _touchStage2Clock(
      state: state,
      nowLocal: effectiveNow,
    );
    var runtime = touched.runtime!;
    var verses = [...touched.verses];
    final currentIndex = state.currentVerseIndex;
    final currentVerse = verses[currentIndex];

    if (runtime.mode == Stage2Mode.correction ||
        currentVerse.stage2.correctionRequired) {
      throw StateError(
          'Correction playback is required before next Stage-2 attempt.');
    }

    final evaluation = await evaluator.evaluate(
      VerseEvaluationRequest(
        verse: currentVerse.verse,
        manualFallbackPass: manualFallbackPass,
        asrConfidence: asrConfidence,
      ),
    );

    final attemptMode = runtime.mode;
    final attemptType = _attemptTypeForStage2Mode(attemptMode);
    final baselineHint = _stage2EffectiveBaselineHint(currentVerse.stage2);
    final effectiveHintLevel = state.currentHintLevel.order < baselineHint.order
        ? baselineHint
        : state.currentHintLevel;
    final assisted = effectiveHintLevel.order > baselineHint.order;
    final autoCheckRequired = runtime.autoCheckRequiredForCurrentMode;
    final autoPrompt = runtime.activeAutoCheckPrompt ??
        _buildStage2AutoCheckPrompt(
          state: state.copyWith(verses: verses),
          verses: verses,
          verseIndex: currentIndex,
          mode: attemptMode,
        );

    if (autoCheckRequired &&
        (selectedAutoCheckOptionId == null ||
            selectedAutoCheckOptionId.trim().isEmpty)) {
      throw StateError('Auto-check option is required for Stage-2 attempts.');
    }

    final autoEval = autoCheckRequired
        ? _autoCheckEngine.evaluate(
            prompt: autoPrompt,
            selectedOptionId: selectedAutoCheckOptionId,
          )
        : const Stage1AutoCheckEvaluation(
            passed: true,
            selectedOptionId: null,
            normalizedSelected: '',
          );

    final passed = evaluation.passed && autoEval.passed;
    final countableAttempt = !assisted &&
        effectiveHintLevel.order <= runtime.config.readinessMaxHint.order;
    final countedPass = passed && countableAttempt;
    final riskTrigger = _stage2RiskTrigger(
      verse: currentVerse,
      config: runtime.config,
    );

    var stage2 = currentVerse.stage2;
    final usedRelief = stage2.reliefPending;
    final nextConsecutiveFailures = passed ? 0 : stage2.consecutiveFailures + 1;
    final nextReliefPending = !passed &&
        !usedRelief &&
        nextConsecutiveFailures >= runtime.config.discriminationFailureTrigger;
    var rotatedFrom = stage2.lastCueRotatedFrom;
    var nextBaseline = stage2.cueBaselineHint;
    if (countedPass) {
      rotatedFrom = stage2.cueBaselineHint;
      nextBaseline = _harderHint(stage2.cueBaselineHint);
    }

    var readinessWindow = stage2.readinessWindow;
    if (countableAttempt) {
      readinessWindow = <Stage2WindowEntry>[
        ...readinessWindow,
        Stage2WindowEntry(
          timestampMs: runtime.lastActionAtEpochMs,
          passed: passed,
          countedPass: countedPass,
          hintLevel: effectiveHintLevel,
          assisted: assisted,
        ),
      ];
      if (readinessWindow.length > runtime.config.readinessWindow) {
        readinessWindow = readinessWindow.sublist(
          readinessWindow.length - runtime.config.readinessWindow,
        );
      }
    }

    stage2 = stage2.copyWith(
      attempts: stage2.attempts + 1,
      countedAttempts: stage2.countedAttempts + (countableAttempt ? 1 : 0),
      countedPasses: stage2.countedPasses + (countedPass ? 1 : 0),
      consecutiveFailures: nextConsecutiveFailures,
      correctionRequired: !passed,
      reliefPending: nextReliefPending,
      weakTarget: stage2.weakTarget || currentVerse.stage1.weak || !countedPass,
      remediationNeeded: stage2.remediationNeeded ||
          (runtime.phase == Stage2Phase.checkpoint && !countedPass),
      discriminationAttempts: stage2.discriminationAttempts +
          (attemptMode == Stage2Mode.discrimination ? 1 : 0),
      discriminationPasses: stage2.discriminationPasses +
          (attemptMode == Stage2Mode.discrimination && countedPass ? 1 : 0),
      linkingAttempts:
          stage2.linkingAttempts + (attemptMode == Stage2Mode.linking ? 1 : 0),
      linkingPassCount: stage2.linkingPassCount +
          (attemptMode == Stage2Mode.linking && countedPass ? 1 : 0),
      checkpointAttempted: attemptMode == Stage2Mode.checkpoint
          ? true
          : stage2.checkpointAttempted,
      checkpointPassed: attemptMode == Stage2Mode.checkpoint
          ? countedPass
          : stage2.checkpointPassed,
      checkpointAttempts: attemptMode == Stage2Mode.checkpoint
          ? stage2.checkpointAttempts + 1
          : stage2.checkpointAttempts,
      cueBaselineHint: nextBaseline,
      lastCueRotatedFrom: countedPass ? rotatedFrom : stage2.lastCueRotatedFrom,
      readinessWindow: readinessWindow,
    );

    final retrievalStrength = computeRetrievalStrength(
      passed: passed,
      hintLevel: effectiveHintLevel,
      latencyToStartMs: latencyToStartMs,
      stopsCount: stopsCount,
      selfCorrectionsCount: selfCorrectionsCount,
      confidence: evaluation.confidence,
    );
    final updatedVerse = currentVerse.copyWith(
      attemptCount: currentVerse.attemptCount + 1,
      stage2: stage2,
      highestHintLevel:
          effectiveHintLevel.order > currentVerse.highestHintLevel.order
              ? effectiveHintLevel
              : currentVerse.highestHintLevel,
      proficiency: _nextProficiency(
        oldValue: currentVerse.proficiency,
        observedValue: retrievalStrength,
        alpha: config.proficiencyEmaAlpha,
      ),
    );
    verses[currentIndex] = updatedVerse;

    await _persistAttempt(
      state: state.copyWith(verses: verses, stage2: runtime),
      verseIndex: currentIndex,
      verse: updatedVerse,
      stageCode: state.activeStage.code,
      attemptType: attemptType,
      hintLevel: effectiveHintLevel,
      assistedFlag: assisted ? 1 : 0,
      evaluatorMode: evaluation.mode,
      evaluatorPassed: passed ? 1 : 0,
      evaluatorConfidence: evaluation.confidence,
      autoCheckType: autoCheckRequired ? autoPrompt.type.code : null,
      autoCheckResult:
          autoCheckRequired ? (autoEval.passed ? 'pass' : 'fail') : null,
      retrievalStrength: retrievalStrength,
      latencyToStartMs: latencyToStartMs,
      stopsCount: stopsCount,
      selfCorrectionsCount: selfCorrectionsCount,
      nowLocal: effectiveNow,
      telemetryExtras: <String, Object?>{
        'stage2_mode': attemptMode.code,
        'stage2_phase': runtime.phase.code,
        'stage2_step': _stage2TelemetryStep(attemptMode),
        'cue_baseline': baselineHint.code,
        'cue_rotated_from': countedPass ? rotatedFrom?.code : null,
        'weak_target': updatedVerse.stage2.weakTarget,
        'risk_trigger': riskTrigger,
        'link_prev_verse_order': currentIndex > 0 ? currentIndex - 1 : 0,
        'readiness_counted_pass': countedPass,
        'audio_plays': audioPlays,
        'loop_count': loopCount,
        'speed': playbackSpeed,
        if (_stage2IsReady(updatedVerse, runtime.config))
          'lifecycle_hook': 'stage4_candidate',
      },
    );
    await _upsertProficiency(
      state: state,
      verse: updatedVerse,
      hintLevel: effectiveHintLevel,
      retrievalStrength: retrievalStrength,
      evaluatorConfidence: evaluation.confidence,
      latencyToStartMs: latencyToStartMs,
      evaluatorPassed: passed,
      nowLocal: effectiveNow,
    );

    if (!passed) {
      runtime = runtime.copyWith(
        mode: Stage2Mode.correction,
        activeAutoCheckPrompt: null,
      );
      final failedState = state.copyWith(
        verses: verses,
        stage2: runtime,
        currentHintLevel: _stage2EffectiveBaselineHint(updatedVerse.stage2),
      );
      final budgetAdvance = await _maybeAdvanceStage2AfterBudget(
        state: failedState,
        config: config,
        nowLocal: effectiveNow,
      );
      if (budgetAdvance != null) {
        return budgetAdvance;
      }
      return ChainAttemptUpdate(
        state: failedState,
        telemetry: VerseAttemptTelemetry(
          stage: state.activeStage,
          hintLevel: effectiveHintLevel,
          latencyToStartMs: latencyToStartMs,
          stopsCount: stopsCount,
          selfCorrectionsCount: selfCorrectionsCount,
          evaluatorPassed: false,
          evaluatorConfidence: evaluation.confidence,
          evaluatorMode: evaluation.mode,
          revealedAfterAttempt: false,
          retrievalStrength: retrievalStrength,
          attemptType: attemptType,
          assisted: assisted,
          autoCheckType: autoCheckRequired ? autoPrompt.type.code : null,
          autoCheckResult:
              autoCheckRequired ? (autoEval.passed ? 'pass' : 'fail') : null,
          timeOnVerseMs: updatedVerse.stage2.timeOnVerseMs,
          timeOnChunkMs: runtime.chunkElapsedMs,
          stage2Mode: attemptMode,
          stage2Phase: runtime.phase,
          correctionRequiredAfterAttempt: true,
        ),
      );
    }

    final advanced = await _advanceStage2AfterPass(
      state: state.copyWith(
        verses: verses,
        stage2: runtime,
        currentHintLevel: _stage2EffectiveBaselineHint(updatedVerse.stage2),
      ),
      passedVerseIndex: currentIndex,
      countedPass: countedPass,
      config: config,
      nowLocal: effectiveNow,
    );
    final budgetAdvance = await _maybeAdvanceStage2AfterBudget(
      state: advanced,
      config: config,
      nowLocal: effectiveNow,
    );
    if (budgetAdvance != null) {
      return budgetAdvance;
    }

    return ChainAttemptUpdate(
      state: advanced,
      telemetry: VerseAttemptTelemetry(
        stage: state.activeStage,
        hintLevel: effectiveHintLevel,
        latencyToStartMs: latencyToStartMs,
        stopsCount: stopsCount,
        selfCorrectionsCount: selfCorrectionsCount,
        evaluatorPassed: true,
        evaluatorConfidence: evaluation.confidence,
        evaluatorMode: evaluation.mode,
        revealedAfterAttempt: false,
        retrievalStrength: retrievalStrength,
        attemptType: attemptType,
        assisted: assisted,
        autoCheckType: autoCheckRequired ? autoPrompt.type.code : null,
        autoCheckResult:
            autoCheckRequired ? (autoEval.passed ? 'pass' : 'fail') : null,
        timeOnVerseMs: updatedVerse.stage2.timeOnVerseMs,
        timeOnChunkMs:
            advanced.stage2?.chunkElapsedMs ?? runtime.chunkElapsedMs,
        stage2Mode: attemptMode,
        stage2Phase: advanced.stage2?.phase ?? runtime.phase,
      ),
    );
  }

  Future<ChainAttemptUpdate> _submitStage3Attempt({
    required ChainRunState state,
    required VerseEvaluator evaluator,
    required bool manualFallbackPass,
    required String? selectedAutoCheckOptionId,
    required double? asrConfidence,
    required int latencyToStartMs,
    required int stopsCount,
    required int selfCorrectionsCount,
    required int audioPlays,
    required int loopCount,
    required double playbackSpeed,
    required ProgressiveRevealChainConfig config,
    required DateTime? nowLocal,
  }) async {
    final effectiveNow = (nowLocal ?? DateTime.now()).toLocal();
    final touched = _touchStage3Clock(
      state: state,
      nowLocal: effectiveNow,
    );
    var runtime = touched.runtime!;
    var verses = [...touched.verses];
    final currentIndex = state.currentVerseIndex;
    final currentVerse = verses[currentIndex];

    if (runtime.mode == Stage3Mode.correction ||
        currentVerse.stage3.correctionRequired) {
      throw StateError(
          'Correction playback is required before next Stage-3 attempt.');
    }

    final evaluation = await evaluator.evaluate(
      VerseEvaluationRequest(
        verse: currentVerse.verse,
        manualFallbackPass: manualFallbackPass,
        asrConfidence: asrConfidence,
      ),
    );

    final attemptMode = runtime.mode;
    final attemptType = _attemptTypeForStage3Mode(attemptMode);
    final weakPreludeActive = state.stage3WeakPreludeTargets.isNotEmpty;
    final baselineHint = _stage3EffectiveBaselineHint(
      currentVerse.stage3,
      capAtH1: weakPreludeActive,
    );
    var effectiveHintLevel = state.currentHintLevel.order < baselineHint.order
        ? baselineHint
        : state.currentHintLevel;
    if (weakPreludeActive &&
        effectiveHintLevel.order > HintLevel.letters.order) {
      effectiveHintLevel = HintLevel.letters;
    }
    final assisted = effectiveHintLevel.order > baselineHint.order;
    final autoCheckRequired = runtime.autoCheckRequiredForCurrentMode;
    final autoPrompt = runtime.activeAutoCheckPrompt ??
        _buildStage3AutoCheckPrompt(
          state: state.copyWith(verses: verses),
          verses: verses,
          verseIndex: currentIndex,
          mode: attemptMode,
        );

    if (autoCheckRequired &&
        (selectedAutoCheckOptionId == null ||
            selectedAutoCheckOptionId.trim().isEmpty)) {
      throw StateError('Auto-check option is required for Stage-3 attempts.');
    }

    final autoEval = autoCheckRequired
        ? _autoCheckEngine.evaluate(
            prompt: autoPrompt,
            selectedOptionId: selectedAutoCheckOptionId,
          )
        : const Stage1AutoCheckEvaluation(
            passed: true,
            selectedOptionId: null,
            normalizedSelected: '',
          );

    final passed = evaluation.passed && autoEval.passed;
    final countableAttempt = !assisted &&
        effectiveHintLevel.order <= runtime.config.readinessMaxHint.order;
    final countedPass = passed && countableAttempt;
    final countedH0Pass = countedPass && effectiveHintLevel == HintLevel.h0;
    final riskTrigger = _stage3RiskTrigger(
      verse: currentVerse,
      config: runtime.config,
      weakPreludeActive: weakPreludeActive,
    );

    var stage3 = currentVerse.stage3;
    final usedRelief = stage3.reliefPending;
    final nextConsecutiveFailures = passed ? 0 : stage3.consecutiveFailures + 1;
    final nextReliefPending = !passed &&
        !usedRelief &&
        nextConsecutiveFailures >= runtime.config.discriminationFailureTrigger;
    var rotatedFrom = stage3.lastCueRotatedFrom;
    var nextBaseline = stage3.cueBaselineHint;
    if (countedPass) {
      rotatedFrom = stage3.cueBaselineHint;
      nextBaseline = _harderHint(stage3.cueBaselineHint);
    }
    if (nextBaseline.order > HintLevel.letters.order) {
      nextBaseline = HintLevel.letters;
    }

    var lastH0SuccessAtMs = stage3.lastH0SuccessAtMs;
    var spacedH0Confirmed = stage3.spacedH0Confirmed;
    if (countedH0Pass) {
      if (lastH0SuccessAtMs != null &&
          runtime.lastActionAtEpochMs - lastH0SuccessAtMs >=
              runtime.config.minSpacingMs) {
        spacedH0Confirmed = true;
      }
      lastH0SuccessAtMs = runtime.lastActionAtEpochMs;
    }

    var readinessWindow = stage3.readinessWindow;
    if (countableAttempt) {
      readinessWindow = <Stage3WindowEntry>[
        ...readinessWindow,
        Stage3WindowEntry(
          timestampMs: runtime.lastActionAtEpochMs,
          passed: passed,
          countedPass: countedPass,
          hintLevel: effectiveHintLevel,
          assisted: assisted,
        ),
      ];
      if (readinessWindow.length > runtime.config.readinessWindow) {
        readinessWindow = readinessWindow.sublist(
          readinessWindow.length - runtime.config.readinessWindow,
        );
      }
    }

    stage3 = stage3.copyWith(
      attempts: stage3.attempts + 1,
      countedAttempts: stage3.countedAttempts + (countableAttempt ? 1 : 0),
      countedPasses: stage3.countedPasses + (countedPass ? 1 : 0),
      countedH0Passes: stage3.countedH0Passes + (countedH0Pass ? 1 : 0),
      consecutiveFailures: nextConsecutiveFailures,
      correctionRequired: !passed,
      reliefPending: nextReliefPending,
      weakTarget: stage3.weakTarget ||
          currentVerse.stage1.weak ||
          currentVerse.stage2.weakTarget ||
          !countedPass,
      remediationNeeded: stage3.remediationNeeded ||
          (runtime.phase == Stage3Phase.checkpoint && !countedPass),
      discriminationAttempts: stage3.discriminationAttempts +
          (attemptMode == Stage3Mode.discrimination ? 1 : 0),
      discriminationPasses: stage3.discriminationPasses +
          (attemptMode == Stage3Mode.discrimination && countedPass ? 1 : 0),
      linkingAttempts:
          stage3.linkingAttempts + (attemptMode == Stage3Mode.linking ? 1 : 0),
      linkingPassCount: stage3.linkingPassCount +
          (attemptMode == Stage3Mode.linking && countedPass ? 1 : 0),
      checkpointAttempted: attemptMode == Stage3Mode.checkpoint
          ? true
          : stage3.checkpointAttempted,
      checkpointPassed: attemptMode == Stage3Mode.checkpoint
          ? countedPass
          : stage3.checkpointPassed,
      checkpointAttempts: attemptMode == Stage3Mode.checkpoint
          ? stage3.checkpointAttempts + 1
          : stage3.checkpointAttempts,
      cueBaselineHint: nextBaseline,
      lastCueRotatedFrom: countedPass ? rotatedFrom : stage3.lastCueRotatedFrom,
      readinessWindow: readinessWindow,
      lastH0SuccessAtMs: lastH0SuccessAtMs,
      spacedH0Confirmed: spacedH0Confirmed,
    );

    final retrievalStrength = computeRetrievalStrength(
      passed: passed,
      hintLevel: effectiveHintLevel,
      latencyToStartMs: latencyToStartMs,
      stopsCount: stopsCount,
      selfCorrectionsCount: selfCorrectionsCount,
      confidence: evaluation.confidence,
    );
    final updatedVerse = currentVerse.copyWith(
      attemptCount: currentVerse.attemptCount + 1,
      hiddenAttemptCount: currentVerse.hiddenAttemptCount + 1,
      stage3: stage3,
      passed: countedPass ? true : currentVerse.passed,
      highestHintLevel:
          effectiveHintLevel.order > currentVerse.highestHintLevel.order
              ? effectiveHintLevel
              : currentVerse.highestHintLevel,
      proficiency: _nextProficiency(
        oldValue: currentVerse.proficiency,
        observedValue: retrievalStrength,
        alpha: config.proficiencyEmaAlpha,
      ),
    );
    verses[currentIndex] = updatedVerse;
    final verseReady = _stage3IsReady(
      state: state.copyWith(verses: verses),
      verse: updatedVerse,
      config: runtime.config,
    );
    final lifecycleHook =
        runtime.phase == Stage3Phase.budgetFallback || runtime.budgetExceeded
            ? 'stage4_candidate'
            : (verseReady
                ? (updatedVerse.stage3.spacedH0Confirmed
                    ? 'stage5_candidate'
                    : 'stage4_candidate')
                : null);

    await _persistAttempt(
      state: state.copyWith(verses: verses, stage3: runtime),
      verseIndex: currentIndex,
      verse: updatedVerse,
      stageCode: state.activeStage.code,
      attemptType: attemptType,
      hintLevel: effectiveHintLevel,
      assistedFlag: assisted ? 1 : 0,
      evaluatorMode: evaluation.mode,
      evaluatorPassed: passed ? 1 : 0,
      evaluatorConfidence: evaluation.confidence,
      autoCheckType: autoCheckRequired ? autoPrompt.type.code : null,
      autoCheckResult:
          autoCheckRequired ? (autoEval.passed ? 'pass' : 'fail') : null,
      retrievalStrength: retrievalStrength,
      latencyToStartMs: latencyToStartMs,
      stopsCount: stopsCount,
      selfCorrectionsCount: selfCorrectionsCount,
      nowLocal: effectiveNow,
      telemetryExtras: <String, Object?>{
        'stage3_mode': attemptMode.code,
        'stage3_phase': runtime.phase.code,
        'stage3_step': _stage3TelemetryStep(attemptMode),
        'cue_baseline': baselineHint.code,
        'cue_rotated_from': countedPass ? rotatedFrom?.code : null,
        'weak_target': updatedVerse.stage3.weakTarget,
        'risk_trigger': riskTrigger,
        'link_prev_verse_order': currentIndex > 0 ? currentIndex - 1 : 0,
        'readiness_counted_pass': countedPass,
        'stage3_error_type': passed
            ? null
            : (evaluation.passed ? 'auto_check_fail' : 'recall_fail'),
        'audio_plays': audioPlays,
        'loop_count': loopCount,
        'speed': playbackSpeed,
        'lifecycle_hook': lifecycleHook,
      },
    );
    await _upsertProficiency(
      state: state,
      verse: updatedVerse,
      hintLevel: effectiveHintLevel,
      retrievalStrength: retrievalStrength,
      evaluatorConfidence: evaluation.confidence,
      latencyToStartMs: latencyToStartMs,
      evaluatorPassed: passed,
      nowLocal: effectiveNow,
    );

    runtime = runtime.copyWith(
      totalCountableAttempts:
          runtime.totalCountableAttempts + (countableAttempt ? 1 : 0),
    );

    if (!passed) {
      runtime = runtime.copyWith(
        mode: Stage3Mode.correction,
        activeAutoCheckPrompt: null,
      );
      final failedState = state.copyWith(
        verses: verses,
        stage3: runtime,
        currentHintLevel: _stage3EffectiveBaselineHint(
          updatedVerse.stage3,
          capAtH1: weakPreludeActive,
        ),
      );
      final budgetAdvance = await _maybeAdvanceStage3AfterBudget(
        state: failedState,
        config: config,
        nowLocal: effectiveNow,
      );
      if (budgetAdvance != null) {
        return budgetAdvance;
      }
      return ChainAttemptUpdate(
        state: failedState,
        telemetry: VerseAttemptTelemetry(
          stage: state.activeStage,
          hintLevel: effectiveHintLevel,
          latencyToStartMs: latencyToStartMs,
          stopsCount: stopsCount,
          selfCorrectionsCount: selfCorrectionsCount,
          evaluatorPassed: false,
          evaluatorConfidence: evaluation.confidence,
          evaluatorMode: evaluation.mode,
          revealedAfterAttempt: false,
          retrievalStrength: retrievalStrength,
          attemptType: attemptType,
          assisted: assisted,
          autoCheckType: autoCheckRequired ? autoPrompt.type.code : null,
          autoCheckResult:
              autoCheckRequired ? (autoEval.passed ? 'pass' : 'fail') : null,
          timeOnVerseMs: updatedVerse.stage3.timeOnVerseMs,
          timeOnChunkMs: runtime.chunkElapsedMs,
          stage3Mode: attemptMode,
          stage3Phase: runtime.phase,
          correctionRequiredAfterAttempt: true,
        ),
      );
    }

    final advanced = await _advanceStage3AfterPass(
      state: state.copyWith(
        verses: verses,
        stage3: runtime,
        currentHintLevel: _stage3EffectiveBaselineHint(
          updatedVerse.stage3,
          capAtH1: weakPreludeActive,
        ),
      ),
      passedVerseIndex: currentIndex,
      countedPass: countedPass,
      config: config,
      nowLocal: effectiveNow,
    );
    final budgetAdvance = await _maybeAdvanceStage3AfterBudget(
      state: advanced,
      config: config,
      nowLocal: effectiveNow,
    );
    if (budgetAdvance != null) {
      return budgetAdvance;
    }

    return ChainAttemptUpdate(
      state: advanced,
      telemetry: VerseAttemptTelemetry(
        stage: state.activeStage,
        hintLevel: effectiveHintLevel,
        latencyToStartMs: latencyToStartMs,
        stopsCount: stopsCount,
        selfCorrectionsCount: selfCorrectionsCount,
        evaluatorPassed: true,
        evaluatorConfidence: evaluation.confidence,
        evaluatorMode: evaluation.mode,
        revealedAfterAttempt: false,
        retrievalStrength: retrievalStrength,
        attemptType: attemptType,
        assisted: assisted,
        autoCheckType: autoCheckRequired ? autoPrompt.type.code : null,
        autoCheckResult:
            autoCheckRequired ? (autoEval.passed ? 'pass' : 'fail') : null,
        timeOnVerseMs: updatedVerse.stage3.timeOnVerseMs,
        timeOnChunkMs:
            advanced.stage3?.chunkElapsedMs ?? runtime.chunkElapsedMs,
        stage3Mode: attemptMode,
        stage3Phase: advanced.stage3?.phase ?? runtime.phase,
      ),
    );
  }

  Future<ChainAttemptUpdate> _submitReviewCorrectionExposure({
    required ChainRunState state,
    required int latencyToStartMs,
    required int stopsCount,
    required int selfCorrectionsCount,
    required DateTime? nowLocal,
  }) async {
    final effectiveNow = (nowLocal ?? DateTime.now()).toLocal();
    final touched = _touchReviewClock(
      state: state,
      nowLocal: effectiveNow,
    );
    var runtime = touched.runtime!;
    final verses = [...touched.verses];
    final currentIndex = state.currentVerseIndex;
    final current = verses[currentIndex];
    final updatedVerse = current.copyWith(
      attemptCount: current.attemptCount + 1,
      stage3: current.stage3.copyWith(
        correctionRequired: false,
      ),
    );
    verses[currentIndex] = updatedVerse;

    await _persistAttempt(
      state: state.copyWith(
        verses: verses,
        review: runtime,
      ),
      verseIndex: currentIndex,
      verse: updatedVerse,
      stageCode: state.activeStage.code,
      attemptType: 'encode_echo',
      hintLevel: _reviewEffectiveBaselineHint(updatedVerse.stage3),
      assistedFlag: 0,
      evaluatorMode: EvaluatorMode.manualFallback,
      evaluatorPassed: 1,
      evaluatorConfidence: null,
      autoCheckType: null,
      autoCheckResult: null,
      retrievalStrength: 0.0,
      latencyToStartMs: latencyToStartMs,
      stopsCount: stopsCount,
      selfCorrectionsCount: selfCorrectionsCount,
      nowLocal: effectiveNow,
      telemetryExtras: <String, Object?>{
        'review_mode': ReviewMode.correction.code,
        'review_phase': runtime.phase.code,
        'review_step': 'correction',
        'correction_exposure': true,
      },
    );

    final nextMode = switch (runtime.phase) {
      ReviewPhase.checkpoint => ReviewMode.checkpoint,
      ReviewPhase.remediation => ReviewMode.remediation,
      _ => _reviewModeForVerse(
          verse: updatedVerse,
          runtime: runtime.copyWith(mode: ReviewMode.hiddenRecall),
        ),
    };

    runtime = runtime.copyWith(
      mode: nextMode,
      activeAutoCheckPrompt: nextMode == ReviewMode.correction
          ? null
          : _buildReviewAutoCheckPrompt(
              state: state.copyWith(verses: verses),
              verses: verses,
              verseIndex: currentIndex,
              mode: nextMode,
            ),
    );

    return ChainAttemptUpdate(
      state: state.copyWith(
        verses: verses,
        review: runtime,
        currentHintLevel: _reviewEffectiveBaselineHint(updatedVerse.stage3),
      ),
      telemetry: VerseAttemptTelemetry(
        stage: state.activeStage,
        hintLevel: _reviewEffectiveBaselineHint(updatedVerse.stage3),
        latencyToStartMs: latencyToStartMs,
        stopsCount: stopsCount,
        selfCorrectionsCount: selfCorrectionsCount,
        evaluatorPassed: true,
        evaluatorConfidence: null,
        evaluatorMode: EvaluatorMode.manualFallback,
        revealedAfterAttempt: false,
        retrievalStrength: 0.0,
        attemptType: 'encode_echo',
        assisted: false,
        timeOnVerseMs: updatedVerse.stage3.timeOnVerseMs,
        timeOnChunkMs: runtime.chunkElapsedMs,
      ),
    );
  }

  Future<ChainAttemptUpdate> _submitReviewAttempt({
    required ChainRunState state,
    required VerseEvaluator evaluator,
    required bool manualFallbackPass,
    required String? selectedAutoCheckOptionId,
    required double? asrConfidence,
    required int latencyToStartMs,
    required int stopsCount,
    required int selfCorrectionsCount,
    required int audioPlays,
    required int loopCount,
    required double playbackSpeed,
    required ProgressiveRevealChainConfig config,
    required DateTime? nowLocal,
  }) async {
    final effectiveNow = (nowLocal ?? DateTime.now()).toLocal();
    final touched = _touchReviewClock(
      state: state,
      nowLocal: effectiveNow,
    );
    var runtime = touched.runtime!;
    var verses = [...touched.verses];
    final currentIndex = state.currentVerseIndex;
    final currentVerse = verses[currentIndex];

    if (runtime.mode == ReviewMode.correction ||
        currentVerse.stage3.correctionRequired) {
      throw StateError(
        'Correction playback is required before next review attempt.',
      );
    }

    final evaluation = await evaluator.evaluate(
      VerseEvaluationRequest(
        verse: currentVerse.verse,
        manualFallbackPass: manualFallbackPass,
        asrConfidence: asrConfidence,
      ),
    );

    final attemptMode = runtime.mode;
    final attemptType = _attemptTypeForReviewMode(attemptMode);
    final baselineHint = _reviewEffectiveBaselineHint(currentVerse.stage3);
    final effectiveHintLevel = state.currentHintLevel.order < baselineHint.order
        ? baselineHint
        : state.currentHintLevel;
    final assisted = effectiveHintLevel.order > baselineHint.order;
    final autoCheckRequired = runtime.autoCheckRequiredForCurrentMode;
    final autoPrompt = runtime.activeAutoCheckPrompt ??
        _buildReviewAutoCheckPrompt(
          state: state.copyWith(verses: verses),
          verses: verses,
          verseIndex: currentIndex,
          mode: attemptMode,
        );

    if (autoCheckRequired &&
        (selectedAutoCheckOptionId == null ||
            selectedAutoCheckOptionId.trim().isEmpty)) {
      throw StateError('Auto-check option is required for review attempts.');
    }

    final autoEval = autoCheckRequired
        ? _autoCheckEngine.evaluate(
            prompt: autoPrompt,
            selectedOptionId: selectedAutoCheckOptionId,
          )
        : const Stage1AutoCheckEvaluation(
            passed: true,
            selectedOptionId: null,
            normalizedSelected: '',
          );

    final passed = evaluation.passed && autoEval.passed;
    final countableAttempt = !assisted &&
        effectiveHintLevel.order <= runtime.config.readinessMaxHint.order;
    final countedPass = passed && countableAttempt;
    final countedH0Pass = countedPass && effectiveHintLevel == HintLevel.h0;
    final riskTrigger = _reviewRiskTrigger(
      verse: currentVerse,
      config: runtime.config,
    );

    var stage3 = currentVerse.stage3;
    final usedRelief = stage3.reliefPending;
    final nextConsecutiveFailures = passed ? 0 : stage3.consecutiveFailures + 1;
    final nextReliefPending = !passed &&
        !usedRelief &&
        nextConsecutiveFailures >= runtime.config.discriminationFailureTrigger;
    var rotatedFrom = stage3.lastCueRotatedFrom;
    var nextBaseline = stage3.cueBaselineHint;
    if (countedPass) {
      rotatedFrom = stage3.cueBaselineHint;
      nextBaseline = _harderHint(stage3.cueBaselineHint);
    }
    if (nextBaseline.order > HintLevel.letters.order) {
      nextBaseline = HintLevel.letters;
    }

    var lastH0SuccessAtMs = stage3.lastH0SuccessAtMs;
    var spacedH0Confirmed = stage3.spacedH0Confirmed;
    if (countedH0Pass) {
      if (lastH0SuccessAtMs != null &&
          runtime.lastActionAtEpochMs - lastH0SuccessAtMs >=
              runtime.config.minSpacingMs) {
        spacedH0Confirmed = true;
      }
      lastH0SuccessAtMs = runtime.lastActionAtEpochMs;
    }

    var readinessWindow = stage3.readinessWindow;
    if (countableAttempt) {
      readinessWindow = <Stage3WindowEntry>[
        ...readinessWindow,
        Stage3WindowEntry(
          timestampMs: runtime.lastActionAtEpochMs,
          passed: passed,
          countedPass: countedPass,
          hintLevel: effectiveHintLevel,
          assisted: assisted,
        ),
      ];
      if (readinessWindow.length > runtime.config.readinessWindow) {
        readinessWindow = readinessWindow.sublist(
          readinessWindow.length - runtime.config.readinessWindow,
        );
      }
    }

    stage3 = stage3.copyWith(
      attempts: stage3.attempts + 1,
      countedAttempts: stage3.countedAttempts + (countableAttempt ? 1 : 0),
      countedPasses: stage3.countedPasses + (countedPass ? 1 : 0),
      countedH0Passes: stage3.countedH0Passes + (countedH0Pass ? 1 : 0),
      consecutiveFailures: nextConsecutiveFailures,
      correctionRequired: !passed,
      reliefPending: nextReliefPending,
      weakTarget: stage3.weakTarget ||
          currentVerse.proficiency < runtime.config.targetSuccessBandMin ||
          !countedPass,
      remediationNeeded: stage3.remediationNeeded ||
          (runtime.phase == ReviewPhase.checkpoint && !countedPass),
      discriminationAttempts: stage3.discriminationAttempts +
          (attemptMode == ReviewMode.discrimination ? 1 : 0),
      discriminationPasses: stage3.discriminationPasses +
          (attemptMode == ReviewMode.discrimination && countedPass ? 1 : 0),
      linkingAttempts:
          stage3.linkingAttempts + (attemptMode == ReviewMode.linking ? 1 : 0),
      linkingPassCount: stage3.linkingPassCount +
          (attemptMode == ReviewMode.linking && countedPass ? 1 : 0),
      checkpointAttempted: attemptMode == ReviewMode.checkpoint
          ? true
          : stage3.checkpointAttempted,
      checkpointPassed: attemptMode == ReviewMode.checkpoint
          ? countedPass
          : stage3.checkpointPassed,
      checkpointAttempts: attemptMode == ReviewMode.checkpoint
          ? stage3.checkpointAttempts + 1
          : stage3.checkpointAttempts,
      cueBaselineHint: nextBaseline,
      lastCueRotatedFrom: countedPass ? rotatedFrom : stage3.lastCueRotatedFrom,
      readinessWindow: readinessWindow,
      lastH0SuccessAtMs: lastH0SuccessAtMs,
      spacedH0Confirmed: spacedH0Confirmed,
    );

    final retrievalStrength = computeRetrievalStrength(
      passed: passed,
      hintLevel: effectiveHintLevel,
      latencyToStartMs: latencyToStartMs,
      stopsCount: stopsCount,
      selfCorrectionsCount: selfCorrectionsCount,
      confidence: evaluation.confidence,
    );
    final updatedVerse = currentVerse.copyWith(
      attemptCount: currentVerse.attemptCount + 1,
      hiddenAttemptCount: currentVerse.hiddenAttemptCount + 1,
      stage3: stage3,
      passed: countedPass ? true : currentVerse.passed,
      highestHintLevel:
          effectiveHintLevel.order > currentVerse.highestHintLevel.order
              ? effectiveHintLevel
              : currentVerse.highestHintLevel,
      proficiency: _nextProficiency(
        oldValue: currentVerse.proficiency,
        observedValue: retrievalStrength,
        alpha: config.proficiencyEmaAlpha,
      ),
    );
    verses[currentIndex] = updatedVerse;
    final verseReady = _reviewIsReady(
      verse: updatedVerse,
      config: runtime.config,
    );

    await _persistAttempt(
      state: state.copyWith(
        verses: verses,
        review: runtime,
      ),
      verseIndex: currentIndex,
      verse: updatedVerse,
      stageCode: state.activeStage.code,
      attemptType: attemptType,
      hintLevel: effectiveHintLevel,
      assistedFlag: assisted ? 1 : 0,
      evaluatorMode: evaluation.mode,
      evaluatorPassed: passed ? 1 : 0,
      evaluatorConfidence: evaluation.confidence,
      autoCheckType: autoCheckRequired ? autoPrompt.type.code : null,
      autoCheckResult:
          autoCheckRequired ? (autoEval.passed ? 'pass' : 'fail') : null,
      retrievalStrength: retrievalStrength,
      latencyToStartMs: latencyToStartMs,
      stopsCount: stopsCount,
      selfCorrectionsCount: selfCorrectionsCount,
      nowLocal: effectiveNow,
      telemetryExtras: <String, Object?>{
        'review_mode': attemptMode.code,
        'review_phase': runtime.phase.code,
        'review_step': _reviewTelemetryStep(attemptMode),
        'cue_baseline': baselineHint.code,
        'cue_rotated_from': countedPass ? rotatedFrom?.code : null,
        'weak_target': updatedVerse.stage3.weakTarget,
        'risk_trigger': riskTrigger,
        'link_prev_verse_order': currentIndex > 0 ? currentIndex - 1 : null,
        'readiness_counted_pass': countedPass,
        'review_error_type': passed
            ? null
            : (evaluation.passed ? 'auto_check_fail' : 'recall_fail'),
        'audio_plays': audioPlays,
        'loop_count': loopCount,
        'speed': playbackSpeed,
        'lifecycle_hook': verseReady && updatedVerse.stage3.spacedH0Confirmed
            ? 'stage5_candidate'
            : null,
      },
    );
    await _upsertProficiency(
      state: state,
      verse: updatedVerse,
      hintLevel: effectiveHintLevel,
      retrievalStrength: retrievalStrength,
      evaluatorConfidence: evaluation.confidence,
      latencyToStartMs: latencyToStartMs,
      evaluatorPassed: passed,
      nowLocal: effectiveNow,
    );

    runtime = runtime.copyWith(
      totalCountableAttempts:
          runtime.totalCountableAttempts + (countableAttempt ? 1 : 0),
    );

    if (!passed) {
      runtime = runtime.copyWith(
        mode: ReviewMode.correction,
        activeAutoCheckPrompt: null,
      );
      final failedState = state.copyWith(
        verses: verses,
        review: runtime,
        currentHintLevel: _reviewEffectiveBaselineHint(updatedVerse.stage3),
      );
      final budgetAdvance = await _maybeAdvanceReviewAfterBudget(
        state: failedState,
        nowLocal: effectiveNow,
      );
      if (budgetAdvance != null) {
        return budgetAdvance;
      }
      return ChainAttemptUpdate(
        state: failedState,
        telemetry: VerseAttemptTelemetry(
          stage: state.activeStage,
          hintLevel: effectiveHintLevel,
          latencyToStartMs: latencyToStartMs,
          stopsCount: stopsCount,
          selfCorrectionsCount: selfCorrectionsCount,
          evaluatorPassed: false,
          evaluatorConfidence: evaluation.confidence,
          evaluatorMode: evaluation.mode,
          revealedAfterAttempt: false,
          retrievalStrength: retrievalStrength,
          attemptType: attemptType,
          assisted: assisted,
          autoCheckType: autoCheckRequired ? autoPrompt.type.code : null,
          autoCheckResult:
              autoCheckRequired ? (autoEval.passed ? 'pass' : 'fail') : null,
          timeOnVerseMs: updatedVerse.stage3.timeOnVerseMs,
          timeOnChunkMs: runtime.chunkElapsedMs,
          correctionRequiredAfterAttempt: true,
        ),
      );
    }

    final advanced = await _advanceReviewAfterPass(
      state: state.copyWith(
        verses: verses,
        review: runtime,
        currentHintLevel: _reviewEffectiveBaselineHint(updatedVerse.stage3),
      ),
      passedVerseIndex: currentIndex,
      countedPass: countedPass,
      nowLocal: effectiveNow,
    );
    final budgetAdvance = await _maybeAdvanceReviewAfterBudget(
      state: advanced,
      nowLocal: effectiveNow,
    );
    if (budgetAdvance != null) {
      return budgetAdvance;
    }

    return ChainAttemptUpdate(
      state: advanced,
      telemetry: VerseAttemptTelemetry(
        stage: state.activeStage,
        hintLevel: effectiveHintLevel,
        latencyToStartMs: latencyToStartMs,
        stopsCount: stopsCount,
        selfCorrectionsCount: selfCorrectionsCount,
        evaluatorPassed: true,
        evaluatorConfidence: evaluation.confidence,
        evaluatorMode: evaluation.mode,
        revealedAfterAttempt: false,
        retrievalStrength: retrievalStrength,
        attemptType: attemptType,
        assisted: assisted,
        autoCheckType: autoCheckRequired ? autoPrompt.type.code : null,
        autoCheckResult:
            autoCheckRequired ? (autoEval.passed ? 'pass' : 'fail') : null,
        timeOnVerseMs: updatedVerse.stage3.timeOnVerseMs,
        timeOnChunkMs:
            advanced.review?.chunkElapsedMs ?? runtime.chunkElapsedMs,
      ),
    );
  }

  Future<ChainRunState> _advanceReviewAfterPass({
    required ChainRunState state,
    required int passedVerseIndex,
    required bool countedPass,
    required DateTime nowLocal,
  }) async {
    var runtime = state.review!;
    var verses = [...state.verses];

    if (runtime.phase == ReviewPhase.remediation) {
      if (countedPass) {
        final verse = verses[passedVerseIndex];
        verses[passedVerseIndex] = verse.copyWith(
          stage3: verse.stage3.copyWith(remediationNeeded: false),
        );
      }

      final pending = runtime.remediationTargets.where((index) {
        if (index < 0 || index >= verses.length) {
          return false;
        }
        return verses[index].stage3.remediationNeeded ||
            !_reviewIsReady(
              verse: verses[index],
              config: runtime.config,
            );
      }).toList(growable: false);
      if (pending.isNotEmpty) {
        final nextIndex = _nextIndexFromList(
          indexes: pending,
          startAfter: passedVerseIndex,
        );
        final nextVerse = verses[nextIndex];
        return state.copyWith(
          verses: verses,
          review: runtime.copyWith(
            phase: ReviewPhase.remediation,
            mode: ReviewMode.remediation,
            remediationCursor: pending.indexOf(nextIndex),
            activeAutoCheckPrompt: _buildReviewAutoCheckPrompt(
              state: state.copyWith(verses: verses),
              verses: verses,
              verseIndex: nextIndex,
              mode: ReviewMode.remediation,
            ),
          ),
          currentVerseIndex: nextIndex,
          currentHintLevel: _reviewEffectiveBaselineHint(nextVerse.stage3),
          returnVerseIndex: null,
        );
      }

      final targets = runtime.remediationTargets;
      if (targets.isNotEmpty) {
        for (final index in targets) {
          final verse = verses[index];
          verses[index] = verse.copyWith(
            stage3: verse.stage3.copyWith(
              checkpointAttempted: false,
              checkpointPassed: false,
            ),
          );
        }
        final first = targets.first;
        return state.copyWith(
          verses: verses,
          review: runtime.copyWith(
            phase: ReviewPhase.checkpoint,
            mode: ReviewMode.checkpoint,
            checkpointTargets: targets,
            checkpointCursor: 0,
            remediationTargets: const <int>[],
            remediationCursor: 0,
            activeAutoCheckPrompt: _buildReviewAutoCheckPrompt(
              state: state.copyWith(verses: verses),
              verses: verses,
              verseIndex: first,
              mode: ReviewMode.checkpoint,
            ),
          ),
          currentVerseIndex: first,
          currentHintLevel: _reviewEffectiveBaselineHint(verses[first].stage3),
          returnVerseIndex: null,
        );
      }
    }

    if (runtime.phase == ReviewPhase.checkpoint) {
      final targets = runtime.checkpointTargets.isEmpty
          ? List<int>.generate(verses.length, (index) => index)
          : runtime.checkpointTargets;
      final nextCursor = runtime.checkpointCursor + 1;
      if (nextCursor < targets.length) {
        final nextIndex = targets[nextCursor];
        return state.copyWith(
          verses: verses,
          review: runtime.copyWith(
            phase: ReviewPhase.checkpoint,
            mode: ReviewMode.checkpoint,
            checkpointTargets: targets,
            checkpointCursor: nextCursor,
            activeAutoCheckPrompt: _buildReviewAutoCheckPrompt(
              state: state.copyWith(verses: verses),
              verses: verses,
              verseIndex: nextIndex,
              mode: ReviewMode.checkpoint,
            ),
          ),
          currentVerseIndex: nextIndex,
          currentHintLevel:
              _reviewEffectiveBaselineHint(verses[nextIndex].stage3),
          returnVerseIndex: null,
        );
      }

      final failed = <int>[
        for (final index in targets)
          if (!verses[index].stage3.checkpointPassed) index,
      ];
      final chunkPassRate = targets.isEmpty
          ? 0.0
          : (targets.length - failed.length) / targets.length;
      final everyReady = verses.every(
        (verse) => _reviewIsReady(
          verse: verse,
          config: runtime.config,
        ),
      );
      final checkpointPassed =
          chunkPassRate >= runtime.config.checkpointThreshold && everyReady;
      final outcome = ReviewCheckpointOutcome(
        chunkPassRate: chunkPassRate,
        failedVerseIndexes: failed,
        everyVerseReady: everyReady,
        passed: checkpointPassed,
      );

      if (checkpointPassed) {
        final completedVerses = <ChainVerseState>[
          for (final verse in verses)
            verse.passed
                ? verse
                : verse.markPassedForStage(CompanionStage.hiddenReveal),
        ];
        return state.copyWith(
          verses: completedVerses,
          review: runtime.copyWith(
            phase: ReviewPhase.completed,
            mode: ReviewMode.checkpoint,
            lastCheckpointOutcome: outcome,
            activeAutoCheckPrompt: null,
          ),
          currentHintLevel: HintLevel.h0,
          returnVerseIndex: null,
        );
      }

      if (runtime.remediationRounds >=
          runtime.config.maxCheckpointRemediationRounds) {
        for (final index in failed) {
          final verse = verses[index];
          verses[index] = verse.copyWith(
            stage3: verse.stage3.copyWith(
              weakTarget: true,
              remediationNeeded: true,
            ),
          );
        }
        return state.copyWith(
          verses: verses,
          review: runtime.copyWith(
            phase: ReviewPhase.budgetFallback,
            budgetExceeded: true,
            lastCheckpointOutcome: outcome,
            activeAutoCheckPrompt: null,
          ),
          returnVerseIndex: null,
        );
      }

      for (final index in failed) {
        final verse = verses[index];
        verses[index] = verse.copyWith(
          stage3: verse.stage3.copyWith(
            weakTarget: true,
            remediationNeeded: true,
          ),
        );
      }
      final first = failed.first;
      return state.copyWith(
        verses: verses,
        review: runtime.copyWith(
          phase: ReviewPhase.remediation,
          mode: ReviewMode.remediation,
          remediationRounds: runtime.remediationRounds + 1,
          remediationTargets: failed,
          remediationCursor: 0,
          lastCheckpointOutcome: outcome,
          activeAutoCheckPrompt: _buildReviewAutoCheckPrompt(
            state: state.copyWith(verses: verses),
            verses: verses,
            verseIndex: first,
            mode: ReviewMode.remediation,
          ),
        ),
        currentVerseIndex: first,
        currentHintLevel: _reviewEffectiveBaselineHint(verses[first].stage3),
        returnVerseIndex: null,
      );
    }

    final allReady = verses.every(
      (verse) => _reviewIsReady(
        verse: verse,
        config: runtime.config,
      ),
    );
    if (allReady) {
      final targets = List<int>.generate(verses.length, (index) => index);
      for (final index in targets) {
        final verse = verses[index];
        verses[index] = verse.copyWith(
          stage3: verse.stage3.copyWith(
            checkpointAttempted: false,
            checkpointPassed: false,
          ),
        );
      }
      final first = targets.first;
      return state.copyWith(
        verses: verses,
        review: runtime.copyWith(
          phase: ReviewPhase.checkpoint,
          mode: ReviewMode.checkpoint,
          checkpointTargets: targets,
          checkpointCursor: 0,
          activeAutoCheckPrompt: _buildReviewAutoCheckPrompt(
            state: state.copyWith(verses: verses),
            verses: verses,
            verseIndex: first,
            mode: ReviewMode.checkpoint,
          ),
        ),
        currentVerseIndex: first,
        currentHintLevel: _reviewEffectiveBaselineHint(verses[first].stage3),
        returnVerseIndex: null,
      );
    }

    final nextState = state.copyWith(verses: verses);
    final target = _pickReviewTarget(
      state: nextState.copyWith(review: runtime),
      verses: verses,
      startAfter: passedVerseIndex,
      runtime: runtime,
    );
    if (target == null) {
      return nextState.copyWith(
        review: runtime.copyWith(
          phase: ReviewPhase.acquisition,
          mode: ReviewMode.hiddenRecall,
          activeAutoCheckPrompt: null,
        ),
      );
    }

    return nextState.copyWith(
      review: runtime.copyWith(
        phase: target.phase,
        mode: target.mode,
        activeAutoCheckPrompt: target.mode == ReviewMode.correction
            ? null
            : _buildReviewAutoCheckPrompt(
                state: nextState,
                verses: verses,
                verseIndex: target.verseIndex,
                mode: target.mode,
              ),
      ),
      currentVerseIndex: target.verseIndex,
      currentHintLevel: _reviewEffectiveBaselineHint(
        verses[target.verseIndex].stage3,
      ),
      returnVerseIndex: null,
    );
  }

  Future<ChainAttemptUpdate?> _maybeAdvanceReviewAfterBudget({
    required ChainRunState state,
    required DateTime nowLocal,
  }) async {
    final runtime = state.review;
    if (runtime == null) {
      return null;
    }
    if (runtime.phase == ReviewPhase.completed && !state.completed) {
      return _finalizeReviewResult(
        state: state,
        resultKind: ChainResultKind.completed,
        nowLocal: nowLocal,
      );
    }
    if (runtime.phase == ReviewPhase.budgetFallback && !state.completed) {
      return _finalizeReviewResult(
        state: state,
        resultKind: ChainResultKind.partial,
        nowLocal: nowLocal,
      );
    }
    if (runtime.chunkElapsedMs < runtime.reviewBudgetMs) {
      return null;
    }

    final verses = [...state.verses];
    final unresolved = _reviewUnresolvedTargets(
      verses: verses,
      config: runtime.config,
    );
    if (unresolved.isNotEmpty) {
      for (final index in unresolved) {
        final verse = verses[index];
        verses[index] = verse.copyWith(
          stage3: verse.stage3.copyWith(
            weakTarget: true,
            remediationNeeded: true,
          ),
        );
      }
      final nextState = state.copyWith(
        verses: verses,
        review: runtime.copyWith(
          phase: ReviewPhase.budgetFallback,
          mode: ReviewMode.remediation,
          budgetExceeded: true,
          activeAutoCheckPrompt: null,
        ),
      );
      return _finalizeReviewResult(
        state: nextState,
        resultKind: ChainResultKind.partial,
        nowLocal: nowLocal,
      );
    }

    return _finalizeReviewResult(
      state: state.copyWith(
        review: runtime.copyWith(
          phase: ReviewPhase.completed,
          activeAutoCheckPrompt: null,
        ),
      ),
      resultKind: ChainResultKind.completed,
      nowLocal: nowLocal,
    );
  }

  Future<ChainAttemptUpdate> _finalizeReviewResult({
    required ChainRunState state,
    required ChainResultKind resultKind,
    required DateTime nowLocal,
  }) async {
    final finalizedVerses = resultKind == ChainResultKind.completed
        ? <ChainVerseState>[
            for (final verse in state.verses)
              verse.passed
                  ? verse
                  : verse.markPassedForStage(CompanionStage.hiddenReveal),
          ]
        : state.verses;

    final summary = await _completeSession(
      state: state.copyWith(verses: finalizedVerses),
      verseStates: finalizedVerses,
      nowLocal: nowLocal,
      resultKind: resultKind,
    );
    return ChainAttemptUpdate(
      state: state.copyWith(
        verses: finalizedVerses,
        completed: true,
        resultKind: resultKind,
        currentHintLevel: HintLevel.h0,
        returnVerseIndex: null,
      ),
      telemetry: VerseAttemptTelemetry(
        stage: CompanionStage.hiddenReveal,
        hintLevel: HintLevel.h0,
        latencyToStartMs: 0,
        stopsCount: 0,
        selfCorrectionsCount: 0,
        evaluatorPassed: resultKind == ChainResultKind.completed,
        evaluatorConfidence: null,
        evaluatorMode: EvaluatorMode.manualFallback,
        revealedAfterAttempt: false,
        retrievalStrength: 0.0,
        attemptType: 'checkpoint',
        assisted: false,
        timeOnVerseMs:
            finalizedVerses[state.currentVerseIndex].stage3.timeOnVerseMs,
        timeOnChunkMs: state.review?.chunkElapsedMs ?? 0,
      ),
      summary: summary,
    );
  }

  Future<ChainAttemptUpdate> _submitStage4Attempt({
    required ChainRunState state,
    required VerseEvaluator evaluator,
    required bool manualFallbackPass,
    required String? selectedAutoCheckOptionId,
    required double? asrConfidence,
    required int latencyToStartMs,
    required int stopsCount,
    required int selfCorrectionsCount,
    required int audioPlays,
    required int loopCount,
    required double playbackSpeed,
    required ProgressiveRevealChainConfig config,
    required DateTime? nowLocal,
  }) async {
    final effectiveNow = (nowLocal ?? DateTime.now()).toLocal();
    final touched = _touchStage4Clock(
      state: state,
      nowLocal: effectiveNow,
    );
    var runtime = touched.runtime!;
    var verses = [...touched.verses];
    final currentIndex = state.currentVerseIndex;
    final currentVerse = verses[currentIndex];

    if (runtime.mode == Stage4Mode.correction ||
        currentVerse.stage4.correctionRequired) {
      throw StateError(
          'Correction playback is required before next Stage-4 attempt.');
    }

    final evaluation = await evaluator.evaluate(
      VerseEvaluationRequest(
        verse: currentVerse.verse,
        manualFallbackPass: manualFallbackPass,
        asrConfidence: asrConfidence,
      ),
    );

    final attemptMode = runtime.mode;
    final attemptType = _attemptTypeForStage4Mode(attemptMode);
    final baselineHint = _stage4EffectiveBaselineHint(currentVerse.stage4);
    final effectiveHintLevel = state.currentHintLevel.order < baselineHint.order
        ? baselineHint
        : state.currentHintLevel;
    final assisted = effectiveHintLevel.order > baselineHint.order;
    final autoCheckRequired = runtime.autoCheckRequiredForCurrentMode;
    final autoPrompt = runtime.activeAutoCheckPrompt ??
        _buildStage4AutoCheckPrompt(
          state: state.copyWith(verses: verses),
          verses: verses,
          verseIndex: currentIndex,
          mode: attemptMode,
        );

    if (autoCheckRequired &&
        (selectedAutoCheckOptionId == null ||
            selectedAutoCheckOptionId.trim().isEmpty)) {
      throw StateError('Auto-check option is required for Stage-4 attempts.');
    }

    final autoEval = autoCheckRequired
        ? _autoCheckEngine.evaluate(
            prompt: autoPrompt,
            selectedOptionId: selectedAutoCheckOptionId,
          )
        : const Stage1AutoCheckEvaluation(
            passed: true,
            selectedOptionId: null,
            normalizedSelected: '',
          );

    final passed = evaluation.passed && autoEval.passed;
    final countableAttempt = !assisted &&
        effectiveHintLevel.order <= runtime.config.readinessMaxHint.order;
    final countedPass = passed && countableAttempt;
    final countedH0Pass = countedPass && effectiveHintLevel == HintLevel.h0;
    final riskTrigger = _stage4RiskTrigger(
      verse: currentVerse,
      config: runtime.config,
    );

    var stage4 = currentVerse.stage4;
    var readinessWindow = stage4.readinessWindow;
    if (countableAttempt) {
      readinessWindow = <Stage4WindowEntry>[
        ...readinessWindow,
        Stage4WindowEntry(
          timestampMs: runtime.lastActionAtEpochMs,
          passed: passed,
          countedPass: countedPass,
          hintLevel: effectiveHintLevel,
          assisted: assisted,
        ),
      ];
      if (readinessWindow.length > runtime.config.readinessWindow) {
        readinessWindow = readinessWindow.sublist(
          readinessWindow.length - runtime.config.readinessWindow,
        );
      }
    }

    final nextConsecutiveFailures = passed ? 0 : stage4.consecutiveFailures + 1;
    stage4 = stage4.copyWith(
      attempts: stage4.attempts + 1,
      countedAttempts: stage4.countedAttempts + (countableAttempt ? 1 : 0),
      countedPasses: stage4.countedPasses + (countedPass ? 1 : 0),
      countedH0Passes: stage4.countedH0Passes + (countedH0Pass ? 1 : 0),
      consecutiveFailures: nextConsecutiveFailures,
      correctionRequired: !passed,
      weakTarget: stage4.weakTarget ||
          currentVerse.stage1.weak ||
          currentVerse.stage2.weakTarget ||
          currentVerse.stage3.weakTarget ||
          !countedPass,
      riskTarget: stage4.riskTarget || riskTrigger != null,
      remediationNeeded: stage4.remediationNeeded ||
          (runtime.phase == Stage4Phase.checkpoint && !countedPass),
      discriminationAttempts: stage4.discriminationAttempts +
          (attemptMode == Stage4Mode.discrimination ? 1 : 0),
      discriminationPasses: stage4.discriminationPasses +
          (attemptMode == Stage4Mode.discrimination && countedPass ? 1 : 0),
      linkingAttempts:
          stage4.linkingAttempts + (attemptMode == Stage4Mode.linking ? 1 : 0),
      linkingPassCount: stage4.linkingPassCount +
          (attemptMode == Stage4Mode.linking && countedPass ? 1 : 0),
      randomStartAttempts: stage4.randomStartAttempts +
          (attemptMode == Stage4Mode.randomStart ? 1 : 0),
      randomStartPasses: stage4.randomStartPasses +
          (attemptMode == Stage4Mode.randomStart && countedPass ? 1 : 0),
      checkpointAttempted: attemptMode == Stage4Mode.checkpoint
          ? true
          : stage4.checkpointAttempted,
      checkpointPassed: attemptMode == Stage4Mode.checkpoint
          ? countedPass
          : stage4.checkpointPassed,
      checkpointAttempts: attemptMode == Stage4Mode.checkpoint
          ? stage4.checkpointAttempts + 1
          : stage4.checkpointAttempts,
      readinessWindow: readinessWindow,
    );

    final retrievalStrength = computeRetrievalStrength(
      passed: passed,
      hintLevel: effectiveHintLevel,
      latencyToStartMs: latencyToStartMs,
      stopsCount: stopsCount,
      selfCorrectionsCount: selfCorrectionsCount,
      confidence: evaluation.confidence,
    );
    final updatedVerse = currentVerse.copyWith(
      attemptCount: currentVerse.attemptCount + 1,
      hiddenAttemptCount: currentVerse.hiddenAttemptCount + 1,
      stage4: stage4,
      passed: countedPass ? true : currentVerse.passed,
      highestHintLevel:
          effectiveHintLevel.order > currentVerse.highestHintLevel.order
              ? effectiveHintLevel
              : currentVerse.highestHintLevel,
      proficiency: _nextProficiency(
        oldValue: currentVerse.proficiency,
        observedValue: retrievalStrength,
        alpha: config.proficiencyEmaAlpha,
      ),
    );
    verses[currentIndex] = updatedVerse;

    final readinessCountedPass = _stage4IsReady(
      state: state.copyWith(verses: verses),
      verse: updatedVerse,
      config: runtime.config,
    );

    await _persistAttempt(
      state: state.copyWith(verses: verses, stage4: runtime),
      verseIndex: currentIndex,
      verse: updatedVerse,
      stageCode: state.activeStage.code,
      attemptType: attemptType,
      hintLevel: effectiveHintLevel,
      assistedFlag: assisted ? 1 : 0,
      evaluatorMode: evaluation.mode,
      evaluatorPassed: passed ? 1 : 0,
      evaluatorConfidence: evaluation.confidence,
      autoCheckType: autoCheckRequired ? autoPrompt.type.code : null,
      autoCheckResult:
          autoCheckRequired ? (autoEval.passed ? 'pass' : 'fail') : null,
      retrievalStrength: retrievalStrength,
      latencyToStartMs: latencyToStartMs,
      stopsCount: stopsCount,
      selfCorrectionsCount: selfCorrectionsCount,
      nowLocal: effectiveNow,
      telemetryExtras: <String, Object?>{
        'lifecycle_stage': 'stage4',
        'stage4_mode': attemptMode.code,
        'stage4_phase': runtime.phase.code,
        'stage4_step': _stage4TelemetryStep(attemptMode),
        'stage4_due_kind': runtime.dueKind,
        'random_start_anchor_verse_order':
            attemptMode == Stage4Mode.randomStart ? currentIndex : null,
        'continuation_span': 1,
        'link_prev_verse_order': currentIndex > 0 ? currentIndex - 1 : null,
        'readiness_counted_pass': readinessCountedPass,
        'cue_baseline': baselineHint.code,
        'cue_rotated_from': null,
        'risk_trigger': riskTrigger,
        'stage4_error_type': passed
            ? null
            : (evaluation.passed ? 'auto_check_fail' : 'recall_fail'),
        'unresolved_targets_count': runtime.unresolvedTargets.length,
        'lifecycle_hook': passed ? null : 'stage4_retry',
        'audio_plays': audioPlays,
        'loop_count': loopCount,
        'speed': playbackSpeed,
      },
    );
    await _upsertProficiency(
      state: state,
      verse: updatedVerse,
      hintLevel: effectiveHintLevel,
      retrievalStrength: retrievalStrength,
      evaluatorConfidence: evaluation.confidence,
      latencyToStartMs: latencyToStartMs,
      evaluatorPassed: passed,
      nowLocal: effectiveNow,
    );

    runtime = runtime.copyWith(
      totalCountableAttempts:
          runtime.totalCountableAttempts + (countableAttempt ? 1 : 0),
    );

    if (!passed) {
      runtime = runtime.copyWith(
        mode: Stage4Mode.correction,
        activeAutoCheckPrompt: null,
      );
      final failedState = state.copyWith(
        verses: verses,
        stage4: runtime,
        currentHintLevel: _stage4EffectiveBaselineHint(updatedVerse.stage4),
      );
      final budgetAdvance = await _maybeAdvanceStage4AfterBudget(
        state: failedState,
        config: config,
        nowLocal: effectiveNow,
      );
      if (budgetAdvance != null) {
        return budgetAdvance;
      }
      return ChainAttemptUpdate(
        state: failedState,
        telemetry: VerseAttemptTelemetry(
          stage: state.activeStage,
          hintLevel: effectiveHintLevel,
          latencyToStartMs: latencyToStartMs,
          stopsCount: stopsCount,
          selfCorrectionsCount: selfCorrectionsCount,
          evaluatorPassed: false,
          evaluatorConfidence: evaluation.confidence,
          evaluatorMode: evaluation.mode,
          revealedAfterAttempt: false,
          retrievalStrength: retrievalStrength,
          attemptType: attemptType,
          assisted: assisted,
          autoCheckType: autoCheckRequired ? autoPrompt.type.code : null,
          autoCheckResult:
              autoCheckRequired ? (autoEval.passed ? 'pass' : 'fail') : null,
          timeOnVerseMs: updatedVerse.stage4.timeOnVerseMs,
          timeOnChunkMs: runtime.chunkElapsedMs,
          stage4Mode: attemptMode,
          stage4Phase: runtime.phase,
          correctionRequiredAfterAttempt: true,
        ),
      );
    }

    final advanced = await _advanceStage4AfterPass(
      state: state.copyWith(
        verses: verses,
        stage4: runtime,
        currentHintLevel: _stage4EffectiveBaselineHint(updatedVerse.stage4),
      ),
      passedVerseIndex: currentIndex,
      countedPass: countedPass,
      config: config,
      nowLocal: effectiveNow,
    );
    final budgetAdvance = await _maybeAdvanceStage4AfterBudget(
      state: advanced,
      config: config,
      nowLocal: effectiveNow,
    );
    if (budgetAdvance != null) {
      return budgetAdvance;
    }

    return ChainAttemptUpdate(
      state: advanced,
      telemetry: VerseAttemptTelemetry(
        stage: state.activeStage,
        hintLevel: effectiveHintLevel,
        latencyToStartMs: latencyToStartMs,
        stopsCount: stopsCount,
        selfCorrectionsCount: selfCorrectionsCount,
        evaluatorPassed: true,
        evaluatorConfidence: evaluation.confidence,
        evaluatorMode: evaluation.mode,
        revealedAfterAttempt: false,
        retrievalStrength: retrievalStrength,
        attemptType: attemptType,
        assisted: assisted,
        autoCheckType: autoCheckRequired ? autoPrompt.type.code : null,
        autoCheckResult:
            autoCheckRequired ? (autoEval.passed ? 'pass' : 'fail') : null,
        timeOnVerseMs: updatedVerse.stage4.timeOnVerseMs,
        timeOnChunkMs:
            advanced.stage4?.chunkElapsedMs ?? runtime.chunkElapsedMs,
        stage4Mode: attemptMode,
        stage4Phase: advanced.stage4?.phase ?? runtime.phase,
      ),
    );
  }

  Future<ChainRunState> _advanceStage4AfterPass({
    required ChainRunState state,
    required int passedVerseIndex,
    required bool countedPass,
    required ProgressiveRevealChainConfig config,
    required DateTime nowLocal,
  }) async {
    var runtime = state.stage4!;
    var verses = [...state.verses];

    var pendingRandomTargets = [...runtime.pendingRandomStartTargets];
    if (runtime.mode == Stage4Mode.randomStart && countedPass) {
      pendingRandomTargets.remove(passedVerseIndex);
    }

    var unresolvedTargets = _stage4UnresolvedTargets(
      state: state.copyWith(verses: verses),
      verses: verses,
      config: runtime.config,
    );

    if (runtime.phase == Stage4Phase.remediation) {
      if (countedPass) {
        final verse = verses[passedVerseIndex];
        verses[passedVerseIndex] = verse.copyWith(
          stage4: verse.stage4.copyWith(remediationNeeded: false),
        );
      }

      final pending = runtime.remediationTargets.where((index) {
        if (index < 0 || index >= verses.length) {
          return false;
        }
        return verses[index].stage4.remediationNeeded ||
            !_stage4IsReady(
              state: state,
              verse: verses[index],
              config: runtime.config,
            );
      }).toList(growable: false);

      if (pending.isNotEmpty) {
        final nextIndex = _nextIndexFromList(
          indexes: pending,
          startAfter: passedVerseIndex,
        );
        return state.copyWith(
          verses: verses,
          stage4: runtime.copyWith(
            phase: Stage4Phase.remediation,
            mode: Stage4Mode.remediation,
            pendingRandomStartTargets: pendingRandomTargets,
            unresolvedTargets: unresolvedTargets,
            remediationCursor: pending.indexOf(nextIndex),
            activeAutoCheckPrompt: _buildStage4AutoCheckPrompt(
              state: state.copyWith(verses: verses),
              verses: verses,
              verseIndex: nextIndex,
              mode: Stage4Mode.remediation,
            ),
          ),
          currentVerseIndex: nextIndex,
          currentHintLevel:
              _stage4EffectiveBaselineHint(verses[nextIndex].stage4),
          returnVerseIndex: null,
        );
      }

      if (runtime.remediationTargets.isNotEmpty) {
        final targets = runtime.remediationTargets;
        for (final index in targets) {
          final verse = verses[index];
          verses[index] = verse.copyWith(
            stage4: verse.stage4.copyWith(
              checkpointAttempted: false,
              checkpointPassed: false,
            ),
          );
        }
        final first = targets.first;
        return state.copyWith(
          verses: verses,
          stage4: runtime.copyWith(
            phase: Stage4Phase.checkpoint,
            mode: Stage4Mode.checkpoint,
            pendingRandomStartTargets: pendingRandomTargets,
            unresolvedTargets: unresolvedTargets,
            checkpointTargets: targets,
            checkpointCursor: 0,
            remediationTargets: const <int>[],
            remediationCursor: 0,
            activeAutoCheckPrompt: _buildStage4AutoCheckPrompt(
              state: state.copyWith(verses: verses),
              verses: verses,
              verseIndex: first,
              mode: Stage4Mode.checkpoint,
            ),
          ),
          currentVerseIndex: first,
          currentHintLevel: _stage4EffectiveBaselineHint(verses[first].stage4),
          returnVerseIndex: null,
        );
      }
    }

    if (runtime.phase == Stage4Phase.checkpoint) {
      final targets = runtime.checkpointTargets.isEmpty
          ? List<int>.generate(verses.length, (index) => index)
          : runtime.checkpointTargets;
      final nextCursor = runtime.checkpointCursor + 1;
      if (nextCursor < targets.length) {
        final nextIndex = targets[nextCursor];
        return state.copyWith(
          verses: verses,
          stage4: runtime.copyWith(
            phase: Stage4Phase.checkpoint,
            mode: Stage4Mode.checkpoint,
            checkpointTargets: targets,
            pendingRandomStartTargets: pendingRandomTargets,
            unresolvedTargets: unresolvedTargets,
            checkpointCursor: nextCursor,
            activeAutoCheckPrompt: _buildStage4AutoCheckPrompt(
              state: state.copyWith(verses: verses),
              verses: verses,
              verseIndex: nextIndex,
              mode: Stage4Mode.checkpoint,
            ),
          ),
          currentVerseIndex: nextIndex,
          currentHintLevel:
              _stage4EffectiveBaselineHint(verses[nextIndex].stage4),
          returnVerseIndex: null,
        );
      }

      final failed = <int>[
        for (final index in targets)
          if (!verses[index].stage4.checkpointPassed) index,
      ];
      final chunkPassRate = targets.isEmpty
          ? 0.0
          : (targets.length - failed.length) / targets.length;
      final randomStartSatisfied = verses.every(
        (verse) =>
            verse.stage4.randomStartPasses >=
            runtime.config.randomStartProbeCount,
      );
      final linkingSatisfied =
          verses.every((verse) => verse.stage4.linkingPassCount >= 1);
      final everyReady = verses.every(
        (verse) => _stage4IsReady(
          state: state,
          verse: verse,
          config: runtime.config,
        ),
      );
      unresolvedTargets = _stage4UnresolvedTargets(
        state: state.copyWith(verses: verses),
        verses: verses,
        config: runtime.config,
      );
      final passedCheckpoint =
          chunkPassRate >= runtime.config.checkpointThreshold &&
              randomStartSatisfied &&
              linkingSatisfied &&
              everyReady &&
              unresolvedTargets.isEmpty;
      final outcome = Stage4CheckpointOutcome(
        chunkPassRate: chunkPassRate,
        failedVerseIndexes: failed,
        everyVerseReady: everyReady,
        randomStartSatisfied: randomStartSatisfied,
        linkingSatisfied: linkingSatisfied,
        passed: passedCheckpoint,
      );

      if (passedCheckpoint) {
        return state.copyWith(
          verses: verses,
          stage4: runtime.copyWith(
            phase: Stage4Phase.completed,
            mode: Stage4Mode.checkpoint,
            pendingRandomStartTargets: pendingRandomTargets,
            unresolvedTargets: const <int>[],
            lastCheckpointOutcome: outcome,
            activeAutoCheckPrompt: null,
          ),
          currentHintLevel: HintLevel.h0,
          returnVerseIndex: null,
        );
      }

      if (runtime.remediationRounds >=
          runtime.config.maxCheckpointRemediationRounds) {
        final unresolvedRatio =
            verses.isEmpty ? 0.0 : failed.length / verses.length;
        final route =
            unresolvedRatio > runtime.config.failUnresolvedRatioThreshold
                ? 'broad_stage3'
                : 'targeted_stage3';
        return state.copyWith(
          verses: verses,
          stage4: runtime.copyWith(
            phase: Stage4Phase.failed,
            budgetExceeded: false,
            unresolvedTargets: failed,
            pendingRandomStartTargets: pendingRandomTargets,
            lastCheckpointOutcome: outcome,
            activeAutoCheckPrompt: null,
            mode: Stage4Mode.remediation,
            dueKind: '$route:${runtime.dueKind}',
          ),
          returnVerseIndex: null,
        );
      }

      for (final index in failed) {
        final verse = verses[index];
        verses[index] = verse.copyWith(
          stage4: verse.stage4.copyWith(
            remediationNeeded: true,
            weakTarget: true,
          ),
        );
      }
      final first = failed.first;
      return state.copyWith(
        verses: verses,
        stage4: runtime.copyWith(
          phase: Stage4Phase.remediation,
          mode: Stage4Mode.remediation,
          remediationRounds: runtime.remediationRounds + 1,
          unresolvedTargets: failed,
          pendingRandomStartTargets: pendingRandomTargets,
          remediationTargets: failed,
          remediationCursor: 0,
          lastCheckpointOutcome: outcome,
          activeAutoCheckPrompt: _buildStage4AutoCheckPrompt(
            state: state.copyWith(verses: verses),
            verses: verses,
            verseIndex: first,
            mode: Stage4Mode.remediation,
          ),
        ),
        currentVerseIndex: first,
        currentHintLevel: _stage4EffectiveBaselineHint(verses[first].stage4),
        returnVerseIndex: null,
      );
    }

    unresolvedTargets = _stage4UnresolvedTargets(
      state: state.copyWith(verses: verses),
      verses: verses,
      config: runtime.config,
    );

    final allReady = unresolvedTargets.isEmpty &&
        pendingRandomTargets.isEmpty &&
        verses.every((verse) => verse.stage4.linkingPassCount >= 1);
    if (allReady) {
      final targets = List<int>.generate(verses.length, (index) => index);
      for (final index in targets) {
        final verse = verses[index];
        verses[index] = verse.copyWith(
          stage4: verse.stage4.copyWith(
            checkpointAttempted: false,
            checkpointPassed: false,
          ),
        );
      }
      final first = targets.first;
      return state.copyWith(
        verses: verses,
        stage4: runtime.copyWith(
          phase: Stage4Phase.checkpoint,
          mode: Stage4Mode.checkpoint,
          unresolvedTargets: unresolvedTargets,
          pendingRandomStartTargets: pendingRandomTargets,
          checkpointTargets: targets,
          checkpointCursor: 0,
          activeAutoCheckPrompt: _buildStage4AutoCheckPrompt(
            state: state.copyWith(verses: verses),
            verses: verses,
            verseIndex: first,
            mode: Stage4Mode.checkpoint,
          ),
        ),
        currentVerseIndex: first,
        currentHintLevel: _stage4EffectiveBaselineHint(verses[first].stage4),
        returnVerseIndex: null,
      );
    }

    final nextState = state.copyWith(verses: verses);
    final target = _pickStage4Target(
      state: nextState.copyWith(stage4: runtime),
      verses: verses,
      startAfter: passedVerseIndex,
      runtime: runtime.copyWith(
        unresolvedTargets: unresolvedTargets,
        pendingRandomStartTargets: pendingRandomTargets,
      ),
    );
    if (target == null) {
      return nextState.copyWith(
        stage4: runtime.copyWith(
          phase: Stage4Phase.verification,
          mode: Stage4Mode.coldStart,
          unresolvedTargets: unresolvedTargets,
          pendingRandomStartTargets: pendingRandomTargets,
          activeAutoCheckPrompt: null,
        ),
      );
    }

    return nextState.copyWith(
      stage4: runtime.copyWith(
        phase: target.phase,
        mode: target.mode,
        unresolvedTargets: unresolvedTargets,
        pendingRandomStartTargets: pendingRandomTargets,
        activeAutoCheckPrompt: target.mode == Stage4Mode.correction
            ? null
            : _buildStage4AutoCheckPrompt(
                state: nextState,
                verses: verses,
                verseIndex: target.verseIndex,
                mode: target.mode,
              ),
      ),
      currentVerseIndex: target.verseIndex,
      currentHintLevel: _stage4EffectiveBaselineHint(
        verses[target.verseIndex].stage4,
      ),
      returnVerseIndex: null,
    );
  }

  Future<ChainAttemptUpdate?> _maybeAdvanceStage4AfterBudget({
    required ChainRunState state,
    required ProgressiveRevealChainConfig config,
    required DateTime nowLocal,
  }) async {
    final runtime = state.stage4;
    if (runtime == null) {
      return null;
    }
    if (runtime.phase == Stage4Phase.completed && !state.completed) {
      return _finalizeStage4Result(
        state: state,
        outcome: 'pass',
        resultKind: ChainResultKind.completed,
        nowLocal: nowLocal,
      );
    }
    if (runtime.phase == Stage4Phase.failed && !state.completed) {
      return _finalizeStage4Result(
        state: state,
        outcome: 'fail',
        resultKind: ChainResultKind.partial,
        nowLocal: nowLocal,
      );
    }
    if (runtime.phase == Stage4Phase.budgetFallback && !state.completed) {
      return _finalizeStage4Result(
        state: state,
        outcome: 'partial',
        resultKind: ChainResultKind.partial,
        nowLocal: nowLocal,
      );
    }
    if (runtime.chunkElapsedMs < runtime.stage4BudgetMs) {
      return null;
    }

    final unresolved = _stage4UnresolvedTargets(
      state: state,
      verses: state.verses,
      config: runtime.config,
    );
    if (unresolved.isNotEmpty) {
      final nextState = state.copyWith(
        stage4: runtime.copyWith(
          phase: Stage4Phase.budgetFallback,
          budgetExceeded: true,
          unresolvedTargets: unresolved,
          activeAutoCheckPrompt: null,
        ),
      );
      return _finalizeStage4Result(
        state: nextState,
        outcome: 'partial',
        resultKind: ChainResultKind.partial,
        nowLocal: nowLocal,
      );
    }

    return _finalizeStage4Result(
      state: state.copyWith(
        stage4: runtime.copyWith(
          phase: Stage4Phase.completed,
          activeAutoCheckPrompt: null,
        ),
      ),
      outcome: 'pass',
      resultKind: ChainResultKind.completed,
      nowLocal: nowLocal,
    );
  }

  Future<ChainAttemptUpdate> _finalizeStage4Result({
    required ChainRunState state,
    required String outcome,
    required ChainResultKind resultKind,
    required DateTime nowLocal,
  }) async {
    final runtime = state.stage4!;
    final unresolved = _stage4UnresolvedTargets(
      state: state,
      verses: state.verses,
      config: runtime.config,
    );
    final summary = await _completeSession(
      state: state,
      verseStates: state.verses,
      nowLocal: nowLocal,
      resultKind: resultKind,
    );

    if (runtime.stage4SessionRecordId != null) {
      final passRate = state.verses.isEmpty
          ? 0.0
          : state.verses
                  .where(
                    (verse) => _stage4IsReady(
                      state: state,
                      verse: verse,
                      config: runtime.config,
                    ),
                  )
                  .length /
              state.verses.length;
      await _companionRepo.completeStage4Session(
        sessionId: runtime.stage4SessionRecordId!,
        outcome: outcome,
        endedDay: localDayIndex(nowLocal),
        endedSeconds: nowLocalSecondsSinceMidnight(nowLocal),
        countedPassRate: passRate,
        randomStartPasses: state.verses
            .fold<int>(0, (sum, verse) => sum + verse.stage4.randomStartPasses),
        linkingPasses: state.verses
            .fold<int>(0, (sum, verse) => sum + verse.stage4.linkingPassCount),
        discriminationPasses: state.verses.fold<int>(
          0,
          (sum, verse) => sum + verse.stage4.discriminationPasses,
        ),
        unresolvedTargetsJson:
            unresolved.isEmpty ? null : jsonEncode(unresolved),
        telemetryJson: jsonEncode(<String, Object?>{
          'lifecycle_stage': 'stage4',
          'stage4_phase': state.stage4?.phase.code,
          'stage4_mode': state.stage4?.mode.code,
          'lifecycle_hook':
              outcome == 'pass' ? 'stage5_candidate' : 'stage4_retry',
        }),
      );
    }

    final unresolvedRatio =
        state.verses.isEmpty ? 0.0 : unresolved.length / state.verses.length;
    final strengtheningRoute =
        unresolvedRatio > runtime.config.failUnresolvedRatioThreshold
            ? 'broad_stage3'
            : 'targeted_stage3';
    final status = switch (outcome) {
      'pass' => 'passed',
      'partial' => 'partial',
      'fail' => 'failed',
      _ => 'partial',
    };

    await _companionRepo.upsertLifecycleState(
      unitId: state.unitId,
      lifecycleTier: Value(outcome == 'pass' ? 'stable' : 'ready'),
      stage4Status: Value(status),
      stage4UnresolvedTargetsJson:
          Value(unresolved.isEmpty ? null : jsonEncode(unresolved)),
      stage4StrengtheningRoute:
          Value(outcome == 'pass' ? null : strengtheningRoute),
      stage4LastOutcome: Value(outcome),
      stage4LastSessionId: Value(runtime.stage4SessionRecordId),
      stage4LastCompletedDay:
          Value(outcome == 'pass' ? localDayIndex(nowLocal) : null),
      stage4RetryDueDay:
          Value(outcome == 'pass' ? null : localDayIndex(nowLocal) + 1),
      updatedAtDay: localDayIndex(nowLocal),
      updatedAtSeconds: nowLocalSecondsSinceMidnight(nowLocal),
    );

    return ChainAttemptUpdate(
      state: state.copyWith(
        completed: true,
        resultKind: resultKind,
        currentHintLevel: HintLevel.h0,
        returnVerseIndex: null,
      ),
      telemetry: VerseAttemptTelemetry(
        stage: CompanionStage.hiddenReveal,
        hintLevel: HintLevel.h0,
        latencyToStartMs: 0,
        stopsCount: 0,
        selfCorrectionsCount: 0,
        evaluatorPassed: outcome == 'pass',
        evaluatorConfidence: null,
        evaluatorMode: EvaluatorMode.manualFallback,
        revealedAfterAttempt: false,
        retrievalStrength: 0.0,
        attemptType: 'checkpoint',
        assisted: false,
        timeOnVerseMs:
            state.verses[state.currentVerseIndex].stage4.timeOnVerseMs,
        timeOnChunkMs: runtime.chunkElapsedMs,
        stage4Mode: runtime.mode,
        stage4Phase: runtime.phase,
      ),
      summary: summary,
    );
  }

  Future<ChainRunState> _advanceStage2AfterPass({
    required ChainRunState state,
    required int passedVerseIndex,
    required bool countedPass,
    required ProgressiveRevealChainConfig config,
    required DateTime nowLocal,
  }) async {
    var runtime = state.stage2!;
    var verses = [...state.verses];

    if (runtime.phase == Stage2Phase.remediation) {
      if (countedPass) {
        final verse = verses[passedVerseIndex];
        verses[passedVerseIndex] = verse.copyWith(
          stage2: verse.stage2.copyWith(
            remediationNeeded: false,
          ),
        );
      }

      final pending = runtime.remediationTargets.where((index) {
        if (index < 0 || index >= verses.length) {
          return false;
        }
        return verses[index].stage2.remediationNeeded ||
            !_stage2IsReady(verses[index], runtime.config);
      }).toList(growable: false);

      if (pending.isNotEmpty) {
        final nextIndex = _nextIndexFromList(
          indexes: pending,
          startAfter: passedVerseIndex,
        );
        final nextVerse = verses[nextIndex];
        return state.copyWith(
          verses: verses,
          stage2: runtime.copyWith(
            mode: Stage2Mode.remediation,
            remediationCursor: (() {
              final cursor = runtime.remediationTargets.indexOf(nextIndex);
              return cursor < 0 ? 0 : cursor;
            })(),
            activeAutoCheckPrompt: _buildStage2AutoCheckPrompt(
              state: state.copyWith(verses: verses),
              verses: verses,
              verseIndex: nextIndex,
              mode: Stage2Mode.remediation,
            ),
          ),
          currentVerseIndex: nextIndex,
          currentHintLevel: _stage2EffectiveBaselineHint(nextVerse.stage2),
          returnVerseIndex: null,
        );
      }

      final targets = runtime.remediationTargets;
      for (final index in targets) {
        final verse = verses[index];
        verses[index] = verse.copyWith(
          stage2: verse.stage2.copyWith(
            checkpointAttempted: false,
            checkpointPassed: false,
          ),
        );
      }
      final first = targets.first;
      final firstVerse = verses[first];
      return state.copyWith(
        verses: verses,
        stage2: runtime.copyWith(
          phase: Stage2Phase.checkpoint,
          mode: Stage2Mode.checkpoint,
          checkpointTargets: targets,
          checkpointCursor: 0,
          remediationTargets: const <int>[],
          remediationCursor: 0,
          activeAutoCheckPrompt: _buildStage2AutoCheckPrompt(
            state: state.copyWith(verses: verses),
            verses: verses,
            verseIndex: first,
            mode: Stage2Mode.checkpoint,
          ),
        ),
        currentVerseIndex: first,
        currentHintLevel: _stage2EffectiveBaselineHint(firstVerse.stage2),
        returnVerseIndex: null,
      );
    }

    if (runtime.phase == Stage2Phase.checkpoint) {
      final targets = runtime.checkpointTargets.isEmpty
          ? List<int>.generate(verses.length, (index) => index)
          : runtime.checkpointTargets;
      final nextCursor = runtime.checkpointCursor + 1;
      if (nextCursor < targets.length) {
        final nextIndex = targets[nextCursor];
        return state.copyWith(
          verses: verses,
          stage2: runtime.copyWith(
            checkpointTargets: targets,
            checkpointCursor: nextCursor,
            mode: Stage2Mode.checkpoint,
            activeAutoCheckPrompt: _buildStage2AutoCheckPrompt(
              state: state.copyWith(verses: verses),
              verses: verses,
              verseIndex: nextIndex,
              mode: Stage2Mode.checkpoint,
            ),
          ),
          currentVerseIndex: nextIndex,
          currentHintLevel:
              _stage2EffectiveBaselineHint(verses[nextIndex].stage2),
          returnVerseIndex: null,
        );
      }

      final failed = <int>[
        for (final index in targets)
          if (!verses[index].stage2.checkpointPassed) index,
      ];
      final chunkPassRate = targets.isEmpty
          ? 0.0
          : (targets.length - failed.length) / targets.length;
      final everyReady =
          verses.every((verse) => _stage2IsReady(verse, runtime.config));
      final checkpointPassed =
          chunkPassRate >= runtime.config.checkpointThreshold && everyReady;
      final outcome = Stage2CheckpointOutcome(
        chunkPassRate: chunkPassRate,
        failedVerseIndexes: failed,
        everyVerseReady: everyReady,
        passed: checkpointPassed,
      );

      if (checkpointPassed) {
        return _advanceFromStage2ToStage3(
          state: state.copyWith(
            verses: verses,
            stage2: runtime.copyWith(
              phase: Stage2Phase.completed,
              lastCheckpointOutcome: outcome,
              activeAutoCheckPrompt: null,
            ),
          ),
          config: config,
          nowLocal: nowLocal,
          weakPreludeTargets: const <int>[],
          budgetFallback: false,
        );
      }

      if (runtime.remediationRounds >=
          runtime.config.maxCheckpointRemediationRounds) {
        for (final index in failed) {
          final verse = verses[index];
          verses[index] = verse.copyWith(
            stage2: verse.stage2.copyWith(
              weakTarget: true,
              remediationNeeded: true,
            ),
          );
        }
        final unresolved = _stage2UnresolvedWeakTargets(
          verses: verses,
          config: runtime.config,
        );
        return _advanceFromStage2ToStage3(
          state: state.copyWith(
            verses: verses,
            stage2: runtime.copyWith(
              phase: Stage2Phase.budgetFallback,
              budgetExceeded: true,
              lastCheckpointOutcome: outcome,
              activeAutoCheckPrompt: null,
            ),
          ),
          config: config,
          nowLocal: nowLocal,
          weakPreludeTargets: unresolved,
          budgetFallback: true,
        );
      }

      for (final index in failed) {
        final verse = verses[index];
        verses[index] = verse.copyWith(
          stage2: verse.stage2.copyWith(
            weakTarget: true,
            remediationNeeded: true,
          ),
        );
      }
      final first = failed.first;
      return state.copyWith(
        verses: verses,
        stage2: runtime.copyWith(
          phase: Stage2Phase.remediation,
          mode: Stage2Mode.remediation,
          remediationRounds: runtime.remediationRounds + 1,
          remediationTargets: failed,
          remediationCursor: 0,
          lastCheckpointOutcome: outcome,
          activeAutoCheckPrompt: _buildStage2AutoCheckPrompt(
            state: state.copyWith(verses: verses),
            verses: verses,
            verseIndex: first,
            mode: Stage2Mode.remediation,
          ),
        ),
        currentVerseIndex: first,
        currentHintLevel: _stage2EffectiveBaselineHint(verses[first].stage2),
        returnVerseIndex: null,
      );
    }

    final allReady =
        verses.every((verse) => _stage2IsReady(verse, runtime.config));
    if (allReady) {
      final targets = List<int>.generate(verses.length, (index) => index);
      for (final index in targets) {
        final verse = verses[index];
        verses[index] = verse.copyWith(
          stage2: verse.stage2.copyWith(
            checkpointAttempted: false,
            checkpointPassed: false,
          ),
        );
      }
      final first = targets.first;
      return state.copyWith(
        verses: verses,
        stage2: runtime.copyWith(
          phase: Stage2Phase.checkpoint,
          mode: Stage2Mode.checkpoint,
          checkpointTargets: targets,
          checkpointCursor: 0,
          activeAutoCheckPrompt: _buildStage2AutoCheckPrompt(
            state: state.copyWith(verses: verses),
            verses: verses,
            verseIndex: first,
            mode: Stage2Mode.checkpoint,
          ),
        ),
        currentVerseIndex: first,
        currentHintLevel: _stage2EffectiveBaselineHint(verses[first].stage2),
        returnVerseIndex: null,
      );
    }

    final target = _pickStage2Target(
      verses: verses,
      startAfter: passedVerseIndex,
      runtime: runtime,
    );
    if (target == null) {
      return state.copyWith(
        verses: verses,
        stage2: runtime.copyWith(
          mode: Stage2Mode.minimalCueRecall,
          activeAutoCheckPrompt: null,
        ),
      );
    }
    final nextVerse = verses[target.verseIndex];
    return state.copyWith(
      verses: verses,
      stage2: runtime.copyWith(
        mode: target.mode,
        activeAutoCheckPrompt: target.mode == Stage2Mode.correction
            ? null
            : _buildStage2AutoCheckPrompt(
                state: state.copyWith(verses: verses),
                verses: verses,
                verseIndex: target.verseIndex,
                mode: target.mode,
              ),
      ),
      currentVerseIndex: target.verseIndex,
      currentHintLevel: _stage2EffectiveBaselineHint(nextVerse.stage2),
      returnVerseIndex: null,
    );
  }

  Future<ChainAttemptUpdate?> _maybeAdvanceStage2AfterBudget({
    required ChainRunState state,
    required ProgressiveRevealChainConfig config,
    required DateTime nowLocal,
  }) async {
    final runtime = state.stage2;
    if (runtime == null || runtime.chunkElapsedMs < runtime.stage2BudgetMs) {
      return null;
    }

    final verses = [...state.verses];
    final unresolved = _stage2UnresolvedWeakTargets(
      verses: verses,
      config: runtime.config,
    );
    if (unresolved.isNotEmpty) {
      for (final index in unresolved) {
        final verse = verses[index];
        verses[index] = verse.copyWith(
          stage2: verse.stage2.copyWith(
            weakTarget: true,
            remediationNeeded: true,
          ),
        );
      }
    }

    final advanced = await _advanceFromStage2ToStage3(
      state: state.copyWith(
        verses: verses,
        stage2: runtime.copyWith(
          phase: unresolved.isEmpty
              ? Stage2Phase.completed
              : Stage2Phase.budgetFallback,
          budgetExceeded: unresolved.isNotEmpty,
          activeAutoCheckPrompt: null,
        ),
      ),
      config: config,
      nowLocal: nowLocal,
      weakPreludeTargets: unresolved,
      budgetFallback: unresolved.isNotEmpty,
    );
    return ChainAttemptUpdate(
      state: advanced,
      telemetry: VerseAttemptTelemetry(
        stage: CompanionStage.cuedRecall,
        hintLevel: HintLevel.h0,
        latencyToStartMs: 0,
        stopsCount: 0,
        selfCorrectionsCount: 0,
        evaluatorPassed: unresolved.isEmpty,
        evaluatorConfidence: null,
        evaluatorMode: EvaluatorMode.manualFallback,
        revealedAfterAttempt: false,
        retrievalStrength: 0.0,
        attemptType: 'checkpoint',
        assisted: false,
        timeOnVerseMs: 0,
        timeOnChunkMs: runtime.chunkElapsedMs,
        stage2Mode: Stage2Mode.checkpoint,
        stage2Phase: unresolved.isEmpty
            ? Stage2Phase.completed
            : Stage2Phase.budgetFallback,
      ),
    );
  }

  Future<ChainRunState> _advanceStage3AfterPass({
    required ChainRunState state,
    required int passedVerseIndex,
    required bool countedPass,
    required ProgressiveRevealChainConfig config,
    required DateTime nowLocal,
  }) async {
    var runtime = state.stage3!;
    var verses = [...state.verses];
    var weakPreludeTargets = [...state.stage3WeakPreludeTargets];
    var weakPreludeCursor = state.stage3WeakPreludeCursor;

    if (runtime.mode == Stage3Mode.weakPrelude &&
        weakPreludeTargets.isNotEmpty) {
      if (countedPass) {
        weakPreludeTargets.remove(passedVerseIndex);
        if (weakPreludeCursor >= weakPreludeTargets.length) {
          weakPreludeCursor = 0;
        }
      } else if (weakPreludeTargets.length > 1) {
        weakPreludeCursor = (weakPreludeCursor + 1) % weakPreludeTargets.length;
      }
    }

    if (runtime.phase == Stage3Phase.remediation) {
      if (countedPass) {
        final verse = verses[passedVerseIndex];
        verses[passedVerseIndex] = verse.copyWith(
          stage3: verse.stage3.copyWith(
            remediationNeeded: false,
          ),
        );
      }

      final pending = runtime.remediationTargets.where((index) {
        if (index < 0 || index >= verses.length) {
          return false;
        }
        return verses[index].stage3.remediationNeeded ||
            !_stage3IsReady(
              state: state.copyWith(
                verses: verses,
                stage3WeakPreludeTargets: weakPreludeTargets,
              ),
              verse: verses[index],
              config: runtime.config,
            );
      }).toList(growable: false);
      if (pending.isNotEmpty) {
        final nextIndex = _nextIndexFromList(
          indexes: pending,
          startAfter: passedVerseIndex,
        );
        final nextVerse = verses[nextIndex];
        return state.copyWith(
          verses: verses,
          stage3: runtime.copyWith(
            phase: Stage3Phase.remediation,
            mode: Stage3Mode.remediation,
            remediationCursor: pending.indexOf(nextIndex),
            activeAutoCheckPrompt: _buildStage3AutoCheckPrompt(
              state: state.copyWith(verses: verses),
              verses: verses,
              verseIndex: nextIndex,
              mode: Stage3Mode.remediation,
            ),
          ),
          stage3WeakPreludeTargets: weakPreludeTargets,
          stage3WeakPreludeCursor: weakPreludeCursor,
          currentVerseIndex: nextIndex,
          currentHintLevel: _stage3EffectiveBaselineHint(
            nextVerse.stage3,
            capAtH1: weakPreludeTargets.isNotEmpty,
          ),
          returnVerseIndex: null,
        );
      }

      final targets = runtime.remediationTargets;
      if (targets.isNotEmpty) {
        for (final index in targets) {
          final verse = verses[index];
          verses[index] = verse.copyWith(
            stage3: verse.stage3.copyWith(
              checkpointAttempted: false,
              checkpointPassed: false,
            ),
          );
        }
        final first = targets.first;
        return state.copyWith(
          verses: verses,
          stage3: runtime.copyWith(
            phase: Stage3Phase.checkpoint,
            mode: Stage3Mode.checkpoint,
            checkpointTargets: targets,
            checkpointCursor: 0,
            remediationTargets: const <int>[],
            remediationCursor: 0,
            activeAutoCheckPrompt: _buildStage3AutoCheckPrompt(
              state: state.copyWith(verses: verses),
              verses: verses,
              verseIndex: first,
              mode: Stage3Mode.checkpoint,
            ),
          ),
          stage3WeakPreludeTargets: weakPreludeTargets,
          stage3WeakPreludeCursor: weakPreludeCursor,
          currentVerseIndex: first,
          currentHintLevel: _stage3EffectiveBaselineHint(
            verses[first].stage3,
            capAtH1: weakPreludeTargets.isNotEmpty,
          ),
          returnVerseIndex: null,
        );
      }
    }

    if (runtime.phase == Stage3Phase.checkpoint) {
      final targets = runtime.checkpointTargets.isEmpty
          ? List<int>.generate(verses.length, (index) => index)
          : runtime.checkpointTargets;
      final nextCursor = runtime.checkpointCursor + 1;
      if (nextCursor < targets.length) {
        final nextIndex = targets[nextCursor];
        final nextVerse = verses[nextIndex];
        return state.copyWith(
          verses: verses,
          stage3: runtime.copyWith(
            phase: Stage3Phase.checkpoint,
            mode: Stage3Mode.checkpoint,
            checkpointTargets: targets,
            checkpointCursor: nextCursor,
            activeAutoCheckPrompt: _buildStage3AutoCheckPrompt(
              state: state.copyWith(verses: verses),
              verses: verses,
              verseIndex: nextIndex,
              mode: Stage3Mode.checkpoint,
            ),
          ),
          stage3WeakPreludeTargets: weakPreludeTargets,
          stage3WeakPreludeCursor: weakPreludeCursor,
          currentVerseIndex: nextIndex,
          currentHintLevel: _stage3EffectiveBaselineHint(
            nextVerse.stage3,
            capAtH1: weakPreludeTargets.isNotEmpty,
          ),
          returnVerseIndex: null,
        );
      }

      final failed = <int>[
        for (final index in targets)
          if (!verses[index].stage3.checkpointPassed) index,
      ];
      final chunkPassRate = targets.isEmpty
          ? 0.0
          : (targets.length - failed.length) / targets.length;
      final everyReady = verses.every(
        (verse) => _stage3IsReady(
          state: state.copyWith(
            verses: verses,
            stage3WeakPreludeTargets: weakPreludeTargets,
          ),
          verse: verse,
          config: runtime.config,
        ),
      );
      final weakPreludeCleared = weakPreludeTargets.isEmpty;
      final checkpointPassed =
          chunkPassRate >= runtime.config.checkpointThreshold &&
              everyReady &&
              weakPreludeCleared;
      final outcome = Stage3CheckpointOutcome(
        chunkPassRate: chunkPassRate,
        failedVerseIndexes: failed,
        everyVerseReady: everyReady,
        weakPreludeCleared: weakPreludeCleared,
        passed: checkpointPassed,
      );

      if (checkpointPassed) {
        final completedVerses = <ChainVerseState>[
          for (final verse in verses)
            verse.passed
                ? verse
                : verse.markPassedForStage(CompanionStage.hiddenReveal),
        ];
        return state.copyWith(
          verses: completedVerses,
          stage3: runtime.copyWith(
            phase: Stage3Phase.completed,
            mode: Stage3Mode.checkpoint,
            lastCheckpointOutcome: outcome,
            activeAutoCheckPrompt: null,
          ),
          stage3WeakPreludeTargets: weakPreludeTargets,
          stage3WeakPreludeCursor: weakPreludeCursor,
          currentHintLevel: HintLevel.h0,
          returnVerseIndex: null,
        );
      }

      if (runtime.remediationRounds >=
          runtime.config.maxCheckpointRemediationRounds) {
        for (final index in failed) {
          final verse = verses[index];
          verses[index] = verse.copyWith(
            stage3: verse.stage3.copyWith(
              weakTarget: true,
              remediationNeeded: true,
            ),
          );
        }
        final unresolved = _stage3UnresolvedWeakTargets(
          state: state.copyWith(
            verses: verses,
            stage3WeakPreludeTargets: weakPreludeTargets,
          ),
          verses: verses,
          config: runtime.config,
        );
        return state.copyWith(
          verses: verses,
          stage3: runtime.copyWith(
            phase: Stage3Phase.budgetFallback,
            budgetExceeded: true,
            lastCheckpointOutcome: outcome,
            activeAutoCheckPrompt: null,
          ),
          stage3WeakPreludeTargets:
              unresolved.isEmpty ? weakPreludeTargets : unresolved,
          stage3WeakPreludeCursor: 0,
          returnVerseIndex: null,
        );
      }

      for (final index in failed) {
        final verse = verses[index];
        verses[index] = verse.copyWith(
          stage3: verse.stage3.copyWith(
            weakTarget: true,
            remediationNeeded: true,
          ),
        );
      }
      final first = failed.first;
      return state.copyWith(
        verses: verses,
        stage3: runtime.copyWith(
          phase: Stage3Phase.remediation,
          mode: Stage3Mode.remediation,
          remediationRounds: runtime.remediationRounds + 1,
          remediationTargets: failed,
          remediationCursor: 0,
          lastCheckpointOutcome: outcome,
          activeAutoCheckPrompt: _buildStage3AutoCheckPrompt(
            state: state.copyWith(verses: verses),
            verses: verses,
            verseIndex: first,
            mode: Stage3Mode.remediation,
          ),
        ),
        stage3WeakPreludeTargets: weakPreludeTargets,
        stage3WeakPreludeCursor: 0,
        currentVerseIndex: first,
        currentHintLevel: _stage3EffectiveBaselineHint(
          verses[first].stage3,
          capAtH1: weakPreludeTargets.isNotEmpty,
        ),
        returnVerseIndex: null,
      );
    }

    final allReady = verses.every(
      (verse) => _stage3IsReady(
        state: state.copyWith(
          verses: verses,
          stage3WeakPreludeTargets: weakPreludeTargets,
        ),
        verse: verse,
        config: runtime.config,
      ),
    );
    if (allReady && weakPreludeTargets.isEmpty) {
      final targets = List<int>.generate(verses.length, (index) => index);
      for (final index in targets) {
        final verse = verses[index];
        verses[index] = verse.copyWith(
          stage3: verse.stage3.copyWith(
            checkpointAttempted: false,
            checkpointPassed: false,
          ),
        );
      }
      final first = targets.first;
      return state.copyWith(
        verses: verses,
        stage3: runtime.copyWith(
          phase: Stage3Phase.checkpoint,
          mode: Stage3Mode.checkpoint,
          checkpointTargets: targets,
          checkpointCursor: 0,
          activeAutoCheckPrompt: _buildStage3AutoCheckPrompt(
            state: state.copyWith(verses: verses),
            verses: verses,
            verseIndex: first,
            mode: Stage3Mode.checkpoint,
          ),
        ),
        stage3WeakPreludeTargets: weakPreludeTargets,
        stage3WeakPreludeCursor: 0,
        currentVerseIndex: first,
        currentHintLevel: _stage3EffectiveBaselineHint(
          verses[first].stage3,
          capAtH1: false,
        ),
        returnVerseIndex: null,
      );
    }

    final nextState = state.copyWith(
      verses: verses,
      stage3WeakPreludeTargets: weakPreludeTargets,
      stage3WeakPreludeCursor: weakPreludeCursor,
    );
    final target = _pickStage3Target(
      state: nextState,
      verses: verses,
      startAfter: passedVerseIndex,
      runtime: runtime,
    );
    if (target == null) {
      return nextState.copyWith(
        stage3: runtime.copyWith(
          phase: weakPreludeTargets.isNotEmpty
              ? Stage3Phase.prelude
              : Stage3Phase.acquisition,
          mode: weakPreludeTargets.isNotEmpty
              ? Stage3Mode.weakPrelude
              : Stage3Mode.hiddenRecall,
          activeAutoCheckPrompt: null,
        ),
      );
    }

    final nextVerse = verses[target.verseIndex];
    final capAtH1 =
        weakPreludeTargets.isNotEmpty || target.mode == Stage3Mode.weakPrelude;
    return nextState.copyWith(
      stage3: runtime.copyWith(
        phase: target.phase,
        mode: target.mode,
        activeAutoCheckPrompt: target.mode == Stage3Mode.correction
            ? null
            : _buildStage3AutoCheckPrompt(
                state: nextState,
                verses: verses,
                verseIndex: target.verseIndex,
                mode: target.mode,
              ),
      ),
      currentVerseIndex: target.verseIndex,
      currentHintLevel: _stage3EffectiveBaselineHint(
        nextVerse.stage3,
        capAtH1: capAtH1,
      ),
      returnVerseIndex: null,
    );
  }

  Future<ChainAttemptUpdate?> _maybeAdvanceStage3AfterBudget({
    required ChainRunState state,
    required ProgressiveRevealChainConfig config,
    required DateTime nowLocal,
  }) async {
    final runtime = state.stage3;
    if (runtime == null) {
      return null;
    }
    if (runtime.phase == Stage3Phase.completed && !state.completed) {
      return _finalizeStage3Result(
        state: state,
        resultKind: ChainResultKind.completed,
        nowLocal: nowLocal,
      );
    }
    if (runtime.phase == Stage3Phase.budgetFallback || runtime.budgetExceeded) {
      return null;
    }
    if (runtime.chunkElapsedMs < runtime.stage3BudgetMs) {
      return null;
    }

    final verses = [...state.verses];
    final unresolved = _stage3UnresolvedWeakTargets(
      state: state,
      verses: verses,
      config: runtime.config,
    );
    if (unresolved.isNotEmpty) {
      for (final index in unresolved) {
        final verse = verses[index];
        verses[index] = verse.copyWith(
          stage3: verse.stage3.copyWith(
            weakTarget: true,
            remediationNeeded: true,
          ),
        );
      }
      final nextIndex = unresolved.first;
      final nextState = state.copyWith(
        verses: verses,
        stage3: runtime.copyWith(
          phase: Stage3Phase.budgetFallback,
          mode: Stage3Mode.weakPrelude,
          budgetExceeded: true,
          activeAutoCheckPrompt: _buildStage3AutoCheckPrompt(
            state: state.copyWith(verses: verses),
            verses: verses,
            verseIndex: nextIndex,
            mode: Stage3Mode.weakPrelude,
          ),
        ),
        stage3WeakPreludeTargets: unresolved,
        stage3WeakPreludeCursor: 0,
        currentVerseIndex: nextIndex,
        currentHintLevel: HintLevel.letters,
        returnVerseIndex: null,
      );
      return ChainAttemptUpdate(
        state: nextState,
        telemetry: VerseAttemptTelemetry(
          stage: CompanionStage.hiddenReveal,
          hintLevel: HintLevel.letters,
          latencyToStartMs: 0,
          stopsCount: 0,
          selfCorrectionsCount: 0,
          evaluatorPassed: false,
          evaluatorConfidence: null,
          evaluatorMode: EvaluatorMode.manualFallback,
          revealedAfterAttempt: false,
          retrievalStrength: 0.0,
          attemptType: 'checkpoint',
          assisted: false,
          timeOnVerseMs: verses[nextIndex].stage3.timeOnVerseMs,
          timeOnChunkMs: runtime.chunkElapsedMs,
          stage3Mode: Stage3Mode.weakPrelude,
          stage3Phase: Stage3Phase.budgetFallback,
        ),
      );
    }

    return _finalizeStage3Result(
      state: state.copyWith(
        verses: verses,
        stage3: runtime.copyWith(
          phase: Stage3Phase.completed,
          activeAutoCheckPrompt: null,
        ),
      ),
      resultKind: ChainResultKind.completed,
      nowLocal: nowLocal,
    );
  }

  Future<ChainAttemptUpdate> _finalizeStage3Result({
    required ChainRunState state,
    required ChainResultKind resultKind,
    required DateTime nowLocal,
  }) async {
    final finalizedVerses = resultKind == ChainResultKind.completed
        ? <ChainVerseState>[
            for (final verse in state.verses)
              verse.passed
                  ? verse
                  : verse.markPassedForStage(CompanionStage.hiddenReveal),
          ]
        : state.verses;

    await _scheduleStage4AfterStage3(
      state: state.copyWith(verses: finalizedVerses),
      resultKind: resultKind,
      nowLocal: nowLocal,
    );

    final summary = await _completeSession(
      state: state.copyWith(verses: finalizedVerses),
      verseStates: finalizedVerses,
      nowLocal: nowLocal,
      resultKind: resultKind,
    );
    return ChainAttemptUpdate(
      state: state.copyWith(
        verses: finalizedVerses,
        completed: true,
        resultKind: resultKind,
        currentHintLevel: HintLevel.h0,
        returnVerseIndex: null,
      ),
      telemetry: VerseAttemptTelemetry(
        stage: CompanionStage.hiddenReveal,
        hintLevel: HintLevel.h0,
        latencyToStartMs: 0,
        stopsCount: 0,
        selfCorrectionsCount: 0,
        evaluatorPassed: resultKind == ChainResultKind.completed,
        evaluatorConfidence: null,
        evaluatorMode: EvaluatorMode.manualFallback,
        revealedAfterAttempt: false,
        retrievalStrength: 0.0,
        attemptType: 'checkpoint',
        assisted: false,
        timeOnVerseMs:
            state.verses[state.currentVerseIndex].stage3.timeOnVerseMs,
        timeOnChunkMs: state.stage3?.chunkElapsedMs ?? 0,
        stage3Mode: state.stage3?.mode,
        stage3Phase: state.stage3?.phase,
      ),
      summary: summary,
    );
  }

  Future<void> _scheduleStage4AfterStage3({
    required ChainRunState state,
    required ChainResultKind resultKind,
    required DateTime nowLocal,
  }) async {
    if (state.launchMode != CompanionLaunchMode.newMemorization ||
        resultKind != ChainResultKind.completed) {
      return;
    }
    final stage3 = state.stage3;
    if (stage3 == null) {
      return;
    }

    final unresolved = _stage3UnresolvedWeakTargets(
      state: state,
      verses: state.verses,
      config: stage3.config,
    );
    final unresolvedRatio =
        state.verses.isEmpty ? 0.0 : unresolved.length / state.verses.length;
    final day = localDayIndex(nowLocal);
    final preSleepDueDay = nowLocal.hour < 20 ? day : null;
    final nextDayDueDay = day + 1;
    final status = unresolvedRatio > 0.30 ? 'needs_reinforcement' : 'pending';

    await _companionRepo.upsertLifecycleState(
      unitId: state.unitId,
      lifecycleTier: const Value('ready'),
      stage4Status: Value(status),
      stage4PreSleepDueDay: Value(preSleepDueDay),
      stage4NextDayDueDay: Value(nextDayDueDay),
      stage4RetryDueDay: const Value(null),
      stage4UnresolvedTargetsJson:
          Value(unresolved.isEmpty ? null : jsonEncode(unresolved)),
      stage4RiskJson: Value(
        jsonEncode(<String, Object?>{
          'stage3_budget_exceeded': stage3.budgetExceeded,
          'weak_target_count': unresolved.length,
        }),
      ),
      stage4StrengtheningRoute:
          Value(unresolvedRatio > 0.30 ? 'broad_stage3' : null),
      stage4LastOutcome: const Value(null),
      stage4LastSessionId: const Value(null),
      stage4LastCompletedDay: const Value(null),
      updatedAtDay: day,
      updatedAtSeconds: nowLocalSecondsSinceMidnight(nowLocal),
    );
  }

  Future<ChainRunState> _advanceFromStage2ToStage3({
    required ChainRunState state,
    required ProgressiveRevealChainConfig config,
    required DateTime nowLocal,
    required List<int> weakPreludeTargets,
    required bool budgetFallback,
  }) async {
    final verseStates = <ChainVerseState>[
      for (final verse in state.verses)
        verse.passedCuedRecall
            ? verse
            : verse.markPassedForStage(CompanionStage.cuedRecall),
    ];
    final advanced = await _advanceToNextStage(
      state: state,
      verseStates: verseStates,
      triggerVerseIndex: state.currentVerseIndex,
      nowLocal: nowLocal,
    );
    final withStageContext = advanced.copyWith(
      verses: verseStates,
      stage2: state.stage2?.copyWith(
        phase:
            budgetFallback ? Stage2Phase.budgetFallback : Stage2Phase.completed,
        budgetExceeded:
            budgetFallback || (state.stage2?.budgetExceeded ?? false),
        activeAutoCheckPrompt: null,
      ),
      stage3WeakPreludeTargets: weakPreludeTargets,
      stage3WeakPreludeCursor: 0,
      returnVerseIndex: null,
    );
    return _initializeStage3Runtime(
      state: withStageContext,
      config: config,
      nowEpochMs: nowLocal.millisecondsSinceEpoch,
      weakPreludeTargets: weakPreludeTargets,
    );
  }

  ChainVerseState _seedInitialVerseState({
    required ChainVerse verse,
    required bool stageOneCleared,
    required bool stageTwoCleared,
    required CompanionStepProficiencyData? reviewProficiency,
    required Stage3Config reviewConfig,
  }) {
    final seededStage3 = reviewProficiency == null
        ? const Stage3VerseStats()
        : _seedReviewStage3Stats(
            proficiency: reviewProficiency,
            config: reviewConfig,
          );
    return ChainVerseState(
      verse: verse,
      revealed: false,
      passed: false,
      passedGuidedVisible: stageOneCleared,
      passedCuedRecall: stageTwoCleared,
      attemptCount: 0,
      hiddenAttemptCount: 0,
      interleaveCycles: 0,
      highestHintLevel: HintLevel.h0,
      proficiency: reviewProficiency?.proficiencyEma ?? 0,
      stage1: const Stage1VerseStats(),
      stage2: const Stage2VerseStats(),
      stage3: seededStage3,
    );
  }

  Stage3VerseStats _seedReviewStage3Stats({
    required CompanionStepProficiencyData proficiency,
    required Stage3Config config,
  }) {
    final lastHint = HintLevel.fromCode(proficiency.lastHintLevel);
    final lowProficiency =
        proficiency.proficiencyEma < config.targetSuccessBandMin;
    final needsCueSupport = lastHint.order > HintLevel.letters.order;
    final weakTarget = lowProficiency ||
        needsCueSupport ||
        proficiency.passesCount < config.readinessPassesRequired;
    final seededLinkingPasses =
        proficiency.passesCount > 0 && !needsCueSupport ? 1 : 0;
    return Stage3VerseStats(
      weakTarget: weakTarget,
      cueBaselineHint: _reviewSeedBaselineHint(lastHint),
      linkingPassCount: seededLinkingPasses,
      discriminationPasses:
          proficiency.proficiencyEma >= config.targetSuccessBandMax ? 1 : 0,
      countedPasses:
          proficiency.passesCount.clamp(0, config.readinessPassesRequired),
      countedAttempts: proficiency.attemptsCount,
      attempts: proficiency.attemptsCount,
    );
  }

  HintLevel _reviewSeedBaselineHint(HintLevel lastHint) {
    if (lastHint.order <= HintLevel.h0.order) {
      return HintLevel.h0;
    }
    if (lastHint.order <= HintLevel.letters.order) {
      return HintLevel.letters;
    }
    return HintLevel.letters;
  }

  ChainRunState _initializeStage2Runtime({
    required ChainRunState state,
    required ProgressiveRevealChainConfig config,
    required int nowEpochMs,
  }) {
    final stage2BudgetMs = config.stage2.stage2ChunkBudgetMs(
      ayahCount: state.verses.length,
      avgNewMinutesPerAyah: state.resolvedAvgNewMinutesPerAyah,
    );
    final perVerseCapMs = config.stage2.perVerseCapMs(
      ayahCount: state.verses.length,
      stage2ChunkBudgetMs: stage2BudgetMs,
    );
    final verses = <ChainVerseState>[
      for (var i = 0; i < state.verses.length; i++)
        state.verses[i].copyWith(
          stage2: state.verses[i].stage2.copyWith(
            weakTarget: state.verses[i].stage2.weakTarget ||
                state.verses[i].stage1.weak,
            cueBaselineHint: state.verses[i].stage1.weak
                ? HintLevel.firstWord
                : HintLevel.letters,
          ),
        ),
    ];

    var runtime = Stage2Runtime(
      config: config.stage2,
      phase: Stage2Phase.acquisition,
      mode: Stage2Mode.minimalCueRecall,
      startedAtEpochMs: nowEpochMs,
      lastActionAtEpochMs: nowEpochMs,
      chunkElapsedMs: 0,
      stage2BudgetMs: stage2BudgetMs,
      perVerseCapMs: perVerseCapMs,
      budgetExceeded: false,
      remediationRounds: 0,
      checkpointTargets: const <int>[],
      checkpointCursor: 0,
      remediationTargets: const <int>[],
      remediationCursor: 0,
      lastCheckpointOutcome: null,
      activeAutoCheckPrompt: null,
    );

    final target = _pickStage2Target(
      verses: verses,
      startAfter: -1,
      runtime: runtime,
    );
    final currentIndex = target?.verseIndex ??
        _firstUnpassedIndexForStage(verses, CompanionStage.cuedRecall) ??
        0;
    final mode = target?.mode ?? Stage2Mode.minimalCueRecall;
    runtime = runtime.copyWith(
      mode: mode,
      activeAutoCheckPrompt: _buildStage2AutoCheckPrompt(
        state: state.copyWith(verses: verses),
        verses: verses,
        verseIndex: currentIndex,
        mode: mode,
      ),
    );
    return state.copyWith(
      verses: verses,
      stage2: runtime,
      currentVerseIndex: currentIndex,
      currentHintLevel:
          _stage2EffectiveBaselineHint(verses[currentIndex].stage2),
      returnVerseIndex: null,
    );
  }

  ChainRunState _initializeStage3Runtime({
    required ChainRunState state,
    required ProgressiveRevealChainConfig config,
    required int nowEpochMs,
    required List<int> weakPreludeTargets,
  }) {
    final normalizedWeakPreludeTargets = weakPreludeTargets
        .where((index) => index >= 0 && index < state.verses.length)
        .toSet()
        .toList(growable: false)
      ..sort();
    final stage3BudgetMs = config.stage3.stage3ChunkBudgetMs(
      ayahCount: state.verses.length,
      avgNewMinutesPerAyah: state.resolvedAvgNewMinutesPerAyah,
    );
    final perVerseCapMs = config.stage3.perVerseCapMs(
      ayahCount: state.verses.length,
      stage3ChunkBudgetMs: stage3BudgetMs,
    );
    final weakPreludeSet = normalizedWeakPreludeTargets.toSet();
    final verses = <ChainVerseState>[
      for (var i = 0; i < state.verses.length; i++)
        state.verses[i].copyWith(
          stage3: state.verses[i].stage3.copyWith(
            weakTarget: state.verses[i].stage3.weakTarget ||
                state.verses[i].stage1.weak ||
                state.verses[i].stage2.weakTarget ||
                weakPreludeSet.contains(i),
            cueBaselineHint: weakPreludeSet.contains(i)
                ? HintLevel.letters
                : state.verses[i].stage3.cueBaselineHint,
          ),
        ),
    ];

    var runtime = Stage3Runtime(
      config: config.stage3,
      phase: normalizedWeakPreludeTargets.isNotEmpty
          ? Stage3Phase.prelude
          : Stage3Phase.acquisition,
      mode: normalizedWeakPreludeTargets.isNotEmpty
          ? Stage3Mode.weakPrelude
          : Stage3Mode.hiddenRecall,
      startedAtEpochMs: nowEpochMs,
      lastActionAtEpochMs: nowEpochMs,
      chunkElapsedMs: 0,
      stage3BudgetMs: stage3BudgetMs,
      perVerseCapMs: perVerseCapMs,
      budgetExceeded: false,
      remediationRounds: 0,
      checkpointTargets: const <int>[],
      checkpointCursor: 0,
      remediationTargets: const <int>[],
      remediationCursor: 0,
      lastCheckpointOutcome: null,
      activeAutoCheckPrompt: null,
      totalCountableAttempts: 0,
    );

    final seededState = state.copyWith(
      verses: verses,
      stage3WeakPreludeTargets: normalizedWeakPreludeTargets,
      stage3WeakPreludeCursor: 0,
    );
    final target = _pickStage3Target(
      state: seededState,
      verses: verses,
      startAfter: -1,
      runtime: runtime,
    );
    final currentIndex = target?.verseIndex ??
        _firstUnpassedIndexForStage(verses, CompanionStage.hiddenReveal) ??
        0;
    final mode = target?.mode ?? runtime.mode;
    runtime = runtime.copyWith(
      phase: target?.phase ?? runtime.phase,
      mode: mode,
      activeAutoCheckPrompt: mode == Stage3Mode.correction
          ? null
          : _buildStage3AutoCheckPrompt(
              state: seededState,
              verses: verses,
              verseIndex: currentIndex,
              mode: mode,
            ),
    );
    return state.copyWith(
      verses: verses,
      stage3: runtime,
      stage3WeakPreludeTargets: normalizedWeakPreludeTargets,
      stage3WeakPreludeCursor: 0,
      currentVerseIndex: currentIndex,
      currentHintLevel: _stage3EffectiveBaselineHint(
        verses[currentIndex].stage3,
        capAtH1: normalizedWeakPreludeTargets.isNotEmpty,
      ),
      returnVerseIndex: null,
    );
  }

  ChainRunState _initializeReviewRuntime({
    required ChainRunState state,
    required ProgressiveRevealChainConfig config,
    required int nowEpochMs,
  }) {
    final reviewBudgetMs = config.stage3.stage3ChunkBudgetMs(
      ayahCount: state.verses.length,
      avgNewMinutesPerAyah: state.resolvedAvgNewMinutesPerAyah,
    );
    final perVerseCapMs = config.stage3.perVerseCapMs(
      ayahCount: state.verses.length,
      stage3ChunkBudgetMs: reviewBudgetMs,
    );

    var runtime = ReviewRuntime(
      config: config.stage3,
      phase: ReviewPhase.acquisition,
      mode: ReviewMode.hiddenRecall,
      startedAtEpochMs: nowEpochMs,
      lastActionAtEpochMs: nowEpochMs,
      chunkElapsedMs: 0,
      reviewBudgetMs: reviewBudgetMs,
      perVerseCapMs: perVerseCapMs,
      budgetExceeded: false,
      remediationRounds: 0,
      checkpointTargets: const <int>[],
      checkpointCursor: 0,
      remediationTargets: const <int>[],
      remediationCursor: 0,
      lastCheckpointOutcome: null,
      activeAutoCheckPrompt: null,
      totalCountableAttempts: 0,
    );

    final seeded = state.copyWith(
      stage3: null,
      stage4: null,
      review: runtime,
      stage3WeakPreludeTargets: const <int>[],
      stage3WeakPreludeCursor: 0,
    );
    final target = _pickReviewTarget(
      state: seeded,
      verses: seeded.verses,
      startAfter: -1,
      runtime: runtime,
    );
    final currentIndex = target?.verseIndex ?? 0;
    final mode = target?.mode ?? ReviewMode.hiddenRecall;
    runtime = runtime.copyWith(
      phase: target?.phase ?? ReviewPhase.acquisition,
      mode: mode,
      activeAutoCheckPrompt: mode == ReviewMode.correction
          ? null
          : _buildReviewAutoCheckPrompt(
              state: seeded,
              verses: seeded.verses,
              verseIndex: currentIndex,
              mode: mode,
            ),
    );
    return state.copyWith(
      stage3: null,
      stage4: null,
      review: runtime,
      currentVerseIndex: currentIndex,
      currentHintLevel: _reviewEffectiveBaselineHint(
        seeded.verses[currentIndex].stage3,
      ),
      returnVerseIndex: null,
      stage3WeakPreludeTargets: const <int>[],
      stage3WeakPreludeCursor: 0,
    );
  }

  Future<ChainRunState> _initializeStage4Runtime({
    required ChainRunState state,
    required ProgressiveRevealChainConfig config,
    required int nowEpochMs,
    required DateTime nowLocal,
  }) async {
    final lifecycle = await _companionRepo.getLifecycleState(state.unitId);
    final dueResolution = _resolveStage4DueKind(
      lifecycle: lifecycle,
      todayDay: localDayIndex(nowLocal),
    );
    final unresolved = _decodeStage4TargetIndexes(
      raw: lifecycle?.stage4UnresolvedTargetsJson,
      maxExclusive: state.verses.length,
    );
    final unresolvedTargets = unresolved.isEmpty
        ? List<int>.generate(state.verses.length, (index) => index)
        : unresolved;

    final stage4BudgetMs = config.stage4.stage4ChunkBudgetMs(
      ayahCount: state.verses.length,
      avgNewMinutesPerAyah: state.resolvedAvgNewMinutesPerAyah,
    );
    final perVerseCapMs = config.stage4.perVerseCapMs(
      ayahCount: state.verses.length,
      stage4ChunkBudgetMs: stage4BudgetMs,
    );

    final weakSet = unresolvedTargets.toSet();
    final verses = <ChainVerseState>[
      for (var i = 0; i < state.verses.length; i++)
        state.verses[i].copyWith(
          stage4: state.verses[i].stage4.copyWith(
            weakTarget: state.verses[i].stage4.weakTarget ||
                state.verses[i].stage1.weak ||
                state.verses[i].stage2.weakTarget ||
                state.verses[i].stage3.weakTarget ||
                weakSet.contains(i),
            riskTarget: weakSet.contains(i),
            cueBaselineHint: HintLevel.h0,
          ),
        ),
    ];

    final stage4SessionRecordId = await _companionRepo.startStage4Session(
      unitId: state.unitId,
      chainSessionId: state.sessionId,
      dueKind: dueResolution.dueKind,
      startedDay: localDayIndex(nowLocal),
      startedSeconds: nowLocalSecondsSinceMidnight(nowLocal),
      unresolvedTargetsJson: jsonEncode(unresolvedTargets),
      telemetryJson: jsonEncode(<String, Object?>{
        'lifecycle_stage': 'stage4',
        'stage4_phase': Stage4Phase.verification.code,
      }),
    );

    await _companionRepo.upsertLifecycleState(
      unitId: state.unitId,
      lifecycleTier: Value(lifecycle?.lifecycleTier ?? 'ready'),
      stage4Status: const Value('in_progress'),
      stage4LastSessionId: Value(stage4SessionRecordId),
      updatedAtDay: localDayIndex(nowLocal),
      updatedAtSeconds: nowLocalSecondsSinceMidnight(nowLocal),
    );

    final randomTargets = _deterministicStage4RandomStartTargets(
      versesLength: verses.length,
      randomProbeCount: config.stage4.randomStartProbeCount,
      unitId: state.unitId,
      sessionId: state.sessionId,
      dueDay: dueResolution.dueDay,
    );

    var runtime = Stage4Runtime(
      config: config.stage4,
      phase: Stage4Phase.verification,
      mode: Stage4Mode.coldStart,
      startedAtEpochMs: nowEpochMs,
      lastActionAtEpochMs: nowEpochMs,
      chunkElapsedMs: 0,
      stage4BudgetMs: stage4BudgetMs,
      perVerseCapMs: perVerseCapMs,
      dueKind: dueResolution.dueKind,
      stage4SessionRecordId: stage4SessionRecordId,
      unresolvedTargets: unresolvedTargets,
      pendingRandomStartTargets: randomTargets,
      randomStartCursor: 0,
      budgetExceeded: false,
      remediationRounds: 0,
      checkpointTargets: const <int>[],
      checkpointCursor: 0,
      remediationTargets: const <int>[],
      remediationCursor: 0,
      lastCheckpointOutcome: null,
      activeAutoCheckPrompt: null,
      totalCountableAttempts: 0,
    );

    final seeded = state.copyWith(
      verses: verses,
      stage3: null,
      stage4: runtime,
      stage3WeakPreludeTargets: const <int>[],
      stage3WeakPreludeCursor: 0,
    );
    final target = _pickStage4Target(
      state: seeded,
      verses: verses,
      startAfter: -1,
      runtime: runtime,
    );
    final currentIndex = target?.verseIndex ?? 0;
    final mode = target?.mode ?? Stage4Mode.coldStart;
    runtime = runtime.copyWith(
      phase: target?.phase ?? Stage4Phase.verification,
      mode: mode,
      activeAutoCheckPrompt: mode == Stage4Mode.correction
          ? null
          : _buildStage4AutoCheckPrompt(
              state: seeded,
              verses: verses,
              verseIndex: currentIndex,
              mode: mode,
            ),
    );

    return state.copyWith(
      verses: verses,
      stage3: null,
      stage4: runtime,
      currentVerseIndex: currentIndex,
      currentHintLevel:
          _stage4EffectiveBaselineHint(verses[currentIndex].stage4),
      returnVerseIndex: null,
      stage3WeakPreludeTargets: const <int>[],
      stage3WeakPreludeCursor: 0,
    );
  }

  Future<ChainRunState> _advanceToNextStage({
    required ChainRunState state,
    required List<ChainVerseState> verseStates,
    required int triggerVerseIndex,
    required DateTime nowLocal,
  }) async {
    final nextStage = state.activeStage.next();
    if (nextStage == null) {
      return state.copyWith(verses: verseStates);
    }

    final unlocked = _maxStage(state.unlockedStage, nextStage);
    if (!state.isReviewMode) {
      await _companionRepo.updateUnlockedStage(
        unitId: state.unitId,
        stage: unlocked,
        updatedAtDay: localDayIndex(nowLocal),
        updatedAtSeconds: nowLocalSecondsSinceMidnight(nowLocal),
      );
    }

    await _companionRepo.insertStageEvent(
      sessionId: state.sessionId,
      unitId: state.unitId,
      fromStage: state.activeStage,
      toStage: nextStage,
      eventType: 'auto_unlock',
      triggerVerseOrder: triggerVerseIndex,
      createdDay: localDayIndex(nowLocal),
      createdSeconds: nowLocalSecondsSinceMidnight(nowLocal),
    );

    return state.copyWith(
      verses: verseStates,
      activeStage: nextStage,
      unlockedStage: unlocked,
      currentVerseIndex:
          _firstUnpassedIndexForStage(verseStates, nextStage) ?? 0,
      currentHintLevel: _defaultHintForStage(nextStage),
      returnVerseIndex: null,
    );
  }

  Future<ChainRunState> _advanceFromStage1ToStage2({
    required ChainRunState state,
    required ProgressiveRevealChainConfig config,
    required DateTime nowLocal,
  }) async {
    final verseStates = <ChainVerseState>[
      for (final verse in state.verses)
        verse.passedGuidedVisible
            ? verse
            : verse.markPassedForStage(CompanionStage.guidedVisible),
    ];
    final advanced = await _advanceToNextStage(
      state: state,
      verseStates: verseStates,
      triggerVerseIndex: state.currentVerseIndex,
      nowLocal: nowLocal,
    );
    return _initializeStage2Runtime(
      state: advanced.copyWith(
        stage1: state.stage1,
      ),
      config: config,
      nowEpochMs: nowLocal.millisecondsSinceEpoch,
    );
  }

  Future<ChainRunState> _advanceStage1AfterPass({
    required ChainRunState state,
    required int passedVerseIndex,
    required bool h0UnassistedPass,
    required ProgressiveRevealChainConfig config,
    required DateTime nowLocal,
  }) async {
    var runtime = state.stage1!;
    var verses = [...state.verses];

    if (runtime.phase == Stage1Phase.remediation) {
      if (h0UnassistedPass) {
        final verse = verses[passedVerseIndex];
        verses[passedVerseIndex] = verse.copyWith(
          stage1: verse.stage1.copyWith(remediationNeeded: false),
        );
      }

      final nextRemediation = _nextMatchingIndex(
        verses: verses,
        startAfter: passedVerseIndex,
        predicate: (verse) => verse.stage1.remediationNeeded,
      );
      if (nextRemediation != null) {
        return state.copyWith(
          verses: verses,
          stage1: runtime.copyWith(
            mode: Stage1Mode.modelEcho,
            remediationCursor: nextRemediation,
            hintsUnlockedForCurrentProbe: false,
            currentProbeAttemptCount: 0,
            activeAutoCheckPrompt: null,
          ),
          currentVerseIndex: nextRemediation,
          currentHintLevel: HintLevel.h0,
        );
      }

      if (runtime.remediationRequiresCheckpoint &&
          runtime.remediationTargets.isNotEmpty) {
        final targets = runtime.remediationTargets;
        for (final index in targets) {
          final verse = verses[index];
          verses[index] = verse.copyWith(
            stage1: verse.stage1.copyWith(
              checkpointAttempted: false,
              checkpointPassed: false,
            ),
          );
        }
        final first = targets.first;
        return state.copyWith(
          verses: verses,
          stage1: runtime.copyWith(
            phase: Stage1Phase.checkpoint,
            mode: Stage1Mode.checkpoint,
            checkpointTargets: targets,
            checkpointCursor: 0,
            remediationTargets: const <int>[],
            remediationCursor: 0,
            hintsUnlockedForCurrentProbe: false,
            currentProbeAttemptCount: 0,
            activeAutoCheckPrompt: _buildAutoCheckPrompt(
              state: state.copyWith(verses: verses),
              verses: verses,
              verseIndex: first,
              runtime: runtime,
              mode: Stage1Mode.checkpoint,
            ),
          ),
          currentVerseIndex: first,
          currentHintLevel: HintLevel.h0,
        );
      }

      return _advanceFromStage1ToStage2(
        state: state.copyWith(
          verses: verses,
          stage1: runtime.copyWith(
            phase: Stage1Phase.completed,
            activeAutoCheckPrompt: null,
          ),
        ),
        config: config,
        nowLocal: nowLocal,
      );
    }

    if (runtime.mode == Stage1Mode.checkpoint) {
      final targets = runtime.checkpointTargets.isEmpty
          ? List<int>.generate(verses.length, (index) => index)
          : runtime.checkpointTargets;
      final nextCursor = runtime.checkpointCursor + 1;
      if (nextCursor < targets.length) {
        final nextIndex = targets[nextCursor];
        return state.copyWith(
          verses: verses,
          stage1: runtime.copyWith(
            checkpointTargets: targets,
            checkpointCursor: nextCursor,
            activeAutoCheckPrompt: _buildAutoCheckPrompt(
              state: state.copyWith(verses: verses),
              verses: verses,
              verseIndex: nextIndex,
              runtime: runtime,
              mode: Stage1Mode.checkpoint,
            ),
            hintsUnlockedForCurrentProbe: false,
            currentProbeAttemptCount: 0,
          ),
          currentVerseIndex: nextIndex,
          currentHintLevel: HintLevel.h0,
        );
      }

      final failed = <int>[
        for (final index in targets)
          if (!verses[index].stage1.checkpointPassed) index,
      ];
      final chunkColdPassRate = targets.isEmpty
          ? 0.0
          : (targets.length - failed.length) / targets.length;
      final everyCold = verses.every((verse) => verse.stage1.hasAnyH0Success);
      final everySpaced = verses.every((verse) => verse.stage1.spacedConfirmed);
      final checkpointPassed =
          chunkColdPassRate >= runtime.config.checkpointThreshold &&
              everyCold &&
              everySpaced;
      final outcome = Stage1CheckpointOutcome(
        chunkColdPassRate: chunkColdPassRate,
        failedVerseIndexes: failed,
        everyVerseHasColdSuccess: everyCold,
        everyVerseHasSpacedSuccess: everySpaced,
        passed: checkpointPassed,
      );

      if (checkpointPassed) {
        final cumulativeTargets = _resolveCumulativeTargets(
          verses,
          runtime,
        );
        if (cumulativeTargets.isEmpty) {
          return _advanceFromStage1ToStage2(
            state: state.copyWith(
              verses: verses,
              stage1: runtime.copyWith(
                phase: Stage1Phase.completed,
                lastCheckpointOutcome: outcome,
                activeAutoCheckPrompt: null,
              ),
            ),
            config: config,
            nowLocal: nowLocal,
          );
        }
        final first = cumulativeTargets.first;
        return state.copyWith(
          verses: verses,
          stage1: runtime.copyWith(
            phase: Stage1Phase.cumulativeCheck,
            mode: Stage1Mode.cumulativeCheck,
            cumulativeTargets: cumulativeTargets,
            cumulativeCursor: 0,
            lastCheckpointOutcome: outcome,
            activeAutoCheckPrompt: _buildAutoCheckPrompt(
              state: state.copyWith(verses: verses),
              verses: verses,
              verseIndex: first,
              runtime: runtime,
              mode: Stage1Mode.cumulativeCheck,
            ),
            hintsUnlockedForCurrentProbe: false,
            currentProbeAttemptCount: 0,
          ),
          currentVerseIndex: first,
          currentHintLevel: HintLevel.h0,
        );
      }

      if (runtime.remediationRounds >=
          runtime.config.maxCheckpointRemediationRounds) {
        for (var i = 0; i < verses.length; i++) {
          verses[i] = verses[i].copyWith(
            stage1: verses[i].stage1.copyWith(
                  weak: true,
                ),
          );
        }
        return _advanceFromStage1ToStage2(
          state: state.copyWith(
            verses: verses,
            stage1: runtime.copyWith(
              phase: Stage1Phase.budgetFallback,
              budgetExceeded: true,
              lastCheckpointOutcome: outcome,
              activeAutoCheckPrompt: null,
            ),
          ),
          config: config,
          nowLocal: nowLocal,
        );
      }

      final remediationTargets = failed;
      for (final index in remediationTargets) {
        verses[index] = verses[index].copyWith(
          stage1: verses[index].stage1.copyWith(
                remediationNeeded: true,
                weak: true,
              ),
        );
      }
      final first = remediationTargets.first;
      return state.copyWith(
        verses: verses,
        stage1: runtime.copyWith(
          phase: Stage1Phase.remediation,
          mode: Stage1Mode.modelEcho,
          remediationRequiresCheckpoint: true,
          remediationRounds: runtime.remediationRounds + 1,
          remediationTargets: remediationTargets,
          remediationCursor: 0,
          lastCheckpointOutcome: outcome,
          activeAutoCheckPrompt: null,
          hintsUnlockedForCurrentProbe: false,
          currentProbeAttemptCount: 0,
        ),
        currentVerseIndex: first,
        currentHintLevel: HintLevel.h0,
      );
    }

    if (runtime.mode == Stage1Mode.cumulativeCheck) {
      final targets = runtime.cumulativeTargets;
      final nextCursor = runtime.cumulativeCursor + 1;
      if (nextCursor < targets.length) {
        final nextIndex = targets[nextCursor];
        return state.copyWith(
          verses: verses,
          stage1: runtime.copyWith(
            cumulativeCursor: nextCursor,
            activeAutoCheckPrompt: _buildAutoCheckPrompt(
              state: state.copyWith(verses: verses),
              verses: verses,
              verseIndex: nextIndex,
              runtime: runtime,
              mode: Stage1Mode.cumulativeCheck,
            ),
            hintsUnlockedForCurrentProbe: false,
            currentProbeAttemptCount: 0,
          ),
          currentVerseIndex: nextIndex,
          currentHintLevel: HintLevel.h0,
        );
      }

      final failed = <int>[
        for (final index in targets)
          if (!verses[index].stage1.cumulativePassed) index,
      ];
      if (failed.isNotEmpty) {
        for (final index in failed) {
          verses[index] = verses[index].copyWith(
            stage1: verses[index].stage1.copyWith(
                  weak: true,
                  remediationNeeded: true,
                ),
          );
        }
        final first = failed.first;
        return state.copyWith(
          verses: verses,
          stage1: runtime.copyWith(
            phase: Stage1Phase.remediation,
            mode: Stage1Mode.modelEcho,
            remediationRequiresCheckpoint: false,
            remediationTargets: failed,
            remediationCursor: 0,
            activeAutoCheckPrompt: null,
            hintsUnlockedForCurrentProbe: false,
            currentProbeAttemptCount: 0,
          ),
          currentVerseIndex: first,
          currentHintLevel: HintLevel.h0,
        );
      }

      return _advanceFromStage1ToStage2(
        state: state.copyWith(
          verses: verses,
          stage1: runtime.copyWith(
            phase: Stage1Phase.completed,
            activeAutoCheckPrompt: null,
          ),
        ),
        config: config,
        nowLocal: nowLocal,
      );
    }

    final allH0 = verses.every((verse) => verse.stage1.hasAnyH0Success);
    final allSpaced = verses.every((verse) => verse.stage1.spacedConfirmed);
    if (allH0 && allSpaced) {
      final targets = List<int>.generate(verses.length, (index) => index);
      for (final index in targets) {
        verses[index] = verses[index].copyWith(
          stage1: verses[index].stage1.copyWith(
                checkpointAttempted: false,
                checkpointPassed: false,
              ),
        );
      }
      final first = targets.first;
      return state.copyWith(
        verses: verses,
        stage1: runtime.copyWith(
          phase: Stage1Phase.checkpoint,
          mode: Stage1Mode.checkpoint,
          checkpointTargets: targets,
          checkpointCursor: 0,
          activeAutoCheckPrompt: _buildAutoCheckPrompt(
            state: state.copyWith(verses: verses),
            verses: verses,
            verseIndex: first,
            runtime: runtime,
            mode: Stage1Mode.checkpoint,
          ),
          hintsUnlockedForCurrentProbe: false,
          currentProbeAttemptCount: 0,
        ),
        currentVerseIndex: first,
        currentHintLevel: HintLevel.h0,
      );
    }

    final target = _pickStage1Target(
      verses: verses,
      startAfter: passedVerseIndex,
      nowEpochMs: runtime.lastActionAtEpochMs,
      runtime: runtime,
    );
    if (target == null) {
      return state.copyWith(
        verses: verses,
        stage1: runtime.copyWith(
          mode: Stage1Mode.modelEcho,
          activeAutoCheckPrompt: null,
        ),
        currentHintLevel: HintLevel.h0,
      );
    }

    return state.copyWith(
      verses: verses,
      stage1: runtime.copyWith(
        phase: target.mode == Stage1Mode.spacedReprobe
            ? Stage1Phase.spacedConfirmation
            : runtime.phase,
        mode: target.mode,
        activeAutoCheckPrompt: target.mode == Stage1Mode.modelEcho
            ? null
            : _buildAutoCheckPrompt(
                state: state.copyWith(verses: verses),
                verses: verses,
                verseIndex: target.verseIndex,
                runtime: runtime,
                mode: target.mode,
              ),
        hintsUnlockedForCurrentProbe: false,
        currentProbeAttemptCount: 0,
      ),
      currentVerseIndex: target.verseIndex,
      currentHintLevel: HintLevel.h0,
    );
  }

  Future<ChainAttemptUpdate?> _maybeAdvanceStage1AfterBudget({
    required ChainRunState state,
    required ProgressiveRevealChainConfig config,
    required DateTime nowLocal,
  }) async {
    final runtime = state.stage1;
    if (runtime == null || runtime.chunkElapsedMs < runtime.stage1BudgetMs) {
      return null;
    }

    var verses = [...state.verses];
    for (var i = 0; i < verses.length; i++) {
      var verse = verses[i];
      if (!verse.stage1.seenModelExposure) {
        verse = verse.copyWith(
          attemptCount: verse.attemptCount + 1,
          stage1: verse.stage1.copyWith(
            seenModelExposure: true,
            modelEchoExposures: verse.stage1.modelEchoExposures + 1,
          ),
        );
        verses[i] = verse;
        await _persistAttempt(
          state: state.copyWith(verses: verses, stage1: runtime),
          verseIndex: i,
          verse: verse,
          stageCode: CompanionStage.guidedVisible.code,
          attemptType: 'encode_echo',
          hintLevel: HintLevel.h0,
          assistedFlag: 0,
          evaluatorMode: EvaluatorMode.manualFallback,
          evaluatorPassed: 1,
          evaluatorConfidence: null,
          autoCheckType: null,
          autoCheckResult: null,
          retrievalStrength: 0.0,
          latencyToStartMs: 0,
          stopsCount: 0,
          selfCorrectionsCount: 0,
          nowLocal: nowLocal,
          telemetryExtras: const <String, Object?>{
            'stage1_mode': 'model_echo',
            'seed_exposure_budget_fallback': true,
          },
        );
      }
      verses[i] = verses[i].copyWith(
        stage1: verses[i].stage1.copyWith(
              weak: verses[i].stage1.weak ||
                  !verses[i].stage1.hasAnyH0Success ||
                  !verses[i].stage1.spacedConfirmed,
            ),
      );
    }

    final advanced = await _advanceFromStage1ToStage2(
      state: state.copyWith(
        verses: verses,
        stage1: runtime.copyWith(
          phase: Stage1Phase.budgetFallback,
          budgetExceeded: true,
          activeAutoCheckPrompt: null,
        ),
      ),
      config: config,
      nowLocal: nowLocal,
    );
    return ChainAttemptUpdate(
      state: advanced,
      telemetry: VerseAttemptTelemetry(
        stage: CompanionStage.guidedVisible,
        hintLevel: HintLevel.h0,
        latencyToStartMs: 0,
        stopsCount: 0,
        selfCorrectionsCount: 0,
        evaluatorPassed: false,
        evaluatorConfidence: null,
        evaluatorMode: EvaluatorMode.manualFallback,
        revealedAfterAttempt: false,
        retrievalStrength: 0.0,
        attemptType: 'encode_echo',
        assisted: false,
        timeOnVerseMs: 0,
        timeOnChunkMs: runtime.chunkElapsedMs,
        stage1Mode: Stage1Mode.modelEcho,
      ),
    );
  }

  _Stage2Touched _touchStage2Clock({
    required ChainRunState state,
    required DateTime nowLocal,
  }) {
    final runtime = state.stage2;
    if (runtime == null) {
      return _Stage2Touched(verses: state.verses, runtime: null);
    }
    final nowMs = nowLocal.millisecondsSinceEpoch;
    final deltaMs = nowMs > runtime.lastActionAtEpochMs
        ? nowMs - runtime.lastActionAtEpochMs
        : 0;
    final verses = [...state.verses];
    final currentIndex = state.currentVerseIndex;
    final current = verses[currentIndex];
    verses[currentIndex] = current.copyWith(
      stage2: current.stage2.copyWith(
        timeOnVerseMs: current.stage2.timeOnVerseMs + deltaMs,
      ),
    );
    return _Stage2Touched(
      verses: verses,
      runtime: runtime.copyWith(
        lastActionAtEpochMs: nowMs,
        chunkElapsedMs: runtime.chunkElapsedMs + deltaMs,
      ),
    );
  }

  _Stage3Touched _touchStage3Clock({
    required ChainRunState state,
    required DateTime nowLocal,
  }) {
    final runtime = state.stage3;
    if (runtime == null) {
      return _Stage3Touched(verses: state.verses, runtime: null);
    }
    final nowMs = nowLocal.millisecondsSinceEpoch;
    final deltaMs = nowMs > runtime.lastActionAtEpochMs
        ? nowMs - runtime.lastActionAtEpochMs
        : 0;
    final verses = [...state.verses];
    final currentIndex = state.currentVerseIndex;
    final current = verses[currentIndex];
    verses[currentIndex] = current.copyWith(
      stage3: current.stage3.copyWith(
        timeOnVerseMs: current.stage3.timeOnVerseMs + deltaMs,
      ),
    );
    return _Stage3Touched(
      verses: verses,
      runtime: runtime.copyWith(
        lastActionAtEpochMs: nowMs,
        chunkElapsedMs: runtime.chunkElapsedMs + deltaMs,
      ),
    );
  }

  _ReviewTouched _touchReviewClock({
    required ChainRunState state,
    required DateTime nowLocal,
  }) {
    final runtime = state.review;
    if (runtime == null) {
      return _ReviewTouched(verses: state.verses, runtime: null);
    }
    final nowMs = nowLocal.millisecondsSinceEpoch;
    final deltaMs = nowMs > runtime.lastActionAtEpochMs
        ? nowMs - runtime.lastActionAtEpochMs
        : 0;
    final verses = [...state.verses];
    final currentIndex = state.currentVerseIndex;
    final current = verses[currentIndex];
    verses[currentIndex] = current.copyWith(
      stage3: current.stage3.copyWith(
        timeOnVerseMs: current.stage3.timeOnVerseMs + deltaMs,
      ),
    );
    return _ReviewTouched(
      verses: verses,
      runtime: runtime.copyWith(
        lastActionAtEpochMs: nowMs,
        chunkElapsedMs: runtime.chunkElapsedMs + deltaMs,
      ),
    );
  }

  _Stage4Touched _touchStage4Clock({
    required ChainRunState state,
    required DateTime nowLocal,
  }) {
    final runtime = state.stage4;
    if (runtime == null) {
      return _Stage4Touched(verses: state.verses, runtime: null);
    }
    final nowMs = nowLocal.millisecondsSinceEpoch;
    final deltaMs = nowMs > runtime.lastActionAtEpochMs
        ? nowMs - runtime.lastActionAtEpochMs
        : 0;
    final verses = [...state.verses];
    final currentIndex = state.currentVerseIndex;
    final current = verses[currentIndex];
    verses[currentIndex] = current.copyWith(
      stage4: current.stage4.copyWith(
        timeOnVerseMs: current.stage4.timeOnVerseMs + deltaMs,
      ),
    );
    return _Stage4Touched(
      verses: verses,
      runtime: runtime.copyWith(
        lastActionAtEpochMs: nowMs,
        chunkElapsedMs: runtime.chunkElapsedMs + deltaMs,
      ),
    );
  }

  Stage1AutoCheckPrompt _buildStage2AutoCheckPrompt({
    required ChainRunState state,
    required List<ChainVerseState> verses,
    required int verseIndex,
    required Stage2Mode mode,
  }) {
    final verse = verses[verseIndex];
    return _autoCheckEngine.buildPrompt(
      sessionId: state.sessionId,
      verseOrder: verseIndex,
      attemptIndex: verse.attemptCount + 1,
      attemptType: _attemptTypeForStage2Mode(mode),
      stage1Mode: _seedStage1ModeForStage2Mode(mode),
      verse: verse.verse,
      chunkVerses: verses.map((entry) => entry.verse).toList(growable: false),
    );
  }

  Stage1Mode _seedStage1ModeForStage2Mode(Stage2Mode mode) {
    return switch (mode) {
      Stage2Mode.minimalCueRecall => Stage1Mode.coldProbe,
      Stage2Mode.discrimination => Stage1Mode.spacedReprobe,
      Stage2Mode.linking => Stage1Mode.spacedReprobe,
      Stage2Mode.correction => Stage1Mode.correction,
      Stage2Mode.checkpoint => Stage1Mode.checkpoint,
      Stage2Mode.remediation => Stage1Mode.checkpoint,
    };
  }

  String _attemptTypeForStage2Mode(Stage2Mode mode) {
    return switch (mode) {
      Stage2Mode.minimalCueRecall => 'probe',
      Stage2Mode.discrimination => 'probe',
      Stage2Mode.linking => 'probe',
      Stage2Mode.correction => 'encode_echo',
      Stage2Mode.checkpoint => 'checkpoint',
      Stage2Mode.remediation => 'checkpoint',
    };
  }

  String _stage2TelemetryStep(Stage2Mode mode) {
    return switch (mode) {
      Stage2Mode.minimalCueRecall => 'minimal_recall',
      Stage2Mode.discrimination => 'discrimination',
      Stage2Mode.linking => 'linking',
      Stage2Mode.correction => 'correction',
      Stage2Mode.checkpoint => 'checkpoint',
      Stage2Mode.remediation => 'remediation',
    };
  }

  String? _stage2RiskTrigger({
    required ChainVerseState verse,
    required Stage2Config config,
  }) {
    if (verse.stage2.remediationNeeded) {
      return 'remediation';
    }
    if (verse.stage2.consecutiveFailures >=
        config.discriminationFailureTrigger) {
      return 'failure_streak';
    }
    if (verse.stage1.weak || verse.stage2.weakTarget) {
      return 'stage1_weak';
    }
    return null;
  }

  bool _stage2IsReady(ChainVerseState verse, Stage2Config config) {
    return verse.stage2.isReady(
      config: config,
      isWeak: verse.stage1.weak || verse.stage2.weakTarget,
    );
  }

  List<int> _stage2UnresolvedWeakTargets({
    required List<ChainVerseState> verses,
    required Stage2Config config,
  }) {
    return <int>[
      for (var i = 0; i < verses.length; i++)
        if (!_stage2IsReady(verses[i], config) ||
            verses[i].stage1.weak ||
            verses[i].stage2.weakTarget)
          i,
    ];
  }

  HintLevel _stage2EffectiveBaselineHint(
    Stage2VerseStats stats, {
    bool capAtH1 = false,
  }) {
    var baseline = stats.cueBaselineHint;
    if (stats.reliefPending) {
      baseline = _easierHint(
        baseline,
        maxHint: HintLevel.firstWord,
      );
    }
    if (capAtH1 && baseline.order > HintLevel.letters.order) {
      return HintLevel.letters;
    }
    return baseline;
  }

  HintLevel _harderHint(HintLevel level) {
    return switch (level) {
      HintLevel.firstWord => HintLevel.letters,
      HintLevel.letters => HintLevel.h0,
      _ => HintLevel.h0,
    };
  }

  HintLevel _easierHint(
    HintLevel level, {
    required HintLevel maxHint,
  }) {
    final eased = switch (level) {
      HintLevel.h0 => HintLevel.letters,
      HintLevel.letters => HintLevel.firstWord,
      _ => level,
    };
    return eased.order > maxHint.order ? maxHint : eased;
  }

  _Stage2Target? _pickStage2Target({
    required List<ChainVerseState> verses,
    required int startAfter,
    required Stage2Runtime runtime,
  }) {
    if (verses.isEmpty) {
      return null;
    }

    if (runtime.phase == Stage2Phase.checkpoint) {
      final targets = runtime.checkpointTargets.isEmpty
          ? List<int>.generate(verses.length, (index) => index)
          : runtime.checkpointTargets;
      final cursor = runtime.checkpointCursor.clamp(0, targets.length - 1);
      final verseIndex = targets[cursor];
      return _Stage2Target(
        verseIndex: verseIndex,
        mode: Stage2Mode.checkpoint,
        weakTarget: true,
        riskTrigger: 'checkpoint',
      );
    }

    if (runtime.phase == Stage2Phase.remediation &&
        runtime.remediationTargets.isNotEmpty) {
      final pending = runtime.remediationTargets.where((index) {
        if (index < 0 || index >= verses.length) {
          return false;
        }
        return verses[index].stage2.remediationNeeded ||
            !_stage2IsReady(verses[index], runtime.config);
      }).toList(growable: false);
      if (pending.isNotEmpty) {
        final verseIndex = _nextIndexFromList(
          indexes: pending,
          startAfter: startAfter,
        );
        return _Stage2Target(
          verseIndex: verseIndex,
          mode: Stage2Mode.remediation,
          weakTarget: true,
          riskTrigger: 'remediation',
        );
      }
    }

    final unresolvedWeak = <int>[
      for (var i = 0; i < verses.length; i++)
        if (!_stage2IsReady(verses[i], runtime.config) &&
            (verses[i].stage1.weak || verses[i].stage2.weakTarget))
          i,
    ];
    if (unresolvedWeak.isNotEmpty) {
      final verseIndex = _nextIndexFromList(
        indexes: unresolvedWeak,
        startAfter: startAfter,
      );
      final verse = verses[verseIndex];
      return _Stage2Target(
        verseIndex: verseIndex,
        mode: _stage2ModeForVerse(
          verse: verse,
          runtime: runtime,
        ),
        weakTarget: true,
        riskTrigger: _stage2RiskTrigger(
          verse: verse,
          config: runtime.config,
        ),
      );
    }

    final unresolved = <int>[
      for (var i = 0; i < verses.length; i++)
        if (!_stage2IsReady(verses[i], runtime.config)) i,
    ];
    if (unresolved.isEmpty) {
      return null;
    }
    final verseIndex = _nextIndexFromList(
      indexes: unresolved,
      startAfter: startAfter,
    );
    final verse = verses[verseIndex];
    return _Stage2Target(
      verseIndex: verseIndex,
      mode: _stage2ModeForVerse(
        verse: verse,
        runtime: runtime,
      ),
      weakTarget: verse.stage1.weak || verse.stage2.weakTarget,
      riskTrigger: _stage2RiskTrigger(
        verse: verse,
        config: runtime.config,
      ),
    );
  }

  Stage2Mode _stage2ModeForVerse({
    required ChainVerseState verse,
    required Stage2Runtime runtime,
  }) {
    if (verse.stage2.correctionRequired) {
      return Stage2Mode.correction;
    }
    if (runtime.phase == Stage2Phase.remediation) {
      return Stage2Mode.remediation;
    }
    if (runtime.phase == Stage2Phase.checkpoint) {
      return Stage2Mode.checkpoint;
    }

    final riskTrigger = _stage2RiskTrigger(
      verse: verse,
      config: runtime.config,
    );
    if (riskTrigger != null &&
        (verse.stage2.discriminationPasses < 1 ||
            verse.stage2.consecutiveFailures >=
                runtime.config.discriminationFailureTrigger ||
            verse.stage2.remediationNeeded)) {
      return Stage2Mode.discrimination;
    }

    if (verse.stage2.linkingPassCount < 1) {
      return Stage2Mode.linking;
    }
    return Stage2Mode.minimalCueRecall;
  }

  Stage1AutoCheckPrompt _buildStage3AutoCheckPrompt({
    required ChainRunState state,
    required List<ChainVerseState> verses,
    required int verseIndex,
    required Stage3Mode mode,
  }) {
    final verse = verses[verseIndex];
    return _autoCheckEngine.buildPrompt(
      sessionId: state.sessionId,
      verseOrder: verseIndex,
      attemptIndex: verse.attemptCount + 1,
      attemptType: _attemptTypeForStage3Mode(mode),
      stage1Mode: _seedStage1ModeForStage3Mode(mode),
      verse: verse.verse,
      chunkVerses: verses.map((entry) => entry.verse).toList(growable: false),
    );
  }

  Stage1Mode _seedStage1ModeForStage3Mode(Stage3Mode mode) {
    return switch (mode) {
      Stage3Mode.weakPrelude => Stage1Mode.coldProbe,
      Stage3Mode.hiddenRecall => Stage1Mode.coldProbe,
      Stage3Mode.linking => Stage1Mode.spacedReprobe,
      Stage3Mode.discrimination => Stage1Mode.spacedReprobe,
      Stage3Mode.correction => Stage1Mode.correction,
      Stage3Mode.checkpoint => Stage1Mode.checkpoint,
      Stage3Mode.remediation => Stage1Mode.checkpoint,
    };
  }

  String _attemptTypeForStage3Mode(Stage3Mode mode) {
    return switch (mode) {
      Stage3Mode.weakPrelude => 'probe',
      Stage3Mode.hiddenRecall => 'probe',
      Stage3Mode.linking => 'probe',
      Stage3Mode.discrimination => 'probe',
      Stage3Mode.correction => 'encode_echo',
      Stage3Mode.checkpoint => 'checkpoint',
      Stage3Mode.remediation => 'checkpoint',
    };
  }

  String _stage3TelemetryStep(Stage3Mode mode) {
    return switch (mode) {
      Stage3Mode.weakPrelude => 'stage3_weak_prelude',
      Stage3Mode.hiddenRecall => 'hidden_attempt',
      Stage3Mode.linking => 'linking',
      Stage3Mode.discrimination => 'discrimination',
      Stage3Mode.correction => 'correction_exposure',
      Stage3Mode.checkpoint => 'checkpoint',
      Stage3Mode.remediation => 'remediation',
    };
  }

  String? _stage3RiskTrigger({
    required ChainVerseState verse,
    required Stage3Config config,
    required bool weakPreludeActive,
  }) {
    if (weakPreludeActive) {
      return 'weak_prelude';
    }
    if (verse.stage3.remediationNeeded) {
      return 'remediation';
    }
    if (verse.stage3.consecutiveFailures >=
        config.discriminationFailureTrigger) {
      return 'failure_streak';
    }
    if (verse.stage1.weak ||
        verse.stage2.weakTarget ||
        verse.stage3.weakTarget) {
      return 'weak_target';
    }
    return null;
  }

  bool _stage3IsReady({
    required ChainRunState state,
    required ChainVerseState verse,
    required Stage3Config config,
  }) {
    return verse.stage3.isReady(
      config: config,
      isWeak: verse.stage1.weak ||
          verse.stage2.weakTarget ||
          verse.stage3.weakTarget,
    );
  }

  List<int> _stage3UnresolvedWeakTargets({
    required ChainRunState state,
    required List<ChainVerseState> verses,
    required Stage3Config config,
  }) {
    final weakPreludeSet = state.stage3WeakPreludeTargets.toSet();
    return <int>[
      for (var i = 0; i < verses.length; i++)
        if (!_stage3IsReady(
              state: state,
              verse: verses[i],
              config: config,
            ) ||
            verses[i].stage1.weak ||
            verses[i].stage2.weakTarget ||
            verses[i].stage3.weakTarget ||
            weakPreludeSet.contains(i))
          i,
    ];
  }

  HintLevel _stage3EffectiveBaselineHint(
    Stage3VerseStats stats, {
    bool capAtH1 = false,
  }) {
    var baseline = stats.cueBaselineHint;
    if (stats.reliefPending) {
      baseline = _easierHint(
        baseline,
        maxHint: HintLevel.letters,
      );
    }
    if (baseline.order > HintLevel.letters.order) {
      baseline = HintLevel.letters;
    }
    if (capAtH1 && baseline.order > HintLevel.letters.order) {
      return HintLevel.letters;
    }
    return baseline;
  }

  Stage3Mode _stage3ModeForVerse({
    required ChainRunState state,
    required ChainVerseState verse,
    required Stage3Runtime runtime,
  }) {
    final weakPreludeActive = state.stage3WeakPreludeTargets.isNotEmpty;
    if (weakPreludeActive) {
      return Stage3Mode.weakPrelude;
    }
    if (verse.stage3.correctionRequired) {
      return Stage3Mode.correction;
    }
    if (runtime.phase == Stage3Phase.remediation) {
      return Stage3Mode.remediation;
    }
    if (runtime.phase == Stage3Phase.checkpoint) {
      return Stage3Mode.checkpoint;
    }

    final riskTrigger = _stage3RiskTrigger(
      verse: verse,
      config: runtime.config,
      weakPreludeActive: weakPreludeActive,
    );
    if (riskTrigger != null &&
        (verse.stage3.discriminationPasses < 1 ||
            verse.stage3.consecutiveFailures >=
                runtime.config.discriminationFailureTrigger ||
            verse.stage3.remediationNeeded)) {
      return Stage3Mode.discrimination;
    }

    if (verse.stage3.linkingPassCount < 1) {
      return Stage3Mode.linking;
    }
    return Stage3Mode.hiddenRecall;
  }

  _Stage3Target? _pickStage3Target({
    required ChainRunState state,
    required List<ChainVerseState> verses,
    required int startAfter,
    required Stage3Runtime runtime,
  }) {
    if (verses.isEmpty) {
      return null;
    }

    if (state.stage3WeakPreludeTargets.isNotEmpty) {
      final target = _nextIndexFromList(
        indexes: state.stage3WeakPreludeTargets,
        startAfter: startAfter,
      );
      return _Stage3Target(
        verseIndex: target,
        mode: Stage3Mode.weakPrelude,
        phase: Stage3Phase.prelude,
        weakTarget: true,
        riskTrigger: 'weak_prelude',
      );
    }

    final correctionTarget = _nextMatchingIndex(
      verses: verses,
      startAfter: startAfter,
      predicate: (verse) => verse.stage3.correctionRequired,
    );
    if (correctionTarget != null) {
      return _Stage3Target(
        verseIndex: correctionTarget,
        mode: Stage3Mode.correction,
        phase: runtime.phase,
        weakTarget: true,
        riskTrigger: 'correction_required',
      );
    }

    if (runtime.phase == Stage3Phase.checkpoint) {
      final targets = runtime.checkpointTargets.isEmpty
          ? List<int>.generate(verses.length, (index) => index)
          : runtime.checkpointTargets;
      final cursor = runtime.checkpointCursor.clamp(0, targets.length - 1);
      final verseIndex = targets[cursor];
      return _Stage3Target(
        verseIndex: verseIndex,
        mode: Stage3Mode.checkpoint,
        phase: Stage3Phase.checkpoint,
        weakTarget: true,
        riskTrigger: 'checkpoint',
      );
    }

    if (runtime.phase == Stage3Phase.remediation &&
        runtime.remediationTargets.isNotEmpty) {
      final pending = runtime.remediationTargets.where((index) {
        if (index < 0 || index >= verses.length) {
          return false;
        }
        return verses[index].stage3.remediationNeeded ||
            !_stage3IsReady(
              state: state,
              verse: verses[index],
              config: runtime.config,
            );
      }).toList(growable: false);
      if (pending.isNotEmpty) {
        final verseIndex = _nextIndexFromList(
          indexes: pending,
          startAfter: startAfter,
        );
        return _Stage3Target(
          verseIndex: verseIndex,
          mode: Stage3Mode.remediation,
          phase: Stage3Phase.remediation,
          weakTarget: true,
          riskTrigger: 'remediation',
        );
      }
    }

    final unresolvedWeak = <int>[
      for (var i = 0; i < verses.length; i++)
        if (!_stage3IsReady(
              state: state,
              verse: verses[i],
              config: runtime.config,
            ) &&
            (verses[i].stage1.weak ||
                verses[i].stage2.weakTarget ||
                verses[i].stage3.weakTarget))
          i,
    ];
    if (unresolvedWeak.isNotEmpty) {
      final verseIndex = _nextIndexFromList(
        indexes: unresolvedWeak,
        startAfter: startAfter,
      );
      final verse = verses[verseIndex];
      return _Stage3Target(
        verseIndex: verseIndex,
        mode: _stage3ModeForVerse(
          state: state,
          verse: verse,
          runtime: runtime,
        ),
        phase: Stage3Phase.acquisition,
        weakTarget: true,
        riskTrigger: _stage3RiskTrigger(
          verse: verse,
          config: runtime.config,
          weakPreludeActive: false,
        ),
      );
    }

    final linkingDeficits = <int>[
      for (var i = 0; i < verses.length; i++)
        if (verses[i].stage3.linkingPassCount < 1) i,
    ];
    if (linkingDeficits.isNotEmpty) {
      final verseIndex = _nextIndexFromList(
        indexes: linkingDeficits,
        startAfter: startAfter,
      );
      return _Stage3Target(
        verseIndex: verseIndex,
        mode: Stage3Mode.linking,
        phase: Stage3Phase.acquisition,
        weakTarget: verses[verseIndex].stage3.weakTarget,
        riskTrigger: 'linking_deficit',
      );
    }

    final readinessDeficits = <int>[
      for (var i = 0; i < verses.length; i++)
        if (!_stage3IsReady(
          state: state,
          verse: verses[i],
          config: runtime.config,
        ))
          i,
    ];
    if (readinessDeficits.isNotEmpty) {
      if (runtime.totalCountableAttempts > 0 &&
          runtime.totalCountableAttempts %
                  runtime.config.randomProbeEveryCountedAttempts ==
              0) {
        final seed = state.sessionId +
            runtime.totalCountableAttempts +
            state.currentVerseIndex +
            verses.length;
        final sorted = readinessDeficits.toList(growable: false)..sort();
        final probeIndex = sorted[seed % sorted.length];
        return _Stage3Target(
          verseIndex: probeIndex,
          mode: Stage3Mode.hiddenRecall,
          phase: Stage3Phase.acquisition,
          weakTarget: verses[probeIndex].stage3.weakTarget,
          riskTrigger: 'random_probe',
        );
      }
      final verseIndex = _nextIndexFromList(
        indexes: readinessDeficits,
        startAfter: startAfter,
      );
      final verse = verses[verseIndex];
      return _Stage3Target(
        verseIndex: verseIndex,
        mode: _stage3ModeForVerse(
          state: state,
          verse: verse,
          runtime: runtime,
        ),
        phase: Stage3Phase.acquisition,
        weakTarget: verse.stage3.weakTarget,
        riskTrigger: _stage3RiskTrigger(
          verse: verse,
          config: runtime.config,
          weakPreludeActive: false,
        ),
      );
    }

    final fallback = _nextUnpassedIndex(
          verses,
          startAfter: startAfter,
        ) ??
        _firstUnpassedIndex(verses);
    if (fallback == null) {
      return null;
    }
    return _Stage3Target(
      verseIndex: fallback,
      mode: Stage3Mode.hiddenRecall,
      phase: Stage3Phase.acquisition,
      weakTarget: verses[fallback].stage3.weakTarget,
      riskTrigger: 'fallback_hidden_interleave',
    );
  }

  Stage1AutoCheckPrompt _buildReviewAutoCheckPrompt({
    required ChainRunState state,
    required List<ChainVerseState> verses,
    required int verseIndex,
    required ReviewMode mode,
  }) {
    final verse = verses[verseIndex];
    return _autoCheckEngine.buildPrompt(
      sessionId: state.sessionId,
      verseOrder: verseIndex,
      attemptIndex: verse.attemptCount + 1,
      attemptType: _attemptTypeForReviewMode(mode),
      stage1Mode: _seedStage1ModeForReviewMode(mode),
      verse: verse.verse,
      chunkVerses: verses.map((entry) => entry.verse).toList(growable: false),
    );
  }

  Stage1Mode _seedStage1ModeForReviewMode(ReviewMode mode) {
    return switch (mode) {
      ReviewMode.hiddenRecall => Stage1Mode.coldProbe,
      ReviewMode.linking => Stage1Mode.spacedReprobe,
      ReviewMode.discrimination => Stage1Mode.spacedReprobe,
      ReviewMode.correction => Stage1Mode.correction,
      ReviewMode.checkpoint => Stage1Mode.checkpoint,
      ReviewMode.remediation => Stage1Mode.checkpoint,
    };
  }

  String _attemptTypeForReviewMode(ReviewMode mode) {
    return switch (mode) {
      ReviewMode.hiddenRecall => 'probe',
      ReviewMode.linking => 'spaced_reprobe',
      ReviewMode.discrimination => 'spaced_reprobe',
      ReviewMode.correction => 'encode_echo',
      ReviewMode.checkpoint => 'checkpoint',
      ReviewMode.remediation => 'checkpoint',
    };
  }

  String _reviewTelemetryStep(ReviewMode mode) {
    return switch (mode) {
      ReviewMode.hiddenRecall => 'hidden_attempt',
      ReviewMode.linking => 'linking',
      ReviewMode.discrimination => 'discrimination',
      ReviewMode.correction => 'correction_exposure',
      ReviewMode.checkpoint => 'checkpoint',
      ReviewMode.remediation => 'remediation',
    };
  }

  String? _reviewRiskTrigger({
    required ChainVerseState verse,
    required Stage3Config config,
  }) {
    if (verse.stage3.remediationNeeded) {
      return 'remediation';
    }
    if (verse.stage3.consecutiveFailures >=
        config.discriminationFailureTrigger) {
      return 'failure_streak';
    }
    if (verse.stage3.weakTarget) {
      return 'weak_target';
    }
    if (verse.proficiency < config.targetSuccessBandMin) {
      return 'low_proficiency';
    }
    return null;
  }

  bool _reviewIsReady({
    required ChainVerseState verse,
    required Stage3Config config,
  }) {
    return verse.stage3.isReady(
      config: config,
      isWeak: verse.stage3.weakTarget ||
          verse.proficiency < config.targetSuccessBandMin,
    );
  }

  List<int> _reviewUnresolvedTargets({
    required List<ChainVerseState> verses,
    required Stage3Config config,
  }) {
    return <int>[
      for (var i = 0; i < verses.length; i++)
        if (!_reviewIsReady(
              verse: verses[i],
              config: config,
            ) ||
            verses[i].stage3.remediationNeeded ||
            verses[i].stage3.correctionRequired)
          i,
    ];
  }

  HintLevel _reviewEffectiveBaselineHint(Stage3VerseStats stats) {
    var baseline = stats.cueBaselineHint;
    if (stats.reliefPending) {
      baseline = _easierHint(
        baseline,
        maxHint: HintLevel.letters,
      );
    }
    if (baseline.order > HintLevel.letters.order) {
      baseline = HintLevel.letters;
    }
    return baseline;
  }

  ReviewMode _reviewModeForVerse({
    required ChainVerseState verse,
    required ReviewRuntime runtime,
  }) {
    if (verse.stage3.correctionRequired) {
      return ReviewMode.correction;
    }
    if (runtime.phase == ReviewPhase.remediation) {
      return ReviewMode.remediation;
    }
    if (runtime.phase == ReviewPhase.checkpoint) {
      return ReviewMode.checkpoint;
    }

    final riskTrigger = _reviewRiskTrigger(
      verse: verse,
      config: runtime.config,
    );
    if (riskTrigger != null &&
        (verse.stage3.discriminationPasses < 1 ||
            verse.stage3.consecutiveFailures >=
                runtime.config.discriminationFailureTrigger ||
            verse.stage3.remediationNeeded)) {
      return ReviewMode.discrimination;
    }

    if (verse.stage3.linkingPassCount < 1) {
      return ReviewMode.linking;
    }
    return ReviewMode.hiddenRecall;
  }

  _ReviewTarget? _pickReviewTarget({
    required ChainRunState state,
    required List<ChainVerseState> verses,
    required int startAfter,
    required ReviewRuntime runtime,
  }) {
    if (verses.isEmpty) {
      return null;
    }

    final correctionTarget = _nextMatchingIndex(
      verses: verses,
      startAfter: startAfter,
      predicate: (verse) => verse.stage3.correctionRequired,
    );
    if (correctionTarget != null) {
      return _ReviewTarget(
        verseIndex: correctionTarget,
        mode: ReviewMode.correction,
        phase: runtime.phase,
        weakTarget: true,
        riskTrigger: 'correction_required',
      );
    }

    final weakOrRiskTargets = <int>[
      for (var i = 0; i < verses.length; i++)
        if (!_reviewIsReady(
              verse: verses[i],
              config: runtime.config,
            ) &&
            (verses[i].stage3.weakTarget ||
                _reviewRiskTrigger(
                      verse: verses[i],
                      config: runtime.config,
                    ) !=
                    null ||
                verses[i].proficiency < runtime.config.targetSuccessBandMin))
          i,
    ];
    if (weakOrRiskTargets.isNotEmpty) {
      final verseIndex = _nextIndexFromList(
        indexes: weakOrRiskTargets,
        startAfter: startAfter,
      );
      final verse = verses[verseIndex];
      return _ReviewTarget(
        verseIndex: verseIndex,
        mode: _reviewModeForVerse(
          verse: verse,
          runtime: runtime,
        ),
        phase: ReviewPhase.acquisition,
        weakTarget: true,
        riskTrigger: _reviewRiskTrigger(
          verse: verse,
          config: runtime.config,
        ),
      );
    }

    final linkingDeficits = <int>[
      for (var i = 0; i < verses.length; i++)
        if (verses[i].stage3.linkingPassCount < 1) i,
    ];
    if (linkingDeficits.isNotEmpty) {
      final verseIndex = _nextIndexFromList(
        indexes: linkingDeficits,
        startAfter: startAfter,
      );
      return _ReviewTarget(
        verseIndex: verseIndex,
        mode: ReviewMode.linking,
        phase: ReviewPhase.acquisition,
        weakTarget: verses[verseIndex].stage3.weakTarget,
        riskTrigger: 'linking_deficit',
      );
    }

    final readinessOrLowProficiency = <int>[
      for (var i = 0; i < verses.length; i++)
        if (!_reviewIsReady(
              verse: verses[i],
              config: runtime.config,
            ) ||
            verses[i].proficiency < runtime.config.targetSuccessBandMin)
          i,
    ];
    if (readinessOrLowProficiency.isNotEmpty) {
      if (runtime.totalCountableAttempts > 0 &&
          runtime.totalCountableAttempts %
                  runtime.config.randomProbeEveryCountedAttempts ==
              0) {
        final seed = state.sessionId +
            runtime.totalCountableAttempts +
            state.currentVerseIndex +
            verses.length;
        final sorted = readinessOrLowProficiency.toList(growable: false)
          ..sort();
        final probeIndex = sorted[seed % sorted.length];
        return _ReviewTarget(
          verseIndex: probeIndex,
          mode: ReviewMode.hiddenRecall,
          phase: ReviewPhase.acquisition,
          weakTarget: verses[probeIndex].stage3.weakTarget,
          riskTrigger: 'deterministic_probe',
        );
      }
      final verseIndex = _nextIndexFromList(
        indexes: readinessOrLowProficiency,
        startAfter: startAfter,
      );
      final verse = verses[verseIndex];
      return _ReviewTarget(
        verseIndex: verseIndex,
        mode: _reviewModeForVerse(
          verse: verse,
          runtime: runtime,
        ),
        phase: ReviewPhase.acquisition,
        weakTarget: verse.stage3.weakTarget,
        riskTrigger: _reviewRiskTrigger(
          verse: verse,
          config: runtime.config,
        ),
      );
    }

    if (runtime.phase == ReviewPhase.checkpoint) {
      final targets = runtime.checkpointTargets.isEmpty
          ? List<int>.generate(verses.length, (index) => index)
          : runtime.checkpointTargets;
      final cursor = runtime.checkpointCursor.clamp(0, targets.length - 1);
      final verseIndex = targets[cursor];
      return _ReviewTarget(
        verseIndex: verseIndex,
        mode: ReviewMode.checkpoint,
        phase: ReviewPhase.checkpoint,
        weakTarget: verses[verseIndex].stage3.weakTarget,
        riskTrigger: 'checkpoint',
      );
    }

    if (runtime.phase == ReviewPhase.remediation &&
        runtime.remediationTargets.isNotEmpty) {
      final pending = runtime.remediationTargets.where((index) {
        if (index < 0 || index >= verses.length) {
          return false;
        }
        return verses[index].stage3.remediationNeeded ||
            !_reviewIsReady(
              verse: verses[index],
              config: runtime.config,
            );
      }).toList(growable: false);
      if (pending.isNotEmpty) {
        final verseIndex = _nextIndexFromList(
          indexes: pending,
          startAfter: startAfter,
        );
        return _ReviewTarget(
          verseIndex: verseIndex,
          mode: ReviewMode.remediation,
          phase: ReviewPhase.remediation,
          weakTarget: true,
          riskTrigger: 'remediation',
        );
      }
    }

    final fallback = _nextUnpassedIndex(
          verses,
          startAfter: startAfter,
        ) ??
        _firstUnpassedIndex(verses);
    if (fallback == null) {
      return null;
    }
    return _ReviewTarget(
      verseIndex: fallback,
      mode: ReviewMode.hiddenRecall,
      phase: ReviewPhase.acquisition,
      weakTarget: verses[fallback].stage3.weakTarget,
      riskTrigger: 'fallback_hidden_interleave',
    );
  }

  Stage1AutoCheckPrompt _buildStage4AutoCheckPrompt({
    required ChainRunState state,
    required List<ChainVerseState> verses,
    required int verseIndex,
    required Stage4Mode mode,
  }) {
    final verse = verses[verseIndex];
    return _autoCheckEngine.buildPrompt(
      sessionId: state.sessionId,
      verseOrder: verseIndex,
      attemptIndex: verse.attemptCount + 1,
      attemptType: _attemptTypeForStage4Mode(mode),
      stage1Mode: _seedStage1ModeForStage4Mode(mode),
      verse: verse.verse,
      chunkVerses: verses.map((entry) => entry.verse).toList(growable: false),
    );
  }

  Stage1Mode _seedStage1ModeForStage4Mode(Stage4Mode mode) {
    return switch (mode) {
      Stage4Mode.coldStart => Stage1Mode.coldProbe,
      Stage4Mode.randomStart => Stage1Mode.spacedReprobe,
      Stage4Mode.linking => Stage1Mode.spacedReprobe,
      Stage4Mode.discrimination => Stage1Mode.spacedReprobe,
      Stage4Mode.correction => Stage1Mode.correction,
      Stage4Mode.checkpoint => Stage1Mode.checkpoint,
      Stage4Mode.remediation => Stage1Mode.checkpoint,
    };
  }

  String _attemptTypeForStage4Mode(Stage4Mode mode) {
    return switch (mode) {
      Stage4Mode.coldStart => 'probe',
      Stage4Mode.randomStart => 'probe',
      Stage4Mode.linking => 'spaced_reprobe',
      Stage4Mode.discrimination => 'spaced_reprobe',
      Stage4Mode.correction => 'encode_echo',
      Stage4Mode.checkpoint => 'checkpoint',
      Stage4Mode.remediation => 'checkpoint',
    };
  }

  String _stage4TelemetryStep(Stage4Mode mode) {
    return switch (mode) {
      Stage4Mode.coldStart => 'hidden_attempt',
      Stage4Mode.randomStart => 'hidden_attempt',
      Stage4Mode.linking => 'linking',
      Stage4Mode.discrimination => 'discrimination',
      Stage4Mode.correction => 'correction_exposure',
      Stage4Mode.checkpoint => 'checkpoint',
      Stage4Mode.remediation => 'remediation',
    };
  }

  String? _stage4RiskTrigger({
    required ChainVerseState verse,
    required Stage4Config config,
  }) {
    if (verse.stage4.remediationNeeded) {
      return 'remediation';
    }
    if (verse.stage4.consecutiveFailures >=
        config.discriminationFailureTrigger) {
      return 'failure_streak';
    }
    if (verse.stage1.weak ||
        verse.stage2.weakTarget ||
        verse.stage3.weakTarget ||
        verse.stage4.weakTarget ||
        verse.stage4.riskTarget) {
      return 'weak_target';
    }
    return null;
  }

  bool _stage4IsReady({
    required ChainRunState state,
    required ChainVerseState verse,
    required Stage4Config config,
  }) {
    return verse.stage4.isReady(
      config: config,
      isWeak: verse.stage1.weak ||
          verse.stage2.weakTarget ||
          verse.stage3.weakTarget ||
          verse.stage4.weakTarget,
    );
  }

  List<int> _stage4UnresolvedTargets({
    required ChainRunState state,
    required List<ChainVerseState> verses,
    required Stage4Config config,
  }) {
    return <int>[
      for (var i = 0; i < verses.length; i++)
        if (!_stage4IsReady(
              state: state,
              verse: verses[i],
              config: config,
            ) ||
            verses[i].stage4.remediationNeeded ||
            verses[i].stage4.correctionRequired)
          i,
    ];
  }

  HintLevel _stage4EffectiveBaselineHint(Stage4VerseStats stats) {
    var baseline = stats.cueBaselineHint;
    if (baseline.order > HintLevel.letters.order) {
      baseline = HintLevel.letters;
    }
    return baseline;
  }

  Stage4Mode _stage4ModeForVerse({
    required ChainVerseState verse,
    required Stage4Runtime runtime,
  }) {
    if (verse.stage4.correctionRequired) {
      return Stage4Mode.correction;
    }
    if (runtime.phase == Stage4Phase.remediation) {
      return Stage4Mode.remediation;
    }
    if (runtime.phase == Stage4Phase.checkpoint) {
      return Stage4Mode.checkpoint;
    }

    final riskTrigger = _stage4RiskTrigger(
      verse: verse,
      config: runtime.config,
    );
    if (riskTrigger != null &&
        (verse.stage4.discriminationPasses < 1 ||
            verse.stage4.consecutiveFailures >=
                runtime.config.discriminationFailureTrigger ||
            verse.stage4.remediationNeeded)) {
      return Stage4Mode.discrimination;
    }

    if (verse.stage4.linkingPassCount < 1) {
      return Stage4Mode.linking;
    }
    return Stage4Mode.coldStart;
  }

  _Stage4Target? _pickStage4Target({
    required ChainRunState state,
    required List<ChainVerseState> verses,
    required int startAfter,
    required Stage4Runtime runtime,
  }) {
    if (verses.isEmpty) {
      return null;
    }

    final correctionTarget = _nextMatchingIndex(
      verses: verses,
      startAfter: startAfter,
      predicate: (verse) => verse.stage4.correctionRequired,
    );
    if (correctionTarget != null) {
      return _Stage4Target(
        verseIndex: correctionTarget,
        mode: Stage4Mode.correction,
        phase: runtime.phase,
        weakTarget: true,
        riskTrigger: 'correction_required',
      );
    }

    final unresolvedWeak = <int>[
      for (var i = 0; i < verses.length; i++)
        if (!_stage4IsReady(
              state: state,
              verse: verses[i],
              config: runtime.config,
            ) &&
            (verses[i].stage1.weak ||
                verses[i].stage2.weakTarget ||
                verses[i].stage3.weakTarget ||
                verses[i].stage4.weakTarget ||
                verses[i].stage4.riskTarget))
          i,
    ];
    if (unresolvedWeak.isNotEmpty) {
      final verseIndex = _nextIndexFromList(
        indexes: unresolvedWeak,
        startAfter: startAfter,
      );
      final verse = verses[verseIndex];
      return _Stage4Target(
        verseIndex: verseIndex,
        mode: _stage4ModeForVerse(verse: verse, runtime: runtime),
        phase: Stage4Phase.verification,
        weakTarget: true,
        riskTrigger: _stage4RiskTrigger(
          verse: verse,
          config: runtime.config,
        ),
      );
    }

    if (runtime.pendingRandomStartTargets.isNotEmpty) {
      final verseIndex = _nextIndexFromList(
        indexes: runtime.pendingRandomStartTargets,
        startAfter: startAfter,
      );
      return _Stage4Target(
        verseIndex: verseIndex,
        mode: Stage4Mode.randomStart,
        phase: Stage4Phase.verification,
        weakTarget: verses[verseIndex].stage4.weakTarget,
        riskTrigger: 'random_start_obligation',
      );
    }

    final linkingDeficits = <int>[
      for (var i = 0; i < verses.length; i++)
        if (verses[i].stage4.linkingPassCount < 1) i,
    ];
    if (linkingDeficits.isNotEmpty) {
      final verseIndex = _nextIndexFromList(
        indexes: linkingDeficits,
        startAfter: startAfter,
      );
      return _Stage4Target(
        verseIndex: verseIndex,
        mode: Stage4Mode.linking,
        phase: Stage4Phase.verification,
        weakTarget: verses[verseIndex].stage4.weakTarget,
        riskTrigger: 'linking_deficit',
      );
    }

    final readinessDeficits = <int>[
      for (var i = 0; i < verses.length; i++)
        if (!_stage4IsReady(
          state: state,
          verse: verses[i],
          config: runtime.config,
        ))
          i,
    ];
    if (readinessDeficits.isNotEmpty) {
      if (runtime.totalCountableAttempts > 0 &&
          runtime.totalCountableAttempts % 4 == 0) {
        final seed = state.unitId +
            state.sessionId +
            runtime.totalCountableAttempts +
            verses.length;
        final sorted = readinessDeficits.toList(growable: false)..sort();
        final probeIndex = sorted[seed % sorted.length];
        return _Stage4Target(
          verseIndex: probeIndex,
          mode: Stage4Mode.randomStart,
          phase: Stage4Phase.verification,
          weakTarget: verses[probeIndex].stage4.weakTarget,
          riskTrigger: 'deterministic_probe',
        );
      }
      final verseIndex = _nextIndexFromList(
        indexes: readinessDeficits,
        startAfter: startAfter,
      );
      final verse = verses[verseIndex];
      return _Stage4Target(
        verseIndex: verseIndex,
        mode: _stage4ModeForVerse(verse: verse, runtime: runtime),
        phase: Stage4Phase.verification,
        weakTarget: verse.stage4.weakTarget,
        riskTrigger: _stage4RiskTrigger(
          verse: verse,
          config: runtime.config,
        ),
      );
    }

    final fallback = _routeNextHiddenVerse(
      state: state,
      verseStates: verses,
      currentIndex: startAfter < 0 ? 0 : startAfter,
      passedCurrent: true,
      config: const ProgressiveRevealChainConfig(),
    );
    return _Stage4Target(
      verseIndex: fallback.nextIndex,
      mode: Stage4Mode.coldStart,
      phase: Stage4Phase.verification,
      weakTarget: verses[fallback.nextIndex].stage4.weakTarget,
      riskTrigger: 'fallback_hidden_interleave',
    );
  }

  List<int> _deterministicStage4RandomStartTargets({
    required int versesLength,
    required int randomProbeCount,
    required int unitId,
    required int sessionId,
    required int dueDay,
  }) {
    if (versesLength <= 0 || randomProbeCount <= 0) {
      return const <int>[];
    }
    final count = randomProbeCount.clamp(1, versesLength);
    final seedBase = unitId + sessionId + dueDay + versesLength;
    final targets = <int>[];
    var cursor = seedBase % versesLength;
    for (var i = 0; i < count; i++) {
      targets.add(cursor);
      cursor = (cursor + 2) % versesLength;
      if (targets.toSet().length != targets.length) {
        cursor = (cursor + 1) % versesLength;
      }
    }
    return targets.toSet().toList(growable: false)..sort();
  }

  _Stage4DueResolution _resolveStage4DueKind({
    required CompanionLifecycleStateData? lifecycle,
    required int todayDay,
  }) {
    final retryDue = lifecycle?.stage4RetryDueDay;
    if (retryDue != null && retryDue <= todayDay) {
      return _Stage4DueResolution(
        dueKind: 'retry_required',
        dueDay: retryDue,
        mandatory: true,
      );
    }
    final nextDay = lifecycle?.stage4NextDayDueDay;
    if (nextDay != null && nextDay <= todayDay) {
      return _Stage4DueResolution(
        dueKind: 'next_day_required',
        dueDay: nextDay,
        mandatory: true,
      );
    }
    final preSleep = lifecycle?.stage4PreSleepDueDay;
    if (preSleep != null && preSleep <= todayDay) {
      return _Stage4DueResolution(
        dueKind: 'pre_sleep_optional',
        dueDay: preSleep,
        mandatory: false,
      );
    }
    return _Stage4DueResolution(
      dueKind: 'next_day_required',
      dueDay: todayDay,
      mandatory: true,
    );
  }

  List<int> _decodeStage4TargetIndexes({
    required String? raw,
    required int maxExclusive,
  }) {
    if (raw == null || raw.trim().isEmpty) {
      return const <int>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<num>()
            .map((value) => value.toInt())
            .where((index) => index >= 0 && index < maxExclusive)
            .toSet()
            .toList(growable: false)
          ..sort();
      }
      if (decoded is Map<String, dynamic>) {
        final targets = decoded['targets'];
        if (targets is List) {
          return targets
              .whereType<num>()
              .map((value) => value.toInt())
              .where((index) => index >= 0 && index < maxExclusive)
              .toSet()
              .toList(growable: false)
            ..sort();
        }
      }
    } catch (_) {
      return const <int>[];
    }
    return const <int>[];
  }

  int _nextIndexFromList({
    required List<int> indexes,
    required int startAfter,
  }) {
    final ordered = indexes.toList(growable: false)..sort();
    for (final index in ordered) {
      if (index > startAfter) {
        return index;
      }
    }
    return ordered.first;
  }

  _Stage1Touched _touchStage1Clock({
    required ChainRunState state,
    required DateTime nowLocal,
  }) {
    final runtime = state.stage1;
    if (runtime == null) {
      return _Stage1Touched(verses: state.verses, runtime: null);
    }
    final nowMs = nowLocal.millisecondsSinceEpoch;
    final deltaMs = nowMs > runtime.lastActionAtEpochMs
        ? nowMs - runtime.lastActionAtEpochMs
        : 0;
    final verses = [...state.verses];
    final currentIndex = state.currentVerseIndex;
    final current = verses[currentIndex];
    verses[currentIndex] = current.copyWith(
      stage1: current.stage1.copyWith(
        timeOnVerseMs: current.stage1.timeOnVerseMs + deltaMs,
      ),
    );
    return _Stage1Touched(
      verses: verses,
      runtime: runtime.copyWith(
        lastActionAtEpochMs: nowMs,
        chunkElapsedMs: runtime.chunkElapsedMs + deltaMs,
      ),
    );
  }

  Future<void> _persistAttempt({
    required ChainRunState state,
    required int verseIndex,
    required ChainVerseState verse,
    required String stageCode,
    required String attemptType,
    required HintLevel hintLevel,
    required int assistedFlag,
    required EvaluatorMode evaluatorMode,
    required int evaluatorPassed,
    required double? evaluatorConfidence,
    required String? autoCheckType,
    required String? autoCheckResult,
    required double retrievalStrength,
    required int latencyToStartMs,
    required int stopsCount,
    required int selfCorrectionsCount,
    required DateTime nowLocal,
    required Map<String, Object?> telemetryExtras,
  }) async {
    final attemptStage = CompanionStage.fromCode(stageCode);
    final timeOnVerseMs = switch (attemptStage) {
      CompanionStage.guidedVisible => verse.stage1.timeOnVerseMs,
      CompanionStage.cuedRecall => verse.stage2.timeOnVerseMs,
      CompanionStage.hiddenReveal => state.stage4 != null
          ? verse.stage4.timeOnVerseMs
          : (state.review != null
              ? verse.stage3.timeOnVerseMs
              : verse.stage3.timeOnVerseMs),
    };
    final timeOnChunkMs = switch (attemptStage) {
      CompanionStage.guidedVisible => state.stage1?.chunkElapsedMs ?? 0,
      CompanionStage.cuedRecall => state.stage2?.chunkElapsedMs ?? 0,
      CompanionStage.hiddenReveal => state.stage4?.chunkElapsedMs ??
          state.review?.chunkElapsedMs ??
          state.stage3?.chunkElapsedMs ??
          0,
    };

    await _companionRepo.insertVerseAttempt(
      sessionId: state.sessionId,
      unitId: state.unitId,
      verseOrder: verseIndex,
      surah: verse.verse.surah,
      ayah: verse.verse.ayah,
      attemptIndex: verse.attemptCount,
      stageCode: stageCode,
      attemptType: attemptType,
      hintLevel: hintLevel.code,
      assistedFlag: assistedFlag,
      latencyToStartMs: latencyToStartMs,
      stopsCount: stopsCount,
      selfCorrectionsCount: selfCorrectionsCount,
      evaluatorMode: evaluatorMode.code,
      evaluatorPassed: evaluatorPassed,
      evaluatorConfidence: evaluatorConfidence,
      autoCheckType: autoCheckType,
      autoCheckResult: autoCheckResult,
      revealedAfterAttempt: verse.revealed ? 1 : 0,
      retrievalStrength: retrievalStrength,
      timeOnVerseMs: timeOnVerseMs,
      timeOnChunkMs: timeOnChunkMs,
      telemetryJson: jsonEncode(telemetryExtras),
      attemptDay: localDayIndex(nowLocal),
      attemptSeconds: nowLocalSecondsSinceMidnight(nowLocal),
    );
  }

  Future<void> _upsertProficiency({
    required ChainRunState state,
    required ChainVerseState verse,
    required HintLevel hintLevel,
    required double retrievalStrength,
    required double? evaluatorConfidence,
    required int latencyToStartMs,
    required bool evaluatorPassed,
    required DateTime nowLocal,
  }) async {
    final existing = await _companionRepo.getStepProficiency(
      unitId: state.unitId,
      surah: verse.verse.surah,
      ayah: verse.verse.ayah,
    );
    final attemptsCount = (existing?.attemptsCount ?? 0) + 1;
    final passesCount =
        (existing?.passesCount ?? 0) + (evaluatorPassed ? 1 : 0);
    await _companionRepo.upsertStepProficiency(
      unitId: state.unitId,
      surah: verse.verse.surah,
      ayah: verse.verse.ayah,
      proficiencyEma: verse.proficiency,
      lastHintLevel: hintLevel.code,
      lastEvaluatorConfidence: evaluatorConfidence,
      lastLatencyToStartMs: latencyToStartMs,
      attemptsCount: attemptsCount,
      passesCount: passesCount,
      lastUpdatedDay: localDayIndex(nowLocal),
      lastSessionId: state.sessionId,
    );
  }

  Stage1Runtime _retuneStage1Runtime(Stage1Runtime runtime) {
    if (runtime.totalRetrievalAttempts < 3) {
      return runtime;
    }
    var spacing = runtime.adaptiveSpacingMs;
    var echoCap = runtime.adaptiveEchoLoopCap;
    final successRate = runtime.retrievalSuccessRate;
    if (successRate > 0.90) {
      spacing = (spacing + 15000).clamp(
        runtime.config.spacingAdaptiveMinMs,
        runtime.config.spacingAdaptiveMaxMs,
      );
      echoCap = (echoCap - 1).clamp(
        runtime.config.echoMinLoops,
        runtime.config.echoMaxLoops,
      );
    } else if (successRate < 0.60) {
      spacing = (spacing - 10000).clamp(
        runtime.config.spacingAdaptiveMinMs,
        runtime.config.spacingAdaptiveMaxMs,
      );
      echoCap = (echoCap + 1).clamp(
        runtime.config.echoMinLoops,
        runtime.config.echoMaxLoops,
      );
    }
    return runtime.copyWith(
      adaptiveSpacingMs: spacing,
      adaptiveEchoLoopCap: echoCap,
    );
  }

  Stage1AutoCheckPrompt _buildAutoCheckPrompt({
    required ChainRunState state,
    required List<ChainVerseState> verses,
    required int verseIndex,
    required Stage1Runtime runtime,
    required Stage1Mode mode,
  }) {
    final verse = verses[verseIndex];
    return _autoCheckEngine.buildPrompt(
      sessionId: state.sessionId,
      verseOrder: verseIndex,
      attemptIndex: verse.attemptCount + 1,
      attemptType: _attemptTypeForStage1Mode(mode),
      stage1Mode: mode,
      verse: verse.verse,
      chunkVerses: verses.map((entry) => entry.verse).toList(growable: false),
    );
  }

  String _attemptTypeForStage1Mode(Stage1Mode mode) {
    return switch (mode) {
      Stage1Mode.modelEcho => 'encode_echo',
      Stage1Mode.coldProbe => 'probe',
      Stage1Mode.correction => 'encode_echo',
      Stage1Mode.spacedReprobe => 'spaced_reprobe',
      Stage1Mode.checkpoint => 'checkpoint',
      Stage1Mode.cumulativeCheck => 'checkpoint',
    };
  }

  _Stage1Target? _pickStage1Target({
    required List<ChainVerseState> verses,
    required int startAfter,
    required int nowEpochMs,
    required Stage1Runtime runtime,
  }) {
    final firstCold = _nextMatchingIndex(
      verses: verses,
      startAfter: startAfter,
      predicate: (verse) => !verse.stage1.hasAnyH0Success,
    );
    if (firstCold != null) {
      final verse = verses[firstCold];
      final mode = (!verse.stage1.seenModelExposure ||
              verse.stage1.modelEchoLoops < runtime.adaptiveEchoLoopCap)
          ? Stage1Mode.modelEcho
          : Stage1Mode.coldProbe;
      return _Stage1Target(verseIndex: firstCold, mode: mode);
    }

    final spacedEligible = _nextMatchingIndex(
      verses: verses,
      startAfter: startAfter,
      predicate: (verse) =>
          !verse.stage1.spacedConfirmed &&
          verse.stage1.lastH0SuccessAtMs != null &&
          nowEpochMs - verse.stage1.lastH0SuccessAtMs! >=
              runtime.adaptiveSpacingMs,
    );
    if (spacedEligible != null) {
      return _Stage1Target(
        verseIndex: spacedEligible,
        mode: Stage1Mode.spacedReprobe,
      );
    }

    final pendingSpaced = _nextMatchingIndex(
      verses: verses,
      startAfter: startAfter,
      predicate: (verse) => !verse.stage1.spacedConfirmed,
    );
    if (pendingSpaced != null) {
      final verse = verses[pendingSpaced];
      final mode = verse.stage1.modelEchoLoops < runtime.adaptiveEchoLoopCap
          ? Stage1Mode.modelEcho
          : Stage1Mode.coldProbe;
      return _Stage1Target(verseIndex: pendingSpaced, mode: mode);
    }
    return null;
  }

  List<int> _resolveCumulativeTargets(
    List<ChainVerseState> verses,
    Stage1Runtime runtime,
  ) {
    final weak = <int>[
      for (var i = 0; i < verses.length; i++)
        if (verses[i].stage1.weak ||
            !verses[i].stage1.coldReady(
                  coldWindowSize: runtime.config.coldWindowSize,
                ))
          i,
    ];
    if (weak.isNotEmpty) {
      return weak;
    }
    final max = runtime.config.cumulativeCheckMaxVerses.clamp(1, verses.length);
    return List<int>.generate(max, (index) => index);
  }

  int? _nextMatchingIndex({
    required List<ChainVerseState> verses,
    required int startAfter,
    required bool Function(ChainVerseState verse) predicate,
  }) {
    for (var i = startAfter + 1; i < verses.length; i++) {
      if (predicate(verses[i])) {
        return i;
      }
    }
    for (var i = 0; i <= startAfter && i < verses.length; i++) {
      if (predicate(verses[i])) {
        return i;
      }
    }
    return null;
  }

  Future<ChainResultSummary> _completeSession({
    required ChainRunState state,
    required List<ChainVerseState> verseStates,
    required DateTime nowLocal,
    ChainResultKind resultKind = ChainResultKind.completed,
  }) async {
    final attempts =
        await _companionRepo.getAttemptsForSession(state.sessionId);
    final avgHint = attempts.isEmpty
        ? 0.0
        : attempts
                .map((attempt) => HintLevel.fromCode(attempt.hintLevel).order)
                .reduce((a, b) => a + b) /
            attempts.length;

    final retrievalAttempts = attempts
        .where((attempt) => attempt.attemptType != 'encode_echo')
        .toList(growable: false);
    final avgStrength = retrievalAttempts.isEmpty
        ? 0.0
        : retrievalAttempts
                .map((attempt) => attempt.retrievalStrength)
                .reduce((a, b) => a + b) /
            retrievalAttempts.length;
    final stage1DurationMs = attempts
        .where(
          (attempt) => attempt.stageCode == CompanionStage.guidedVisible.code,
        )
        .fold<int>(
          0,
          (current, attempt) =>
              attempt.timeOnChunkMs > current ? attempt.timeOnChunkMs : current,
        );
    final weakVerseCount =
        verseStates.where((verse) => verse.stage1.weak).length;
    final chunkColdPassRate =
        state.stage1?.lastCheckpointOutcome?.chunkColdPassRate ?? 0.0;
    final stage1BudgetExceeded = state.stage1?.budgetExceeded ?? false;

    final summary = ChainResultSummary(
      sessionId: state.sessionId,
      resultKind: resultKind,
      totalVerses: verseStates.length,
      passedVerses: verseStates.where((verse) => verse.passed).length,
      averageHintLevel: avgHint,
      averageRetrievalStrength: avgStrength,
      stage1DurationMs: stage1DurationMs,
      weakVerseCount: weakVerseCount,
      chunkColdPassRate: chunkColdPassRate,
      stage1BudgetExceeded: stage1BudgetExceeded,
    );

    await _companionRepo.completeChainSession(
      sessionId: state.sessionId,
      passedVerseCount: summary.passedVerses,
      chainResult: summary.resultKind.code,
      retrievalStrength: summary.averageRetrievalStrength,
      updatedAtDay: localDayIndex(nowLocal),
      endedAtSeconds: nowLocalSecondsSinceMidnight(nowLocal),
    );

    await _calibrationBridge.onChainCompleted(
      summary: summary,
      ayahCount: summary.totalVerses,
      nowLocal: nowLocal,
      attempts: attempts,
    );

    return summary;
  }

  _RoutingResult _routeNextHiddenVerse({
    required ChainRunState state,
    required List<ChainVerseState> verseStates,
    required int currentIndex,
    required bool passedCurrent,
    required ProgressiveRevealChainConfig config,
  }) {
    var nextIndex = currentIndex;
    int? returnVerseIndex = state.returnVerseIndex;

    if (passedCurrent) {
      if (returnVerseIndex != null && currentIndex != returnVerseIndex) {
        nextIndex = returnVerseIndex;
        returnVerseIndex = null;
      } else {
        nextIndex = _nextUnpassedIndex(verseStates, startAfter: currentIndex) ??
            _firstUnpassedIndex(verseStates) ??
            currentIndex;
      }
      return _RoutingResult(
        nextIndex: nextIndex,
        returnVerseIndex: returnVerseIndex,
        verseStates: verseStates,
      );
    }

    if (returnVerseIndex != null && currentIndex != returnVerseIndex) {
      return _RoutingResult(
        nextIndex: returnVerseIndex,
        returnVerseIndex: null,
        verseStates: verseStates,
      );
    }

    final current = verseStates[currentIndex];
    final attemptsBeforeInterleave = config.maxAttemptsBeforeInterleave < 1
        ? 1
        : config.maxAttemptsBeforeInterleave;
    final maxInterleaveCycles = config.maxInterleaveCyclesPerVerse < 0
        ? 0
        : config.maxInterleaveCyclesPerVerse;

    final shouldInterleave =
        current.hiddenAttemptCount % attemptsBeforeInterleave == 0 &&
            current.interleaveCycles < maxInterleaveCycles;

    if (shouldInterleave) {
      final alternate = _nextUnpassedIndex(
        verseStates,
        startAfter: currentIndex,
      );
      if (alternate != null && alternate != currentIndex) {
        final updatedCurrent = current.copyWith(
          interleaveCycles: current.interleaveCycles + 1,
        );
        final nextVerses = [...verseStates];
        nextVerses[currentIndex] = updatedCurrent;

        return _RoutingResult(
          nextIndex: alternate,
          returnVerseIndex: currentIndex,
          verseStates: nextVerses,
        );
      }
    }

    return _RoutingResult(
      nextIndex: currentIndex,
      returnVerseIndex: returnVerseIndex,
      verseStates: verseStates,
    );
  }

  int? _nextUnpassedIndex(
    List<ChainVerseState> verses, {
    required int startAfter,
  }) {
    for (var i = startAfter + 1; i < verses.length; i++) {
      if (!verses[i].passed) {
        return i;
      }
    }

    for (var i = 0; i <= startAfter && i < verses.length; i++) {
      if (!verses[i].passed) {
        return i;
      }
    }

    return null;
  }

  int? _firstUnpassedIndex(List<ChainVerseState> verses) {
    for (var i = 0; i < verses.length; i++) {
      if (!verses[i].passed) {
        return i;
      }
    }
    return null;
  }

  int? _firstUnpassedIndexForStage(
    List<ChainVerseState> verses,
    CompanionStage stage,
  ) {
    for (var i = 0; i < verses.length; i++) {
      if (!verses[i].passedForStage(stage)) {
        return i;
      }
    }
    return null;
  }

  HintLevel _defaultHintForStage(CompanionStage stage) {
    return switch (stage) {
      CompanionStage.guidedVisible => HintLevel.h0,
      CompanionStage.cuedRecall => HintLevel.firstWord,
      CompanionStage.hiddenReveal => HintLevel.h0,
    };
  }

  CompanionStage _maxStage(CompanionStage a, CompanionStage b) {
    return a.stageNumber >= b.stageNumber ? a : b;
  }

  double _nextProficiency({
    required double oldValue,
    required double observedValue,
    required double alpha,
  }) {
    final safeAlpha = alpha.clamp(0.05, 0.95);
    final next = (safeAlpha * observedValue) + ((1.0 - safeAlpha) * oldValue);
    return next.clamp(0.0, 1.0);
  }
}

class _RoutingResult {
  const _RoutingResult({
    required this.nextIndex,
    required this.returnVerseIndex,
    required this.verseStates,
  });

  final int nextIndex;
  final int? returnVerseIndex;
  final List<ChainVerseState> verseStates;
}

class _Stage1Touched {
  const _Stage1Touched({
    required this.verses,
    required this.runtime,
  });

  final List<ChainVerseState> verses;
  final Stage1Runtime? runtime;
}

class _Stage1Target {
  const _Stage1Target({
    required this.verseIndex,
    required this.mode,
  });

  final int verseIndex;
  final Stage1Mode mode;
}

class _Stage2Touched {
  const _Stage2Touched({
    required this.verses,
    required this.runtime,
  });

  final List<ChainVerseState> verses;
  final Stage2Runtime? runtime;
}

class _Stage2Target {
  const _Stage2Target({
    required this.verseIndex,
    required this.mode,
    required this.weakTarget,
    required this.riskTrigger,
  });

  final int verseIndex;
  final Stage2Mode mode;
  final bool weakTarget;
  final String? riskTrigger;
}

class _Stage3Touched {
  const _Stage3Touched({
    required this.verses,
    required this.runtime,
  });

  final List<ChainVerseState> verses;
  final Stage3Runtime? runtime;
}

class _ReviewTouched {
  const _ReviewTouched({
    required this.verses,
    required this.runtime,
  });

  final List<ChainVerseState> verses;
  final ReviewRuntime? runtime;
}

class _Stage3Target {
  const _Stage3Target({
    required this.verseIndex,
    required this.mode,
    required this.phase,
    required this.weakTarget,
    required this.riskTrigger,
  });

  final int verseIndex;
  final Stage3Mode mode;
  final Stage3Phase phase;
  final bool weakTarget;
  final String? riskTrigger;
}

class _ReviewTarget {
  const _ReviewTarget({
    required this.verseIndex,
    required this.mode,
    required this.phase,
    required this.weakTarget,
    required this.riskTrigger,
  });

  final int verseIndex;
  final ReviewMode mode;
  final ReviewPhase phase;
  final bool weakTarget;
  final String? riskTrigger;
}

class _Stage4Touched {
  const _Stage4Touched({
    required this.verses,
    required this.runtime,
  });

  final List<ChainVerseState> verses;
  final Stage4Runtime? runtime;
}

class _Stage4Target {
  const _Stage4Target({
    required this.verseIndex,
    required this.mode,
    required this.phase,
    required this.weakTarget,
    required this.riskTrigger,
  });

  final int verseIndex;
  final Stage4Mode mode;
  final Stage4Phase phase;
  final bool weakTarget;
  final String? riskTrigger;
}

class _Stage4DueResolution {
  const _Stage4DueResolution({
    required this.dueKind,
    required this.dueDay,
    required this.mandatory,
  });

  final String dueKind;
  final int dueDay;
  final bool mandatory;
}
