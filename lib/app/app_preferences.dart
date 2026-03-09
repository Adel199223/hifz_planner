import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_language.dart';
import 'app_preferences_store.dart';

const Object _readerLastLocationNoChange = Object();

enum AppThemeChoice {
  sepia(code: 'sepia'),
  dark(code: 'dark');

  const AppThemeChoice({required this.code});

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

enum ReaderLastLocationMode {
  verse(code: 'verse'),
  page(code: 'page');

  const ReaderLastLocationMode({required this.code});

  final String code;

  static ReaderLastLocationMode? fromCode(String? code) {
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

class ReaderLastLocation {
  const ReaderLastLocation({
    required this.mode,
    this.page,
    this.targetSurah,
    this.targetAyah,
  });

  final ReaderLastLocationMode mode;
  final int? page;
  final int? targetSurah;
  final int? targetAyah;

  bool sameAs({
    required ReaderLastLocationMode mode,
    int? page,
    int? targetSurah,
    int? targetAyah,
  }) {
    return this.mode == mode &&
        this.page == page &&
        this.targetSurah == targetSurah &&
        this.targetAyah == targetAyah;
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
    this.readerLastLocation,
    this.hasLoaded = false,
  });

  final AppLanguage language;
  final AppThemeChoice theme;
  final bool companionAutoReciteEnabled;
  final bool readerShowVerseTranslation;
  final bool readerShowWordHelp;
  final bool readerShowTransliteration;
  final ReaderLastLocation? readerLastLocation;
  final bool hasLoaded;

  AppPreferencesState copyWith({
    AppLanguage? language,
    AppThemeChoice? theme,
    bool? companionAutoReciteEnabled,
    bool? readerShowVerseTranslation,
    bool? readerShowWordHelp,
    bool? readerShowTransliteration,
    Object? readerLastLocation = _readerLastLocationNoChange,
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
      readerLastLocation:
          identical(readerLastLocation, _readerLastLocationNoChange)
          ? this.readerLastLocation
          : readerLastLocation as ReaderLastLocation?,
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
    await ref
        .read(appPreferencesStoreProvider)
        .saveReaderShowVerseTranslation(value);
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

  Future<void> setReaderLastLocation({
    required ReaderLastLocationMode mode,
    int? page,
    int? targetSurah,
    int? targetAyah,
  }) async {
    final normalizedPage = page != null && page > 0 ? page : null;
    final normalizedSurah = targetSurah != null && targetSurah > 0
        ? targetSurah
        : null;
    final normalizedAyah = targetAyah != null && targetAyah > 0
        ? targetAyah
        : null;
    final currentLocation = state.readerLastLocation;
    if (currentLocation != null &&
        currentLocation.sameAs(
          mode: mode,
          page: normalizedPage,
          targetSurah: normalizedSurah,
          targetAyah: normalizedAyah,
        )) {
      return;
    }
    final nextLocation = ReaderLastLocation(
      mode: mode,
      page: normalizedPage,
      targetSurah: normalizedSurah,
      targetAyah: normalizedAyah,
    );
    state = state.copyWith(readerLastLocation: nextLocation);
    await ref
        .read(appPreferencesStoreProvider)
        .saveLastReaderLocation(
          mode: mode.code,
          page: normalizedPage,
          surah: normalizedSurah,
          ayah: normalizedAyah,
        );
  }

  Future<void> clearReaderLastLocation() async {
    if (state.readerLastLocation == null) {
      return;
    }
    state = state.copyWith(readerLastLocation: null);
    await ref.read(appPreferencesStoreProvider).clearLastReaderLocation();
  }

  Future<void> _restore() async {
    final stored = await ref.read(appPreferencesStoreProvider).load();
    const defaults = AppPreferencesState();
    final language =
        AppLanguage.fromCode(stored.languageCode) ?? defaults.language;
    final theme = AppThemeChoice.fromCode(stored.themeCode) ?? defaults.theme;
    final companionAutoReciteEnabled =
        stored.companionAutoReciteEnabled ??
        defaults.companionAutoReciteEnabled;
    final readerShowVerseTranslation =
        stored.readerShowVerseTranslation ??
        defaults.readerShowVerseTranslation;
    final readerShowWordHelp =
        stored.readerShowWordHelp ?? defaults.readerShowWordHelp;
    final readerShowTransliteration =
        stored.readerShowTransliteration ?? defaults.readerShowTransliteration;
    final readerLastLocation = _restoreReaderLastLocation(stored);
    state = state.copyWith(
      language: language,
      theme: theme,
      companionAutoReciteEnabled: companionAutoReciteEnabled,
      readerShowVerseTranslation: readerShowVerseTranslation,
      readerShowWordHelp: readerShowWordHelp,
      readerShowTransliteration: readerShowTransliteration,
      readerLastLocation: readerLastLocation,
      hasLoaded: true,
    );
  }

  ReaderLastLocation? _restoreReaderLastLocation(StoredAppPreferences stored) {
    final mode = ReaderLastLocationMode.fromCode(stored.lastReaderMode);
    if (mode == null) {
      return null;
    }
    final page = stored.lastReaderPage != null && stored.lastReaderPage! > 0
        ? stored.lastReaderPage
        : null;
    final targetSurah =
        stored.lastReaderSurah != null && stored.lastReaderSurah! > 0
        ? stored.lastReaderSurah
        : null;
    final targetAyah =
        stored.lastReaderAyah != null && stored.lastReaderAyah! > 0
        ? stored.lastReaderAyah
        : null;

    switch (mode) {
      case ReaderLastLocationMode.page:
        if (page == null) {
          return null;
        }
        return ReaderLastLocation(
          mode: mode,
          page: page,
          targetSurah: targetSurah,
          targetAyah: targetAyah,
        );
      case ReaderLastLocationMode.verse:
        if (targetSurah == null || targetAyah == null) {
          return null;
        }
        return ReaderLastLocation(
          mode: mode,
          targetSurah: targetSurah,
          targetAyah: targetAyah,
        );
    }
  }
}
