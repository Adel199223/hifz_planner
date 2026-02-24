import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/app/app_preferences.dart';
import 'package:hifz_planner/app/app_preferences_store.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/data/services/ayah_audio_service.dart';
import 'package:hifz_planner/data/services/ayah_audio_source.dart';
import 'package:hifz_planner/data/services/companion/companion_models.dart';
import 'package:hifz_planner/data/services/qurancom_api.dart';
import 'package:hifz_planner/data/services/tajweed_tags_service.dart';
import 'package:hifz_planner/screens/companion_chain_screen.dart';
import 'package:hifz_planner/ui/qcf/qcf_font_manager.dart';

import '../helpers/pump_until_found.dart';

void main() {
  void registerTestCleanup(WidgetTester tester) {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    });
  }

  String stageLabelText(WidgetTester tester) {
    final textWidget = tester.widget<Text>(
      find.byKey(const ValueKey('companion_stage_label')),
    );
    return textWidget.data ?? '';
  }

  String stage1ModeLabelText(WidgetTester tester) {
    final textWidget = tester.widget<Text>(
      find.byKey(const ValueKey('companion_stage1_mode_label')),
    );
    return textWidget.data ?? '';
  }

  String stage2ModeLabelText(WidgetTester tester) {
    final textWidget = tester.widget<Text>(
      find.byKey(const ValueKey('companion_stage2_mode_label')),
    );
    return textWidget.data ?? '';
  }

  String stage3ModeLabelText(WidgetTester tester) {
    final textWidget = tester.widget<Text>(
      find.byKey(const ValueKey('companion_stage3_mode_label')),
    );
    return textWidget.data ?? '';
  }

  bool autoplayToggleValue(WidgetTester tester) {
    final toggle =
        tester.widget(find.byKey(const ValueKey('companion_autoplay_toggle')));
    if (toggle is Switch) {
      return toggle.value;
    }
    if (toggle is CupertinoSwitch) {
      return toggle.value;
    }
    throw StateError(
        'Unexpected autoplay toggle widget: ${toggle.runtimeType}');
  }

  Finder firstAutoCheckOptionFinder({
    String prefix = 'companion_stage1_auto_check_',
  }) {
    return find.byWidgetPredicate((widget) {
      final key = widget.key;
      if (key is! ValueKey) {
        return false;
      }
      final value = key.value;
      return value is String && value.startsWith(prefix);
    });
  }

  Future<void> submitManualDecision(WidgetTester tester, bool passed) async {
    final recordButton =
        find.byKey(const ValueKey('companion_record_start_button'));
    await tester.ensureVisible(recordButton);
    await tester.tap(recordButton);
    await tester.pumpAndSettle();
    final passKey = passed
        ? const ValueKey('companion_mark_correct')
        : const ValueKey('companion_mark_incorrect');
    final decisionFinder = find.byKey(passKey);
    if (decisionFinder.evaluate().isNotEmpty) {
      await tester.tap(decisionFinder);
      await tester.pumpAndSettle();
    }
  }

  Future<void> driveToFirstColdProbe(WidgetTester tester) async {
    await submitManualDecision(tester, true);
    await submitManualDecision(tester, true);
    await submitManualDecision(tester, true);
  }

  Future<int> seedUnitAndAyah(
    AppDatabase db, {
    String unitKey = 'companion-u1',
  }) async {
    await db.into(db.ayah).insert(
          AyahCompanion.insert(
            surah: 1,
            ayah: 1,
            textUthmani: 'الرَّحْمٰنِ',
            pageMadina: const Value(1),
          ),
        );

    return db.into(db.memUnit).insert(
          MemUnitCompanion.insert(
            kind: 'ayah_range',
            unitKey: unitKey,
            startSurah: const Value(1),
            startAyah: const Value(1),
            endSurah: const Value(1),
            endAyah: const Value(1),
            pageMadina: const Value(1),
            createdAtDay: 100,
            updatedAtDay: 100,
          ),
        );
  }

  Future<void> seedUnlockedStage(
    AppDatabase db, {
    required int unitId,
    required CompanionStage stage,
  }) async {
    await db.into(db.companionUnitState).insert(
          CompanionUnitStateCompanion.insert(
            unitId: Value(unitId),
            unlockedStage: stage.stageNumber,
            updatedAtDay: 100,
            updatedAtSeconds: 100,
          ),
        );
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    ProviderContainer container, {
    required int unitId,
    required CompanionLaunchMode mode,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: CompanionChainScreen(
              unitId: unitId,
              launchMode: mode,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('companion_stage_label')),
    );
  }

  ProviderContainer buildContainer(
    AppDatabase db, {
    AppPreferencesStore? appPreferencesStore,
    AyahAudioService? audioService,
  }) {
    return ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        if (appPreferencesStore != null)
          appPreferencesStoreProvider.overrideWithValue(appPreferencesStore),
        if (audioService != null)
          ayahAudioServiceProvider.overrideWithValue(audioService),
        quranComApiProvider.overrideWithValue(_FakeQuranComApi()),
        qcfFontManagerProvider.overrideWithValue(
          _FakeQcfFontManager(familyName: 'qcf_companion_test'),
        ),
        tajweedTagsServiceProvider.overrideWith(
          (ref) => TajweedTagsService(
            loadAssetText: (_) async => '{}',
          ),
        ),
      ],
    );
  }

  testWidgets('new mode starts with Stage-1 model+echo and skip control',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final unitId = await seedUnitAndAyah(db, unitKey: 'companion-new-start');
    final container = buildContainer(db);
    addTearDown(container.dispose);
    registerTestCleanup(tester);

    await pumpScreen(
      tester,
      container,
      unitId: unitId,
      mode: CompanionLaunchMode.newMemorization,
    );

    expect(stageLabelText(tester), 'Guided visible');
    expect(stage1ModeLabelText(tester), 'Model + Echo');
    expect(find.byKey(const ValueKey('companion_skip_stage_button')),
        findsOneWidget);
  });

  testWidgets('forced cold probe hides text after echo cap', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final unitId = await seedUnitAndAyah(db, unitKey: 'companion-cold-hidden');
    final container = buildContainer(db);
    addTearDown(container.dispose);
    registerTestCleanup(tester);

    await pumpScreen(
      tester,
      container,
      unitId: unitId,
      mode: CompanionLaunchMode.newMemorization,
    );

    await driveToFirstColdProbe(tester);
    expect(stage1ModeLabelText(tester), 'Cold Probe');
    expect(find.byKey(const ValueKey('companion_stage1_hidden_prompt')),
        findsOneWidget);
  });

  testWidgets('micro-check is required by default on cold attempts',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final unitId = await seedUnitAndAyah(db, unitKey: 'companion-micro-check');
    final container = buildContainer(db);
    addTearDown(container.dispose);
    registerTestCleanup(tester);

    await pumpScreen(
      tester,
      container,
      unitId: unitId,
      mode: CompanionLaunchMode.newMemorization,
    );

    await driveToFirstColdProbe(tester);
    expect(find.byKey(const ValueKey('companion_stage1_auto_check_card')),
        findsOneWidget);

    final recordButton =
        find.byKey(const ValueKey('companion_record_start_button'));
    await tester.ensureVisible(recordButton);
    await tester.tap(recordButton);
    await tester.pumpAndSettle();
    expect(
      find.text('Select an answer for the micro-check first.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('companion_mark_correct')), findsNothing);
  });

  testWidgets('cold failure requires correction action before retry',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final unitId = await seedUnitAndAyah(db, unitKey: 'companion-correction');
    final container = buildContainer(db);
    addTearDown(container.dispose);
    registerTestCleanup(tester);

    await pumpScreen(
      tester,
      container,
      unitId: unitId,
      mode: CompanionLaunchMode.newMemorization,
    );

    await driveToFirstColdProbe(tester);
    final optionFinder = firstAutoCheckOptionFinder().first;
    await tester.ensureVisible(optionFinder);
    await tester.tap(optionFinder);
    await tester.pumpAndSettle();
    final recordButton =
        find.byKey(const ValueKey('companion_record_start_button'));
    final incorrectFinder =
        find.byKey(const ValueKey('companion_mark_incorrect'));
    for (var attempt = 0; attempt < 3; attempt++) {
      if (incorrectFinder.evaluate().isNotEmpty) {
        break;
      }
      await tester.ensureVisible(recordButton);
      await tester.tap(recordButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      if (incorrectFinder.evaluate().isEmpty) {
        await tester.ensureVisible(optionFinder);
        await tester.tap(optionFinder);
        await tester.pumpAndSettle();
      }
    }
    if (incorrectFinder.evaluate().isEmpty) {
      return;
    }
    await tester.tap(incorrectFinder);
    await tester.pumpAndSettle();

    expect(stage1ModeLabelText(tester), 'Correction');
    expect(find.text('Play Correction'), findsOneWidget);

    final correctionButton =
        find.byKey(const ValueKey('companion_record_start_button'));
    await tester.ensureVisible(correctionButton);
    await tester.tap(correctionButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(stage1ModeLabelText(tester), isNot('Correction'));
  });

  testWidgets('resumed Stage-2 session shows Stage-2 mode card and auto-check',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final unitId = await seedUnitAndAyah(db, unitKey: 'companion-stage2-start');
    await seedUnlockedStage(
      db,
      unitId: unitId,
      stage: CompanionStage.cuedRecall,
    );
    final container = buildContainer(db);
    addTearDown(container.dispose);
    registerTestCleanup(tester);

    await pumpScreen(
      tester,
      container,
      unitId: unitId,
      mode: CompanionLaunchMode.newMemorization,
    );

    expect(stageLabelText(tester), 'Cued recall');
    expect(find.byKey(const ValueKey('companion_stage2_mode_card')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('companion_stage1_mode_card')), findsNothing);
    expect(find.byKey(const ValueKey('companion_stage2_auto_check_card')),
        findsOneWidget);
  });

  testWidgets('Stage-2 micro-check selection is required by default',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final unitId = await seedUnitAndAyah(
      db,
      unitKey: 'companion-stage2-micro-check',
    );
    await seedUnlockedStage(
      db,
      unitId: unitId,
      stage: CompanionStage.cuedRecall,
    );
    final container = buildContainer(db);
    addTearDown(container.dispose);
    registerTestCleanup(tester);

    await pumpScreen(
      tester,
      container,
      unitId: unitId,
      mode: CompanionLaunchMode.newMemorization,
    );

    final recordButton =
        find.byKey(const ValueKey('companion_record_start_button'));
    await tester.ensureVisible(recordButton);
    await tester.tap(recordButton);
    await tester.pumpAndSettle();
    expect(
      find.text('Select an answer for the micro-check first.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('companion_mark_correct')), findsNothing);
  });

  testWidgets(
      'Stage-2 failure enters correction flow and requires correction action',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final unitId =
        await seedUnitAndAyah(db, unitKey: 'companion-stage2-correction');
    await seedUnlockedStage(
      db,
      unitId: unitId,
      stage: CompanionStage.cuedRecall,
    );
    final container = buildContainer(db);
    addTearDown(container.dispose);
    registerTestCleanup(tester);

    await pumpScreen(
      tester,
      container,
      unitId: unitId,
      mode: CompanionLaunchMode.newMemorization,
    );

    final optionFinder = firstAutoCheckOptionFinder(
      prefix: 'companion_stage2_auto_check_o',
    );
    await tester.ensureVisible(optionFinder.first);
    await tester.tap(optionFinder.first);
    await tester.pumpAndSettle();

    final recordButton =
        find.byKey(const ValueKey('companion_record_start_button'));
    await tester.ensureVisible(recordButton);
    await tester.tap(recordButton);
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('companion_mark_incorrect')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('companion_mark_incorrect')));
    await tester.pumpAndSettle();

    expect(stage2ModeLabelText(tester), 'Correction');
    expect(find.text('Play Stage-2 Correction'), findsOneWidget);

    await tester.ensureVisible(recordButton);
    await tester.tap(recordButton);
    await tester.pumpAndSettle();
    expect(stage2ModeLabelText(tester), isNot('Correction'));
  });

  testWidgets('skipping Stage-2 shows Stage-3 weak-prelude indicator',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final unitId = await seedUnitAndAyah(
      db,
      unitKey: 'companion-stage2-skip-prelude',
    );
    await seedUnlockedStage(
      db,
      unitId: unitId,
      stage: CompanionStage.cuedRecall,
    );
    final container = buildContainer(db);
    addTearDown(container.dispose);
    registerTestCleanup(tester);

    await pumpScreen(
      tester,
      container,
      unitId: unitId,
      mode: CompanionLaunchMode.newMemorization,
    );

    await tester.tap(find.byKey(const ValueKey('companion_skip_stage_button')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('companion_skip_stage_confirm')));
    await tester.pumpAndSettle();

    expect(stageLabelText(tester), 'Hidden reveal');
    expect(find.byKey(const ValueKey('companion_stage3_weak_prelude_banner')),
        findsOneWidget);
  });

  testWidgets('resumed Stage-3 session shows Stage-3 mode card and auto-check',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final unitId = await seedUnitAndAyah(
      db,
      unitKey: 'companion-stage3-start',
    );
    await seedUnlockedStage(
      db,
      unitId: unitId,
      stage: CompanionStage.hiddenReveal,
    );
    final container = buildContainer(db);
    addTearDown(container.dispose);
    registerTestCleanup(tester);

    await pumpScreen(
      tester,
      container,
      unitId: unitId,
      mode: CompanionLaunchMode.newMemorization,
    );

    expect(stageLabelText(tester), 'Hidden reveal');
    expect(find.byKey(const ValueKey('companion_stage3_mode_card')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('companion_stage2_mode_card')), findsNothing);
    expect(find.byKey(const ValueKey('companion_stage3_auto_check_card')),
        findsOneWidget);
  });

  testWidgets(
      'Stage-3 failure enters correction flow and requires correction action',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final unitId = await seedUnitAndAyah(
      db,
      unitKey: 'companion-stage3-correction',
    );
    await seedUnlockedStage(
      db,
      unitId: unitId,
      stage: CompanionStage.hiddenReveal,
    );
    final container = buildContainer(db);
    addTearDown(container.dispose);
    registerTestCleanup(tester);

    await pumpScreen(
      tester,
      container,
      unitId: unitId,
      mode: CompanionLaunchMode.newMemorization,
    );

    final optionFinder = firstAutoCheckOptionFinder(
      prefix: 'companion_stage3_auto_check_o',
    );
    await tester.ensureVisible(optionFinder.first);
    await tester.tap(optionFinder.first);
    await tester.pumpAndSettle();

    final recordButton =
        find.byKey(const ValueKey('companion_record_start_button'));
    await tester.ensureVisible(recordButton);
    await tester.tap(recordButton);
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('companion_mark_incorrect')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('companion_mark_incorrect')));
    await tester.pumpAndSettle();

    expect(stage3ModeLabelText(tester), 'Correction');
    expect(find.text('Play Stage-3 Correction'), findsOneWidget);

    await tester.ensureVisible(recordButton);
    await tester.tap(recordButton);
    await tester.pumpAndSettle();
    expect(stage3ModeLabelText(tester), isNot('Correction'));
  });

  testWidgets('review mode still starts hidden with no skip control',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final unitId = await seedUnitAndAyah(db, unitKey: 'companion-review-start');
    final container = buildContainer(db);
    addTearDown(container.dispose);
    registerTestCleanup(tester);

    await pumpScreen(
      tester,
      container,
      unitId: unitId,
      mode: CompanionLaunchMode.review,
    );

    expect(stageLabelText(tester), 'Hidden reveal');
    expect(find.byKey(const ValueKey('companion_skip_stage_button')),
        findsNothing);
  });

  testWidgets(
      'companion supports play action and autoplay toggle write-through',
      (tester) async {
    final store = _FakeAppPreferencesStore();
    final audio = _FakeAyahAudioService();
    final db = AppDatabase(NativeDatabase.memory());
    final unitId = await seedUnitAndAyah(db, unitKey: 'companion-audio-1');
    final container = buildContainer(
      db,
      appPreferencesStore: store,
      audioService: audio,
    );
    registerTestCleanup(tester);

    await pumpScreen(
      tester,
      container,
      unitId: unitId,
      mode: CompanionLaunchMode.newMemorization,
    );

    expect(find.byKey(const ValueKey('companion_play_ayah_button')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('companion_play_ayah_button')));
    await tester.pump();
    expect(audio.playAyahCalls, [const AyahRef(surah: 1, ayah: 1)]);

    expect(autoplayToggleValue(tester), isFalse);
    await tester.tap(find.byKey(const ValueKey('companion_autoplay_toggle')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(store.savedCompanionAutoReciteEnabled, isTrue);

    await audio.dispose();
    container.dispose();
  });

  testWidgets('word tooltip uses translation and suppresses end markers',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final unitId = await seedUnitAndAyah(
      db,
      unitKey: 'companion-word-tooltip',
    );
    final container = buildContainer(db);
    addTearDown(container.dispose);
    registerTestCleanup(tester);

    await pumpScreen(
      tester,
      container,
      unitId: unitId,
      mode: CompanionLaunchMode.newMemorization,
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('companion_word_1:1_0')),
    );

    final tooltipFinder =
        find.byKey(const ValueKey('companion_word_tooltip_1:1_0'));
    expect(tooltipFinder, findsOneWidget);
    final tooltip = tester.widget<Tooltip>(tooltipFinder);
    expect(tooltip.message, 'All praise and thanks');
    expect(find.byKey(const ValueKey('companion_word_1:1_1')), findsNothing);
  });
}

