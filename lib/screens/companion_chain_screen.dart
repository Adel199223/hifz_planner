import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_preferences.dart';
import '../data/database/app_database.dart';
import '../data/providers/database_providers.dart';
import '../data/services/ayah_audio_service.dart';
import '../data/services/companion/companion_models.dart';
import '../data/services/companion/progressive_reveal_chain_engine.dart';
import '../data/services/companion/verse_evaluator.dart';
import '../data/services/quran_wording.dart';
import '../data/services/qurancom_api.dart';
import '../l10n/app_strings.dart';
import '../ui/quran/arabic_ayah_text.dart';
import '../ui/quran/quran_word_wrap.dart';
import '../ui/qcf/qcf_font_manager.dart';

class CompanionChainScreen extends ConsumerStatefulWidget {
  const CompanionChainScreen({
    super.key,
    required this.unitId,
    required this.launchMode,
  });

  final int unitId;
  final CompanionLaunchMode launchMode;

  @override
  ConsumerState<CompanionChainScreen> createState() =>
      _CompanionChainScreenState();
}

class _CompanionChainScreenState extends ConsumerState<CompanionChainScreen> {
  ChainRunState? _state;
  ChainResultSummary? _summary;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isChangingStage = false;
  bool _tajweedEnabled = true;
  String? _lastAutoRecitedVerseKey;
  String? _error;
  final Map<String, _CompanionVerseWordRenderData> _wordRenderDataByVerseKey =
      <String, _CompanionVerseWordRenderData>{};

  AppStrings get _strings =>
      AppStrings.of(ref.read(appPreferencesProvider).language);

  ProgressiveRevealChainEngine get _engine =>
      ref.read(progressiveRevealChainEngineProvider);

  VerseEvaluator get _evaluator =>
      ref.read(manualFallbackVerseEvaluatorProvider);

  @override
  void initState() {
    super.initState();
    _loadChain();
  }

