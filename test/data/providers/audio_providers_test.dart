import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/providers/audio_providers.dart';
import 'package:hifz_planner/data/services/ayah_audio_preferences.dart';
import 'package:hifz_planner/data/services/ayah_audio_service.dart';
import 'package:hifz_planner/data/services/ayah_audio_source.dart';
import 'package:hifz_planner/data/services/ayah_audio_stream_resolver.dart';
import 'package:hifz_planner/data/services/ayah_reciter_catalog_service.dart';

void main() {
  test('restores persisted reciter, speed, and repeat preferences', () async {
    final store = _FakeAudioPreferencesStore(
      stored: const StoredAyahAudioPreferences(
        edition: 'ar.hudhaify',
        bitrate: 64,
        speed: 1.25,
        repeatCount: 2,
        reciterDisplayName: 'Hudhaify',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        ayahAudioPreferencesStoreProvider.overrideWithValue(store),
        ayahReciterCatalogProvider.overrideWith(
          (ref) async => const <AyahReciterOption>[
            AyahReciterOption(
              edition: 'ar.hudhaify',
              englishName: 'Hudhaify',
              nativeName: 'الحذيفي',
              languageCode: 'ar',
              isFallback: false,
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    await _waitForPreferencesLoad(container);
    final prefs = container.read(ayahAudioPreferencesProvider);
    final selectedReciter = container.read(selectedReciterProvider);

    expect(prefs.hasLoaded, isTrue);
    expect(prefs.edition, 'ar.hudhaify');
    expect(prefs.bitrate, 64);
    expect(prefs.speed, 1.25);
    expect(prefs.repeatCount, 2);
    expect(selectedReciter.edition, 'ar.hudhaify');
    expect(selectedReciter.englishName, 'Hudhaify');
  });

  test('preference updates propagate to stream config and source URLs',
      () async {
    final store = _FakeAudioPreferencesStore();
    final container = ProviderContainer(
      overrides: [
        ayahAudioPreferencesStoreProvider.overrideWithValue(store),
        ayahReciterCatalogProvider.overrideWith(
          (ref) async => const <AyahReciterOption>[
            AyahReciterOption(
              edition: 'ar.abdurrahmaansudais',
              englishName: 'Abdurrahmaan As-Sudais',
              nativeName: 'عبدالرحمن السديس',
              languageCode: 'ar',
              isFallback: false,
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    await _waitForPreferencesLoad(container);
    final notifier = container.read(ayahAudioPreferencesProvider.notifier);
    await notifier.setReciter(
      const AyahReciterOption(
        edition: 'ar.abdurrahmaansudais',
        englishName: 'Abdurrahmaan As-Sudais',
        nativeName: 'عبدالرحمن السديس',
        languageCode: 'ar',
        isFallback: false,
      ),
    );
    await notifier.setSpeed(1.5);
    await notifier.setRepeatCount(3);

    final config = container.read(ayahAudioStreamConfigProvider);
    final source = container.read(ayahAudioSourceProvider);
    final url = source.urlForAyah(1, 1).toString();

    expect(config.edition, 'ar.abdurrahmaansudais');
    expect(config.bitrate, 128);
    expect(url, contains('/128/ar.abdurrahmaansudais/1.mp3'));
    expect(container.read(ayahAudioPreferencesProvider).speed, 1.5);
    expect(container.read(ayahAudioPreferencesProvider).repeatCount, 3);
    expect(store.savedEdition, 'ar.abdurrahmaansudais');
    expect(store.savedSpeed, 1.5);
    expect(store.savedRepeatCount, 3);
  });

  test('switchReciter stops audio and resolves fallback bitrate', () async {
    final fakeAudioService = _FakeAyahAudioService();
    final store = _FakeAudioPreferencesStore(
      stored: const StoredAyahAudioPreferences(
        edition: 'ar.alafasy',
        bitrate: 128,
        reciterDisplayName: 'Alafasy',
      ),
      stopCallCount: () => fakeAudioService.stopCalls,
    );
    final container = ProviderContainer(
      overrides: [
        ayahAudioPreferencesStoreProvider.overrideWithValue(store),
        ayahAudioServiceProvider.overrideWithValue(fakeAudioService),
        ayahAudioStreamResolverProvider.overrideWithValue(
          const _FakeAyahAudioStreamResolver(64),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _waitForPreferencesLoad(container);
    final coordinator = container.read(ayahReciterSwitchCoordinatorProvider);
    const reciter = AyahReciterOption(
      edition: 'ar.abdulsamad',
      englishName: 'Abdul Samad',
      nativeName: 'عبدالباسط عبدالصمد',
      languageCode: 'ar',
      isFallback: false,
    );

    final result = await coordinator.switchReciter(reciter);
    final prefs = container.read(ayahAudioPreferencesProvider);

    expect(fakeAudioService.stopCalls, 1);
    expect(result.status, ReciterSelectionStatus.applied);
    expect(result.resolvedBitrate, 64);
    expect(result.didChangeBitrate, isTrue);
    expect(prefs.edition, reciter.edition);
    expect(prefs.bitrate, 64);
    expect(store.savedEdition, reciter.edition);
    expect(store.savedBitrate, 64);
    expect(store.savedReciterName, reciter.englishName);
    expect(store.stopCallsWhenEditionSaved, 1);
  });

  test('switchReciter ignores concurrent second selection', () async {
    final fakeAudioService = _FakeAyahAudioService();
    final store = _FakeAudioPreferencesStore(
      stored: const StoredAyahAudioPreferences(
        edition: 'ar.alafasy',
        bitrate: 128,
        reciterDisplayName: 'Alafasy',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        ayahAudioPreferencesStoreProvider.overrideWithValue(store),
        ayahAudioServiceProvider.overrideWithValue(fakeAudioService),
        ayahAudioStreamResolverProvider.overrideWithValue(
          const _DelayedAyahAudioStreamResolver(
            resolvedBitrate: 64,
            delay: Duration(milliseconds: 120),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _waitForPreferencesLoad(container);
    final coordinator = container.read(ayahReciterSwitchCoordinatorProvider);
    const first = AyahReciterOption(
      edition: 'ar.abdulsamad',
      englishName: 'Abdul Samad',
      nativeName: 'عبدالباسط عبدالصمد',
      languageCode: 'ar',
      isFallback: false,
    );
    const second = AyahReciterOption(
      edition: 'ar.abdurrahmaansudais',
      englishName: 'Abdurrahmaan As-Sudais',
      nativeName: 'عبدالرحمن السديس',
      languageCode: 'ar',
      isFallback: false,
    );

    final firstFuture = coordinator.switchReciter(first);
    final secondResult = await coordinator.switchReciter(second);
    final firstResult = await firstFuture;
    final prefs = container.read(ayahAudioPreferencesProvider);

    expect(secondResult.status, ReciterSelectionStatus.failed);
    expect(secondResult.error, isA<StateError>());
    expect(firstResult.status, ReciterSelectionStatus.applied);
    expect(fakeAudioService.stopCalls, 1);
    expect(prefs.edition, first.edition);
  });

  test('applyReciterSelection keeps current reciter when unavailable',
      () async {
    final store = _FakeAudioPreferencesStore(
      stored: const StoredAyahAudioPreferences(
        edition: 'ar.alafasy',
        bitrate: 128,
        reciterDisplayName: 'Alafasy',
      ),
    );
    final fakeAudioService = _FakeAyahAudioService();
    final container = ProviderContainer(
      overrides: [
        ayahAudioPreferencesStoreProvider.overrideWithValue(store),
        ayahAudioServiceProvider.overrideWithValue(fakeAudioService),
        ayahAudioStreamResolverProvider.overrideWithValue(
          const _FakeAyahAudioStreamResolver(null),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _waitForPreferencesLoad(container);
    final before = container.read(ayahAudioPreferencesProvider);
    final result = await container
        .read(ayahAudioPreferencesProvider.notifier)
        .applyReciterSelection(
          const AyahReciterOption(
            edition: 'ar.unavailable',
            englishName: 'Unavailable',
            nativeName: 'Unavailable',
            languageCode: 'ar',
            isFallback: false,
          ),
        );
    final after = container.read(ayahAudioPreferencesProvider);

    expect(fakeAudioService.stopCalls, 0);
    expect(result.status, ReciterSelectionStatus.unavailable);
    expect(after.edition, before.edition);
    expect(after.reciterDisplayName, before.reciterDisplayName);
    expect(after.bitrate, before.bitrate);
    expect(store.savedEdition, isNull);
    expect(store.savedBitrate, isNull);
    expect(store.savedReciterName, isNull);
  });

  test('applyReciterSelection does not trigger provider circular dependency',
      () async {
    final store = _FakeAudioPreferencesStore(
      stored: const StoredAyahAudioPreferences(
        edition: 'ar.alafasy',
        bitrate: 128,
        reciterDisplayName: 'Alafasy',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        ayahAudioPreferencesStoreProvider.overrideWithValue(store),
        ayahAudioServiceProvider.overrideWith((ref) {
          // This would create preferences -> service -> preferences cycle
          // if applyReciterSelection reads the audio service provider.
          ref.read(ayahAudioPreferencesProvider);
          return _FakeAyahAudioService();
        }),
        ayahAudioStreamResolverProvider.overrideWithValue(
          const _FakeAyahAudioStreamResolver(64),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _waitForPreferencesLoad(container);
    final result = await container
        .read(ayahAudioPreferencesProvider.notifier)
        .applyReciterSelection(
          const AyahReciterOption(
            edition: 'ar.abdulsamad',
            englishName: 'Abdul Samad',
            nativeName: 'عبدالباسط عبدالصمد',
            languageCode: 'ar',
            isFallback: false,
          ),
        );

    expect(result.status, ReciterSelectionStatus.applied);
    expect(
        container.read(ayahAudioPreferencesProvider).edition, 'ar.abdulsamad');
  });
}

Future<void> _waitForPreferencesLoad(ProviderContainer container) async {
  for (var i = 0; i < 40; i++) {
    if (container.read(ayahAudioPreferencesProvider).hasLoaded) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for audio preferences to load.');
}

class _FakeAudioPreferencesStore implements AyahAudioPreferencesStore {
  _FakeAudioPreferencesStore({
    StoredAyahAudioPreferences? stored,
    this.stopCallCount,
  }) : _stored = stored ?? const StoredAyahAudioPreferences();

  final StoredAyahAudioPreferences _stored;
  final int Function()? stopCallCount;

  String? savedEdition;
  int? savedBitrate;
  double? savedSpeed;
  int? savedRepeatCount;
  String? savedReciterName;
  int? stopCallsWhenEditionSaved;

  @override
  Future<StoredAyahAudioPreferences> load() async => _stored;

  @override
  Future<void> saveBitrate(int bitrate) async {
    savedBitrate = bitrate;
  }

  @override
  Future<void> saveEdition(String edition) async {
    savedEdition = edition;
    stopCallsWhenEditionSaved = stopCallCount?.call();
  }

  @override
  Future<void> saveReciterDisplayName(String displayName) async {
    savedReciterName = displayName;
  }

  @override
  Future<void> saveRepeatCount(int repeatCount) async {
    savedRepeatCount = repeatCount;
  }

  @override
  Future<void> saveSpeed(double speed) async {
    savedSpeed = speed;
  }
}

class _FakeAyahAudioService implements AyahAudioService {
  int stopCalls = 0;

  @override
  AyahAudioState get currentState => const AyahAudioState.initial();

  @override
  Stream<String> get errorStream => const Stream<String>.empty();

  @override
  Stream<AyahAudioState> get stateStream =>
      const Stream<AyahAudioState>.empty();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> next() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> playAyah(int surah, int ayah) async {}

  @override
  Future<void> playFrom(int surah, int ayah) async {}

  @override
  Future<void> previous() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Future<void> setRepeatCount(int repeatCount) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }

  @override
  Future<void> updateSource(
    AyahAudioSource source, {
    bool stopPlayback = true,
  }) async {}
}

class _FakeAyahAudioStreamResolver implements AyahAudioStreamResolver {
  const _FakeAyahAudioStreamResolver(this._resolvedBitrate);

  final int? _resolvedBitrate;

  @override
  Future<int?> resolvePlayableBitrate({
    required String edition,
    required int preferredBitrate,
  }) async {
    return _resolvedBitrate;
  }
}

class _DelayedAyahAudioStreamResolver implements AyahAudioStreamResolver {
  const _DelayedAyahAudioStreamResolver({
    required this.resolvedBitrate,
    required this.delay,
  });

  final int? resolvedBitrate;
  final Duration delay;

  @override
  Future<int?> resolvePlayableBitrate({
    required String edition,
    required int preferredBitrate,
  }) async {
    await Future<void>.delayed(delay);
    return resolvedBitrate;
  }
}
