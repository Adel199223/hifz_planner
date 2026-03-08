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
  String? _selectedAutoCheckOptionId;
  String? _autoCheckPromptSignature;
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
        _syncAutoCheckSelection(state);
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

    await _playVerseAudio(currentVerse, markAsAuto: true);
  }

  bool _isStage1RuntimeActive(ChainRunState state) {
    return state.activeStage == CompanionStage.guidedVisible &&
        !state.completed &&
        state.stage1 != null &&
        !state.isReviewMode;
  }

  bool _isStage2RuntimeActive(ChainRunState state) {
    return state.activeStage == CompanionStage.cuedRecall &&
        !state.completed &&
        state.stage2 != null &&
        !state.isReviewMode;
  }

  bool _isStage3RuntimeActive(ChainRunState state) {
    return state.activeStage == CompanionStage.hiddenReveal &&
        !state.completed &&
        state.stage3 != null &&
        !state.isReviewMode;
  }

  bool _isStage4RuntimeActive(ChainRunState state) {
    return state.activeStage == CompanionStage.hiddenReveal &&
        !state.completed &&
        state.stage4 != null &&
        !state.isReviewMode;
  }

  bool _isHintLockedByStage1(ChainRunState state) {
    final runtime = state.stage1;
    if (!_isStage1RuntimeActive(state) || runtime == null) {
      return false;
    }
    return runtime.autoCheckRequiredForCurrentMode &&
        !runtime.hintsUnlockedForCurrentProbe;
  }

  bool _isStage1ColdMode(Stage1Mode mode) {
    return mode == Stage1Mode.coldProbe ||
        mode == Stage1Mode.spacedReprobe ||
        mode == Stage1Mode.checkpoint ||
        mode == Stage1Mode.cumulativeCheck;
  }

  Stage1AutoCheckPrompt? _currentAutoCheckPrompt(ChainRunState state) {
    if (_isStage1RuntimeActive(state)) {
      final runtime = state.stage1!;
      if (!runtime.autoCheckRequiredForCurrentMode) {
        return null;
      }
      return runtime.activeAutoCheckPrompt;
    }
    if (_isStage2RuntimeActive(state)) {
      final runtime = state.stage2!;
      if (!runtime.autoCheckRequiredForCurrentMode) {
        return null;
      }
      return runtime.activeAutoCheckPrompt;
    }
    if (_isStage3RuntimeActive(state)) {
      final runtime = state.stage3!;
      if (!runtime.autoCheckRequiredForCurrentMode) {
        return null;
      }
      return runtime.activeAutoCheckPrompt;
    }
    if (_isStage4RuntimeActive(state)) {
      final runtime = state.stage4!;
      if (!runtime.autoCheckRequiredForCurrentMode) {
        return null;
      }
      return runtime.activeAutoCheckPrompt;
    }
    return null;
  }

  String? _autoCheckSignature(Stage1AutoCheckPrompt? prompt) {
    if (prompt == null) {
      return null;
    }
    final options = prompt.options.map((option) => option.id).join('|');
    return '${prompt.type.code}:${prompt.correctOptionId}:$options:${prompt.normalizedPayload}';
  }

  void _syncAutoCheckSelection(ChainRunState state) {
    final signature = _autoCheckSignature(_currentAutoCheckPrompt(state));
    if (_autoCheckPromptSignature == signature) {
      return;
    }
    _autoCheckPromptSignature = signature;
    _selectedAutoCheckOptionId = null;
  }

  String _stage1ModeLabel(Stage1Mode mode) {
    return switch (mode) {
      Stage1Mode.modelEcho => _strings.companionStage1ModeModelEcho,
      Stage1Mode.coldProbe => _strings.companionStage1ModeColdProbe,
      Stage1Mode.correction => _strings.companionStage1ModeCorrection,
      Stage1Mode.spacedReprobe => _strings.companionStage1ModeSpacedReprobe,
      Stage1Mode.checkpoint => _strings.companionStage1ModeCheckpoint,
      Stage1Mode.cumulativeCheck => _strings.companionStage1ModeCumulative,
    };
  }

  String _stage2ModeLabel(Stage2Mode mode) {
    return switch (mode) {
      Stage2Mode.minimalCueRecall =>
        _strings.companionStage2ModeMinimalCueRecall,
      Stage2Mode.discrimination => _strings.companionStage2ModeDiscrimination,
      Stage2Mode.linking => _strings.companionStage2ModeLinking,
      Stage2Mode.correction => _strings.companionStage2ModeCorrection,
      Stage2Mode.checkpoint => _strings.companionStage2ModeCheckpoint,
      Stage2Mode.remediation => _strings.companionStage2ModeRemediation,
    };
  }

  String _stage3ModeLabel(Stage3Mode mode) {
    return switch (mode) {
      Stage3Mode.weakPrelude => _strings.companionStage3ModeWeakPrelude,
      Stage3Mode.hiddenRecall => _strings.companionStage3ModeHiddenRecall,
      Stage3Mode.linking => _strings.companionStage3ModeLinking,
      Stage3Mode.discrimination => _strings.companionStage3ModeDiscrimination,
      Stage3Mode.correction => _strings.companionStage3ModeCorrection,
      Stage3Mode.checkpoint => _strings.companionStage3ModeCheckpoint,
      Stage3Mode.remediation => _strings.companionStage3ModeRemediation,
    };
  }

  String _stage4ModeLabel(Stage4Mode mode) {
    return switch (mode) {
      Stage4Mode.coldStart => _strings.companionStage4ModeColdStart,
      Stage4Mode.randomStart => _strings.companionStage4ModeRandomStart,
      Stage4Mode.linking => _strings.companionStage4ModeLinking,
      Stage4Mode.discrimination => _strings.companionStage4ModeDiscrimination,
      Stage4Mode.correction => _strings.companionStage4ModeCorrection,
      Stage4Mode.checkpoint => _strings.companionStage4ModeCheckpoint,
      Stage4Mode.remediation => _strings.companionStage4ModeRemediation,
    };
  }

  Future<void> _recordAttempt() async {
    final state = _state;
    if (state == null || state.completed || _isSubmitting || _isChangingStage) {
      return;
    }

    final isStage1Correction =
        _isStage1RuntimeActive(state) &&
        state.stage1!.mode == Stage1Mode.correction;
    final isStage2Correction =
        _isStage2RuntimeActive(state) &&
        state.stage2!.mode == Stage2Mode.correction;
    final isStage3Correction =
        _isStage3RuntimeActive(state) &&
        state.stage3!.mode == Stage3Mode.correction;
    final isStage4Correction =
        _isStage4RuntimeActive(state) &&
        state.stage4!.mode == Stage4Mode.correction;
    if (isStage1Correction ||
        isStage2Correction ||
        isStage3Correction ||
        isStage4Correction) {
      setState(() {
        _isSubmitting = true;
      });
      try {
        final update = await _engine.submitCorrectionExposure(
          state: state,
          latencyToStartMs: 400,
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
          _syncAutoCheckSelection(update.state);
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
      return;
    }

    final autoPrompt = _currentAutoCheckPrompt(state);
    if (autoPrompt != null && _selectedAutoCheckOptionId == null) {
      _showSnackBar(_strings.companionStage1AutoCheckRequiredSelection);
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
        selectedAutoCheckOptionId: _selectedAutoCheckOptionId,
        latencyToStartMs: 800,
        stopsCount: 0,
        selfCorrectionsCount: 0,
        audioPlays: 1,
        loopCount: 1,
        playbackSpeed: 1.0,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _state = update.state;
        _summary = update.summary ?? _summary;
        _isSubmitting = false;
        _syncAutoCheckSelection(update.state);
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
        _syncAutoCheckSelection(updated);
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
          content: Text(_strings.companionSkipStageBody(_stageLabel(stage))),
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
    if (_isHintLockedByStage1(state)) {
      _showSnackBar(_strings.companionStage1HintLockedMessage);
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
        final provisional = state.copyWith(currentVerseIndex: i);
        final nextState = provisional.copyWith(
          currentHintLevel: _dynamicBaselineHint(provisional),
          returnVerseIndex: null,
        );
        setState(() {
          _state = nextState;
          _syncAutoCheckSelection(nextState);
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

  HintLevel _stage2BaselineHint(Stage2VerseStats stats) {
    var baseline = stats.cueBaselineHint;
    if (stats.reliefPending) {
      if (baseline == HintLevel.h0) {
        baseline = HintLevel.letters;
      } else if (baseline == HintLevel.letters) {
        baseline = HintLevel.firstWord;
      }
    }
    return baseline;
  }

  HintLevel _stage3BaselineHint(
    Stage3VerseStats stats, {
    required bool capAtH1,
  }) {
    var baseline = stats.cueBaselineHint;
    if (stats.reliefPending) {
      if (baseline == HintLevel.h0) {
        baseline = HintLevel.letters;
      }
    }
    if (baseline.order > HintLevel.letters.order) {
      baseline = HintLevel.letters;
    }
    if (capAtH1 && baseline.order > HintLevel.letters.order) {
      baseline = HintLevel.letters;
    }
    return baseline;
  }

  HintLevel _stage4BaselineHint(Stage4VerseStats stats) {
    var baseline = stats.cueBaselineHint;
    if (baseline.order > HintLevel.letters.order) {
      baseline = HintLevel.letters;
    }
    return baseline;
  }

  HintLevel _dynamicBaselineHint(ChainRunState state) {
    if (_isStage2RuntimeActive(state)) {
      return _stage2BaselineHint(state.currentVerse.stage2);
    }
    if (_isStage4RuntimeActive(state)) {
      return _stage4BaselineHint(state.currentVerse.stage4);
    }
    if (_isStage3RuntimeActive(state)) {
      return _stage3BaselineHint(
        state.currentVerse.stage3,
        capAtH1: state.stage3WeakPreludeTargets.isNotEmpty,
      );
    }
    if (state.activeStage == CompanionStage.hiddenReveal &&
        state.stage3WeakPreludeTargets.isNotEmpty) {
      return HintLevel.letters;
    }
    return _baselineHint(state.activeStage);
  }

  HintLevel _effectiveHintLevel(ChainRunState state) {
    final baseline = _dynamicBaselineHint(state);
    var level = state.currentHintLevel.order < baseline.order
        ? baseline
        : state.currentHintLevel;
    if (state.activeStage == CompanionStage.hiddenReveal &&
        state.stage3WeakPreludeTargets.isNotEmpty &&
        level.order > HintLevel.letters.order) {
      level = HintLevel.letters;
    }
    return level;
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
    final isCurrent = identical(verse, state.currentVerse);
    if (_isStage1RuntimeActive(state) && isCurrent) {
      return _stage1ModeLabel(state.stage1!.mode);
    }
    if (_isStage2RuntimeActive(state) && isCurrent) {
      return _stage2ModeLabel(state.stage2!.mode);
    }
    if (_isStage3RuntimeActive(state) && isCurrent) {
      return _stage3ModeLabel(state.stage3!.mode);
    }
    if (_isStage4RuntimeActive(state) && isCurrent) {
      return _stage4ModeLabel(state.stage4!.mode);
    }
    return switch (state.activeStage) {
      CompanionStage.guidedVisible =>
        verse.passedGuidedVisible
            ? _strings.companionVersePassed
            : _strings.companionStageGuidedVisible,
      CompanionStage.cuedRecall =>
        verse.passedCuedRecall
            ? _strings.companionVersePassed
            : _strings.companionStageCuedRecall,
      CompanionStage.hiddenReveal =>
        verse.passed
            ? _strings.companionVersePassed
            : verse.revealed
            ? _strings.companionVerseRevealed
            : _strings.companionVerseHidden,
    };
  }

  bool _shouldHideCurrentVerseForStage1(
    ChainRunState state,
    ChainVerseState verse,
  ) {
    if (!_isStage1RuntimeActive(state) ||
        state.stage1 == null ||
        !identical(verse, state.currentVerse)) {
      return false;
    }
    final mode = state.stage1!.mode;
    if (!_isStage1ColdMode(mode)) {
      return false;
    }
    return _effectiveHintLevel(state) == HintLevel.h0;
  }

  bool _shouldHideCurrentVerseForStage2(
    ChainRunState state,
    ChainVerseState verse,
  ) {
    if (!_isStage2RuntimeActive(state) ||
        !identical(verse, state.currentVerse)) {
      return false;
    }
    if (verse.passedCuedRecall) {
      return false;
    }
    return _effectiveHintLevel(state) == HintLevel.h0;
  }

  bool _shouldHideCurrentVerseForStage3(
    ChainRunState state,
    ChainVerseState verse,
  ) {
    if (!_isStage3RuntimeActive(state) ||
        !identical(verse, state.currentVerse)) {
      return false;
    }
    if (verse.passed) {
      return false;
    }
    return _effectiveHintLevel(state) == HintLevel.h0;
  }

  bool _shouldHideCurrentVerseForStage4(
    ChainRunState state,
    ChainVerseState verse,
  ) {
    if (!_isStage4RuntimeActive(state) ||
        !identical(verse, state.currentVerse)) {
      return false;
    }
    return _effectiveHintLevel(state) == HintLevel.h0;
  }

  String? _stage2CueText(ChainRunState state, ChainVerseState verse) {
    if (!_isStage2RuntimeActive(state)) {
      return null;
    }
    if (verse.passedCuedRecall) {
      return verse.verse.text;
    }
    if (!identical(verse, state.currentVerse)) {
      return null;
    }
    final hintLevel = _effectiveHintLevel(state);
    return switch (hintLevel) {
      HintLevel.h0 => null,
      HintLevel.letters => _lettersHint(verse.verse.text),
      HintLevel.firstWord => _firstWordCue(verse.verse.text),
      HintLevel.meaningCue => _strings.companionTafsirCuePlaceholder,
      HintLevel.chunkText => _chunkHint(verse.verse.text),
      HintLevel.fullText => verse.verse.text,
    };
  }

  String? _stage3CueText(ChainRunState state, ChainVerseState verse) {
    if (!_isStage3RuntimeActive(state)) {
      return null;
    }
    if (!identical(verse, state.currentVerse)) {
      return null;
    }
    final hintLevel = _effectiveHintLevel(state);
    return switch (hintLevel) {
      HintLevel.h0 => null,
      HintLevel.letters => _lettersHint(verse.verse.text),
      HintLevel.firstWord => _firstWordCue(verse.verse.text),
      HintLevel.meaningCue => _strings.companionTafsirCuePlaceholder,
      HintLevel.chunkText => _chunkHint(verse.verse.text),
      HintLevel.fullText => verse.verse.text,
    };
  }

  String? _stage4CueText(ChainRunState state, ChainVerseState verse) {
    if (!_isStage4RuntimeActive(state)) {
      return null;
    }
    if (!identical(verse, state.currentVerse)) {
      return null;
    }
    final hintLevel = _effectiveHintLevel(state);
    return switch (hintLevel) {
      HintLevel.h0 => null,
      HintLevel.letters => _lettersHint(verse.verse.text),
      HintLevel.firstWord => _firstWordCue(verse.verse.text),
      HintLevel.meaningCue => _strings.companionTafsirCuePlaceholder,
      HintLevel.chunkText => _chunkHint(verse.verse.text),
      HintLevel.fullText => verse.verse.text,
    };
  }

  String? _verseBodyText(ChainRunState state, ChainVerseState verse) {
    if (_shouldHideCurrentVerseForStage1(state, verse)) {
      return null;
    }
    if (_shouldHideCurrentVerseForStage2(state, verse)) {
      return null;
    }
    if (_shouldHideCurrentVerseForStage3(state, verse)) {
      return null;
    }
    if (_shouldHideCurrentVerseForStage4(state, verse)) {
      return null;
    }
    return switch (state.activeStage) {
      CompanionStage.guidedVisible => verse.verse.text,
      CompanionStage.cuedRecall =>
        _isStage2RuntimeActive(state)
            ? _stage2CueText(state, verse)
            : (verse.passedCuedRecall
                  ? verse.verse.text
                  : _firstWordCue(verse.verse.text)),
      CompanionStage.hiddenReveal =>
        _isStage3RuntimeActive(state)
            ? _stage3CueText(state, verse)
            : _isStage4RuntimeActive(state)
            ? _stage4CueText(state, verse)
            : (verse.revealed ? verse.verse.text : null),
    };
  }

  bool _isFullVerseVisible(ChainRunState state, ChainVerseState verse) {
    if (_shouldHideCurrentVerseForStage1(state, verse)) {
      return false;
    }
    if (_shouldHideCurrentVerseForStage2(state, verse)) {
      return false;
    }
    if (_shouldHideCurrentVerseForStage3(state, verse)) {
      return false;
    }
    if (_shouldHideCurrentVerseForStage4(state, verse)) {
      return false;
    }
    return switch (state.activeStage) {
      CompanionStage.guidedVisible => true,
      CompanionStage.cuedRecall =>
        _isStage2RuntimeActive(state)
            ? (verse.passedCuedRecall ||
                  (identical(verse, state.currentVerse) &&
                      _effectiveHintLevel(state) == HintLevel.fullText))
            : verse.passedCuedRecall,
      CompanionStage.hiddenReveal =>
        _isStage3RuntimeActive(state)
            ? (identical(verse, state.currentVerse) &&
                  _effectiveHintLevel(state) == HintLevel.fullText)
            : _isStage4RuntimeActive(state)
            ? (identical(verse, state.currentVerse) &&
                  _effectiveHintLevel(state) == HintLevel.fullText)
            : verse.revealed,
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

  Widget? _buildStage1ModeCard(ChainRunState state) {
    if (!_isStage1RuntimeActive(state) || state.stage1 == null) {
      return null;
    }
    final runtime = state.stage1!;
    final modeLabel = _stage1ModeLabel(runtime.mode);
    final helperText = runtime.mode == Stage1Mode.correction
        ? _strings.companionStage1CorrectionRequiredMessage
        : _isHintLockedByStage1(state)
        ? _strings.companionStage1HintLockedMessage
        : _strings.companionStage1ReciteNow;

    return Card(
      key: const ValueKey('companion_stage1_mode_card'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _strings.companionStage1ModeLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(modeLabel, key: const ValueKey('companion_stage1_mode_label')),
            const SizedBox(height: 4),
            Text(helperText, key: const ValueKey('companion_stage1_mode_hint')),
          ],
        ),
      ),
    );
  }

  Widget? _buildStage2ModeCard(ChainRunState state) {
    if (!_isStage2RuntimeActive(state) || state.stage2 == null) {
      return null;
    }
    final runtime = state.stage2!;
    final modeLabel = _stage2ModeLabel(runtime.mode);
    final helperText = runtime.mode == Stage2Mode.correction
        ? _strings.companionStage2CorrectionRequiredMessage
        : _strings.companionStage2ReciteNow;

    return Card(
      key: const ValueKey('companion_stage2_mode_card'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _strings.companionStage2ModeLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(modeLabel, key: const ValueKey('companion_stage2_mode_label')),
            const SizedBox(height: 4),
            Text(helperText, key: const ValueKey('companion_stage2_mode_hint')),
          ],
        ),
      ),
    );
  }

  Widget? _buildStage3ModeCard(ChainRunState state) {
    if (!_isStage3RuntimeActive(state) || state.stage3 == null) {
      return null;
    }
    final runtime = state.stage3!;
    final modeLabel = _stage3ModeLabel(runtime.mode);
    final helperText = runtime.mode == Stage3Mode.correction
        ? _strings.companionStage3CorrectionRequiredMessage
        : _strings.companionStage3ReciteNow;

    return Card(
      key: const ValueKey('companion_stage3_mode_card'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _strings.companionStage3ModeLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(modeLabel, key: const ValueKey('companion_stage3_mode_label')),
            const SizedBox(height: 4),
            Text(helperText, key: const ValueKey('companion_stage3_mode_hint')),
          ],
        ),
      ),
    );
  }

  Widget? _buildStage4ModeCard(ChainRunState state) {
    if (!_isStage4RuntimeActive(state) || state.stage4 == null) {
      return null;
    }
    final runtime = state.stage4!;
    final modeLabel = _stage4ModeLabel(runtime.mode);
    final helperText = runtime.mode == Stage4Mode.correction
        ? _strings.companionStage4CorrectionRequiredMessage
        : _strings.companionStage4ReciteNow;

    return Card(
      key: const ValueKey('companion_stage4_mode_card'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _strings.companionStage4ModeLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(modeLabel, key: const ValueKey('companion_stage4_mode_label')),
            const SizedBox(height: 4),
            Text(helperText, key: const ValueKey('companion_stage4_mode_hint')),
          ],
        ),
      ),
    );
  }

  Widget? _buildAutoCheckCard(ChainRunState state) {
    final prompt = _currentAutoCheckPrompt(state);
    if (prompt == null) {
      return null;
    }
    final keyPrefix = _isStage2RuntimeActive(state)
        ? 'companion_stage2_auto_check'
        : _isStage3RuntimeActive(state)
        ? 'companion_stage3_auto_check'
        : _isStage4RuntimeActive(state)
        ? 'companion_stage4_auto_check'
        : 'companion_stage1_auto_check';

    return Card(
      key: ValueKey('${keyPrefix}_card'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _strings.companionStage1AutoCheckTitle,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              prompt.stem,
              key: ValueKey('${keyPrefix}_stem'),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _selectedAutoCheckOptionId,
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedAutoCheckOptionId = value;
                });
              },
              child: Column(
                children: [
                  for (final option in prompt.options)
                    RadioListTile<String>(
                      key: ValueKey('${keyPrefix}_${option.id}'),
                      dense: true,
                      value: option.id,
                      title: Text(
                        option.label,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
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
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
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
        child: Center(child: Text(_strings.companionNoSessionState)),
      );
    }

    final isPlayingCurrentAyah = _isPlayingCurrentAyah(state, audioState);
    final stage1ModeCard = _buildStage1ModeCard(state);
    final stage2ModeCard = _buildStage2ModeCard(state);
    final stage3ModeCard = _buildStage3ModeCard(state);
    final stage4ModeCard = _buildStage4ModeCard(state);
    final stage1AutoCheckCard = _buildAutoCheckCard(state);
    final hintLocked = _isHintLockedByStage1(state);
    final isStage1Correction =
        _isStage1RuntimeActive(state) &&
        state.stage1?.mode == Stage1Mode.correction;
    final isStage2Correction =
        _isStage2RuntimeActive(state) &&
        state.stage2?.mode == Stage2Mode.correction;
    final isStage3Correction =
        _isStage3RuntimeActive(state) &&
        state.stage3?.mode == Stage3Mode.correction;
    final isStage4Correction =
        _isStage4RuntimeActive(state) &&
        state.stage4?.mode == Stage4Mode.correction;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _strings.companionPracticeTitle,
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
            if (stage1ModeCard != null) ...[
              const SizedBox(height: 8),
              stage1ModeCard,
            ],
            if (stage2ModeCard != null) ...[
              const SizedBox(height: 8),
              stage2ModeCard,
            ],
            if (stage3ModeCard != null) ...[
              const SizedBox(height: 8),
              stage3ModeCard,
            ],
            if (stage4ModeCard != null) ...[
              const SizedBox(height: 8),
              stage4ModeCard,
            ],
            if (stage1AutoCheckCard != null) ...[
              const SizedBox(height: 8),
              stage1AutoCheckCard,
            ],
            if (state.activeStage == CompanionStage.hiddenReveal &&
                state.stage3WeakPreludeTargets.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _strings.companionStage3WeakPreludeBanner(
                  state.stage3WeakPreludeTargets.length,
                ),
                key: const ValueKey('companion_stage3_weak_prelude_banner'),
              ),
            ],
            if (_isStage4RuntimeActive(state) && state.stage4 != null) ...[
              const SizedBox(height: 8),
              Text(
                _strings.companionStage4DueBanner(state.stage4!.dueKind),
                key: const ValueKey('companion_stage4_due_banner'),
              ),
              if (state.stage4!.unresolvedTargets.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _strings.companionStage4UnresolvedTargets(
                    state.stage4!.unresolvedTargets.length,
                  ),
                  key: const ValueKey('companion_stage4_unresolved_banner'),
                ),
              ],
            ],
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
                            : (value) => unawaited(
                                _setCompanionAutoplayEnabled(value),
                              ),
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
              _buildVerseTile(context: context, state: state, index: i),
            if (_isStage1RuntimeActive(state)) ...[
              Builder(
                builder: (_) {
                  final weakCount = state.verses
                      .where((verse) => verse.stage1.weak)
                      .length;
                  if (weakCount <= 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _strings.companionStage1WeakVerses(weakCount),
                      key: const ValueKey('companion_stage1_weak_message'),
                    ),
                  );
                },
              ),
            ],
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
                        : isStage1Correction
                        ? _strings.companionStage1CorrectionAction
                        : isStage2Correction
                        ? _strings.companionStage2CorrectionAction
                        : isStage3Correction
                        ? _strings.companionStage3CorrectionAction
                        : isStage4Correction
                        ? _strings.companionStage4CorrectionAction
                        : _strings.companionRecordStart,
                  ),
                ),
                OutlinedButton(
                  key: const ValueKey('companion_hint_button'),
                  onPressed: state.completed || hintLocked
                      ? null
                      : _requestHint,
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
              if (body != null) ...[const SizedBox(height: 6), body],
              if (body == null &&
                  _shouldHideCurrentVerseForStage1(state, verse)) ...[
                const SizedBox(height: 6),
                Text(
                  _strings.companionStage1ReciteNowHiddenPrompt,
                  key: const ValueKey('companion_stage1_hidden_prompt'),
                ),
              ],
              if (body == null &&
                  _shouldHideCurrentVerseForStage2(state, verse)) ...[
                const SizedBox(height: 6),
                Text(
                  _strings.companionStage1ReciteNowHiddenPrompt,
                  key: const ValueKey('companion_stage2_hidden_prompt'),
                ),
              ],
              if (body == null &&
                  _shouldHideCurrentVerseForStage3(state, verse)) ...[
                const SizedBox(height: 6),
                Text(
                  _strings.companionStage1ReciteNowHiddenPrompt,
                  key: const ValueKey('companion_stage3_hidden_prompt'),
                ),
              ],
              if (body == null &&
                  _shouldHideCurrentVerseForStage4(state, verse)) ...[
                const SizedBox(height: 6),
                Text(
                  _strings.companionStage1ReciteNowHiddenPrompt,
                  key: const ValueKey('companion_stage4_hidden_prompt'),
                ),
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
