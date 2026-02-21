import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:hifz_planner/data/services/tanzil_text_parser.dart';

const int _firstMadaniPage = 1;
const int _lastMadaniPage = 604;
const int _expectedVerseCount = 6236;
const String _outputAssetPath = 'assets/quran/tajweed_uthmani_tags.json';
const String _tanzilAssetPath = 'assets/quran/tanzil_uthmani.txt';

const Duration _retryDelay = Duration(seconds: 1);
const int _requestAttempts = 3;

final RegExp _verseKeyPattern = RegExp(r'^\d{1,3}:\d{1,3}$');
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

  final unknownArgs = args.where((arg) => arg != '--allow-mismatches').toList();
  if (unknownArgs.isNotEmpty) {
    stderr.writeln('Unknown arguments: ${unknownArgs.join(', ')}');
    _printUsage();
    exitCode = 64;
    return;
  }
  final allowMismatches = args.contains('--allow-mismatches');

  final config = _QfConfig.fromEnvironment();

  stdout.writeln('Fetching tajweed-tagged verses from QuranFoundation...');
  final token = await _fetchAccessToken(config);

  final tajweedByVerseKey = <String, String>{};
  for (var page = _firstMadaniPage; page <= _lastMadaniPage; page++) {
    final verses = await _fetchPageVerses(
      config: config,
      accessToken: token,
      pageNumber: page,
    );
    for (final verse in verses) {
      if (tajweedByVerseKey.containsKey(verse.verseKey)) {
        throw StateError(
            'Duplicate verse key from API data: ${verse.verseKey}');
      }
      tajweedByVerseKey[verse.verseKey] = verse.textUthmaniTajweed;
    }

    if (page == _firstMadaniPage || page % 50 == 0 || page == _lastMadaniPage) {
      stdout.writeln(
        'Fetched page $page of $_lastMadaniPage '
        '(${tajweedByVerseKey.length} verses collected).',
      );
    }
  }

  if (tajweedByVerseKey.length != _expectedVerseCount) {
    throw StateError(
      'Expected $_expectedVerseCount verse keys, found ${tajweedByVerseKey.length}.',
    );
  }

  final tanzilByVerseKey = await _loadTanzilMap();
  final mismatchReport = _validateAgainstTanzil(
    tajweedByVerseKey: tajweedByVerseKey,
    tanzilByVerseKey: tanzilByVerseKey,
  );

  stdout.writeln('Total keys: ${tajweedByVerseKey.length}');
  stdout.writeln('Mismatches: ${mismatchReport.count}');

  if (mismatchReport.samples.isNotEmpty) {
    stderr
        .writeln('Mismatch samples (first ${mismatchReport.samples.length}):');
    for (final sample in mismatchReport.samples) {
      stderr.writeln('- $sample');
    }
  }

  if (mismatchReport.count > 0 && !allowMismatches) {
    stderr.writeln(
      'Validation failed. Re-run with --allow-mismatches to write output anyway.',
    );
    exitCode = 1;
    return;
  }

  final orderedEntries = tajweedByVerseKey.entries.toList()
    ..sort((a, b) => _compareVerseKeys(a.key, b.key));
  final orderedMap = LinkedHashMap<String, String>.fromEntries(orderedEntries);
  final encodedJson =
      '${const JsonEncoder.withIndent('  ').convert(orderedMap)}\n';

  final outputFile = File(_outputAssetPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(encodedJson);

  stdout.writeln('Output written to ${outputFile.path}');
}

