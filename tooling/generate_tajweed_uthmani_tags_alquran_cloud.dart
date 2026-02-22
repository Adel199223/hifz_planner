import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:hifz_planner/data/services/tanzil_text_parser.dart'
    as tanzil_parser;

const int expectedVerseCount = 6236;
const String outputAssetPath = 'assets/quran/tajweed_uthmani_tags.json';
const String tanzilAssetPath = 'assets/quran/tanzil_uthmani.txt';

const List<String> _endpointPriority = <String>[
  'https://api.alquran.cloud/v1/quran/quran-tajweed',
  'https://alquran.api.islamic.network/v1/quran/quran-tajweed',
  'http://api.alquran.cloud/v1/quran/quran-tajweed',
];

const Map<String, String> _markerTypeToClass = <String, String>{
  'h': 'ham_wasl',
  'l': 'laam_shamsiyah',
  'n': 'madda_normal',
  'p': 'madda_permissible',
  'm': 'madda_obligatory',
  'o': 'madda_obligatory',
  'q': 'qalqalah',
  'c': 'ikhfa',
  'f': 'iqlab',
  'w': 'idgham',
};

final RegExp _endSpanPattern = RegExp(
  r'''<span\b[^>]*\bclass\s*=\s*(?:"end"|'end'|end)[^>]*>.*?<\/span>''',
  caseSensitive: false,
  dotAll: true,
);
final RegExp _allTagPattern = RegExp(r'<[^>]+>', dotAll: true);

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final allowMismatches = args.contains('--allow-mismatches');
  final unknownArgs = args.where((arg) => arg != '--allow-mismatches').toList();
  if (unknownArgs.isNotEmpty) {
    stderr.writeln('Unknown args: ${unknownArgs.join(', ')}');
    _printUsage();
    exitCode = 64;
    return;
  }

  final tanzilMap = await loadTanzilVerseMap();
  if (tanzilMap.length != expectedVerseCount) {
    throw StateError(
      'Expected $expectedVerseCount Tanzil verses, found ${tanzilMap.length}.',
    );
  }

  final fetchResult = await _fetchTajweedFromEndpoints();
  final actualHtmlByKey = fetchResult.verseHtmlByKey;
  final comparison = _compareVerseMaps(
    expectedByKey: tanzilMap,
    actualHtmlByKey: actualHtmlByKey,
  );

  _printSummary(fetchResult.endpointUsed, comparison);
  _printMismatchDebugIfNeeded(
    comparison: comparison,
    expectedByKey: tanzilMap,
    actualHtmlByKey: actualHtmlByKey,
  );

  final destination = File(outputAssetPath);
  final payload = buildOutputJson(actualHtmlByKey);

  if (comparison.normalizedMismatched > 0 && !allowMismatches) {
    stderr.writeln(
      'Validation failed in strict mode: normalized_mismatched='
      '${comparison.normalizedMismatched}. Output not written.',
    );
    exitCode = 1;
    return;
  }

  if (comparison.normalizedMismatched > 0 && allowMismatches) {
    stderr.writeln(
      'WARNING: Writing output with mismatches. normalized_mismatched='
      '${comparison.normalizedMismatched}, '
      'match_rate_normalized=${comparison.normalizedMatchRate.toStringAsFixed(6)}',
    );
  }

  await writeFileAtomically(destination, payload);
  stdout.writeln('Wrote ${destination.path}');
}

Future<_FetchResult> _fetchTajweedFromEndpoints() async {
  Object? lastError;

  for (final endpoint in _endpointPriority) {
    try {
      final raw = await _fetchEndpointBody(endpoint);
      final verseHtmlByKey = parseAlQuranCloudPayload(raw);
      if (verseHtmlByKey.length != expectedVerseCount) {
        throw StateError(
          'Endpoint $endpoint returned ${verseHtmlByKey.length} verses '
          '(expected $expectedVerseCount).',
        );
      }
      return _FetchResult(
        endpointUsed: endpoint,
        verseHtmlByKey: verseHtmlByKey,
      );
    } catch (error) {
      lastError = error;
      stderr.writeln('Endpoint failed: $endpoint\n$error');
    }
  }

  throw StateError('All endpoints failed. Last error: $lastError');
}

