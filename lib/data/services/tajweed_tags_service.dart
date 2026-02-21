import 'dart:convert';

import 'package:flutter/services.dart';

const String tajweedTagsAssetPath = 'assets/quran/tajweed_uthmani_tags.json';

final RegExp _verseKeyPattern = RegExp(r'^\d{1,3}:\d{1,3}$');

typedef _AssetTextLoader = Future<String> Function(String assetPath);

class TajweedTagsService {
  TajweedTagsService({
    Future<String> Function(String assetPath)? loadAssetText,
  }) : _loadAssetText = loadAssetText ?? rootBundle.loadString;

  final _AssetTextLoader _loadAssetText;
  Map<String, String>? _tagsByVerseKey;
  Future<void>? _loadOperation;

  bool get hasAnyTags => (_tagsByVerseKey?.isNotEmpty ?? false);

  Future<void> ensureLoaded() async {
    if (_tagsByVerseKey != null) {
      return;
    }

    _loadOperation ??= _loadInternal();
    try {
      await _loadOperation;
    } finally {
      if (_tagsByVerseKey == null) {
        _loadOperation = null;
      }
    }
  }

  String? getTajweedHtmlFor(int surah, int ayah) {
    final map = _tagsByVerseKey;
    if (map == null) {
      return null;
    }
    return map['$surah:$ayah'];
  }

  Future<void> _loadInternal() async {
    final rawJson = await _loadAssetText(tajweedTagsAssetPath);
    _tagsByVerseKey = _parseTagsJson(rawJson);
  }
}

Map<String, String> _parseTagsJson(String rawJson) {
  final decoded = jsonDecode(rawJson);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException(
      'Invalid tajweed tags format: expected top-level JSON object.',
    );
  }

  final map = <String, String>{};
  for (final entry in decoded.entries) {
    final key = entry.key.trim();
    if (!_verseKeyPattern.hasMatch(key)) {
      throw FormatException('Invalid verse key format: "$key".');
    }

    final value = entry.value;
    if (value is! String) {
      throw FormatException('Invalid tajweed tag value for "$key".');
    }

    map[key] = value;
  }

  return map;
}
