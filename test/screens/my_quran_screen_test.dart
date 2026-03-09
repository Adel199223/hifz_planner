import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hifz_planner/app/app_preferences.dart';
import 'package:hifz_planner/app/app_preferences_store.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/data/services/ayah_audio_preferences.dart';
import 'package:hifz_planner/screens/my_quran_screen.dart';

import '../helpers/pump_until_found.dart';

void main() {
  testWidgets('shows a useful no-history My Quran hub and opens Reader', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        appPreferencesStoreProvider.overrideWithValue(
          _FakeAppPreferencesStore(),
        ),
        ayahAudioPreferencesStoreProvider.overrideWithValue(
          _FakeAudioPreferencesStore(),
        ),
      ],
    );
    addTearDown(container.dispose);
    _registerTestCleanup(tester);

    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('my_quran_continue_card')),
    );

    expect(find.text('My Quran'), findsOneWidget);
    expect(
      find.text('Keep your place, saved study, and listening setup together.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('my_quran_continue_card')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('my_quran_saved_card')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('my_quran_listening_card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('my_quran_study_setup_card')),
      findsOneWidget,
    );
    expect(find.text('Start from Reader'), findsOneWidget);
    expect(
      find.text(
        'No recent reading saved yet. Open Reader to start from a place you can return to later.',
      ),
      findsOneWidget,
    );
    expect(find.text('Bookmarks: 0 · Notes: 0'), findsOneWidget);
    expect(
      find.text(
        'No saved items yet. Use Save for later or notes while you read.',
      ),
      findsOneWidget,
    );
    expect(find.text('Mishari Rashid al-`Afasy'), findsOneWidget);
    expect(find.text('Speed 1x · Repeat Off'), findsOneWidget);
    expect(
      find.text('Meaning help: translation On, word help On, transliteration Off.'),
      findsOneWidget,
    );
    expect(
      find.text('Practice from Memory: autoplay Off.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Choose the meaning help you want in Reader and whether Practice from Memory should autoplay the next ayah.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Use Listening setup if you want to change reciter.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('my_quran_continue_button')));
    await pumpUntilFound(tester, find.text('Route /reader'));

    expect(find.text('Route /reader'), findsOneWidget);
  });

  testWidgets(
    'continue reading uses the saved Reader snapshot when available',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            ref.onDispose(db.close);
            return db;
          }),
          appPreferencesStoreProvider.overrideWithValue(
            _FakeAppPreferencesStore(
              initial: const StoredAppPreferences(
                lastReaderMode: 'page',
                lastReaderPage: 42,
                lastReaderSurah: 2,
                lastReaderAyah: 255,
              ),
            ),
          ),
          ayahAudioPreferencesStoreProvider.overrideWithValue(
            _FakeAudioPreferencesStore(),
          ),
        ],
      );
      addTearDown(container.dispose);
      _registerTestCleanup(tester);

      final router = _buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await pumpUntilFound(tester, find.text('Resume on Page 42'));

      expect(find.text('Continue reading'), findsWidgets);
      expect(find.text('Resume on Page 42'), findsOneWidget);
      expect(
        find.text('Pick up where you last opened Reader.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('my_quran_continue_button')));
      await pumpUntilFound(
        tester,
        find.text(
          'Route /reader?mode=page&page=42&targetSurah=2&targetAyah=255',
        ),
      );

      expect(
        find.text(
          'Route /reader?mode=page&page=42&targetSurah=2&targetAyah=255',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows saved counts, library shortcut, and listening summary', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final now = DateTime(2026, 3, 9, 8, 30);
    await db.into(db.bookmark).insert(
          BookmarkCompanion.insert(surah: 2, ayah: 255, createdAt: Value(now)),
        );
    await db.into(db.note).insert(
          NoteCompanion.insert(
            surah: 18,
            ayah: 10,
            body: 'Keep this for later',
            updatedAt: Value(now),
          ),
        );

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        appPreferencesStoreProvider.overrideWithValue(
          _FakeAppPreferencesStore(),
        ),
        ayahAudioPreferencesStoreProvider.overrideWithValue(
          _FakeAudioPreferencesStore(
            stored: const StoredAyahAudioPreferences(
              edition: 'ar.hudhaify',
              speed: 1.25,
              repeatCount: 2,
              reciterDisplayName: 'Hudhaify',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    _registerTestCleanup(tester);

    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpUntilFound(tester, find.text('Bookmarks: 1 · Notes: 1'));

    expect(
      find.text('Open Library to revisit saved verses and notes.'),
      findsOneWidget,
    );
    expect(find.text('Hudhaify'), findsOneWidget);
    expect(find.text('Speed 1.25x · Repeat 2x'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('my_quran_library_button')),
    );
    await tester.tap(find.byKey(const ValueKey('my_quran_library_button')));
    await pumpUntilFound(tester, find.text('Route /library'));
    expect(find.text('Route /library'), findsOneWidget);
  });

  testWidgets('shows latest saved previews and reopens them in Reader', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final earlier = DateTime(2026, 3, 9, 8, 0);
    final later = DateTime(2026, 3, 9, 9, 15);
    await db.into(db.ayah).insert(
          AyahCompanion.insert(
            surah: 2,
            ayah: 255,
            textUthmani: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
            pageMadina: const Value(42),
          ),
        );
    await db.into(db.ayah).insert(
          AyahCompanion.insert(
            surah: 18,
            ayah: 10,
            textUthmani: 'رَبَّنَا آتِنَا مِن لَّدُنكَ رَحْمَةً',
            pageMadina: const Value(293),
          ),
        );
    await db.into(db.bookmark).insert(
          BookmarkCompanion.insert(
            surah: 1,
            ayah: 1,
            createdAt: Value(earlier),
          ),
        );
    await db.into(db.bookmark).insert(
          BookmarkCompanion.insert(
            surah: 2,
            ayah: 255,
            createdAt: Value(later),
          ),
        );
    await db.into(db.note).insert(
          NoteCompanion.insert(
            surah: 18,
            ayah: 10,
            title: const Value('Cave opening'),
            body: 'Remember the dua here.',
            updatedAt: Value(later),
          ),
        );

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        appPreferencesStoreProvider.overrideWithValue(
          _FakeAppPreferencesStore(),
        ),
        ayahAudioPreferencesStoreProvider.overrideWithValue(
          _FakeAudioPreferencesStore(),
        ),
      ],
    );
    addTearDown(container.dispose);
    _registerTestCleanup(tester);

    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('my_quran_latest_bookmark_section')),
    );

    expect(find.text('Latest bookmark'), findsOneWidget);
    expect(find.text('Surah 2, Ayah 255'), findsOneWidget);
    expect(find.text('اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ'), findsOneWidget);
    expect(find.text('Page 42'), findsOneWidget);

    expect(find.text('Latest note'), findsOneWidget);
    expect(find.text('Surah 18, Ayah 10'), findsOneWidget);
    expect(find.text('Cave opening: Remember the dua here.'), findsOneWidget);
    expect(find.text('Page 293'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('my_quran_reopen_bookmark_button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('my_quran_reopen_bookmark_button')),
    );
    await pumpUntilFound(
      tester,
      find.text('Route /reader?mode=page&page=42&targetSurah=2&targetAyah=255'),
    );
    expect(
      find.text('Route /reader?mode=page&page=42&targetSurah=2&targetAyah=255'),
      findsOneWidget,
    );

    router.go('/my-quran');
    await tester.pumpAndSettle();
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('my_quran_reopen_note_button')),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('my_quran_reopen_note_button')),
    );
    await tester.tap(find.byKey(const ValueKey('my_quran_reopen_note_button')));
    await pumpUntilFound(
      tester,
      find.text(
        'Route /reader?mode=page&page=293&targetSurah=18&targetAyah=10',
      ),
    );
    expect(
      find.text('Route /reader?mode=page&page=293&targetSurah=18&targetAyah=10'),
      findsOneWidget,
    );
  });

  testWidgets('shows study setup summary and updates shortcuts inline', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final store = _FakeAppPreferencesStore(
      initial: const StoredAppPreferences(
        companionAutoReciteEnabled: true,
        readerShowVerseTranslation: false,
        readerShowWordHelp: false,
        readerShowTransliteration: true,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        appPreferencesStoreProvider.overrideWithValue(store),
        ayahAudioPreferencesStoreProvider.overrideWithValue(
          _FakeAudioPreferencesStore(),
        ),
      ],
    );
    addTearDown(container.dispose);
    _registerTestCleanup(tester);

    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('my_quran_study_setup_card')),
    );

    expect(
      find.text(
        'Meaning help: translation Off, word help Off, transliteration On.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Practice from Memory: autoplay On.'),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('my_quran_study_translation_toggle')),
    );
    await tester.tap(
      find.byKey(const ValueKey('my_quran_study_translation_toggle')),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('my_quran_study_word_help_toggle')),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('my_quran_study_transliteration_toggle')),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('my_quran_study_autoplay_toggle')),
    );
    await tester.pump();

    expect(
      find.text('Meaning help: translation On, word help On, transliteration Off.'),
      findsOneWidget,
    );
    expect(
      find.text('Practice from Memory: autoplay Off.'),
      findsOneWidget,
    );
    expect(store.savedReaderShowVerseTranslation, isTrue);
    expect(store.savedReaderShowWordHelp, isTrue);
    expect(store.savedReaderShowTransliteration, isFalse);
    expect(store.savedCompanionAutoReciteEnabled, isFalse);
  });
}

