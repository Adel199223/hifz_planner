import 'dart:collection';
import 'dart:convert';
import 'dart:io';

const String _sourceUrl =
    'https://raw.githubusercontent.com/hamzakat/madani-muhsaf-json/main/madani-muhsaf.json';
const String _outputPath = 'assets/quran/page_index_madani_hafs.json';
const int _firstPage = 1;
const int _lastPage = 604;
const int _expectedVerseCount = 6236;

Future<void> main() async {
  final rawJson = await _downloadSourceJson();
  final decoded = jsonDecode(rawJson);
  if (decoded is! List) {
    throw const FormatException('Expected top-level JSON array.');
  }

  final verseToPage = <String, int>{};
  for (var page = _firstPage; page <= _lastPage; page++) {
    if (page >= decoded.length) {
      throw FormatException(
        'Dataset ended early. Missing page index $page.',
      );
    }

    final pageEntry = decoded[page];
    if (pageEntry is! Map) {
      throw FormatException(
        'Expected page entry at index $page to be an object.',
      );
    }

    for (final entry in pageEntry.entries) {
      final surahNumber = int.tryParse(entry.key.toString());
      if (surahNumber == null) {
        continue;
      }

      final surahPayload = entry.value;
      if (surahPayload is! Map) {
        throw FormatException(
          'Surah payload for page $page key "${entry.key}" is not an object.',
        );
      }

      final chapterNumber = _asInt(
        surahPayload['chapterNumber'],
        context: 'page $page key "${entry.key}" chapterNumber',
      );
      if (chapterNumber != surahNumber) {
        throw FormatException(
          'chapterNumber mismatch at page $page key "${entry.key}". '
          'Found $chapterNumber.',
        );
      }

      final verses = surahPayload['text'];
      if (verses is! List) {
        throw FormatException(
          'Missing/invalid "text" list for Surah $surahNumber on page $page.',
        );
      }

      for (final verse in verses) {
        if (verse is! Map) {
          throw FormatException(
            'Invalid verse entry for Surah $surahNumber on page $page.',
          );
        }

        final ayahNumber = _asInt(
          verse['verseNumber'],
          context: 'Surah $surahNumber verseNumber on page $page',
        );
        final key = '$surahNumber:$ayahNumber';
        if (verseToPage.containsKey(key)) {
          throw StateError('Duplicate verse key detected: $key');
        }
        verseToPage[key] = page;
      }
    }
  }

  _validateOutput(verseToPage);

  final orderedEntries = verseToPage.entries.toList()
    ..sort((a, b) => _compareVerseKeys(a.key, b.key));
  final orderedMap = LinkedHashMap<String, int>.fromEntries(orderedEntries);
  final jsonText =
      '${const JsonEncoder.withIndent('  ').convert(orderedMap)}\n';

  final file = File(_outputPath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(jsonText);

  stdout.writeln('Generated ${orderedMap.length} mappings.');
  stdout.writeln('Output: ${file.path}');
}

Future<String> _downloadSourceJson() async {
  Object? lastError;
  for (var attempt = 1; attempt <= 3; attempt++) {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(_sourceUrl));
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Failed to download source JSON. HTTP ${response.statusCode}.',
          uri: Uri.parse(_sourceUrl),
        );
      }
      return await response.transform(utf8.decoder).join();
    } catch (error) {
      lastError = error;
      if (attempt == 3) {
        rethrow;
      }
      stderr.writeln('Download attempt $attempt failed. Retrying...');
      await Future<void>.delayed(const Duration(seconds: 1));
    } finally {
      client.close(force: true);
    }
  }

  throw StateError('Unable to download source JSON: $lastError');
}

int _asInt(dynamic value, {required String context}) {
  if (value is int) {
    return value;
  }
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) {
      return parsed;
    }
  }
  throw FormatException('Expected integer for $context, got "$value".');
}

void _validateOutput(Map<String, int> verseToPage) {
  if (verseToPage.length != _expectedVerseCount) {
    throw StateError(
      'Expected $_expectedVerseCount unique verse keys, '
      'found ${verseToPage.length}.',
    );
  }

  if (verseToPage.isEmpty) {
    throw StateError('Generated mapping is empty.');
  }

  final pages = verseToPage.values.toList(growable: false);
  final minPage = pages.reduce((a, b) => a < b ? a : b);
  final maxPage = pages.reduce((a, b) => a > b ? a : b);
  if (minPage != _firstPage || maxPage != _lastPage) {
    throw StateError(
      'Page range must be $_firstPage..$_lastPage, got $minPage..$maxPage.',
    );
  }
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