Future<String> _fetchAccessToken(_QfConfig config) async {
  return _withRetry(
    label: 'OAuth token request',
    action: () async {
      final client = HttpClient();
      try {
        final uri = Uri.parse('${config.authBaseUrl}/oauth2/token');
        final request = await client.postUrl(uri);
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Basic ${base64Encode(utf8.encode('${config.clientId}:${config.clientSecret}'))}',
        );
        request.headers.contentType = ContentType(
          'application',
          'x-www-form-urlencoded',
          charset: 'utf-8',
        );
        request.write('grant_type=client_credentials&scope=content');

        final response = await request.close();
        final body = await utf8.decoder.bind(response).join();
        if (response.statusCode != HttpStatus.ok) {
          throw HttpException(
            'OAuth request failed with ${response.statusCode}. '
            'Body snippet: ${_snippet(body)}',
            uri: uri,
          );
        }

        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Invalid OAuth response format.');
        }
        final token = decoded['access_token'];
        if (token is! String || token.isEmpty) {
          throw const FormatException('OAuth response missing access_token.');
        }
        return token;
      } finally {
        client.close(force: true);
      }
    },
  );
}

Future<List<_QfVerse>> _fetchPageVerses({
  required _QfConfig config,
  required String accessToken,
  required int pageNumber,
}) {
  return _withRetry(
    label: 'page $pageNumber',
    action: () async {
      final client = HttpClient();
      try {
        final uri = Uri.parse(
          '${config.apiBaseUrl}/content/api/v4/quran/verses/uthmani_tajweed'
          '?page_number=$pageNumber',
        );
        final request = await client.getUrl(uri);
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        request.headers.set('x-auth-token', accessToken);
        request.headers.set('x-client-id', config.clientId);

        final response = await request.close();
        final body = await utf8.decoder.bind(response).join();
        if (response.statusCode != HttpStatus.ok) {
          throw HttpException(
            'Page $pageNumber request failed with ${response.statusCode}. '
            'Body snippet: ${_snippet(body)}',
            uri: uri,
          );
        }

        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) {
          throw FormatException('Invalid JSON payload for page $pageNumber.');
        }
        final verses = decoded['verses'];
        if (verses is! List) {
          throw FormatException('Missing "verses" array for page $pageNumber.');
        }

        final pageVerses = <_QfVerse>[];
        for (final item in verses) {
          if (item is! Map<String, dynamic>) {
            throw FormatException('Invalid verse item on page $pageNumber.');
          }
          final verseKey = item['verse_key'];
          final tajweedText = item['text_uthmani_tajweed'];
          if (verseKey is! String || !_verseKeyPattern.hasMatch(verseKey)) {
            throw FormatException(
              'Invalid verse_key "$verseKey" on page $pageNumber.',
            );
          }
          if (tajweedText is! String) {
            throw FormatException(
              'Invalid text_uthmani_tajweed for key "$verseKey".',
            );
          }
          pageVerses.add(
            _QfVerse(
              verseKey: verseKey,
              textUthmaniTajweed: tajweedText,
            ),
          );
        }

        return pageVerses;
      } finally {
        client.close(force: true);
      }
    },
  );
}

Future<Map<String, String>> _loadTanzilMap() async {
  final file = File(_tanzilAssetPath);
  if (!await file.exists()) {
    throw StateError('Missing Tanzil asset: ${file.path}');
  }

  final rawText = await file.readAsString();
  final rows = parseTanzilText(rawText);
  if (rows.length != _expectedVerseCount) {
    throw StateError(
      'Expected $_expectedVerseCount Tanzil rows, found ${rows.length}.',
    );
  }

  final map = <String, String>{};
  for (final row in rows) {
    final key = '${row.surah}:${row.ayah}';
    if (!map.containsKey(key)) {
      map[key] = row.text;
      continue;
    }
    throw StateError('Duplicate verse key in Tanzil source: $key');
  }
  return map;
}

_MismatchReport _validateAgainstTanzil({
  required Map<String, String> tajweedByVerseKey,
  required Map<String, String> tanzilByVerseKey,
}) {
  final samples = <String>[];
  var mismatchCount = 0;

  for (final entry in tanzilByVerseKey.entries) {
    final tajweedText = tajweedByVerseKey[entry.key];
    if (tajweedText == null) {
      mismatchCount += 1;
      if (samples.length < 10) {
        samples.add('${entry.key}: missing tajweed text');
      }
      continue;
    }

    final stripped = _stripTajweedTagsForCompare(tajweedText);
    if (stripped != entry.value) {
      mismatchCount += 1;
      if (samples.length < 10) {
        samples.add(
          '${entry.key}: expected "${_snippet(entry.value)}", '
          'got "${_snippet(stripped)}"',
        );
      }
    }
  }

  for (final key in tajweedByVerseKey.keys) {
    if (tanzilByVerseKey.containsKey(key)) {
      continue;
    }
    mismatchCount += 1;
    if (samples.length < 10) {
      samples.add('$key: not found in Tanzil source');
    }
  }

  return _MismatchReport(count: mismatchCount, samples: samples);
}

