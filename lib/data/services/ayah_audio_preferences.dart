import 'package:shared_preferences/shared_preferences.dart';

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
  const SharedPrefsAyahAudioPreferencesStore();

  static const String _editionKey = 'reader_audio.edition';
  static const String _bitrateKey = 'reader_audio.bitrate';
  static const String _speedKey = 'reader_audio.speed';
  static const String _repeatCountKey = 'reader_audio.repeat_count';
  static const String _reciterNameKey = 'reader_audio.reciter_name';

  @override
  Future<StoredAyahAudioPreferences> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return StoredAyahAudioPreferences(
        edition: prefs.getString(_editionKey),
        bitrate: prefs.getInt(_bitrateKey),
        speed: prefs.getDouble(_speedKey),
        repeatCount: prefs.getInt(_repeatCountKey),
        reciterDisplayName: prefs.getString(_reciterNameKey),
      );
    } catch (_) {
      return const StoredAyahAudioPreferences();
    }
  }

  @override
  Future<void> saveEdition(String edition) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_editionKey, edition);
    } catch (_) {
      // Keep runtime behavior stable when local persistence is unavailable.
    }
  }

  @override
  Future<void> saveBitrate(int bitrate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bitrateKey, bitrate);
    } catch (_) {
      // Keep runtime behavior stable when local persistence is unavailable.
    }
  }

  @override
  Future<void> saveSpeed(double speed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_speedKey, speed);
    } catch (_) {
      // Keep runtime behavior stable when local persistence is unavailable.
    }
  }

  @override
  Future<void> saveRepeatCount(int repeatCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_repeatCountKey, repeatCount);
    } catch (_) {
      // Keep runtime behavior stable when local persistence is unavailable.
    }
  }

  @override
  Future<void> saveReciterDisplayName(String displayName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_reciterNameKey, displayName);
    } catch (_) {
      // Keep runtime behavior stable when local persistence is unavailable.
    }
  }
}