  Future<void> _loadChain() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _lastAutoRecitedVerseKey = null;
      _wordRenderDataByVerseKey.clear();
    });

    try {
      final memUnitRepo = ref.read(memUnitRepoProvider);
      final quranRepo = ref.read(quranRepoProvider);
      final tajweedService = ref.read(tajweedTagsServiceProvider);

      final unit = await memUnitRepo.get(widget.unitId);
      if (unit == null) {
        throw StateError('Memorization unit not found.');
      }

      final startSurah = unit.startSurah;
      final startAyah = unit.startAyah;
      final endSurah = unit.endSurah;
      final endAyah = unit.endAyah;
      if (startSurah == null ||
          startAyah == null ||
          endSurah == null ||
          endAyah == null) {
        throw StateError('Unit has no ayah range.');
      }

      bool tajweedEnabled = true;
      try {
        await tajweedService.ensureLoaded();
        if (!tajweedService.hasAnyTags) {
          tajweedEnabled = false;
        }
      } catch (_) {
        tajweedEnabled = false;
      }

      final ayahs = await quranRepo.getAyahsInRange(
        startSurah: startSurah,
        startAyah: startAyah,
        endSurah: endSurah,
        endAyah: endAyah,
      );
      if (ayahs.isEmpty) {
        throw StateError('No ayahs found for this unit.');
      }

      final verses = [
        for (final ayah in ayahs)
          ChainVerse(
            surah: ayah.surah,
            ayah: ayah.ayah,
            text: ayah.textUthmani,
          ),
      ];

      final state = await _engine.startSession(
        unitId: widget.unitId,
        verses: verses,
        launchMode: widget.launchMode,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _state = state;
        _isLoading = false;
        _tajweedEnabled = tajweedEnabled;
        _summary = null;
      });
      unawaited(_loadWordRenderData(ayahs));
      unawaited(_maybeAutoplayCurrentVerse(state, force: true));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  String _verseKey(ChainVerse verse) => '${verse.surah}:${verse.ayah}';

  bool get _companionAutoplayEnabled =>
      ref.read(appPreferencesProvider).companionAutoReciteEnabled;

  Future<void> _loadWordRenderData(List<AyahData> ayahs) async {
    final translationResourceId = translationResourceIdForLanguage(
      ref.read(appPreferencesProvider).language,
    );
    final quranComApi = ref.read(quranComApiProvider);
    final qcfFontManager = ref.read(qcfFontManagerProvider);
    final pageFamilyFutureByPage = <int, Future<String?>>{};

    Future<String?> resolvePageFamilyName(int page) {
      return pageFamilyFutureByPage.putIfAbsent(page, () async {
        try {
          final selection = await qcfFontManager.ensurePageFont(
            page: page,
            variant: QcfFontVariant.v4tajweed,
          );
          return selection.familyName;
        } catch (_) {
          return null;
        }
      });
    }

    final loaded = <String, _CompanionVerseWordRenderData>{};
    for (final ayah in ayahs) {
      final page = ayah.pageMadina;
      if (page == null || page < 1 || page > 604) {
        continue;
      }

      final verseKey = '${ayah.surah}:${ayah.ayah}';
      try {
        final familyName = await resolvePageFamilyName(page);
        if (familyName == null || familyName.trim().isEmpty) {
          continue;
        }
        final verseData = await quranComApi.getVerseDataByPage(
          page: page,
          mushafId: 19,
          verseKey: verseKey,
          translationResourceId: translationResourceId,
        );
        if (verseData.words.isEmpty) {
          continue;
        }
        loaded[verseKey] = _CompanionVerseWordRenderData(
          qcfFamilyName: familyName,
          words: verseData.words,
        );
      } catch (_) {
        // Word-level rendering is optional in Companion. Keep fallback stable.
      }
    }

    if (!mounted || loaded.isEmpty) {
      return;
    }
    setState(() {
      _wordRenderDataByVerseKey.addAll(loaded);
    });
  }

  bool _isPlayingCurrentAyah(ChainRunState state, AyahAudioState? audioState) {
    final activeAyah = audioState?.currentAyah;
    return audioState?.isPlaying == true &&
        activeAyah != null &&
        activeAyah.surah == state.currentVerse.verse.surah &&
        activeAyah.ayah == state.currentVerse.verse.ayah;
  }

  String _audioErrorText(Object error) {
    final raw = error.toString().trim();
    if (raw.isEmpty) {
      return _strings.unknown;
    }
    if (error is MissingPluginException ||
        raw.contains('MissingPluginException')) {
      return _strings.audioPluginUnavailable;
    }
    final normalized = raw.toLowerCase();
    if (normalized.contains('socketexception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('timed out')) {
      return _strings.audioNetworkError;
    }
    return raw;
  }

  Future<void> _playVerseAudio(
    ChainVerse verse, {
    bool markAsAuto = false,
  }) async {
    try {
      await ref
          .read(ayahAudioServiceProvider)
          .playAyah(verse.surah, verse.ayah);
      _lastAutoRecitedVerseKey = _verseKey(verse);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(_strings.audioLoadFailed(_audioErrorText(error)));
      if (!markAsAuto) {
        _lastAutoRecitedVerseKey = null;
      }
    }
  }

  Future<void> _toggleCurrentAyahPlayback(ChainRunState state) async {
    final audioState = ref.read(ayahAudioStateProvider).asData?.value;
    if (_isPlayingCurrentAyah(state, audioState)) {
      try {
        await ref.read(ayahAudioServiceProvider).pause();
      } catch (error) {
        if (!mounted) {
          return;
        }
        _showSnackBar(_strings.audioLoadFailed(_audioErrorText(error)));
      }
      return;
    }
    await _playVerseAudio(state.currentVerse.verse);
  }

  Future<void> _setCompanionAutoplayEnabled(bool value) async {
    await ref
        .read(appPreferencesProvider.notifier)
        .setCompanionAutoReciteEnabled(value);
    if (!value) {
      return;
    }
    final state = _state;
    if (state == null || state.completed) {
      return;
    }
    await _maybeAutoplayCurrentVerse(state, force: true);
  }

  Future<void> _maybeAutoplayCurrentVerse(
    ChainRunState state, {
    required bool force,
  }) async {
    if (!_companionAutoplayEnabled || state.completed) {
      return;
    }

    final currentVerse = state.currentVerse.verse;
    final verseKey = _verseKey(currentVerse);
    if (!force && _lastAutoRecitedVerseKey == verseKey) {
      return;
    }

    final audioState = ref.read(ayahAudioStateProvider).asData?.value;
    if (!force &&
        audioState?.isPlaying == true &&
        audioState?.currentAyah?.surah == currentVerse.surah &&
        audioState?.currentAyah?.ayah == currentVerse.ayah) {
      _lastAutoRecitedVerseKey = verseKey;
      return;
    }

    await _playVerseAudio(
      currentVerse,
      markAsAuto: true,
    );
  }

  Future<void> _recordAttempt() async {
    final state = _state;
    if (state == null || state.completed || _isSubmitting || _isChangingStage) {
      return;
    }

    final result = await _pickManualResult();
    if (result == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final update = await _engine.submitAttempt(
        state: state,
        evaluator: _evaluator,
        manualFallbackPass: result,
        latencyToStartMs: 800,
        stopsCount: 0,
        selfCorrectionsCount: 0,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _state = update.state;
        _summary = update.summary ?? _summary;
        _isSubmitting = false;
      });
      unawaited(_maybeAutoplayCurrentVerse(update.state, force: false));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
      });
      _showSnackBar(_strings.companionFailedToSaveAttempt(error.toString()));
    }
  }

  Future<void> _skipCurrentStage() async {
    final state = _state;
    if (state == null ||
        state.completed ||
        state.activeStage == CompanionStage.hiddenReveal ||
        _isChangingStage ||
        _isSubmitting) {
      return;
    }

    final confirmed = await _confirmSkipStage(state.activeStage);
    if (!confirmed) {
      return;
    }

    setState(() {
      _isChangingStage = true;
    });

    try {
      final updated = await _engine.skipCurrentStage(state: state);
      if (!mounted) {
        return;
      }
      setState(() {
        _state = updated;
        _isChangingStage = false;
      });
      unawaited(_maybeAutoplayCurrentVerse(updated, force: false));
      _showSnackBar(_strings.companionStageSkipped);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isChangingStage = false;
      });
      _showSnackBar(_strings.companionFailedToSaveAttempt(error.toString()));
    }
  }

  Future<bool> _confirmSkipStage(CompanionStage stage) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_strings.companionSkipStageTitle),
          content: Text(
            _strings.companionSkipStageBody(_stageLabel(stage)),
          ),
          actions: [
            TextButton(
              key: const ValueKey('companion_skip_stage_cancel'),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(_strings.cancel),
            ),
            FilledButton(
              key: const ValueKey('companion_skip_stage_confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(_strings.companionSkipStageConfirm),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<bool?> _pickManualResult() {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const ValueKey('companion_mark_correct'),
                leading: const Icon(Icons.check_circle_outline),
                title: Text(_strings.companionMarkCorrect),
                onTap: () => Navigator.of(context).pop(true),
              ),
              ListTile(
                key: const ValueKey('companion_mark_incorrect'),
                leading: const Icon(Icons.cancel_outlined),
                title: Text(_strings.companionMarkIncorrect),
                onTap: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        );
      },
    );
  }

  void _requestHint() {
    final state = _state;
    if (state == null || state.completed) {
      return;
    }
    setState(() {
      _state = _engine.requestHint(state);
    });
  }

  void _repeatCurrent() {
    _showSnackBar(_strings.companionRepeatPrompt);
  }

  void _manualNext() {
    final state = _state;
    if (state == null || state.completed) {
      return;
    }
    final current = state.currentVerse;
    if (!current.passedForStage(state.activeStage)) {
      return;
    }

    for (var i = 0; i < state.verses.length; i++) {
      if (!state.verses[i].passedForStage(state.activeStage)) {
        final nextState = state.copyWith(
          currentVerseIndex: i,
          currentHintLevel: _baselineHint(state.activeStage),
          returnVerseIndex: null,
        );
        setState(() {
          _state = nextState;
        });
        unawaited(_maybeAutoplayCurrentVerse(nextState, force: false));
        return;
      }
    }
  }

  HintLevel _baselineHint(CompanionStage stage) {
    return switch (stage) {
      CompanionStage.guidedVisible => HintLevel.h0,
      CompanionStage.cuedRecall => HintLevel.firstWord,
      CompanionStage.hiddenReveal => HintLevel.h0,
    };
  }

  HintLevel _effectiveHintLevel(ChainRunState state) {
    final baseline = _baselineHint(state.activeStage);
    if (state.currentHintLevel.order < baseline.order) {
      return baseline;
    }
    return state.currentHintLevel;
  }

  String _hintText(ChainRunState state) {
    final verseText = state.currentVerse.verse.text;
    final words = verseText
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final hintLevel = _effectiveHintLevel(state);

    return switch (hintLevel) {
      HintLevel.h0 => _strings.companionHintLevelH0,
      HintLevel.letters => _lettersHint(verseText),
      HintLevel.firstWord =>
        words.isEmpty ? _strings.companionHintUnavailable : words.first,
      HintLevel.meaningCue => _strings.companionTafsirCuePlaceholder,
      HintLevel.chunkText => _chunkHint(verseText),
      HintLevel.fullText => verseText,
    };
  }

  String _lettersHint(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), '');
    if (compact.isEmpty) {
      return _strings.companionHintUnavailable;
    }
    final prefixLength = compact.length < 4 ? compact.length : 4;
    final prefix = compact.substring(0, prefixLength);
    return '$prefix...';
  }

  String _chunkHint(String text) {
    if (text.isEmpty) {
      return _strings.companionHintUnavailable;
    }
    final splitAt = (text.length / 2).ceil();
    return '${text.substring(0, splitAt)}...';
  }

  String _firstWordCue(String text) {
    final words = text
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) {
      return _strings.companionHintUnavailable;
    }
    return '${words.first} ...';
  }

  String _positionLabel(ChainRunState state) {
    return _strings.companionCurrentVersePosition(
      state.currentVerseIndex + 1,
      state.totalVerses,
    );
  }

  String _stageLabel(CompanionStage stage) {
    return switch (stage) {
      CompanionStage.guidedVisible => _strings.companionStageGuidedVisible,
      CompanionStage.cuedRecall => _strings.companionStageCuedRecall,
      CompanionStage.hiddenReveal => _strings.companionStageHiddenReveal,
    };
  }

  String _stageStatusText(ChainRunState state, ChainVerseState verse) {
    return switch (state.activeStage) {
      CompanionStage.guidedVisible => verse.passedGuidedVisible
          ? _strings.companionVersePassed
          : _strings.companionStageGuidedVisible,
      CompanionStage.cuedRecall => verse.passedCuedRecall
          ? _strings.companionVersePassed
          : _strings.companionStageCuedRecall,
      CompanionStage.hiddenReveal => verse.passed
          ? _strings.companionVersePassed
          : verse.revealed
              ? _strings.companionVerseRevealed
              : _strings.companionVerseHidden,
    };
  }

  String? _verseBodyText(ChainRunState state, ChainVerseState verse) {
    return switch (state.activeStage) {
      CompanionStage.guidedVisible => verse.verse.text,
      CompanionStage.cuedRecall => verse.passedCuedRecall
          ? verse.verse.text
          : _firstWordCue(verse.verse.text),
      CompanionStage.hiddenReveal => verse.revealed ? verse.verse.text : null,
    };
  }

  bool _isFullVerseVisible(ChainRunState state, ChainVerseState verse) {
    return switch (state.activeStage) {
      CompanionStage.guidedVisible => true,
      CompanionStage.cuedRecall => verse.passedCuedRecall,
      CompanionStage.hiddenReveal => verse.revealed,
    };
  }

  String? _tajweedHtmlFor(ChainVerse verse) {
    if (!_tajweedEnabled) {
      return null;
    }
    final service = ref.read(tajweedTagsServiceProvider);
    return service.getTajweedHtmlFor(verse.surah, verse.ayah);
  }

  Widget? _buildVerseBody(ChainRunState state, ChainVerseState verse) {
    final bodyText = _verseBodyText(state, verse);
    if (bodyText == null) {
      return null;
    }

    if (_isFullVerseVisible(state, verse)) {
      final renderData = _wordRenderDataByVerseKey[_verseKey(verse.verse)];
      if (renderData != null) {
        final verseKey = _verseKey(verse.verse);
        return QuranWordWrap(
          key: ValueKey('companion_word_wrap_$verseKey'),
          words: renderData.words,
          qcfFamilyName: renderData.qcfFamilyName,
          showWordHover: true,
          showTooltips: true,
          suppressEndMarkers: true,
          preserveQcfTextColorOnHover: true,
          translationUnavailableText: _strings.translationUnavailable,
          wordTextKeyBuilder: (wordIndex, _) {
            return ValueKey('companion_word_${verseKey}_$wordIndex');
          },
          wordTooltipKeyBuilder: (wordIndex, _) {
            return ValueKey('companion_word_tooltip_${verseKey}_$wordIndex');
          },
          baseStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'UthmanicHafs',
                fontSize: 30,
                height: 1.6,
              ),
        );
      }

      return ArabicAyahText(
        text: bodyText,
        tajweedHtml: _tajweedHtmlFor(verse.verse),
        tajweedEnabled: _tajweedEnabled,
        textAlign: TextAlign.right,
      );
    }

    return Text(
      bodyText,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
    );
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<String>>(ayahAudioErrorProvider, (previous, next) {
      next.whenData((message) {
        final trimmed = message.trim();
        if (trimmed.isEmpty || !mounted) {
          return;
        }
        _showSnackBar(_strings.audioLoadFailed(trimmed));
      });
    });

    final preferences = ref.watch(appPreferencesProvider);
    final autoplayEnabled = preferences.companionAutoReciteEnabled;
    final audioState = ref.watch(ayahAudioStateProvider).asData?.value;
    final state = _state;

    if (_isLoading) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _loadChain,
                  child: Text(_strings.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state == null) {
      return SafeArea(
        child: Center(
          child: Text(_strings.companionNoSessionState),
        ),
      );
    }

    final isPlayingCurrentAyah = _isPlayingCurrentAyah(state, audioState);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _strings.companionProgressiveRevealTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _positionLabel(state),
              key: const ValueKey('companion_position_label'),
            ),
            const SizedBox(height: 8),
            Text(
              _strings.companionStageProgress(
                state.activeStage.stageNumber,
                CompanionStage.values.length,
              ),
              key: const ValueKey('companion_stage_progress'),
            ),
            const SizedBox(height: 4),
            Text(
              _stageLabel(state.activeStage),
              key: const ValueKey('companion_stage_label'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.icon(
                  key: const ValueKey('companion_play_ayah_button'),
                  onPressed: state.completed
                      ? null
                      : () => _toggleCurrentAyahPlayback(state),
                  icon: Icon(
                    isPlayingCurrentAyah ? Icons.pause : Icons.play_arrow,
                  ),
                  label: Text(
                    isPlayingCurrentAyah
                        ? _strings.pause
                        : _strings.companionPlayCurrentAyah,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _strings.companionAutoplayNextAyah,
                        key: const ValueKey('companion_autoplay_label'),
                      ),
                      const SizedBox(width: 6),
                      Switch.adaptive(
                        key: const ValueKey('companion_autoplay_toggle'),
                        value: autoplayEnabled,
                        onChanged: state.completed
                            ? null
                            : (value) =>
                                unawaited(_setCompanionAutoplayEnabled(value)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (state.activeStage != CompanionStage.hiddenReveal &&
                !state.completed) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                key: const ValueKey('companion_skip_stage_button'),
                onPressed: (_isChangingStage || _isSubmitting)
                    ? null
                    : _skipCurrentStage,
                child: Text(_strings.companionSkipStageButton),
              ),
            ],
            const SizedBox(height: 12),
            for (var i = 0; i < state.verses.length; i++)
              _buildVerseTile(
                context: context,
                state: state,
                index: i,
              ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_strings.companionActiveHintLabel),
                    const SizedBox(height: 4),
                    Text(_hintText(state)),
                  ],
                ),
              ),
            ),
            if (_summary != null) ...[
              const SizedBox(height: 12),
              _buildSummaryCard(_summary!),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: const ValueKey('companion_record_start_button'),
                  onPressed:
                      _isSubmitting || _isChangingStage || state.completed
                          ? null
                          : _recordAttempt,
                  child: Text(
                    _isSubmitting
                        ? _strings.applying
                        : _strings.companionRecordStart,
                  ),
                ),
                OutlinedButton(
                  key: const ValueKey('companion_hint_button'),
                  onPressed: state.completed ? null : _requestHint,
                  child: Text(_strings.companionHintButton),
                ),
                OutlinedButton(
                  key: const ValueKey('companion_repeat_button'),
                  onPressed: state.completed ? null : _repeatCurrent,
                  child: Text(_strings.companionRepeatButton),
                ),
                OutlinedButton(
                  key: const ValueKey('companion_next_button'),
                  onPressed:
                      state.currentVerse.passedForStage(state.activeStage)
                          ? _manualNext
                          : null,
                  child: Text(_strings.companionNextButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseTile({
    required BuildContext context,
    required ChainRunState state,
    required int index,
  }) {
    final verse = state.verses[index];
    final active = index == state.currentVerseIndex;
    final label = '${verse.verse.surah}:${verse.verse.ayah}';
    final statusText = _stageStatusText(state, verse);
    final body = _buildVerseBody(state, verse);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        key: ValueKey('companion_verse_$index'),
        decoration: BoxDecoration(
          border: Border.all(
            color: active
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  const Spacer(),
                  Text(statusText),
                ],
              ),
              if (body != null) ...[
                const SizedBox(height: 6),
                body,
              ],
              if (verse.passed) ...[
                const SizedBox(height: 4),
                Text(
                  _strings.companionProficiency(
                    verse.proficiency.toStringAsFixed(2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ChainResultSummary summary) {
    return Card(
      key: const ValueKey('companion_summary_card'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _strings.companionSessionComplete,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              _strings.companionSummaryPassed(
                summary.passedVerses,
                summary.totalVerses,
              ),
            ),
            Text(
              _strings.companionSummaryHint(
                summary.averageHintLevel.toStringAsFixed(2),
              ),
            ),
            Text(
              _strings.companionSummaryStrength(
                summary.averageRetrievalStrength.toStringAsFixed(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanionVerseWordRenderData {
  const _CompanionVerseWordRenderData({
    required this.qcfFamilyName,
    required this.words,
  });

  final String qcfFamilyName;
  final List<MushafWord> words;
}
