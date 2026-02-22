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
    this.hasLoaded = false,
  });

  final AppLanguage language;
  final AppThemeChoice theme;
  final bool hasLoaded;

  AppPreferencesState copyWith({
    AppLanguage? language,
    AppThemeChoice? theme,
    bool? hasLoaded,
  }) {
    return AppPreferencesState(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

final appPreferencesStoreProvider = Provider<AppPreferencesStore>((ref) {
  return const SharedPrefsAppPreferencesStore();
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

  Future<void> _restore() async {
    final stored = await ref.read(appPreferencesStoreProvider).load();
    final language = AppLanguage.fromCode(stored.languageCode) ??
        const AppPreferencesState().language;
    final theme = AppThemeChoice.fromCode(stored.themeCode) ??
        const AppPreferencesState().theme;
    state = state.copyWith(
      language: language,
      theme: theme,
      hasLoaded: true,
    );
  }
}
