import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_language.dart';
import 'app_preferences_store.dart';

enum AppThemeChoice {
  sepia(code: 'sepia'),
  dark(code: 'dark');

  const AppThemeChoice({
    required this.code,
  });

  final String code;

  static AppThemeChoice? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final value in values) {
      if (value.code == code) {
        return value;
      }
    }
    return null;
  }
}

class AppPreferencesState {
  const AppPreferencesState({
    this.language = AppLanguage.english,
    this.theme = AppThemeChoice.sepia,
    this.companionAutoReciteEnabled = false,
    this.readerShowVerseTranslation = true,
    this.readerShowWordHelp = true,
    this.readerShowTransliteration = false,
    this.hasLoaded = false,
  });

  final AppLanguage language;
  final AppThemeChoice theme;
  final bool companionAutoReciteEnabled;
  final bool readerShowVerseTranslation;
  final bool readerShowWordHelp;
  final bool readerShowTransliteration;
  final bool hasLoaded;

  AppPreferencesState copyWith({
    AppLanguage? language,
    AppThemeChoice? theme,
    bool? companionAutoReciteEnabled,
    bool? readerShowVerseTranslation,
    bool? readerShowWordHelp,
    bool? readerShowTransliteration,
    bool? hasLoaded,
  }) {
    return AppPreferencesState(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      companionAutoReciteEnabled:
          companionAutoReciteEnabled ?? this.companionAutoReciteEnabled,
      readerShowVerseTranslation:
          readerShowVerseTranslation ?? this.readerShowVerseTranslation,
      readerShowWordHelp: readerShowWordHelp ?? this.readerShowWordHelp,
      readerShowTransliteration:
          readerShowTransliteration ?? this.readerShowTransliteration,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

final appPreferencesStoreProvider = Provider<AppPreferencesStore>((ref) {
  return SharedPrefsAppPreferencesStore();
});

final appPreferencesProvider =
    NotifierProvider<AppPreferencesNotifier, AppPreferencesState>(
  AppPreferencesNotifier.new,
);

class AppPreferencesNotifier extends Notifier<AppPreferencesState> {
  bool _didStartLoad = false;

  @override
  AppPreferencesState build() {
    if (!_didStartLoad) {
      _didStartLoad = true;
      unawaited(_restore());
    }
    return const AppPreferencesState();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (state.language == language) {
      return;
    }
    state = state.copyWith(language: language);
    await ref.read(appPreferencesStoreProvider).saveLanguageCode(language.code);
  }

  Future<void> setTheme(AppThemeChoice theme) async {
    if (state.theme == theme) {
      return;
    }
    state = state.copyWith(theme: theme);
    await ref.read(appPreferencesStoreProvider).saveThemeCode(theme.code);
  }

  Future<void> setCompanionAutoReciteEnabled(bool value) async {
    if (state.companionAutoReciteEnabled == value) {
      return;
    }
    state = state.copyWith(companionAutoReciteEnabled: value);
    await ref
        .read(appPreferencesStoreProvider)
        .saveCompanionAutoReciteEnabled(value);
  }

  Future<void> setReaderShowVerseTranslation(bool value) async {
    if (state.readerShowVerseTranslation == value) {
      return;
    }
    state = state.copyWith(readerShowVerseTranslation: value);
    await ref.read(appPreferencesStoreProvider).saveReaderShowVerseTranslation(
      value,
    );
  }

  Future<void> setReaderShowWordHelp(bool value) async {
    if (state.readerShowWordHelp == value) {
      return;
    }
    state = state.copyWith(readerShowWordHelp: value);
    await ref.read(appPreferencesStoreProvider).saveReaderShowWordHelp(value);
  }

  Future<void> setReaderShowTransliteration(bool value) async {
    if (state.readerShowTransliteration == value) {
      return;
    }
    state = state.copyWith(readerShowTransliteration: value);
    await ref
        .read(appPreferencesStoreProvider)
        .saveReaderShowTransliteration(value);
  }

  Future<void> _restore() async {
    final stored = await ref.read(appPreferencesStoreProvider).load();
    const defaults = AppPreferencesState();
    final language =
        AppLanguage.fromCode(stored.languageCode) ?? defaults.language;
    final theme = AppThemeChoice.fromCode(stored.themeCode) ?? defaults.theme;
    final companionAutoReciteEnabled = stored.companionAutoReciteEnabled ??
        defaults.companionAutoReciteEnabled;
    final readerShowVerseTranslation = stored.readerShowVerseTranslation ??
        defaults.readerShowVerseTranslation;
    final readerShowWordHelp =
        stored.readerShowWordHelp ?? defaults.readerShowWordHelp;
    final readerShowTransliteration = stored.readerShowTransliteration ??
        defaults.readerShowTransliteration;
    state = state.copyWith(
      language: language,
      theme: theme,
      companionAutoReciteEnabled: companionAutoReciteEnabled,
      readerShowVerseTranslation: readerShowVerseTranslation,
      readerShowWordHelp: readerShowWordHelp,
      readerShowTransliteration: readerShowTransliteration,
      hasLoaded: true,
    );
  }
}
