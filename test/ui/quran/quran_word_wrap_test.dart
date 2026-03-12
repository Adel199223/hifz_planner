import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/qurancom_api.dart';
import 'package:hifz_planner/ui/quran/quran_word_wrap.dart';

void main() {
  testWidgets('renders tooltip translation and suppresses end marker token',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuranWordWrap(
            words: const <MushafWord>[
              MushafWord(
                codeV2: 'A',
                textQpcHafs: 'A',
                translationText: 'All praise and thanks',
                charTypeName: 'word',
                lineNumber: 1,
                position: 1,
                pageNumber: 1,
              ),
              MushafWord(
                codeV2: '۝',
                textQpcHafs: '1',
                charTypeName: 'end',
                lineNumber: 1,
                position: 2,
                pageNumber: 1,
              ),
            ],
            qcfFamilyName: 'qcf_test_family',
            showWordHover: true,
            showTooltips: true,
            suppressEndMarkers: true,
            translationUnavailableText: 'Translation unavailable',
            wordTextKeyBuilder: (index, _) => ValueKey('test_word_$index'),
            wordTooltipKeyBuilder: (index, _) =>
                ValueKey('test_word_tooltip_$index'),
          ),
        ),
      ),
    );

    final tooltipFinder = find.byKey(const ValueKey('test_word_tooltip_0'));
    expect(tooltipFinder, findsOneWidget);
    expect(find.byKey(const ValueKey('test_word_1')), findsNothing);
    final tooltip = tester.widget<Tooltip>(tooltipFinder);
    expect(tooltip.message, 'All praise and thanks');
  });

  testWidgets('hover highlights active word', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuranWordWrap(
            words: const <MushafWord>[
              MushafWord(
                codeV2: '',
                textQpcHafs: 'ٱلْحَمْدُ',
                charTypeName: 'word',
                lineNumber: 1,
                position: 1,
                pageNumber: 1,
              ),
            ],
            qcfFamilyName: 'qcf_test_family',
            showWordHover: true,
            showTooltips: true,
            suppressEndMarkers: true,
            translationUnavailableText: 'Translation unavailable',
            wordTextKeyBuilder: (index, _) => ValueKey('hover_word_$index'),
          ),
        ),
      ),
    );

    final wordFinder = find.byKey(const ValueKey('hover_word_0'));
    expect(wordFinder, findsOneWidget);
    final beforeHoverColor = _wordHighlightColor(tester, wordFinder);
    expect(beforeHoverColor, isNull);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(wordFinder));
    await tester.pump();
    await mouse.moveTo(tester.getCenter(wordFinder));
    await tester.pumpAndSettle();

    final afterHoverColor = _wordHighlightColor(tester, wordFinder);
    expect(afterHoverColor, isNotNull);
    await mouse.removePointer();
  });

  testWidgets('disables tooltip and hover highlight when flags are false',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuranWordWrap(
            words: const <MushafWord>[
              MushafWord(
                codeV2: '',
                textQpcHafs: 'ٱلْحَمْدُ',
                translationText: 'All praise and thanks',
                charTypeName: 'word',
                lineNumber: 1,
                position: 1,
                pageNumber: 1,
              ),
            ],
            qcfFamilyName: 'qcf_test_family',
            showWordHover: false,
            showTooltips: false,
            suppressEndMarkers: true,
            translationUnavailableText: 'Translation unavailable',
            wordTextKeyBuilder: (index, _) => ValueKey('plain_word_$index'),
            wordTooltipKeyBuilder: (index, _) =>
                ValueKey('plain_word_tooltip_$index'),
          ),
        ),
      ),
    );

    final wordFinder = find.byKey(const ValueKey('plain_word_0'));
    expect(wordFinder, findsOneWidget);
    expect(find.byKey(const ValueKey('plain_word_tooltip_0')), findsNothing);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(wordFinder));
    await tester.pump();
    await mouse.moveTo(tester.getCenter(wordFinder));
    await tester.pumpAndSettle();

    final afterHoverColor = _wordHighlightColor(tester, wordFinder);
    expect(afterHoverColor, isNull);
    await mouse.removePointer();
  });
}

Color? _wordHighlightColor(WidgetTester tester, Finder wordFinder) {
  final containerFinder = find.ancestor(
    of: wordFinder,
    matching: find.byType(AnimatedContainer),
  );
  expect(containerFinder, findsWidgets);
  final container = tester.widget<AnimatedContainer>(containerFinder.first);
  final decoration = container.decoration;
  if (decoration is! BoxDecoration) {
    return null;
  }
  return decoration.color;
}