class _FakeAppPreferencesStore implements AppPreferencesStore {
  _FakeAppPreferencesStore({
    StoredAppPreferences? initial,
  }) : _stored = initial ?? const StoredAppPreferences();

  StoredAppPreferences _stored;
  bool? savedCompanionAutoReciteEnabled;

  @override
  Future<StoredAppPreferences> load() async {
    return _stored;
  }

  @override
  Future<void> saveLanguageCode(String code) async {
    _stored = StoredAppPreferences(
      languageCode: code,
      themeCode: _stored.themeCode,
      companionAutoReciteEnabled: _stored.companionAutoReciteEnabled,
    );
  }

  @override
  Future<void> saveThemeCode(String code) async {
    _stored = StoredAppPreferences(
      languageCode: _stored.languageCode,
      themeCode: code,
      companionAutoReciteEnabled: _stored.companionAutoReciteEnabled,
    );
  }

  @override
  Future<void> saveCompanionAutoReciteEnabled(bool value) async {
    savedCompanionAutoReciteEnabled = value;
    _stored = StoredAppPreferences(
      languageCode: _stored.languageCode,
      themeCode: _stored.themeCode,
      companionAutoReciteEnabled: value,
    );
  }
}

class _FakeAyahAudioService implements AyahAudioService {
  final StreamController<AyahAudioState> _stateController =
      StreamController<AyahAudioState>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  AyahAudioState _state = const AyahAudioState.initial();
  final List<AyahRef> playAyahCalls = <AyahRef>[];
  int pauseCalls = 0;

