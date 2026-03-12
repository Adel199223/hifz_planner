import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/app/reader_display_preferences.dart';
import 'package:hifz_planner/app/reader_display_preferences_store.dart';

void main() {
  test('restores reader display preferences from store', () async {
    final store = _FakeReaderDisplayPreferencesStore(
      initial: const StoredReaderDisplayPreferences(
        showVerseTranslations: false,
        showWordTooltips: false,
        showWordHoverHighlights: true,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        readerDisplayPreferencesStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);

    container.read(readerDisplayPreferencesProvider);
    await _flush();
    await _flush();

    final state = container.read(readerDisplayPreferencesProvider);
    expect(state.hasLoaded, isTrue);
    expect(state.showVerseTranslations, isFalse);
    expect(state.showWordTooltips, isFalse);
    expect(state.showWordHoverHighlights, isTrue);
  });

  test('writes reader display preference changes and reset to store', () async {
    final store = _FakeReaderDisplayPreferencesStore();
    final container = ProviderContainer(
      overrides: [
        readerDisplayPreferencesStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);

    container.read(readerDisplayPreferencesProvider);
    await _flush();

    final notifier = container.read(readerDisplayPreferencesProvider.notifier);
    await notifier.setShowVerseTranslations(false);
    await notifier.setShowWordTooltips(false);
    await notifier.setShowWordHoverHighlights(false);

    var state = container.read(readerDisplayPreferencesProvider);
    expect(state.showVerseTranslations, isFalse);
    expect(state.showWordTooltips, isFalse);
    expect(state.showWordHoverHighlights, isFalse);
    expect(store.savedShowVerseTranslations, isFalse);
    expect(store.savedShowWordTooltips, isFalse);
    expect(store.savedShowWordHoverHighlights, isFalse);

    await notifier.reset();

    state = container.read(readerDisplayPreferencesProvider);
    expect(state.showVerseTranslations, isTrue);
    expect(state.showWordTooltips, isTrue);
    expect(state.showWordHoverHighlights, isTrue);
    expect(store.savedShowVerseTranslations, isTrue);
    expect(store.savedShowWordTooltips, isTrue);
    expect(store.savedShowWordHoverHighlights, isTrue);
  });
}

Future<void> _flush() {
  return Future<void>.delayed(Duration.zero);
}

class _FakeReaderDisplayPreferencesStore
    implements ReaderDisplayPreferencesStore {
  _FakeReaderDisplayPreferencesStore({
    StoredReaderDisplayPreferences? initial,
  }) : _stored = initial ?? const StoredReaderDisplayPreferences();

  StoredReaderDisplayPreferences _stored;
  bool? savedShowVerseTranslations;
  bool? savedShowWordTooltips;
  bool? savedShowWordHoverHighlights;

  @override
  Future<StoredReaderDisplayPreferences> load() async {
    return _stored;
  }

  @override
  Future<void> saveShowVerseTranslations(bool value) async {
    savedShowVerseTranslations = value;
    _stored = StoredReaderDisplayPreferences(
      showVerseTranslations: value,
      showWordTooltips: _stored.showWordTooltips,
      showWordHoverHighlights: _stored.showWordHoverHighlights,
    );
  }

  @override
  Future<void> saveShowWordHoverHighlights(bool value) async {
    savedShowWordHoverHighlights = value;
    _stored = StoredReaderDisplayPreferences(
      showVerseTranslations: _stored.showVerseTranslations,
      showWordTooltips: _stored.showWordTooltips,
      showWordHoverHighlights: value,
    );
  }

  @override
  Future<void> saveShowWordTooltips(bool value) async {
    savedShowWordTooltips = value;
    _stored = StoredReaderDisplayPreferences(
      showVerseTranslations: _stored.showVerseTranslations,
      showWordTooltips: value,
      showWordHoverHighlights: _stored.showWordHoverHighlights,
    );
  }
}
