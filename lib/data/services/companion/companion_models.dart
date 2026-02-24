enum HintLevel {
  h0(code: 'h0', order: 0),
  letters(code: 'letters', order: 1),
  firstWord(code: 'first_word', order: 2),
  meaningCue(code: 'meaning_cue', order: 3),
  chunkText(code: 'chunk_text', order: 4),
  fullText(code: 'full_text', order: 5);

  const HintLevel({
    required this.code,
    required this.order,
  });

  final String code;
  final int order;

  static HintLevel fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) {
        return value;
      }
    }
    return HintLevel.h0;
  }

  HintLevel next() {
    final nextOrder = order + 1;
    for (final value in values) {
      if (value.order == nextOrder) {
        return value;
      }
    }
    return this;
  }
}

enum Stage1Mode {
  modelEcho(code: 'model_echo'),
  coldProbe(code: 'cold_probe'),
  correction(code: 'correction'),
  spacedReprobe(code: 'spaced_reprobe'),
  checkpoint(code: 'checkpoint'),
  cumulativeCheck(code: 'cumulative_check');

  const Stage1Mode({required this.code});

  final String code;
}

enum Stage1Phase {
  acquisition(code: 'acquisition'),
  spacedConfirmation(code: 'spaced_confirmation'),
  checkpoint(code: 'checkpoint'),
  remediation(code: 'remediation'),
  cumulativeCheck(code: 'cumulative_check'),
  completed(code: 'completed'),
  budgetFallback(code: 'budget_fallback'),
  skipped(code: 'skipped');

  const Stage1Phase({required this.code});

  final String code;
}

enum Stage1AutoCheckType {
  nextWordMcq(code: 'next_word_mcq'),
  oneWordCloze(code: 'one_word_cloze'),
  ordering(code: 'ordering');

  const Stage1AutoCheckType({required this.code});

  final String code;
}

enum Stage2Mode {
  minimalCueRecall(code: 'minimal_cue_recall'),
  discrimination(code: 'discrimination'),
  linking(code: 'linking'),
  correction(code: 'correction'),
  checkpoint(code: 'checkpoint'),
  remediation(code: 'remediation');

  const Stage2Mode({required this.code});

  final String code;
}

enum Stage2Phase {
  acquisition(code: 'acquisition'),
  checkpoint(code: 'checkpoint'),
  remediation(code: 'remediation'),
  completed(code: 'completed'),
  budgetFallback(code: 'budget_fallback'),
  skipped(code: 'skipped');

  const Stage2Phase({required this.code});

  final String code;
}

enum Stage3Mode {
  weakPrelude(code: 'weak_prelude'),
  hiddenRecall(code: 'hidden_recall'),
  linking(code: 'linking'),
  discrimination(code: 'discrimination'),
  correction(code: 'correction'),
  checkpoint(code: 'checkpoint'),
  remediation(code: 'remediation');

  const Stage3Mode({required this.code});

  final String code;
}

enum Stage3Phase {
  prelude(code: 'prelude'),
  acquisition(code: 'acquisition'),
  checkpoint(code: 'checkpoint'),
  remediation(code: 'remediation'),
  completed(code: 'completed'),
  budgetFallback(code: 'budget_fallback'),
  skipped(code: 'skipped');

  const Stage3Phase({required this.code});

  final String code;
}

enum CompanionStage {
  guidedVisible(code: 'guided_visible', stageNumber: 1),
  cuedRecall(code: 'cued_recall', stageNumber: 2),
  hiddenReveal(code: 'hidden_reveal', stageNumber: 3);

  const CompanionStage({
    required this.code,
    required this.stageNumber,
  });

  final String code;
  final int stageNumber;

  static CompanionStage fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) {
        return value;
      }
    }
    return CompanionStage.hiddenReveal;
  }

  static CompanionStage fromStageNumber(int? stageNumber) {
    for (final value in values) {
      if (value.stageNumber == stageNumber) {
        return value;
      }
    }
    return CompanionStage.guidedVisible;
  }

  CompanionStage? next() {
    final nextNumber = stageNumber + 1;
    for (final value in values) {
      if (value.stageNumber == nextNumber) {
        return value;
      }
    }
    return null;
  }
}

enum CompanionLaunchMode {
  newMemorization(code: 'new'),
  review(code: 'review');

  const CompanionLaunchMode({required this.code});

  final String code;

  static CompanionLaunchMode fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) {
        return value;
      }
    }
    return CompanionLaunchMode.review;
  }
}

enum EvaluatorMode {
  manualFallback(code: 'manual_fallback'),
  asr(code: 'asr');

  const EvaluatorMode({required this.code});

  final String code;

  static EvaluatorMode fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) {
        return value;
      }
    }
    return EvaluatorMode.manualFallback;
  }
}

enum ChainResultKind {
  completed(code: 'completed'),
  partial(code: 'partial'),
  abandoned(code: 'abandoned');

  const ChainResultKind({required this.code});

  final String code;
}

class Stage1Config {
  const Stage1Config({
    this.echoMinLoops = 2,
    this.echoMaxLoops = 4,
    this.echoDefaultLoops = 3,
    this.minSpacingMs = 120000,
    this.spacingAdaptiveMinMs = 90000,
    this.spacingAdaptiveMaxMs = 150000,
    this.coldWindowSize = 3,
    this.checkpointThreshold = 0.70,
    this.targetSuccessBandMin = 0.70,
    this.targetSuccessBandMax = 0.85,
    this.perVerseCapMinMs = 60000,
    this.perVerseCapMaxMs = 120000,
    this.stage1BudgetMinMs = 120000,
    this.stage1BudgetMaxMs = 480000,
    this.stage1BudgetFractionOfNewTime = 0.30,
    this.maxCheckpointRemediationRounds = 2,
    this.cumulativeCheckMaxVerses = 3,
    this.autoCheckRequiredByDefault = true,
  });

  final int echoMinLoops;
  final int echoMaxLoops;
  final int echoDefaultLoops;
  final int minSpacingMs;
  final int spacingAdaptiveMinMs;
  final int spacingAdaptiveMaxMs;
  final int coldWindowSize;
  final double checkpointThreshold;
  final double targetSuccessBandMin;
  final double targetSuccessBandMax;
  final int perVerseCapMinMs;
  final int perVerseCapMaxMs;
  final int stage1BudgetMinMs;
  final int stage1BudgetMaxMs;
  final double stage1BudgetFractionOfNewTime;
  final int maxCheckpointRemediationRounds;
  final int cumulativeCheckMaxVerses;
  final bool autoCheckRequiredByDefault;

  int stage1ChunkBudgetMs({
    required int ayahCount,
    required double avgNewMinutesPerAyah,
  }) {
    final safeAyahCount = ayahCount < 1 ? 1 : ayahCount;
    final safeAvg = avgNewMinutesPerAyah <= 0 ? 2.0 : avgNewMinutesPerAyah;
    final raw =
        (safeAyahCount * safeAvg * 60000 * stage1BudgetFractionOfNewTime)
            .round();
    return raw.clamp(stage1BudgetMinMs, stage1BudgetMaxMs);
  }

