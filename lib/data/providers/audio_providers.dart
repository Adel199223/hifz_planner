import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import '../services/ayah_audio_download_service.dart';
import '../services/ayah_audio_preferences.dart';
import '../services/ayah_audio_playback_resolver.dart';
import '../services/ayah_audio_service.dart';
import '../services/ayah_audio_source.dart';
import '../services/ayah_reciter_catalog_service.dart';
import '../services/ayah_audio_stream_resolver.dart';

enum ReciterSelectionStatus {
  applied,
  unavailable,
  failed,
}

class ReciterSelectionResult {
  const ReciterSelectionResult._({
    required this.status,
    this.resolvedBitrate,
    this.previousBitrate,
    this.error,
  });

  const ReciterSelectionResult.applied({
    required int resolvedBitrate,
    required int previousBitrate,
  }) : this._(
          status: ReciterSelectionStatus.applied,
          resolvedBitrate: resolvedBitrate,
          previousBitrate: previousBitrate,
        );

  const ReciterSelectionResult.unavailable({
    required int previousBitrate,
  }) : this._(
          status: ReciterSelectionStatus.unavailable,
          previousBitrate: previousBitrate,
        );

  const ReciterSelectionResult.failed({
    required Object error,
    required int previousBitrate,
  }) : this._(
          status: ReciterSelectionStatus.failed,
          previousBitrate: previousBitrate,
          error: error,
        );

  final ReciterSelectionStatus status;
  final int? resolvedBitrate;
  final int? previousBitrate;
  final Object? error;

  bool get didChangeBitrate =>
      status == ReciterSelectionStatus.applied &&
      resolvedBitrate != null &&
      previousBitrate != null &&
      resolvedBitrate != previousBitrate;
}

final ayahAudioPreferencesStoreProvider = Provider<AyahAudioPreferencesStore>(
  (ref) => const SharedPrefsAyahAudioPreferencesStore(),
);

final ayahAudioPreferencesProvider =
    NotifierProvider<AyahAudioPreferencesNotifier, AyahAudioPreferencesState>(
  AyahAudioPreferencesNotifier.new,
);

class AyahAudioPreferencesNotifier extends Notifier<AyahAudioPreferencesState> {
  bool _didStartLoad = false;

  @override
  AyahAudioPreferencesState build() {
    if (!_didStartLoad) {
      _didStartLoad = true;
      unawaited(_restore());
    }
    return const AyahAudioPreferencesState();
  }

  Future<void> setReciter(AyahReciterOption option) async {
    if (option.edition == state.edition &&
        option.englishName == state.reciterDisplayName) {
      return;
    }
    state = state.copyWith(
      edition: option.edition,
      reciterDisplayName: option.englishName,
    );
    final store = ref.read(ayahAudioPreferencesStoreProvider);
    await store.saveEdition(option.edition);
    await store.saveReciterDisplayName(option.englishName);
  }

  Future<ReciterSelectionResult> applyReciterSelection(
    AyahReciterOption option,
  ) async {
    final previous = state;
    final previousBitrate = previous.bitrate > 0
        ? previous.bitrate
        : const AyahAudioPreferencesState().bitrate;

    try {
      final resolver = ref.read(ayahAudioStreamResolverProvider);
      final resolvedBitrate = await resolver.resolvePlayableBitrate(
        edition: option.edition,
        preferredBitrate: previousBitrate,
      );

      if (resolvedBitrate == null) {
        return ReciterSelectionResult.unavailable(
          previousBitrate: previousBitrate,
        );
      }

      state = state.copyWith(
        edition: option.edition,
        reciterDisplayName: option.englishName,
        bitrate: resolvedBitrate,
      );

      final store = ref.read(ayahAudioPreferencesStoreProvider);
      await store.saveEdition(option.edition);
      await store.saveReciterDisplayName(option.englishName);
      await store.saveBitrate(resolvedBitrate);

      return ReciterSelectionResult.applied(
        resolvedBitrate: resolvedBitrate,
        previousBitrate: previousBitrate,
      );
    } catch (error) {
      return ReciterSelectionResult.failed(
        error: error,
        previousBitrate: previousBitrate,
      );
    }
  }