void _registerTestCleanup(WidgetTester tester) {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/my-quran',
    routes: [
      GoRoute(
        path: '/my-quran',
        builder: (_, __) => const Scaffold(body: MyQuranScreen()),
      ),
      GoRoute(
        path: '/reader',
        builder: (context, state) =>
            Scaffold(body: Center(child: Text('Route ${state.uri}'))),
      ),
      GoRoute(
        path: '/library',
        builder: (context, state) =>
            Scaffold(body: Center(child: Text('Route ${state.uri}'))),
      ),
      GoRoute(
        path: '/reciters',
        builder: (context, state) =>
            Scaffold(body: Center(child: Text('Route ${state.uri}'))),
      ),
    ],
  );
}

class _FakeAppPreferencesStore implements AppPreferencesStore {
  _FakeAppPreferencesStore({StoredAppPreferences? initial})
      : _stored = initial ?? const StoredAppPreferences();

  StoredAppPreferences _stored;
  bool? savedCompanionAutoReciteEnabled;
  bool? savedReaderShowVerseTranslation;
  bool? savedReaderShowWordHelp;
  bool? savedReaderShowTransliteration;

  @override
  Future<StoredAppPreferences> load() async => _stored;

  @override
  Future<void> clearLastReaderLocation() async {}

  @override
  Future<void> saveCompanionAutoReciteEnabled(bool value) async {
    savedCompanionAutoReciteEnabled = value;
    _stored = StoredAppPreferences(
      languageCode: _stored.languageCode,
      themeCode: _stored.themeCode,
      companionAutoReciteEnabled: value,
      readerShowVerseTranslation: _stored.readerShowVerseTranslation,
      readerShowWordHelp: _stored.readerShowWordHelp,
      readerShowTransliteration: _stored.readerShowTransliteration,
      lastReaderMode: _stored.lastReaderMode,
      lastReaderPage: _stored.lastReaderPage,
      lastReaderSurah: _stored.lastReaderSurah,
      lastReaderAyah: _stored.lastReaderAyah,
    );
  }

