import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/calibration_repo.dart';
import 'package:hifz_planner/data/repositories/companion_repo.dart';
import 'package:hifz_planner/data/services/companion/companion_calibration_bridge.dart';
import 'package:hifz_planner/data/services/companion/companion_models.dart';
import 'package:hifz_planner/data/services/companion/progressive_reveal_chain_engine.dart';
import 'package:hifz_planner/data/services/companion/verse_evaluator.dart';

void main() {
  late AppDatabase db;
  late CompanionRepo companionRepo;
  late ProgressiveRevealChainEngine engine;
  const evaluator = ManualFallbackVerseEvaluator();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    companionRepo = CompanionRepo(db);
    engine = ProgressiveRevealChainEngine(
      companionRepo,
      CompanionCalibrationBridge(CalibrationRepo(db)),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> createUnit(String key, {int endAyah = 3}) {
    return db.into(db.memUnit).insert(
          MemUnitCompanion.insert(
            kind: 'ayah_range',
            unitKey: key,
            startSurah: const Value(1),
            startAyah: const Value(1),
            endSurah: const Value(1),
            endAyah: Value(endAyah),
            createdAtDay: 100,
            updatedAtDay: 100,
          ),
        );
  }

  ProgressiveRevealChainConfig configForStage1(Stage1Config stage1) {
    return ProgressiveRevealChainConfig(stage1: stage1);
  }

  ProgressiveRevealChainConfig configForStage2(Stage2Config stage2) {
    return ProgressiveRevealChainConfig(stage2: stage2);
  }

  String correctOption(ChainRunState state) {
    final prompt =
        state.stage1?.activeAutoCheckPrompt ?? state.stage2?.activeAutoCheckPrompt;
    expect(prompt, isNotNull);
    return prompt!.correctOptionId;
  }

  test('forces cold probe after model-echo cap', () async {
    final unitId = await createUnit('stage1-echo-cap', endAyah: 1);
    const stage1 = Stage1Config(
      echoMinLoops: 2,
      echoMaxLoops: 4,
      echoDefaultLoops: 2,
    );
    final config = configForStage1(stage1);
    var now = DateTime(2026, 2, 24, 8, 0, 0);

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'الحمد لله رب العالمين'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      config: config,
      nowLocal: now,
    );

    now = now.add(const Duration(seconds: 1));
    var update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      config: config,
      nowLocal: now,
    );
    state = update.state;
    expect(state.stage1?.mode, Stage1Mode.modelEcho);

    now = now.add(const Duration(seconds: 1));
    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      config: config,
      nowLocal: now,
    );
    state = update.state;
    expect(state.stage1?.mode, Stage1Mode.coldProbe);

    final attempts = await companionRepo.getAttemptsForSession(state.sessionId);
    expect(attempts.where((entry) => entry.attemptType == 'encode_echo').length, 2);
  });

  test('locks hints for first H0 cold attempt, then unlocks', () async {
    final unitId = await createUnit('stage1-h0-lock', endAyah: 1);
    const stage1 = Stage1Config(
      echoMinLoops: 1,
      echoMaxLoops: 2,
      echoDefaultLoops: 1,
    );
    final config = configForStage1(stage1);

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'مالك يوم الدين'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 8, 0, 0),
    );

    var update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 8, 0, 1),
    );
    state = update.state;
    expect(state.stage1?.mode, Stage1Mode.coldProbe);
    expect(state.currentHintLevel, HintLevel.h0);

    final lockedHintState = engine.requestHint(state);
    expect(lockedHintState.currentHintLevel, HintLevel.h0);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 8, 0, 5),
    );
    state = update.state;

    final unlockedHintState = engine.requestHint(state);
    expect(unlockedHintState.currentHintLevel, HintLevel.letters);
  });

  test('enforces correction exposure before next cold attempt', () async {
    final unitId = await createUnit('stage1-correction-gate', endAyah: 1);
    const stage1 = Stage1Config(
      echoMinLoops: 1,
      echoMaxLoops: 1,
      echoDefaultLoops: 1,
    );
    final config = configForStage1(stage1);

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'إياك نعبد وإياك نستعين'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 8, 0, 0),
    );

    var update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 8, 0, 1),
    );
    state = update.state;
    expect(state.stage1?.mode, Stage1Mode.coldProbe);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: false,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 8, 0, 2),
    );
    state = update.state;
    expect(state.stage1?.mode, Stage1Mode.correction);
    expect(update.telemetry.correctionRequiredAfterAttempt, isTrue);

    await expectLater(
      engine.submitAttempt(
        state: state,
        evaluator: evaluator,
        manualFallbackPass: true,
        selectedAutoCheckOptionId: null,
        config: config,
        nowLocal: DateTime(2026, 2, 24, 8, 0, 3),
      ),
      throwsA(isA<StateError>()),
    );

    final correction = await engine.submitCorrectionExposure(
      state: state,
      nowLocal: DateTime(2026, 2, 24, 8, 0, 4),
    );
    state = correction.state;
    expect(state.stage1?.mode, Stage1Mode.coldProbe);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 8, 2, 10),
    );
    expect(update.state.stage1?.mode, isNot(Stage1Mode.correction));
  });

  test('requires real time gap for per-verse spaced cold success', () async {
    final unitId = await createUnit('stage1-spacing', endAyah: 1);
    const stage1 = Stage1Config(
      echoMinLoops: 1,
      echoMaxLoops: 1,
      echoDefaultLoops: 1,
      minSpacingMs: 120000,
      spacingAdaptiveMinMs: 120000,
      spacingAdaptiveMaxMs: 120000,
    );
    final config = configForStage1(stage1);

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'اهدنا الصراط المستقيم'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 8, 0, 0),
    );

    var update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 8, 0, 1),
    );
    state = update.state;
    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 8, 0, 2),
    );
    state = update.state;
    expect(state.verses.first.stage1.spacedConfirmed, isFalse);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 8, 0, 3),
    );
    state = update.state;
    expect(state.stage1?.mode, Stage1Mode.spacedReprobe);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 8, 1, 0),
    );
    state = update.state;
    expect(state.verses.first.stage1.spacedConfirmed, isFalse);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 8, 1, 1),
    );
    state = update.state;
    expect(state.stage1?.mode, Stage1Mode.spacedReprobe);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 8, 3, 2),
    );
    state = update.state;
    expect(state.verses.first.stage1.spacedConfirmed, isTrue);
  });

  test('checkpoint failure remediates only failed verse indexes', () async {
    final unitId = await createUnit('stage1-checkpoint-remediation', endAyah: 2);
    const stage1 = Stage1Config(
      echoMinLoops: 1,
      echoMaxLoops: 1,
      echoDefaultLoops: 1,
      minSpacingMs: 1000,
      spacingAdaptiveMinMs: 1000,
      spacingAdaptiveMaxMs: 1000,
      checkpointThreshold: 0.70,
    );
    final config = configForStage1(stage1);

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'الرحمن الرحيم'),
        ChainVerse(surah: 1, ayah: 2, text: 'مالك يوم الدين'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 8, 0, 0),
    );

    DateTime at(int second) => DateTime(2026, 2, 24, 8, 0, second);

    ChainAttemptUpdate update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      config: config,
      nowLocal: at(1),
    );
    state = update.state;
    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: at(2),
    );
    state = update.state;

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      config: config,
      nowLocal: at(3),
    );
    state = update.state;
    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: at(4),
    );
    state = update.state;

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: at(5),
    );
    state = update.state;
    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: at(6),
    );
    state = update.state;
    expect(state.stage1?.mode, Stage1Mode.checkpoint);
    expect(state.currentVerseIndex, 0);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: false,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: at(7),
    );
    state = update.state;
    expect(state.stage1?.mode, Stage1Mode.correction);

    final correction = await engine.submitCorrectionExposure(
      state: state,
      nowLocal: at(8),
    );
    state = correction.state;
    expect(state.stage1?.mode, Stage1Mode.checkpoint);

    final hinted = engine.requestHint(state);
    expect(hinted.currentHintLevel, HintLevel.letters);

    update = await engine.submitAttempt(
      state: hinted,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(hinted),
      config: config,
      nowLocal: at(9),
    );
    state = update.state;
    expect(state.stage1?.mode, Stage1Mode.checkpoint);
    expect(state.currentVerseIndex, 1);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: at(10),
    );
    state = update.state;
    expect(state.stage1?.phase, Stage1Phase.remediation);
    expect(state.stage1?.remediationTargets, const <int>[0]);
    expect(state.currentVerseIndex, 0);
    expect(state.verses[0].stage1.remediationNeeded, isTrue);
    expect(state.verses[1].stage1.remediationNeeded, isFalse);
  });

  test('budget fallback marks weak verses and advances to Stage 2', () async {
    final unitId = await createUnit('stage1-budget-fallback', endAyah: 2);
    const stage1 = Stage1Config(
      echoMinLoops: 1,
      echoMaxLoops: 1,
      echoDefaultLoops: 1,
      stage1BudgetMinMs: 1,
      stage1BudgetMaxMs: 1,
      stage1BudgetFractionOfNewTime: 0.01,
      perVerseCapMinMs: 1,
      perVerseCapMaxMs: 1,
    );
    final config = configForStage1(stage1);

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'اهدنا'),
        ChainVerse(surah: 1, ayah: 2, text: 'الصراط'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 8, 0, 0),
    );

    final update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 8, 0, 3),
    );
    state = update.state;

    expect(state.activeStage, CompanionStage.cuedRecall);
    expect(state.stage1?.phase, Stage1Phase.budgetFallback);
    expect(state.stage1?.budgetExceeded, isTrue);
    expect(state.verses.every((verse) => verse.stage1.seenModelExposure), isTrue);
    expect(state.verses.every((verse) => verse.stage1.weak), isTrue);
  });

  test('Stage 1 skip marks unresolved verses weak and advances', () async {
    final unitId = await createUnit('stage1-skip-weak', endAyah: 2);

    final state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'نعبد'),
        ChainVerse(surah: 1, ayah: 2, text: 'نستعين'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      nowLocal: DateTime(2026, 2, 24, 8, 0, 0),
    );

    final skipped = await engine.skipCurrentStage(
      state: state,
      nowLocal: DateTime(2026, 2, 24, 8, 0, 10),
    );

    expect(skipped.activeStage, CompanionStage.cuedRecall);
    expect(skipped.verses.every((verse) => verse.stage1.weak), isTrue);
  });

  test('Stage 2 runtime activates and cue baseline fades after counted pass',
      () async {
    final unitId = await createUnit('stage2-activation', endAyah: 1);
    final config = configForStage2(const Stage2Config());

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'اهدنا الصراط المستقيم'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      unlockedStage: CompanionStage.cuedRecall,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 0, 0),
    );

    expect(state.activeStage, CompanionStage.cuedRecall);
    expect(state.stage2, isNotNull);
    expect(state.currentHintLevel, HintLevel.letters);

    final update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 0, 4),
    );
    state = update.state;

    expect(state.verses.first.stage2.linkingPassCount, 1);
    expect(state.verses.first.stage2.cueBaselineHint, HintLevel.h0);
    expect(state.currentHintLevel, HintLevel.h0);
    expect(state.stage2?.mode, isNot(Stage2Mode.correction));
  });

  test('Stage 2 applies one-step temporary relief after two failures',
      () async {
    final unitId = await createUnit('stage2-relief', endAyah: 1);
    final config = configForStage2(const Stage2Config());

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'إياك نعبد وإياك نستعين'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      unlockedStage: CompanionStage.cuedRecall,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 10, 0),
    );

    var update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: false,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 10, 2),
    );
    state = update.state;
    expect(state.stage2?.mode, Stage2Mode.correction);

    var correction = await engine.submitCorrectionExposure(
      state: state,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 10, 4),
    );
    state = correction.state;

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: false,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 10, 6),
    );
    state = update.state;
    expect(state.stage2?.mode, Stage2Mode.correction);

    correction = await engine.submitCorrectionExposure(
      state: state,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 10, 8),
    );
    state = correction.state;

    expect(state.currentHintLevel, HintLevel.firstWord);
    expect(state.verses.first.stage2.reliefPending, isTrue);
  });

  test('Stage 2 excludes assisted attempts from readiness counting', () async {
    final unitId = await createUnit('stage2-assisted-exclusion', endAyah: 1);
    final config = configForStage2(const Stage2Config());

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'صراط الذين أنعمت عليهم'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      unlockedStage: CompanionStage.cuedRecall,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 20, 0),
    );

    var update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 20, 2),
    );
    state = update.state;

    var hinted = engine.requestHint(state);
    update = await engine.submitAttempt(
      state: hinted,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(hinted),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 20, 4),
    );
    state = update.state;

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 20, 6),
    );
    state = update.state;

    expect(state.verses.first.stage2.countedPasses, 2);
    expect(state.verses.first.stage2.countedAttempts, 2);
    expect(
      state.verses.first.stage2.isReady(
        config: state.stage2!.config,
        isWeak: false,
      ),
      isTrue,
    );
  });

  test('Stage 2 checkpoint failure remediates only failed verses', () async {
    final unitId = await createUnit('stage2-remediation', endAyah: 2);
    final config = configForStage2(
      const Stage2Config(
        readinessWindow: 1,
        readinessPassesRequired: 1,
      ),
    );

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'الرحمن الرحيم'),
        ChainVerse(surah: 1, ayah: 2, text: 'مالك يوم الدين'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      unlockedStage: CompanionStage.cuedRecall,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 30, 0),
    );

    var update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 30, 2),
    );
    state = update.state;
    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 30, 4),
    );
    state = update.state;
    expect(state.stage2?.phase, Stage2Phase.checkpoint);
    expect(state.stage2?.mode, Stage2Mode.checkpoint);

    final hinted = engine.requestHint(state);
    update = await engine.submitAttempt(
      state: hinted,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(hinted),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 30, 6),
    );
    state = update.state;
    expect(state.currentVerseIndex, 1);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 30, 8),
    );
    state = update.state;

    expect(state.stage2?.phase, Stage2Phase.remediation);
    expect(state.stage2?.mode, Stage2Mode.remediation);
    expect(state.stage2?.remediationTargets, const <int>[0]);
    expect(state.currentVerseIndex, 0);
  });

  test('Stage 2 budget fallback unlocks guarded Stage-3 weak prelude',
      () async {
    final unitId = await createUnit('stage2-budget-fallback', endAyah: 2);
    final config = configForStage2(
      const Stage2Config(
        stage2BudgetFractionOfNewTime: 0.01,
        stage2BudgetMinMs: 1,
        stage2BudgetMaxMs: 1,
        perVerseCapMinMs: 1,
        perVerseCapMaxMs: 1,
      ),
    );

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'اهدنا'),
        ChainVerse(surah: 1, ayah: 2, text: 'الصراط'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      unlockedStage: CompanionStage.cuedRecall,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 40, 0),
    );

    var update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 40, 3),
    );
    state = update.state;

    expect(state.activeStage, CompanionStage.hiddenReveal);
    expect(state.stage3WeakPreludeTargets, isNotEmpty);
    final weakBefore = state.stage3WeakPreludeTargets.length;

    var hinted = engine.requestHint(state);
    hinted = engine.requestHint(hinted);
    update = await engine.submitAttempt(
      state: hinted,
      evaluator: evaluator,
      manualFallbackPass: true,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 40, 4),
    );

    expect(update.telemetry.hintLevel, HintLevel.letters);
    expect(update.state.stage3WeakPreludeTargets.length, weakBefore - 1);
  });

  test('Stage 2 prioritizes weak verses from Stage 1 before other unresolved',
      () async {
    final unitId = await createUnit('stage2-weak-priority', endAyah: 3);
    final config = configForStage2(
      const Stage2Config(
        readinessWindow: 1,
        readinessPassesRequired: 1,
      ),
    );

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'قل هو الله أحد'),
        ChainVerse(surah: 1, ayah: 2, text: 'الله الصمد'),
        ChainVerse(surah: 1, ayah: 3, text: 'لم يلد ولم يولد'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      unlockedStage: CompanionStage.cuedRecall,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 50, 0),
    );

    const readyWindow = <Stage2WindowEntry>[
      Stage2WindowEntry(
        timestampMs: 0,
        passed: true,
        countedPass: true,
        hintLevel: HintLevel.h0,
        assisted: false,
      ),
    ];
    final verses = <ChainVerseState>[
      state.verses[0].copyWith(
        stage2: state.verses[0].stage2.copyWith(
          linkingPassCount: 1,
          countedPasses: 1,
          countedAttempts: 1,
          readinessWindow: readyWindow,
          cueBaselineHint: HintLevel.h0,
        ),
      ),
      state.verses[1].copyWith(
        stage1: state.verses[1].stage1.copyWith(weak: true),
        stage2: state.verses[1].stage2.copyWith(
          weakTarget: true,
          cueBaselineHint: HintLevel.firstWord,
        ),
      ),
      state.verses[2],
    ];
    state = state.copyWith(
      verses: verses,
      currentVerseIndex: 0,
      currentHintLevel: HintLevel.h0,
    );

    final update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 9, 50, 3),
    );

    expect(update.state.currentVerseIndex, 1);
  });

  test('review mode remains hidden-first and bypasses Stage 2 runtime', () async {
    final unitId = await createUnit('stage2-review-unchanged', endAyah: 1);
    final config = configForStage2(const Stage2Config());

    final state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'قل أعوذ برب الناس'),
      ],
      launchMode: CompanionLaunchMode.review,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 0, 0),
    );

    expect(state.activeStage, CompanionStage.hiddenReveal);
    expect(state.stage2, isNull);

    final update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 0, 2),
    );
    expect(update.state.activeStage, CompanionStage.hiddenReveal);
    expect(update.state.stage2, isNull);
  });
}
