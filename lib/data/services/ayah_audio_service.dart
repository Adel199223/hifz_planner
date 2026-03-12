import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'ayah_audio_playback_resolver.dart';
import 'ayah_audio_source.dart';

class AyahRef {
  const AyahRef({
    required this.surah,
    required this.ayah,
  });

  final int surah;
  final int ayah;

  String get key => '$surah:$ayah';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AyahRef && other.surah == surah && other.ayah == ayah;
  }

  @override
  int get hashCode => Object.hash(surah, ayah);
}

class AyahAudioState {
  const AyahAudioState({
    required this.currentAyah,
    required this.isPlaying,
    required this.isBuffering,
    required this.speed,
    required this.repeatCount,
    required this.canNext,
    required this.canPrevious,
    required this.queueLength,
    required this.position,
    required this.bufferedPosition,
    required this.duration,
  });

  const AyahAudioState.initial()
      : currentAyah = null,
        isPlaying = false,
        isBuffering = false,
        speed = 1.0,
        repeatCount = 0,
        canNext = false,
        canPrevious = false,
        queueLength = 0,
        position = Duration.zero,
        bufferedPosition = Duration.zero,
        duration = null;

  final AyahRef? currentAyah;
  final bool isPlaying;
  final bool isBuffering;
  final double speed;
  final int repeatCount;
  final bool canNext;
  final bool canPrevious;
  final int queueLength;
  final Duration position;
  final Duration bufferedPosition;
  final Duration? duration;

  bool get hasActiveAyah => currentAyah != null;
}

abstract class AyahAudioService {
  Stream<AyahAudioState> get stateStream;
  Stream<String> get errorStream;
  AyahAudioState get currentState;

  Future<void> updateSource(AyahAudioSource source, {bool stopPlayback = true});
  Future<void> playAyah(int surah, int ayah);
  Future<void> playFrom(int surah, int ayah);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> next();
  Future<void> previous();
  Future<void> seekTo(Duration position);
  Future<void> setSpeed(double speed);
  Future<void> setRepeatCount(int repeatCount);
  Future<void> dispose();
}

class AyahAudioStreamConfig {
  const AyahAudioStreamConfig({
    this.edition = 'ar.alafasy',
    this.bitrate = 128,
  });

  final String edition;
  final int bitrate;
}

class AudioOperationQueue {
  Future<void> _tail = Future<void>.value();

