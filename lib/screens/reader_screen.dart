import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app/app_preferences.dart';
import '../app/navigation_providers.dart';
import '../data/database/app_database.dart';
import '../data/providers/database_providers.dart';
import '../data/services/qurancom_api.dart';
import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';
import '../ui/qcf/qcf_font_manager.dart';
import '../ui/tajweed/tajweed_colors.dart';
import '../ui/tajweed/tajweed_markup.dart';

const double _mushafCanvasMaxWidth = 860;
const double _mushafCanvasMinWidth = 420;
const double _mushafLeftPaneWidth = 304;
const double _mushafSettingsPaneWidth = 360;
const double _mushafWordHorizontalPadding = 1.5;
const double _mushafWordVerticalPadding = 1.0;
const double _mushafWordMinScale = 0.03;
const double _mushafChapterHeaderMaxWidth = 560;
const double _mushafTargetLineWidthToViewportHeight = 0.56;
const double _mushafLineHeightToViewportHeight = 0.061;
const double _mushafQcfFontSizeToViewportHeight = 0.032;
const double _mushafFallbackFontSizeToViewportHeight = 0.04;
const double _mushafChapterIconFontSize = 96;
const double _mushafControlMinHeight = 42;
const double _mushafControlSeparatorHeight = 20;
const double _mushafControlHorizontalPadding = 10;
const double _mushafControlVerticalPadding = 10;
const double _mushafUnderlineTabIndicator = 2;
const double _readerTopRightMenuClearance = 64;
const double _verseByVerseWordGap = 4;
const double _verseByVerseWordRunSpacing = 8;
const int _translationResourceEnglish = 85;
const int _translationResourceFrench = 31;
const int _translationResourcePortuguese = 43;
const Map<int, String> _translationResourceLabelById = <int, String>{
  _translationResourceEnglish: 'M.A.S. Abdel Haleem',
  _translationResourceFrench: 'Muhammad Hamidullah',
  _translationResourcePortuguese: 'Samir El-Hayek',
};

