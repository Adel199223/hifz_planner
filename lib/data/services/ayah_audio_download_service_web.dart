import '../../support/web_io_shim.dart';

import 'package:http/http.dart' as http;

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
  });

  @override
  Future<SurahAudioDownloadSnapshot> getSurahDownloadStatus({
    required int surah,
    required AyahAudioStreamConfig config,
  }) async {
    return SurahAudioDownloadSnapshot(
      surah: surah,
      edition: config.edition,
      bitrate: config.bitrate,
      downloadedAyahs: 0,
      totalAyahs: ayahCountForSurah(surah),
    );
  }

  @override
  Future<void> downloadSurah({
    required int surah,
    required AyahAudioStreamConfig config,
    void Function(SurahAudioDownloadProgress progress)? onProgress,
  }) async {
    throw UnsupportedError(
      'Offline audio downloads are not available in web mode.',
    );
  }

  @override
  Future<void> removeSurahDownload({
    required int surah,
    required AyahAudioStreamConfig config,
  }) async {}

  @override
  Future<File?> findCachedAyahFile({
    required int surah,
    required int ayah,
    required AyahAudioStreamConfig config,
  }) async {
    return null;
  }
}

