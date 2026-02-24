import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/app/app_preferences.dart';
import 'package:hifz_planner/app/app_preferences_store.dart';
import 'package:hifz_planner/data/services/ayah_audio_service.dart';
import 'package:hifz_planner/data/services/ayah_audio_source.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
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

  Future<int> seedUnitAndAyah(AppDatabase db,
      {String unitKey = 'companion-u1'}) async {
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

  testWidgets('new mode starts guided stage and shows skip control',
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
    expect(find.byKey(const ValueKey('companion_skip_stage_button')),
        findsOneWidget);
  });

  testWidgets('skip control advances Stage 1 -> Stage 2 -> Stage 3',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final unitId = await seedUnitAndAyah(db, unitKey: 'companion-skip-flow');
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
    expect(stageLabelText(tester), 'Cued recall');

    await tester.tap(find.byKey(const ValueKey('companion_skip_stage_button')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('companion_skip_stage_confirm')));
    await tester.pumpAndSettle();
    expect(stageLabelText(tester), 'Hidden reveal');
    expect(find.byKey(const ValueKey('companion_skip_stage_button')),
        findsNothing);
  });

  testWidgets('review mode starts hidden stage with no skip control',
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

  testWidgets('correct attempts progress Stage 1 to Stage 2 to Stage 3',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final unitId = await seedUnitAndAyah(db, unitKey: 'companion-pass-flow');
    final container = buildContainer(db);
    addTearDown(container.dispose);
    registerTestCleanup(tester);

    await pumpScreen(
      tester,
      container,
      unitId: unitId,
      mode: CompanionLaunchMode.newMemorization,
    );

    await tester
        .tap(find.byKey(const ValueKey('companion_record_start_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('companion_mark_correct')));
    await tester.pumpAndSettle();
    expect(stageLabelText(tester), 'Cued recall');

    await tester
        .tap(find.byKey(const ValueKey('companion_record_start_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('companion_mark_correct')));
    await tester.pumpAndSettle();
    expect(stageLabelText(tester), 'Hidden reveal');
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

  testWidgets('hidden stage no longer renders dot placeholder text',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final unitId = await seedUnitAndAyah(
      db,
      unitKey: 'companion-hidden-placeholder',
    );
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
    expect(find.text('••••••••••'), findsNothing);
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
