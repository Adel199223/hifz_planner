import 'companion_models.dart';

class Stage1AutoCheckEvaluation {
  const Stage1AutoCheckEvaluation({
    required this.passed,
    required this.selectedOptionId,
    required this.normalizedSelected,
  });

  final bool passed;
  final String? selectedOptionId;
  final String normalizedSelected;
}

class Stage1AutoCheckEngine {
  const Stage1AutoCheckEngine();

  Stage1AutoCheckPrompt buildPrompt({
    required int sessionId,
    required int verseOrder,
    required int attemptIndex,
    required String attemptType,
    required Stage1Mode stage1Mode,
    required ChainVerse verse,
    required List<ChainVerse> chunkVerses,
  }) {
    final normalizedVerse = normalizeText(verse.text);
    final verseTokens = _tokenize(verse.text);
    if (verseTokens.isEmpty) {
      throw StateError(
        'Unable to build Stage-1 auto-check prompt for verse '
        '${verse.surah}:${verse.ayah}: no gradable tokens found.',
      );
    }

    final seed = _seed(
      sessionId: sessionId,
      verseOrder: verseOrder,
      attemptIndex: attemptIndex,
      attemptType: attemptType,
      stage1Mode: stage1Mode,
    );

    final availableTypes = <Stage1AutoCheckType>[
      if (verseTokens.length >= 2) Stage1AutoCheckType.nextWordMcq,
      Stage1AutoCheckType.oneWordCloze,
      if (verseTokens.length >= 3) Stage1AutoCheckType.ordering,
    ];
    final chosenType = availableTypes[seed % availableTypes.length];

    return switch (chosenType) {
      Stage1AutoCheckType.nextWordMcq => _buildNextWordMcq(
          verseTokens: verseTokens,
          chunkVerses: chunkVerses,
          verseOrder: verseOrder,
          seed: seed,
          normalizedVerse: normalizedVerse,
        ),
      Stage1AutoCheckType.oneWordCloze => _buildOneWordCloze(
          verseTokens: verseTokens,
          chunkVerses: chunkVerses,
          verseOrder: verseOrder,
          seed: seed,
          normalizedVerse: normalizedVerse,
        ),
      Stage1AutoCheckType.ordering => _buildOrdering(
          verseTokens: verseTokens,
          seed: seed,
          normalizedVerse: normalizedVerse,
        ),
    };
  }

  Stage1AutoCheckEvaluation evaluate({
    required Stage1AutoCheckPrompt prompt,
    required String? selectedOptionId,
  }) {
    if (selectedOptionId == null || selectedOptionId.trim().isEmpty) {
      return const Stage1AutoCheckEvaluation(
        passed: false,
        selectedOptionId: null,
        normalizedSelected: '',
      );
    }

    final selected = prompt.options
        .where((option) => option.id == selectedOptionId)
        .toList(growable: false);
    if (selected.isEmpty) {
      return Stage1AutoCheckEvaluation(
        passed: false,
        selectedOptionId: selectedOptionId,
        normalizedSelected: '',
      );
    }

    return Stage1AutoCheckEvaluation(
      passed: selectedOptionId == prompt.correctOptionId,
      selectedOptionId: selectedOptionId,
      normalizedSelected: normalizeText(selected.first.label),
    );
  }

  String normalizeText(String text) {
    final rawTokens = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((token) => token.trim().isNotEmpty);
    final normalized = <String>[];
    for (final token in rawTokens) {
      final cleaned = _normalizeToken(token);
      if (cleaned.isNotEmpty) {
        normalized.add(cleaned);
      }
    }
    return normalized.join(' ');
  }

  Stage1AutoCheckPrompt _buildNextWordMcq({
    required List<_TokenEntry> verseTokens,
    required List<ChainVerse> chunkVerses,
    required int verseOrder,
    required int seed,
    required String normalizedVerse,
  }) {
    final anchor = seed % (verseTokens.length - 1);
    final lead = verseTokens[anchor];
    final correct = verseTokens[anchor + 1];

    final distractors = _distractors(
      chunkVerses: chunkVerses,
      verseOrder: verseOrder,
      correct: correct.normalized,
      limit: 3,
    );
    final options =
        _buildOptions(seed: seed, correct: correct.display, distractors: distractors);

    return Stage1AutoCheckPrompt(
      type: Stage1AutoCheckType.nextWordMcq,
      stem: 'After "${lead.display}", what comes next?',
      options: options.options,
      correctOptionId: options.correctOptionId,
      normalizedPayload: normalizedVerse,
    );
  }