Future<String> _fetchEndpointBody(String endpoint) async {
  final uri = Uri.parse(endpoint);
  final client = HttpClient();
  try {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final request = await client.getUrl(uri);
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final response = await request.close();
        final body = await utf8.decoder.bind(response).join();
        if (response.statusCode != HttpStatus.ok) {
          throw HttpException(
            'HTTP ${response.statusCode} from $endpoint: ${_short(body)}',
            uri: uri,
          );
        }
        return body;
      } catch (error) {
        lastError = error;
        if (attempt == 2) {
          rethrow;
        }
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
    throw StateError('Unreachable fetch state: $lastError');
  } finally {
    client.close(force: true);
  }
}

Map<String, String> parseAlQuranCloudPayload(String rawJson) {
  final decoded = jsonDecode(rawJson);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Invalid endpoint payload root object.');
  }

  final data = decoded['data'];
  if (data is! Map<String, dynamic>) {
    throw const FormatException('Endpoint payload missing data object.');
  }

  final surahs = data['surahs'];
  if (surahs is! List) {
    throw const FormatException('Endpoint payload missing data.surahs list.');
  }

  final byKey = <String, String>{};
  for (final surah in surahs) {
    if (surah is! Map<String, dynamic>) {
      continue;
    }
    final surahNumber = _asInt(surah['number']);
    if (surahNumber == null) {
      continue;
    }
    final ayahs = surah['ayahs'];
    if (ayahs is! List) {
      continue;
    }

    for (final ayah in ayahs) {
      if (ayah is! Map<String, dynamic>) {
        continue;
      }
      final ayahNumber = _asInt(ayah['numberInSurah']);
      final text = ayah['text'];
      if (ayahNumber == null || text is! String) {
        continue;
      }
      final key = '$surahNumber:$ayahNumber';
      if (byKey.containsKey(key)) {
        throw StateError('Duplicate verse key from endpoint payload: $key');
      }
      byKey[key] = convertTajweedMarkersToHtml(text);
    }
  }

  return byKey;
}

Future<Map<String, String>> loadTanzilVerseMap() async {
  final file = File(tanzilAssetPath);
  if (!await file.exists()) {
    throw StateError('Missing Tanzil file: ${file.path}');
  }
  final rows = tanzil_parser.parseTanzilText(await file.readAsString());
  final byKey = <String, String>{};
  for (final row in rows) {
    final key = '${row.surah}:${row.ayah}';
    if (byKey.containsKey(key)) {
      throw StateError('Duplicate Tanzil verse key: $key');
    }
    byKey[key] = row.text;
  }
  return byKey;
}

String convertTajweedMarkersToHtml(String source) {
  final out = StringBuffer();
  var index = 0;
  while (index < source.length) {
    final codeUnit = source.codeUnitAt(index);
    if (codeUnit != 0x5B) {
      out.writeCharCode(codeUnit);
      index += 1;
      continue;
    }

    final marker = _tryParseMarker(source, index);
    if (marker == null) {
      out.write('[');
      index += 1;
      continue;
    }

    final mappedClass = _markerTypeToClass[marker.type.toLowerCase()];
    if (marker.text.isEmpty) {
      index = marker.endIndexExclusive;
      continue;
    }
    if (mappedClass == null) {
      out.write(marker.text);
      index = marker.endIndexExclusive;
      continue;
    }

    out.write('<tajweed class=$mappedClass>');
    out.write(marker.text);
    out.write('</tajweed>');
    index = marker.endIndexExclusive;
  }

  return out.toString();
}