  int perVerseCapMs({
    required int ayahCount,
    required int stage1ChunkBudgetMs,
  }) {
    final safeAyahCount = ayahCount < 1 ? 1 : ayahCount;
    final raw = (stage1ChunkBudgetMs / safeAyahCount).round();
    return raw.clamp(perVerseCapMinMs, perVerseCapMaxMs);
  }
}

class Stage1AutoCheckOption {
  const Stage1AutoCheckOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class Stage1AutoCheckPrompt {
  const Stage1AutoCheckPrompt({
    required this.type,
    required this.stem,
    required this.options,
    required this.correctOptionId,
    required this.normalizedPayload,
  });

  final Stage1AutoCheckType type;
  final String stem;
  final List<Stage1AutoCheckOption> options;
  final String correctOptionId;
  final String normalizedPayload;
}

class Stage2Config {
  const Stage2Config({
    this.readinessWindow = 3,
    this.readinessPassesRequired = 2,
    this.readinessMaxHint = HintLevel.firstWord,
    this.weakRequiredHint = HintLevel.letters,
    this.checkpointThreshold = 0.75,
    this.stage2BudgetFractionOfNewTime = 0.35,
    this.stage2BudgetMinMs = 90000,
    this.stage2BudgetMaxMs = 600000,
    this.perVerseCapMinMs = 45000,
    this.perVerseCapMaxMs = 90000,
    this.maxCheckpointRemediationRounds = 2,
    this.autoCheckRequiredByDefault = true,
    this.discriminationFailureTrigger = 2,
  });

  final int readinessWindow;
  final int readinessPassesRequired;
  final HintLevel readinessMaxHint;
  final HintLevel weakRequiredHint;
  final double checkpointThreshold;
  final double stage2BudgetFractionOfNewTime;
  final int stage2BudgetMinMs;
  final int stage2BudgetMaxMs;
  final int perVerseCapMinMs;
  final int perVerseCapMaxMs;
  final int maxCheckpointRemediationRounds;
  final bool autoCheckRequiredByDefault;
  final int discriminationFailureTrigger;

  int stage2ChunkBudgetMs({
    required int ayahCount,
    required double avgNewMinutesPerAyah,
  }) {
    final safeAyahCount = ayahCount < 1 ? 1 : ayahCount;
    final safeAvg = avgNewMinutesPerAyah <= 0 ? 2.0 : avgNewMinutesPerAyah;
    final raw =
        (safeAyahCount * safeAvg * 60000 * stage2BudgetFractionOfNewTime)
            .round();
    return raw.clamp(stage2BudgetMinMs, stage2BudgetMaxMs);
  }

  int perVerseCapMs({
    required int ayahCount,
    required int stage2ChunkBudgetMs,
  }) {
    final safeAyahCount = ayahCount < 1 ? 1 : ayahCount;
    final raw = (stage2ChunkBudgetMs / safeAyahCount).round();
    return raw.clamp(perVerseCapMinMs, perVerseCapMaxMs);
  }
}

class Stage3Config {
  const Stage3Config({
    this.readinessWindow = 4,
    this.readinessPassesRequired = 3,
    this.readinessMaxHint = HintLevel.letters,
    this.readinessRequiredH0Passes = 2,
    this.weakRequiredH0Passes = 1,
    this.checkpointThreshold = 0.75,
    this.stage3BudgetFractionOfNewTime = 0.35,
    this.stage3BudgetMinMs = 90000,
    this.stage3BudgetMaxMs = 600000,
    this.perVerseCapMinMs = 45000,
    this.perVerseCapMaxMs = 90000,
    this.maxCheckpointRemediationRounds = 2,
    this.autoCheckRequiredByDefault = true,
    this.discriminationFailureTrigger = 2,
    this.randomProbeEveryCountedAttempts = 4,
    this.minSpacingMs = 90000,
    this.targetSuccessBandMin = 0.70,
    this.targetSuccessBandMax = 0.85,
  });

  final int readinessWindow;
  final int readinessPassesRequired;
  final HintLevel readinessMaxHint;
  final int readinessRequiredH0Passes;
  final int weakRequiredH0Passes;
  final double checkpointThreshold;
  final double stage3BudgetFractionOfNewTime;
  final int stage3BudgetMinMs;
  final int stage3BudgetMaxMs;
  final int perVerseCapMinMs;
  final int perVerseCapMaxMs;
  final int maxCheckpointRemediationRounds;
  final bool autoCheckRequiredByDefault;
  final int discriminationFailureTrigger;
  final int randomProbeEveryCountedAttempts;
  final int minSpacingMs;
  final double targetSuccessBandMin;
  final double targetSuccessBandMax;

  int stage3ChunkBudgetMs({
    required int ayahCount,
    required double avgNewMinutesPerAyah,
  }) {
    final safeAyahCount = ayahCount < 1 ? 1 : ayahCount;
    final safeAvg = avgNewMinutesPerAyah <= 0 ? 2.0 : avgNewMinutesPerAyah;
    final raw =
        (safeAyahCount * safeAvg * 60000 * stage3BudgetFractionOfNewTime)
            .round();
    return raw.clamp(stage3BudgetMinMs, stage3BudgetMaxMs);
  }

  int perVerseCapMs({
    required int ayahCount,
    required int stage3ChunkBudgetMs,
  }) {
    final safeAyahCount = ayahCount < 1 ? 1 : ayahCount;
    final raw = (stage3ChunkBudgetMs / safeAyahCount).round();
    return raw.clamp(perVerseCapMinMs, perVerseCapMaxMs);
  }
}

class Stage1ColdWindowEntry {
  const Stage1ColdWindowEntry({
    required this.timestampMs,
    required this.passed,
    required this.hintLevel,
    required this.assisted,
  });

  final int timestampMs;
  final bool passed;
  final HintLevel hintLevel;
  final bool assisted;
}

class Stage1VerseStats {
  const Stage1VerseStats({
    this.modelEchoLoops = 0,
    this.modelEchoExposures = 0,
    this.coldAttempts = 0,
    this.h0Successes = 0,
    this.assistedSuccesses = 0,
    this.spacedH0Successes = 0,
    this.spacedConfirmed = false,
    this.firstColdSuccessAtMs,
    this.lastH0SuccessAtMs,
    this.correctionRequired = false,
    this.weak = false,
    this.seenModelExposure = false,
    this.checkpointAttempted = false,
    this.checkpointPassed = false,
    this.checkpointAttempts = 0,
    this.cumulativeAttempted = false,
    this.cumulativePassed = false,
    this.remediationNeeded = false,
    this.remediationRounds = 0,
    this.timeOnVerseMs = 0,
    this.coldWindow = const <Stage1ColdWindowEntry>[],
  });