String _stripTajweedTagsForCompare(String html) {
  final withoutEndMarkers = html.replaceAll(_endSpanPattern, '');
  return withoutEndMarkers.replaceAll(_allTagPattern, '');
}

Future<T> _withRetry<T>({
  required String label,
  required Future<T> Function() action,
}) async {
  Object? lastError;
  for (var attempt = 1; attempt <= _requestAttempts; attempt++) {
    try {
      return await action();
    } catch (error) {
      lastError = error;
      if (attempt >= _requestAttempts) {
        rethrow;
      }
      stderr.writeln(
        '$label failed on attempt $attempt of $_requestAttempts; retrying...',
      );
      await Future<void>.delayed(_retryDelay);
    }
  }

  throw StateError('$label failed: $lastError');
}

int _compareVerseKeys(String a, String b) {
  final aParts = a.split(':');
  final bParts = b.split(':');
  if (aParts.length != 2 || bParts.length != 2) {
    throw FormatException('Invalid verse key while sorting: "$a" or "$b".');
  }

  final aSurah = int.parse(aParts[0]);
  final aAyah = int.parse(aParts[1]);
  final bSurah = int.parse(bParts[0]);
  final bAyah = int.parse(bParts[1]);

  final surahOrder = aSurah.compareTo(bSurah);
  if (surahOrder != 0) {
    return surahOrder;
  }
  return aAyah.compareTo(bAyah);
}

String _snippet(String text, {int maxChars = 40}) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= maxChars) {
    return normalized;
  }
  return '${normalized.substring(0, maxChars)}...';
}

void _printUsage() {
  stdout.writeln(
    'Usage: dart run tooling/generate_tajweed_uthmani_tags.dart '
    '[--allow-mismatches]',
  );
}

class _QfConfig {
  const _QfConfig({
    required this.clientId,
    required this.clientSecret,
    required this.authBaseUrl,
    required this.apiBaseUrl,
  });

  final String clientId;
  final String clientSecret;
  final String authBaseUrl;
  final String apiBaseUrl;

  static _QfConfig fromEnvironment() {
    final clientId = Platform.environment['QF_CLIENT_ID']?.trim() ?? '';
    final clientSecret = Platform.environment['QF_CLIENT_SECRET']?.trim() ?? '';
    final env =
        (Platform.environment['QF_ENV']?.trim().toLowerCase() ?? 'prelive');

    if (clientId.isEmpty) {
      throw StateError('QF_CLIENT_ID is required.');
    }
    if (clientSecret.isEmpty) {
      throw StateError('QF_CLIENT_SECRET is required.');
    }

    if (env == 'production') {
      return _QfConfig(
        clientId: clientId,
        clientSecret: clientSecret,
        authBaseUrl: 'https://oauth2.quran.foundation',
        apiBaseUrl: 'https://apis.quran.foundation',
      );
    }

    return _QfConfig(
      clientId: clientId,
      clientSecret: clientSecret,
      authBaseUrl: 'https://prelive-oauth2.quran.foundation',
      apiBaseUrl: 'https://apis-prelive.quran.foundation',
    );
  }
}

class _QfVerse {
  const _QfVerse({
    required this.verseKey,
    required this.textUthmaniTajweed,
  });

  final String verseKey;
  final String textUthmaniTajweed;
}

class _MismatchReport {
  const _MismatchReport({
    required this.count,
    required this.samples,
  });

  final int count;
  final List<String> samples;
}
