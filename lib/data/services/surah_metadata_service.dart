import 'dart:convert';

import 'package:flutter/services.dart';

const String surahMetadataAssetPath = 'assets/quran/surah_metadata.json';

typedef _AssetTextLoader = Future<String> Function(String assetPath);

class SurahMetadataEntry {
  const SurahMetadataEntry({
    required this.number,
    required this.en,
    required this.ar,
    required this.fr,
    required this.pt,
  });

  final int number;
  final String en;
  final String ar;
  final String fr;
  final String pt;
}

class SurahMetadataService {
  SurahMetadataService({
    Future<String> Function(String assetPath)? loadAssetText,
  }) : _loadAssetText = loadAssetText ?? rootBundle.loadString;

  final _AssetTextLoader _loadAssetText;
  Map<int, SurahMetadataEntry>? _entriesByNumber;
  Future<void>? _loadOperation;

  Future<void> ensureLoaded() async {
    if (_entriesByNumber != null) {
      return;
    }

    _loadOperation ??= _loadInternal();
    try {
      await _loadOperation;
    } finally {
      if (_entriesByNumber == null) {
        _loadOperation = null;
      }
    }
  }

  SurahMetadataEntry? getByNumber(int number) => _entriesByNumber?[number];

  List<SurahMetadataEntry> getAll() {
    final entries = _entriesByNumber;
    if (entries == null) {
      return const <SurahMetadataEntry>[];
    }
    return entries.values.toList(growable: false)
      ..sort((a, b) => a.number.compareTo(b.number));
  }

  Future<void> _loadInternal() async {
    final rawJson = await _loadAssetText(surahMetadataAssetPath);
    _entriesByNumber = _parseSurahMetadata(rawJson);
  }
}

Map<int, SurahMetadataEntry> _parseSurahMetadata(String rawJson) {
  final decoded = jsonDecode(rawJson);
  if (decoded is! List) {
    throw const FormatException(
      'Invalid surah metadata format: expected top-level JSON array.',
    );
  }

  final entries = <int, SurahMetadataEntry>{};
  for (final item in decoded) {
    if (item is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid surah metadata entry: expected JSON object.',
      );
    }

    final number = _coerceInt(item['number'], field: 'number');
    if (number < 1 || number > 114) {
      throw FormatException('Invalid surah number: $number.');
    }
    if (entries.containsKey(number)) {
      throw FormatException('Duplicate surah metadata number: $number.');
    }

    entries[number] = SurahMetadataEntry(
      number: number,
      en: _coerceString(item['en'], field: 'en'),
      ar: _coerceString(item['ar'], field: 'ar'),
      fr: _coerceString(item['fr'], field: 'fr'),
      pt: _coerceString(item['pt'], field: 'pt'),
    );
  }

  return entries;
}

int _coerceInt(dynamic value, {required String field}) {
  if (value is int) {
    return value;
  }
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) {
      return parsed;
    }
  }
  throw FormatException('Invalid int value for "$field": $value');
}

String _coerceString(dynamic value, {required String field}) {
  if (value is String) {
    return value;
  }
  throw FormatException('Invalid string value for "$field": $value');
}