  final int modelEchoLoops;
  final int modelEchoExposures;
  final int coldAttempts;
  final int h0Successes;
  final int assistedSuccesses;
  final int spacedH0Successes;
  final bool spacedConfirmed;
  final int? firstColdSuccessAtMs;
  final int? lastH0SuccessAtMs;
  final bool correctionRequired;
  final bool weak;
  final bool seenModelExposure;
  final bool checkpointAttempted;
  final bool checkpointPassed;
  final int checkpointAttempts;
  final bool cumulativeAttempted;
  final bool cumulativePassed;
  final bool remediationNeeded;
  final int remediationRounds;
  final int timeOnVerseMs;
  final List<Stage1ColdWindowEntry> coldWindow;

  bool get hasAnyH0Success => h0Successes > 0;

  bool coldReady({required int coldWindowSize}) {
    final safeWindow = coldWindowSize < 1 ? 1 : coldWindowSize;
    final window = coldWindow.length <= safeWindow
        ? coldWindow
        : coldWindow.sublist(coldWindow.length - safeWindow);
    var unassistedPasses = 0;
    var hasH0Pass = false;
    for (final entry in window) {
      if (entry.passed && !entry.assisted) {
        unassistedPasses += 1;
      }
      if (entry.passed && !entry.assisted && entry.hintLevel == HintLevel.h0) {
        hasH0Pass = true;
      }
    }
    return unassistedPasses >= 2 && hasH0Pass && spacedConfirmed;
  }

  Stage1VerseStats copyWith({
    int? modelEchoLoops,
    int? modelEchoExposures,
    int? coldAttempts,
    int? h0Successes,
    int? assistedSuccesses,
    int? spacedH0Successes,
    bool? spacedConfirmed,
    int? firstColdSuccessAtMs,
    int? lastH0SuccessAtMs,
    bool? correctionRequired,
    bool? weak,
    bool? seenModelExposure,
    bool? checkpointAttempted,
    bool? checkpointPassed,
    int? checkpointAttempts,
    bool? cumulativeAttempted,
    bool? cumulativePassed,
    bool? remediationNeeded,
    int? remediationRounds,
    int? timeOnVerseMs,
    List<Stage1ColdWindowEntry>? coldWindow,
  }) {
    return Stage1VerseStats(
      modelEchoLoops: modelEchoLoops ?? this.modelEchoLoops,
      modelEchoExposures: modelEchoExposures ?? this.modelEchoExposures,
      coldAttempts: coldAttempts ?? this.coldAttempts,
      h0Successes: h0Successes ?? this.h0Successes,
      assistedSuccesses: assistedSuccesses ?? this.assistedSuccesses,
      spacedH0Successes: spacedH0Successes ?? this.spacedH0Successes,
      spacedConfirmed: spacedConfirmed ?? this.spacedConfirmed,
      firstColdSuccessAtMs: firstColdSuccessAtMs ?? this.firstColdSuccessAtMs,
      lastH0SuccessAtMs: lastH0SuccessAtMs ?? this.lastH0SuccessAtMs,
      correctionRequired: correctionRequired ?? this.correctionRequired,
      weak: weak ?? this.weak,
      seenModelExposure: seenModelExposure ?? this.seenModelExposure,
      checkpointAttempted: checkpointAttempted ?? this.checkpointAttempted,
      checkpointPassed: checkpointPassed ?? this.checkpointPassed,
      checkpointAttempts: checkpointAttempts ?? this.checkpointAttempts,
      cumulativeAttempted: cumulativeAttempted ?? this.cumulativeAttempted,
      cumulativePassed: cumulativePassed ?? this.cumulativePassed,
      remediationNeeded: remediationNeeded ?? this.remediationNeeded,
      remediationRounds: remediationRounds ?? this.remediationRounds,
      timeOnVerseMs: timeOnVerseMs ?? this.timeOnVerseMs,
      coldWindow: coldWindow ?? this.coldWindow,
    );
  }
}

class Stage1CheckpointOutcome {
  const Stage1CheckpointOutcome({
    required this.chunkColdPassRate,
    required this.failedVerseIndexes,
    required this.everyVerseHasColdSuccess,
    required this.everyVerseHasSpacedSuccess,
    required this.passed,
  });

  final double chunkColdPassRate;
  final List<int> failedVerseIndexes;
  final bool everyVerseHasColdSuccess;
  final bool everyVerseHasSpacedSuccess;
  final bool passed;
}

class Stage1Runtime {
  const Stage1Runtime({
    required this.config,
    required this.phase,
    required this.mode,
    required this.startedAtEpochMs,
    required this.lastActionAtEpochMs,
    required this.chunkElapsedMs,
    required this.stage1BudgetMs,
    required this.perVerseCapMs,
    required this.adaptiveSpacingMs,
    required this.adaptiveEchoLoopCap,
    required this.hintsUnlockedForCurrentProbe,
    required this.currentProbeAttemptCount,
    required this.totalRetrievalAttempts,
    required this.totalRetrievalPasses,
    required this.budgetExceeded,
    required this.remediationRequiresCheckpoint,
    required this.remediationRounds,
    required this.checkpointTargets,
    required this.checkpointCursor,
    required this.remediationTargets,
    required this.remediationCursor,
    required this.cumulativeTargets,
    required this.cumulativeCursor,
    required this.lastCheckpointOutcome,
    required this.activeAutoCheckPrompt,
  });

  final Stage1Config config;
  final Stage1Phase phase;
  final Stage1Mode mode;
  final int startedAtEpochMs;
  final int lastActionAtEpochMs;
  final int chunkElapsedMs;
  final int stage1BudgetMs;
  final int perVerseCapMs;
  final int adaptiveSpacingMs;
  final int adaptiveEchoLoopCap;
  final bool hintsUnlockedForCurrentProbe;
  final int currentProbeAttemptCount;
  final int totalRetrievalAttempts;
  final int totalRetrievalPasses;
  final bool budgetExceeded;
  final bool remediationRequiresCheckpoint;
  final int remediationRounds;
  final List<int> checkpointTargets;
  final int checkpointCursor;
  final List<int> remediationTargets;
  final int remediationCursor;
  final List<int> cumulativeTargets;
  final int cumulativeCursor;
  final Stage1CheckpointOutcome? lastCheckpointOutcome;
  final Stage1AutoCheckPrompt? activeAutoCheckPrompt;

  bool get autoCheckRequiredForCurrentMode {
    if (!config.autoCheckRequiredByDefault) {
      return false;
    }
    return mode == Stage1Mode.coldProbe ||
        mode == Stage1Mode.spacedReprobe ||
        mode == Stage1Mode.checkpoint ||
        mode == Stage1Mode.cumulativeCheck;
  }

  double get retrievalSuccessRate {
    if (totalRetrievalAttempts <= 0) {
      return 0.0;
    }
    return totalRetrievalPasses / totalRetrievalAttempts;
  }

