import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/ayah_audio_source.dart';

void main() {
  group('globalAyahIndex', () {
    test('maps canonical boundary examples', () {
      expect(globalAyahIndex(1, 1), 1);
      expect(globalAyahIndex(2, 1), 8);
      expect(globalAyahIndex(114, 6), 6236);
    });

    test('maps spot checks across surah boundaries', () {
      expect(globalAyahIndex(2, 286), 293);
      expect(globalAyahIndex(3, 1), 294);
      expect(globalAyahIndex(114, 1), 6231);
    });

    test('throws on invalid surah or ayah', () {
      expect(() => globalAyahIndex(0, 1), throwsRangeError);
      expect(() => globalAyahIndex(115, 1), throwsRangeError);
      expect(() => globalAyahIndex(1, 0), throwsRangeError);
      expect(() => globalAyahIndex(1, 8), throwsRangeError);
    });
  });

  group('AlQuranCloudAyahAudioSource', () {
    test('builds default url from global index', () {
      final source = AlQuranCloudAyahAudioSource();
      expect(
        source.urlForAyah(2, 1).toString(),
        'https://cdn.islamic.network/quran/audio/128/ar.alafasy/8.mp3',
      );
    });

    test('supports custom edition and bitrate', () {
      final source = AlQuranCloudAyahAudioSource(
        edition: 'ar.hudhaify',
        bitrate: 64,
      );
      expect(
        source.urlForAyah(1, 1).toString(),
        'https://cdn.islamic.network/quran/audio/64/ar.hudhaify/1.mp3',
      );
    });
  });
}
