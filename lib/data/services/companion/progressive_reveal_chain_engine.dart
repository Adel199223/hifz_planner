import 'dart:convert';

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

    final persistedUnitState = launchMode == CompanionLaunchMode.newMemorization
        ? await _companionRepo.getOrCreateUnitState(
            unitId,
            nowLocal: effectiveNow,
          )
        : null;

    final resolvedUnlockedStage = launchMode == CompanionLaunchMode.review
        ? CompanionStage.hiddenReveal
        : _maxStage(
            persistedUnitState!.unlockedStage,
            unlockedStage ?? persistedUnitState.unlockedStage,
          );
    final activeStage = launchMode == CompanionLaunchMode.review
        ? CompanionStage.hiddenReveal
        : resolvedUnlockedStage;

    final sessionId = await _companionRepo.startChainSession(
      unitId: unitId,
      targetVerseCount: verses.length,
      createdAtDay: createdAtDay,
      startedAtSeconds: createdAtSeconds,
    );

    if (launchMode == CompanionLaunchMode.newMemorization &&
        activeStage != CompanionStage.guidedVisible) {
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
    final verseStates = <ChainVerseState>[
      for (final verse in verses)
        ChainVerseState(
          verse: verse,
          revealed: false,
          passed: false,
          passedGuidedVisible: stageOneCleared,
          passedCuedRecall: stageTwoCleared,
          attemptCount: 0,
          hiddenAttemptCount: 0,
          interleaveCycles: 0,
          highestHintLevel: HintLevel.h0,
          proficiency: 0,
          stage1: const Stage1VerseStats(),
          stage2: const Stage2VerseStats(),
          stage3: const Stage3VerseStats(),
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
    final stage1Runtime = launchMode == CompanionLaunchMode.newMemorization &&
            activeStage == CompanionStage.guidedVisible
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
      stage3WeakPreludeTargets: const <int>[],
      stage3WeakPreludeCursor: 0,
      resolvedAvgNewMinutesPerAyah: resolvedAvg,
    );

    if (launchMode == CompanionLaunchMode.newMemorization &&
        activeStage == CompanionStage.cuedRecall) {
      initialState = _initializeStage2Runtime(
        state: initialState,
        config: config,
        nowEpochMs: nowEpochMs,
      );
    }

    if (launchMode == CompanionLaunchMode.newMemorization &&
        activeStage == CompanionStage.hiddenReveal) {
      initialState = _initializeStage3Runtime(
        state: initialState,
        config: config,
        nowEpochMs: nowEpochMs,
        weakPreludeTargets: initialState.stage3WeakPreludeTargets,
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

    if (state.completed ||
        (!stage1Correction && !stage2Correction && !stage3Correction)) {
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

    return _submitLegacyAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: manualFallbackPass,
      asrConfidence: asrConfidence,
      latencyToStartMs: latencyToStartMs,
      stopsCount: stopsCount,
      selfCorrectionsCount: selfCorrectionsCount,
      config: config,
      nowLocal: nowLocal,
    );
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

  Future<ChainAttemptUpdate> _submitLegacyAttempt({
    required ChainRunState state,
    required VerseEvaluator evaluator,
    required bool manualFallbackPass,
    required double? asrConfidence,
    required int latencyToStartMs,
    required int stopsCount,
    required int selfCorrectionsCount,
    required ProgressiveRevealChainConfig config,
    required DateTime? nowLocal,
  }) async {
    final effectiveNow = (nowLocal ?? DateTime.now()).toLocal();
    final currentIndex = state.currentVerseIndex;
    final currentVerseState = state.verses[currentIndex];
    final stage3WeakPreludeActive =
        state.activeStage == CompanionStage.hiddenReveal &&
            state.stage3WeakPreludeTargets.isNotEmpty;
    final baselineHint = stage3WeakPreludeActive
        ? HintLevel.letters
        : _defaultHintForStage(state.activeStage);
    var effectiveHintLevel = state.currentHintLevel.order < baselineHint.order
        ? baselineHint
        : state.currentHintLevel;
    if (stage3WeakPreludeActive &&
        effectiveHintLevel.order > HintLevel.letters.order) {
      effectiveHintLevel = HintLevel.letters;
    }
    final assisted = effectiveHintLevel.order > baselineHint.order;

    final evaluation = await evaluator.evaluate(
      VerseEvaluationRequest(
        verse: currentVerseState.verse,
        manualFallbackPass: manualFallbackPass,
        asrConfidence: asrConfidence,
      ),
    );

    final retrievalStrength = computeRetrievalStrength(
      passed: evaluation.passed,
      hintLevel: effectiveHintLevel,
      latencyToStartMs: latencyToStartMs,
      stopsCount: stopsCount,
      selfCorrectionsCount: selfCorrectionsCount,
      confidence: evaluation.confidence,
    );

    final updatedAttemptCount = currentVerseState.attemptCount + 1;
    final updatedHiddenAttemptCount =
        state.activeStage == CompanionStage.hiddenReveal
            ? currentVerseState.hiddenAttemptCount + 1
            : currentVerseState.hiddenAttemptCount;

    final updatedVerseState = currentVerseState.copyWith(
      attemptCount: updatedAttemptCount,
      hiddenAttemptCount: updatedHiddenAttemptCount,
      revealed:
          state.activeStage == CompanionStage.hiddenReveal && evaluation.passed
              ? true
              : currentVerseState.revealed,
      passed:
          state.activeStage == CompanionStage.hiddenReveal && evaluation.passed
              ? true
              : currentVerseState.passed,
      passedGuidedVisible:
          state.activeStage == CompanionStage.guidedVisible && evaluation.passed
              ? true
              : currentVerseState.passedGuidedVisible,
      passedCuedRecall:
          state.activeStage == CompanionStage.cuedRecall && evaluation.passed
              ? true
              : currentVerseState.passedCuedRecall,
      highestHintLevel:
          effectiveHintLevel.order > currentVerseState.highestHintLevel.order
              ? effectiveHintLevel
              : currentVerseState.highestHintLevel,
      proficiency: _nextProficiency(
        oldValue: currentVerseState.proficiency,
        observedValue: retrievalStrength,
        alpha: config.proficiencyEmaAlpha,
      ),
    );

    final verseStates = [...state.verses];
    verseStates[currentIndex] = updatedVerseState;

    await _persistAttempt(
      state: state.copyWith(verses: verseStates),
      verseIndex: currentIndex,
      verse: updatedVerseState,
      stageCode: state.activeStage.code,
      attemptType: 'probe',
      hintLevel: effectiveHintLevel,
      assistedFlag: assisted ? 1 : 0,
      evaluatorMode: evaluation.mode,
      evaluatorPassed: evaluation.passed ? 1 : 0,
      evaluatorConfidence: evaluation.confidence,
      autoCheckType: null,
      autoCheckResult: null,
      retrievalStrength: retrievalStrength,
      latencyToStartMs: latencyToStartMs,
      stopsCount: stopsCount,
      selfCorrectionsCount: selfCorrectionsCount,
      nowLocal: effectiveNow,
      telemetryExtras: <String, Object?>{
        'legacy_path': true,
        if (stage3WeakPreludeActive) ...<String, Object?>{
          'stage2_step': 'stage3_weak_prelude',
          'weak_target': true,
          'lifecycle_hook': 'stage5_candidate',
        },
      },
    );

    await _upsertProficiency(
      state: state,
      verse: updatedVerseState,
      hintLevel: effectiveHintLevel,
      retrievalStrength: retrievalStrength,
      evaluatorConfidence: evaluation.confidence,
      latencyToStartMs: latencyToStartMs,
      evaluatorPassed: evaluation.passed,
      nowLocal: effectiveNow,
    );

    final telemetry = VerseAttemptTelemetry(
      stage: state.activeStage,
      hintLevel: effectiveHintLevel,
      latencyToStartMs: latencyToStartMs,
      stopsCount: stopsCount,
      selfCorrectionsCount: selfCorrectionsCount,
      evaluatorPassed: evaluation.passed,
      evaluatorConfidence: evaluation.confidence,
      evaluatorMode: evaluation.mode,
      revealedAfterAttempt: updatedVerseState.revealed,
      retrievalStrength: retrievalStrength,
      attemptType: 'probe',
      assisted: assisted,
      timeOnVerseMs: updatedVerseState.stage1.timeOnVerseMs,
      timeOnChunkMs: state.stage1?.chunkElapsedMs ?? 0,
    );

    if (state.activeStage != CompanionStage.hiddenReveal) {
      if (!evaluation.passed) {
        return ChainAttemptUpdate(
          state: state.copyWith(verses: verseStates),
          telemetry: telemetry,
        );
      }

      final stagePassed =
          verseStates.every((verse) => verse.passedForStage(state.activeStage));
      if (!stagePassed) {
        final nextIndex = _nextUnpassedIndexForStage(
              verseStates,
              stage: state.activeStage,
              startAfter: currentIndex,
            ) ??
            currentIndex;
        return ChainAttemptUpdate(
          state: state.copyWith(
            verses: verseStates,
            currentVerseIndex: nextIndex,
            currentHintLevel: _defaultHintForStage(state.activeStage),
            returnVerseIndex: null,
          ),
          telemetry: telemetry,
        );
      }

      final advanced = await _advanceToNextStage(
        state: state,
        verseStates: verseStates,
        triggerVerseIndex: currentIndex,
        nowLocal: effectiveNow,
      );

      return ChainAttemptUpdate(
        state: advanced,
        telemetry: telemetry,
      );
    }

    final allPassed = verseStates.every((verse) => verse.passed);
    if (allPassed) {
      final summary = await _completeSession(
        state: state.copyWith(verses: verseStates),
        verseStates: verseStates,
        nowLocal: effectiveNow,
      );
      return ChainAttemptUpdate(
        state: state.copyWith(
          verses: verseStates,
          completed: true,
          resultKind: ChainResultKind.completed,
          currentHintLevel: _defaultHintForStage(CompanionStage.hiddenReveal),
          returnVerseIndex: null,
        ),
        telemetry: telemetry,
        summary: summary,
      );
    }

    if (stage3WeakPreludeActive) {
      final routed = _routeStage3WeakPrelude(
        state: state,
        verseStates: verseStates,
        currentIndex: currentIndex,
        passedCurrent: evaluation.passed,
      );
      return ChainAttemptUpdate(
        state: state.copyWith(
          verses: routed.verseStates,
          currentVerseIndex: routed.nextIndex,
          currentHintLevel: routed.nextHintLevel,
          returnVerseIndex: null,
          stage3WeakPreludeTargets: routed.remainingTargets,
          stage3WeakPreludeCursor: routed.nextCursor,
        ),
        telemetry: telemetry,
      );
    }

    final routed = _routeNextHiddenVerse(
      state: state,
      verseStates: verseStates,
      currentIndex: currentIndex,
      passedCurrent: evaluation.passed,
      config: config,
    );

    return ChainAttemptUpdate(
      state: state.copyWith(
        verses: routed.verseStates,
        currentVerseIndex: routed.nextIndex,
        returnVerseIndex: routed.returnVerseIndex,
        currentHintLevel: routed.nextIndex == currentIndex
            ? state.currentHintLevel
            : _defaultHintForStage(CompanionStage.hiddenReveal),
      ),
      telemetry: telemetry,
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
      CompanionStage.hiddenReveal => verse.stage3.timeOnVerseMs,
    };
    final timeOnChunkMs = switch (attemptStage) {
      CompanionStage.guidedVisible => state.stage1?.chunkElapsedMs ?? 0,
      CompanionStage.cuedRecall => state.stage2?.chunkElapsedMs ?? 0,
      CompanionStage.hiddenReveal => state.stage3?.chunkElapsedMs ?? 0,
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

  _Stage3WeakPreludeRouting _routeStage3WeakPrelude({
    required ChainRunState state,
    required List<ChainVerseState> verseStates,
    required int currentIndex,
    required bool passedCurrent,
  }) {
    final targets = [...state.stage3WeakPreludeTargets];
    if (targets.isEmpty) {
      final fallbackNext = _nextUnpassedIndex(
            verseStates,
            startAfter: currentIndex,
          ) ??
          _firstUnpassedIndex(verseStates) ??
          currentIndex;
      return _Stage3WeakPreludeRouting(
        nextIndex: fallbackNext,
        nextHintLevel: _defaultHintForStage(CompanionStage.hiddenReveal),
        nextCursor: 0,
        remainingTargets: const <int>[],
        verseStates: verseStates,
      );
    }

    var cursor = state.stage3WeakPreludeCursor;
    if (cursor < 0 || cursor >= targets.length) {
      cursor = 0;
    }
    final activeTarget = targets[cursor];
    if (activeTarget != currentIndex) {
      return _Stage3WeakPreludeRouting(
        nextIndex: activeTarget,
        nextHintLevel: HintLevel.letters,
        nextCursor: cursor,
        remainingTargets: targets,
        verseStates: verseStates,
      );
    }

    if (passedCurrent) {
      targets.removeAt(cursor);
      if (targets.isEmpty) {
        final nextIndex = _nextUnpassedIndex(
              verseStates,
              startAfter: currentIndex,
            ) ??
            _firstUnpassedIndex(verseStates) ??
            currentIndex;
        return _Stage3WeakPreludeRouting(
          nextIndex: nextIndex,
          nextHintLevel: _defaultHintForStage(CompanionStage.hiddenReveal),
          nextCursor: 0,
          remainingTargets: const <int>[],
          verseStates: verseStates,
        );
      }
      if (cursor >= targets.length) {
        cursor = 0;
      }
      return _Stage3WeakPreludeRouting(
        nextIndex: targets[cursor],
        nextHintLevel: HintLevel.letters,
        nextCursor: cursor,
        remainingTargets: targets,
        verseStates: verseStates,
      );
    }

    if (targets.length > 1) {
      cursor = (cursor + 1) % targets.length;
    }
    return _Stage3WeakPreludeRouting(
      nextIndex: targets[cursor],
      nextHintLevel: HintLevel.letters,
      nextCursor: cursor,
      remainingTargets: targets,
      verseStates: verseStates,
    );
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

  int? _nextUnpassedIndexForStage(
    List<ChainVerseState> verses, {
    required CompanionStage stage,
    required int startAfter,
  }) {
    for (var i = startAfter + 1; i < verses.length; i++) {
      if (!verses[i].passedForStage(stage)) {
        return i;
      }
    }

    for (var i = 0; i <= startAfter && i < verses.length; i++) {
      if (!verses[i].passedForStage(stage)) {
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

class _Stage3WeakPreludeRouting {
  const _Stage3WeakPreludeRouting({
    required this.nextIndex,
    required this.nextHintLevel,
    required this.nextCursor,
    required this.remainingTargets,
    required this.verseStates,
  });

  final int nextIndex;
  final HintLevel nextHintLevel;
  final int nextCursor;
  final List<int> remainingTargets;
  final List<ChainVerseState> verseStates;
}
