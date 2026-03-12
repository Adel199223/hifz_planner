import 'dart:convert';

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
import 'package:hifz_planner/data/time/local_day_time.dart';

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

  ProgressiveRevealChainConfig configForStage3(Stage3Config stage3) {
    return ProgressiveRevealChainConfig(stage3: stage3);
  }

  ProgressiveRevealChainConfig configForStage4(Stage4Config stage4) {
    return ProgressiveRevealChainConfig(stage4: stage4);
  }

  String correctOption(ChainRunState state) {
    final prompt = state.stage1?.activeAutoCheckPrompt ??
        state.stage2?.activeAutoCheckPrompt ??
        state.stage3?.activeAutoCheckPrompt ??
        state.review?.activeAutoCheckPrompt ??
        state.stage4?.activeAutoCheckPrompt;
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
    expect(attempts.where((entry) => entry.attemptType == 'encode_echo').length,
        2);
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
    final unitId =
        await createUnit('stage1-checkpoint-remediation', endAyah: 2);
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
    expect(
        state.verses.every((verse) => verse.stage1.seenModelExposure), isTrue);
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
      selectedAutoCheckOptionId: correctOption(hinted),
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

  test('Stage 3 runtime activates for resumed NEW hidden stage', () async {
    final unitId = await createUnit('stage3-activation', endAyah: 1);
    final config = configForStage3(const Stage3Config());

    final state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'قل أعوذ برب الناس'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      unlockedStage: CompanionStage.hiddenReveal,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 10, 0),
    );

    expect(state.activeStage, CompanionStage.hiddenReveal);
    expect(state.stage3, isNotNull);
    expect(state.stage3?.mode, Stage3Mode.linking);
    expect(state.currentHintLevel, HintLevel.h0);
  });

  test('Stage 3 failure requires correction exposure before retry', () async {
    final unitId = await createUnit('stage3-correction-gate', endAyah: 1);
    final config = configForStage3(const Stage3Config());

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'مالك يوم الدين'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      unlockedStage: CompanionStage.hiddenReveal,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 20, 0),
    );

    var update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: false,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 20, 2),
    );
    state = update.state;
    expect(state.stage3?.mode, Stage3Mode.correction);
    expect(update.telemetry.correctionRequiredAfterAttempt, isTrue);

    await expectLater(
      engine.submitAttempt(
        state: state,
        evaluator: evaluator,
        manualFallbackPass: true,
        config: config,
        nowLocal: DateTime(2026, 2, 24, 10, 20, 4),
      ),
      throwsA(isA<StateError>()),
    );

    final correction = await engine.submitCorrectionExposure(
      state: state,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 20, 6),
    );
    state = correction.state;
    expect(state.stage3?.mode, isNot(Stage3Mode.correction));
  });

  test('Stage 3 checkpoint pass completes session', () async {
    final unitId = await createUnit('stage3-checkpoint-pass', endAyah: 1);
    final config = configForStage3(
      const Stage3Config(
        readinessWindow: 1,
        readinessPassesRequired: 1,
        readinessRequiredH0Passes: 1,
        weakRequiredH0Passes: 1,
        checkpointThreshold: 1.0,
        minSpacingMs: 1,
      ),
    );

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'اهدنا الصراط المستقيم'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      unlockedStage: CompanionStage.hiddenReveal,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 30, 0),
    );

    var update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 30, 2),
    );
    state = update.state;
    expect(state.stage3?.phase, Stage3Phase.checkpoint);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 30, 4),
    );
    state = update.state;

    expect(state.completed, isTrue);
    expect(state.resultKind, ChainResultKind.completed);
    expect(update.summary, isNotNull);
    expect(update.summary?.resultKind, ChainResultKind.completed);
  });

  test('Stage 3 checkpoint failure remediates failed-only targets', () async {
    final unitId = await createUnit('stage3-remediation', endAyah: 2);
    final config = configForStage3(
      const Stage3Config(
        readinessWindow: 1,
        readinessPassesRequired: 1,
        readinessRequiredH0Passes: 1,
        weakRequiredH0Passes: 1,
        checkpointThreshold: 1.0,
      ),
    );

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'الرحمن الرحيم'),
        ChainVerse(surah: 1, ayah: 2, text: 'مالك يوم الدين'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      unlockedStage: CompanionStage.hiddenReveal,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 40, 0),
    );

    var update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 40, 2),
    );
    state = update.state;
    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 40, 4),
    );
    state = update.state;
    expect(state.stage3?.phase, Stage3Phase.checkpoint);
    expect(state.currentVerseIndex, 0);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 40, 6),
    );
    state = update.state;
    expect(state.currentVerseIndex, 1);

    final hinted = engine.requestHint(engine.requestHint(state));
    update = await engine.submitAttempt(
      state: hinted,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(hinted),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 40, 8),
    );
    state = update.state;

    expect(state.stage3?.phase, Stage3Phase.remediation);
    expect(state.stage3?.mode, Stage3Mode.remediation);
    expect(state.stage3?.remediationTargets, const <int>[1]);
    expect(state.currentVerseIndex, 1);
  });

  test('Stage 3 budget fallback is explicit and non-terminal', () async {
    final unitId = await createUnit('stage3-budget-fallback', endAyah: 1);
    final config = configForStage3(
      const Stage3Config(
        stage3BudgetFractionOfNewTime: 0.01,
        stage3BudgetMinMs: 1,
        stage3BudgetMaxMs: 1,
        perVerseCapMinMs: 1,
        perVerseCapMaxMs: 1,
      ),
    );

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'الصراط'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      unlockedStage: CompanionStage.hiddenReveal,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 50, 0),
    );

    var update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 50, 3),
    );

    state = update.state;
    expect(state.completed, isFalse);
    expect(state.stage3?.phase, Stage3Phase.budgetFallback);
    expect(update.summary, isNull);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 50, 5),
    );
    state = update.state;
    final attempts = await companionRepo.getAttemptsForSession(state.sessionId);
    final stage3Attempts = attempts
        .where((entry) => entry.stageCode == CompanionStage.hiddenReveal.code)
        .toList(growable: false);
    expect(stage3Attempts, isNotEmpty);
    final stage3Telemetry = jsonDecode(
      stage3Attempts.last.telemetryJson ?? '{}',
    ) as Map<String, dynamic>;
    expect(stage3Telemetry['stage3_phase'], Stage3Phase.budgetFallback.code);
    expect(stage3Telemetry['lifecycle_hook'], 'stage4_candidate');
  });

  test(
      'Stage 3 weak-prelude routes only remaining targets until prelude clears',
      () async {
    final unitId = await createUnit('stage3-weak-prelude-routing', endAyah: 3);
    final config = configForStage3(const Stage3Config());

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'قل هو الله أحد'),
        ChainVerse(surah: 1, ayah: 2, text: 'الله الصمد'),
        ChainVerse(surah: 1, ayah: 3, text: 'لم يلد ولم يولد'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      unlockedStage: CompanionStage.hiddenReveal,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 11, 0, 0),
    );

    state = state.copyWith(
      verses: <ChainVerseState>[
        state.verses[0].copyWith(
          stage3: state.verses[0].stage3.copyWith(
            weakTarget: true,
            cueBaselineHint: HintLevel.letters,
          ),
        ),
        state.verses[1],
        state.verses[2].copyWith(
          stage3: state.verses[2].stage3.copyWith(
            weakTarget: true,
            cueBaselineHint: HintLevel.letters,
          ),
        ),
      ],
      stage3: state.stage3?.copyWith(
        mode: Stage3Mode.weakPrelude,
        phase: Stage3Phase.prelude,
      ),
      stage3WeakPreludeTargets: const <int>[0, 2],
      stage3WeakPreludeCursor: 0,
      currentVerseIndex: 0,
      currentHintLevel: HintLevel.letters,
    );

    var update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 11, 0, 2),
    );
    state = update.state;

    expect(state.stage3WeakPreludeTargets, const <int>[2]);
    expect(state.currentVerseIndex, 2);
    expect(state.stage3?.mode, Stage3Mode.weakPrelude);
    expect(state.currentHintLevel, HintLevel.letters);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 11, 0, 4),
    );
    state = update.state;
    expect(state.stage3WeakPreludeTargets, isEmpty);
  });

  test('Stage 3 correction gate is enforced across runtime modes', () async {
    final scenarios = <Map<String, Object>>[
      <String, Object>{
        'mode': Stage3Mode.hiddenRecall,
        'phase': Stage3Phase.acquisition,
        'weakTargets': const <int>[],
      },
      <String, Object>{
        'mode': Stage3Mode.linking,
        'phase': Stage3Phase.acquisition,
        'weakTargets': const <int>[],
      },
      <String, Object>{
        'mode': Stage3Mode.discrimination,
        'phase': Stage3Phase.acquisition,
        'weakTargets': const <int>[],
      },
      <String, Object>{
        'mode': Stage3Mode.checkpoint,
        'phase': Stage3Phase.checkpoint,
        'weakTargets': const <int>[],
      },
      <String, Object>{
        'mode': Stage3Mode.remediation,
        'phase': Stage3Phase.remediation,
        'weakTargets': const <int>[],
      },
      <String, Object>{
        'mode': Stage3Mode.weakPrelude,
        'phase': Stage3Phase.prelude,
        'weakTargets': const <int>[0],
      },
    ];
    final config = configForStage3(const Stage3Config());

    for (var index = 0; index < scenarios.length; index++) {
      final scenario = scenarios[index];
      final mode = scenario['mode']! as Stage3Mode;
      final phase = scenario['phase']! as Stage3Phase;
      final weakTargets = scenario['weakTargets']! as List<int>;
      final unitId = await createUnit('stage3-mode-correction-$index');

      var state = await engine.startSession(
        unitId: unitId,
        verses: const <ChainVerse>[
          ChainVerse(
              surah: 1, ayah: 1, text: 'وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ'),
        ],
        launchMode: CompanionLaunchMode.newMemorization,
        unlockedStage: CompanionStage.hiddenReveal,
        config: config,
        nowLocal: DateTime(2026, 2, 24, 11, 10, index * 10),
      );

      final verse = state.verses.first.copyWith(
        stage3: state.verses.first.stage3.copyWith(
          weakTarget: weakTargets.isNotEmpty,
          cueBaselineHint:
              weakTargets.isNotEmpty ? HintLevel.letters : HintLevel.h0,
        ),
      );
      state = state.copyWith(
        verses: <ChainVerseState>[verse],
        stage3WeakPreludeTargets: weakTargets,
        stage3WeakPreludeCursor: 0,
        currentHintLevel:
            weakTargets.isNotEmpty ? HintLevel.letters : HintLevel.h0,
        stage3: state.stage3?.copyWith(
          mode: mode,
          phase: phase,
          checkpointTargets:
              mode == Stage3Mode.checkpoint ? const <int>[0] : const <int>[],
          checkpointCursor: 0,
          remediationTargets:
              mode == Stage3Mode.remediation ? const <int>[0] : const <int>[],
          remediationCursor: 0,
        ),
      );

      var update = await engine.submitAttempt(
        state: state,
        evaluator: evaluator,
        manualFallbackPass: false,
        selectedAutoCheckOptionId: 'invalid',
        config: config,
        nowLocal: DateTime(2026, 2, 24, 11, 10, index * 10 + 2),
      );
      state = update.state;
      expect(
        state.stage3?.mode,
        Stage3Mode.correction,
        reason: 'mode=$mode should enter correction',
      );

      await expectLater(
        engine.submitAttempt(
          state: state,
          evaluator: evaluator,
          manualFallbackPass: true,
          selectedAutoCheckOptionId: 'ignored',
          config: config,
          nowLocal: DateTime(2026, 2, 24, 11, 10, index * 10 + 3),
        ),
        throwsA(isA<StateError>()),
      );

      final correction = await engine.submitCorrectionExposure(
        state: state,
        config: config,
        nowLocal: DateTime(2026, 2, 24, 11, 10, index * 10 + 4),
      );
      expect(
        correction.state.stage3?.mode,
        isNot(Stage3Mode.correction),
        reason: 'mode=$mode should clear correction gate after exposure',
      );
    }
  });

  test(
      'Stage 3 readiness uses counted unassisted attempts and ignores assisted passes',
      () async {
    final unitId = await createUnit('stage3-readiness-counted', endAyah: 1);
    final config = configForStage3(
      const Stage3Config(
        readinessWindow: 4,
        readinessPassesRequired: 3,
        readinessRequiredH0Passes: 2,
        weakRequiredH0Passes: 1,
        checkpointThreshold: 0.75,
        minSpacingMs: 1,
      ),
    );

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'اهدنا الصراط المستقيم'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      unlockedStage: CompanionStage.hiddenReveal,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 11, 20, 0),
    );

    var update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 11, 20, 2),
    );
    state = update.state;
    expect(state.verses.first.stage3.linkingPassCount, 1);
    expect(state.verses.first.stage3.countedPasses, 1);
    expect(state.verses.first.stage3.countedAttempts, 1);

    final hinted = engine.requestHint(state);
    update = await engine.submitAttempt(
      state: hinted,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(hinted),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 11, 20, 4),
    );
    state = update.state;
    expect(state.verses.first.stage3.countedPasses, 1);
    expect(state.verses.first.stage3.countedAttempts, 1);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 11, 20, 6),
    );
    state = update.state;

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 11, 20, 8),
    );
    state = update.state;

    expect(state.verses.first.stage3.countedPasses, 3);
    expect(state.verses.first.stage3.countedH0Passes, greaterThanOrEqualTo(2));
    expect(state.verses.first.stage3.countedAttempts, 3);
    expect(state.stage3?.phase, Stage3Phase.checkpoint);
  });

  test('Stage 3 selection is deterministic for identical state and input',
      () async {
    final unitId =
        await createUnit('stage3-deterministic-selection', endAyah: 3);
    final config = configForStage3(const Stage3Config());

    final seedState = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'قل هو الله أحد'),
        ChainVerse(surah: 1, ayah: 2, text: 'الله الصمد'),
        ChainVerse(surah: 1, ayah: 3, text: 'لم يلد ولم يولد'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      unlockedStage: CompanionStage.hiddenReveal,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 11, 30, 0),
    );

    var stateA = seedState;
    var stateB = seedState;

    var updateA = await engine.submitAttempt(
      state: stateA,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(stateA),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 11, 30, 2),
    );
    var updateB = await engine.submitAttempt(
      state: stateB,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(stateB),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 11, 30, 2),
    );

    expect(updateA.state.currentVerseIndex, updateB.state.currentVerseIndex);
    expect(updateA.state.stage3?.mode, updateB.state.stage3?.mode);
    expect(updateA.state.stage3?.phase, updateB.state.stage3?.phase);
    expect(updateA.telemetry.stage3Mode, updateB.telemetry.stage3Mode);
    expect(updateA.telemetry.stage3Phase, updateB.telemetry.stage3Phase);

    stateA = updateA.state;
    stateB = updateB.state;
    updateA = await engine.submitAttempt(
      state: stateA,
      evaluator: evaluator,
      manualFallbackPass: false,
      selectedAutoCheckOptionId: correctOption(stateA),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 11, 30, 4),
    );
    updateB = await engine.submitAttempt(
      state: stateB,
      evaluator: evaluator,
      manualFallbackPass: false,
      selectedAutoCheckOptionId: correctOption(stateB),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 11, 30, 4),
    );

    expect(updateA.state.currentVerseIndex, updateB.state.currentVerseIndex);
    expect(updateA.state.stage3?.mode, updateB.state.stage3?.mode);
    expect(updateA.state.stage3?.phase, updateB.state.stage3?.phase);
    expect(updateA.telemetry.stage3Mode, updateB.telemetry.stage3Mode);
    expect(updateA.telemetry.stage3Phase, updateB.telemetry.stage3Phase);
  });

  test('Stage 3 telemetry_json persists schema-free Stage-3 keys', () async {
    final unitId = await createUnit('stage3-telemetry-keys', endAyah: 1);
    final config = configForStage3(const Stage3Config());

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'بسم الله الرحمن الرحيم'),
      ],
      launchMode: CompanionLaunchMode.newMemorization,
      unlockedStage: CompanionStage.hiddenReveal,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 11, 40, 0),
    );

    final update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 11, 40, 3),
    );
    state = update.state;

    final attempts = await companionRepo.getAttemptsForSession(state.sessionId);
    final stage3Attempts = attempts
        .where((entry) => entry.stageCode == CompanionStage.hiddenReveal.code)
        .toList(growable: false);
    expect(stage3Attempts, isNotEmpty);

    final telemetry = jsonDecode(stage3Attempts.last.telemetryJson ?? '{}')
        as Map<String, dynamic>;
    expect(telemetry.containsKey('stage3_step'), isTrue);
    expect(telemetry.containsKey('stage3_mode'), isTrue);
    expect(telemetry.containsKey('stage3_phase'), isTrue);
    expect(telemetry.containsKey('link_prev_verse_order'), isTrue);
    expect(telemetry.containsKey('readiness_counted_pass'), isTrue);
    expect(telemetry.containsKey('cue_baseline'), isTrue);
    expect(telemetry.containsKey('cue_rotated_from'), isTrue);
    expect(telemetry.containsKey('risk_trigger'), isTrue);
    expect(telemetry.containsKey('stage3_error_type'), isTrue);
    expect(telemetry.containsKey('lifecycle_hook'), isTrue);
    expect(stage3Attempts.last.timeOnVerseMs, greaterThan(0));
    expect(stage3Attempts.last.timeOnChunkMs, greaterThan(0));
  });

  test('Stage-4 launch mode initializes dedicated runtime on hidden stage',
      () async {
    final unitId = await createUnit('stage4-init', endAyah: 2);

    final state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'بسم الله الرحمن الرحيم'),
        ChainVerse(surah: 1, ayah: 2, text: 'الحمد لله رب العالمين'),
      ],
      launchMode: CompanionLaunchMode.stage4Consolidation,
      nowLocal: DateTime(2026, 2, 26, 7, 0, 0),
    );

    expect(state.activeStage, CompanionStage.hiddenReveal);
    expect(state.stage4, isNotNull);
    expect(state.stage3, isNull);
    expect(state.stage4?.phase, Stage4Phase.verification);
    expect(state.stage4?.mode, isNot(Stage4Mode.correction));
  });

  test('Stage-4 failure requires correction exposure before retry', () async {
    final unitId = await createUnit('stage4-correction-gate', endAyah: 1);
    final config = configForStage4(
      const Stage4Config(
        readinessWindow: 1,
        readinessPassesRequired: 1,
        readinessRequiredH0Passes: 1,
        randomStartProbeCount: 0,
      ),
    );

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'مالك يوم الدين'),
      ],
      launchMode: CompanionLaunchMode.stage4Consolidation,
      config: config,
      nowLocal: DateTime(2026, 2, 26, 7, 10, 0),
    );

    final update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: false,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 26, 7, 10, 3),
    );
    state = update.state;
    expect(state.stage4?.mode, Stage4Mode.correction);
    expect(update.telemetry.correctionRequiredAfterAttempt, isTrue);

    await expectLater(
      engine.submitAttempt(
        state: state,
        evaluator: evaluator,
        manualFallbackPass: true,
        selectedAutoCheckOptionId: null,
        config: config,
        nowLocal: DateTime(2026, 2, 26, 7, 10, 4),
      ),
      throwsA(isA<StateError>()),
    );

    final correction = await engine.submitCorrectionExposure(
      state: state,
      config: config,
      nowLocal: DateTime(2026, 2, 26, 7, 10, 5),
    );
    state = correction.state;
    expect(state.stage4?.mode, isNot(Stage4Mode.correction));
  });

  test('Stage-4 budget fallback finalizes as partial and persists unresolved',
      () async {
    final unitId = await createUnit('stage4-budget-fallback', endAyah: 1);
    final config = configForStage4(
      const Stage4Config(
        stage4BudgetFractionOfNewTime: 0.01,
        stage4BudgetMinMs: 1,
        stage4BudgetMaxMs: 1,
        randomStartProbeCount: 0,
      ),
    );

    final state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'إياك نعبد وإياك نستعين'),
      ],
      launchMode: CompanionLaunchMode.stage4Consolidation,
      config: config,
      nowLocal: DateTime(2026, 2, 26, 7, 20, 0),
    );

    final update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: false,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 26, 7, 20, 3),
    );

    expect(update.state.completed, isTrue);
    expect(update.summary, isNotNull);
    expect(update.summary!.resultKind, ChainResultKind.partial);
    expect(update.state.stage4?.phase, Stage4Phase.budgetFallback);

    final lifecycle = await companionRepo.getLifecycleState(unitId);
    expect(lifecycle, isNotNull);
    expect(lifecycle!.stage4Status, 'partial');
    expect(lifecycle.stage4UnresolvedTargetsJson, isNotNull);

    final sessions = await companionRepo.getStage4SessionsForUnit(unitId);
    expect(sessions, isNotEmpty);
    expect(sessions.last.outcome, 'partial');
    expect(sessions.last.unresolvedTargetsJson, isNotNull);
  });

  test('Stage-4 pass marks lifecycle stable and stage5-candidate path', () async {
    final unitId = await createUnit('stage4-pass', endAyah: 1);
    final config = configForStage4(
      const Stage4Config(
        readinessWindow: 1,
        readinessPassesRequired: 1,
        readinessRequiredH0Passes: 1,
        weakRequiredH0Passes: 1,
        randomStartProbeCount: 0,
        checkpointThreshold: 1.0,
      ),
    );

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'اهدنا الصراط المستقيم'),
      ],
      launchMode: CompanionLaunchMode.stage4Consolidation,
      config: config,
      nowLocal: DateTime(2026, 2, 26, 7, 30, 0),
    );

    var update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 26, 7, 30, 2),
    );
    state = update.state;

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 26, 7, 30, 4),
    );
    state = update.state;
    expect(state.stage4?.phase, Stage4Phase.checkpoint);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 26, 7, 30, 6),
    );

    expect(update.state.completed, isTrue);
    expect(update.summary, isNotNull);
    expect(update.summary!.resultKind, ChainResultKind.completed);
    final lifecycle = await companionRepo.getLifecycleState(unitId);
    expect(lifecycle, isNotNull);
    expect(lifecycle!.lifecycleTier, 'stable');
    expect(lifecycle.stage4Status, 'passed');
  });

  test('review mode initializes dedicated runtime and removes legacy telemetry',
      () async {
    final unitId = await createUnit('review-runtime-init', endAyah: 1);
    final config = configForStage3(const Stage3Config());

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
    expect(state.stage3, isNull);
    expect(state.stage4, isNull);
    expect(state.review, isNotNull);

    final update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 0, 2),
    );
    expect(update.state.activeStage, CompanionStage.hiddenReveal);
    expect(update.state.review, isNotNull);

    final attempts = await companionRepo.getAttemptsForSession(state.sessionId);
    expect(attempts, isNotEmpty);
    final telemetry = jsonDecode(attempts.first.telemetryJson!);
    expect(telemetry['review_mode'], isNotNull);
    expect(telemetry.containsKey('legacy_path'), isFalse);
  });

  test('review mode prioritizes weak targets and enforces correction replay',
      () async {
    final unitId = await createUnit('review-runtime-priority', endAyah: 2);
    const config = ProgressiveRevealChainConfig(stage3: Stage3Config());
    final day = localDayIndex(DateTime(2026, 2, 24));
    final sessionId = await companionRepo.startChainSession(
      unitId: unitId,
      targetVerseCount: 2,
      createdAtDay: day,
      startedAtSeconds: 0,
    );

    await companionRepo.upsertStepProficiency(
      unitId: unitId,
      surah: 1,
      ayah: 1,
      proficiencyEma: 0.92,
      lastHintLevel: HintLevel.h0.code,
      lastEvaluatorConfidence: 0.95,
      lastLatencyToStartMs: 400,
      attemptsCount: 6,
      passesCount: 6,
      lastUpdatedDay: day,
      lastSessionId: sessionId,
    );
    await companionRepo.upsertStepProficiency(
      unitId: unitId,
      surah: 1,
      ayah: 2,
      proficiencyEma: 0.22,
      lastHintLevel: HintLevel.firstWord.code,
      lastEvaluatorConfidence: 0.40,
      lastLatencyToStartMs: 1200,
      attemptsCount: 3,
      passesCount: 1,
      lastUpdatedDay: day,
      lastSessionId: sessionId,
    );

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'قل أعوذ برب الناس'),
        ChainVerse(surah: 1, ayah: 2, text: 'ملك الناس'),
      ],
      launchMode: CompanionLaunchMode.review,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 0, 0),
    );

    expect(state.currentVerseIndex, 1);

    var update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: false,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 0, 2),
    );
    state = update.state;
    expect(state.review?.mode, ReviewMode.correction);
    expect(update.telemetry.correctionRequiredAfterAttempt, isTrue);

    await expectLater(
      engine.submitAttempt(
        state: state,
        evaluator: evaluator,
        manualFallbackPass: true,
        selectedAutoCheckOptionId: null,
        config: config,
        nowLocal: DateTime(2026, 2, 24, 10, 0, 3),
      ),
      throwsA(isA<StateError>()),
    );

    update = await engine.submitCorrectionExposure(
      state: state,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 10, 0, 4),
    );
    expect(update.state.review?.mode, isNot(ReviewMode.correction));
  });

  test('review runtime reaches checkpoint and completes deterministically',
      () async {
    final unitId = await createUnit('review-runtime-checkpoint', endAyah: 1);
    const config = ProgressiveRevealChainConfig(stage3: Stage3Config());
    final day = localDayIndex(DateTime(2026, 2, 24));
    final sessionId = await companionRepo.startChainSession(
      unitId: unitId,
      targetVerseCount: 1,
      createdAtDay: day,
      startedAtSeconds: 0,
    );

    await companionRepo.upsertStepProficiency(
      unitId: unitId,
      surah: 1,
      ayah: 1,
      proficiencyEma: 0.88,
      lastHintLevel: HintLevel.h0.code,
      lastEvaluatorConfidence: 0.90,
      lastLatencyToStartMs: 500,
      attemptsCount: 5,
      passesCount: 5,
      lastUpdatedDay: day,
      lastSessionId: sessionId,
    );

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'إله الناس'),
      ],
      launchMode: CompanionLaunchMode.review,
      config: config,
      nowLocal: DateTime(2026, 2, 24, 11, 0, 0),
    );

    for (var i = 0; i < 3; i++) {
      final update = await engine.submitAttempt(
        state: state,
        evaluator: evaluator,
        manualFallbackPass: true,
        selectedAutoCheckOptionId: correctOption(state),
        config: config,
        nowLocal: DateTime(2026, 2, 24, 11, 0, i + 1),
      );
      state = update.state;
    }

    expect(state.review?.phase, ReviewPhase.checkpoint);

    final finalUpdate = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
      selectedAutoCheckOptionId: correctOption(state),
      config: config,
      nowLocal: DateTime(2026, 2, 24, 11, 0, 5),
    );

    expect(finalUpdate.state.completed, isTrue);
    expect(finalUpdate.summary, isNotNull);
    expect(finalUpdate.summary!.resultKind, ChainResultKind.completed);
  });
}