  Future<void> setBitrate(int bitrate) async {
    if (bitrate <= 0 || state.bitrate == bitrate) {
      return;
    }
    state = state.copyWith(bitrate: bitrate);
    await ref.read(ayahAudioPreferencesStoreProvider).saveBitrate(bitrate);
  }

  Future<void> setSpeed(double speed) async {
    if (speed <= 0 || state.speed == speed) {
      return;
    }
    state = state.copyWith(speed: speed);
    await ref.read(ayahAudioPreferencesStoreProvider).saveSpeed(speed);
  }

  Future<void> setRepeatCount(int repeatCount) async {
    if (repeatCount < 0 ||
        repeatCount > 3 ||
        state.repeatCount == repeatCount) {
      return;
    }
    state = state.copyWith(repeatCount: repeatCount);
    await ref
        .read(ayahAudioPreferencesStoreProvider)
        .saveRepeatCount(repeatCount);
  }

  Future<void> _restore() async {
    final stored = await ref.read(ayahAudioPreferencesStoreProvider).load();
    final defaults = const AyahAudioPreferencesState();
    final restored = defaults.copyWith(
      edition: (stored.edition ?? '').trim().isEmpty
          ? defaults.edition
          : stored.edition!.trim(),
      bitrate: stored.bitrate != null && stored.bitrate! > 0
          ? stored.bitrate
          : defaults.bitrate,
      speed: stored.speed != null && stored.speed! > 0
          ? stored.speed
          : defaults.speed,
      repeatCount: stored.repeatCount != null &&
              stored.repeatCount! >= 0 &&
              stored.repeatCount! <= 3
          ? stored.repeatCount
          : defaults.repeatCount,
      reciterDisplayName: (stored.reciterDisplayName ?? '').trim().isEmpty
          ? defaults.reciterDisplayName
          : stored.reciterDisplayName!.trim(),
      hasLoaded: true,
    );
    state = restored;
  }
}

class AyahReciterSwitchCoordinator {
  const AyahReciterSwitchCoordinator(this._ref);

  final Ref _ref;

  Future<ReciterSelectionResult> switchReciter(AyahReciterOption option) async {
    final inProgressNotifier =
        _ref.read(ayahReciterSwitchInProgressProvider.notifier);
    if (_ref.read(ayahReciterSwitchInProgressProvider)) {
      return ReciterSelectionResult.failed(
        error: StateError('Reciter switch already in progress.'),
        previousBitrate: _resolvedPreviousBitrate(),
      );
    }
    inProgressNotifier.setInProgress(true);

    final currentPrefs = _ref.read(ayahAudioPreferencesProvider);
    final previousBitrate = currentPrefs.bitrate > 0
        ? currentPrefs.bitrate
        : const AyahAudioPreferencesState().bitrate;

    try {
      await _ref.read(ayahAudioServiceProvider).stop();
      return await _ref
          .read(ayahAudioPreferencesProvider.notifier)
          .applyReciterSelection(option);
    } catch (error) {
      return ReciterSelectionResult.failed(
        error: error,
        previousBitrate: previousBitrate,
      );
    } finally {
      try {
        inProgressNotifier.setInProgress(false);
      } catch (_) {
        // Provider can be disposed when leaving the reader; ignore safely.
      }
    }
  }

  int _resolvedPreviousBitrate() {
    final prefs = _ref.read(ayahAudioPreferencesProvider);
    if (prefs.bitrate > 0) {
      return prefs.bitrate;
    }
    return const AyahAudioPreferencesState().bitrate;
  }
}

final ayahReciterCatalogServiceProvider = Provider<AyahReciterCatalogService>(
  (ref) {
    final client = http.Client();
    ref.onDispose(client.close);
    return AlQuranCloudAyahReciterCatalogService(client: client);
  },
);

final ayahAudioStreamResolverProvider = Provider<AyahAudioStreamResolver>(
  (ref) {
    final client = http.Client();
    ref.onDispose(client.close);
    return AlQuranCloudAyahAudioStreamResolver(client: client);
  },
);

final ayahAudioDownloadServiceProvider = Provider<AyahAudioDownloadService>(
  (ref) {
    final client = http.Client();
    ref.onDispose(client.close);
    return SupportDirAyahAudioDownloadService(client: client);
  },
);