_MarkerMatch? _tryParseMarker(String source, int startIndex) {
  if (source.codeUnitAt(startIndex) != 0x5B) {
    return null;
  }

  var cursor = startIndex + 1;
  if (cursor >= source.length) {
    return null;
  }

  final typeStart = cursor;
  while (cursor < source.length) {
    final unit = source.codeUnitAt(cursor);
    final isUpper = unit >= 0x41 && unit <= 0x5A;
    final isLower = unit >= 0x61 && unit <= 0x7A;
    if (!isUpper && !isLower) {
      break;
    }
    cursor += 1;
  }
  if (cursor == typeStart) {
    return null;
  }
  final type = source.substring(typeStart, cursor);

  if (cursor < source.length && source.codeUnitAt(cursor) == 0x3A) {
    cursor += 1;
    final digitsStart = cursor;
    while (cursor < source.length) {
      final unit = source.codeUnitAt(cursor);
      if (unit < 0x30 || unit > 0x39) {
        break;
      }
      cursor += 1;
    }
    if (cursor == digitsStart) {
      return null;
    }
  }

  if (cursor >= source.length || source.codeUnitAt(cursor) != 0x5B) {
    return null;
  }
  cursor += 1;
  final textStart = cursor;
  final closingIndex = source.indexOf(']', textStart);
  if (closingIndex < 0) {
    return null;
  }

  return _MarkerMatch(
    type: type,
    text: source.substring(textStart, closingIndex),
    endIndexExclusive: closingIndex + 1,
  );
}

String stripAllTags(String html) {
  final withoutEndMarkers = html.replaceAll(_endSpanPattern, '');
  return withoutEndMarkers.replaceAll(_allTagPattern, '');
}

String normalizeForCompare(String input) {
  return tanzil_parser.normalizeForCompare(input);
}

String normalizeForCompareLoose(String input) {
  return tanzil_parser.normalizeForCompareLoose(input);
}

_ComparisonStats _compareVerseMaps({
  required Map<String, String> expectedByKey,
  required Map<String, String> actualHtmlByKey,
}) {
  var strictMatched = 0;
  var normalizedMatched = 0;
  var looseMatched = 0;
  _MismatchSample? firstNormalizedMismatch;

  for (final entry in expectedByKey.entries) {
    final actualHtml = actualHtmlByKey[entry.key];
    final expectedText = entry.value;
    final actualPlain = actualHtml == null ? '' : stripAllTags(actualHtml);

    final strictEqual = actualHtml != null && expectedText == actualPlain;
    final normalizedEqual = actualHtml != null &&
        normalizeForCompare(expectedText) == normalizeForCompare(actualPlain);
    final looseEqual = actualHtml != null &&
        normalizeForCompareLoose(expectedText) ==
            normalizeForCompareLoose(actualPlain);

    if (strictEqual) {
      strictMatched += 1;
    }
    if (normalizedEqual) {
      normalizedMatched += 1;
    }
    if (looseEqual) {
      looseMatched += 1;
    }
    if (!normalizedEqual && firstNormalizedMismatch == null) {
      firstNormalizedMismatch = _MismatchSample(
        verseKey: entry.key,
        expected: expectedText,
        actual: actualPlain,
      );
    }
  }

  return _ComparisonStats(
    total: expectedVerseCount,
    strictMatched: strictMatched,
    strictMismatched: expectedVerseCount - strictMatched,
    normalizedMatched: normalizedMatched,
    normalizedMismatched: expectedVerseCount - normalizedMatched,
    looseMatched: looseMatched,
    looseMismatched: expectedVerseCount - looseMatched,
    firstNormalizedMismatch: firstNormalizedMismatch,
  );
}

String buildOutputJson(Map<String, String> htmlByVerseKey) {
  final orderedEntries = htmlByVerseKey.entries.toList()
    ..sort((a, b) => _compareVerseKeys(a.key, b.key));
  final orderedMap = LinkedHashMap<String, String>.fromEntries(orderedEntries);
  return '${const JsonEncoder.withIndent('  ').convert(orderedMap)}\n';
}

Future<void> writeFileAtomically(File destination, String content) async {
  await destination.parent.create(recursive: true);
  final tempPath =
      '${destination.path}.tmp_${DateTime.now().microsecondsSinceEpoch}';
  final tempFile = File(tempPath);
  await tempFile.writeAsString(content, flush: true);
  if (await destination.exists()) {
    await destination.delete();
  }
  await tempFile.rename(destination.path);
}