const Map<int, Set<int>> _staticCenteredMushafLines = <int, Set<int>>{
  255: <int>{2},
  528: <int>{9},
  534: <int>{6},
  545: <int>{6},
  586: <int>{1},
  593: <int>{2},
  594: <int>{5},
  600: <int>{10},
  602: <int>{5, 15},
  603: <int>{10, 15},
  604: <int>{4, 9, 14, 15},
};

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    this.mode,
    this.page,
    this.targetSurah,
    this.targetAyah,
    this.highlightStartSurah,
    this.highlightStartAyah,
    this.highlightEndSurah,
    this.highlightEndAyah,
  });

  final String? mode;
  final int? page;
  final int? targetSurah;
  final int? targetAyah;
  final int? highlightStartSurah;
  final int? highlightStartAyah;
  final int? highlightEndSurah;
  final int? highlightEndAyah;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  _ReaderViewMode _viewMode = _ReaderViewMode.simple;
  _ReaderMode _mode = _ReaderMode.surah;
  _ArabicRenderMode _arabicRenderMode = _ArabicRenderMode.plain;
  _MushafNavTab _mushafNavTab = _MushafNavTab.surah;
  _MushafSettingsTab _mushafSettingsTab = _MushafSettingsTab.arabic;
  bool _mushafSettingsOpen = false;
  int _mushafFontStep = 5;
  int _selectedSurah = 1;
  int _verseTabSelectedSurah = 1;
  String _mushafSurahSearchQuery = '';
  String _mushafVerseSearchQuery = '';
  String _mushafJuzSearchQuery = '';
  String _mushafPageSearchQuery = '';
  final Map<int, String> _surahNamesEn = <int, String>{};
  final Map<int, String> _surahNamesAr = <int, String>{};
  int? _selectedPage;
  Future<List<int>>? _availablePagesFuture;
  Future<List<MushafJuzNavEntry>>? _juzIndexFuture;
  Future<int>? _verseTabAyahCountFuture;
  Future<List<AyahData>>? _ayahsFuture;
  Future<_MushafRenderData>? _mushafFuture;
  int? _mushafFuturePage;
  _ArabicRenderMode? _mushafFutureRenderMode;
  String? _hoveredAyahKey;
  String? _tappedAyahKey;
  String? _hoveredMushafVerseKey;
  String? _hoveredMushafWordKey;
  MushafWord? _hoveredMushafPreviewWord;
  String? _selectedMushafVerseKey;
  String? _jumpHighlightedAyahKey;
  _VerseJumpTarget? _pendingJumpTarget;
  _VerseRange? _rangeHighlight;
  bool _jumpScheduled = false;
  int _pageLoadGeneration = 0;

  final ScrollController _ayahScrollController = ScrollController();
  final ScrollController _mushafScrollController = ScrollController();
  final Map<String, GlobalKey> _ayahRowKeys = <String, GlobalKey>{};
  final Map<String, Future<_VerseByVerseRowRenderData>>
      _simpleQuranComRowFutureCache =
      <String, Future<_VerseByVerseRowRenderData>>{};
  final Set<String> _simpleQuranComPrefetchKeys = <String>{};
  final Map<String, Future<MushafPageMeta>> _verseContextMetaFutureCache =
      <String, Future<MushafPageMeta>>{};
  Map<String, AyahData> _mushafAyahLookupByVerseKey = <String, AyahData>{};
  String? _lastMushafInteractionWarningKey;
  bool _pendingMushafScrollReset = false;
  Timer? _jumpHighlightTimer;

  AppStrings get _strings =>
      AppStrings.of(ref.read(appPreferencesProvider).language);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(readerSettingsPaneOpenProvider.notifier).setOpen(false);
    });
    unawaited(_loadSurahMetadata());
    _applyWidgetInputs();
  }

  @override
  void didUpdateWidget(covariant ReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_didInputsChange(oldWidget)) {
      return;
    }

    setState(() {
      _applyWidgetInputs();
    });
  }

  @override
  void dispose() {
    _jumpHighlightTimer?.cancel();
    _ayahScrollController.dispose();
    _mushafScrollController.dispose();
    super.dispose();
  }

  bool _didInputsChange(ReaderScreen oldWidget) {
    return oldWidget.mode != widget.mode ||
        oldWidget.page != widget.page ||
        oldWidget.targetSurah != widget.targetSurah ||
        oldWidget.targetAyah != widget.targetAyah ||
        oldWidget.highlightStartSurah != widget.highlightStartSurah ||
        oldWidget.highlightStartAyah != widget.highlightStartAyah ||
        oldWidget.highlightEndSurah != widget.highlightEndSurah ||
        oldWidget.highlightEndAyah != widget.highlightEndAyah;
  }

  void _applyWidgetInputs() {
    var resolvedMode = _resolveMode(
      mode: widget.mode,
      page: widget.page,
    );
    final target = _normalizeTarget(
      surah: widget.targetSurah,
      ayah: widget.targetAyah,
    );
    if (_viewMode == _ReaderViewMode.mushaf) {
      resolvedMode = _ReaderMode.page;
    }

    _mode = resolvedMode;
    if (_viewMode == _ReaderViewMode.simple) {
      _mushafNavTab =
          _mode == _ReaderMode.surah ? _MushafNavTab.surah : _MushafNavTab.page;
    }
    _rangeHighlight = _normalizeRange();
    _pendingJumpTarget = target;
    _clearInteractiveHighlights();
    _jumpScheduled = false;
    _invalidateMushafFuture();
    _clearSimpleQuranComRowCache();

    if (_verseTabSelectedSurah < 1 || _verseTabSelectedSurah > 114) {
      _verseTabSelectedSurah = _selectedSurah;
    }
    if (target != null) {
      _verseTabSelectedSurah = target.surah;
    } else if (_mode == _ReaderMode.surah) {
      _verseTabSelectedSurah = _selectedSurah;
    }
    _verseTabAyahCountFuture = _loadVerseTabAyahCount(_verseTabSelectedSurah);

    if (_mode == _ReaderMode.surah) {
      _pageLoadGeneration += 1;
      _selectedPage = null;
      _availablePagesFuture = null;
      if (target != null) {
        _selectedSurah = target.surah;
      }
      _ayahsFuture = _loadAyahsBySurah(_selectedSurah);
      _maybePrefetchSimpleQuranComCurrentContext();
      return;
    }

    _selectedPage = null;
    _ayahsFuture = Future.value(const <AyahData>[]);
    _availablePagesFuture = _loadAvailablePages();
    _resolvePageSelection(
      requestedPage: widget.page,
      target: target,
      showMissingTargetMessage: true,
    );
  }

  _ReaderMode _resolveMode({
    required String? mode,
    required int? page,
  }) {
    final normalized = mode?.toLowerCase().trim();
    if (normalized == 'page') {
      return _ReaderMode.page;
    }
    if (normalized == 'surah') {
      return _ReaderMode.surah;
    }
    if (page != null && page > 0) {
      return _ReaderMode.page;
    }
    return _ReaderMode.surah;
  }

  Future<List<int>> _loadAvailablePages() {
    return ref.read(quranRepoProvider).getPagesAvailable();
  }

  Future<List<AyahData>> _loadAyahsBySurah(int surah) {
    return ref.read(quranRepoProvider).getAyahsBySurah(surah);
  }

  Future<List<AyahData>> _loadAyahsByPage(int page) {
    return ref.read(quranRepoProvider).getAyahsByPage(page);
  }

  Future<int> _loadVerseTabAyahCount(int surah) {
    return ref.read(quranRepoProvider).getAyahCountForSurah(surah);
  }

  Future<List<MushafJuzNavEntry>> _loadMushafJuzIndex() {
    return ref.read(quranComApiProvider).getJuzIndex(
          mushafId: _activeMushafId(),
        );
  }

  Future<void> _resolvePageSelection({
    required int? requestedPage,
    required _VerseJumpTarget? target,
    required bool showMissingTargetMessage,
  }) async {
    final generation = ++_pageLoadGeneration;
    final pages = await (_availablePagesFuture ?? _loadAvailablePages());

    if (!mounted ||
        generation != _pageLoadGeneration ||
        _mode != _ReaderMode.page) {
      return;
    }

    if (pages.isEmpty) {
      setState(() {
        _selectedPage = null;
        _pendingJumpTarget = null;
        _ayahsFuture = Future.value(const <AyahData>[]);
        _invalidateMushafFuture();
        _clearSimpleQuranComRowCache();
      });
      return;
    }

    _VerseJumpTarget? targetForJump = target;
    int? pageToSelect;

    if (target != null) {
      final targetAyah = await ref.read(quranRepoProvider).getAyah(
            target.surah,
            target.ayah,
          );

      if (!mounted ||
          generation != _pageLoadGeneration ||
          _mode != _ReaderMode.page) {
        return;
      }

      final targetPage = targetAyah?.pageMadina;
      if (targetPage == null) {
        if (showMissingTargetMessage) {
          _showSnackBar(_strings.targetAyahNoPageMetadataYet);
        }
        targetForJump = null;
      } else if (!pages.contains(targetPage)) {
        if (showMissingTargetMessage) {
          _showSnackBar(_strings.targetAyahPageUnavailable);
        }
        targetForJump = null;
      } else {
        pageToSelect = targetPage;
      }
    }

    if (pageToSelect == null &&
        requestedPage != null &&
        pages.contains(requestedPage)) {
      pageToSelect = requestedPage;
    }

    pageToSelect ??= pages.first;

    if (!mounted ||
        generation != _pageLoadGeneration ||
        _mode != _ReaderMode.page) {
      return;
    }

    setState(() {
      _selectedPage = pageToSelect;
      _pendingJumpTarget = targetForJump;
      _ayahsFuture = _loadAyahsByPage(pageToSelect!);
      _invalidateMushafFuture();
      _clearSimpleQuranComRowCache();
    });
    _maybePrefetchSimpleQuranComCurrentContext();
  }

  void _clearInteractiveHighlights() {
    _hoveredAyahKey = null;
    _tappedAyahKey = null;
    _hoveredMushafVerseKey = null;
    _hoveredMushafWordKey = null;
    _hoveredMushafPreviewWord = null;
    _selectedMushafVerseKey = null;
    _jumpHighlightedAyahKey = null;
    _jumpHighlightTimer?.cancel();
  }

  void _switchMode(_ReaderMode mode) {
    if (_viewMode == _ReaderViewMode.mushaf) {
      return;
    }
    if (mode == _mode) {
      return;
    }

    setState(() {
      _mode = mode;
      _pendingJumpTarget = null;
      _clearInteractiveHighlights();
      _jumpScheduled = false;
      _invalidateMushafFuture();
      _clearSimpleQuranComRowCache();

      if (_mode == _ReaderMode.surah) {
        _pageLoadGeneration += 1;
        _selectedPage = null;
        _availablePagesFuture = null;
        _ayahsFuture = _loadAyahsBySurah(_selectedSurah);
      } else {
        _selectedPage = null;
        _ayahsFuture = Future.value(const <AyahData>[]);
        _availablePagesFuture = _loadAvailablePages();
      }
    });

    if (mode == _ReaderMode.page) {
      _resolvePageSelection(
        requestedPage: null,
        target: null,
        showMissingTargetMessage: false,
      );
      return;
    }

    _maybePrefetchSimpleQuranComCurrentContext();
  }

  void _switchArabicRenderMode(_ArabicRenderMode mode) {
    if (mode == _arabicRenderMode) {
      return;
    }

    final previousMushafId = _activeMushafId();
    setState(() {
      _arabicRenderMode = mode;
      _invalidateMushafFuture();
      _clearSimpleQuranComRowCache();
      if (_viewMode == _ReaderViewMode.mushaf &&
          previousMushafId != _activeMushafId()) {
        _juzIndexFuture = null;
      }
    });

    if (mode == _ArabicRenderMode.tajweed &&
        _viewMode == _ReaderViewMode.simple) {
      unawaited(_prepareTajweedTags());
    }
    if (_viewMode == _ReaderViewMode.mushaf) {
      _resetMushafScrollToTop();
    }

    _maybePrefetchSimpleQuranComCurrentContext();
  }

  void _switchViewMode(_ReaderViewMode mode) {
    if (mode == _viewMode) {
      return;
    }

    setState(() {
      _viewMode = mode;
      _invalidateMushafFuture();
      _clearSimpleQuranComRowCache();
      if (mode == _ReaderViewMode.mushaf) {
        _mode = _ReaderMode.page;
        _mushafNavTab = _MushafNavTab.page;
        _setMushafSettingsOpen(false);
        _selectedPage = null;
        _pendingJumpTarget = null;
        _clearInteractiveHighlights();
        _jumpScheduled = false;
        _ayahsFuture = Future.value(const <AyahData>[]);
        _availablePagesFuture = _loadAvailablePages();
        _juzIndexFuture = null;
      } else {
        _setMushafSettingsOpen(false);
        _mushafNavTab = _mode == _ReaderMode.surah
            ? _MushafNavTab.surah
            : _MushafNavTab.page;
      }
    });

    if (mode == _ReaderViewMode.mushaf) {
      _resetMushafScrollToTop();
      _resolvePageSelection(
        requestedPage: widget.page,
        target: null,
        showMissingTargetMessage: false,
      );
      return;
    }

    if (_mode == _ReaderMode.page && _selectedPage == null) {
      _resolvePageSelection(
        requestedPage: widget.page,
        target: null,
        showMissingTargetMessage: false,
      );
      return;
    }

    _maybePrefetchSimpleQuranComCurrentContext();
  }

  Future<void> _prepareTajweedTags() async {
    try {
      await ref.read(tajweedTagsServiceProvider).ensureLoaded();
      if (!mounted) {
        return;
      }
      setState(() {});
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _arabicRenderMode = _ArabicRenderMode.plain;
      });
      _showSnackBar(_strings.tajweedTagsUnavailableShowingPlain);
    }
  }

  void _selectSurah(int surah) {
    if (surah == _selectedSurah) {
      return;
    }
    setState(() {
      _selectedSurah = surah;
      _verseTabSelectedSurah = surah;
      _verseTabAyahCountFuture = _loadVerseTabAyahCount(surah);
      _pendingJumpTarget = null;
      _clearInteractiveHighlights();
      _jumpScheduled = false;
      _ayahsFuture = _loadAyahsBySurah(surah);
      _invalidateMushafFuture();
      _clearSimpleQuranComRowCache();
    });
    _maybePrefetchSimpleQuranComCurrentContext();
  }

  void _selectPage(int page) {
    if (page == _selectedPage) {
      return;
    }
    setState(() {
      _selectedPage = page;
      _pendingJumpTarget = null;
      _clearInteractiveHighlights();
      _jumpScheduled = false;
      _ayahsFuture = _loadAyahsByPage(page);
      _invalidateMushafFuture();
      _clearSimpleQuranComRowCache();
    });
    if (_viewMode == _ReaderViewMode.mushaf) {
      _resetMushafScrollToTop();
    }
    _maybePrefetchSimpleQuranComCurrentContext();
  }

  void _selectVerseTabSurah(int surah) {
    if (surah < 1 || surah > 114 || surah == _verseTabSelectedSurah) {
      return;
    }
    setState(() {
      _verseTabSelectedSurah = surah;
      _verseTabAyahCountFuture = _loadVerseTabAyahCount(surah);
    });
  }

  Future<void> _jumpToSurahStartInMushaf(int surah) async {
    final ayahs = await ref.read(quranRepoProvider).getAyahsBySurah(surah);
    if (!mounted || _viewMode != _ReaderViewMode.mushaf) {
      return;
    }
    final page = _firstMadinaPage(ayahs);
    if (page == null) {
      _showSnackBar(_strings.noPageMetadataForSurah(surah));
      return;
    }

    setState(() {
      _selectedSurah = surah;
      _verseTabSelectedSurah = surah;
      _verseTabAyahCountFuture = _loadVerseTabAyahCount(surah);
    });
    _selectPage(page);
  }

  Future<void> _jumpToVerseInMushaf({
    required int surah,
    required int ayah,
  }) async {
    final page = await ref.read(quranRepoProvider).getPageForVerse(surah, ayah);
    if (!mounted || _viewMode != _ReaderViewMode.mushaf) {
      return;
    }
    if (page == null) {
      _showSnackBar(_strings.noPageMetadataForSurahAyah(surah, ayah));
      return;
    }
    setState(() {
      _selectedSurah = surah;
    });
    _selectPage(page);
  }

  void _jumpToJuzInMushaf(MushafJuzNavEntry entry) {
    _selectPage(entry.page);
  }

  void _ensureMushafJuzIndexFuture() {
    _juzIndexFuture ??= _loadMushafJuzIndex();
  }

  void _refreshCurrentView() {
    setState(() {
      _clearInteractiveHighlights();
      _jumpScheduled = false;
      _invalidateMushafFuture();
      _clearSimpleQuranComRowCache();
      if (_viewMode == _ReaderViewMode.mushaf) {
        _juzIndexFuture = null;
      }
      if (_mode == _ReaderMode.surah) {
        _ayahsFuture = _loadAyahsBySurah(_selectedSurah);
      } else {
        _availablePagesFuture = _loadAvailablePages();
        if (_selectedPage != null) {
          _ayahsFuture = _loadAyahsByPage(_selectedPage!);
        } else {
          _ayahsFuture = Future.value(const <AyahData>[]);
        }
      }
    });
    if (_viewMode == _ReaderViewMode.mushaf) {
      _resetMushafScrollToTop();
    }

    if (_mode == _ReaderMode.page && _selectedPage == null) {
      _resolvePageSelection(
        requestedPage: widget.page,
        target: null,
        showMissingTargetMessage: false,
      );
      return;
    }

    _maybePrefetchSimpleQuranComCurrentContext();
  }

  Future<void> _loadSurahMetadata() async {
    try {
      final metadata = ref.read(surahMetadataServiceProvider);
      await metadata.ensureLoaded();
      if (!mounted) {
        return;
      }
      final namesEn = <int, String>{};
      final namesAr = <int, String>{};
      for (final entry in metadata.getAll()) {
        namesEn[entry.number] = entry.en;
        namesAr[entry.number] = entry.ar;
      }
      setState(() {
        _surahNamesEn
          ..clear()
          ..addAll(namesEn);
        _surahNamesAr
          ..clear()
          ..addAll(namesAr);
      });
    } catch (_) {
      // Use "Surah N" fallback labels when metadata fails to load.
    }
  }

  String _surahLabelFor(int surahNumber) {
    final enName = _surahNamesEn[surahNumber];
    if (enName == null || enName.trim().isEmpty) {
      return '$surahNumber. ${_strings.surahLabel(surahNumber)}';
    }
    return '$surahNumber. $enName';
  }

  int _translationResourceIdForLanguage(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return _translationResourceEnglish;
      case AppLanguage.french:
        return _translationResourceFrench;
      case AppLanguage.portuguese:
        return _translationResourcePortuguese;
      case AppLanguage.arabic:
        // Arabic app language currently falls back to English translation.
        return _translationResourceEnglish;
    }
  }

  String _translationResourceLabelForId(int resourceId) {
    return _translationResourceLabelById[resourceId] ?? _strings.translation;
  }

  String _ayahKey(AyahData ayah) => '${ayah.surah}:${ayah.ayah}';

  GlobalKey _ayahRowKey(String ayahKey) {
    return _ayahRowKeys.putIfAbsent(
      ayahKey,
      () => GlobalKey(debugLabel: 'ayah_row_key_$ayahKey'),
    );
  }

  _VerseJumpTarget? _normalizeTarget({
    required int? surah,
    required int? ayah,
  }) {
    if (surah == null || ayah == null) {
      return null;
    }
    if (surah < 1 || surah > 114 || ayah < 1) {
      return null;
    }
    return _VerseJumpTarget(surah: surah, ayah: ayah);
  }

  _VerseRange? _normalizeRange() {
    final startSurah = widget.highlightStartSurah;
    final startAyah = widget.highlightStartAyah;
    final endSurah = widget.highlightEndSurah;
    final endAyah = widget.highlightEndAyah;

    if (startSurah == null ||
        startAyah == null ||
        endSurah == null ||
        endAyah == null) {
      return null;
    }
    if (startSurah < 1 ||
        startSurah > 114 ||
        endSurah < 1 ||
        endSurah > 114 ||
        startAyah < 1 ||
        endAyah < 1) {
      return null;
    }

    var start = _VersePosition(
      surah: startSurah,
      ayah: startAyah,
    );
    var end = _VersePosition(
      surah: endSurah,
      ayah: endAyah,
    );

    if (start.compareTo(end) > 0) {
      final temp = start;
      start = end;
      end = temp;
    }

    return _VerseRange(start: start, end: end);
  }

  bool _isRangeHighlighted(AyahData ayah) {
    final range = _rangeHighlight;
    if (range == null) {
      return false;
    }
    final position = _VersePosition(
      surah: ayah.surah,
      ayah: ayah.ayah,
    );
    return position.compareTo(range.start) >= 0 &&
        position.compareTo(range.end) <= 0;
  }

  void _queuePendingJump(List<AyahData> ayahs) {
    if (_jumpScheduled || _pendingJumpTarget == null) {
      return;
    }

    _jumpScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _jumpScheduled = false;
      await _performPendingJump(ayahs);
    });
  }

  Future<void> _performPendingJump(List<AyahData> ayahs) async {
    final pendingTarget = _pendingJumpTarget;
    if (!mounted || pendingTarget == null) {
      return;
    }

    final targetIndex = ayahs.indexWhere(
      (row) =>
          row.surah == pendingTarget.surah && row.ayah == pendingTarget.ayah,
    );
    if (targetIndex < 0) {
      setState(() {
        _pendingJumpTarget = null;
      });
      if (_mode == _ReaderMode.page) {
        _showSnackBar(_strings.targetAyahNotVisibleOnSelectedPage);
      } else {
        _showSnackBar(
          _strings.ayahNotFoundInSurah(
            pendingTarget.ayah,
            pendingTarget.surah,
          ),
        );
      }
      return;
    }

    final targetAyah = ayahs[targetIndex];
    final targetKey = _ayahKey(targetAyah);
    double? estimatedOffset;

    if (_ayahScrollController.hasClients) {
      final position = _ayahScrollController.position;
      final maxExtent = position.maxScrollExtent;
      final ratio = ayahs.length <= 1 ? 0.0 : targetIndex / (ayahs.length - 1);
      estimatedOffset = (maxExtent * ratio).clamp(0.0, maxExtent);
      _ayahScrollController.jumpTo(estimatedOffset);
    }

    BuildContext? rowContext = _ayahRowKey(targetKey).currentContext;
    for (var attempt = 0; attempt < 8 && rowContext == null; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      rowContext = _ayahRowKey(targetKey).currentContext;
      if (rowContext != null || !_ayahScrollController.hasClients) {
        continue;
      }

      final position = _ayahScrollController.position;
      final maxExtent = position.maxScrollExtent;
      final viewport = position.viewportDimension;
      final baseOffset = estimatedOffset ??
          (ayahs.length <= 1
              ? 0.0
              : (maxExtent * (targetIndex / (ayahs.length - 1))));
      final probeDirection = attempt.isEven ? -1.0 : 1.0;
      final probeMultiplier = ((attempt + 1) / 2.0);
      final probeOffset =
          (baseOffset + (probeDirection * probeMultiplier * (viewport * 0.75)))
              .clamp(0.0, maxExtent);

      if ((probeOffset - position.pixels).abs() > 1) {
        _ayahScrollController.jumpTo(probeOffset);
      }
    }

    if (rowContext == null && _ayahScrollController.hasClients) {
      final position = _ayahScrollController.position;
      final maxExtent = position.maxScrollExtent;
      final viewport =
          position.viewportDimension <= 0 ? 320.0 : position.viewportDimension;
      for (var probe = 0.0;
          probe <= maxExtent && rowContext == null;
          probe += viewport * 0.8) {
        _ayahScrollController.jumpTo(probe.clamp(0.0, maxExtent));
        await Future<void>.delayed(const Duration(milliseconds: 16));
        rowContext = _ayahRowKey(targetKey).currentContext;
      }
    }

    if (rowContext == null && _ayahScrollController.hasClients) {
      if (_ayahScrollController.hasClients) {
        final maxExtent = _ayahScrollController.position.maxScrollExtent;
        final fallbackOffset = (estimatedOffset ?? (targetIndex * 140.0)).clamp(
          0.0,
          maxExtent,
        );
        _ayahScrollController.jumpTo(fallbackOffset);
        await Future<void>.delayed(const Duration(milliseconds: 16));
        rowContext = _ayahRowKey(targetKey).currentContext;
      }
    }

    if (rowContext != null) {
      await Scrollable.ensureVisible(
        rowContext,
        duration: const Duration(milliseconds: 300),
        alignment: 0.2,
        curve: Curves.easeOut,
      );
    }

    if (!mounted) {
      return;
    }

    _jumpHighlightTimer?.cancel();
    setState(() {
      _pendingJumpTarget = null;
      _jumpHighlightedAyahKey = targetKey;
    });

    _jumpHighlightTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_jumpHighlightedAyahKey == targetKey) {
          _jumpHighlightedAyahKey = null;
        }
      });
    });
  }

  Future<void> _showAyahActions(AyahData ayah) async {
    final action = await showModalBottomSheet<_AyahAction>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const ValueKey('action_bookmark'),
                leading: const Icon(Icons.bookmark_add_outlined),
                title: Text(_strings.bookmarkVerse),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_AyahAction.bookmark),
              ),
              ListTile(
                key: const ValueKey('action_note'),
                leading: const Icon(Icons.note_alt_outlined),
                title: Text(_strings.addEditNote),
                onTap: () => Navigator.of(sheetContext).pop(_AyahAction.note),
              ),
              ListTile(
                key: const ValueKey('action_copy'),
                leading: const Icon(Icons.copy_outlined),
                title: Text(_strings.copyTextUthmani),
                onTap: () => Navigator.of(sheetContext).pop(_AyahAction.copy),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _AyahAction.bookmark:
        await _bookmarkAyah(ayah);
        break;
      case _AyahAction.note:
        await _addOrEditNote(ayah);
        break;
      case _AyahAction.copy:
        await _copyText(ayah);
        break;
    }
  }

  Future<void> _bookmarkAyah(AyahData ayah) async {
    try {
      final repo = ref.read(bookmarkRepoProvider);
      final existing = await repo.getBookmarkByAyah(
        surah: ayah.surah,
        ayah: ayah.ayah,
      );
      if (existing != null) {
        _showSnackBar(_strings.verseAlreadyBookmarked);
        return;
      }

      await repo.addBookmark(
        surah: ayah.surah,
        ayah: ayah.ayah,
      );
      _showSnackBar(_strings.bookmarkSaved);
    } catch (_) {
      _showSnackBar(_strings.failedToSaveBookmark);
    }
  }

  Future<void> _addOrEditNote(AyahData ayah) async {
    try {
      final noteRepo = ref.read(noteRepoProvider);
      final existingNotes = await noteRepo.getNotesForAyah(
        surah: ayah.surah,
        ayah: ayah.ayah,
      );
      final existing = existingNotes.isNotEmpty ? existingNotes.first : null;

      final draft = await _showNoteDialog(existing);
      if (draft == null) {
        return;
      }

      if (existing == null) {
        await noteRepo.createNote(
          surah: ayah.surah,
          ayah: ayah.ayah,
          title: draft.title,
          body: draft.body,
        );
        _showSnackBar(_strings.noteAdded);
      } else {
        final updated = await noteRepo.updateNote(
          id: existing.id,
          title: draft.title,
          body: draft.body,
        );
        _showSnackBar(
            updated ? _strings.noteUpdated : _strings.noteUpdateFailed);
      }
    } catch (_) {
      _showSnackBar(_strings.noteSaveFailed);
    }
  }

  Future<void> _copyText(AyahData ayah) async {
    _showSnackBar(_strings.copiedVerseText);
    unawaited(
      Clipboard.setData(
        ClipboardData(text: ayah.textUthmani),
      ).catchError((Object _, StackTrace __) {
        // Surface consistent UI feedback even if clipboard channel is unavailable.
      }),
    );
  }

  Future<_NoteDraft?> _showNoteDialog(NoteData? existing) async {
    final strings = _strings;
    return showDialog<_NoteDraft>(
      context: context,
      builder: (dialogContext) {
        return _ReaderNoteEditorDialog(
          existing: existing,
          strings: strings,
        );
      },
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _setMushafSettingsOpen(bool isOpen) {
    _mushafSettingsOpen = isOpen;
    ref.read(readerSettingsPaneOpenProvider.notifier).setOpen(isOpen);
  }

  double _readerTopActionsEndInset() {
    final isReaderSettingsOpen = ref.watch(readerSettingsPaneOpenProvider);
    return isReaderSettingsOpen ? 0 : _readerTopRightMenuClearance;
  }

  void _setHoveredMushafHoverState({
    required String? verseKey,
    required String? wordKey,
    required MushafWord? previewWord,
  }) {
    if (_hoveredMushafVerseKey == verseKey &&
        _hoveredMushafWordKey == wordKey &&
        _hoveredMushafPreviewWord == previewWord) {
      return;
    }
    setState(() {
      _hoveredMushafVerseKey = verseKey;
      _hoveredMushafWordKey = wordKey;
      _hoveredMushafPreviewWord = previewWord;
    });
  }

  Future<void> _handleMushafVerseTap(String verseKey) async {
    final ayah = _mushafAyahLookupByVerseKey[verseKey];
    if (ayah == null) {
      _showSnackBar(_strings.verseActionsUnavailable);
      return;
    }

    setState(() {
      _selectedMushafVerseKey = verseKey;
    });
    await _showAyahActions(ayah);
    if (!mounted) {
      return;
    }
    setState(() {
      if (_selectedMushafVerseKey == verseKey) {
        _selectedMushafVerseKey = null;
      }
    });
  }

  void _logMushafInteractionDisabledOnce({
    required int page,
    required String reason,
  }) {
    final key = '$page|$reason';
    if (_lastMushafInteractionWarningKey == key) {
      return;
    }
    _lastMushafInteractionWarningKey = key;
    debugPrint('Mushaf verse interaction disabled on page $page: $reason');
  }

  void _clearSimpleQuranComRowCache() {
    _simpleQuranComRowFutureCache.clear();
    _verseContextMetaFutureCache.clear();
  }

  double _mushafFontScaleForStep(int step) {
    final scale = 1.0 + ((step - 5) * 0.08);
    return scale.clamp(0.68, 1.32);
  }

  void _setMushafFontStep(int nextStep) {
    final clamped = nextStep.clamp(1, 9);
    if (clamped == _mushafFontStep) {
      return;
    }
    setState(() {
      _mushafFontStep = clamped;
    });
  }

  void _resetMushafSettings() {
    setState(() {
      _mushafFontStep = 5;
      _mushafSettingsTab = _MushafSettingsTab.arabic;
      if (_arabicRenderMode != _ArabicRenderMode.plain) {
        _arabicRenderMode = _ArabicRenderMode.plain;
        _invalidateMushafFuture();
      }
    });
  }

  int _activeMushafId() {
    return _arabicRenderMode == _ArabicRenderMode.tajweed ? 19 : 1;
  }

  QcfFontVariant _activeQcfVariant() {
    return _arabicRenderMode == _ArabicRenderMode.tajweed
        ? QcfFontVariant.v4tajweed
        : QcfFontVariant.v2;
  }

  void _maybePrefetchSimpleQuranComCurrentContext() {
    if (_viewMode != _ReaderViewMode.simple) {
      return;
    }
    unawaited(_prefetchSimpleQuranComCurrentContext());
  }

  Future<void> _prefetchSimpleQuranComCurrentContext() async {
    if (_viewMode != _ReaderViewMode.simple) {
      return;
    }

    final mushafId = _activeMushafId();
    final translationResourceId = _translationResourceIdForLanguage(
        ref.read(appPreferencesProvider).language);
    var page = _mode == _ReaderMode.page ? _selectedPage : null;

    if (page == null) {
      final ayahsFuture = _ayahsFuture;
      if (ayahsFuture != null) {
        try {
          final ayahs = await ayahsFuture;
          page = _firstMadinaPage(ayahs);
        } catch (_) {
          return;
        }
      }
    }

    if (page == null) {
      return;
    }

    _prefetchSimpleQuranComPage(
      page: page,
      mushafId: mushafId,
      translationResourceId: translationResourceId,
    );
    if (page < 604) {
      _prefetchSimpleQuranComPage(
        page: page + 1,
        mushafId: mushafId,
        translationResourceId: translationResourceId,
      );
    }
  }

  void _prefetchSimpleQuranComForAyahs(List<AyahData> ayahs) {
    if (_viewMode != _ReaderViewMode.simple) {
      return;
    }

    final mushafId = _activeMushafId();
    final translationResourceId = _translationResourceIdForLanguage(
        ref.read(appPreferencesProvider).language);
    var page = _mode == _ReaderMode.page ? _selectedPage : null;
    page ??= _firstMadinaPage(ayahs);
    if (page == null) {
      return;
    }

    _prefetchSimpleQuranComPage(
      page: page,
      mushafId: mushafId,
      translationResourceId: translationResourceId,
    );
    if (page < 604) {
      _prefetchSimpleQuranComPage(
        page: page + 1,
        mushafId: mushafId,
        translationResourceId: translationResourceId,
      );
    }
  }

  void _prefetchSimpleQuranComPage({
    required int page,
    required int mushafId,
    required int translationResourceId,
  }) {
    if (page < 1 || page > 604) {
      return;
    }
    final prefetchKey = '$page|$mushafId|t$translationResourceId';
    if (!_simpleQuranComPrefetchKeys.add(prefetchKey)) {
      return;
    }

    final api = ref.read(quranComApiProvider);
    unawaited(
      () async {
        try {
          await api.getPageWithVerses(
            page: page,
            mushafId: mushafId,
            translationResourceId: translationResourceId,
          );
        } catch (_) {
          _simpleQuranComPrefetchKeys.remove(prefetchKey);
        }
      }(),
    );
  }

  int? _firstMadinaPage(List<AyahData> ayahs) {
    for (final ayah in ayahs) {
      final page = ayah.pageMadina;
      if (page != null) {
        return page;
      }
    }
    return null;
  }

  Future<_VerseByVerseRowRenderData>? _getSimpleQuranComVerseFuture(
    AyahData ayah,
  ) {
    final page = ayah.pageMadina;
    if (page == null) {
      return null;
    }

    final ayahKey = _ayahKey(ayah);
    final mushafId = _activeMushafId();
    final variant = _activeQcfVariant();
    final translationResourceId = _translationResourceIdForLanguage(
        ref.read(appPreferencesProvider).language);
    final cacheKey = '$ayahKey|m$mushafId|t$translationResourceId';
    return _simpleQuranComRowFutureCache.putIfAbsent(
      cacheKey,
      () => _loadSimpleQuranComVerseRenderData(
        page: page,
        mushafId: mushafId,
        variant: variant,
        verseKey: ayahKey,
        translationResourceId: translationResourceId,
      ),
    );
  }

  Future<_VerseByVerseRowRenderData> _loadSimpleQuranComVerseRenderData({
    required int page,
    required int mushafId,
    required QcfFontVariant variant,
    required String verseKey,
    required int translationResourceId,
  }) async {
    final fontSelection = await ref.read(qcfFontManagerProvider).ensurePageFont(
          page: page,
          variant: variant,
        );
    final verseData = await ref.read(quranComApiProvider).getVerseDataByPage(
          page: page,
          mushafId: mushafId,
          verseKey: verseKey,
          translationResourceId: translationResourceId,
        );
    final words = verseData.words;
    if (words.isEmpty) {
      throw QuranComApiException('No words found for verse $verseKey.');
    }

    return _VerseByVerseRowRenderData(
      qcfFamilyName: fontSelection.familyName,
      words: words,
      translationText: _resolveVerseTranslationText(
            verseData,
            translationResourceId: translationResourceId,
          ) ??
          _strings.translationUnavailable,
    );
  }

  String? _resolveVerseTranslationText(
    MushafVerseData verseData, {
    required int translationResourceId,
  }) {
    for (final translation in verseData.translations) {
      if (translation.resourceId == translationResourceId) {
        final cleaned = _cleanTranslationText(translation.text);
        if (cleaned.isNotEmpty) {
          return cleaned;
        }
      }
    }
    for (final translation in verseData.translations) {
      final cleaned = _cleanTranslationText(translation.text);
      if (cleaned.isNotEmpty) {
        return cleaned;
      }
    }
    return null;
  }

  String _cleanTranslationText(String? rawText) {
    if (rawText == null) {
      return '';
    }
    var text = rawText.replaceAll(RegExp(r'<[^>]*>'), ' ');
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', '\'');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Widget _buildSimpleQuranComArabicContent({
    required BuildContext context,
    required String ayahKey,
    required _VerseByVerseRowRenderData data,
  }) {
    final baseArabicStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
              fontFamily: 'UthmanicHafs',
              fontSize: 34,
              height: 1.65,
            ) ??
        const TextStyle(
          fontFamily: 'UthmanicHafs',
          fontSize: 34,
          height: 1.65,
        );
    final qcfStyle = baseArabicStyle.copyWith(fontFamily: data.qcfFamilyName);
    final fallbackStyle = baseArabicStyle.copyWith(fontFamily: 'UthmanicHafs');
    return Wrap(
      key: ValueKey('ayah_qurancom_text_$ayahKey'),
      textDirection: TextDirection.rtl,
      spacing: _verseByVerseWordGap,
      runSpacing: _verseByVerseWordRunSpacing,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var wordIndex = 0; wordIndex < data.words.length; wordIndex++)
          if (_wordTextForSpan(data.words[wordIndex]).isNotEmpty)
            _buildVerseByVerseWordWidget(
              word: data.words[wordIndex],
              ayahKey: ayahKey,
              wordIndex: wordIndex,
              qcfStyle: qcfStyle,
              fallbackStyle: fallbackStyle,
            ),
      ],
    );
  }

  Widget _buildVerseByVerseWordWidget({
    required MushafWord word,
    required String ayahKey,
    required int wordIndex,
    required TextStyle qcfStyle,
    required TextStyle fallbackStyle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final verseWordKey = 'verse:$ayahKey:${word.position ?? wordIndex}';
    final hoveredWord = _hoveredMushafWordKey == verseWordKey;
    final isQcfWord = (word.codeV2 ?? '').isNotEmpty;
    final isEndMarker = (word.charTypeName ?? '').trim().toLowerCase() == 'end';
    final isTajweedV4Qcf =
        _arabicRenderMode == _ArabicRenderMode.tajweed && isQcfWord;
    final baseStyle = isQcfWord ? qcfStyle : fallbackStyle;
    final resolvedStyle = hoveredWord && !isTajweedV4Qcf
        ? baseStyle.copyWith(color: colorScheme.secondary)
        : baseStyle;
    final highlightColor = hoveredWord
        ? colorScheme.primary.withValues(
            alpha: isTajweedV4Qcf ? 0.18 : 0.24,
          )
        : null;

    Widget child = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1),
      decoration: highlightColor != null
          ? BoxDecoration(
              color: highlightColor,
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Text(
        _wordTextForSpan(word),
        key: ValueKey('reader_verse_word_${ayahKey}_$wordIndex'),
        textDirection: TextDirection.rtl,
        maxLines: 1,
        softWrap: false,
        textScaler: const TextScaler.linear(1.0),
        style: resolvedStyle,
      ),
    );

    if (!isEndMarker) {
      child = Tooltip(
        key: ValueKey('reader_verse_word_tooltip_${ayahKey}_$wordIndex'),
        message: _mushafWordTooltipMessage(word),
        waitDuration: Duration.zero,
        child: child,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHoveredMushafHoverState(
        verseKey: ayahKey,
        wordKey: verseWordKey,
        previewWord: word,
      ),
      onExit: (_) {
        if (_hoveredMushafWordKey == verseWordKey) {
          _setHoveredMushafHoverState(
            verseKey: null,
            wordKey: null,
            previewWord: null,
          );
        }
      },
      child: child,
    );
  }

  Widget _buildAyahPanel() {
    if (_viewMode == _ReaderViewMode.mushaf) {
      return _buildMushafPanel();
    }
    return _buildVerseByVersePanel();
  }

  Widget _buildVerseByVersePanel() {
    final ayahsFuture = _ayahsFuture;
    final preferences = ref.watch(appPreferencesProvider);
    final strings = AppStrings.of(preferences.language);
    final translationResourceId =
        _translationResourceIdForLanguage(preferences.language);
    if (ayahsFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<AyahData>>(
      future: ayahsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(strings.failedToLoadAyahs),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const ValueKey('reader_retry_button'),
                  onPressed: _refreshCurrentView,
                  child: Text(strings.retry),
                ),
              ],
            ),
          );
        }

        final ayahs = snapshot.data ?? const <AyahData>[];
        if (ayahs.isEmpty) {
          if (_mode == _ReaderMode.page && _selectedPage == null) {
            return Center(
              child: Text(
                strings.noPageMetadataImportInSettings,
              ),
            );
          }
          return Center(
            child: Text(
              _mode == _ReaderMode.surah
                  ? strings.noAyahsForSurah(_selectedSurah)
                  : strings.noAyahsForPage(_selectedPage),
            ),
          );
        }
        _queuePendingJump(ayahs);
        _prefetchSimpleQuranComForAyahs(ayahs);
        final chapterHeader = _buildVerseByVerseChapterHeader(ayahs);
        final itemCount = ayahs.length + (chapterHeader == null ? 0 : 1);
        final contextPage = _resolveVerseByVerseContextPage(ayahs);
        final mushafId = _activeMushafId();

        return Column(
          children: [
            if (contextPage != null)
              FutureBuilder<MushafPageMeta>(
                future: _getVerseByVerseContextMetaFuture(
                  page: contextPage,
                  mushafId: mushafId,
                  translationResourceId: translationResourceId,
                ),
                builder: (context, contextSnapshot) {
                  final meta = contextSnapshot.data;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    child: _buildVerseByVerseContextRow(
                      pageNumber: contextPage,
                      meta: meta,
                    ),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: _buildVerseByVerseTopActionsRow(
                translationResourceId: translationResourceId,
              ),
            ),
            Expanded(
              child: ListView.builder(
                key: const ValueKey('reader_ayah_list'),
                controller: _ayahScrollController,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                itemBuilder: (context, index) {
                  if (chapterHeader != null && index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: chapterHeader,
                    );
                  }
                  final ayahIndex = chapterHeader == null ? index : index - 1;
                  final ayah = ayahs[ayahIndex];
                  final ayahKey = _ayahKey(ayah);

                  Widget buildFallbackCell() {
                    return _buildVerseByVerseAyahCell(
                      ayah: ayah,
                      ayahKey: ayahKey,
                      renderData: null,
                      translationText: strings.translationUnavailable,
                    );
                  }

                  final quranComFuture = _getSimpleQuranComVerseFuture(ayah);
                  if (quranComFuture == null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: buildFallbackCell(),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: FutureBuilder<_VerseByVerseRowRenderData>(
                      future: quranComFuture,
                      builder: (context, rowSnapshot) {
                        final renderData = rowSnapshot.data;
                        if (rowSnapshot.hasError || renderData == null) {
                          return buildFallbackCell();
                        }

                        return _buildVerseByVerseAyahCell(
                          ayah: ayah,
                          ayahKey: ayahKey,
                          renderData: renderData,
                          translationText: renderData.translationText,
                        );
                      },
                    ),
                  );
                },
                itemCount: itemCount,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget? _buildVerseByVerseChapterHeader(List<AyahData> ayahs) {
    if (ayahs.isEmpty) {
      return null;
    }
    final firstAyah = ayahs.first;
    if (firstAyah.ayah != 1) {
      return null;
    }

    final chapter = firstAyah.surah;
    final transliterated =
        _surahNamesEn[chapter] ?? _strings.surahLabel(chapter);
    final translated = _strings.surahLabel(chapter);
    final showBasmala = chapter != 1 && chapter != 9;
    final colorScheme = Theme.of(context).colorScheme;
    final headerTitleStyle =
        Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            );
    final headerSubtitleStyle =
        Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w500,
            );

    return ConstrainedBox(
      key: ValueKey('reader_verse_chapter_header_$chapter'),
      constraints: const BoxConstraints(maxWidth: _mushafChapterHeaderMaxWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      chapter.toString().padLeft(3, '0'),
                      style: const TextStyle(
                        fontFamily: 'SurahNames',
                        fontSize: _mushafChapterIconFontSize,
                        height: 0.9,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$chapter. $transliterated',
                          style: headerTitleStyle,
                        ),
                        Text(
                          translated,
                          style: headerSubtitleStyle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (showBasmala) ...[
              const SizedBox(height: 8),
              SvgPicture.asset(
                'assets/quran/bismillah.svg',
                key: ValueKey('reader_verse_external_basmala_$chapter'),
                width: 260,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 4),
              Text(
                _strings.basmalaTranslation,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerseByVerseAyahCell({
    required AyahData ayah,
    required String ayahKey,
    required _VerseByVerseRowRenderData? renderData,
    required String translationText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlighted = _jumpHighlightedAyahKey == ayahKey ||
        _isRangeHighlighted(ayah) ||
        _tappedAyahKey == ayahKey;
    final background = highlighted
        ? colorScheme.primaryContainer.withValues(alpha: 0.2)
        : Colors.transparent;

    final arabicWidget = renderData == null
        ? _buildVerseByVerseFallbackArabicContent(ayah)
        : _buildSimpleQuranComArabicContent(
            context: context,
            ayahKey: ayahKey,
            data: renderData,
          );

    return KeyedSubtree(
      key: _ayahRowKey(ayahKey),
      child: MouseRegion(
        key: ValueKey('ayah_mouse_$ayahKey'),
        onEnter: (_) {
          setState(() {
            _hoveredAyahKey = ayahKey;
          });
        },
        onExit: (_) {
          if (_hoveredAyahKey == ayahKey) {
            setState(() {
              _hoveredAyahKey = null;
            });
          }
        },
        child: Material(
          key: ValueKey('ayah_material_$ayahKey'),
          color: background,
          child: Container(
            key: ValueKey('ayah_row_$ayahKey'),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVerseByVerseTopActionRow(
                  ayah: ayah,
                  ayahKey: ayahKey,
                ),
                const SizedBox(height: 8),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: arabicWidget,
                ),
                const SizedBox(height: 12),
                Text(
                  translationText,
                  key: ValueKey('reader_verse_translation_$ayahKey'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                          ) ??
                      const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                      ),
                ),
                const SizedBox(height: 14),
                _buildVerseByVerseBottomActionRow(ayahKey: ayahKey),
                const SizedBox(height: 14),
                const Divider(height: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerseByVerseTopActionRow({
    required AyahData ayah,
    required String ayahKey,
  }) {
    return SingleChildScrollView(
      key: ValueKey('reader_verse_top_actions_$ayahKey'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text(
            ayahKey,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: ValueKey('reader_verse_action_play_$ayahKey'),
            icon: const Icon(Icons.play_arrow_rounded),
            tooltip: _strings.listen,
            onPressed: () => _showSnackBar(_strings.audioControlsComingSoon),
          ),
          IconButton(
            key: ValueKey('reader_verse_action_bookmark_$ayahKey'),
            icon: const Icon(Icons.bookmark_border),
            tooltip: _strings.bookmarkVerse,
            onPressed: () => unawaited(_bookmarkAyah(ayah)),
          ),
          IconButton(
            key: ValueKey('reader_verse_action_copy_$ayahKey'),
            icon: const Icon(Icons.copy_outlined),
            tooltip: _strings.copy,
            onPressed: () => unawaited(_copyText(ayah)),
          ),
          IconButton(
            key: ValueKey('reader_verse_action_share_$ayahKey'),
            icon: const Icon(Icons.share_outlined),
            tooltip: _strings.share,
            onPressed: () => _showSnackBar(_strings.shareComingSoon),
          ),
          IconButton(
            key: ValueKey('reader_verse_action_note_$ayahKey'),
            icon: const Icon(Icons.edit_note_outlined),
            tooltip: _strings.addEditNote,
            onPressed: () => unawaited(_addOrEditNote(ayah)),
          ),
          IconButton(
            key: ValueKey('reader_verse_action_more_$ayahKey'),
            icon: const Icon(Icons.more_horiz),
            tooltip: _strings.more,
            onPressed: () => unawaited(_showAyahActions(ayah)),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseByVerseBottomActionRow({
    required String ayahKey,
  }) {
    final textColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final rowStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: textColor,
            ) ??
        TextStyle(color: textColor);
    return SingleChildScrollView(
      key: ValueKey('reader_verse_bottom_actions_$ayahKey'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildVerseByVerseBottomActionChip(
            key: ValueKey('reader_verse_tafsir_$ayahKey'),
            icon: Icons.menu_book_outlined,
            label: _strings.tafsirs,
            style: rowStyle,
            onTap: () => _showSnackBar(_strings.tafsirsComingSoon),
          ),
          const SizedBox(width: 16),
          _buildVerseByVerseBottomActionChip(
            key: ValueKey('reader_verse_lessons_$ayahKey'),
            icon: Icons.school_outlined,
            label: _strings.lessons,
            style: rowStyle,
            onTap: () => _showSnackBar(_strings.lessonsComingSoon),
          ),
          const SizedBox(width: 16),
          _buildVerseByVerseBottomActionChip(
            key: ValueKey('reader_verse_reflections_$ayahKey'),
            icon: Icons.chat_bubble_outline,
            label: _strings.reflections,
            style: rowStyle,
            onTap: () => _showSnackBar(_strings.reflectionsComingSoon),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseByVerseFallbackArabicContent(AyahData ayah) {
    final baseArabicStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
              fontFamily: 'UthmanicHafs',
              fontSize: 34,
              height: 1.6,
            ) ??
        const TextStyle(
          fontFamily: 'UthmanicHafs',
          fontSize: 34,
          height: 1.6,
        );
    final tajweedService = ref.read(tajweedTagsServiceProvider);
    final tajweedEnabled = _arabicRenderMode == _ArabicRenderMode.tajweed &&
        tajweedService.hasAnyTags;
    if (!tajweedEnabled) {
      return Text(
        ayah.textUthmani,
        textAlign: TextAlign.right,
        style: baseArabicStyle,
      );
    }

    final tajweedHtml = tajweedService.getTajweedHtmlFor(ayah.surah, ayah.ayah);
    if (tajweedHtml == null) {
      return Text(
        ayah.textUthmani,
        textAlign: TextAlign.right,
        style: baseArabicStyle,
      );
    }
    final fallbackTextColor =
        baseArabicStyle.color ?? Theme.of(context).colorScheme.onSurface;
    return RichText(
      textAlign: TextAlign.right,
      text: TextSpan(
        children: buildTajweedSpans(
          tajweedHtml: tajweedHtml,
          baseStyle: baseArabicStyle,
          classColors: tajweedClassColors,
          fallbackColor: fallbackTextColor,
        ),
      ),
    );
  }

  Widget _buildVerseByVerseBottomActionChip({
    required Key key,
    required IconData icon,
    required String label,
    required TextStyle style,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: style.color),
            const SizedBox(width: 6),
            Text(label, style: style),
          ],
        ),
      ),
    );
  }

  int? _resolveVerseByVerseContextPage(List<AyahData> ayahs) {
    final selectedPage = _selectedPage;
    if (selectedPage != null) {
      return selectedPage;
    }
    return _firstMadinaPage(ayahs);
  }

  Future<MushafPageMeta> _getVerseByVerseContextMetaFuture({
    required int page,
    required int mushafId,
    required int translationResourceId,
  }) {
    final cacheKey = '$page|$mushafId|t$translationResourceId';
    return _verseContextMetaFutureCache.putIfAbsent(
      cacheKey,
      () async {
        final pageData = await ref.read(quranComApiProvider).getPageWithVerses(
              page: page,
              mushafId: mushafId,
              translationResourceId: translationResourceId,
            );
        return pageData.meta;
      },
    );
  }

  Widget _buildVerseByVerseContextRow({
    required int pageNumber,
    required MushafPageMeta? meta,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final subduedStyle = textTheme.titleMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.82),
      fontWeight: FontWeight.w500,
    );
    return SingleChildScrollView(
      key: const ValueKey('reader_verse_context_scroll'),
      scrollDirection: Axis.horizontal,
      child: Row(
        key: const ValueKey('reader_verse_context_row'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bookmark_border, size: 18),
          const SizedBox(width: 8),
          Text(
            _strings.pageLabel(pageNumber),
            key: const ValueKey('reader_page_label'),
          ),
          if (meta?.juzNumber != null) ...[
            const SizedBox(width: 12),
            Text(_strings.juzLabel(meta!.juzNumber!), style: subduedStyle),
          ],
          if (meta?.hizbNumber != null) ...[
            const SizedBox(width: 12),
            Text(_strings.hizbLabel(meta!.hizbNumber!), style: subduedStyle),
          ],
        ],
      ),
    );
  }

  Widget _buildVerseByVerseTopActionsRow({
    required int translationResourceId,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final translationLabel = _strings.translationLabel(
      _translationResourceLabelForId(translationResourceId),
    );
    final topActionsEndInset = _readerTopActionsEndInset();

    return Padding(
      padding: EdgeInsetsDirectional.only(end: topActionsEndInset),
      child: Row(
        key: const ValueKey('reader_verse_top_actions'),
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('reader_verse_top_actions_scroll'),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('reader_verse_listen_button'),
                    onPressed: null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(_strings.listen),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    key: const ValueKey('reader_verse_translation_button'),
                    onPressed: () {
                      setState(() {
                        _setMushafSettingsOpen(true);
                        _mushafSettingsTab = _MushafSettingsTab.translation;
                      });
                    },
                    child: Text(translationLabel),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _strings.tajweedColors,
                      key: const ValueKey('reader_verse_tajweed_colors'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: const ValueKey('reader_verse_settings_button'),
            icon: Icon(_mushafSettingsOpen ? Icons.close : Icons.tune),
            tooltip: _mushafSettingsOpen
                ? _strings.closeSettings
                : _strings.openSettings,
            onPressed: () {
              setState(() {
                _setMushafSettingsOpen(!_mushafSettingsOpen);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMushafPanel() {
    final selectedPage = _selectedPage;
    if (selectedPage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final mushafFuture = _getMushafFuture(page: selectedPage);
    return FutureBuilder<_MushafRenderData>(
      future: mushafFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_strings.failedToLoadMushafPage),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const ValueKey('reader_mushaf_retry_button'),
                  onPressed: () {
                    setState(() {
                      _invalidateMushafFuture();
                    });
                  },
                  child: Text(_strings.retry),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return Center(child: Text(_strings.noMushafDataAvailable));
        }
        if (_pendingMushafScrollReset) {
          _resetMushafScrollToTop();
        }
        _mushafAyahLookupByVerseKey = data.ayahLookupByVerseKey;
        final displayLines = _buildMushafDisplayLines(data.pageData);
        final interactionEnabled =
            _hasCompleteMushafWordVerseKeys(data.pageData);
        if (!interactionEnabled && data.pageData.verses.isNotEmpty) {
          _logMushafInteractionDisabledOnce(
            page: selectedPage,
            reason: 'Mushaf words are missing verse linkage.',
          );
        }
        final chapterHeader = _buildMushafExternalChapterHeader(data.pageData);
        if (displayLines.isEmpty) {
          return Center(child: Text(_strings.noMushafTextAvailable));
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: _buildMushafContextRow(
                pageNumber: selectedPage,
                meta: data.pageData.meta,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: _buildMushafTopActionsRow(),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const horizontalPad = 16.0;
                  final verticalPad = constraints.maxHeight * 0.03;
                  final availableWidth =
                      (constraints.maxWidth - (2 * horizontalPad))
                          .clamp(0.0, double.infinity);
                  if (availableWidth <= 0 || constraints.maxHeight <= 0) {
                    return const SizedBox.shrink();
                  }

                  final viewportHeight = MediaQuery.sizeOf(context).height;
                  final upperBound =
                      math.min(_mushafCanvasMaxWidth, availableWidth);
                  if (upperBound <= 0) {
                    return const SizedBox.shrink();
                  }
                  final lowerBound =
                      math.min(_mushafCanvasMinWidth, upperBound);
                  final targetCanvasWidth =
                      viewportHeight * _mushafTargetLineWidthToViewportHeight;
                  final canvasWidth = targetCanvasWidth
                      .clamp(lowerBound, upperBound)
                      .toDouble();
                  final renderedLineCount = math.max(displayLines.length, 1);
                  final fontScale = _mushafFontScaleForStep(_mushafFontStep);
                  final lineHeight = viewportHeight *
                      _mushafLineHeightToViewportHeight *
                      fontScale;
                  if (lineHeight <= 0) {
                    return const SizedBox.shrink();
                  }
                  final canvasHeight = lineHeight * renderedLineCount;
                  final qcfFontSize = viewportHeight *
                      _mushafQcfFontSizeToViewportHeight *
                      fontScale;
                  final fallbackFontSize = viewportHeight *
                      _mushafFallbackFontSizeToViewportHeight *
                      fontScale;

                  return Scrollbar(
                    controller: _mushafScrollController,
                    child: SingleChildScrollView(
                      key: const ValueKey('reader_mushaf_scroll'),
                      controller: _mushafScrollController,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPad,
                          vertical: verticalPad,
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: canvasWidth,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (chapterHeader != null)
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(12, 8, 12, 4),
                                    child: chapterHeader,
                                  ),
                                SizedBox(
                                  key: const ValueKey('reader_mushaf_canvas'),
                                  width: canvasWidth,
                                  height: canvasHeight,
                                  child: Column(
                                    children: [
                                      for (final displayLine in displayLines)
                                        SizedBox(
                                          key: ValueKey(
                                            'reader_mushaf_line_${displayLine.lineNumber}',
                                          ),
                                          height: lineHeight,
                                          child: _buildMushafWordLine(
                                            context: context,
                                            lineWords: displayLine.words,
                                            qcfFontFamily:
                                                data.fontSelection.familyName,
                                            maxTextWidth: canvasWidth,
                                            lineHeight: lineHeight,
                                            pageNumber: selectedPage,
                                            lineNumber: displayLine.lineNumber,
                                            interactionEnabled:
                                                interactionEnabled,
                                            hoveredVerseKey:
                                                _hoveredMushafVerseKey,
                                            selectedVerseKey:
                                                _selectedMushafVerseKey,
                                            qcfFontSizeBase: qcfFontSize,
                                            fallbackFontSizeBase:
                                                fallbackFontSize,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMushafContextRow({
    required int pageNumber,
    required MushafPageMeta meta,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final subduedStyle = textTheme.titleMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.82),
      fontWeight: FontWeight.w500,
    );

    return SingleChildScrollView(
      key: const ValueKey('reader_mushaf_context_scroll'),
      scrollDirection: Axis.horizontal,
      child: Row(
        key: const ValueKey('reader_mushaf_context_row'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bookmark_border, size: 18),
          const SizedBox(width: 8),
          Text(
            _strings.pageLabel(pageNumber),
            key: const ValueKey('reader_page_label'),
          ),
          if (meta.juzNumber != null) ...[
            const SizedBox(width: 12),
            Text(_strings.juzLabel(meta.juzNumber!), style: subduedStyle),
          ],
          if (meta.hizbNumber != null) ...[
            const SizedBox(width: 12),
            Text(_strings.hizbLabel(meta.hizbNumber!), style: subduedStyle),
          ],
        ],
      ),
    );
  }

  Widget _buildMushafTopActionsRow() {
    final colorScheme = Theme.of(context).colorScheme;
    final topActionsEndInset = _readerTopActionsEndInset();
    return Padding(
      padding: EdgeInsetsDirectional.only(end: topActionsEndInset),
      child: Row(
        key: const ValueKey('reader_mushaf_top_actions'),
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('reader_mushaf_top_actions_scroll'),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('reader_mushaf_listen_button'),
                    onPressed: null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(_strings.listen),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const ValueKey('reader_mushaf_language_arabic'),
                    onPressed: () {},
                    child: Text(_strings.arabic),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    key: const ValueKey('reader_mushaf_language_translation'),
                    onPressed: () {
                      setState(() {
                        _setMushafSettingsOpen(true);
                        _mushafSettingsTab = _MushafSettingsTab.translation;
                      });
                    },
                    child: Text(_strings.translation),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _strings.tajweedColors,
                      key: const ValueKey('reader_mushaf_tajweed_colors'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: const ValueKey('reader_mushaf_settings_button'),
            icon: Icon(_mushafSettingsOpen ? Icons.close : Icons.tune),
            tooltip: _mushafSettingsOpen
                ? _strings.closeSettings
                : _strings.openSettings,
            onPressed: () {
              setState(() {
                _setMushafSettingsOpen(!_mushafSettingsOpen);
              });
            },
          ),
        ],
      ),
    );
  }

  List<_MushafDisplayLine> _buildMushafDisplayLines(MushafPageData pageData) {
    final wordsByLine = <int, List<_MushafLineWord>>{};

    for (final word in pageData.words) {
      final lineNumber = word.lineNumber;
      if (lineNumber == null || lineNumber < 1 || lineNumber > 15) {
        continue;
      }
      final displayText = _wordTextForSpan(word);
      if (displayText.isEmpty) {
        continue;
      }
      final verseKey = (word.verseKey ?? '').trim();
      wordsByLine.putIfAbsent(lineNumber, () => <_MushafLineWord>[]).add(
            _MushafLineWord(
              word: word,
              verseKey: verseKey.isEmpty ? null : verseKey,
              lineNumber: lineNumber,
              isEndMarker: (word.charTypeName ?? '').toLowerCase() == 'end',
              displayText: displayText,
              useQcf: (word.codeV2 ?? '').isNotEmpty,
            ),
          );
    }

    final nonEmptyLineNumbers = wordsByLine.keys.toList(growable: false)
      ..sort();
    return [
      for (final lineNumber in nonEmptyLineNumbers)
        _MushafDisplayLine(
          lineNumber: lineNumber,
          words: wordsByLine[lineNumber]!,
        ),
    ];
  }

  bool _hasCompleteMushafWordVerseKeys(MushafPageData pageData) {
    var hasRenderableWords = false;
    for (final word in pageData.words) {
      final lineNumber = word.lineNumber;
      if (lineNumber == null || lineNumber < 1 || lineNumber > 15) {
        continue;
      }
      final displayText = _wordTextForSpan(word);
      if (displayText.isEmpty) {
        continue;
      }
      hasRenderableWords = true;
      final verseKey = (word.verseKey ?? '').trim();
      if (verseKey.isEmpty) {
        return false;
      }
    }
    return hasRenderableWords;
  }

  Widget? _buildMushafExternalChapterHeader(MushafPageData pageData) {
    final chapter = pageData.meta.firstChapterId ??
        _chapterFromVerseKey(pageData.meta.firstVerseKey);
    final verseNumber = pageData.meta.firstVerseNumber ??
        _ayahFromVerseKey(pageData.meta.firstVerseKey);
    if (chapter == null || verseNumber != 1) {
      return null;
    }

    final transliterated =
        _surahNamesEn[chapter] ?? _strings.surahLabel(chapter);
    final translated = _strings.surahLabel(chapter);
    final showBasmala = chapter != 1 && chapter != 9;
    final colorScheme = Theme.of(context).colorScheme;
    final headerTitleStyle =
        Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            );
    final headerSubtitleStyle =
        Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w500,
            );

    return ConstrainedBox(
      key: ValueKey('reader_mushaf_chapter_header_$chapter'),
      constraints: const BoxConstraints(maxWidth: _mushafChapterHeaderMaxWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      chapter.toString().padLeft(3, '0'),
                      key: ValueKey('reader_mushaf_chapter_icon_$chapter'),
                      style: const TextStyle(
                        fontFamily: 'SurahNames',
                        fontSize: _mushafChapterIconFontSize,
                        height: 0.9,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$chapter. $transliterated',
                          style: headerTitleStyle,
                        ),
                        Text(
                          translated,
                          style: headerSubtitleStyle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (showBasmala) ...[
              const SizedBox(height: 8),
              SvgPicture.asset(
                'assets/quran/bismillah.svg',
                key: ValueKey('reader_mushaf_external_basmala_$chapter'),
                width: 260,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 4),
              Text(
                _strings.basmalaTranslation,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMushafWordLine({
    required BuildContext context,
    required List<_MushafLineWord> lineWords,
    required String qcfFontFamily,
    required double maxTextWidth,
    required double lineHeight,
    required double qcfFontSizeBase,
    required double fallbackFontSizeBase,
    required int pageNumber,
    required int lineNumber,
    required bool interactionEnabled,
    required String? hoveredVerseKey,
    required String? selectedVerseKey,
  }) {
    final shouldCenter = _isStaticCenteredMushafLine(
      pageNumber: pageNumber,
      lineNumber: lineNumber,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final safeLineHeight = lineHeight <= 0 ? 1.0 : lineHeight;
    final qcfFontSize = math.min(qcfFontSizeBase, safeLineHeight * 0.94);
    final fallbackFontSize =
        math.min(fallbackFontSizeBase, safeLineHeight * 0.98);
    final baseQcfStyle = TextStyle(
      fontFamily: qcfFontFamily,
      fontSize: qcfFontSize,
      height: 1.0,
      color: colorScheme.onSurface,
    );
    final baseFallbackStyle = TextStyle(
      fontFamily: 'UthmanicHafs',
      fontSize: fallbackFontSize,
      height: 1.0,
      color: colorScheme.onSurface,
    );

    if (lineWords.isEmpty) {
      return const SizedBox.expand();
    }

    var scale = 1.0;
    var qcfStyle = baseQcfStyle;
    var fallbackStyle = baseFallbackStyle;
    for (var i = 0; i < 6; i++) {
      final measuredWidth = _measureMushafLineWordsWidth(
        lineWords: lineWords,
        qcfStyle: qcfStyle,
        fallbackStyle: fallbackStyle,
      );
      if (measuredWidth <= maxTextWidth + 0.5) {
        break;
      }
      final nextScale = (scale * (maxTextWidth / measuredWidth))
          .clamp(_mushafWordMinScale, 1.0)
          .toDouble();
      if ((scale - nextScale).abs() < 0.001) {
        scale = nextScale;
        break;
      }
      scale = nextScale;
      qcfStyle = baseQcfStyle.copyWith(
        fontSize: (baseQcfStyle.fontSize ?? 0) * scale,
      );
      fallbackStyle = baseFallbackStyle.copyWith(
        fontSize: (baseFallbackStyle.fontSize ?? 0) * scale,
      );
    }

    return SizedBox(
      key: ValueKey('reader_mushaf_line_interaction_$lineNumber'),
      width: maxTextWidth,
      height: safeLineHeight,
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: shouldCenter
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var index = 0; index < lineWords.length; index++)
            _buildMushafWordWidget(
              lineWord: lineWords[index],
              lineNumber: lineNumber,
              wordIndex: index,
              interactionEnabled: interactionEnabled,
              hoveredVerseKey: hoveredVerseKey,
              selectedVerseKey: selectedVerseKey,
              qcfStyle: qcfStyle,
              fallbackStyle: fallbackStyle,
            ),
        ],
      ),
    );
  }

  double _measureMushafLineWordsWidth({
    required List<_MushafLineWord> lineWords,
    required TextStyle qcfStyle,
    required TextStyle fallbackStyle,
  }) {
    var total = lineWords.length * (_mushafWordHorizontalPadding * 2);
    // Add a small per-word safety budget to avoid pixel-rounding overflows in
    // dense lines with many independent widgets.
    total += lineWords.length * 2.0;
    for (final lineWord in lineWords) {
      final painter = TextPainter(
        text: TextSpan(
          text: lineWord.displayText,
          style: lineWord.useQcf ? qcfStyle : fallbackStyle,
        ),
        textDirection: TextDirection.rtl,
        textScaler: const TextScaler.linear(1.0),
        maxLines: 1,
      )..layout(maxWidth: double.infinity);
      total += painter.width;
    }
    return total;
  }

  Widget _buildMushafWordWidget({
    required _MushafLineWord lineWord,
    required int lineNumber,
    required int wordIndex,
    required bool interactionEnabled,
    required String? hoveredVerseKey,
    required String? selectedVerseKey,
    required TextStyle qcfStyle,
    required TextStyle fallbackStyle,
  }) {
    final verseKey = lineWord.verseKey;
    final colorScheme = Theme.of(context).colorScheme;
    final wordKey =
        '${verseKey ?? "none"}:${lineWord.word.position ?? wordIndex}:$lineNumber';
    final hoveredWord = _hoveredMushafWordKey == wordKey;
    final verseHovered = verseKey != null && verseKey == hoveredVerseKey;
    final verseSelected = verseKey != null && verseKey == selectedVerseKey;
    Color? highlightColor;
    if (verseSelected) {
      highlightColor = colorScheme.primaryContainer.withValues(alpha: 0.42);
    } else if (hoveredWord) {
      highlightColor = colorScheme.primary.withValues(
        alpha: _arabicRenderMode == _ArabicRenderMode.tajweed ? 0.18 : 0.24,
      );
    } else if (verseHovered) {
      highlightColor = colorScheme.primary.withValues(alpha: 0.12);
    }

    final isTajweedV4Qcf =
        _arabicRenderMode == _ArabicRenderMode.tajweed && lineWord.useQcf;
    final baseTextStyle = lineWord.useQcf ? qcfStyle : fallbackStyle;
    final resolvedTextStyle = hoveredWord && !isTajweedV4Qcf
        ? baseTextStyle.copyWith(color: colorScheme.secondary)
        : baseTextStyle;

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(
        horizontal: _mushafWordHorizontalPadding,
        vertical: _mushafWordVerticalPadding,
      ),
      decoration: highlightColor != null
          ? BoxDecoration(
              color: highlightColor,
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Text(
        lineWord.displayText,
        key: ValueKey(
          'reader_mushaf_word_${lineNumber}_${wordIndex}_${verseKey ?? "none"}',
        ),
        textDirection: TextDirection.rtl,
        maxLines: 1,
        softWrap: false,
        textScaler: const TextScaler.linear(1.0),
        style: resolvedTextStyle,
      ),
    );

    if (!interactionEnabled || verseKey == null) {
      return child;
    }

    final wordBody = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (lineWord.isEndMarker) {
          unawaited(_handleMushafVerseTap(verseKey));
          return;
        }
        unawaited(
          _showMushafWordPopover(
            lineWord: lineWord,
            lineNumber: lineNumber,
            wordIndex: wordIndex,
          ),
        );
      },
      child: child,
    );

    Widget interactiveChild = wordBody;
    if (!lineWord.isEndMarker) {
      interactiveChild = Tooltip(
        key: ValueKey('reader_mushaf_word_tooltip_${lineNumber}_$wordIndex'),
        message: _mushafWordTooltipMessage(lineWord.word),
        waitDuration: Duration.zero,
        child: interactiveChild,
      );
    }

    final hoverableWord = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHoveredMushafHoverState(
        verseKey: verseKey,
        wordKey: wordKey,
        previewWord: lineWord.word,
      ),
      onExit: (_) {
        if (_hoveredMushafWordKey == wordKey) {
          _setHoveredMushafHoverState(
            verseKey: null,
            wordKey: null,
            previewWord: null,
          );
        }
      },
      child: interactiveChild,
    );

    if (!lineWord.isEndMarker) {
      return hoverableWord;
    }

    return Container(
      key:
          ValueKey('reader_mushaf_marker_${lineNumber}_${verseKey}_$wordIndex'),
      child: hoverableWord,
    );
  }

  String _mushafWordTooltipMessage(MushafWord word) {
    final translation = (word.translationText ?? '').trim();
    if (translation.isNotEmpty) {
      return translation;
    }
    return _strings.translationUnavailable;
  }

  Future<void> _showMushafWordPopover({
    required _MushafLineWord lineWord,
    required int lineNumber,
    required int wordIndex,
  }) async {
    if (!mounted) {
      return;
    }
    final wordText = lineWord.word.textQpcHafs ?? lineWord.displayText;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: ValueKey('reader_mushaf_word_popover_${lineNumber}_$wordIndex'),
          title: Text(_strings.word),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                wordText,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: 'UthmanicHafs',
                  fontSize: 30,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_strings.verse}: ${lineWord.verseKey ?? _strings.unknown}',
              ),
            ],
          ),
          actions: [
            TextButton(
              key: const ValueKey('reader_mushaf_word_popover_close'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_strings.close),
            ),
          ],
        );
      },
    );
  }

  Future<_MushafRenderData> _getMushafFuture({required int page}) {
    if (_mushafFuture == null ||
        _mushafFuturePage != page ||
        _mushafFutureRenderMode != _arabicRenderMode) {
      _mushafFuturePage = page;
      _mushafFutureRenderMode = _arabicRenderMode;
      _mushafFuture = _loadMushafPage(page: page);
    }
    return _mushafFuture!;
  }

  Future<_MushafRenderData> _loadMushafPage({
    required int page,
  }) async {
    final mushafId = _activeMushafId();
    final variant = _activeQcfVariant();

    final api = ref.read(quranComApiProvider);
    final pageData = await api.getPageWithVerses(
      page: page,
      mushafId: mushafId,
      requireWordTooltipData: true,
    );
    final ayahsOnPage = await ref.read(quranRepoProvider).getAyahsByPage(page);
    final ayahLookupByVerseKey = <String, AyahData>{
      for (final ayah in ayahsOnPage) '${ayah.surah}:${ayah.ayah}': ayah,
    };
    final fontSelection = await ref.read(qcfFontManagerProvider).ensurePageFont(
          page: page,
          variant: variant,
        );

    return _MushafRenderData(
      pageData: pageData,
      fontSelection: fontSelection,
      mushafId: mushafId,
      ayahLookupByVerseKey: ayahLookupByVerseKey,
    );
  }

  void _invalidateMushafFuture() {
    _mushafFuture = null;
    _mushafFuturePage = null;
    _mushafFutureRenderMode = null;
    _mushafAyahLookupByVerseKey = <String, AyahData>{};
    _lastMushafInteractionWarningKey = null;
    if (_viewMode == _ReaderViewMode.mushaf) {
      _pendingMushafScrollReset = true;
    }
  }

  void _resetMushafScrollToTop({int retries = 8}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _viewMode != _ReaderViewMode.mushaf) {
        return;
      }
      if (_mushafScrollController.hasClients) {
        _mushafScrollController.jumpTo(0);
        _pendingMushafScrollReset = false;
        return;
      }
      if (retries > 0) {
        _resetMushafScrollToTop(retries: retries - 1);
      }
    });
  }

  int? _chapterFromVerseKey(String? verseKey) {
    if (verseKey == null) {
      return null;
    }
    final parts = verseKey.split(':');
    if (parts.length != 2) {
      return null;
    }
    return int.tryParse(parts[0]);
  }

  int? _ayahFromVerseKey(String? verseKey) {
    if (verseKey == null) {
      return null;
    }
    final parts = verseKey.split(':');
    if (parts.length != 2) {
      return null;
    }
    return int.tryParse(parts[1]);
  }

  bool _isStaticCenteredMushafLine({
    required int pageNumber,
    required int lineNumber,
  }) {
    if (pageNumber == 1 || pageNumber == 2) {
      return true;
    }
    final centeredLines = _staticCenteredMushafLines[pageNumber];
    if (centeredLines == null) {
      return false;
    }
    return centeredLines.contains(lineNumber);
  }

  String _wordTextForSpan(MushafWord word) {
    final codeV2 = word.codeV2;
    if (codeV2 != null && codeV2.isNotEmpty) {
      return codeV2;
    }
    return word.textQpcHafs ?? '';
  }

  Widget _buildMushafViewToggle() {
    return _buildMushafPillSwitch<_ReaderViewMode>(
      key: const ValueKey('reader_view_toggle'),
      options: [
        _MushafControlOption<_ReaderViewMode>(
          value: _ReaderViewMode.simple,
          label: _strings.verseByVerse,
          optionKey: const ValueKey('reader_mushaf_view_simple'),
        ),
        _MushafControlOption<_ReaderViewMode>(
          value: _ReaderViewMode.mushaf,
          label: _strings.reading,
          optionKey: const ValueKey('reader_mushaf_view_mushaf'),
        ),
      ],
      selectedValue: _viewMode,
      onSelected: _switchViewMode,
    );
  }

  Widget _buildMushafNavTabs() {
    return _buildMushafPillSwitch<_MushafNavTab>(
      key: const ValueKey('reader_mushaf_nav_tabs'),
      options: [
        _MushafControlOption<_MushafNavTab>(
          value: _MushafNavTab.surah,
          label: _strings.surah,
          optionKey: const ValueKey('reader_mushaf_nav_tab_surah'),
        ),
        _MushafControlOption<_MushafNavTab>(
          value: _MushafNavTab.verse,
          label: _strings.verse,
          optionKey: const ValueKey('reader_mushaf_nav_tab_verse'),
        ),
        _MushafControlOption<_MushafNavTab>(
          value: _MushafNavTab.juz,
          label: _strings.juz,
          optionKey: const ValueKey('reader_mushaf_nav_tab_juz'),
        ),
        _MushafControlOption<_MushafNavTab>(
          value: _MushafNavTab.page,
          label: _strings.page,
          optionKey: const ValueKey('reader_mushaf_nav_tab_page'),
        ),
      ],
      selectedValue: _mushafNavTab,
      onSelected: (selected) {
        final switchingToJuz = selected == _MushafNavTab.juz;
        setState(() {
          _mushafNavTab = selected;
          if (switchingToJuz) {
            _ensureMushafJuzIndexFuture();
          }
        });
        if (_viewMode == _ReaderViewMode.simple) {
          _switchMode(
            selected == _MushafNavTab.surah
                ? _ReaderMode.surah
                : _ReaderMode.page,
          );
        }
      },
    );
  }

  Widget _buildMushafSettingsTabs() {
    return _buildMushafUnderlineTabs<_MushafSettingsTab>(
      key: const ValueKey('reader_mushaf_settings_tabs'),
      options: [
        _MushafControlOption<_MushafSettingsTab>(
          value: _MushafSettingsTab.arabic,
          label: _strings.arabic,
          optionKey: const ValueKey('reader_mushaf_settings_tab_arabic'),
        ),
        _MushafControlOption<_MushafSettingsTab>(
          value: _MushafSettingsTab.translation,
          label: _strings.translation,
          optionKey: const ValueKey('reader_mushaf_settings_tab_translation'),
        ),
        _MushafControlOption<_MushafSettingsTab>(
          value: _MushafSettingsTab.wordByWord,
          label: _strings.wordByWord,
          optionKey: const ValueKey('reader_mushaf_settings_tab_word_by_word'),
        ),
      ],
      selectedValue: _mushafSettingsTab,
      onSelected: (selected) {
        setState(() {
          _mushafSettingsTab = selected;
        });
      },
    );
  }

  Widget _buildMushafScriptStyleTabs() {
    final selectedScriptStyle = _arabicRenderMode == _ArabicRenderMode.tajweed
        ? _MushafScriptStyleOption.tajweed
        : _MushafScriptStyleOption.uthmani;
    return _buildMushafPillSwitch<_MushafScriptStyleOption>(
      key: const ValueKey('reader_mushaf_script_tabs'),
      options: [
        _MushafControlOption<_MushafScriptStyleOption>(
          value: _MushafScriptStyleOption.uthmani,
          label: _strings.uthmani,
          optionKey: const ValueKey('reader_mushaf_script_tab_uthmani'),
        ),
        _MushafControlOption<_MushafScriptStyleOption>(
          value: _MushafScriptStyleOption.tajweed,
          label: _strings.tajweed,
          optionKey: const ValueKey('reader_mushaf_script_tab_tajweed'),
        ),
        _MushafControlOption<_MushafScriptStyleOption>(
          value: _MushafScriptStyleOption.indopak,
          label: _strings.indoPakSoon,
          optionKey: const ValueKey('reader_mushaf_script_tab_indopak'),
          enabled: false,
        ),
      ],
      selectedValue: selectedScriptStyle,
      onSelected: (selected) {
        switch (selected) {
          case _MushafScriptStyleOption.uthmani:
            _switchArabicRenderMode(_ArabicRenderMode.plain);
            return;
          case _MushafScriptStyleOption.tajweed:
            _switchArabicRenderMode(_ArabicRenderMode.tajweed);
            return;
          case _MushafScriptStyleOption.indopak:
            return;
        }
      },
    );
  }

  Widget _buildMushafControlLabel(
    String label, {
    required TextStyle style,
  }) {
    return Text(
      label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: style,
    );
  }

  Widget _buildMushafPillSwitch<T>({
    required Key key,
    required List<_MushafControlOption<T>> options,
    required T selectedValue,
    required ValueChanged<T> onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.9);
    return DecoratedBox(
      key: key,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            for (var index = 0; index < options.length; index++) ...[
              Expanded(
                child: _buildMushafPillSwitchItem<T>(
                  option: options[index],
                  selectedValue: selectedValue,
                  onSelected: onSelected,
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                ),
              ),
              if (index < options.length - 1)
                _buildMushafPillSwitchSeparator<T>(
                  left: options[index].value,
                  right: options[index + 1].value,
                  selected: selectedValue,
                  color: borderColor,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMushafPillSwitchItem<T>({
    required _MushafControlOption<T> option,
    required T selectedValue,
    required ValueChanged<T> onSelected,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    final isSelected = option.value == selectedValue;
    final enabled = option.enabled;
    final labelColor = !enabled
        ? colorScheme.onSurface.withValues(alpha: 0.4)
        : isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant;
    final labelStyle = textTheme.labelLarge?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: labelColor,
        ) ??
        TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: labelColor,
        );
    final selectedColor = colorScheme.primaryContainer.withValues(alpha: 0.78);
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: enabled,
      child: Material(
        color: isSelected ? selectedColor : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          key: option.optionKey,
          borderRadius: BorderRadius.circular(24),
          onTap: enabled ? () => onSelected(option.value) : null,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(minHeight: _mushafControlMinHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _mushafControlHorizontalPadding,
                  vertical: _mushafControlVerticalPadding,
                ),
                child: _buildMushafControlLabel(
                  option.label,
                  style: labelStyle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMushafPillSwitchSeparator<T>({
    required T left,
    required T right,
    required T selected,
    required Color color,
  }) {
    final shouldHide = left == selected || right == selected;
    return SizedBox(
      width: 1,
      height: _mushafControlSeparatorHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: shouldHide ? Colors.transparent : color,
        ),
      ),
    );
  }

  Widget _buildMushafUnderlineTabs<T>({
    required Key key,
    required List<_MushafControlOption<T>> options,
    required T selectedValue,
    required ValueChanged<T> onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      key: key,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _buildMushafUnderlineTabItem<T>(
                option: option,
                selectedValue: selectedValue,
                onSelected: onSelected,
                textTheme: textTheme,
                colorScheme: colorScheme,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMushafUnderlineTabItem<T>({
    required _MushafControlOption<T> option,
    required T selectedValue,
    required ValueChanged<T> onSelected,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    final isSelected = option.value == selectedValue;
    final enabled = option.enabled;
    final labelColor = !enabled
        ? colorScheme.onSurface.withValues(alpha: 0.4)
        : isSelected
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant;
    final labelStyle = textTheme.labelLarge?.copyWith(
          color: labelColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ) ??
        TextStyle(
          color: labelColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        );
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: option.optionKey,
          onTap: enabled ? () => onSelected(option.value) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  width: _mushafUnderlineTabIndicator,
                ),
              ),
            ),
            child: _buildMushafControlLabel(option.label, style: labelStyle),
          ),
        ),
      ),
    );
  }

  List<int> _filteredMushafSurahNumbers() {
    final query = _mushafSurahSearchQuery.trim().toLowerCase();
    final all = List<int>.generate(114, (index) => index + 1);
    if (query.isEmpty) {
      return all;
    }
    return all.where((surah) {
      final numberMatch = surah.toString().contains(query);
      final enName = (_surahNamesEn[surah] ?? '').toLowerCase();
      final arName = (_surahNamesAr[surah] ?? '').toLowerCase();
      return numberMatch || enName.contains(query) || arName.contains(query);
    }).toList(growable: false);
  }

  List<int> _filteredVerseNumbers(int maxAyah) {
    final query = _mushafVerseSearchQuery.trim();
    final all = List<int>.generate(maxAyah, (index) => index + 1);
    if (query.isEmpty) {
      return all;
    }
    return all
        .where((ayahNumber) => ayahNumber.toString().contains(query))
        .toList(growable: false);
  }

  List<MushafJuzNavEntry> _filteredJuzEntries(List<MushafJuzNavEntry> entries) {
    final query = _mushafJuzSearchQuery.trim();
    if (query.isEmpty) {
      return entries;
    }
    return entries
        .where((entry) => entry.juzNumber.toString().contains(query))
        .toList(growable: false);
  }

  List<int> _filteredPageNumbers(List<int> pages) {
    final query = _mushafPageSearchQuery.trim();
    if (query.isEmpty) {
      return pages;
    }
    return pages
        .where((page) => page.toString().contains(query))
        .toList(growable: false);
  }

  Widget _buildMushafLeftPane(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withValues(alpha: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: _buildMushafViewToggle(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: _buildMushafNavTabs(),
          ),
          const Divider(height: 1),
          Expanded(
            child: switch (_mushafNavTab) {
              _MushafNavTab.surah => _buildMushafSurahNavTab(context),
              _MushafNavTab.verse => _buildMushafVerseNavTab(context),
              _MushafNavTab.juz => _buildMushafJuzNavTab(context),
              _MushafNavTab.page => _buildMushafPageNavTab(context),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMushafSurahNavTab(BuildContext context) {
    final filteredSurahs = _filteredMushafSurahNumbers();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            key: const ValueKey('reader_mushaf_nav_surah_search'),
            decoration: InputDecoration(
              hintText: _strings.searchSurah,
              isDense: true,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _mushafSurahSearchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: KeyedSubtree(
            key: const ValueKey('reader_surah_list'),
            child: ListView.builder(
              key: const ValueKey('reader_mushaf_nav_surah_list'),
              itemCount: filteredSurahs.length,
              itemBuilder: (context, index) {
                final surah = filteredSurahs[index];
                final selected = surah == _selectedSurah;
                return KeyedSubtree(
                  key: ValueKey('surah_tile_$surah'),
                  child: ListTile(
                    key: ValueKey('reader_mushaf_nav_surah_$surah'),
                    selected: selected,
                    title: Text(_surahLabelFor(surah)),
                    onTap: () {
                      if (_viewMode == _ReaderViewMode.simple) {
                        _selectSurah(surah);
                        return;
                      }
                      unawaited(_jumpToSurahStartInMushaf(surah));
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMushafVerseNavTab(BuildContext context) {
    final countFuture = _verseTabAyahCountFuture ??
        _loadVerseTabAyahCount(_verseTabSelectedSurah);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: DropdownButtonFormField<int>(
            key: const ValueKey('reader_mushaf_nav_verse_surah'),
            value: _verseTabSelectedSurah,
            decoration: InputDecoration(
              labelText: _strings.surah,
              isDense: true,
            ),
            items: [
              for (var surah = 1; surah <= 114; surah++)
                DropdownMenuItem<int>(
                  value: surah,
                  child: Text(_surahLabelFor(surah)),
                ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              _selectVerseTabSurah(value);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: TextField(
            key: const ValueKey('reader_mushaf_nav_verse_search'),
            decoration: InputDecoration(
              hintText: _strings.verseNumberHint,
              isDense: true,
              prefixIcon: const Icon(Icons.search),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _mushafVerseSearchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<int>(
            future: countFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(_strings.failedToLoadVerses),
                );
              }
              final maxAyah = snapshot.data ?? 0;
              if (maxAyah <= 0) {
                return Center(
                  child: Text(_strings.noVersesAvailableForSelectedSurah),
                );
              }
              final filteredAyahs = _filteredVerseNumbers(maxAyah);
              return ListView.builder(
                key: const ValueKey('reader_mushaf_nav_verse_list'),
                itemCount: filteredAyahs.length,
                itemBuilder: (context, index) {
                  final ayah = filteredAyahs[index];
                  return ListTile(
                    key: ValueKey(
                      'reader_mushaf_nav_verse_${_verseTabSelectedSurah}_$ayah',
                    ),
                    title: Text(_strings.ayahLabel(ayah)),
                    onTap: () {
                      unawaited(
                        _jumpToVerseInMushaf(
                          surah: _verseTabSelectedSurah,
                          ayah: ayah,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMushafJuzNavTab(BuildContext context) {
    _ensureMushafJuzIndexFuture();
    final juzFuture = _juzIndexFuture;
    if (juzFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            key: const ValueKey('reader_mushaf_nav_juz_search'),
            decoration: InputDecoration(
              hintText: _strings.searchJuz,
              isDense: true,
              prefixIcon: const Icon(Icons.search),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _mushafJuzSearchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<MushafJuzNavEntry>>(
            future: juzFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_strings.failedToLoadJuzIndex),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        key: const ValueKey('reader_mushaf_nav_juz_retry'),
                        onPressed: () {
                          setState(() {
                            _juzIndexFuture = _loadMushafJuzIndex();
                          });
                        },
                        child: Text(_strings.retry),
                      ),
                    ],
                  ),
                );
              }
              final entries = _filteredJuzEntries(
                snapshot.data ?? const <MushafJuzNavEntry>[],
              );
              if (entries.isEmpty) {
                return Center(
                  child: Text(_strings.noJuzEntriesFound),
                );
              }
              return ListView.builder(
                key: const ValueKey('reader_mushaf_nav_juz_list'),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return ListTile(
                    key: ValueKey('reader_mushaf_nav_juz_${entry.juzNumber}'),
                    title: Text(_strings.juzLabel(entry.juzNumber)),
                    subtitle: Text(_strings.pageLabel(entry.page)),
                    onTap: () => _jumpToJuzInMushaf(entry),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMushafPageNavTab(BuildContext context) {
    final pagesFuture = _availablePagesFuture;
    if (pagesFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            key: const ValueKey('reader_mushaf_nav_page_search'),
            decoration: InputDecoration(
              hintText: _strings.searchPage,
              isDense: true,
              prefixIcon: const Icon(Icons.search),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _mushafPageSearchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<int>>(
            future: pagesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_strings.failedToLoadPages),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        key: const ValueKey('reader_page_retry_button'),
                        onPressed: _refreshCurrentView,
                        child: Text(_strings.retry),
                      ),
                    ],
                  ),
                );
              }
              final pages = _filteredPageNumbers(
                snapshot.data ?? const <int>[],
              );
              if (pages.isEmpty) {
                return Center(
                  child: Text(_strings.noPagesAvailable),
                );
              }
              return ListView.builder(
                key: const ValueKey('reader_page_list'),
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return ListTile(
                    key: ValueKey('reader_page_$page'),
                    selected: page == _selectedPage,
                    title: Text(_strings.pageLabel(page)),
                    onTap: () => _selectPage(page),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMushafSettingsPane(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildMushafSettingsTabs(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: switch (_mushafSettingsTab) {
                _MushafSettingsTab.arabic => _buildMushafArabicSettingsBody(),
                _MushafSettingsTab.translation =>
                  _buildMushafScaffoldSettingsBody(
                    _strings.translationSettingsComingSoon,
                  ),
                _MushafSettingsTab.wordByWord =>
                  _buildMushafScaffoldSettingsBody(
                    _strings.wordByWordSettingsComingSoon,
                  ),
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                TextButton(
                  key: const ValueKey('reader_mushaf_settings_reset'),
                  onPressed: _resetMushafSettings,
                  child: Text(_strings.reset),
                ),
                const Spacer(),
                FilledButton(
                  key: const ValueKey('reader_mushaf_settings_done'),
                  onPressed: () {
                    setState(() {
                      _setMushafSettingsOpen(false);
                    });
                  },
                  child: Text(_strings.done),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMushafArabicSettingsBody() {
    final colorScheme = Theme.of(context).colorScheme;
    final previewWord = _hoveredMushafPreviewWord;
    final previewArabic =
        previewWord?.textQpcHafs ?? previewWord?.codeV2 ?? _strings.preview;
    final previewTranslation = previewWord == null
        ? _strings.translationUnavailable
        : _mushafWordTooltipMessage(previewWord);

    return SingleChildScrollView(
      key: const ValueKey('reader_mushaf_settings_scroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_strings.preview}:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Container(
            key: const ValueKey('reader_mushaf_settings_preview'),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  previewArabic,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: 34,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(previewTranslation),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _strings.scriptStyle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _buildMushafScriptStyleTabs(),
          const SizedBox(height: 12),
          CheckboxListTile(
            key: const ValueKey('reader_mushaf_tajweed_toggle'),
            value: _arabicRenderMode == _ArabicRenderMode.tajweed,
            contentPadding: EdgeInsets.zero,
            title: Text(_strings.showTajweedRulesWhileReading),
            onChanged: (value) {
              _switchArabicRenderMode(
                value == true
                    ? _ArabicRenderMode.tajweed
                    : _ArabicRenderMode.plain,
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _strings.fontSize,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              IconButton(
                key: const ValueKey('reader_mushaf_font_minus'),
                onPressed: () => _setMushafFontStep(_mushafFontStep - 1),
                icon: const Icon(Icons.remove),
              ),
              Text(
                '$_mushafFontStep',
                key: const ValueKey('reader_mushaf_font_step'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                key: const ValueKey('reader_mushaf_font_plus'),
                onPressed: () => _setMushafFontStep(_mushafFontStep + 1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            key: const ValueKey('reader_mushaf_reciter_card'),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_strings.selectedReciter),
                const SizedBox(height: 6),
                Text(
                  'Mishari Rashid al-`Afasy',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMushafScaffoldSettingsBody(String message) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMushafLayout(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: _mushafLeftPaneWidth,
          child: _buildMushafLeftPane(context),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _buildAyahPanel()),
        if (_mushafSettingsOpen)
          SizedBox(
            width: _mushafSettingsPaneWidth,
            child: _buildMushafSettingsPane(context),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _buildMushafLayout(context),
    );
  }
}

enum _ReaderMode {
  surah,
  page,
}

enum _ReaderViewMode {
  simple,
  mushaf,
}

enum _ArabicRenderMode {
  plain,
  tajweed,
}

enum _MushafNavTab {
  surah,
  verse,
  juz,
  page,
}

enum _MushafSettingsTab {
  arabic,
  translation,
  wordByWord,
}

enum _MushafScriptStyleOption {
  uthmani,
  tajweed,
  indopak,
}

class _MushafControlOption<T> {
  const _MushafControlOption({
    required this.value,
    required this.label,
    required this.optionKey,
    this.enabled = true,
  });

  final T value;
  final String label;
  final Key optionKey;
  final bool enabled;
}

class _VerseByVerseRowRenderData {
  const _VerseByVerseRowRenderData({
    required this.qcfFamilyName,
    required this.words,
    required this.translationText,
  });

  final String qcfFamilyName;
  final List<MushafWord> words;
  final String translationText;
}

class _MushafRenderData {
  const _MushafRenderData({
    required this.pageData,
    required this.fontSelection,
    required this.mushafId,
    required this.ayahLookupByVerseKey,
  });

  final MushafPageData pageData;
  final QcfFontSelection fontSelection;
  final int mushafId;
  final Map<String, AyahData> ayahLookupByVerseKey;
}

class _MushafLineWord {
  const _MushafLineWord({
    required this.word,
    required this.verseKey,
    required this.lineNumber,
    required this.isEndMarker,
    required this.displayText,
    required this.useQcf,
  });

  final MushafWord word;
  final String? verseKey;
  final int lineNumber;
  final bool isEndMarker;
  final String displayText;
  final bool useQcf;
}

class _MushafDisplayLine {
  const _MushafDisplayLine({
    required this.lineNumber,
    required this.words,
  });

  final int lineNumber;
  final List<_MushafLineWord> words;
}

enum _AyahAction {
  bookmark,
  note,
  copy,
}

class _NoteDraft {
  const _NoteDraft({
    required this.title,
    required this.body,
  });

  final String? title;
  final String body;
}

class _ReaderNoteEditorDialog extends StatefulWidget {
  const _ReaderNoteEditorDialog({
    required this.existing,
    required this.strings,
  });

  final NoteData? existing;
  final AppStrings strings;

  @override
  State<_ReaderNoteEditorDialog> createState() =>
      _ReaderNoteEditorDialogState();
}

class _ReaderNoteEditorDialogState extends State<_ReaderNoteEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _bodyFocusNode = FocusNode();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existing?.title ?? '');
    _bodyController = TextEditingController(text: widget.existing?.body ?? '');
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();
    _bodyFocusNode.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _close([_NoteDraft? result]) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(result);
  }

  void _save() {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      setState(() {
        _errorMessage = widget.strings.bodyRequired;
      });
      return;
    }

    final title = _titleController.text.trim();
    _close(
      _NoteDraft(
        title: title.isEmpty ? null : title,
        body: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? widget.strings.addNote
            : widget.strings.editNote,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('note_title_field'),
                controller: _titleController,
                focusNode: _titleFocusNode,
                decoration: InputDecoration(
                  labelText: widget.strings.noteTitleOptional,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('note_body_field'),
                controller: _bodyController,
                focusNode: _bodyFocusNode,
                maxLines: 6,
                minLines: 4,
                decoration: InputDecoration(
                  labelText: widget.strings.noteBody,
                  alignLabelWithHint: true,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _close,
          child: Text(widget.strings.cancel),
        ),
        FilledButton(
          key: const ValueKey('note_save_button'),
          onPressed: _save,
          child: Text(widget.strings.save),
        ),
      ],
    );
  }
}

class _VerseJumpTarget {
  const _VerseJumpTarget({
    required this.surah,
    required this.ayah,
  });

  final int surah;
  final int ayah;
}

class _VerseRange {
  const _VerseRange({
    required this.start,
    required this.end,
  });

  final _VersePosition start;
  final _VersePosition end;
}

class _VersePosition implements Comparable<_VersePosition> {
  const _VersePosition({
    required this.surah,
    required this.ayah,
  });

  final int surah;
  final int ayah;

  @override
  int compareTo(_VersePosition other) {
    if (surah != other.surah) {
      return surah.compareTo(other.surah);
    }
    return ayah.compareTo(other.ayah);
  }
}
