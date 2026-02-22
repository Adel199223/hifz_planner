import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class QuranComApiException implements Exception {
  const QuranComApiException(
    this.message, {
    this.statusCode,
    this.cause,
  });

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() {
    final status = statusCode == null ? '' : ' (status $statusCode)';
    return 'QuranComApiException$message$status';
  }
}

class MushafWord {
  const MushafWord({
    required this.codeV2,
    required this.textQpcHafs,
    required this.charTypeName,
    required this.lineNumber,
    required this.position,
    required this.pageNumber,
  });

  final String? codeV2;
  final String? textQpcHafs;
  final String? charTypeName;
  final int? lineNumber;
  final int? position;
  final int? pageNumber;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code_v2': codeV2,
      'text_qpc_hafs': textQpcHafs,
      'char_type_name': charTypeName,
      'line_number': lineNumber,
      'position': position,
      'page_number': pageNumber,
    };
  }

  factory MushafWord.fromJson(Map<String, dynamic> json) {
    return MushafWord(
      codeV2: _asString(json['code_v2']),
      textQpcHafs: _asString(json['text_qpc_hafs']),
      charTypeName: _asString(json['char_type_name']),
      lineNumber: _asInt(json['line_number']),
      position: _asInt(json['position']),
      pageNumber: _asInt(json['page_number']),
    );
  }
}

class MushafPageMeta {
  const MushafPageMeta({
    required this.firstChapterId,
    required this.firstVerseNumber,
    required this.firstVerseKey,
  });

  final int? firstChapterId;
  final int? firstVerseNumber;
  final String? firstVerseKey;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'first_chapter_id': firstChapterId,
      'first_verse_number': firstVerseNumber,
      'first_verse_key': firstVerseKey,
    };
  }

  factory MushafPageMeta.fromJson(Map<String, dynamic> json) {
    return MushafPageMeta(
      firstChapterId: _asInt(json['first_chapter_id']),
      firstVerseNumber: _asInt(json['first_verse_number']),
      firstVerseKey: _asString(json['first_verse_key']),
    );
  }
}

class MushafPageData {
  const MushafPageData({
    required this.words,
    required this.meta,
  });

  final List<MushafWord> words;
  final MushafPageMeta meta;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'meta': meta.toJson(),
      'words': [for (final word in words) word.toJson()],
    };
  }

  factory MushafPageData.fromJson(Map<String, dynamic> json) {
    final wordsRaw = json['words'];
    final metaRaw = json['meta'];
    if (wordsRaw is! List || metaRaw is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid cached Mushaf page data format.',
      );
    }

    return MushafPageData(
      words: [
        for (final item in wordsRaw)
          if (item is Map<String, dynamic>) MushafWord.fromJson(item),
      ],
      meta: MushafPageMeta.fromJson(metaRaw),
    );
  }
}

class QuranComApi {
  QuranComApi({
    http.Client? httpClient,
    Future<Directory> Function()? getSupportDirectory,
    Duration retryDelay = const Duration(milliseconds: 400),
    int retries = 2,
  })  : _httpClient = httpClient ?? http.Client(),
        _getSupportDirectory =
            getSupportDirectory ?? getApplicationSupportDirectory,
        _retryDelay = retryDelay,
        _retries = retries;

  static const String _apiBase = 'https://api.quran.com/api/v4';

  final http.Client _httpClient;
  final Future<Directory> Function() _getSupportDirectory;
  final Duration _retryDelay;
  final int _retries;

  Future<MushafPageData> getPage({
    required int page,
    required int mushafId,
  }) async {
    if (page < 1 || page > 604) {
      throw QuranComApiException(
        'Invalid page number $page. Expected 1..604.',
      );
    }
    if (mushafId <= 0) {
      throw QuranComApiException('Invalid mushaf id $mushafId.');
    }

    final cacheFile = await _resolveCacheFile(page: page, mushafId: mushafId);
    if (await cacheFile.exists()) {
      try {
        final rawCache = await cacheFile.readAsString();
        final decoded = jsonDecode(rawCache);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Invalid cache JSON root object.');
        }
        return MushafPageData.fromJson(decoded);
      } catch (_) {
        // Fall through to network fetch if cache is unreadable.
      }
    }

