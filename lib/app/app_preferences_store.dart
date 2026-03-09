import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();
typedef PreferenceErrorReporter =
    void Function(String operation, Object error, StackTrace stackTrace);

class StoredAppPreferences {
  const StoredAppPreferences({
    this.languageCode,
    this.themeCode,
    this.companionAutoReciteEnabled,
    this.readerShowVerseTranslation,
    this.readerShowWordHelp,
    this.readerShowTransliteration,
    this.lastReaderMode,
    this.lastReaderPage,
    this.lastReaderSurah,
    this.lastReaderAyah,
  });

  final String? languageCode;
  final String? themeCode;
  final bool? companionAutoReciteEnabled;
  final bool? readerShowVerseTranslation;
  final bool? readerShowWordHelp;
  final bool? readerShowTransliteration;
  final String? lastReaderMode;
  final int? lastReaderPage;
  final int? lastReaderSurah;
  final int? lastReaderAyah;
}

abstract class AppPreferencesStore {
  Future<StoredAppPreferences> load();

  Future<void> saveLanguageCode(String code);

  Future<void> saveThemeCode(String code);

  Future<void> saveCompanionAutoReciteEnabled(bool value);

  Future<void> saveReaderShowVerseTranslation(bool value);

  Future<void> saveReaderShowWordHelp(bool value);

  Future<void> saveReaderShowTransliteration(bool value);

  Future<void> saveLastReaderLocation({
    required String mode,
    int? page,
    int? surah,
    int? ayah,
  });

  Future<void> clearLastReaderLocation();
}

class SharedPrefsAppPreferencesStore implements AppPreferencesStore {
  SharedPrefsAppPreferencesStore({
    SharedPreferencesLoader? loadPreferences,
    PreferenceErrorReporter? reportError,
  }) : _loadPreferences = loadPreferences ?? SharedPreferences.getInstance,
       _reportError = reportError ?? _defaultReportError;

  static const String _languageCodeKey = 'app_preferences.language_code';
  static const String _themeCodeKey = 'app_preferences.theme_code';
  static const String _companionAutoReciteEnabledKey =
      'app_preferences.companion_auto_recite_enabled';
  static const String _readerShowVerseTranslationKey =
      'app_preferences.reader_show_verse_translation';
  static const String _readerShowWordHelpKey =
      'app_preferences.reader_show_word_help';
  static const String _readerShowTransliterationKey =
      'app_preferences.reader_show_transliteration';
  static const String _lastReaderModeKey = 'app_preferences.last_reader_mode';
  static const String _lastReaderPageKey = 'app_preferences.last_reader_page';
  static const String _lastReaderSurahKey = 'app_preferences.last_reader_surah';
  static const String _lastReaderAyahKey = 'app_preferences.last_reader_ayah';

  final SharedPreferencesLoader _loadPreferences;
  final PreferenceErrorReporter _reportError;

  @override
  Future<StoredAppPreferences> load() async {
    try {
      final prefs = await _loadPreferences();
      return StoredAppPreferences(
        languageCode: prefs.getString(_languageCodeKey),
        themeCode: prefs.getString(_themeCodeKey),
        companionAutoReciteEnabled: prefs.getBool(
          _companionAutoReciteEnabledKey,
        ),
        readerShowVerseTranslation: prefs.getBool(
          _readerShowVerseTranslationKey,
        ),
        readerShowWordHelp: prefs.getBool(_readerShowWordHelpKey),
        readerShowTransliteration: prefs.getBool(_readerShowTransliterationKey),
        lastReaderMode: prefs.getString(_lastReaderModeKey),
        lastReaderPage: prefs.getInt(_lastReaderPageKey),
        lastReaderSurah: prefs.getInt(_lastReaderSurahKey),
        lastReaderAyah: prefs.getInt(_lastReaderAyahKey),
      );
    } catch (error, stackTrace) {
      _reportError('load app preferences', error, stackTrace);
      return const StoredAppPreferences();
    }
  }

  @override
  Future<void> saveLanguageCode(String code) async {
    await _savePreference(
      operation: 'save app language code',
      action: (prefs) => prefs.setString(_languageCodeKey, code),
    );
  }

  @override
  Future<void> saveThemeCode(String code) async {
    await _savePreference(
      operation: 'save app theme code',
      action: (prefs) => prefs.setString(_themeCodeKey, code),
    );
  }

  @override
  Future<void> saveCompanionAutoReciteEnabled(bool value) async {
    await _savePreference(
      operation: 'save companion auto-recite preference',
      action: (prefs) => prefs.setBool(_companionAutoReciteEnabledKey, value),
    );
  }

  @override
  Future<void> saveReaderShowVerseTranslation(bool value) async {
    await _savePreference(
      operation: 'save reader verse translation preference',
      action: (prefs) => prefs.setBool(_readerShowVerseTranslationKey, value),
    );
  }

  @override
  Future<void> saveReaderShowWordHelp(bool value) async {
    await _savePreference(
      operation: 'save reader word help preference',
      action: (prefs) => prefs.setBool(_readerShowWordHelpKey, value),
    );
  }

  @override
  Future<void> saveReaderShowTransliteration(bool value) async {
    await _savePreference(
      operation: 'save reader transliteration preference',
      action: (prefs) => prefs.setBool(_readerShowTransliterationKey, value),
    );
  }

  @override
  Future<void> saveLastReaderLocation({
    required String mode,
    int? page,
    int? surah,
    int? ayah,
  }) async {
    await _savePreference(
      operation: 'save last reader location preference',
      action: (prefs) async {
        final didSaveMode = await prefs.setString(_lastReaderModeKey, mode);
        final didSavePage = page == null
            ? await prefs.remove(_lastReaderPageKey)
            : await prefs.setInt(_lastReaderPageKey, page);
        final didSaveSurah = surah == null
            ? await prefs.remove(_lastReaderSurahKey)
            : await prefs.setInt(_lastReaderSurahKey, surah);
        final didSaveAyah = ayah == null
            ? await prefs.remove(_lastReaderAyahKey)
            : await prefs.setInt(_lastReaderAyahKey, ayah);
        return didSaveMode && didSavePage && didSaveSurah && didSaveAyah;
      },
    );
  }

  @override
  Future<void> clearLastReaderLocation() async {
    await _savePreference(
      operation: 'clear last reader location preference',
      action: (prefs) async {
        final didClearMode = await prefs.remove(_lastReaderModeKey);
        final didClearPage = await prefs.remove(_lastReaderPageKey);
        final didClearSurah = await prefs.remove(_lastReaderSurahKey);
        final didClearAyah = await prefs.remove(_lastReaderAyahKey);
        return didClearMode && didClearPage && didClearSurah && didClearAyah;
      },
    );
  }

  Future<void> _savePreference({
    required String operation,
    required Future<bool> Function(SharedPreferences prefs) action,
  }) async {
    try {
      final prefs = await _loadPreferences();
      final didSave = await action(prefs);
      if (!didSave) {
        _reportError(
          operation,
          StateError('$operation returned false.'),
          StackTrace.current,
        );
      }
    } catch (error, stackTrace) {
      _reportError(operation, error, stackTrace);
    }
  }
}

void _defaultReportError(
  String operation,
  Object error,
  StackTrace stackTrace,
) {
  developer.log(
    operation,
    name: 'app_preferences_store',
    error: error,
    stackTrace: stackTrace,
  );
}
