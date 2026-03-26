import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'ayah_audio_service.dart';
import 'ayah_audio_source.dart';

class SurahAudioDownloadSnapshot {
  const SurahAudioDownloadSnapshot({
    required this.surah,
    required this.edition,
    required this.bitrate,
    required this.downloadedAyahs,
    required this.totalAyahs,
  });

  final int surah;
  final String edition;
  final int bitrate;
  final int downloadedAyahs;
  final int totalAyahs;

  bool get hasAnyDownload => downloadedAyahs > 0;
  bool get isFullyDownloaded => downloadedAyahs == totalAyahs;
  double get fraction =>
      totalAyahs == 0 ? 0 : downloadedAyahs / totalAyahs.toDouble();
}

class SurahAudioDownloadProgress {
  const SurahAudioDownloadProgress({
    required this.surah,
    required this.completedAyahs,
    required this.totalAyahs,
  });

  final int surah;
  final int completedAyahs;
  final int totalAyahs;
}

abstract class AyahAudioDownloadService {
  Future<SurahAudioDownloadSnapshot> getSurahDownloadStatus({
    required int surah,
    required AyahAudioStreamConfig config,
  });

  Future<void> downloadSurah({
    required int surah,
    required AyahAudioStreamConfig config,
    void Function(SurahAudioDownloadProgress progress)? onProgress,
  });

  Future<void> removeSurahDownload({
    required int surah,
    required AyahAudioStreamConfig config,
  });

  Future<File?> findCachedAyahFile({
    required int surah,
    required int ayah,
    required AyahAudioStreamConfig config,
  });
}

class SupportDirAyahAudioDownloadService implements AyahAudioDownloadService {
  SupportDirAyahAudioDownloadService({
    required http.Client client,
    Future<Directory> Function()? getSupportDirectory,
  })  : _client = client,
        _getSupportDirectory =
            getSupportDirectory ?? getApplicationSupportDirectory;

  final http.Client _client;
  final Future<Directory> Function() _getSupportDirectory;

  @override
  Future<SurahAudioDownloadSnapshot> getSurahDownloadStatus({
    required int surah,
    required AyahAudioStreamConfig config,
  }) async {
    final totalAyahs = ayahCountForSurah(surah);
    var downloadedAyahs = 0;
    for (var ayah = 1; ayah <= totalAyahs; ayah++) {
      if (await _hasCachedAyahFile(surah: surah, ayah: ayah, config: config)) {
        downloadedAyahs++;
      }
    }
    return SurahAudioDownloadSnapshot(
      surah: surah,
      edition: config.edition,
      bitrate: config.bitrate,
      downloadedAyahs: downloadedAyahs,
      totalAyahs: totalAyahs,
    );
  }

  @override
  Future<void> downloadSurah({
    required int surah,
    required AyahAudioStreamConfig config,
    void Function(SurahAudioDownloadProgress progress)? onProgress,
  }) async {
    final totalAyahs = ayahCountForSurah(surah);
    var completedAyahs = 0;
    final source = AlQuranCloudAyahAudioSource(
      edition: config.edition,
      bitrate: config.bitrate,
    );

    for (var ayah = 1; ayah <= totalAyahs; ayah++) {
      final targetFile = await _resolveAyahFile(
        surah: surah,
        ayah: ayah,
        config: config,
      );
      if (!await targetFile.exists()) {
        await _downloadAyah(
          file: targetFile,
          uri: source.urlForAyah(surah, ayah),
        );
      }
      completedAyahs++;
      onProgress?.call(
        SurahAudioDownloadProgress(
          surah: surah,
          completedAyahs: completedAyahs,
          totalAyahs: totalAyahs,
        ),
      );
    }
  }

  @override
  Future<void> removeSurahDownload({
    required int surah,
    required AyahAudioStreamConfig config,
  }) async {
    final surahDir = await _resolveSurahDirectory(
      surah: surah,
      config: config,
    );
    if (await surahDir.exists()) {
      await surahDir.delete(recursive: true);
    }
  }

  @override
  Future<File?> findCachedAyahFile({
    required int surah,
    required int ayah,
    required AyahAudioStreamConfig config,
  }) async {
    final file = await _resolveAyahFile(
      surah: surah,
      ayah: ayah,
      config: config,
    );
    if (!await file.exists()) {
      return null;
    }
    return file;
  }

  Future<bool> _hasCachedAyahFile({
    required int surah,
    required int ayah,
    required AyahAudioStreamConfig config,
  }) async {
    final file = await _resolveAyahFile(
      surah: surah,
      ayah: ayah,
      config: config,
    );
    return file.exists();
  }

  Future<File> _resolveAyahFile({
    required int surah,
    required int ayah,
    required AyahAudioStreamConfig config,
  }) async {
    final surahDir = await _resolveSurahDirectory(
      surah: surah,
      config: config,
    );
    return File(_joinPath(surahDir.path, 'ayah_$ayah.mp3'));
  }

  Future<Directory> _resolveSurahDirectory({
    required int surah,
    required AyahAudioStreamConfig config,
  }) async {
    final rootDir = await _resolveCacheRoot();
    final dir = Directory(
      _joinPath(
        rootDir.path,
        '${_sanitizePathSegment(config.edition)}_${config.bitrate}',
        'surah_$surah',
      ),
    );
    await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _resolveCacheRoot() async {
    final supportDir = await _getSupportDirectory();
    final cacheDir = Directory(_joinPath(supportDir.path, 'ayah_audio_cache'));
    await cacheDir.create(recursive: true);
    return cacheDir;
  }

  Future<void> _downloadAyah({
    required File file,
    required Uri uri,
  }) async {
    final response = await _client.get(uri);
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Audio download failed with status ${response.statusCode}.',
        uri: uri,
      );
    }

    final tempFile = File('${file.path}.tmp');
    try {
      await tempFile.parent.create(recursive: true);
      await tempFile.writeAsBytes(response.bodyBytes, flush: true);
      if (await file.exists()) {
        await file.delete();
      }
      await tempFile.rename(file.path);
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  String _sanitizePathSegment(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
  }

  String _joinPath(String part1, String part2, [String? part3]) {
    final separator = Platform.pathSeparator;
    final buffer = StringBuffer(part1);
    buffer.write(separator);
    buffer.write(part2);
    if (part3 != null) {
      buffer.write(separator);
      buffer.write(part3);
    }
    return buffer.toString();
  }
}
