import 'dart:convert';

import 'package:flutter/services.dart';

const String madaniPageIndexAssetPath =
    'assets/quran/page_index_madani_hafs.json';
const int madaniPageCount = 604;

final RegExp _verseKeyPattern = RegExp(r'^(\d{1,3}):(\d{1,3})$');

String verseKey(int surahNumber, int ayahNumber) => '$surahNumber:$ayahNumber';

Future<Map<String, int>> loadMadaniPageIndex({
  AssetBundle? bundle,
}) async {
  final resolvedBundle = bundle ?? rootBundle;
  final rawJson = await resolvedBundle.loadString(madaniPageIndexAssetPath);
  return parseMadaniPageIndexJson(rawJson);
}

Map<String, int> parseMadaniPageIndexJson(String rawJson) {
  final decoded = jsonDecode(rawJson);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException(
      'Invalid page index format: expected top-level JSON object.',
    );
  }

  final result = <String, int>{};
  for (final entry in decoded.entries) {
    final key = entry.key.trim();
    final match = _verseKeyPattern.firstMatch(key);
    if (match == null) {
      throw FormatException('Invalid verse key format: "$key".');
    }

    final surahNumber = int.parse(match.group(1)!);
    final ayahNumber = int.parse(match.group(2)!);
    if (surahNumber < 1 || surahNumber > 114 || ayahNumber < 1) {
      throw FormatException('Invalid verse key values: "$key".');
    }

    final page = _coercePageNumber(entry.value, key: key);
    if (page < 1 || page > madaniPageCount) {
      throw FormatException(
        'Page number out of range for "$key": $page.',
      );
    }

    result[verseKey(surahNumber, ayahNumber)] = page;
  }

  return result;
}

void debugValidateMadaniPageCoverage({
  required Map<String, int> pageIndex,
  required Iterable<String> appVerseKeys,
  int? expectedVerseCount,
}) {
  assert(() {
    final providedKeys = appVerseKeys.toList(growable: false);
    final uniqueKeys = providedKeys.toSet();

    if (uniqueKeys.length != providedKeys.length) {
      throw AssertionError('Duplicate verse keys found in app verse list.');
    }

    if (expectedVerseCount != null && uniqueKeys.length != expectedVerseCount) {
      throw AssertionError(
        'Expected $expectedVerseCount app verse keys, found ${uniqueKeys.length}.',
      );
    }

    final missing = <String>[];
    for (final key in uniqueKeys) {
      if (!pageIndex.containsKey(key)) {
        missing.add(key);
      }
    }

    if (missing.isNotEmpty) {
      final sample = missing.take(5).join(', ');
      throw AssertionError(
        'Missing page mapping for ${missing.length} verses. Sample: $sample',
      );
    }

    if (uniqueKeys.isEmpty) {
      throw AssertionError('App verse key list is empty.');
    }

    final pages =
        uniqueKeys.map((key) => pageIndex[key]!).toList(growable: false);
    final minPage = pages.reduce((a, b) => a < b ? a : b);
    final maxPage = pages.reduce((a, b) => a > b ? a : b);
    if (minPage != 1 || maxPage != madaniPageCount) {
      throw AssertionError(
        'Mapped page bounds are $minPage..$maxPage, expected 1..$madaniPageCount.',
      );
    }

    return true;
  }());
}

int _coercePageNumber(
  dynamic value, {
  required String key,
}) {
  if (value is int) {
    return value;
  }
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) {
      return parsed;
    }
  }

  throw FormatException('Invalid page value for "$key": "$value".');
}
