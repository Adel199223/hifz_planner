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
    this.verseKey,
    required this.codeV2,
    required this.textQpcHafs,
    this.translationText,
    this.transliterationText,
    required this.charTypeName,
    required this.lineNumber,
    required this.position,
    required this.pageNumber,
  });

  final String? verseKey;
  final String? codeV2;
  final String? textQpcHafs;
  final String? translationText;
  final String? transliterationText;
  final String? charTypeName;
  final int? lineNumber;
  final int? position;
  final int? pageNumber;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'verse_key': verseKey,
      'code_v2': codeV2,
      'text_qpc_hafs': textQpcHafs,
      'translation_text': translationText,
      'transliteration_text': transliterationText,
      'char_type_name': charTypeName,
      'line_number': lineNumber,
      'position': position,
      'page_number': pageNumber,
    };
  }

  factory MushafWord.fromJson(Map<String, dynamic> json) {
    return MushafWord(
      verseKey: _asString(json['verse_key']),
      codeV2: _asString(json['code_v2']),
      textQpcHafs: _asString(json['text_qpc_hafs']),
      translationText: _asString(json['translation_text']) ??
          _asNestedText(json['translation']),
      transliterationText: _asString(json['transliteration_text']) ??
          _asNestedText(json['transliteration']),
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
    this.pageNumber,
    this.juzNumber,
    this.hizbNumber,
    this.rubElHizbNumber,
  });

  final int? firstChapterId;
  final int? firstVerseNumber;
  final String? firstVerseKey;
  final int? pageNumber;
  final int? juzNumber;
  final int? hizbNumber;
  final int? rubElHizbNumber;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'first_chapter_id': firstChapterId,
      'first_verse_number': firstVerseNumber,
      'first_verse_key': firstVerseKey,
      'page_number': pageNumber,
      'juz_number': juzNumber,
      'hizb_number': hizbNumber,
      'rub_el_hizb_number': rubElHizbNumber,
    };
  }

  factory MushafPageMeta.fromJson(Map<String, dynamic> json) {
    return MushafPageMeta(
      firstChapterId: _asInt(json['first_chapter_id']),
      firstVerseNumber: _asInt(json['first_verse_number']),
      firstVerseKey: _asString(json['first_verse_key']),
      pageNumber: _asInt(json['page_number']),
      juzNumber: _asInt(json['juz_number']),
      hizbNumber: _asInt(json['hizb_number']),
      rubElHizbNumber: _asInt(json['rub_el_hizb_number']),
    );
  }
}

class MushafJuzNavEntry {
  const MushafJuzNavEntry({
    required this.juzNumber,
    required this.page,
    required this.verseKey,
  });

  final int juzNumber;
  final int page;
  final String? verseKey;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'juz_number': juzNumber,
      'page': page,
      'verse_key': verseKey,
    };
  }

  factory MushafJuzNavEntry.fromJson(Map<String, dynamic> json) {
    final juzNumber = _asInt(json['juz_number']);
    final page = _asInt(json['page']);
    if (juzNumber == null || page == null) {
      throw const FormatException('Invalid cached juz navigation entry.');
    }
    return MushafJuzNavEntry(
      juzNumber: juzNumber,
      page: page,
      verseKey: _asString(json['verse_key']),
    );
  }
}

class MushafVerseData {
  const MushafVerseData({
    required this.verseKey,
    required this.words,
    this.codeV2,
    this.translations = const <MushafVerseTranslation>[],
  });

  final String verseKey;
  final List<MushafWord> words;
  final String? codeV2;
  final List<MushafVerseTranslation> translations;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'verse_key': verseKey,
      'words': [for (final word in words) word.toJson()],
      'code_v2': codeV2,
      'translations': [
        for (final translation in translations) translation.toJson(),
      ],
    };
  }

  factory MushafVerseData.fromJson(Map<String, dynamic> json) {
    final verseKey = _asString(json['verse_key']);
    final wordsRaw = json['words'];
    if (verseKey == null || verseKey.trim().isEmpty || wordsRaw is! List) {
      throw const FormatException('Invalid cached Mushaf verse data format.');
    }

    final translations = <MushafVerseTranslation>[];
    final translationsRaw = json['translations'];
    if (translationsRaw is List) {
      for (final item in translationsRaw) {
        if (item is Map<String, dynamic>) {
          translations.add(MushafVerseTranslation.fromJson(item));
        }
      }
    }

    return MushafVerseData(
      verseKey: verseKey,
      words: [
        for (final item in wordsRaw)
          if (item is Map<String, dynamic>) MushafWord.fromJson(item),
      ],
      codeV2: _asString(json['code_v2']),
      translations: translations,
    );
  }
}

