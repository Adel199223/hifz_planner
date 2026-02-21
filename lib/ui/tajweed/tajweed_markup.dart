import 'package:flutter/material.dart';

final RegExp _endSpanPattern = RegExp(
  r'''<span\b[^>]*\bclass\s*=\s*(?:"end"|'end'|end)[^>]*>.*?<\/span>''',
  caseSensitive: false,
  dotAll: true,
);
final RegExp _allTagPattern = RegExp(r'<[^>]+>', dotAll: true);
final RegExp _tajweedTagPattern = RegExp(
  r'<tajweed\b([^>]*)>(.*?)<\/tajweed>',
  caseSensitive: false,
  dotAll: true,
);
final RegExp _tajweedOpenPattern = RegExp(
  r'<tajweed\b[^>]*>',
  caseSensitive: false,
);
final RegExp _tajweedClosePattern = RegExp(
  r'<\/tajweed>',
  caseSensitive: false,
);
final RegExp _leftoverTajweedPattern = RegExp(
  r'<\/?tajweed\b',
  caseSensitive: false,
);
final RegExp _classAttributePattern = RegExp(
  r'''class\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))''',
  caseSensitive: false,
);

class TajweedToken {
  const TajweedToken({
    required this.text,
    this.ruleClass,
  });

  final String text;
  final String? ruleClass;
}

String stripAllTags(String html) {
  final withoutEndMarkers = html.replaceAll(_endSpanPattern, '');
  return withoutEndMarkers.replaceAll(_allTagPattern, '');
}

List<TajweedToken> tokenizeTajweedHtml(String html) {
  final withoutEndMarkers = html.replaceAll(_endSpanPattern, '');
  final openTagCount = _tajweedOpenPattern.allMatches(withoutEndMarkers).length;
  final closeTagCount =
      _tajweedClosePattern.allMatches(withoutEndMarkers).length;
  if (openTagCount != closeTagCount) {
    return _plainFallbackTokens(withoutEndMarkers);
  }

  final tokens = <TajweedToken>[];
  var cursor = 0;

  for (final match in _tajweedTagPattern.allMatches(withoutEndMarkers)) {
    if (match.start < cursor) {
      continue;
    }

    final leading = withoutEndMarkers.substring(cursor, match.start);
    final leadingText = stripAllTags(leading);
    if (leadingText.isNotEmpty) {
      tokens.add(TajweedToken(text: leadingText));
    }

    final attrs = match.group(1) ?? '';
    final innerText = stripAllTags(match.group(2) ?? '');
    if (innerText.isNotEmpty) {
      tokens.add(
        TajweedToken(
          text: innerText,
          ruleClass: _parseClassName(attrs),
        ),
      );
    }

    cursor = match.end;
  }

  final trailing = withoutEndMarkers.substring(cursor);
  final trailingText = stripAllTags(trailing);
  if (trailingText.isNotEmpty) {
    tokens.add(TajweedToken(text: trailingText));
  }

  final leftover =
      withoutEndMarkers.replaceAll(_tajweedTagPattern, '').toLowerCase();
  if (_leftoverTajweedPattern.hasMatch(leftover)) {
    return _plainFallbackTokens(withoutEndMarkers);
  }

  if (tokens.isEmpty && withoutEndMarkers.isNotEmpty) {
    return _plainFallbackTokens(withoutEndMarkers);
  }

  return tokens;
}

List<TextSpan> buildTajweedSpans({
  required String tajweedHtml,
  required TextStyle baseStyle,
  required Map<String, Color> classColors,
  required Color fallbackColor,
}) {
  final tokens = tokenizeTajweedHtml(tajweedHtml);
  if (tokens.isEmpty) {
    final plain = stripAllTags(tajweedHtml);
    return <TextSpan>[
      TextSpan(
        text: plain,
        style: baseStyle.copyWith(color: fallbackColor),
      ),
    ];
  }

  return <TextSpan>[
    for (final token in tokens)
      TextSpan(
        text: token.text,
        style: baseStyle.copyWith(
          color: token.ruleClass == null
              ? fallbackColor
              : (classColors[token.ruleClass] ?? fallbackColor),
        ),
      ),
  ];
}

List<TajweedToken> _plainFallbackTokens(String html) {
  final plain = stripAllTags(html);
  if (plain.isEmpty) {
    return const <TajweedToken>[];
  }
  return <TajweedToken>[TajweedToken(text: plain)];
}

String? _parseClassName(String attrs) {
  final match = _classAttributePattern.firstMatch(attrs);
  if (match == null) {
    return null;
  }

  final rawClass =
      (match.group(1) ?? match.group(2) ?? match.group(3) ?? '').trim();
  if (rawClass.isEmpty) {
    return null;
  }
  return rawClass;
}
