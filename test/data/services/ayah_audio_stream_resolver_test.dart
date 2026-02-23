import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/ayah_audio_stream_resolver.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('returns preferred bitrate when probe succeeds', () async {
    final client = MockClient((request) async {
      expect(request.headers['Range'], 'bytes=0-0');
      expect(request.url.path, '/quran/audio/128/ar.alafasy/1.mp3');
      return http.Response('', 206);
    });
    final resolver = AlQuranCloudAyahAudioStreamResolver(client: client);

    final bitrate = await resolver.resolvePlayableBitrate(
      edition: 'ar.alafasy',
      preferredBitrate: 128,
    );

    expect(bitrate, 128);
  });

  test('falls back to lower bitrate when preferred fails', () async {
    final client = MockClient((request) async {
      if (request.url.path.contains('/audio/128/')) {
        return http.Response('', 403);
      }
      if (request.url.path.contains('/audio/64/')) {
        return http.Response('', 206);
      }
      return http.Response('', 404);
    });
    final resolver = AlQuranCloudAyahAudioStreamResolver(client: client);

    final bitrate = await resolver.resolvePlayableBitrate(
      edition: 'ar.abdulsamad',
      preferredBitrate: 128,
    );

    expect(bitrate, 64);
  });

  test('returns null when all candidates fail', () async {
    final client = MockClient((request) async {
      return http.Response('', 403);
    });
    final resolver = AlQuranCloudAyahAudioStreamResolver(client: client);

    final bitrate = await resolver.resolvePlayableBitrate(
      edition: 'ar.unavailable',
      preferredBitrate: 128,
    );

    expect(bitrate, isNull);
  });
}