  Stage1AutoCheckPrompt _buildOneWordCloze({
    required List<_TokenEntry> verseTokens,
    required List<ChainVerse> chunkVerses,
    required int verseOrder,
    required int seed,
    required String normalizedVerse,
  }) {
    final index = seed % verseTokens.length;
    final target = verseTokens[index];
    final displayTokens = <String>[
      for (var i = 0; i < verseTokens.length; i++)
        if (i == index) '_____' else verseTokens[i].display,
    ];

    final distractors = _distractors(
      chunkVerses: chunkVerses,
      verseOrder: verseOrder,
      correct: target.normalized,
      limit: 3,
    );
    final options =
        _buildOptions(seed: seed, correct: target.display, distractors: distractors);

    return Stage1AutoCheckPrompt(
      type: Stage1AutoCheckType.oneWordCloze,
      stem: 'Fill the blank: ${displayTokens.join(' ')}',
      options: options.options,
      correctOptionId: options.correctOptionId,
      normalizedPayload: normalizedVerse,
    );
  }

  Stage1AutoCheckPrompt _buildOrdering({
    required List<_TokenEntry> verseTokens,
    required int seed,
    required String normalizedVerse,
  }) {
    final start = seed % (verseTokens.length - 2);
    final a = verseTokens[start].display;
    final b = verseTokens[start + 1].display;
    final c = verseTokens[start + 2].display;

    final optionsRaw = <String>[
      '$a $b $c',
      '$b $a $c',
      '$c $b $a',
    ];
    final deduped = <String>[];
    final seen = <String>{};
    for (final option in optionsRaw) {
      final normalized = normalizeText(option);
      if (normalized.isEmpty || seen.contains(normalized)) {
        continue;
      }
      seen.add(normalized);
      deduped.add(option);
    }

    final shuffled = _stableShuffle(
      values: deduped,
      seed: seed,
    );
    final options = <Stage1AutoCheckOption>[];
    var correctOptionId = '';
    for (var i = 0; i < shuffled.length; i++) {
      final id = 'o$i';
      options.add(Stage1AutoCheckOption(id: id, label: shuffled[i]));
      if (normalizeText(shuffled[i]) == normalizeText('$a $b $c')) {
        correctOptionId = id;
      }
    }

    return Stage1AutoCheckPrompt(
      type: Stage1AutoCheckType.ordering,
      stem: 'Pick the correct order:',
      options: options,
      correctOptionId: correctOptionId,
      normalizedPayload: normalizedVerse,
    );
  }

  List<String> _distractors({
    required List<ChainVerse> chunkVerses,
    required int verseOrder,
    required String correct,
    required int limit,
  }) {
    final collected = <String>[];
    final seen = <String>{correct};

    void collectFromVerse(ChainVerse verse) {
      final tokens = _tokenize(verse.text);
      for (final token in tokens) {
        if (token.normalized.isEmpty || seen.contains(token.normalized)) {
          continue;
        }
        seen.add(token.normalized);
        collected.add(token.display);
        if (collected.length >= limit) {
          return;
        }
      }
    }

    final localStart = verseOrder - 1;
    final localEnd = verseOrder + 1;
    for (var i = localStart; i <= localEnd; i++) {
      if (i < 0 || i >= chunkVerses.length || i == verseOrder) {
        continue;
      }
      collectFromVerse(chunkVerses[i]);
      if (collected.length >= limit) {
        return collected;
      }
    }

    for (var i = 0; i < chunkVerses.length; i++) {
      if (i >= localStart && i <= localEnd) {
        continue;
      }
      collectFromVerse(chunkVerses[i]);
      if (collected.length >= limit) {
        return collected;
      }
    }

    return collected;
  }

