import '../../repositories/companion_repo.dart';
import '../../time/local_day_time.dart';
import 'companion_calibration_bridge.dart';
import 'companion_models.dart';
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
    this._calibrationBridge,
  );

  final CompanionRepo _companionRepo;
  final CompanionCalibrationBridge _calibrationBridge;

  Future<ChainRunState> startSession({
    required int unitId,
    required List<ChainVerse> verses,
    required CompanionLaunchMode launchMode,
    CompanionStage? unlockedStage,
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
        ),
    ];

    return ChainRunState(
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
    );
  }

  ChainRunState requestHint(ChainRunState state) {
    if (state.completed) {
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
    final updatedVerses = <ChainVerseState>[
      for (final verse in state.verses)
        verse.passedForStage(state.activeStage)
            ? verse
            : verse.markPassedForStage(state.activeStage),
    ];

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

    return state.copyWith(
      activeStage: nextStage,
      unlockedStage: _maxStage(state.unlockedStage, nextStage),
      verses: updatedVerses,
      currentVerseIndex:
          _firstUnpassedIndexForStage(updatedVerses, nextStage) ?? 0,
      currentHintLevel: _defaultHintForStage(nextStage),
      returnVerseIndex: null,
    );
  }

  Future<ChainAttemptUpdate> submitAttempt({
    required ChainRunState state,
    required VerseEvaluator evaluator,
    required bool manualFallbackPass,
    double? asrConfidence,
    int latencyToStartMs = 0,
    int stopsCount = 0,
    int selfCorrectionsCount = 0,
    ProgressiveRevealChainConfig config = const ProgressiveRevealChainConfig(),
    DateTime? nowLocal,
  }) async {
    if (state.completed) {
      throw StateError('Cannot submit attempts for completed chain session.');
    }

    final effectiveNow = (nowLocal ?? DateTime.now()).toLocal();
    final currentIndex = state.currentVerseIndex;
    final currentVerseState = state.verses[currentIndex];

    final evaluation = await evaluator.evaluate(
      VerseEvaluationRequest(
        verse: currentVerseState.verse,
        manualFallbackPass: manualFallbackPass,
        asrConfidence: asrConfidence,
      ),
    );

    final retrievalStrength = computeRetrievalStrength(
      passed: evaluation.passed,
      hintLevel: state.currentHintLevel,
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
      revealed: state.activeStage == CompanionStage.hiddenReveal &&
              evaluation.passed
          ? true
          : currentVerseState.revealed,
      passed: state.activeStage == CompanionStage.hiddenReveal &&
              evaluation.passed
          ? true
          : currentVerseState.passed,
      passedGuidedVisible: state.activeStage == CompanionStage.guidedVisible &&
              evaluation.passed
          ? true
          : currentVerseState.passedGuidedVisible,
      passedCuedRecall: state.activeStage == CompanionStage.cuedRecall &&
              evaluation.passed
          ? true
          : currentVerseState.passedCuedRecall,
      highestHintLevel: state.currentHintLevel.order >
              currentVerseState.highestHintLevel.order
          ? state.currentHintLevel
          : currentVerseState.highestHintLevel,
      proficiency: _nextProficiency(
        oldValue: currentVerseState.proficiency,
        observedValue: retrievalStrength,
        alpha: config.proficiencyEmaAlpha,
      ),
    );

    final verseStates = [...state.verses];
    verseStates[currentIndex] = updatedVerseState;

    await _companionRepo.insertVerseAttempt(
      sessionId: state.sessionId,
      unitId: state.unitId,
      verseOrder: currentIndex,
      surah: currentVerseState.verse.surah,
      ayah: currentVerseState.verse.ayah,
      attemptIndex: updatedAttemptCount,
      stageCode: state.activeStage.code,
      hintLevel: state.currentHintLevel.code,
      latencyToStartMs: latencyToStartMs,
      stopsCount: stopsCount,
      selfCorrectionsCount: selfCorrectionsCount,
      evaluatorMode: evaluation.mode.code,
      evaluatorPassed: evaluation.passed ? 1 : 0,
      evaluatorConfidence: evaluation.confidence,
      revealedAfterAttempt: updatedVerseState.revealed ? 1 : 0,
      retrievalStrength: retrievalStrength,
      attemptDay: localDayIndex(effectiveNow),
      attemptSeconds: nowLocalSecondsSinceMidnight(effectiveNow),
    );

    final existingProficiency = await _companionRepo.getStepProficiency(
      unitId: state.unitId,
      surah: currentVerseState.verse.surah,
      ayah: currentVerseState.verse.ayah,
    );

    final attemptsCount = (existingProficiency?.attemptsCount ?? 0) + 1;
    final passesCount =
        (existingProficiency?.passesCount ?? 0) + (evaluation.passed ? 1 : 0);

    await _companionRepo.upsertStepProficiency(
      unitId: state.unitId,
      surah: currentVerseState.verse.surah,
      ayah: currentVerseState.verse.ayah,
      proficiencyEma: updatedVerseState.proficiency,
      lastHintLevel: state.currentHintLevel.code,
      lastEvaluatorConfidence: evaluation.confidence,
      lastLatencyToStartMs: latencyToStartMs,
      attemptsCount: attemptsCount,
      passesCount: passesCount,
      lastUpdatedDay: localDayIndex(effectiveNow),
      lastSessionId: state.sessionId,
    );

    final telemetry = VerseAttemptTelemetry(
      stage: state.activeStage,
      hintLevel: state.currentHintLevel,
      latencyToStartMs: latencyToStartMs,
      stopsCount: stopsCount,
      selfCorrectionsCount: selfCorrectionsCount,
      evaluatorPassed: evaluation.passed,
      evaluatorConfidence: evaluation.confidence,
      evaluatorMode: evaluation.mode,
      revealedAfterAttempt: updatedVerseState.revealed,
      retrievalStrength: retrievalStrength,
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
        state: state,
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

  Future<ChainResultSummary> _completeSession({
    required ChainRunState state,
    required List<ChainVerseState> verseStates,
    required DateTime nowLocal,
  }) async {
    final attempts = await _companionRepo.getAttemptsForSession(state.sessionId);
    final avgHint = attempts.isEmpty
        ? 0.0
        : attempts
                .map((attempt) => HintLevel.fromCode(attempt.hintLevel).order)
                .reduce((a, b) => a + b) /
            attempts.length;

    final avgStrength = attempts.isEmpty
        ? 0.0
        : attempts
                .map((attempt) => attempt.retrievalStrength)
                .reduce((a, b) => a + b) /
            attempts.length;

    final summary = ChainResultSummary(
      sessionId: state.sessionId,
      resultKind: ChainResultKind.completed,
      totalVerses: verseStates.length,
      passedVerses: verseStates.where((verse) => verse.passed).length,
      averageHintLevel: avgHint,
      averageRetrievalStrength: avgStrength,
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
        nextIndex =
                _nextUnpassedIndex(verseStates, startAfter: currentIndex) ??
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
