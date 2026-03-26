import 'dart:io';

import 'ayah_audio_download_service.dart';
import 'ayah_audio_service.dart';
import 'ayah_audio_source.dart';

abstract class AyahAudioPlaybackResolver {
  Future<Uri> resolveAyahUri({
    required AyahAudioSource source,
    required int surah,
    required int ayah,
  });
}

class CachedAyahAudioPlaybackResolver implements AyahAudioPlaybackResolver {
  const CachedAyahAudioPlaybackResolver(this._downloadService);

  final AyahAudioDownloadService _downloadService;

  @override
  Future<Uri> resolveAyahUri({
    required AyahAudioSource source,
    required int surah,
    required int ayah,
  }) async {
    final cachedFile = await _downloadService.findCachedAyahFile(
      surah: surah,
      ayah: ayah,
      config: AyahAudioStreamConfig(
        edition: source.edition,
        bitrate: source.bitrate,
      ),
    );
    if (cachedFile != null) {
      return File(cachedFile.path).uri;
    }
    return source.urlForAyah(surah, ayah);
  }
}
