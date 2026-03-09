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

    await tester.tap(find.byKey(const ValueKey('my_quran_library_button')));
    await pumpUntilFound(tester, find.text('Route /library'));
    expect(find.text('Route /library'), findsOneWidget);
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

  final StoredAppPreferences _stored;

  @override
  Future<StoredAppPreferences> load() async => _stored;

  @override
  Future<void> clearLastReaderLocation() async {}

  @override
  Future<void> saveCompanionAutoReciteEnabled(bool value) async {}

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
  Future<void> saveReaderShowTransliteration(bool value) async {}

  @override
  Future<void> saveReaderShowVerseTranslation(bool value) async {}

  @override
  Future<void> saveReaderShowWordHelp(bool value) async {}

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