    final payload = await _fetchPagePayload(page: page, mushafId: mushafId);
    final data = _parseApiPayload(payload);
    await _writeCacheAtomic(cacheFile, jsonEncode(data.toJson()));
    return data;
  }

  Future<File> _resolveCacheFile({
    required int page,
    required int mushafId,
  }) async {
    final supportDir = await _getSupportDirectory();
    final cacheDir = Directory(_joinPath(supportDir.path, 'qurancom_pages'));
    await cacheDir.create(recursive: true);
    return File(_joinPath(cacheDir.path, 'page_${page}_m$mushafId.json'));
  }

  Future<String> _fetchPagePayload({
    required int page,
    required int mushafId,
  }) async {
    final uri = Uri.parse(
      '$_apiBase/verses/by_page/$page'
      '?words=true&mushaf=$mushafId&word_fields=code_v2,text_qpc_hafs',
    );

    Object? lastError;
    for (var attempt = 0; attempt <= _retries; attempt++) {
      try {
        final response = await _httpClient.get(uri);
        if (response.statusCode != HttpStatus.ok) {
          throw QuranComApiException(
            'Request failed for page $page.',
            statusCode: response.statusCode,
          );
        }
        return response.body;
      } catch (error) {
        lastError = error;
        if (attempt >= _retries) {
          break;
        }
        await Future<void>.delayed(_retryDelay);
      }
    }

    if (lastError is QuranComApiException) {
      throw lastError;
    }
    throw QuranComApiException(
      'Failed to fetch page $page after ${_retries + 1} attempts.',
      cause: lastError,
    );
  }

  MushafPageData _parseApiPayload(String rawBody) {
    final decoded = jsonDecode(rawBody);
    if (decoded is! Map<String, dynamic>) {
      throw const QuranComApiException('Invalid Quran.com payload root.');
    }

    final versesRaw = decoded['verses'];
    if (versesRaw is! List) {
      throw const QuranComApiException('Invalid Quran.com payload: verses.');
    }
    if (versesRaw.isEmpty) {
      throw const QuranComApiException(
          'No verses returned for requested page.');
    }

    final firstVerse = versesRaw.first;
    if (firstVerse is! Map<String, dynamic>) {
      throw const QuranComApiException('Invalid first verse payload.');
    }
    final firstVerseKey = _asString(firstVerse['verse_key']);
    final firstChapterId =
        _asInt(firstVerse['chapter_id']) ?? _chapterFromVerseKey(firstVerseKey);
    final firstVerseNumber = _asInt(firstVerse['verse_number']);
    final meta = MushafPageMeta(
      firstChapterId: firstChapterId,
      firstVerseNumber: firstVerseNumber,
      firstVerseKey: firstVerseKey,
    );

    final words = <MushafWord>[];
    for (final verse in versesRaw) {
      if (verse is! Map<String, dynamic>) {
        throw const QuranComApiException('Invalid verse entry in payload.');
      }

      final wordsRaw = verse['words'];
      if (wordsRaw is! List) {
        throw const QuranComApiException(
            'Invalid words array in verse payload.');
      }

      for (final word in wordsRaw) {
        if (word is! Map<String, dynamic>) {
          throw const QuranComApiException('Invalid word entry in payload.');
        }
        words.add(
          MushafWord(
            codeV2: _asString(word['code_v2']),
            textQpcHafs: _asString(word['text_qpc_hafs']),
            charTypeName: _asString(word['char_type_name']),
            lineNumber: _asInt(word['line_number']),
            position: _asInt(word['position']),
            pageNumber: _asInt(word['page_number']),
          ),
        );
      }
    }

    return MushafPageData(
      words: words,
      meta: meta,
    );
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

  int? _chapterFromVerseKey(String? verseKey) {
    if (verseKey == null) {
      return null;
    }
    final parts = verseKey.split(':');
    if (parts.length != 2) {
      return null;
    }
    return int.tryParse(parts.first);
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

String _joinPath(String base, String leaf) {
  if (base.endsWith(Platform.pathSeparator)) {
    return '$base$leaf';
  }
  return '$base${Platform.pathSeparator}$leaf';
}
