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

  Future<int> createUnit(String key, {int endAyah = 2}) {
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

  const verses2 = <ChainVerse>[
    ChainVerse(surah: 1, ayah: 1, text: 'v1'),
    ChainVerse(surah: 1, ayah: 2, text: 'v2'),
  ];

  test('new mode starts in Stage 1 guided visible', () async {
    final unitId = await createUnit('chain-new-s1');

    final state = await engine.startSession(
      unitId: unitId,
      verses: verses2,
      launchMode: CompanionLaunchMode.newMemorization,
    );

    expect(state.activeStage, CompanionStage.guidedVisible);
    expect(state.currentHintLevel, HintLevel.h0);
    expect(state.currentVerseIndex, 0);
    expect(state.verses.every((verse) => !verse.passedGuidedVisible), isTrue);
    expect(state.verses.every((verse) => !verse.passedCuedRecall), isTrue);
    expect(state.verses.every((verse) => !verse.passed), isTrue);
  });

  test('Stage 1 and Stage 2 complete before Stage 3 hidden progression',
      () async {
    final unitId = await createUnit('chain-new-s123');
    final evaluator = const ManualFallbackVerseEvaluator();

    var state = await engine.startSession(
      unitId: unitId,
      verses: verses2,
      launchMode: CompanionLaunchMode.newMemorization,
    );

    var update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
    );
    state = update.state;
    expect(state.activeStage, CompanionStage.guidedVisible);
    expect(state.currentVerseIndex, 1);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
    );
    state = update.state;
    expect(state.activeStage, CompanionStage.cuedRecall);
    expect(state.currentHintLevel, HintLevel.firstWord);
    expect(state.verses.every((verse) => verse.passedGuidedVisible), isTrue);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
    );
    state = update.state;
    expect(state.activeStage, CompanionStage.cuedRecall);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
    );
    state = update.state;
    expect(state.activeStage, CompanionStage.hiddenReveal);
    expect(state.currentHintLevel, HintLevel.h0);
    expect(state.verses.every((verse) => verse.passedCuedRecall), isTrue);
    expect(state.verses.every((verse) => !verse.revealed), isTrue);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
    );
    state = update.state;
    expect(state.verses[0].revealed, isTrue);

    update = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: true,
    );
    state = update.state;
    expect(state.completed, isTrue);
    expect(update.summary, isNotNull);

    final events = await companionRepo.getStageEventsForSession(state.sessionId);
    expect(events.length, 2);
    expect(events[0].eventType, 'auto_unlock');
    expect(events[0].fromStage, 1);
    expect(events[0].toStage, 2);
    expect(events[1].eventType, 'auto_unlock');
    expect(events[1].fromStage, 2);
    expect(events[1].toStage, 3);

    final attempts = await companionRepo.getAttemptsForSession(state.sessionId);
    final stageCounts = <String, int>{};
    for (final attempt in attempts) {
      stageCounts.update(
        attempt.stageCode,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    expect(stageCounts[CompanionStage.guidedVisible.code], 2);
    expect(stageCounts[CompanionStage.cuedRecall.code], 2);
    expect(stageCounts[CompanionStage.hiddenReveal.code], 2);
  });

  test('skip stage transitions and logs user_skip events', () async {
    final unitId = await createUnit('chain-new-skip');

    var state = await engine.startSession(
      unitId: unitId,
      verses: verses2,
      launchMode: CompanionLaunchMode.newMemorization,
    );

    state = await engine.skipCurrentStage(state: state);
    expect(state.activeStage, CompanionStage.cuedRecall);
    expect(state.verses.every((verse) => verse.passedGuidedVisible), isTrue);

    state = await engine.skipCurrentStage(state: state);
    expect(state.activeStage, CompanionStage.hiddenReveal);
    expect(state.verses.every((verse) => verse.passedCuedRecall), isTrue);

    final events = await companionRepo.getStageEventsForSession(state.sessionId);
    expect(events.length, 2);
    expect(events[0].eventType, 'user_skip');
    expect(events[0].fromStage, 1);
    expect(events[0].toStage, 2);
    expect(events[1].eventType, 'user_skip');
    expect(events[1].fromStage, 2);
    expect(events[1].toStage, 3);
  });

  test('new mode persists stage memory and resumes from unlocked stage',
      () async {
    final unitId = await createUnit('chain-new-memory');

    var firstRun = await engine.startSession(
      unitId: unitId,
      verses: verses2,
      launchMode: CompanionLaunchMode.newMemorization,
    );
    firstRun = await engine.skipCurrentStage(state: firstRun);
    firstRun = await engine.skipCurrentStage(state: firstRun);
    expect(firstRun.activeStage, CompanionStage.hiddenReveal);

    final stored = await companionRepo.getOrCreateUnitState(unitId);
    expect(stored.unlockedStage, CompanionStage.hiddenReveal);

    final secondRun = await engine.startSession(
      unitId: unitId,
      verses: verses2,
      launchMode: CompanionLaunchMode.newMemorization,
    );
    expect(secondRun.activeStage, CompanionStage.hiddenReveal);

    final resumeEvents =
        await companionRepo.getStageEventsForSession(secondRun.sessionId);
    expect(resumeEvents.length, 1);
    expect(resumeEvents.single.eventType, 'resume_stage');
    expect(resumeEvents.single.fromStage, 3);
    expect(resumeEvents.single.toStage, 3);
  });

  test('review mode always starts hidden reveal regardless of stored stage',
      () async {
    final unitId = await createUnit('chain-review-hidden');
    await companionRepo.updateUnlockedStage(
      unitId: unitId,
      stage: CompanionStage.guidedVisible,
      updatedAtDay: 100,
      updatedAtSeconds: 120,
    );

    final state = await engine.startSession(
      unitId: unitId,
      verses: verses2,
      launchMode: CompanionLaunchMode.review,
    );

    expect(state.activeStage, CompanionStage.hiddenReveal);
    expect(state.currentHintLevel, HintLevel.h0);
    expect(state.verses.every((verse) => !verse.revealed), isTrue);
  });

  test('micro-interleaves only in hidden stage', () async {
    final unitId = await createUnit('chain-review-interleave', endAyah: 3);

    var state = await engine.startSession(
      unitId: unitId,
      verses: const <ChainVerse>[
        ChainVerse(surah: 1, ayah: 1, text: 'v1'),
        ChainVerse(surah: 1, ayah: 2, text: 'v2'),
        ChainVerse(surah: 1, ayah: 3, text: 'v3'),
      ],
      launchMode: CompanionLaunchMode.review,
    );

    final evaluator = const ManualFallbackVerseEvaluator();
    for (var i = 0; i < 3; i++) {
      final update = await engine.submitAttempt(
        state: state,
        evaluator: evaluator,
        manualFallbackPass: false,
      );
      state = update.state;
    }

    expect(state.currentVerseIndex, 1);
    expect(state.returnVerseIndex, 0);

    final interleavedAttempt = await engine.submitAttempt(
      state: state,
      evaluator: evaluator,
      manualFallbackPass: false,
    );

    expect(interleavedAttempt.state.currentVerseIndex, 0);
    expect(interleavedAttempt.state.returnVerseIndex, isNull);
  });
}