  @override
  Stream<AyahAudioState> get stateStream async* {
    yield _state;
    yield* _stateController.stream;
  }

  @override
  Stream<String> get errorStream => _errorController.stream;

  @override
  AyahAudioState get currentState => _state;

  @override
  Future<void> updateSource(
    AyahAudioSource source, {
    bool stopPlayback = true,
  }) async {}

  @override
  Future<void> playAyah(int surah, int ayah) async {
    playAyahCalls.add(AyahRef(surah: surah, ayah: ayah));
    _state = AyahAudioState(
      currentAyah: AyahRef(surah: surah, ayah: ayah),
      isPlaying: true,
      isBuffering: false,
      speed: _state.speed,
      repeatCount: _state.repeatCount,
      canNext: false,
      canPrevious: false,
      queueLength: 1,
      position: Duration.zero,
      bufferedPosition: Duration.zero,
      duration: null,
    );
    _stateController.add(_state);
  }

  @override
  Future<void> playFrom(int surah, int ayah) async {}

  @override
  Future<void> pause() async {
    pauseCalls += 1;
    _state = AyahAudioState(
      currentAyah: _state.currentAyah,
      isPlaying: false,
      isBuffering: false,
      speed: _state.speed,
      repeatCount: _state.repeatCount,
      canNext: _state.canNext,
      canPrevious: _state.canPrevious,
      queueLength: _state.queueLength,
      position: _state.position,
      bufferedPosition: _state.bufferedPosition,
      duration: _state.duration,
    );
    _stateController.add(_state);
  }

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> next() async {}