  @override
  Future<void> saveLanguageCode(String code) async {}

  @override
  Future<void> saveLastReaderLocation({
    required String mode,
    int? page,
    int? surah,
    int? ayah,
  }) async {}

  @override
  Future<void> saveReaderShowTransliteration(bool value) async {
    savedReaderShowTransliteration = value;
    _stored = StoredAppPreferences(
      languageCode: _stored.languageCode,
      themeCode: _stored.themeCode,
      companionAutoReciteEnabled: _stored.companionAutoReciteEnabled,
      readerShowVerseTranslation: _stored.readerShowVerseTranslation,
      readerShowWordHelp: _stored.readerShowWordHelp,
      readerShowTransliteration: value,
      lastReaderMode: _stored.lastReaderMode,
      lastReaderPage: _stored.lastReaderPage,
      lastReaderSurah: _stored.lastReaderSurah,
      lastReaderAyah: _stored.lastReaderAyah,
    );
  }

  @override
  Future<void> saveReaderShowVerseTranslation(bool value) async {
    savedReaderShowVerseTranslation = value;
    _stored = StoredAppPreferences(
      languageCode: _stored.languageCode,
      themeCode: _stored.themeCode,
      companionAutoReciteEnabled: _stored.companionAutoReciteEnabled,
      readerShowVerseTranslation: value,
      readerShowWordHelp: _stored.readerShowWordHelp,
      readerShowTransliteration: _stored.readerShowTransliteration,
      lastReaderMode: _stored.lastReaderMode,
      lastReaderPage: _stored.lastReaderPage,
      lastReaderSurah: _stored.lastReaderSurah,
      lastReaderAyah: _stored.lastReaderAyah,
    );
  }

  @override
  Future<void> saveReaderShowWordHelp(bool value) async {
    savedReaderShowWordHelp = value;
    _stored = StoredAppPreferences(
      languageCode: _stored.languageCode,
      themeCode: _stored.themeCode,
      companionAutoReciteEnabled: _stored.companionAutoReciteEnabled,
      readerShowVerseTranslation: _stored.readerShowVerseTranslation,
      readerShowWordHelp: value,
      readerShowTransliteration: _stored.readerShowTransliteration,
      lastReaderMode: _stored.lastReaderMode,
      lastReaderPage: _stored.lastReaderPage,
      lastReaderSurah: _stored.lastReaderSurah,
      lastReaderAyah: _stored.lastReaderAyah,
    );
  }

  @override
  Future<void> saveThemeCode(String code) async {}
}

class _FakeAudioPreferencesStore implements AyahAudioPreferencesStore {
  _FakeAudioPreferencesStore({StoredAyahAudioPreferences? stored})
      : _stored = stored ?? const StoredAyahAudioPreferences();

  final StoredAyahAudioPreferences _stored;

  @override
  Future<StoredAyahAudioPreferences> load() async => _stored;

  @override
  Future<void> saveBitrate(int bitrate) async {}

  @override
  Future<void> saveEdition(String edition) async {}

  @override
  Future<void> saveReciterDisplayName(String displayName) async {}

  @override
  Future<void> saveRepeatCount(int repeatCount) async {}

  @override
  Future<void> saveSpeed(double speed) async {}
}