  Stage1Runtime copyWith({
    Stage1Config? config,
    Stage1Phase? phase,
    Stage1Mode? mode,
    int? startedAtEpochMs,
    int? lastActionAtEpochMs,
    int? chunkElapsedMs,
    int? stage1BudgetMs,
    int? perVerseCapMs,
    int? adaptiveSpacingMs,
    int? adaptiveEchoLoopCap,
    bool? hintsUnlockedForCurrentProbe,
    int? currentProbeAttemptCount,
    int? totalRetrievalAttempts,
    int? totalRetrievalPasses,
    bool? budgetExceeded,
    bool? remediationRequiresCheckpoint,
    int? remediationRounds,
    List<int>? checkpointTargets,
    int? checkpointCursor,
    List<int>? remediationTargets,
    int? remediationCursor,
    List<int>? cumulativeTargets,
    int? cumulativeCursor,
    Object? lastCheckpointOutcome = _runtimeUnset,
    Object? activeAutoCheckPrompt = _runtimeUnset,
  }) {
    return Stage1Runtime(
      config: config ?? this.config,
      phase: phase ?? this.phase,
      mode: mode ?? this.mode,
      startedAtEpochMs: startedAtEpochMs ?? this.startedAtEpochMs,
      lastActionAtEpochMs: lastActionAtEpochMs ?? this.lastActionAtEpochMs,
      chunkElapsedMs: chunkElapsedMs ?? this.chunkElapsedMs,
      stage1BudgetMs: stage1BudgetMs ?? this.stage1BudgetMs,
      perVerseCapMs: perVerseCapMs ?? this.perVerseCapMs,
      adaptiveSpacingMs: adaptiveSpacingMs ?? this.adaptiveSpacingMs,
      adaptiveEchoLoopCap: adaptiveEchoLoopCap ?? this.adaptiveEchoLoopCap,
      hintsUnlockedForCurrentProbe:
          hintsUnlockedForCurrentProbe ?? this.hintsUnlockedForCurrentProbe,
      currentProbeAttemptCount:
          currentProbeAttemptCount ?? this.currentProbeAttemptCount,
      totalRetrievalAttempts:
          totalRetrievalAttempts ?? this.totalRetrievalAttempts,
      totalRetrievalPasses: totalRetrievalPasses ?? this.totalRetrievalPasses,
      budgetExceeded: budgetExceeded ?? this.budgetExceeded,
      remediationRequiresCheckpoint:
          remediationRequiresCheckpoint ?? this.remediationRequiresCheckpoint,
      remediationRounds: remediationRounds ?? this.remediationRounds,
      checkpointTargets: checkpointTargets ?? this.checkpointTargets,
      checkpointCursor: checkpointCursor ?? this.checkpointCursor,
      remediationTargets: remediationTargets ?? this.remediationTargets,
      remediationCursor: remediationCursor ?? this.remediationCursor,
      cumulativeTargets: cumulativeTargets ?? this.cumulativeTargets,
      cumulativeCursor: cumulativeCursor ?? this.cumulativeCursor,
      lastCheckpointOutcome: identical(lastCheckpointOutcome, _runtimeUnset)
          ? this.lastCheckpointOutcome
          : lastCheckpointOutcome as Stage1CheckpointOutcome?,
      activeAutoCheckPrompt: identical(activeAutoCheckPrompt, _runtimeUnset)
          ? this.activeAutoCheckPrompt
          : activeAutoCheckPrompt as Stage1AutoCheckPrompt?,
    );
  }

  static const Object _runtimeUnset = Object();
}

class Stage2WindowEntry {
  const Stage2WindowEntry({
    required this.timestampMs,
    required this.passed,
    required this.countedPass,
    required this.hintLevel,
    required this.assisted,
  });

  final int timestampMs;
  final bool passed;
  final bool countedPass;
  final HintLevel hintLevel;
  final bool assisted;
}

class Stage2VerseStats {
  const Stage2VerseStats({
    this.attempts = 0,
    this.countedAttempts = 0,
    this.countedPasses = 0,
    this.consecutiveFailures = 0,
    this.correctionRequired = false,
    this.reliefPending = false,
    this.weakTarget = false,
    this.remediationNeeded = false,
    this.remediationRounds = 0,
    this.discriminationAttempts = 0,
    this.discriminationPasses = 0,
    this.linkingAttempts = 0,
    this.linkingPassCount = 0,
    this.checkpointAttempted = false,
    this.checkpointPassed = false,
    this.checkpointAttempts = 0,
    this.cueBaselineHint = HintLevel.letters,
    this.lastCueRotatedFrom,
    this.timeOnVerseMs = 0,
    this.readinessWindow = const <Stage2WindowEntry>[],
  });

  final int attempts;
  final int countedAttempts;
  final int countedPasses;
  final int consecutiveFailures;
  final bool correctionRequired;
  final bool reliefPending;
  final bool weakTarget;
  final bool remediationNeeded;
  final int remediationRounds;
  final int discriminationAttempts;
  final int discriminationPasses;
  final int linkingAttempts;
  final int linkingPassCount;
  final bool checkpointAttempted;
  final bool checkpointPassed;
  final int checkpointAttempts;
  final HintLevel cueBaselineHint;
  final HintLevel? lastCueRotatedFrom;
  final int timeOnVerseMs;
  final List<Stage2WindowEntry> readinessWindow;

  bool countedPassesInWindow({
    required int windowSize,
    required int minimumPasses,
  }) {
    final safeWindow = windowSize < 1 ? 1 : windowSize;
    final window = readinessWindow.length <= safeWindow
        ? readinessWindow
        : readinessWindow.sublist(readinessWindow.length - safeWindow);
    final passes = window.where((entry) => entry.countedPass).length;
    return passes >= minimumPasses;
  }

  bool hasCountedPassAtOrBelow(HintLevel maxHint) {
    return readinessWindow.any(
      (entry) => entry.countedPass && entry.hintLevel.order <= maxHint.order,
    );
  }

  bool isReady({
    required Stage2Config config,
    required bool isWeak,
  }) {
    final hasWindowPasses = countedPassesInWindow(
      windowSize: config.readinessWindow,
      minimumPasses: config.readinessPassesRequired,
    );
    if (!hasWindowPasses) {
      return false;
    }
    if (isWeak && !hasCountedPassAtOrBelow(config.weakRequiredHint)) {
      return false;
    }
    return linkingPassCount >= 1;
  }

