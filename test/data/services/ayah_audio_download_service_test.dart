import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/ayah_audio_download_service.dart';
import 'package:hifz_planner/data/services/ayah_audio_playback_resolver.dart';
import 'package:hifz_planner/data/services/ayah_audio_service.dart';
import 'package:hifz_planner/data/services/ayah_audio_source.dart';
import 'package:http/http.dart' as http;

void main() {
  test('downloadSurah caches audio, reports status, and removeSurahDownload clears it',
      () async {
    final tempDir = await Directory.systemTemp.createTemp('audio_download_test');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final requests = <Uri>[];
    final service = SupportDirAyahAudioDownloadService(
      client: _FakeHttpClient((request) async {
        requests.add(request.url);
        return http.Response.bytes(<int>[1, 2, 3], HttpStatus.ok);
      }),
      getSupportDirectory: () async => tempDir,
    );
    const config = AyahAudioStreamConfig(
      edition: 'ar.alafasy',
      bitrate: 128,
    );
    SurahAudioDownloadProgress? lastProgress;

    await service.downloadSurah(
      surah: 1,
      config: config,
      onProgress: (progress) {
        lastProgress = progress;
      },
    );

    final afterDownload = await service.getSurahDownloadStatus(
      surah: 1,
      config: config,
    );
    expect(lastProgress, isNotNull);
    expect(lastProgress!.completedAyahs, 7);
    expect(afterDownload.downloadedAyahs, 7);
    expect(afterDownload.isFullyDownloaded, isTrue);
    expect(requests.length, 7);

    await service.removeSurahDownload(
      surah: 1,
      config: config,
    );
    final afterRemove = await service.getSurahDownloadStatus(
      surah: 1,
      config: config,
    );
    expect(afterRemove.downloadedAyahs, 0);
    expect(afterRemove.hasAnyDownload, isFalse);
  });

  test('playback resolver prefers cached file and falls back to remote url',
      () async {
    final tempDir = await Directory.systemTemp.createTemp('audio_resolver_test');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final service = SupportDirAyahAudioDownloadService(
      client: _FakeHttpClient((_) async {
        return http.Response.bytes(<int>[4, 5, 6], HttpStatus.ok);
      }),
      getSupportDirectory: () async => tempDir,
    );
    final resolver = CachedAyahAudioPlaybackResolver(service);
    final source = AlQuranCloudAyahAudioSource(
      edition: 'ar.alafasy',
      bitrate: 128,
    );

    final remoteUri = await resolver.resolveAyahUri(
      source: source,
      surah: 1,
      ayah: 1,
    );
    expect(remoteUri.toString(), contains('/quran/audio/128/ar.alafasy/1.mp3'));

    await service.downloadSurah(
      surah: 1,
      config: const AyahAudioStreamConfig(
        edition: 'ar.alafasy',
        bitrate: 128,
      ),
    );

    final localUri = await resolver.resolveAyahUri(
      source: source,
      surah: 1,
      ayah: 1,
    );
    expect(localUri.scheme, 'file');
    expect(localUri.path, contains('ayah_1.mp3'));
  });
}

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._handler);

  final Future<http.Response> Function(http.Request request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final typedRequest = http.Request(request.method, request.url)
      ..headers.addAll(request.headers);
    final response = await _handler(typedRequest);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
      reasonPhrase: response.reasonPhrase,
    );
  }
}
