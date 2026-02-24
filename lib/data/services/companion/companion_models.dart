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
  });

  final int maxAttemptsBeforeInterleave;
  final int maxInterleaveCyclesPerVerse;
  final double proficiencyEmaAlpha;
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
    );
  }
}

class ChainResultSummary {
  const ChainResultSummary({
    required this.sessionId,
    required this.resultKind,
    required this.totalVerses,
    required this.passedVerses,
    required this.averageHintLevel,
    required this.averageRetrievalStrength,
  });

  final int sessionId;
  final ChainResultKind resultKind;
  final int totalVerses;
  final int passedVerses;
  final double averageHintLevel;
  final double averageRetrievalStrength;
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
