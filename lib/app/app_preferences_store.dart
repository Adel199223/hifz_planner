import 'package:shared_preferences/shared_preferences.dart';

class StoredAppPreferences {
  const StoredAppPreferences({
    this.languageCode,
    this.themeCode,
  });

  final String? languageCode;
  final String? themeCode;
}

abstract class AppPreferencesStore {
  Future<StoredAppPreferences> load();

  Future<void> saveLanguageCode(String code);

  Future<void> saveThemeCode(String code);
}

class SharedPrefsAppPreferencesStore implements AppPreferencesStore {
  const SharedPrefsAppPreferencesStore();

  static const String _languageCodeKey = 'app_preferences.language_code';
  static const String _themeCodeKey = 'app_preferences.theme_code';

  @override
  Future<StoredAppPreferences> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return StoredAppPreferences(
        languageCode: prefs.getString(_languageCodeKey),
        themeCode: prefs.getString(_themeCodeKey),
      );
    } catch (_) {
      return const StoredAppPreferences();
    }
  }

  @override
  Future<void> saveLanguageCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageCodeKey, code);
    } catch (_) {
      // Keep runtime behavior stable even when local persistence is unavailable.
    }
  }

  @override
  Future<void> saveThemeCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeCodeKey, code);
    } catch (_) {
      // Keep runtime behavior stable even when local persistence is unavailable.
    }
  }
}
