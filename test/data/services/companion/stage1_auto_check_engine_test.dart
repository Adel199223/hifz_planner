import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/companion/companion_models.dart';
import 'package:hifz_planner/data/services/companion/stage1_auto_check_engine.dart';

void main() {
  const engine = Stage1AutoCheckEngine();

  const chunk = <ChainVerse>[
    ChainVerse(
      surah: 1,
      ayah: 1,
      text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    ),
    ChainVerse(
      surah: 1,
      ayah: 2,
      text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    ),
    ChainVerse(
      surah: 1,
      ayah: 3,
      text: 'الرَّحْمَٰنِ الرَّحِيمِ',
    ),
  ];

  test('buildPrompt is deterministic for identical seed inputs', () {
    final first = engine.buildPrompt(
      sessionId: 42,
      verseOrder: 1,
      attemptIndex: 3,
      attemptType: 'probe',
      stage1Mode: Stage1Mode.coldProbe,
      verse: chunk[1],
      chunkVerses: chunk,
    );
    final second = engine.buildPrompt(
      sessionId: 42,
      verseOrder: 1,
      attemptIndex: 3,
      attemptType: 'probe',
      stage1Mode: Stage1Mode.coldProbe,
      verse: chunk[1],
      chunkVerses: chunk,
    );

    expect(first.type, second.type);
    expect(first.stem, second.stem);
    expect(first.correctOptionId, second.correctOptionId);
    expect(first.normalizedPayload, second.normalizedPayload);
    expect(
      first.options.map((entry) => '${entry.id}:${entry.label}').toList(),
      second.options.map((entry) => '${entry.id}:${entry.label}').toList(),
    );
  });

  test('seed varies prompt layout across attempts and sessions', () {
    final signatures = <String>{};
    for (final sessionId in <int>[42, 43]) {
      for (final attemptIndex in <int>[1, 2, 3, 4]) {
        final prompt = engine.buildPrompt(
          sessionId: sessionId,
          verseOrder: 1,
          attemptIndex: attemptIndex,
          attemptType: 'probe',
          stage1Mode: Stage1Mode.coldProbe,
          verse: chunk[1],
          chunkVerses: chunk,
        );
        signatures.add(
          '${prompt.type.code}|${prompt.correctOptionId}|${prompt.options.map((option) => option.label).join("|")}',
        );
      }
    }

    expect(signatures.length, greaterThan(1));
  });

  test('normalization strips Arabic markers/diacritics and punctuation', () {
    final normalized = engine.normalizeText(
      'الرَّحْمَٰنِ۝،  الرَّحِيمِ!',
    );
    expect(normalized, 'الرحمن الرحيم');
  });

  test('normalization handles Uthmani/Hafs forms without empty artifacts', () {
    final normalized = engine.normalizeText(
      'ٱلْحَمْدُ۝ لِلَّهِۖ رَبِّىَ ٱلْعَٰلَمِينَ',
    );

    expect(normalized, 'الحمد لله ربي العالمين');
  });

  test('prompt options never include junk placeholder values', () {
    final prompt = engine.buildPrompt(
      sessionId: 7,
      verseOrder: 0,
      attemptIndex: 1,
      attemptType: 'checkpoint',
      stage1Mode: Stage1Mode.checkpoint,
      verse: chunk[0],
      chunkVerses: chunk,
    );

    expect(prompt.options, isNotEmpty);
    expect(
      prompt.options.any((option) => option.label.trim() == '...'),
      isFalse,
    );
    expect(
      prompt.options
          .every((option) => engine.normalizeText(option.label).isNotEmpty),
      isTrue,
    );
  });

  test('evaluate returns pass only for selected correct option', () {
    final prompt = engine.buildPrompt(
      sessionId: 55,
      verseOrder: 2,
      attemptIndex: 2,
      attemptType: 'spaced_reprobe',
      stage1Mode: Stage1Mode.spacedReprobe,
      verse: chunk[2],
      chunkVerses: chunk,
    );

    final correct = engine.evaluate(
      prompt: prompt,
      selectedOptionId: prompt.correctOptionId,
    );
    expect(correct.passed, isTrue);
    expect(correct.selectedOptionId, prompt.correctOptionId);
    expect(correct.normalizedSelected, isNotEmpty);

    expect(prompt.options.length, greaterThan(1));
    final wrongOption = prompt.options
        .firstWhere((option) => option.id != prompt.correctOptionId);
    final wrong = engine.evaluate(
      prompt: prompt,
      selectedOptionId: wrongOption.id,
    );
    expect(wrong.passed, isFalse);
  });
}