class MushafVerseTranslation {
  const MushafVerseTranslation({
    this.resourceId,
    this.resourceName,
    this.text,
    this.languageCode,
  });

  final int? resourceId;
  final String? resourceName;
  final String? text;
  final String? languageCode;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'resource_id': resourceId,
      'resource_name': resourceName,
      'text': text,
      'language_code': languageCode,
    };
  }

  factory MushafVerseTranslation.fromJson(Map<String, dynamic> json) {
    var resourceId = _asInt(json['resource_id']) ?? _asInt(json['id']);
    var resourceName =
        _asString(json['resource_name']) ?? _asString(json['name']);
    final text = _asString(json['text']);
    var languageCode =
        _asString(json['language_code']) ?? _asString(json['language_name']);

    final resource = json['resource'];
    if (resource is Map<String, dynamic>) {
      resourceId ??= _asInt(resource['id']);
      resourceName ??= _asString(resource['name']);
      languageCode ??= _asString(resource['language_code']) ??
          _asString(resource['language_name']);
    }

    return MushafVerseTranslation(
      resourceId: resourceId,
      resourceName: resourceName,
      text: text,
      languageCode: languageCode,
    );
  }
}

class MushafPageData {
  const MushafPageData({
    required this.words,
    required this.meta,
    this.verses = const <MushafVerseData>[],
  });

  final List<MushafWord> words;
  final MushafPageMeta meta;
  final List<MushafVerseData> verses;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'meta': meta.toJson(),
      'words': [for (final word in words) word.toJson()],
      'verses': [for (final verse in verses) verse.toJson()],
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

    final verses = <MushafVerseData>[];
    final versesRaw = json['verses'];
    if (versesRaw is List) {
      for (final item in versesRaw) {
        if (item is Map<String, dynamic>) {
          verses.add(MushafVerseData.fromJson(item));
        }
      }
    }