void _printSummary(String endpointUsed, _ComparisonStats stats) {
  stdout.writeln('endpoint_used=$endpointUsed');
  stdout.writeln('total=$expectedVerseCount');
  stdout.writeln(
    'strict_matched=${stats.strictMatched} / '
    'strict_mismatched=${stats.strictMismatched}',
  );
  stdout.writeln(
    'normalized_matched=${stats.normalizedMatched} / '
    'normalized_mismatched=${stats.normalizedMismatched}',
  );
  stdout.writeln(
    'loose_matched=${stats.looseMatched} / '
    'loose_mismatched=${stats.looseMismatched}',
  );
  stdout.writeln(
    'match_rate_normalized=${stats.normalizedMatchRate.toStringAsFixed(6)}',
  );
}

void _printMismatchDebugIfNeeded({
  required _ComparisonStats comparison,
  required Map<String, String> expectedByKey,
  required Map<String, String> actualHtmlByKey,
}) {
  if (comparison.normalizedMismatched == 0) {
    return;
  }

  final first = comparison.firstNormalizedMismatch;
  if (first != null) {
    stderr.writeln('first_mismatch_key=${first.verseKey}');
    stderr.writeln(
      'expected_codepoints=${firstCodepointsAsInts(first.expected).join(',')}',
    );
    stderr.writeln(
      'actual_codepoints=${firstCodepointsAsInts(first.actual).join(',')}',
    );
  }

  for (final key in const <String>['1:1', '2:1', '3:1', '4:1', '9:1']) {
    final expected = expectedByKey[key];
    final actual = actualHtmlByKey[key];
    if (expected == null) {
      continue;
    }
    final actualPlain = actual == null ? '<missing>' : stripAllTags(actual);
    stderr.writeln('debug_$key expected="${_short(expected, maxChars: 80)}"');
    stderr.writeln('debug_$key actual="${_short(actualPlain, maxChars: 80)}"');
  }
}

List<int> firstCodepointsAsInts(String input, {int count = 80}) {
  final values = <int>[];
  for (final rune in input.runes) {
    values.add(rune);
    if (values.length >= count) {
      break;
    }
  }
  return values;
}

int _compareVerseKeys(String a, String b) {
  final aParts = a.split(':');
  final bParts = b.split(':');
  if (aParts.length != 2 || bParts.length != 2) {
    return a.compareTo(b);
  }
  final aSurah = int.tryParse(aParts[0]) ?? 0;
  final aAyah = int.tryParse(aParts[1]) ?? 0;
  final bSurah = int.tryParse(bParts[0]) ?? 0;
  final bAyah = int.tryParse(bParts[1]) ?? 0;
  final surahCompare = aSurah.compareTo(bSurah);
  if (surahCompare != 0) {
    return surahCompare;
  }
  return aAyah.compareTo(bAyah);
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

String _short(String text, {int maxChars = 60}) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= maxChars) {
    return normalized;
  }
  return '${normalized.substring(0, maxChars)}...';
}

void _printUsage() {
  stdout.writeln(
    'Usage: dart run tooling/generate_tajweed_uthmani_tags_alquran_cloud.dart '
    '[--allow-mismatches]',
  );
}

class _FetchResult {
  const _FetchResult({
    required this.endpointUsed,
    required this.verseHtmlByKey,
  });

  final String endpointUsed;
  final Map<String, String> verseHtmlByKey;
}

class _MarkerMatch {
  const _MarkerMatch({
    required this.type,
    required this.text,
    required this.endIndexExclusive,
  });

  final String type;
  final String text;
  final int endIndexExclusive;
}

class _MismatchSample {
  const _MismatchSample({
    required this.verseKey,
    required this.expected,
    required this.actual,
  });

  final String verseKey;
  final String expected;
  final String actual;
}

class _ComparisonStats {
  const _ComparisonStats({
    required this.total,
    required this.strictMatched,
    required this.strictMismatched,
    required this.normalizedMatched,
    required this.normalizedMismatched,
    required this.looseMatched,
    required this.looseMismatched,
    required this.firstNormalizedMismatch,
  });

  final int total;
  final int strictMatched;
  final int strictMismatched;
  final int normalizedMatched;
  final int normalizedMismatched;
  final int looseMatched;
  final int looseMismatched;
  final _MismatchSample? firstNormalizedMismatch;

  double get normalizedMatchRate => total == 0 ? 0 : normalizedMatched / total;
}
