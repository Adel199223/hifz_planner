import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();
typedef PreferenceErrorReporter =
    void Function(String operation, Object error, StackTrace stackTrace);

class AyahAudioPreferencesState {
  const AyahAudioPreferencesState({
    this.edition = 'ar.alafasy',
    this.bitrate = 128,
    this.speed = 1.0,
    this.repeatCount = 0,
    this.reciterDisplayName = 'Mishari Rashid al-`Afasy',
    this.hasLoaded = false,
  });

  final String edition;
  final int bitrate;
  final double speed;
  final int repeatCount;
  final String reciterDisplayName;
  final bool hasLoaded;

  AyahAudioPreferencesState copyWith({
    String? edition,
    int? bitrate,
    double? speed,
    int? repeatCount,
    String? reciterDisplayName,
    bool? hasLoaded,
  }) {
    return AyahAudioPreferencesState(
      edition: edition ?? this.edition,
      bitrate: bitrate ?? this.bitrate,
      speed: speed ?? this.speed,
      repeatCount: repeatCount ?? this.repeatCount,
      reciterDisplayName: reciterDisplayName ?? this.reciterDisplayName,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

class StoredAyahAudioPreferences {
  const StoredAyahAudioPreferences({
    this.edition,
    this.bitrate,
    this.speed,
    this.repeatCount,
    this.reciterDisplayName,
  });

  final String? edition;
  final int? bitrate;
  final double? speed;
  final int? repeatCount;
  final String? reciterDisplayName;
}

abstract class AyahAudioPreferencesStore {
  Future<StoredAyahAudioPreferences> load();

  Future<void> saveEdition(String edition);

  Future<void> saveBitrate(int bitrate);

  Future<void> saveSpeed(double speed);

  Future<void> saveRepeatCount(int repeatCount);

  Future<void> saveReciterDisplayName(String displayName);
}

class SharedPrefsAyahAudioPreferencesStore
    implements AyahAudioPreferencesStore {
  SharedPrefsAyahAudioPreferencesStore({
    SharedPreferencesLoader? loadPreferences,
    PreferenceErrorReporter? reportError,
  }) : _loadPreferences = loadPreferences ?? SharedPreferences.getInstance,
       _reportError = reportError ?? _defaultReportError;

  static const String _editionKey = 'reader_audio.edition';
  static const String _bitrateKey = 'reader_audio.bitrate';
  static const String _speedKey = 'reader_audio.speed';
  static const String _repeatCountKey = 'reader_audio.repeat_count';
  static const String _reciterNameKey = 'reader_audio.reciter_name';

  final SharedPreferencesLoader _loadPreferences;
  final PreferenceErrorReporter _reportError;

  @override
  Future<StoredAyahAudioPreferences> load() async {
    try {
      final prefs = await _loadPreferences();
      return StoredAyahAudioPreferences(
        edition: prefs.getString(_editionKey),
        bitrate: prefs.getInt(_bitrateKey),
        speed: prefs.getDouble(_speedKey),
        repeatCount: prefs.getInt(_repeatCountKey),
        reciterDisplayName: prefs.getString(_reciterNameKey),
      );
    } catch (error, stackTrace) {
      _reportError('load reader audio preferences', error, stackTrace);
      return const StoredAyahAudioPreferences();
    }
  }

  @override
  Future<void> saveEdition(String edition) async {
    await _savePreference(
      operation: 'save reader audio edition',
      action: (prefs) => prefs.setString(_editionKey, edition),
    );
  }

  @override
  Future<void> saveBitrate(int bitrate) async {
    await _savePreference(
      operation: 'save reader audio bitrate',
      action: (prefs) => prefs.setInt(_bitrateKey, bitrate),
    );
  }

  @override
  Future<void> saveSpeed(double speed) async {
    await _savePreference(
      operation: 'save reader audio speed',
      action: (prefs) => prefs.setDouble(_speedKey, speed),
    );
  }

  @override
  Future<void> saveRepeatCount(int repeatCount) async {
    await _savePreference(
      operation: 'save reader audio repeat count',
      action: (prefs) => prefs.setInt(_repeatCountKey, repeatCount),
    );
  }

  @override
  Future<void> saveReciterDisplayName(String displayName) async {
    await _savePreference(
      operation: 'save reader audio reciter display name',
      action: (prefs) => prefs.setString(_reciterNameKey, displayName),
    );
  }

  Future<void> _savePreference({
    required String operation,
    required Future<bool> Function(SharedPreferences prefs) action,
  }) async {
    try {
      final prefs = await _loadPreferences();
      final didSave = await action(prefs);
      if (!didSave) {
        _reportError(
          operation,
          StateError('$operation returned false.'),
          StackTrace.current,
        );
      }
    } catch (error, stackTrace) {
      _reportError(operation, error, stackTrace);
    }
  }
}

void _defaultReportError(
  String operation,
  Object error,
  StackTrace stackTrace,
) {
  developer.log(
    operation,
    name: 'ayah_audio_preferences',
    error: error,
    stackTrace: stackTrace,
  );
}
