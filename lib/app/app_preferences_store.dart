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
  });

  final String? languageCode;
  final String? themeCode;
  final bool? companionAutoReciteEnabled;
}

abstract class AppPreferencesStore {
  Future<StoredAppPreferences> load();

  Future<void> saveLanguageCode(String code);

  Future<void> saveThemeCode(String code);

  Future<void> saveCompanionAutoReciteEnabled(bool value);
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

  final SharedPreferencesLoader _loadPreferences;
  final PreferenceErrorReporter _reportError;

  @override
  Future<StoredAppPreferences> load() async {
    try {
      final prefs = await _loadPreferences();
      return StoredAppPreferences(
        languageCode: prefs.getString(_languageCodeKey),
        themeCode: prefs.getString(_themeCodeKey),
        companionAutoReciteEnabled:
            prefs.getBool(_companionAutoReciteEnabledKey),
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