  @override
  Future<void> previous() async {}

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> setRepeatCount(int repeatCount) async {}

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _errorController.close();
  }
}

class _FakeQuranComApi extends QuranComApi {
  _FakeQuranComApi() : super();

  @override
  Future<MushafVerseData> getVerseDataByPage({
    required int page,
    required int mushafId,
    required String verseKey,
    int? translationResourceId,
  }) async {
    return const MushafVerseData(
      verseKey: '1:1',
      words: <MushafWord>[
        MushafWord(
          verseKey: '1:1',
          codeV2: 'A',
          textQpcHafs: 'A',
          translationText: 'All praise and thanks',
          charTypeName: 'word',
          lineNumber: 1,
          position: 1,
          pageNumber: 1,
        ),
        MushafWord(
          verseKey: '1:1',
          codeV2: '۝',
          textQpcHafs: '1',
          charTypeName: 'end',
          lineNumber: 1,
          position: 2,
          pageNumber: 1,
        ),
      ],
    );
  }
}

class _FakeQcfFontManager extends QcfFontManager {
  _FakeQcfFontManager({required this.familyName});

  final String familyName;

  @override
  Future<QcfFontSelection> ensurePageFont({
    required int page,
    required QcfFontVariant variant,
  }) async {
    return QcfFontSelection(
      familyName: familyName,
      requestedVariant: variant,
      effectiveVariant: variant,
    );
  }
}
