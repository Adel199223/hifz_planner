import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reader_display_preferences_store.dart';

class ReaderDisplayPreferencesState {
  const ReaderDisplayPreferencesState({
    this.showVerseTranslations = true,
    this.showWordTooltips = true,
    this.showWordHoverHighlights = true,
    this.hasLoaded = false,
  });

  final bool showVerseTranslations;
  final bool showWordTooltips;
  final bool showWordHoverHighlights;
  final bool hasLoaded;

  ReaderDisplayPreferencesState copyWith({
    bool? showVerseTranslations,
    bool? showWordTooltips,
    bool? showWordHoverHighlights,
    bool? hasLoaded,
  }) {
    return ReaderDisplayPreferencesState(
      showVerseTranslations:
          showVerseTranslations ?? this.showVerseTranslations,
      showWordTooltips: showWordTooltips ?? this.showWordTooltips,
      showWordHoverHighlights:
          showWordHoverHighlights ?? this.showWordHoverHighlights,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

final readerDisplayPreferencesStoreProvider =
    Provider<ReaderDisplayPreferencesStore>((ref) {
  return const SharedPrefsReaderDisplayPreferencesStore();
});

final readerDisplayPreferencesProvider = NotifierProvider<
    ReaderDisplayPreferencesNotifier, ReaderDisplayPreferencesState>(
  ReaderDisplayPreferencesNotifier.new,
);

class ReaderDisplayPreferencesNotifier
    extends Notifier<ReaderDisplayPreferencesState> {
  bool _didStartLoad = false;

  @override
  ReaderDisplayPreferencesState build() {
    if (!_didStartLoad) {
      _didStartLoad = true;
      unawaited(_restore());
    }
    return const ReaderDisplayPreferencesState();
  }

  Future<void> setShowVerseTranslations(bool value) async {
    if (state.showVerseTranslations == value) {
      return;
    }
    state = state.copyWith(showVerseTranslations: value);
    await ref
        .read(readerDisplayPreferencesStoreProvider)
        .saveShowVerseTranslations(value);
  }

  Future<void> setShowWordTooltips(bool value) async {
    if (state.showWordTooltips == value) {
      return;
    }
    state = state.copyWith(showWordTooltips: value);
    await ref.read(readerDisplayPreferencesStoreProvider).saveShowWordTooltips(
          value,
        );
  }

  Future<void> setShowWordHoverHighlights(bool value) async {
    if (state.showWordHoverHighlights == value) {
      return;
    }
    state = state.copyWith(showWordHoverHighlights: value);
    await ref
        .read(readerDisplayPreferencesStoreProvider)
        .saveShowWordHoverHighlights(value);
  }

  Future<void> reset() async {
    state = const ReaderDisplayPreferencesState(
      hasLoaded: true,
    );
    final store = ref.read(readerDisplayPreferencesStoreProvider);
    await store.saveShowVerseTranslations(true);
    await store.saveShowWordTooltips(true);
    await store.saveShowWordHoverHighlights(true);
  }

  Future<void> _restore() async {
    final stored = await ref.read(readerDisplayPreferencesStoreProvider).load();
    const defaults = ReaderDisplayPreferencesState();
    state = state.copyWith(
      showVerseTranslations:
          stored.showVerseTranslations ?? defaults.showVerseTranslations,
      showWordTooltips: stored.showWordTooltips ?? defaults.showWordTooltips,
      showWordHoverHighlights:
          stored.showWordHoverHighlights ?? defaults.showWordHoverHighlights,
      hasLoaded: true,
    );
  }
}