  _OptionPack _buildOptions({
    required int seed,
    required String correct,
    required List<String> distractors,
  }) {
    final raw = <String>[correct, ...distractors];
    final deduped = <String>[];
    final seen = <String>{};
    for (final option in raw) {
      final normalized = normalizeText(option);
      if (normalized.isEmpty || seen.contains(normalized)) {
        continue;
      }
      seen.add(normalized);
      deduped.add(option);
    }

    final shuffled = _stableShuffle(values: deduped, seed: seed);
    final options = <Stage1AutoCheckOption>[];
    var correctOptionId = '';
    final normalizedCorrect = normalizeText(correct);
    for (var i = 0; i < shuffled.length; i++) {
      final id = 'o$i';
      options.add(Stage1AutoCheckOption(id: id, label: shuffled[i]));
      if (normalizeText(shuffled[i]) == normalizedCorrect && correctOptionId.isEmpty) {
        correctOptionId = id;
      }
    }

    if (correctOptionId.isEmpty) {
      correctOptionId = options.first.id;
    }

    return _OptionPack(
      options: options,
      correctOptionId: correctOptionId,
    );
  }

  int _seed({
    required int sessionId,
    required int verseOrder,
    required int attemptIndex,
    required String attemptType,
    required Stage1Mode stage1Mode,
  }) {
    var hash = 17;
    hash = _combine(hash, sessionId);
    hash = _combine(hash, verseOrder);
    hash = _combine(hash, attemptIndex);
    hash = _combine(hash, _stringHash(attemptType));
    hash = _combine(hash, _stringHash(stage1Mode.code));
    return hash.abs();
  }

  int _combine(int current, int value) {
    return 0x1fffffff & ((current * 31) + value);
  }

  int _stringHash(String value) {
    var hash = 13;
    for (final unit in value.codeUnits) {
      hash = _combine(hash, unit);
    }
    return hash;
  }

  List<String> _stableShuffle({
    required List<String> values,
    required int seed,
  }) {
    final indexed = <_IndexedString>[];
    for (var i = 0; i < values.length; i++) {
      final rank = _combine(seed, i * 37 + values[i].length);
      indexed.add(_IndexedString(value: values[i], rank: rank));
    }
    indexed.sort((a, b) {
      final rankCompare = a.rank.compareTo(b.rank);
      if (rankCompare != 0) {
        return rankCompare;
      }
      return a.value.compareTo(b.value);
    });
    return indexed.map((row) => row.value).toList(growable: false);
  }

  List<_TokenEntry> _tokenize(String text) {
    final tokens = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((token) => token.trim().isNotEmpty);
    final out = <_TokenEntry>[];
    for (final token in tokens) {
      final normalized = _normalizeToken(token);
      if (normalized.isEmpty) {
        continue;
      }
      out.add(_TokenEntry(display: token, normalized: normalized));
    }
    return out;
  }

  String _normalizeToken(String token) {
    var value = token;
    value = value.replaceAll('\u0671', '\u0627');
    value = value.replaceAll('\u0649', '\u064A');
    value = value.replaceAll(
      RegExp('\u0639[\u064B-\u0652]?\u0670'),
      '\u0639\u0627',
    );
    value = value.replaceAll(_diacriticsRegex, '');
    value = value.replaceAll(_ayahMarkerRegex, '');
    value = value.replaceAll(_nonWordRegex, '');
    value = value.replaceAll(RegExp(r'\s+'), '');
    return value.trim();
  }

  static final RegExp _diacriticsRegex =
      RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]');
  static final RegExp _ayahMarkerRegex =
      RegExp(r'[\u06DD\u06DE\u06E9\u06DF\u06E0\u06E1\u06E2\u06E3\u06E4\u06E5\u06E6]');
  static final RegExp _nonWordRegex =
      RegExp(r'[^\u0621-\u063A\u0641-\u066F\u0671-\u06D3\u06FA-\u06FFa-zA-Z0-9]');
}

class _OptionPack {
  const _OptionPack({
    required this.options,
    required this.correctOptionId,
  });

  final List<Stage1AutoCheckOption> options;
  final String correctOptionId;
}

class _TokenEntry {
  const _TokenEntry({
    required this.display,
    required this.normalized,
  });

  final String display;
  final String normalized;
}

class _IndexedString {
  const _IndexedString({
    required this.value,
    required this.rank,
  });

  final String value;
  final int rank;
}
