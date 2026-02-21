import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/ui/tajweed/tajweed_markup.dart';

void main() {
  test('tokenizeTajweedHtml splits plain and tajweed segments', () {
    const html = 'بِسْمِ <tajweed class=ham_wasl>ٱ</tajweed>للَّهِ';

    final tokens = tokenizeTajweedHtml(html);

    expect(tokens.length, 3);
    expect(tokens[0].text, 'بِسْمِ ');
    expect(tokens[0].ruleClass, isNull);
    expect(tokens[1].text, 'ٱ');
    expect(tokens[1].ruleClass, 'ham_wasl');
    expect(tokens[2].text, 'للَّهِ');
    expect(tokens[2].ruleClass, isNull);
  });

  test('stripAllTags removes tajweed wrappers and end span', () {
    const html =
        'بِسْمِ <tajweed class=ham_wasl>ٱ</tajweed>للَّهِ <span class=end>١</span>';

    final stripped = stripAllTags(html);

    expect(stripped, 'بِسْمِ ٱللَّهِ ');
  });

  test('malformed tajweed markup falls back to stripped plain text', () {
    const html = 'abc <tajweed class=idgham>def';

    final tokens = tokenizeTajweedHtml(html);
    final spans = buildTajweedSpans(
      tajweedHtml: html,
      baseStyle: const TextStyle(fontSize: 20),
      classColors: const <String, Color>{},
      fallbackColor: const Color(0xFF111111),
    );

    expect(tokens.length, 1);
    expect(tokens[0].text, 'abc def');
    expect(tokens[0].ruleClass, isNull);
    expect(spans.length, 1);
    expect(spans.first.text, 'abc def');
  });
}
