import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hifz_planner/app/app_preferences.dart';
import 'package:hifz_planner/app/app_preferences_store.dart';
import 'package:hifz_planner/data/providers/audio_providers.dart';
import 'package:hifz_planner/data/services/ayah_audio_preferences.dart';
import 'package:hifz_planner/data/services/ayah_reciter_catalog_service.dart';
import 'package:hifz_planner/data/services/ayah_audio_stream_resolver.dart';
import 'package:hifz_planner/screens/reciters_screen.dart';

void main() {
  testWidgets('reciters screen renders searchable list from provider',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        appPreferencesStoreProvider
            .overrideWithValue(_FakeAppPreferencesStore()),
        ayahAudioPreferencesStoreProvider
            .overrideWithValue(_FakeAudioPreferencesStore()),
        ayahAudioStreamResolverProvider.overrideWithValue(
          const _FakeAyahAudioStreamResolver(128),
        ),
        ayahReciterCatalogProvider.overrideWith(
          (ref) async => _sampleReciters,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: RecitersScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reciters_screen_root')), findsOneWidget);
    expect(find.byKey(const ValueKey('reciters_search_field')), findsOneWidget);
    expect(find.text('Alafasy'), findsOneWidget);
    expect(find.text('Hudhaify'), findsOneWidget);
  });

  testWidgets('selecting reciter updates persisted audio preferences',
      (tester) async {
    final audioStore = _FakeAudioPreferencesStore();
    final container = ProviderContainer(
      overrides: [
        appPreferencesStoreProvider
            .overrideWithValue(_FakeAppPreferencesStore()),
        ayahAudioPreferencesStoreProvider.overrideWithValue(audioStore),
        ayahAudioStreamResolverProvider.overrideWithValue(
          const _FakeAyahAudioStreamResolver(128),
        ),
        ayahReciterCatalogProvider.overrideWith(
          (ref) async => _sampleReciters,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: RecitersScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reciter_option_ar.hudhaify')));
    await tester.pumpAndSettle();

    final prefs = container.read(ayahAudioPreferencesProvider);
    expect(prefs.edition, 'ar.hudhaify');
    expect(prefs.reciterDisplayName, 'Hudhaify');
    expect(audioStore.savedEdition, 'ar.hudhaify');
    expect(audioStore.savedReciterName, 'Hudhaify');
  });

  testWidgets('reciter list is disabled while switch is in progress',
      (tester) async {
    final audioStore = _FakeAudioPreferencesStore();
    final container = ProviderContainer(
      overrides: [
        appPreferencesStoreProvider
            .overrideWithValue(_FakeAppPreferencesStore()),
        ayahAudioPreferencesStoreProvider.overrideWithValue(audioStore),
        ayahAudioStreamResolverProvider.overrideWithValue(
          const _FakeAyahAudioStreamResolver(128),
        ),
        ayahReciterCatalogProvider.overrideWith(
          (ref) async => _sampleReciters,
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(ayahReciterSwitchInProgressProvider.notifier)
        .setInProgress(true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: RecitersScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reciter_option_ar.hudhaify')));
    await tester.pumpAndSettle();

    final prefs = container.read(ayahAudioPreferencesProvider);
    expect(prefs.edition, 'ar.alafasy');
    expect(audioStore.savedEdition, isNull);
    expect(audioStore.savedReciterName, isNull);
  });
}

const List<AyahReciterOption> _sampleReciters = <AyahReciterOption>[
  AyahReciterOption(
    edition: 'ar.alafasy',
    englishName: 'Alafasy',
    nativeName: 'مشاري العفاسي',
    languageCode: 'ar',
    isFallback: false,
  ),
  AyahReciterOption(
    edition: 'ar.hudhaify',
    englishName: 'Hudhaify',
    nativeName: 'الحذيفي',
    languageCode: 'ar',
    isFallback: false,
  ),
];

class _FakeAppPreferencesStore implements AppPreferencesStore {
  @override
  Future<StoredAppPreferences> load() async {
    return const StoredAppPreferences();
  }

  @override
  Future<void> saveLanguageCode(String code) async {}

  @override
  Future<void> saveThemeCode(String code) async {}

  @override
  Future<void> saveCompanionAutoReciteEnabled(bool value) async {}

  @override
  Future<void> saveReaderShowVerseTranslation(bool value) async {}

  @override
  Future<void> saveReaderShowWordHelp(bool value) async {}

  @override
  Future<void> saveReaderShowTransliteration(bool value) async {}

  @override
  Future<void> saveLastReaderLocation({
    required String mode,
    int? page,
    int? surah,
    int? ayah,
  }) async {}

  @override
  Future<void> clearLastReaderLocation() async {}
}

class _FakeAudioPreferencesStore implements AyahAudioPreferencesStore {
  String? savedEdition;
  String? savedReciterName;

  @override
  Future<StoredAyahAudioPreferences> load() async {
    return const StoredAyahAudioPreferences();
  }

  @override
  Future<void> saveBitrate(int bitrate) async {}

  @override
  Future<void> saveEdition(String edition) async {
    savedEdition = edition;
  }

  @override
  Future<void> saveReciterDisplayName(String displayName) async {
    savedReciterName = displayName;
  }

  @override
  Future<void> saveRepeatCount(int repeatCount) async {}

  @override
  Future<void> saveSpeed(double speed) async {}
}

class _FakeAyahAudioStreamResolver implements AyahAudioStreamResolver {
  const _FakeAyahAudioStreamResolver(this._bitrate);

  final int? _bitrate;

  @override
  Future<int?> resolvePlayableBitrate({
    required String edition,
    required int preferredBitrate,
  }) async {
    return _bitrate;
  }
}