  Stage2VerseStats copyWith({
    int? attempts,
    int? countedAttempts,
    int? countedPasses,
    int? consecutiveFailures,
    bool? correctionRequired,
    bool? reliefPending,
    bool? weakTarget,
    bool? remediationNeeded,
    int? remediationRounds,
    int? discriminationAttempts,
    int? discriminationPasses,
    int? linkingAttempts,
    int? linkingPassCount,
    bool? checkpointAttempted,
    bool? checkpointPassed,
    int? checkpointAttempts,
    HintLevel? cueBaselineHint,
    Object? lastCueRotatedFrom = _stage2StatsUnset,
    int? timeOnVerseMs,
    List<Stage2WindowEntry>? readinessWindow,
  }) {
    return Stage2VerseStats(
      attempts: attempts ?? this.attempts,
      countedAttempts: countedAttempts ?? this.countedAttempts,
      countedPasses: countedPasses ?? this.countedPasses,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      correctionRequired: correctionRequired ?? this.correctionRequired,
      reliefPending: reliefPending ?? this.reliefPending,
      weakTarget: weakTarget ?? this.weakTarget,
      remediationNeeded: remediationNeeded ?? this.remediationNeeded,
      remediationRounds: remediationRounds ?? this.remediationRounds,
      discriminationAttempts:
          discriminationAttempts ?? this.discriminationAttempts,
      discriminationPasses: discriminationPasses ?? this.discriminationPasses,
      linkingAttempts: linkingAttempts ?? this.linkingAttempts,
      linkingPassCount: linkingPassCount ?? this.linkingPassCount,
      checkpointAttempted: checkpointAttempted ?? this.checkpointAttempted,
      checkpointPassed: checkpointPassed ?? this.checkpointPassed,
      checkpointAttempts: checkpointAttempts ?? this.checkpointAttempts,
      cueBaselineHint: cueBaselineHint ?? this.cueBaselineHint,
      lastCueRotatedFrom: identical(lastCueRotatedFrom, _stage2StatsUnset)
          ? this.lastCueRotatedFrom
          : lastCueRotatedFrom as HintLevel?,
      timeOnVerseMs: timeOnVerseMs ?? this.timeOnVerseMs,
      readinessWindow: readinessWindow ?? this.readinessWindow,
    );
  }

  static const Object _stage2StatsUnset = Object();
}

class Stage2CheckpointOutcome {
  const Stage2CheckpointOutcome({
    required this.chunkPassRate,
    required this.failedVerseIndexes,
    required this.everyVerseReady,
    required this.passed,
  });

  final double chunkPassRate;
  final List<int> failedVerseIndexes;
  final bool everyVerseReady;
  final bool passed;
}

class Stage2Runtime {
  const Stage2Runtime({
    required this.config,
    required this.phase,
    required this.mode,
    required this.startedAtEpochMs,
    required this.lastActionAtEpochMs,
    required this.chunkElapsedMs,
    required this.stage2BudgetMs,
    required this.perVerseCapMs,
    required this.budgetExceeded,
    required this.remediationRounds,
    required this.checkpointTargets,
    required this.checkpointCursor,
    required this.remediationTargets,
    required this.remediationCursor,
    required this.lastCheckpointOutcome,
    required this.activeAutoCheckPrompt,
  });

  final Stage2Config config;
  final Stage2Phase phase;
  final Stage2Mode mode;
  final int startedAtEpochMs;
  final int lastActionAtEpochMs;
  final int chunkElapsedMs;
  final int stage2BudgetMs;
  final int perVerseCapMs;
  final bool budgetExceeded;
  final int remediationRounds;
  final List<int> checkpointTargets;
  final int checkpointCursor;
  final List<int> remediationTargets;
  final int remediationCursor;
  final Stage2CheckpointOutcome? lastCheckpointOutcome;
  final Stage1AutoCheckPrompt? activeAutoCheckPrompt;

  bool get autoCheckRequiredForCurrentMode {
    if (!config.autoCheckRequiredByDefault) {
      return false;
    }
    return mode == Stage2Mode.minimalCueRecall ||
        mode == Stage2Mode.discrimination ||
        mode == Stage2Mode.linking ||
        mode == Stage2Mode.checkpoint ||
        mode == Stage2Mode.remediation;
  }

  Stage2Runtime copyWith({
    Stage2Config? config,
    Stage2Phase? phase,
    Stage2Mode? mode,
    int? startedAtEpochMs,
    int? lastActionAtEpochMs,
    int? chunkElapsedMs,
    int? stage2BudgetMs,
    int? perVerseCapMs,
    bool? budgetExceeded,
    int? remediationRounds,
    List<int>? checkpointTargets,
    int? checkpointCursor,
    List<int>? remediationTargets,
    int? remediationCursor,
    Object? lastCheckpointOutcome = _stage2RuntimeUnset,
    Object? activeAutoCheckPrompt = _stage2RuntimeUnset,
  }) {
    return Stage2Runtime(
      config: config ?? this.config,
      phase: phase ?? this.phase,
      mode: mode ?? this.mode,
      startedAtEpochMs: startedAtEpochMs ?? this.startedAtEpochMs,
      lastActionAtEpochMs: lastActionAtEpochMs ?? this.lastActionAtEpochMs,
      chunkElapsedMs: chunkElapsedMs ?? this.chunkElapsedMs,
      stage2BudgetMs: stage2BudgetMs ?? this.stage2BudgetMs,
      perVerseCapMs: perVerseCapMs ?? this.perVerseCapMs,
      budgetExceeded: budgetExceeded ?? this.budgetExceeded,
      remediationRounds: remediationRounds ?? this.remediationRounds,
      checkpointTargets: checkpointTargets ?? this.checkpointTargets,
      checkpointCursor: checkpointCursor ?? this.checkpointCursor,
      remediationTargets: remediationTargets ?? this.remediationTargets,
      remediationCursor: remediationCursor ?? this.remediationCursor,
      lastCheckpointOutcome:
          identical(lastCheckpointOutcome, _stage2RuntimeUnset)
              ? this.lastCheckpointOutcome
              : lastCheckpointOutcome as Stage2CheckpointOutcome?,
      activeAutoCheckPrompt:
          identical(activeAutoCheckPrompt, _stage2RuntimeUnset)
              ? this.activeAutoCheckPrompt
              : activeAutoCheckPrompt as Stage1AutoCheckPrompt?,
    );
  }

  static const Object _stage2RuntimeUnset = Object();
}

class Stage3WindowEntry {
  const Stage3WindowEntry({
    required this.timestampMs,
    required this.passed,
    required this.countedPass,
    required this.hintLevel,
    required this.assisted,
  });

  final int timestampMs;
  final bool passed;
  final bool countedPass;
  final HintLevel hintLevel;
  final bool assisted;
}

class Stage3VerseStats {
  const Stage3VerseStats({
    this.attempts = 0,
    this.countedAttempts = 0,
    this.countedPasses = 0,
    this.countedH0Passes = 0,
    this.consecutiveFailures = 0,
    this.correctionRequired = false,
    this.reliefPending = false,
    this.weakTarget = false,
    this.remediationNeeded = false,
    this.remediationRounds = 0,
    this.discriminationAttempts = 0,
    this.discriminationPasses = 0,
    this.linkingAttempts = 0,
    this.linkingPassCount = 0,
    this.checkpointAttempted = false,
    this.checkpointPassed = false,
    this.checkpointAttempts = 0,
    this.cueBaselineHint = HintLevel.h0,
    this.lastCueRotatedFrom,
    this.timeOnVerseMs = 0,
    this.readinessWindow = const <Stage3WindowEntry>[],
    this.lastH0SuccessAtMs,
    this.spacedH0Confirmed = false,
  });

