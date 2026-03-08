import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class QuranComChapterEntry {
  const QuranComChapterEntry({
    required this.id,
    required this.nameSimple,
    required this.nameArabic,
    required this.translatedName,
    required this.translatedLanguageName,
  });

  final int id;
  final String nameSimple;
  final String nameArabic;
  final String translatedName;
  final String translatedLanguageName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name_simple': nameSimple,
      'name_arabic': nameArabic,
      'translated_name': translatedName,
      'translated_language_name': translatedLanguageName,
    };
  }

  factory QuranComChapterEntry.fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null || id < 1 || id > 114) {
      throw const FormatException('Invalid chapter id.');
    }
    return QuranComChapterEntry(
      id: id,
      nameSimple: (_asString(json['name_simple']) ?? '').trim(),
      nameArabic: (_asString(json['name_arabic']) ?? '').trim(),
      translatedName: (_asString(json['translated_name']) ?? '').trim(),
      translatedLanguageName:
          (_asString(json['translated_language_name']) ?? '').trim(),
    );
  }
}

class QuranComChaptersService {
  QuranComChaptersService({
    http.Client? httpClient,
    Future<Directory> Function()? getSupportDirectory,
    Duration requestTimeout = const Duration(seconds: 4),
  })  : _httpClient = httpClient ?? http.Client(),
        _getSupportDirectory =
            getSupportDirectory ?? getApplicationSupportDirectory,
        _requestTimeout = requestTimeout;

  static const String _apiBase = 'https://api.quran.com/api/v4';
  final http.Client _httpClient;
  final Future<Directory> Function() _getSupportDirectory;
  final Duration _requestTimeout;
  final Map<String, List<QuranComChapterEntry>> _memoryCache =
      <String, List<QuranComChapterEntry>>{};

  Future<List<QuranComChapterEntry>> getChapters({
    required String languageCode,
  }) async {
    final code = languageCode.trim().toLowerCase();
    if (code.isEmpty) {
      return const <QuranComChapterEntry>[];
    }

    final memory = _memoryCache[code];
    if (memory != null && memory.isNotEmpty) {
      return memory;
    }

    final cacheFile = await _resolveCacheFile(code);

    try {
      final uri = Uri.parse('$_apiBase/chapters?language=$code');
      final response = await _httpClient.get(uri).timeout(_requestTimeout);
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Unexpected status ${response.statusCode}');
      }
      final remote = _parseApiPayload(response.body);
      if (remote.isNotEmpty) {
        _memoryCache[code] = remote;
        try {
          await _writeCacheAtomic(
            cacheFile,
            jsonEncode(<String, dynamic>{
              'language_code': code,
              'chapters': [
                for (final chapter in remote) chapter.toJson(),
              ],
            }),
          );
        } catch (_) {
          // Cache write failures should not block UI labels.
        }
        return remote;
      }
    } catch (_) {
      // Fall back to cache when network or parse fails.
    }

    final cached = await _readCache(cacheFile);
    if (cached.isNotEmpty) {
      _memoryCache[code] = cached;
    }
    return cached;
  }

  Future<QuranComChapterEntry?> getChapter({
    required int chapterId,
    required String languageCode,
  }) async {
    final chapters = await getChapters(languageCode: languageCode);
    for (final chapter in chapters) {
      if (chapter.id == chapterId) {
        return chapter;
      }
    }
    return null;
  }

  List<QuranComChapterEntry> _parseApiPayload(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid chapters payload root.');
    }
    final rawChapters = decoded['chapters'];
    if (rawChapters is! List) {
      throw const FormatException('Missing chapters list.');
    }

    final chapters = <QuranComChapterEntry>[];
    for (final raw in rawChapters) {
      if (raw is! Map) {
        continue;
      }
      final chapterMap = Map<String, dynamic>.from(raw);
      final translatedRaw = chapterMap['translated_name'];
      final translated = translatedRaw is Map
          ? Map<String, dynamic>.from(translatedRaw)
          : const <String, dynamic>{};
      final normalized = <String, dynamic>{
        'id': chapterMap['id'],
        'name_simple': chapterMap['name_simple'],
        'name_arabic': chapterMap['name_arabic'],
        'translated_name': translated['name'],
        'translated_language_name': translated['language_name'],
      };
      chapters.add(QuranComChapterEntry.fromJson(normalized));
    }
    chapters.sort((a, b) => a.id.compareTo(b.id));
    return chapters;
  }

  Future<List<QuranComChapterEntry>> _readCache(File cacheFile) async {
    try {
      if (!await cacheFile.exists()) {
        return const <QuranComChapterEntry>[];
      }
      final raw = await cacheFile.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const <QuranComChapterEntry>[];
      }
      final rawChapters = decoded['chapters'];
      if (rawChapters is! List) {
        return const <QuranComChapterEntry>[];
      }
      final chapters = <QuranComChapterEntry>[];
      for (final rawChapter in rawChapters) {
        if (rawChapter is Map) {
          chapters.add(
            QuranComChapterEntry.fromJson(
              Map<String, dynamic>.from(rawChapter),
            ),
          );
        }
      }
      chapters.sort((a, b) => a.id.compareTo(b.id));
      return chapters;
    } catch (_) {
      return const <QuranComChapterEntry>[];
    }
  }

  Future<File> _resolveCacheFile(String languageCode) async {
    final supportDir = await _getSupportDirectory();
    final cacheDir = Directory(_joinPath(supportDir.path, 'qurancom_chapters'));
    await cacheDir.create(recursive: true);
    return File(_joinPath(cacheDir.path, 'chapters_$languageCode.json'));
  }

  Future<void> _writeCacheAtomic(File destination, String payload) async {
    final tempPath =
        '${destination.path}.tmp_${DateTime.now().microsecondsSinceEpoch}';
    final tempFile = File(tempPath);
    await tempFile.writeAsString(payload, flush: true);
    if (await destination.exists()) {
      await destination.delete();
    }
    await tempFile.rename(destination.path);
  }
}

int? _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

String? _asString(dynamic value) {
  if (value is String) {
    return value;
  }
  return null;
}

String _joinPath(String left, String right) {
  if (left.isEmpty) {
    return right;
  }
  if (right.isEmpty) {
    return left;
  }
  if (left.endsWith(Platform.pathSeparator)) {
    return '$left$right';
  }
  return '$left${Platform.pathSeparator}$right';
}