  Future<void> run(Future<void> Function() operation) {
    final completer = Completer<void>();
    _tail = _tail.catchError((_) {}).then((_) async {
      try {
        await operation();
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}

class JustAudioAyahAudioService implements AyahAudioService {
  JustAudioAyahAudioService({
    required AudioPlayer audioPlayer,
    required AyahAudioSource source,
    required AyahAudioPlaybackResolver playbackResolver,
  })  : _audioPlayer = audioPlayer,
        _source = source,
        _playbackResolver = playbackResolver {
    _playerSubscriptions = <StreamSubscription<dynamic>>[
      _audioPlayer.currentIndexStream.listen((_) {
        _syncState();
      }),
      _audioPlayer.playerStateStream.listen((_) {
        _syncState();
      }),
      _audioPlayer.positionStream.listen((_) {
        _syncState();
      }),
      _audioPlayer.bufferedPositionStream.listen((_) {
        _syncState();
      }),
      _audioPlayer.durationStream.listen((_) {
        _syncState();
      }),
      _audioPlayer.playbackEventStream.listen(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {
          final message = error.toString();
          _emitError(message);
          final normalized = message.toLowerCase();
          if (normalized.contains('operation aborted') ||
              normalized.contains('bufferingprogress')) {
            _syncState();
            return;
          }
          unawaited(stop());
        },
      ),
    ];
    _syncState();
  }

  final AudioPlayer _audioPlayer;
  AyahAudioSource _source;
  final AyahAudioPlaybackResolver _playbackResolver;
  final StreamController<AyahAudioState> _stateController =
      StreamController<AyahAudioState>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  late final List<StreamSubscription<dynamic>> _playerSubscriptions;
  final AudioOperationQueue _operationQueue = AudioOperationQueue();

  AyahAudioState _state = const AyahAudioState.initial();
  List<AyahRef> _timeline = const <AyahRef>[];
  double _speed = 1.0;
  int _repeatCount = 0;
  bool _isDisposed = false;

  @override
  Stream<AyahAudioState> get stateStream async* {
    yield _state;
    yield* _stateController.stream;
  }

  @override
  Stream<String> get errorStream => _errorController.stream;

  @override
  AyahAudioState get currentState => _state;

  @override
  Future<void> updateSource(
    AyahAudioSource source, {
    bool stopPlayback = true,
  }) {
    return _runSerialized(() async {
      _source = source;
      if (stopPlayback) {
        await _stopInternal();
        return;
      }
      _syncState();
    });
  }

  @override
  Future<void> playAyah(int surah, int ayah) {
    return _runSerialized(() async {
      final ayahCount = ayahCountForSurah(surah);
      if (ayah < 1 || ayah > ayahCount) {
        throw RangeError.range(ayah, 1, ayahCount, 'ayah');
      }
      final timeline = _buildTimeline(
        <AyahRef>[
          AyahRef(surah: surah, ayah: ayah),
        ],
      );
      await _startTimelineInternal(timeline, autoPlay: true);
    });
  }

  @override
  Future<void> playFrom(int surah, int ayah) {
    return _runSerialized(() async {
      final ayahCount = ayahCountForSurah(surah);
      if (ayah < 1 || ayah > ayahCount) {
        throw RangeError.range(ayah, 1, ayahCount, 'ayah');
      }
      final queue = <AyahRef>[
        for (var currentAyah = ayah; currentAyah <= ayahCount; currentAyah++)
          AyahRef(surah: surah, ayah: currentAyah),
      ];
      await _startTimelineInternal(_buildTimeline(queue), autoPlay: true);
    });
  }

  @override
  Future<void> pause() {
    return _runSerialized(() async {
      await _audioPlayer.pause();
      _syncState();
    });
  }

  @override
  Future<void> resume() {
    return _runSerialized(() async {
      if (_timeline.isEmpty) {
        return;
      }
      await _audioPlayer.play();
      _syncState();
    });
  }

  @override
  Future<void> stop() {
    return _runSerialized(_stopInternal);
  }

  Future<void> _stopInternal() async {
    _timeline = const <AyahRef>[];
    try {
      await _audioPlayer.stop();
    } catch (error) {
      _emitError(error.toString());
      try {
        await _audioPlayer.pause();
      } catch (_) {
        // Ignore secondary stop/pause failures from platform plugin.
      }
    }
    _syncState();
  }

  @override
  Future<void> next() {
    return _runSerialized(() async {
      final currentIndex = _resolvedCurrentIndex();
      final targetIndex = _nextDistinctIndexFrom(currentIndex);
      if (targetIndex == null) {
        return;
      }
      await _seekToDistinctIndexInternal(targetIndex);
    });
  }

  @override
  Future<void> previous() {
    return _runSerialized(() async {
      final currentIndex = _resolvedCurrentIndex();
      final targetIndex = _previousDistinctIndexFrom(currentIndex);
      if (targetIndex == null) {
        return;
      }
      await _seekToDistinctIndexInternal(targetIndex);
    });
  }

  @override
  Future<void> seekTo(Duration position) {
    return _runSerialized(() async {
      if (_timeline.isEmpty) {
        return;
      }
      final totalDuration = _audioPlayer.duration;
      var safePosition = position;
      if (safePosition < Duration.zero) {
        safePosition = Duration.zero;
      }
      if (totalDuration != null && safePosition > totalDuration) {
        safePosition = totalDuration;
      }
      try {
        await _audioPlayer.seek(safePosition);
        _syncState();
      } catch (error) {
        _emitError(error.toString());
        await _stopInternal();
      }
    });
  }

  @override
  Future<void> setSpeed(double speed) {
    return _runSerialized(() async {
      if (speed <= 0) {
        throw RangeError.value(speed, 'speed', 'Speed must be > 0.');
      }
      _speed = speed;
      try {
        await _audioPlayer.setSpeed(speed);
      } catch (error) {
        _emitError(error.toString());
      }
      _syncState();
    });
  }

  @override
  Future<void> setRepeatCount(int repeatCount) {
    return _runSerialized(() async {
      if (repeatCount < 0 || repeatCount > 3) {
        throw RangeError.range(repeatCount, 0, 3, 'repeatCount');
      }
      if (_repeatCount == repeatCount) {
        return;
      }
      _repeatCount = repeatCount;

      if (_timeline.isEmpty) {
        _syncState();
        return;
      }

      final remainingQueue = _remainingDistinctQueueFromCurrent();
      if (remainingQueue.isEmpty) {
        _syncState();
        return;
      }
      final wasPlaying = _audioPlayer.playing;
      await _startTimelineInternal(
        _buildTimeline(remainingQueue),
        autoPlay: wasPlaying,
      );
    });
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    await _operationQueue.run(() async {
      for (final sub in _playerSubscriptions) {
        await sub.cancel();
      }
      try {
        await _audioPlayer.dispose();
      } catch (_) {
        // Best effort disposal; avoid bubbling plugin teardown failures.
      }
      await _stateController.close();
      await _errorController.close();
    });
  }

  List<AyahRef> _buildTimeline(List<AyahRef> queue) {
    if (queue.isEmpty) {
      return const <AyahRef>[];
    }
    final timeline = <AyahRef>[];
    for (var index = 0; index < queue.length; index++) {
      final ayah = queue[index];
      final copies = index == 0 ? _repeatCount + 1 : 1;
      for (var copy = 0; copy < copies; copy++) {
        timeline.add(ayah);
      }
    }
    return timeline;
  }

  Future<void> _startTimelineInternal(
    List<AyahRef> timeline, {
    required bool autoPlay,
  }) async {
    if (timeline.isEmpty) {
      await _stopInternal();
      return;
    }

    final resolvedUris = await Future.wait<Uri>([
      for (final ayah in timeline)
        _playbackResolver.resolveAyahUri(
          source: _source,
          surah: ayah.surah,
          ayah: ayah.ayah,
        ),
    ]);
    final sources = <AudioSource>[
      for (var index = 0; index < timeline.length; index++)
        AudioSource.uri(
          resolvedUris[index],
          tag: timeline[index],
        ),
    ];

    _timeline = List<AyahRef>.unmodifiable(timeline);
    try {
      await _audioPlayer.setAudioSources(
        sources,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );
      await _audioPlayer.setSpeed(_speed);
      if (autoPlay) {
        await _audioPlayer.play();
      }
      _syncState();
    } catch (error) {
      _emitError(error.toString());
      await _stopInternal();
    }
  }

  Future<void> _seekToDistinctIndexInternal(int index) async {
    final wasPlaying = _audioPlayer.playing;
    try {
      await _audioPlayer.seek(Duration.zero, index: index);
      if (wasPlaying) {
        await _audioPlayer.play();
      }
      _syncState();
    } catch (error) {
      _emitError(error.toString());
      await _stopInternal();
    }
  }

  List<AyahRef> _remainingDistinctQueueFromCurrent() {
    if (_timeline.isEmpty) {
      return const <AyahRef>[];
    }
    final currentIndex = _resolvedCurrentIndex();
    if (currentIndex < 0) {
      return const <AyahRef>[];
    }
    final distinct = <AyahRef>[];
    AyahRef? previous;
    for (var index = currentIndex; index < _timeline.length; index++) {
      final ayah = _timeline[index];
      if (previous != ayah) {
        distinct.add(ayah);
        previous = ayah;
      }
    }
    return distinct;
  }

  int _resolvedCurrentIndex() {
    if (_timeline.isEmpty) {
      return -1;
    }
    final currentIndex = _audioPlayer.currentIndex;
    if (currentIndex == null ||
        currentIndex < 0 ||
        currentIndex >= _timeline.length) {
      return 0;
    }
    return currentIndex;
  }

  AyahRef? _currentAyah() {
    final index = _resolvedCurrentIndex();
    if (index < 0 || index >= _timeline.length) {
      return null;
    }
    return _timeline[index];
  }

  int? _nextDistinctIndexFrom(int startIndex) {
    if (startIndex < 0 || startIndex >= _timeline.length) {
      return null;
    }
    final currentAyah = _timeline[startIndex];
    for (var index = startIndex + 1; index < _timeline.length; index++) {
      if (_timeline[index] != currentAyah) {
        return index;
      }
    }
    return null;
  }

  int? _previousDistinctIndexFrom(int startIndex) {
    if (startIndex < 0 || startIndex >= _timeline.length) {
      return null;
    }
    final currentAyah = _timeline[startIndex];
    for (var index = startIndex - 1; index >= 0; index--) {
      if (_timeline[index] != currentAyah) {
        return index;
      }
    }
    return null;
  }

  void _syncState() {
    final currentIndex = _resolvedCurrentIndex();
    final currentAyah = _currentAyah();
    final state = AyahAudioState(
      currentAyah: currentAyah,
      isPlaying: _audioPlayer.playing,
      isBuffering: _audioPlayer.processingState == ProcessingState.loading ||
          _audioPlayer.processingState == ProcessingState.buffering,
      speed: _speed,
      repeatCount: _repeatCount,
      canNext: _nextDistinctIndexFrom(currentIndex) != null,
      canPrevious: _previousDistinctIndexFrom(currentIndex) != null,
      queueLength: _timeline.length,
      position: _audioPlayer.position,
      bufferedPosition: _audioPlayer.bufferedPosition,
      duration: _audioPlayer.duration,
    );
    _state = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  void _emitError(String message) {
    if (_errorController.isClosed) {
      return;
    }
    _errorController.add(message);
  }

  Future<void> _runSerialized(Future<void> Function() operation) {
    if (_isDisposed) {
      return Future<void>.value();
    }
    return _operationQueue.run(() async {
      try {
        await operation();
      } catch (error) {
        _emitError(error.toString());
      }
    });
  }
}

class NoopAyahAudioService implements AyahAudioService {
  final StreamController<AyahAudioState> _stateController =
      StreamController<AyahAudioState>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  AyahAudioState _state = const AyahAudioState.initial();

  @override
  Stream<AyahAudioState> get stateStream async* {
    yield _state;
    yield* _stateController.stream;
  }

  @override
  Stream<String> get errorStream => _errorController.stream;

  @override
  AyahAudioState get currentState => _state;

  @override
  Future<void> updateSource(
    AyahAudioSource source, {
    bool stopPlayback = true,
  }) async {}

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
  Future<void> setRepeatCount(int repeatCount) async {
    _state = AyahAudioState(
      currentAyah: _state.currentAyah,
      isPlaying: _state.isPlaying,
      isBuffering: _state.isBuffering,
      speed: _state.speed,
      repeatCount: repeatCount,
      canNext: _state.canNext,
      canPrevious: _state.canPrevious,
      queueLength: _state.queueLength,
      position: _state.position,
      bufferedPosition: _state.bufferedPosition,
      duration: _state.duration,
    );
    _stateController.add(_state);
  }

  @override
  Future<void> setSpeed(double speed) async {
    _state = AyahAudioState(
      currentAyah: _state.currentAyah,
      isPlaying: _state.isPlaying,
      isBuffering: _state.isBuffering,
      speed: speed,
      repeatCount: _state.repeatCount,
      canNext: _state.canNext,
      canPrevious: _state.canPrevious,
      queueLength: _state.queueLength,
      position: _state.position,
      bufferedPosition: _state.bufferedPosition,
      duration: _state.duration,
    );
    _stateController.add(_state);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _errorController.close();
  }
}