  final int attempts;
  final int countedAttempts;
  final int countedPasses;
  final int countedH0Passes;
  final int consecutiveFailures;
  final bool correctionRequired;
  final bool reliefPending;
  final bool weakTarget;
  final bool remediationNeeded;
  final int remediationRounds;
  final int discriminationAttempts;
  final int discriminationPasses;
  final int linkingAttempts;
  final int linkingPassCount;
  final bool checkpointAttempted;
  final bool checkpointPassed;
  final int checkpointAttempts;
  final HintLevel cueBaselineHint;
  final HintLevel? lastCueRotatedFrom;
  final int timeOnVerseMs;
  final List<Stage3WindowEntry> readinessWindow;
  final int? lastH0SuccessAtMs;
  final bool spacedH0Confirmed;

  int _countedPassesInWindow({
    required int windowSize,
  }) {
    final safeWindow = windowSize < 1 ? 1 : windowSize;
    final window = readinessWindow.length <= safeWindow
        ? readinessWindow
        : readinessWindow.sublist(readinessWindow.length - safeWindow);
    return window.where((entry) => entry.countedPass).length;
  }

  int _countedH0PassesInWindow({
    required int windowSize,
  }) {
    final safeWindow = windowSize < 1 ? 1 : windowSize;
    final window = readinessWindow.length <= safeWindow
        ? readinessWindow
        : readinessWindow.sublist(readinessWindow.length - safeWindow);
    return window
        .where(
          (entry) => entry.countedPass && entry.hintLevel == HintLevel.h0,
        )
        .length;
  }

  bool isReady({
    required Stage3Config config,
    required bool isWeak,
  }) {
    if (_countedPassesInWindow(windowSize: config.readinessWindow) <
        config.readinessPassesRequired) {
      return false;
    }
    if (_countedH0PassesInWindow(windowSize: config.readinessWindow) <
        config.readinessRequiredH0Passes) {
      return false;
    }
    if (linkingPassCount < 1) {
      return false;
    }
    if (isWeak && countedH0Passes < config.weakRequiredH0Passes) {
      return false;
    }
    return true;
  }

  Stage3VerseStats copyWith({
    int? attempts,
    int? countedAttempts,
    int? countedPasses,
    int? countedH0Passes,
    int? consecutiveFailures,
    bool? correctionRequired,
    bool? reliefPending,
    bool? weakTarget,
    bool? remediationNeeded,
    int? remediationRounds,
    int? discriminationAttempts,
    int? discriminationPasses,
    int? linkingAttempts,
    int? linkingPassCount,
    bool? checkpointAttempted,
    bool? checkpointPassed,
    int? checkpointAttempts,
    HintLevel? cueBaselineHint,
    Object? lastCueRotatedFrom = _stage3StatsUnset,
    int? timeOnVerseMs,
    List<Stage3WindowEntry>? readinessWindow,
    Object? lastH0SuccessAtMs = _stage3StatsUnset,
    bool? spacedH0Confirmed,
  }) {
    return Stage3VerseStats(
      attempts: attempts ?? this.attempts,
      countedAttempts: countedAttempts ?? this.countedAttempts,
      countedPasses: countedPasses ?? this.countedPasses,
      countedH0Passes: countedH0Passes ?? this.countedH0Passes,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      correctionRequired: correctionRequired ?? this.correctionRequired,
      reliefPending: reliefPending ?? this.reliefPending,
      weakTarget: weakTarget ?? this.weakTarget,
      remediationNeeded: remediationNeeded ?? this.remediationNeeded,
      remediationRounds: remediationRounds ?? this.remediationRounds,
      discriminationAttempts:
          discriminationAttempts ?? this.discriminationAttempts,
      discriminationPasses: discriminationPasses ?? this.discriminationPasses,
      linkingAttempts: linkingAttempts ?? this.linkingAttempts,
      linkingPassCount: linkingPassCount ?? this.linkingPassCount,
      checkpointAttempted: checkpointAttempted ?? this.checkpointAttempted,
      checkpointPassed: checkpointPassed ?? this.checkpointPassed,
      checkpointAttempts: checkpointAttempts ?? this.checkpointAttempts,
      cueBaselineHint: cueBaselineHint ?? this.cueBaselineHint,
      lastCueRotatedFrom: identical(lastCueRotatedFrom, _stage3StatsUnset)
          ? this.lastCueRotatedFrom
          : lastCueRotatedFrom as HintLevel?,
      timeOnVerseMs: timeOnVerseMs ?? this.timeOnVerseMs,
      readinessWindow: readinessWindow ?? this.readinessWindow,
      lastH0SuccessAtMs: identical(lastH0SuccessAtMs, _stage3StatsUnset)
          ? this.lastH0SuccessAtMs
          : lastH0SuccessAtMs as int?,
      spacedH0Confirmed: spacedH0Confirmed ?? this.spacedH0Confirmed,
    );
  }

  static const Object _stage3StatsUnset = Object();
}

class Stage3CheckpointOutcome {
  const Stage3CheckpointOutcome({
    required this.chunkPassRate,
    required this.failedVerseIndexes,
    required this.everyVerseReady,
    required this.weakPreludeCleared,
    required this.passed,
  });

  final double chunkPassRate;
  final List<int> failedVerseIndexes;
  final bool everyVerseReady;
  final bool weakPreludeCleared;
  final bool passed;
}

class Stage3Runtime {
  const Stage3Runtime({
    required this.config,
    required this.phase,
    required this.mode,
    required this.startedAtEpochMs,
    required this.lastActionAtEpochMs,
    required this.chunkElapsedMs,
    required this.stage3BudgetMs,
    required this.perVerseCapMs,
    required this.budgetExceeded,
    required this.remediationRounds,
    required this.checkpointTargets,
    required this.checkpointCursor,
    required this.remediationTargets,
    required this.remediationCursor,
    required this.lastCheckpointOutcome,
    required this.activeAutoCheckPrompt,
    required this.totalCountableAttempts,
  });

  final Stage3Config config;
  final Stage3Phase phase;
  final Stage3Mode mode;
  final int startedAtEpochMs;
  final int lastActionAtEpochMs;
  final int chunkElapsedMs;
  final int stage3BudgetMs;
  final int perVerseCapMs;
  final bool budgetExceeded;
  final int remediationRounds;
  final List<int> checkpointTargets;
  final int checkpointCursor;
  final List<int> remediationTargets;
  final int remediationCursor;
  final Stage3CheckpointOutcome? lastCheckpointOutcome;
  final Stage1AutoCheckPrompt? activeAutoCheckPrompt;
  final int totalCountableAttempts;

  bool get autoCheckRequiredForCurrentMode {
    if (!config.autoCheckRequiredByDefault) {
      return false;
    }
    return mode == Stage3Mode.weakPrelude ||
        mode == Stage3Mode.hiddenRecall ||
        mode == Stage3Mode.linking ||
        mode == Stage3Mode.discrimination ||
        mode == Stage3Mode.checkpoint ||
        mode == Stage3Mode.remediation;
  }