    return MushafPageData(
      words: [
        for (final item in wordsRaw)
          if (item is Map<String, dynamic>) MushafWord.fromJson(item),
      ],
      meta: MushafPageMeta.fromJson(metaRaw),
      verses: verses,
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
  final Map<String, MushafPageData> _pageMemoryCache =
      <String, MushafPageData>{};
  final Map<String, Future<MushafPageData>> _pendingPageLoads =
      <String, Future<MushafPageData>>{};
  final Map<String, Future<MushafPageData>> _pendingPageRefreshes =
      <String, Future<MushafPageData>>{};
  final Map<int, List<MushafJuzNavEntry>> _juzIndexMemoryCache =
      <int, List<MushafJuzNavEntry>>{};
  final Map<int, Future<List<MushafJuzNavEntry>>> _pendingJuzIndexLoads =
      <int, Future<List<MushafJuzNavEntry>>>{};

  Future<MushafPageData> getPage({
    required int page,
    required int mushafId,
  }) async {
    return _getPage(
      page: page,
      mushafId: mushafId,
      translationResourceId: null,
      requireVerseData: false,
      requireVerseTranslations: false,
      requireWordTooltipData: false,
    );
  }

  Future<List<MushafJuzNavEntry>> getJuzIndex({
    required int mushafId,
  }) async {
    _validatePageAndMushaf(page: 1, mushafId: mushafId);
    final cached = _juzIndexMemoryCache[mushafId];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    var pending = _pendingJuzIndexLoads[mushafId];
    if (pending == null) {
      final future = _loadJuzIndexFromCacheOrNetwork(mushafId: mushafId);
      pending = future.whenComplete(() {
        _pendingJuzIndexLoads.remove(mushafId);
      });
      _pendingJuzIndexLoads[mushafId] = pending;
    }

    final entries = await pending;
    _juzIndexMemoryCache[mushafId] = entries;
    return entries;
  }

  Future<MushafPageData> getPageWithVerses({
    required int page,
    required int mushafId,
    bool requireWordTooltipData = false,
    int? translationResourceId,
  }) async {
    if (!requireWordTooltipData) {
      return _getPage(
        page: page,
        mushafId: mushafId,
        translationResourceId: translationResourceId,
        requireVerseData: true,
        requireVerseTranslations: translationResourceId != null,
        requireWordTooltipData: false,
      );
    }

    try {
      return await _getPage(
        page: page,
        mushafId: mushafId,
        translationResourceId: translationResourceId,
        requireVerseData: true,
        requireVerseTranslations: translationResourceId != null,
        requireWordTooltipData: true,
      );
    } catch (_) {
      // Tooltip data is optional. Fall back to verse-ready data when refresh fails.
      return _getPage(
        page: page,
        mushafId: mushafId,
        translationResourceId: translationResourceId,
        requireVerseData: true,
        requireVerseTranslations: translationResourceId != null,
        requireWordTooltipData: false,
      );
    }
  }

  Future<MushafPageData> _loadPageForVerseWords({
    required int page,
    required int mushafId,
    int? translationResourceId,
  }) async {
    return _getPage(
      page: page,
      mushafId: mushafId,
      translationResourceId: translationResourceId,
      requireVerseData: true,
      requireVerseTranslations: translationResourceId != null,
      requireWordTooltipData: false,
    );
  }

  Future<MushafVerseData> getVerseDataByPage({
    required int page,
    required int mushafId,
    required String verseKey,
    int? translationResourceId,
  }) async {
    final normalizedVerseKey = verseKey.trim();
    if (normalizedVerseKey.isEmpty) {
      throw const QuranComApiException('Verse key is required.');
    }

    var pageData = await getPageWithVerses(
      page: page,
      mushafId: mushafId,
      translationResourceId: translationResourceId,
    );
    if (pageData.verses.isEmpty) {
      pageData = await _loadPageForVerseWords(
        page: page,
        mushafId: mushafId,
        translationResourceId: translationResourceId,
      );
    }

    for (final verse in pageData.verses) {
      if (verse.verseKey == normalizedVerseKey) {
        return verse;
      }
    }

    throw QuranComApiException(
      'Verse $normalizedVerseKey not found in page $page (mushaf $mushafId).',
    );
  }

  Future<List<MushafWord>> getVerseWordsByPage({
    required int page,
    required int mushafId,
    required String verseKey,
  }) async {
    final verse = await getVerseDataByPage(
      page: page,
      mushafId: mushafId,
      verseKey: verseKey,
    );
    return verse.words;
  }

  Future<MushafPageData> _getPage({
    required int page,
    required int mushafId,
    required int? translationResourceId,
    required bool requireVerseData,
    required bool requireVerseTranslations,
    required bool requireWordTooltipData,
  }) async {
    _validatePageAndMushaf(page: page, mushafId: mushafId);
    final key = _pageKey(
      page: page,
      mushafId: mushafId,
      translationResourceId: translationResourceId,
    );
    final cached = _pageMemoryCache[key];
    if (cached != null) {
      if ((!requireVerseData || _hasRequiredVerseData(cached)) &&
          (!requireVerseTranslations ||
              _hasRequiredVerseTranslations(
                cached,
                translationResourceId: translationResourceId,
              )) &&
          (!requireWordTooltipData || _hasWordTooltipData(cached))) {
        return cached;
      }
    }

    var pending = _pendingPageLoads[key];
    if (pending == null) {
      final future = _loadPageFromCacheOrNetwork(
        page: page,
        mushafId: mushafId,
        translationResourceId: translationResourceId,
      );
      pending = future.whenComplete(() {
        _pendingPageLoads.remove(key);
      });
      _pendingPageLoads[key] = pending;
    }

    final pageData = await pending;
    final normalizedPageData = _normalizeWordVerseKeys(pageData);
    _pageMemoryCache[key] = normalizedPageData;
    if ((!requireVerseData || _hasRequiredVerseData(normalizedPageData)) &&
        (!requireVerseTranslations ||
            _hasRequiredVerseTranslations(
              normalizedPageData,
              translationResourceId: translationResourceId,
            )) &&
        (!requireWordTooltipData || _hasWordTooltipData(normalizedPageData))) {
      return normalizedPageData;
    }

    var refreshPending = _pendingPageRefreshes[key];
    if (refreshPending == null) {
      final refreshFuture = _refreshPageFromNetwork(
        page: page,
        mushafId: mushafId,
        translationResourceId: translationResourceId,
      );
      refreshPending = refreshFuture.whenComplete(() {
        _pendingPageRefreshes.remove(key);
      });
      _pendingPageRefreshes[key] = refreshPending;
    }
    final refreshed = _normalizeWordVerseKeys(await refreshPending);
    _pageMemoryCache[key] = refreshed;
    return refreshed;
  }

  bool _hasRequiredVerseData(MushafPageData data) {
    if (data.verses.isEmpty) {
      return false;
    }
    for (final verse in data.verses) {
      final codeV2 = verse.codeV2;
      if (codeV2 == null || codeV2.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  bool _hasRequiredVerseTranslations(
    MushafPageData data, {
    required int? translationResourceId,
  }) {
    if (translationResourceId == null || data.verses.isEmpty) {
      return false;
    }

    for (final verse in data.verses) {
      final hasTranslation = verse.translations.any((translation) {
        final text = (translation.text ?? '').trim();
        if (text.isEmpty) {
          return false;
        }
        final resourceId = translation.resourceId;
        if (resourceId == null) {
          return true;
        }
        return resourceId == translationResourceId;
      });
      if (!hasTranslation) {
        return false;
      }
    }
    return true;
  }

  bool _hasWordTooltipData(MushafPageData data) {
    for (final word in data.words) {
      final charType = (word.charTypeName ?? '').trim().toLowerCase();
      if (charType != 'word') {
        continue;
      }
      final translation = (word.translationText ?? '').trim();
      final transliteration = (word.transliterationText ?? '').trim();
      if (translation.isNotEmpty || transliteration.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  MushafPageData _normalizeWordVerseKeys(MushafPageData data) {
    final allWordsHaveVerseKey = data.words.every(
      (word) => (word.verseKey ?? '').trim().isNotEmpty,
    );
    if (allWordsHaveVerseKey || data.verses.isEmpty) {
      return data;
    }

    final rebuiltWords = <MushafWord>[];
    final rebuiltVerses = <MushafVerseData>[];
    for (final verse in data.verses) {
      final normalizedVerseKey = verse.verseKey.trim();
      if (normalizedVerseKey.isEmpty) {
        return data;
      }

      final verseWords = <MushafWord>[
        for (final word in verse.words)
          _copyWordWithVerseKey(
            word: word,
            verseKey: normalizedVerseKey,
          ),
      ];
      rebuiltWords.addAll(verseWords);
      rebuiltVerses.add(
        MushafVerseData(
          verseKey: normalizedVerseKey,
          words: verseWords,
          codeV2: verse.codeV2,
          translations: verse.translations,
        ),
      );
    }

    if (rebuiltWords.length != data.words.length) {
      return data;
    }
    return MushafPageData(
      words: rebuiltWords,
      meta: data.meta,
      verses: rebuiltVerses,
    );
  }

  MushafWord _copyWordWithVerseKey({
    required MushafWord word,
    required String verseKey,
  }) {
    return MushafWord(
      verseKey: verseKey,
      codeV2: word.codeV2,
      textQpcHafs: word.textQpcHafs,
      translationText: word.translationText,
      transliterationText: word.transliterationText,
      charTypeName: word.charTypeName,
      lineNumber: word.lineNumber,
      position: word.position,
      pageNumber: word.pageNumber,
    );
  }

  Future<List<MushafJuzNavEntry>> _loadJuzIndexFromCacheOrNetwork({
    required int mushafId,
  }) async {
    final cacheFile = await _resolveJuzIndexCacheFile(mushafId: mushafId);
    final cached = await _readCachedJuzIndex(cacheFile);
    if (cached != null) {
      return cached;
    }

    final fetched = await _fetchJuzIndex(mushafId: mushafId);
    await _writeCacheAtomic(
        cacheFile,
        jsonEncode([
          for (final entry in fetched) entry.toJson(),
        ]));
    return fetched;
  }

  Future<List<MushafJuzNavEntry>?> _readCachedJuzIndex(File cacheFile) async {
    if (!await cacheFile.exists()) {
      return null;
    }

    try {
      final rawCache = await cacheFile.readAsString();
      final decoded = jsonDecode(rawCache);
      if (decoded is! List) {
        return null;
      }
      final entries = <MushafJuzNavEntry>[
        for (final item in decoded)
          if (item is Map<String, dynamic>) MushafJuzNavEntry.fromJson(item),
      ];
      if (entries.length != 30) {
        return null;
      }
      entries.sort((a, b) => a.juzNumber.compareTo(b.juzNumber));
      return entries;
    } catch (_) {
      return null;
    }
  }

  Future<List<MushafJuzNavEntry>> _fetchJuzIndex({
    required int mushafId,
  }) async {
    final entries = <MushafJuzNavEntry>[];
    for (var juzNumber = 1; juzNumber <= 30; juzNumber++) {
      final payload = await _fetchJuzNavPayload(
        mushafId: mushafId,
        juzNumber: juzNumber,
      );
      final entry = _parseJuzNavPayload(
        rawBody: payload,
        fallbackJuzNumber: juzNumber,
      );
      entries.add(entry);
    }

    entries.sort((a, b) => a.juzNumber.compareTo(b.juzNumber));
    return entries;
  }

  Future<MushafPageData> _loadPageFromCacheOrNetwork({
    required int page,
    required int mushafId,
    required int? translationResourceId,
  }) async {
    final cacheFile = await _resolveCacheFile(
      page: page,
      mushafId: mushafId,
      translationResourceId: translationResourceId,
    );
    final cached = await _readCachedPage(cacheFile);
    if (cached != null) {
      return cached;
    }
    return _fetchAndCachePage(
      page: page,
      mushafId: mushafId,
      translationResourceId: translationResourceId,
      cacheFile: cacheFile,
    );
  }

  Future<MushafPageData> _refreshPageFromNetwork({
    required int page,
    required int mushafId,
    required int? translationResourceId,
  }) async {
    final cacheFile = await _resolveCacheFile(
      page: page,
      mushafId: mushafId,
      translationResourceId: translationResourceId,
    );
    return _fetchAndCachePage(
      page: page,
      mushafId: mushafId,
      translationResourceId: translationResourceId,
      cacheFile: cacheFile,
    );
  }

  Future<MushafPageData?> _readCachedPage(File cacheFile) async {
    if (!await cacheFile.exists()) {
      return null;
    }

    try {
      final rawCache = await cacheFile.readAsString();
      final decoded = jsonDecode(rawCache);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid cache JSON root object.');
      }
      return MushafPageData.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<MushafPageData> _fetchAndCachePage({
    required int page,
    required int mushafId,
    required int? translationResourceId,
    required File cacheFile,
  }) async {
    final payload = await _fetchPagePayload(
      page: page,
      mushafId: mushafId,
      translationResourceId: translationResourceId,
    );
    final data = _parseApiPayload(payload);
    await _writeCacheAtomic(cacheFile, jsonEncode(data.toJson()));
    return data;
  }

  void _validatePageAndMushaf({
    required int page,
    required int mushafId,
  }) {
    if (page < 1 || page > 604) {
      throw QuranComApiException(
        'Invalid page number $page. Expected 1..604.',
      );
    }
    if (mushafId <= 0) {
      throw QuranComApiException('Invalid mushaf id $mushafId.');
    }
  }

  String _pageKey({
    required int page,
    required int mushafId,
    required int? translationResourceId,
  }) {
    final translationPart =
        translationResourceId == null ? 't0' : 't$translationResourceId';
    return '$page|$mushafId|$translationPart';
  }

  Future<File> _resolveCacheFile({
    required int page,
    required int mushafId,
    required int? translationResourceId,
  }) async {
    final cacheDir = await _resolveCacheDirectory();
    final translationSuffix =
        translationResourceId == null ? '' : '_t$translationResourceId';
    return File(
      _joinPath(
        cacheDir.path,
        'page_${page}_m$mushafId$translationSuffix.json',
      ),
    );
  }

  Future<File> _resolveJuzIndexCacheFile({
    required int mushafId,
  }) async {
    final cacheDir = await _resolveCacheDirectory();
    return File(_joinPath(cacheDir.path, 'juz_index_m$mushafId.json'));
  }

  Future<Directory> _resolveCacheDirectory() async {
    final supportDir = await _getSupportDirectory();
    final cacheDir = Directory(_joinPath(supportDir.path, 'qurancom_pages'));
    await cacheDir.create(recursive: true);
    return cacheDir;
  }

  Future<String> _fetchPagePayload({
    required int page,
    required int mushafId,
    required int? translationResourceId,
  }) async {
    final translationParams = translationResourceId == null
        ? ''
        : '&translations=$translationResourceId'
            '&translation_fields=resource_name,language_name,text';
    final uri = Uri.parse(
      '$_apiBase/verses/by_page/$page'
      '?words=true&mushaf=$mushafId'
      '&fields=verse_key,chapter_id,verse_number,page_number,juz_number,hizb_number,rub_el_hizb_number,code_v2'
      '&word_fields=verse_key,position,line_number,page_number,char_type_name,code_v2,text_qpc_hafs,translation,transliteration'
      '$translationParams',
    );

    return _fetchPayload(
      uri: uri,
      requestFailureMessage: 'Request failed for page $page.',
      attemptsFailureMessage:
          'Failed to fetch page $page after ${_retries + 1} attempts.',
    );
  }

  Future<String> _fetchJuzNavPayload({
    required int mushafId,
    required int juzNumber,
  }) async {
    final uri = Uri.parse(
      '$_apiBase/verses/by_juz/$juzNumber'
      '?mushaf=$mushafId'
      '&words=false'
      '&per_page=1'
      '&page=1'
      '&fields=verse_key,chapter_id,verse_number,page_number,juz_number,hizb_number,rub_el_hizb_number',
    );
    return _fetchPayload(
      uri: uri,
      requestFailureMessage: 'Request failed for juz $juzNumber.',
      attemptsFailureMessage:
          'Failed to fetch juz $juzNumber after ${_retries + 1} attempts.',
    );
  }

  Future<String> _fetchPayload({
    required Uri uri,
    required String requestFailureMessage,
    required String attemptsFailureMessage,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt <= _retries; attempt++) {
      try {
        final response = await _httpClient.get(uri);
        if (response.statusCode != HttpStatus.ok) {
          throw QuranComApiException(
            requestFailureMessage,
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
      attemptsFailureMessage,
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
    final firstVerseKey = _asString(firstVerse['verse_key']) ??
        _composeVerseKey(
          chapterId: _asInt(firstVerse['chapter_id']),
          verseNumber: _asInt(firstVerse['verse_number']),
        );
    final firstChapterId =
        _asInt(firstVerse['chapter_id']) ?? _chapterFromVerseKey(firstVerseKey);
    final firstVerseNumber = _asInt(firstVerse['verse_number']);
    final pageNumber = _asInt(firstVerse['page_number']);
    final juzNumber = _asInt(firstVerse['juz_number']);
    final hizbNumber = _asInt(firstVerse['hizb_number']);
    final rubElHizbNumber = _asInt(firstVerse['rub_el_hizb_number']);
    final meta = MushafPageMeta(
      firstChapterId: firstChapterId,
      firstVerseNumber: firstVerseNumber,
      firstVerseKey: firstVerseKey,
      pageNumber: pageNumber,
      juzNumber: juzNumber,
      hizbNumber: hizbNumber,
      rubElHizbNumber: rubElHizbNumber,
    );

    final words = <MushafWord>[];
    final verses = <MushafVerseData>[];
    for (final verse in versesRaw) {
      if (verse is! Map<String, dynamic>) {
        throw const QuranComApiException('Invalid verse entry in payload.');
      }

      final verseKey = _asString(verse['verse_key']) ??
          _composeVerseKey(
            chapterId: _asInt(verse['chapter_id']),
            verseNumber: _asInt(verse['verse_number']),
          );
      if (verseKey == null || verseKey.trim().isEmpty) {
        throw const QuranComApiException('Invalid verse key in payload.');
      }

      final wordsRaw = verse['words'];
      if (wordsRaw is! List) {
        throw const QuranComApiException(
            'Invalid words array in verse payload.');
      }

      final verseWords = <MushafWord>[];
      for (final word in wordsRaw) {
        if (word is! Map<String, dynamic>) {
          throw const QuranComApiException('Invalid word entry in payload.');
        }
        final parsedWord = MushafWord(
          verseKey: _asString(word['verse_key']) ?? verseKey,
          codeV2: _asString(word['code_v2']),
          textQpcHafs: _asString(word['text_qpc_hafs']),
          translationText: _asNestedText(word['translation']),
          transliterationText: _asNestedText(word['transliteration']),
          charTypeName: _asString(word['char_type_name']),
          lineNumber: _asInt(word['line_number']),
          position: _asInt(word['position']),
          pageNumber: _asInt(word['page_number']),
        );
        verseWords.add(parsedWord);
        words.add(parsedWord);
      }

      verses.add(
        MushafVerseData(
          verseKey: verseKey,
          words: verseWords,
          codeV2: _asString(verse['code_v2']),
          translations: _parseVerseTranslations(verse),
        ),
      );
    }

    return MushafPageData(
      words: words,
      meta: meta,
      verses: verses,
    );
  }

  MushafJuzNavEntry _parseJuzNavPayload({
    required String rawBody,
    required int fallbackJuzNumber,
  }) {
    final decoded = jsonDecode(rawBody);
    if (decoded is! Map<String, dynamic>) {
      throw const QuranComApiException('Invalid Quran.com payload root.');
    }

    final versesRaw = decoded['verses'];
    if (versesRaw is! List || versesRaw.isEmpty) {
      throw const QuranComApiException(
        'Invalid Quran.com payload: verses.',
      );
    }
    final firstVerse = versesRaw.first;
    if (firstVerse is! Map<String, dynamic>) {
      throw const QuranComApiException('Invalid first verse payload.');
    }

    final pageNumber = _asInt(firstVerse['page_number']);
    if (pageNumber == null || pageNumber < 1 || pageNumber > 604) {
      throw const QuranComApiException('Invalid page number in juz payload.');
    }

    final juzNumber = _asInt(firstVerse['juz_number']) ?? fallbackJuzNumber;
    final verseKey = _asString(firstVerse['verse_key']) ??
        _composeVerseKey(
          chapterId: _asInt(firstVerse['chapter_id']),
          verseNumber: _asInt(firstVerse['verse_number']),
        );

    return MushafJuzNavEntry(
      juzNumber: juzNumber,
      page: pageNumber,
      verseKey: verseKey,
    );
  }

  List<MushafVerseTranslation> _parseVerseTranslations(
    Map<String, dynamic> verse,
  ) {
    final translationsRaw = verse['translations'];
    if (translationsRaw is! List) {
      return const <MushafVerseTranslation>[];
    }

    final translations = <MushafVerseTranslation>[];
    for (final item in translationsRaw) {
      if (item is Map<String, dynamic>) {
        translations.add(MushafVerseTranslation.fromJson(item));
      }
    }
    return translations;
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

  String? _composeVerseKey({
    required int? chapterId,
    required int? verseNumber,
  }) {
    if (chapterId == null || verseNumber == null) {
      return null;
    }
    return '$chapterId:$verseNumber';
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

String? _asNestedText(dynamic value) {
  if (value is! Map) {
    return null;
  }
  return _asString(value['text']);
}

String _joinPath(String base, String leaf) {
  if (base.endsWith(Platform.pathSeparator)) {
    return '$base$leaf';
  }
  return '$base${Platform.pathSeparator}$leaf';
}