final ayahAudioPlaybackResolverProvider = Provider<AyahAudioPlaybackResolver>(
  (ref) {
    final downloadService = ref.watch(ayahAudioDownloadServiceProvider);
    return CachedAyahAudioPlaybackResolver(downloadService);
  },
);

final ayahReciterCatalogProvider = FutureProvider<List<AyahReciterOption>>((
  ref,
) async {
  return ref.read(ayahReciterCatalogServiceProvider).loadReciters();
});

final ayahReciterSwitchCoordinatorProvider =
    Provider<AyahReciterSwitchCoordinator>(
  (ref) => AyahReciterSwitchCoordinator(ref),
);

final ayahReciterSwitchInProgressProvider =
    NotifierProvider<AyahReciterSwitchInProgressNotifier, bool>(
  AyahReciterSwitchInProgressNotifier.new,
);

class AyahReciterSwitchInProgressNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setInProgress(bool value) {
    state = value;
  }
}

final selectedReciterProvider = Provider<AyahReciterOption>((ref) {
  final prefs = ref.watch(ayahAudioPreferencesProvider);
  final reciters = ref.watch(ayahReciterCatalogProvider).maybeWhen(
        data: (value) => value,
        orElse: () => const <AyahReciterOption>[],
      );
  for (final option in reciters) {
    if (option.edition == prefs.edition) {
      return option;
    }
  }
  return AyahReciterOption(
    edition: prefs.edition,
    englishName: prefs.reciterDisplayName,
    nativeName: prefs.reciterDisplayName,
    languageCode: 'ar',
    isFallback: true,
  );
});

final ayahAudioStreamConfigProvider = Provider<AyahAudioStreamConfig>((ref) {
  final prefs = ref.watch(ayahAudioPreferencesProvider);
  return AyahAudioStreamConfig(
    edition: prefs.edition,
    bitrate: prefs.bitrate,
  );
});

final ayahAudioSourceProvider = Provider<AyahAudioSource>((ref) {
  final config = ref.watch(ayahAudioStreamConfigProvider);
  return AlQuranCloudAyahAudioSource(
    edition: config.edition,
    bitrate: config.bitrate,
  );
});

AyahAudioService createStreamingAyahAudioService(Ref ref) {
  final source = ref.read(ayahAudioSourceProvider);
  final playbackResolver = ref.read(ayahAudioPlaybackResolverProvider);
  final service = JustAudioAyahAudioService(
    audioPlayer: AudioPlayer(),
    source: source,
    playbackResolver: playbackResolver,
  );
  final initialPrefs = ref.read(ayahAudioPreferencesProvider);
  unawaited(_syncServiceSettingsFromPrefs(service, initialPrefs));

  ref.listen<AyahAudioPreferencesState>(ayahAudioPreferencesProvider,
      (previous, next) {
    if (previous == null || previous.speed != next.speed) {
      unawaited(service.setSpeed(next.speed));
    }
    if (previous == null || previous.repeatCount != next.repeatCount) {
      unawaited(service.setRepeatCount(next.repeatCount));
    }
  });

  ref.listen<AyahAudioStreamConfig>(ayahAudioStreamConfigProvider,
      (previous, next) {
    if (previous == null ||
        previous.edition != next.edition ||
        previous.bitrate != next.bitrate) {
      unawaited(
        service.updateSource(
          AlQuranCloudAyahAudioSource(
            edition: next.edition,
            bitrate: next.bitrate,
          ),
          stopPlayback: false,
        ),
      );
    }
  });

  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
}

Future<void> _syncServiceSettingsFromPrefs(
  AyahAudioService service,
  AyahAudioPreferencesState state,
) async {
  try {
    await service.setSpeed(state.speed);
    await service.setRepeatCount(state.repeatCount);
  } catch (_) {
    // Keep runtime stable if plugin initialization is not available yet.
  }
}

final ayahAudioServiceProvider = Provider.autoDispose<AyahAudioService>((ref) {
  final service = NoopAyahAudioService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

final ayahAudioStateProvider =
    StreamProvider.autoDispose<AyahAudioState>((ref) {
  final service = ref.watch(ayahAudioServiceProvider);
  return service.stateStream;
});

final ayahAudioErrorProvider = StreamProvider.autoDispose<String>((ref) {
  final service = ref.watch(ayahAudioServiceProvider);
  return service.errorStream;
});