  Stage3Runtime copyWith({
    Stage3Config? config,
    Stage3Phase? phase,
    Stage3Mode? mode,
    int? startedAtEpochMs,
    int? lastActionAtEpochMs,
    int? chunkElapsedMs,
    int? stage3BudgetMs,
    int? perVerseCapMs,
    bool? budgetExceeded,
    int? remediationRounds,
    List<int>? checkpointTargets,
    int? checkpointCursor,
    List<int>? remediationTargets,
    int? remediationCursor,
    Object? lastCheckpointOutcome = _stage3RuntimeUnset,
    Object? activeAutoCheckPrompt = _stage3RuntimeUnset,
    int? totalCountableAttempts,
  }) {
    return Stage3Runtime(
      config: config ?? this.config,
      phase: phase ?? this.phase,
      mode: mode ?? this.mode,
      startedAtEpochMs: startedAtEpochMs ?? this.startedAtEpochMs,
      lastActionAtEpochMs: lastActionAtEpochMs ?? this.lastActionAtEpochMs,
      chunkElapsedMs: chunkElapsedMs ?? this.chunkElapsedMs,
      stage3BudgetMs: stage3BudgetMs ?? this.stage3BudgetMs,
      perVerseCapMs: perVerseCapMs ?? this.perVerseCapMs,
      budgetExceeded: budgetExceeded ?? this.budgetExceeded,
      remediationRounds: remediationRounds ?? this.remediationRounds,
      checkpointTargets: checkpointTargets ?? this.checkpointTargets,
      checkpointCursor: checkpointCursor ?? this.checkpointCursor,
      remediationTargets: remediationTargets ?? this.remediationTargets,
      remediationCursor: remediationCursor ?? this.remediationCursor,
      lastCheckpointOutcome:
          identical(lastCheckpointOutcome, _stage3RuntimeUnset)
              ? this.lastCheckpointOutcome
              : lastCheckpointOutcome as Stage3CheckpointOutcome?,
      activeAutoCheckPrompt:
          identical(activeAutoCheckPrompt, _stage3RuntimeUnset)
              ? this.activeAutoCheckPrompt
              : activeAutoCheckPrompt as Stage1AutoCheckPrompt?,
      totalCountableAttempts:
          totalCountableAttempts ?? this.totalCountableAttempts,
    );
  }

  static const Object _stage3RuntimeUnset = Object();
}

class ChainVerse {
  const ChainVerse({
    required this.surah,
    required this.ayah,
    required this.text,
  });

  final int surah;
  final int ayah;
  final String text;
}

class ProgressiveRevealChainConfig {
  const ProgressiveRevealChainConfig({
    this.maxAttemptsBeforeInterleave = 3,
    this.maxInterleaveCyclesPerVerse = 2,
    this.proficiencyEmaAlpha = 0.30,
    this.defaultAvgNewMinutesPerAyah = 2.0,
    this.stage1 = const Stage1Config(),
    this.stage2 = const Stage2Config(),
    this.stage3 = const Stage3Config(),
  });

  final int maxAttemptsBeforeInterleave;
  final int maxInterleaveCyclesPerVerse;
  final double proficiencyEmaAlpha;
  final double defaultAvgNewMinutesPerAyah;
  final Stage1Config stage1;
  final Stage2Config stage2;
  final Stage3Config stage3;
}

class VerseAttemptTelemetry {
  const VerseAttemptTelemetry({
    required this.stage,
    required this.hintLevel,
    required this.latencyToStartMs,
    required this.stopsCount,
    required this.selfCorrectionsCount,
    required this.evaluatorPassed,
    required this.evaluatorConfidence,
    required this.evaluatorMode,
    required this.revealedAfterAttempt,
    required this.retrievalStrength,
    this.attemptType = 'probe',
    this.assisted = false,
    this.autoCheckType,
    this.autoCheckResult,
    this.timeOnVerseMs = 0,
    this.timeOnChunkMs = 0,
    this.stage1Mode,
    this.stage2Mode,
    this.stage2Phase,
    this.stage3Mode,
    this.stage3Phase,
    this.correctionRequiredAfterAttempt = false,
  });

  final CompanionStage stage;
  final HintLevel hintLevel;
  final int latencyToStartMs;
  final int stopsCount;
  final int selfCorrectionsCount;
  final bool evaluatorPassed;
  final double? evaluatorConfidence;
  final EvaluatorMode evaluatorMode;
  final bool revealedAfterAttempt;
  final double retrievalStrength;
  final String attemptType;
  final bool assisted;
  final String? autoCheckType;
  final String? autoCheckResult;
  final int timeOnVerseMs;
  final int timeOnChunkMs;
  final Stage1Mode? stage1Mode;
  final Stage2Mode? stage2Mode;
  final Stage2Phase? stage2Phase;
  final Stage3Mode? stage3Mode;
  final Stage3Phase? stage3Phase;
  final bool correctionRequiredAfterAttempt;
}

class ChainVerseState {
  const ChainVerseState({
    required this.verse,
    required this.revealed,
    required this.passed,
    required this.passedGuidedVisible,
    required this.passedCuedRecall,
    required this.attemptCount,
    required this.hiddenAttemptCount,
    required this.interleaveCycles,
    required this.highestHintLevel,
    required this.proficiency,
    required this.stage1,
    required this.stage2,
    this.stage3 = const Stage3VerseStats(),
  });

  final ChainVerse verse;
  final bool revealed;
  final bool passed;
  final bool passedGuidedVisible;
  final bool passedCuedRecall;
  final int attemptCount;
  final int hiddenAttemptCount;
  final int interleaveCycles;
  final HintLevel highestHintLevel;
  final double proficiency;
  final Stage1VerseStats stage1;
  final Stage2VerseStats stage2;
  final Stage3VerseStats stage3;

  bool passedForStage(CompanionStage stage) {
    return switch (stage) {
      CompanionStage.guidedVisible => passedGuidedVisible,
      CompanionStage.cuedRecall => passedCuedRecall,
      CompanionStage.hiddenReveal => passed,
    };
  }

  ChainVerseState markPassedForStage(CompanionStage stage) {
    return switch (stage) {
      CompanionStage.guidedVisible => copyWith(passedGuidedVisible: true),
      CompanionStage.cuedRecall => copyWith(passedCuedRecall: true),
      CompanionStage.hiddenReveal => copyWith(
          passed: true,
          revealed: true,
        ),
    };
  }

