import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hifz_planner/app/app_preferences.dart';
import 'package:hifz_planner/app/app_preferences_store.dart';
import 'package:hifz_planner/l10n/app_language.dart';

void main() {
  test('restores language and theme from store', () async {
    final store = _FakeAppPreferencesStore(
      initial: const StoredAppPreferences(
        languageCode: 'pt',
        themeCode: 'dark',
        companionAutoReciteEnabled: true,
        readerShowVerseTranslation: false,
        readerShowWordHelp: false,
        readerShowTransliteration: true,
        lastReaderMode: 'page',
        lastReaderPage: 42,
        lastReaderSurah: 2,
        lastReaderAyah: 255,
      ),
    );
    final container = ProviderContainer(
      overrides: [appPreferencesStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    container.read(appPreferencesProvider);
    await _flush();
    await _flush();

    final state = container.read(appPreferencesProvider);
    expect(state.language, AppLanguage.portuguese);
    expect(state.theme, AppThemeChoice.dark);
    expect(state.companionAutoReciteEnabled, isTrue);
    expect(state.readerShowVerseTranslation, isFalse);
    expect(state.readerShowWordHelp, isFalse);
    expect(state.readerShowTransliteration, isTrue);
    expect(state.readerLastLocation, isNotNull);
    expect(state.readerLastLocation!.mode, ReaderLastLocationMode.page);
    expect(state.readerLastLocation!.page, 42);
    expect(state.readerLastLocation!.targetSurah, 2);
    expect(state.readerLastLocation!.targetAyah, 255);
    expect(state.hasLoaded, isTrue);
  });

  test('writes language and theme changes to store', () async {
    final store = _FakeAppPreferencesStore();
    final container = ProviderContainer(
      overrides: [appPreferencesStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    container.read(appPreferencesProvider);
    await _flush();

    await container
        .read(appPreferencesProvider.notifier)
        .setLanguage(AppLanguage.french);
    await container
        .read(appPreferencesProvider.notifier)
        .setTheme(AppThemeChoice.dark);
    await container
        .read(appPreferencesProvider.notifier)
        .setCompanionAutoReciteEnabled(true);
    await container
        .read(appPreferencesProvider.notifier)
        .setReaderShowVerseTranslation(false);
    await container
        .read(appPreferencesProvider.notifier)
        .setReaderShowWordHelp(false);
    await container
        .read(appPreferencesProvider.notifier)
        .setReaderShowTransliteration(true);
    await container
        .read(appPreferencesProvider.notifier)
        .setReaderLastLocation(
          mode: ReaderLastLocationMode.verse,
          targetSurah: 18,
          targetAyah: 10,
        );

    final state = container.read(appPreferencesProvider);
    expect(state.language, AppLanguage.french);
    expect(state.theme, AppThemeChoice.dark);
    expect(state.companionAutoReciteEnabled, isTrue);
    expect(state.readerShowVerseTranslation, isFalse);
    expect(state.readerShowWordHelp, isFalse);
    expect(state.readerShowTransliteration, isTrue);
    expect(state.readerLastLocation, isNotNull);
    expect(state.readerLastLocation!.mode, ReaderLastLocationMode.verse);
    expect(state.readerLastLocation!.targetSurah, 18);
    expect(state.readerLastLocation!.targetAyah, 10);
    expect(store.savedLanguageCode, 'fr');
    expect(store.savedThemeCode, 'dark');
    expect(store.savedCompanionAutoReciteEnabled, isTrue);
    expect(store.savedReaderShowVerseTranslation, isFalse);
    expect(store.savedReaderShowWordHelp, isFalse);
    expect(store.savedReaderShowTransliteration, isTrue);
    expect(store.savedLastReaderMode, 'verse');
    expect(store.savedLastReaderSurah, 18);
    expect(store.savedLastReaderAyah, 10);

    await container
        .read(appPreferencesProvider.notifier)
        .clearReaderLastLocation();

    final cleared = container.read(appPreferencesProvider);
    expect(cleared.readerLastLocation, isNull);
    expect(store.didClearLastReaderLocation, isTrue);
  });
}

Future<void> _flush() {
  return Future<void>.delayed(Duration.zero);
}

class _FakeAppPreferencesStore implements AppPreferencesStore {
  _FakeAppPreferencesStore({StoredAppPreferences? initial})
    : _stored = initial ?? const StoredAppPreferences();

  StoredAppPreferences _stored;
  String? savedLanguageCode;
  String? savedThemeCode;
  bool? savedCompanionAutoReciteEnabled;
  bool? savedReaderShowVerseTranslation;
  bool? savedReaderShowWordHelp;
  bool? savedReaderShowTransliteration;
  String? savedLastReaderMode;
  int? savedLastReaderPage;
  int? savedLastReaderSurah;
  int? savedLastReaderAyah;
  bool didClearLastReaderLocation = false;

  @override
  Future<StoredAppPreferences> load() async {
    return _stored;
  }

  @override
  Future<void> saveLanguageCode(String code) async {
    savedLanguageCode = code;
    _stored = StoredAppPreferences(
      languageCode: code,
      themeCode: _stored.themeCode,
      companionAutoReciteEnabled: _stored.companionAutoReciteEnabled,
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
  Future<void> saveThemeCode(String code) async {
    savedThemeCode = code;
    _stored = StoredAppPreferences(
      languageCode: _stored.languageCode,
      themeCode: code,
      companionAutoReciteEnabled: _stored.companionAutoReciteEnabled,
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
  Future<void> saveLastReaderLocation({
    required String mode,
    int? page,
    int? surah,
    int? ayah,
  }) async {
    savedLastReaderMode = mode;
    savedLastReaderPage = page;
    savedLastReaderSurah = surah;
    savedLastReaderAyah = ayah;
    didClearLastReaderLocation = false;
    _stored = StoredAppPreferences(
      languageCode: _stored.languageCode,
      themeCode: _stored.themeCode,
      companionAutoReciteEnabled: _stored.companionAutoReciteEnabled,
      readerShowVerseTranslation: _stored.readerShowVerseTranslation,
      readerShowWordHelp: _stored.readerShowWordHelp,
      readerShowTransliteration: _stored.readerShowTransliteration,
      lastReaderMode: mode,
      lastReaderPage: page,
      lastReaderSurah: surah,
      lastReaderAyah: ayah,
    );
  }

  @override
  Future<void> clearLastReaderLocation() async {
    didClearLastReaderLocation = true;
    _stored = StoredAppPreferences(
      languageCode: _stored.languageCode,
      themeCode: _stored.themeCode,
      companionAutoReciteEnabled: _stored.companionAutoReciteEnabled,
      readerShowVerseTranslation: _stored.readerShowVerseTranslation,
      readerShowWordHelp: _stored.readerShowWordHelp,
      readerShowTransliteration: _stored.readerShowTransliteration,
    );
  }
}
