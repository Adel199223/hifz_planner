import 'package:shared_preferences/shared_preferences.dart';

class StoredReaderDisplayPreferences {
  const StoredReaderDisplayPreferences({
    this.showVerseTranslations,
    this.showWordTooltips,
    this.showWordHoverHighlights,
  });

  final bool? showVerseTranslations;
  final bool? showWordTooltips;
  final bool? showWordHoverHighlights;
}

abstract class ReaderDisplayPreferencesStore {
  Future<StoredReaderDisplayPreferences> load();

  Future<void> saveShowVerseTranslations(bool value);

  Future<void> saveShowWordTooltips(bool value);

  Future<void> saveShowWordHoverHighlights(bool value);
}

class SharedPrefsReaderDisplayPreferencesStore
    implements ReaderDisplayPreferencesStore {
  const SharedPrefsReaderDisplayPreferencesStore();

  static const String _showVerseTranslationsKey =
      'reader_display.show_verse_translations';
  static const String _showWordTooltipsKey =
      'reader_display.show_word_tooltips';
  static const String _showWordHoverHighlightsKey =
      'reader_display.show_word_hover_highlights';

  @override
  Future<StoredReaderDisplayPreferences> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return StoredReaderDisplayPreferences(
        showVerseTranslations: prefs.getBool(_showVerseTranslationsKey),
        showWordTooltips: prefs.getBool(_showWordTooltipsKey),
        showWordHoverHighlights: prefs.getBool(_showWordHoverHighlightsKey),
      );
    } catch (_) {
      return const StoredReaderDisplayPreferences();
    }
  }

  @override
  Future<void> saveShowVerseTranslations(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showVerseTranslationsKey, value);
    } catch (_) {
      // Keep runtime stable even when persistence is unavailable.
    }
  }

  @override
  Future<void> saveShowWordTooltips(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showWordTooltipsKey, value);
    } catch (_) {
      // Keep runtime stable even when persistence is unavailable.
    }
  }

  @override
  Future<void> saveShowWordHoverHighlights(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showWordHoverHighlightsKey, value);
    } catch (_) {
      // Keep runtime stable even when persistence is unavailable.
    }
  }
}