  ChainVerseState copyWith({
    bool? revealed,
    bool? passed,
    bool? passedGuidedVisible,
    bool? passedCuedRecall,
    int? attemptCount,
    int? hiddenAttemptCount,
    int? interleaveCycles,
    HintLevel? highestHintLevel,
    double? proficiency,
    Stage1VerseStats? stage1,
    Stage2VerseStats? stage2,
    Stage3VerseStats? stage3,
  }) {
    return ChainVerseState(
      verse: verse,
      revealed: revealed ?? this.revealed,
      passed: passed ?? this.passed,
      passedGuidedVisible: passedGuidedVisible ?? this.passedGuidedVisible,
      passedCuedRecall: passedCuedRecall ?? this.passedCuedRecall,
      attemptCount: attemptCount ?? this.attemptCount,
      hiddenAttemptCount: hiddenAttemptCount ?? this.hiddenAttemptCount,
      interleaveCycles: interleaveCycles ?? this.interleaveCycles,
      highestHintLevel: highestHintLevel ?? this.highestHintLevel,
      proficiency: proficiency ?? this.proficiency,
      stage1: stage1 ?? this.stage1,
      stage2: stage2 ?? this.stage2,
      stage3: stage3 ?? this.stage3,
    );
  }
}

class ChainRunState {
  const ChainRunState({
    required this.sessionId,
    required this.unitId,
    required this.launchMode,
    required this.activeStage,
    required this.unlockedStage,
    required this.verses,
    required this.currentVerseIndex,
    required this.currentHintLevel,
    required this.returnVerseIndex,
    required this.completed,
    required this.resultKind,
    required this.stage1,
    required this.stage2,
    this.stage3,
    required this.stage3WeakPreludeTargets,
    required this.stage3WeakPreludeCursor,
    required this.resolvedAvgNewMinutesPerAyah,
  });

  final int sessionId;
  final int unitId;
  final CompanionLaunchMode launchMode;
  final CompanionStage activeStage;
  final CompanionStage unlockedStage;
  final List<ChainVerseState> verses;
  final int currentVerseIndex;
  final HintLevel currentHintLevel;
  final int? returnVerseIndex;
  final bool completed;
  final ChainResultKind resultKind;
  final Stage1Runtime? stage1;
  final Stage2Runtime? stage2;
  final Stage3Runtime? stage3;
  final List<int> stage3WeakPreludeTargets;
  final int stage3WeakPreludeCursor;
  final double resolvedAvgNewMinutesPerAyah;

  ChainVerseState get currentVerse => verses[currentVerseIndex];

  bool get isReviewMode => launchMode == CompanionLaunchMode.review;

  int get totalVerses => verses.length;

  int get passedVerses => verses.where((verse) => verse.passed).length;

  bool stagePassed(CompanionStage stage) {
    return verses.every((verse) => verse.passedForStage(stage));
  }

  int firstUnpassedVerseIndexForStage(CompanionStage stage) {
    for (var i = 0; i < verses.length; i++) {
      if (!verses[i].passedForStage(stage)) {
        return i;
      }
    }
    return 0;
  }

  ChainRunState copyWith({
    CompanionStage? activeStage,
    CompanionStage? unlockedStage,
    List<ChainVerseState>? verses,
    int? currentVerseIndex,
    HintLevel? currentHintLevel,
    int? returnVerseIndex,
    bool? completed,
    ChainResultKind? resultKind,
    Object? stage1 = _stateUnset,
    Object? stage2 = _stateUnset,
    Object? stage3 = _stateUnset,
    List<int>? stage3WeakPreludeTargets,
    int? stage3WeakPreludeCursor,
    double? resolvedAvgNewMinutesPerAyah,
  }) {
    return ChainRunState(
      sessionId: sessionId,
      unitId: unitId,
      launchMode: launchMode,
      activeStage: activeStage ?? this.activeStage,
      unlockedStage: unlockedStage ?? this.unlockedStage,
      verses: verses ?? this.verses,
      currentVerseIndex: currentVerseIndex ?? this.currentVerseIndex,
      currentHintLevel: currentHintLevel ?? this.currentHintLevel,
      returnVerseIndex: returnVerseIndex,
      completed: completed ?? this.completed,
      resultKind: resultKind ?? this.resultKind,
      stage1: identical(stage1, _stateUnset)
          ? this.stage1
          : stage1 as Stage1Runtime?,
      stage2: identical(stage2, _stateUnset)
          ? this.stage2
          : stage2 as Stage2Runtime?,
      stage3: identical(stage3, _stateUnset)
          ? this.stage3
          : stage3 as Stage3Runtime?,
      stage3WeakPreludeTargets:
          stage3WeakPreludeTargets ?? this.stage3WeakPreludeTargets,
      stage3WeakPreludeCursor:
          stage3WeakPreludeCursor ?? this.stage3WeakPreludeCursor,
      resolvedAvgNewMinutesPerAyah:
          resolvedAvgNewMinutesPerAyah ?? this.resolvedAvgNewMinutesPerAyah,
    );
  }

  static const Object _stateUnset = Object();
}

class ChainResultSummary {
  const ChainResultSummary({
    required this.sessionId,
    required this.resultKind,
    required this.totalVerses,
    required this.passedVerses,
    required this.averageHintLevel,
    required this.averageRetrievalStrength,
    this.stage1DurationMs = 0,
    this.weakVerseCount = 0,
    this.chunkColdPassRate = 0,
    this.stage1BudgetExceeded = false,
  });

  final int sessionId;
  final ChainResultKind resultKind;
  final int totalVerses;
  final int passedVerses;
  final double averageHintLevel;
  final double averageRetrievalStrength;
  final int stage1DurationMs;
  final int weakVerseCount;
  final double chunkColdPassRate;
  final bool stage1BudgetExceeded;
}

class CompanionUnitState {
  const CompanionUnitState({
    required this.unitId,
    required this.unlockedStage,
    required this.updatedAtDay,
    required this.updatedAtSeconds,
  });

  final int unitId;
  final CompanionStage unlockedStage;
  final int updatedAtDay;
  final int updatedAtSeconds;
}

class CompanionStageEvent {
  const CompanionStageEvent({
    required this.id,
    required this.sessionId,
    required this.unitId,
    required this.fromStage,
    required this.toStage,
    required this.eventType,
    required this.triggerVerseOrder,
    required this.createdDay,
    required this.createdSeconds,
  });

  final int id;
  final int sessionId;
  final int unitId;
  final CompanionStage fromStage;
  final CompanionStage toStage;
  final String eventType;
  final int? triggerVerseOrder;
  final int createdDay;
  final int createdSeconds;
}

double computeRetrievalStrength({
  required bool passed,
  required HintLevel hintLevel,
  required int latencyToStartMs,
  required int stopsCount,
  required int selfCorrectionsCount,
  required double? confidence,
}) {
  final hintPenalty = hintLevel.order * 0.12;
  final latencyPenalty = (latencyToStartMs / 8000.0).clamp(0.0, 0.20);
  final stopPenalty = (stopsCount * 0.04).clamp(0.0, 0.12);
  final selfCorrectionPenalty = (selfCorrectionsCount * 0.03).clamp(0.0, 0.12);
  final confidenceBonus =
      confidence == null ? 0.0 : ((confidence - 0.5) * 0.2).clamp(-0.1, 0.1);

  final base = passed ? 1.0 : 0.35;
  final strength = base -
      hintPenalty -
      latencyPenalty -
      stopPenalty -
      selfCorrectionPenalty +
      confidenceBonus;

  return strength.clamp(0.0, 1.0);
}
