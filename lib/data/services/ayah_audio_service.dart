import 'dart:async';

import 'package:just_audio/just_audio.dart';

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
    required this.speed,
    required this.repeatCount,
    required this.canNext,
    required this.canPrevious,
    required this.queueLength,
  });

  const AyahAudioState.initial()
      : currentAyah = null,
        isPlaying = false,
        speed = 1.0,
        repeatCount = 0,
        canNext = false,
        canPrevious = false,
        queueLength = 0;

  final AyahRef? currentAyah;
  final bool isPlaying;
  final double speed;
  final int repeatCount;
  final bool canNext;
  final bool canPrevious;
  final int queueLength;

  bool get hasActiveAyah => currentAyah != null;
}

abstract class AyahAudioService {
  Stream<AyahAudioState> get stateStream;
  Stream<String> get errorStream;
  AyahAudioState get currentState;

  Future<void> playAyah(int surah, int ayah);
  Future<void> playFrom(int surah, int ayah);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> next();
  Future<void> previous();
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

class JustAudioAyahAudioService implements AyahAudioService {
  JustAudioAyahAudioService({
    required AudioPlayer audioPlayer,
    required AyahAudioSource source,
  })  : _audioPlayer = audioPlayer,
        _source = source {
    _playerSubscriptions = <StreamSubscription<dynamic>>[
      _audioPlayer.currentIndexStream.listen((_) {
        _syncState();
      }),
      _audioPlayer.playerStateStream.listen((_) {
        _syncState();
      }),
      _audioPlayer.playbackEventStream.listen(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {
          _emitError(error.toString());
          unawaited(stop());
        },
      ),
    ];
    _syncState();
  }

  final AudioPlayer _audioPlayer;
  final AyahAudioSource _source;
  final StreamController<AyahAudioState> _stateController =
      StreamController<AyahAudioState>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  late final List<StreamSubscription<dynamic>> _playerSubscriptions;

  AyahAudioState _state = const AyahAudioState.initial();
  List<AyahRef> _timeline = const <AyahRef>[];
  double _speed = 1.0;
  int _repeatCount = 0;

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
  Future<void> playAyah(int surah, int ayah) async {
    final ayahCount = ayahCountForSurah(surah);
    if (ayah < 1 || ayah > ayahCount) {
      throw RangeError.range(ayah, 1, ayahCount, 'ayah');
    }
    final timeline = _buildTimeline(
      <AyahRef>[
        AyahRef(surah: surah, ayah: ayah),
      ],
    );
    await _startTimeline(timeline, autoPlay: true);
  }

  @override
  Future<void> playFrom(int surah, int ayah) async {
    final ayahCount = ayahCountForSurah(surah);
    if (ayah < 1 || ayah > ayahCount) {
      throw RangeError.range(ayah, 1, ayahCount, 'ayah');
    }
    final queue = <AyahRef>[
      for (var currentAyah = ayah; currentAyah <= ayahCount; currentAyah++)
        AyahRef(surah: surah, ayah: currentAyah),
    ];
    await _startTimeline(_buildTimeline(queue), autoPlay: true);
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
    _syncState();
  }

  @override
  Future<void> resume() async {
    if (_timeline.isEmpty) {
      return;
    }
    await _audioPlayer.play();
    _syncState();
  }

  @override
  Future<void> stop() async {
    _timeline = const <AyahRef>[];
    await _audioPlayer.stop();
    _syncState();
  }

  @override
  Future<void> next() async {
    final currentIndex = _resolvedCurrentIndex();
    final targetIndex = _nextDistinctIndexFrom(currentIndex);
    if (targetIndex == null) {
      return;
    }
    await _seekToDistinctIndex(targetIndex);
  }

  @override
  Future<void> previous() async {
    final currentIndex = _resolvedCurrentIndex();
    final targetIndex = _previousDistinctIndexFrom(currentIndex);
    if (targetIndex == null) {
      return;
    }
    await _seekToDistinctIndex(targetIndex);
  }

  @override
  Future<void> setSpeed(double speed) async {
    if (speed <= 0) {
      throw RangeError.value(speed, 'speed', 'Speed must be > 0.');
    }
    _speed = speed;
    await _audioPlayer.setSpeed(speed);
    _syncState();
  }

  @override
  Future<void> setRepeatCount(int repeatCount) async {
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
    await _startTimeline(_buildTimeline(remainingQueue), autoPlay: wasPlaying);
  }

  @override
  Future<void> dispose() async {
    for (final sub in _playerSubscriptions) {
      await sub.cancel();
    }
    await _audioPlayer.dispose();
    await _stateController.close();
    await _errorController.close();
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

  Future<void> _startTimeline(
    List<AyahRef> timeline, {
    required bool autoPlay,
  }) async {
    if (timeline.isEmpty) {
      await stop();
      return;
    }

    final sources = <AudioSource>[
      for (final ayah in timeline)
        AudioSource.uri(
          _source.urlForAyah(ayah.surah, ayah.ayah),
          tag: ayah,
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
      await stop();
    }
  }

  Future<void> _seekToDistinctIndex(int index) async {
    final wasPlaying = _audioPlayer.playing;
    try {
      await _audioPlayer.seek(Duration.zero, index: index);
      if (wasPlaying) {
        await _audioPlayer.play();
      }
      _syncState();
    } catch (error) {
      _emitError(error.toString());
      await stop();
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
      speed: _speed,
      repeatCount: _repeatCount,
      canNext: _nextDistinctIndexFrom(currentIndex) != null,
      canPrevious: _previousDistinctIndexFrom(currentIndex) != null,
      queueLength: _timeline.length,
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
  Future<void> setRepeatCount(int repeatCount) async {
    _state = AyahAudioState(
      currentAyah: _state.currentAyah,
      isPlaying: _state.isPlaying,
      speed: _state.speed,
      repeatCount: repeatCount,
      canNext: _state.canNext,
      canPrevious: _state.canPrevious,
      queueLength: _state.queueLength,
    );
    _stateController.add(_state);
  }

  @override
  Future<void> setSpeed(double speed) async {
    _state = AyahAudioState(
      currentAyah: _state.currentAyah,
      isPlaying: _state.isPlaying,
      speed: speed,
      repeatCount: _state.repeatCount,
      canNext: _state.canNext,
      canPrevious: _state.canPrevious,
      queueLength: _state.queueLength,
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
