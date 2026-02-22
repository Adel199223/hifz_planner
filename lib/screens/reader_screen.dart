import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/database/app_database.dart';
import '../data/providers/database_providers.dart';
import '../data/services/qurancom_api.dart';
import '../ui/qcf/qcf_font_manager.dart';
import '../ui/quran/basmala_header.dart';
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
const String _mushafBasmalaTranslation =
    'In the Name of Allah - the Most Compassionate, Most Merciful';

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
  _SimpleTextSource _simpleTextSource = _SimpleTextSource.local;
  _MushafNavTab _mushafNavTab = _MushafNavTab.page;
  _MushafSettingsTab _mushafSettingsTab = _MushafSettingsTab.arabic;
  bool _mushafSettingsOpen = false;
  int _mushafFontStep = 5;
  int _selectedSurah = 1;
  int _verseTabSelectedSurah = 1;
  String _surahSearchQuery = '';
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
  final Map<String, Future<_SimpleQuranComVerseRenderData>>
      _simpleQuranComRowFutureCache =
      <String, Future<_SimpleQuranComVerseRenderData>>{};
  final Set<String> _simpleQuranComPrefetchKeys = <String>{};
  Map<String, AyahData> _mushafAyahLookupByVerseKey = <String, AyahData>{};
  String? _lastMushafInteractionWarningKey;
  bool _pendingMushafScrollReset = false;
  Timer? _jumpHighlightTimer;

  @override
  void initState() {
    super.initState();
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
          _showSnackBar('Target ayah has no page metadata yet.');
        }
        targetForJump = null;
      } else if (!pages.contains(targetPage)) {
        if (showMissingTargetMessage) {
          _showSnackBar(
              'Target ayah page is not available in imported metadata.');
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
        _viewMode == _ReaderViewMode.simple &&
        _simpleTextSource == _SimpleTextSource.local) {
      unawaited(_prepareTajweedTags());
    }
    if (_viewMode == _ReaderViewMode.mushaf) {
      _resetMushafScrollToTop();
    }

    _maybePrefetchSimpleQuranComCurrentContext();
  }

  void _switchSimpleTextSource(_SimpleTextSource source) {
    if (source == _simpleTextSource) {
      return;
    }

    setState(() {
      _simpleTextSource = source;
      _clearSimpleQuranComRowCache();
    });

    if (source == _SimpleTextSource.local &&
        _arabicRenderMode == _ArabicRenderMode.tajweed) {
      unawaited(_prepareTajweedTags());
      return;
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
        _mushafSettingsOpen = false;
        _selectedPage = null;
        _pendingJumpTarget = null;
        _clearInteractiveHighlights();
        _jumpScheduled = false;
        _ayahsFuture = Future.value(const <AyahData>[]);
        _availablePagesFuture = _loadAvailablePages();
        _juzIndexFuture = null;
      } else {
        _mushafSettingsOpen = false;
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
      _showSnackBar('Tajweed tags unavailable. Showing plain text.');
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
      _showSnackBar('No page metadata found for Surah $surah.');
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
      _showSnackBar('No page metadata found for $surah:$ayah.');
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
      return '$surahNumber. Surah $surahNumber';
    }
    return '$surahNumber. $enName';
  }

  List<int> _filteredSurahNumbers() {
    final query = _surahSearchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return List<int>.generate(114, (index) => index + 1);
    }

    final result = <int>[];
    for (var surah = 1; surah <= 114; surah++) {
      final numberMatch = surah.toString().contains(query);
      final nameMatch =
          (_surahNamesEn[surah] ?? '').toLowerCase().contains(query);
      if (numberMatch || nameMatch) {
        result.add(surah);
      }
    }
    return result;
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
        _showSnackBar('Target ayah is not visible on the selected page.');
      } else {
        _showSnackBar(
          'Ayah ${pendingTarget.ayah} was not found in Surah ${pendingTarget.surah}.',
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
                title: const Text('Bookmark verse'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_AyahAction.bookmark),
              ),
              ListTile(
                key: const ValueKey('action_note'),
                leading: const Icon(Icons.note_alt_outlined),
                title: const Text('Add/Edit note'),
                onTap: () => Navigator.of(sheetContext).pop(_AyahAction.note),
              ),
              ListTile(
                key: const ValueKey('action_copy'),
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Copy text (Uthmani)'),
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
        _showSnackBar('Verse already bookmarked.');
        return;
      }

      await repo.addBookmark(
        surah: ayah.surah,
        ayah: ayah.ayah,
      );
      _showSnackBar('Bookmark saved.');
    } catch (_) {
      _showSnackBar('Failed to save bookmark.');
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
        _showSnackBar('Note added.');
      } else {
        final updated = await noteRepo.updateNote(
          id: existing.id,
          title: draft.title,
          body: draft.body,
        );
        _showSnackBar(updated ? 'Note updated.' : 'Note update failed.');
      }
    } catch (_) {
      _showSnackBar('Failed to save note.');
    }
  }

  Future<void> _copyText(AyahData ayah) async {
    _showSnackBar('Copied verse text.');
    unawaited(
      Clipboard.setData(
        ClipboardData(text: ayah.textUthmani),
      ).catchError((Object _, StackTrace __) {
        // Surface consistent UI feedback even if clipboard channel is unavailable.
      }),
    );
  }

  Future<_NoteDraft?> _showNoteDialog(NoteData? existing) async {
    return showDialog<_NoteDraft>(
      context: context,
      builder: (dialogContext) {
        return _ReaderNoteEditorDialog(existing: existing);
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
      _showSnackBar('Verse actions unavailable for this page data.');
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
    if (_viewMode != _ReaderViewMode.simple ||
        _simpleTextSource != _SimpleTextSource.quranCom) {
      return;
    }
    unawaited(_prefetchSimpleQuranComCurrentContext());
  }

  Future<void> _prefetchSimpleQuranComCurrentContext() async {
    if (_viewMode != _ReaderViewMode.simple ||
        _simpleTextSource != _SimpleTextSource.quranCom) {
      return;
    }

    final mushafId = _activeMushafId();
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

    _prefetchSimpleQuranComPage(page: page, mushafId: mushafId);
    if (page < 604) {
      _prefetchSimpleQuranComPage(page: page + 1, mushafId: mushafId);
    }
  }

  void _prefetchSimpleQuranComForAyahs(List<AyahData> ayahs) {
    if (_viewMode != _ReaderViewMode.simple ||
        _simpleTextSource != _SimpleTextSource.quranCom) {
      return;
    }

    final mushafId = _activeMushafId();
    var page = _mode == _ReaderMode.page ? _selectedPage : null;
    page ??= _firstMadinaPage(ayahs);
    if (page == null) {
      return;
    }

    _prefetchSimpleQuranComPage(page: page, mushafId: mushafId);
    if (page < 604) {
      _prefetchSimpleQuranComPage(page: page + 1, mushafId: mushafId);
    }
  }

  void _prefetchSimpleQuranComPage({
    required int page,
    required int mushafId,
  }) {
    if (page < 1 || page > 604) {
      return;
    }
    final prefetchKey = '$page|$mushafId';
    if (!_simpleQuranComPrefetchKeys.add(prefetchKey)) {
      return;
    }

    final api = ref.read(quranComApiProvider);
    unawaited(
      () async {
        try {
          await api.getPage(page: page, mushafId: mushafId);
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

  Future<_SimpleQuranComVerseRenderData>? _getSimpleQuranComVerseFuture(
    AyahData ayah,
  ) {
    final page = ayah.pageMadina;
    if (page == null) {
      return null;
    }

    final ayahKey = _ayahKey(ayah);
    final mushafId = _activeMushafId();
    final variant = _activeQcfVariant();
    final cacheKey = '$ayahKey|m$mushafId';
    return _simpleQuranComRowFutureCache.putIfAbsent(
      cacheKey,
      () => _loadSimpleQuranComVerseRenderData(
        page: page,
        mushafId: mushafId,
        variant: variant,
        verseKey: ayahKey,
      ),
    );
  }

  Future<_SimpleQuranComVerseRenderData> _loadSimpleQuranComVerseRenderData({
    required int page,
    required int mushafId,
    required QcfFontVariant variant,
    required String verseKey,
  }) async {
    final fontSelection = await ref.read(qcfFontManagerProvider).ensurePageFont(
          page: page,
          variant: variant,
        );
    final words = await ref.read(quranComApiProvider).getVerseWordsByPage(
          page: page,
          mushafId: mushafId,
          verseKey: verseKey,
        );
    if (words.isEmpty) {
      throw QuranComApiException('No words found for verse $verseKey.');
    }

    return _SimpleQuranComVerseRenderData(
      qcfFamilyName: fontSelection.familyName,
      words: words,
    );
  }

  Widget _buildSimpleQuranComArabicContent({
    required BuildContext context,
    required String ayahKey,
    required _SimpleQuranComVerseRenderData data,
  }) {
    final baseArabicStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
              fontFamily: 'UthmanicHafs',
              fontSize: 34,
              height: 1.9,
            ) ??
        const TextStyle(
          fontFamily: 'UthmanicHafs',
          fontSize: 34,
          height: 1.9,
        );
    final qcfStyle = baseArabicStyle.copyWith(fontFamily: data.qcfFamilyName);
    final fallbackStyle = baseArabicStyle.copyWith(fontFamily: 'UthmanicHafs');

    return RichText(
      key: ValueKey('ayah_qurancom_text_$ayahKey'),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      softWrap: true,
      text: TextSpan(
        children: [
          for (final word in data.words)
            _buildMushafWordSpan(
              word: word,
              qcfStyle: qcfStyle,
              fallbackStyle: fallbackStyle,
            ),
        ],
      ),
    );
  }

  Widget _buildAyahPanel() {
    if (_viewMode == _ReaderViewMode.mushaf) {
      return _buildMushafPanel();
    }
    return _buildSimpleAyahPanel();
  }

  Widget _buildSimpleAyahPanel() {
    final ayahsFuture = _ayahsFuture;
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
                const Text('Failed to load ayahs.'),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const ValueKey('reader_retry_button'),
                  onPressed: _refreshCurrentView,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final ayahs = snapshot.data ?? const <AyahData>[];
        if (ayahs.isEmpty) {
          if (_mode == _ReaderMode.page && _selectedPage == null) {
            return const Center(
              child: Text(
                'No page metadata found. Import Page Metadata in Settings.',
              ),
            );
          }
          return Center(
            child: Text(
              _mode == _ReaderMode.surah
                  ? 'No ayahs found for Surah $_selectedSurah.'
                  : 'No ayahs found for Page $_selectedPage.',
            ),
          );
        }
        _queuePendingJump(ayahs);
        final usingQuranComSource =
            _simpleTextSource == _SimpleTextSource.quranCom;
        final tajweedTagsService = ref.read(tajweedTagsServiceProvider);
        final tajweedEnabled = !usingQuranComSource &&
            _arabicRenderMode == _ArabicRenderMode.tajweed &&
            tajweedTagsService.hasAnyTags;
        final entries = _buildSimplePanelEntries(ayahs);
        if (usingQuranComSource) {
          _prefetchSimpleQuranComForAyahs(ayahs);
        }

        return ListView.builder(
          key: const ValueKey('reader_ayah_list'),
          controller: _ayahScrollController,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final entry = entries[index];
            if (entry.kind == _SimplePanelEntryKind.basmalaHeader) {
              final header = _mode == _ReaderMode.surah
                  ? const BasmalaHeader()
                  : BasmalaHeader(
                      key: ValueKey(
                        'basmala_header_${entry.ayah!.surah}:${entry.ayah!.ayah}',
                      ),
                    );
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: header,
              );
            }

            final ayah = entry.ayah!;
            final key = _ayahKey(ayah);
            final localTajweedHtml = tajweedEnabled
                ? tajweedTagsService.getTajweedHtmlFor(
                    ayah.surah,
                    ayah.ayah,
                  )
                : null;
            Widget buildLocalRow({Widget? arabicContent}) {
              return _buildSimpleAyahRow(
                ayah: ayah,
                ayahKey: key,
                tajweedHtml: localTajweedHtml,
                arabicContent: arabicContent,
              );
            }

            if (!usingQuranComSource) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: buildLocalRow(),
              );
            }

            final quranComFuture = _getSimpleQuranComVerseFuture(ayah);
            if (quranComFuture == null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: buildLocalRow(),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FutureBuilder<_SimpleQuranComVerseRenderData>(
                future: quranComFuture,
                builder: (context, rowSnapshot) {
                  final renderData = rowSnapshot.data;
                  if (rowSnapshot.hasError || renderData == null) {
                    return buildLocalRow();
                  }

                  return buildLocalRow(
                    arabicContent: _buildSimpleQuranComArabicContent(
                      context: context,
                      ayahKey: key,
                      data: renderData,
                    ),
                  );
                },
              ),
            );
          },
          itemCount: entries.length,
        );
      },
    );
  }

  Widget _buildSimpleAyahRow({
    required AyahData ayah,
    required String ayahKey,
    required String? tajweedHtml,
    Widget? arabicContent,
  }) {
    return _AyahRow(
      rowKey: _ayahRowKey(ayahKey),
      ayah: ayah,
      tajweedHtml: tajweedHtml,
      arabicContent: arabicContent,
      hovered: _hoveredAyahKey == ayahKey,
      tappedHighlighted: _tappedAyahKey == ayahKey,
      jumpHighlighted: _jumpHighlightedAyahKey == ayahKey,
      rangeHighlighted: _isRangeHighlighted(ayah),
      onHoverChanged: (isHovered) {
        setState(() {
          if (isHovered) {
            _hoveredAyahKey = ayahKey;
          } else if (_hoveredAyahKey == ayahKey) {
            _hoveredAyahKey = null;
          }
        });
      },
      onTap: () async {
        setState(() {
          _tappedAyahKey = ayahKey;
        });
        await _showAyahActions(ayah);
      },
    );
  }

  List<_SimplePanelEntry> _buildSimplePanelEntries(List<AyahData> ayahs) {
    final entries = <_SimplePanelEntry>[];
    for (final ayah in ayahs) {
      if (_shouldShowSimpleBasmalaHeaderBefore(ayah)) {
        entries.add(_SimplePanelEntry.basmalaHeader(ayah: ayah));
      }
      entries.add(_SimplePanelEntry.ayah(ayah: ayah));
    }
    return entries;
  }

  bool _shouldShowSimpleBasmalaHeaderBefore(AyahData ayah) {
    if (ayah.ayah != 1 || ayah.surah == 1 || ayah.surah == 9) {
      return false;
    }
    if (_mode == _ReaderMode.surah) {
      return ayah.surah == _selectedSurah;
    }
    return true;
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
                const Text('Failed to load Mushaf page.'),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const ValueKey('reader_mushaf_retry_button'),
                  onPressed: () {
                    setState(() {
                      _invalidateMushafFuture();
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('No Mushaf data available.'));
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
          return const Center(child: Text('No Mushaf text available.'));
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
          Text('Page $pageNumber', key: const ValueKey('reader_page_label')),
          if (meta.juzNumber != null) ...[
            const SizedBox(width: 12),
            Text('Juz ${meta.juzNumber}', style: subduedStyle),
          ],
          if (meta.hizbNumber != null) ...[
            const SizedBox(width: 12),
            Text('Hizb ${meta.hizbNumber}', style: subduedStyle),
          ],
        ],
      ),
    );
  }

  Widget _buildMushafTopActionsRow() {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
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
                  label: const Text('Listen'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const ValueKey('reader_mushaf_language_arabic'),
                  onPressed: () {},
                  child: const Text('Arabic'),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  key: const ValueKey('reader_mushaf_language_translation'),
                  onPressed: () {
                    setState(() {
                      _mushafSettingsOpen = true;
                      _mushafSettingsTab = _MushafSettingsTab.translation;
                    });
                  },
                  child: const Text('Translation'),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Tajweed colors',
                    key: ValueKey('reader_mushaf_tajweed_colors'),
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
          tooltip: _mushafSettingsOpen ? 'Close settings' : 'Open settings',
          onPressed: () {
            setState(() {
              _mushafSettingsOpen = !_mushafSettingsOpen;
            });
          },
        ),
      ],
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

    final transliterated = _surahNamesEn[chapter] ?? 'Surah $chapter';
    final translated = 'Surah $chapter';
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
                _mushafBasmalaTranslation,
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
    return 'Translation unavailable';
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
          title: const Text('Word'),
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
              Text('Verse: ${lineWord.verseKey ?? 'Unknown'}'),
            ],
          ),
          actions: [
            TextButton(
              key: const ValueKey('reader_mushaf_word_popover_close'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
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

  TextSpan _buildMushafWordSpan({
    required MushafWord word,
    required TextStyle qcfStyle,
    required TextStyle fallbackStyle,
  }) {
    final codeV2 = word.codeV2;
    final text = _wordTextForSpan(word);
    if (codeV2 != null && codeV2.isNotEmpty) {
      return TextSpan(text: text, style: qcfStyle);
    }
    return TextSpan(text: text, style: fallbackStyle);
  }

  String _wordTextForSpan(MushafWord word) {
    final codeV2 = word.codeV2;
    if (codeV2 != null && codeV2.isNotEmpty) {
      return codeV2;
    }
    return word.textQpcHafs ?? '';
  }

  Widget _buildViewToggle() {
    return SegmentedButton<_ReaderViewMode>(
      key: const ValueKey('reader_view_toggle'),
      segments: const [
        ButtonSegment<_ReaderViewMode>(
          value: _ReaderViewMode.simple,
          label: Text('Simple'),
        ),
        ButtonSegment<_ReaderViewMode>(
          value: _ReaderViewMode.mushaf,
          label: Text('Mushaf (Quran.com)'),
        ),
      ],
      selected: <_ReaderViewMode>{_viewMode},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) {
          return;
        }
        _switchViewMode(selection.first);
      },
    );
  }

  Widget _buildMushafViewToggle() {
    return _buildMushafPillSwitch<_ReaderViewMode>(
      key: const ValueKey('reader_view_toggle'),
      options: const [
        _MushafControlOption<_ReaderViewMode>(
          value: _ReaderViewMode.simple,
          label: 'Simple',
          optionKey: ValueKey('reader_mushaf_view_simple'),
        ),
        _MushafControlOption<_ReaderViewMode>(
          value: _ReaderViewMode.mushaf,
          label: 'Mushaf (Quran.com)',
          optionKey: ValueKey('reader_mushaf_view_mushaf'),
        ),
      ],
      selectedValue: _viewMode,
      onSelected: _switchViewMode,
    );
  }

  Widget _buildMushafNavTabs() {
    return _buildMushafPillSwitch<_MushafNavTab>(
      key: const ValueKey('reader_mushaf_nav_tabs'),
      options: const [
        _MushafControlOption<_MushafNavTab>(
          value: _MushafNavTab.surah,
          label: 'Surah',
          optionKey: ValueKey('reader_mushaf_nav_tab_surah'),
        ),
        _MushafControlOption<_MushafNavTab>(
          value: _MushafNavTab.verse,
          label: 'Verse',
          optionKey: ValueKey('reader_mushaf_nav_tab_verse'),
        ),
        _MushafControlOption<_MushafNavTab>(
          value: _MushafNavTab.juz,
          label: 'Juz',
          optionKey: ValueKey('reader_mushaf_nav_tab_juz'),
        ),
        _MushafControlOption<_MushafNavTab>(
          value: _MushafNavTab.page,
          label: 'Page',
          optionKey: ValueKey('reader_mushaf_nav_tab_page'),
        ),
      ],
      selectedValue: _mushafNavTab,
      onSelected: (selected) {
        setState(() {
          _mushafNavTab = selected;
          if (_mushafNavTab == _MushafNavTab.juz) {
            _ensureMushafJuzIndexFuture();
          }
        });
      },
    );
  }

  Widget _buildMushafSettingsTabs() {
    return _buildMushafUnderlineTabs<_MushafSettingsTab>(
      key: const ValueKey('reader_mushaf_settings_tabs'),
      options: const [
        _MushafControlOption<_MushafSettingsTab>(
          value: _MushafSettingsTab.arabic,
          label: 'Arabic',
          optionKey: ValueKey('reader_mushaf_settings_tab_arabic'),
        ),
        _MushafControlOption<_MushafSettingsTab>(
          value: _MushafSettingsTab.translation,
          label: 'Translation',
          optionKey: ValueKey('reader_mushaf_settings_tab_translation'),
        ),
        _MushafControlOption<_MushafSettingsTab>(
          value: _MushafSettingsTab.wordByWord,
          label: 'Word By Word',
          optionKey: ValueKey('reader_mushaf_settings_tab_word_by_word'),
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
      options: const [
        _MushafControlOption<_MushafScriptStyleOption>(
          value: _MushafScriptStyleOption.uthmani,
          label: 'Uthmani',
          optionKey: ValueKey('reader_mushaf_script_tab_uthmani'),
        ),
        _MushafControlOption<_MushafScriptStyleOption>(
          value: _MushafScriptStyleOption.tajweed,
          label: 'Tajweed',
          optionKey: ValueKey('reader_mushaf_script_tab_tajweed'),
        ),
        _MushafControlOption<_MushafScriptStyleOption>(
          value: _MushafScriptStyleOption.indopak,
          label: 'IndoPak (Soon)',
          optionKey: ValueKey('reader_mushaf_script_tab_indopak'),
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

  Widget _buildModeToggle() {
    return SegmentedButton<_ReaderMode>(
      key: const ValueKey('reader_mode_toggle'),
      segments: const [
        ButtonSegment<_ReaderMode>(
          value: _ReaderMode.surah,
          label: Text('Surah Mode'),
          icon: Icon(Icons.menu_book_outlined),
        ),
        ButtonSegment<_ReaderMode>(
          value: _ReaderMode.page,
          label: Text('Page Mode'),
          icon: Icon(Icons.filter_1_outlined),
        ),
      ],
      selected: <_ReaderMode>{_mode},
      onSelectionChanged: _viewMode == _ReaderViewMode.mushaf
          ? null
          : (selection) {
              if (selection.isEmpty) {
                return;
              }
              _switchMode(selection.first);
            },
    );
  }

  Widget _buildArabicRenderToggle() {
    return SegmentedButton<_ArabicRenderMode>(
      key: const ValueKey('reader_arabic_render_toggle'),
      segments: const [
        ButtonSegment<_ArabicRenderMode>(
          value: _ArabicRenderMode.plain,
          label: Text('Plain'),
        ),
        ButtonSegment<_ArabicRenderMode>(
          value: _ArabicRenderMode.tajweed,
          label: Text('Tajweed'),
        ),
      ],
      selected: <_ArabicRenderMode>{_arabicRenderMode},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) {
          return;
        }
        _switchArabicRenderMode(selection.first);
      },
    );
  }

  Widget _buildSimpleTextSourceToggle() {
    return SegmentedButton<_SimpleTextSource>(
      key: const ValueKey('reader_simple_text_source_toggle'),
      segments: const [
        ButtonSegment<_SimpleTextSource>(
          value: _SimpleTextSource.local,
          label: Text('Local'),
        ),
        ButtonSegment<_SimpleTextSource>(
          value: _SimpleTextSource.quranCom,
          label: Text('Quran.com'),
        ),
      ],
      selected: <_SimpleTextSource>{_simpleTextSource},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) {
          return;
        }
        _switchSimpleTextSource(selection.first);
      },
    );
  }

  Widget _buildSurahSelectorPanel(BuildContext context) {
    final filteredSurahs = _filteredSurahNumbers();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Surahs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              key: const ValueKey('reader_surah_search'),
              decoration: const InputDecoration(
                hintText: 'Search Surah',
                isDense: true,
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _surahSearchQuery = value;
                });
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              key: const ValueKey('reader_surah_list'),
              itemCount: filteredSurahs.length,
              itemBuilder: (context, index) {
                final surahNumber = filteredSurahs[index];
                final selected = surahNumber == _selectedSurah;
                return ListTile(
                  key: ValueKey('surah_tile_$surahNumber'),
                  selected: selected,
                  title: Text(_surahLabelFor(surahNumber)),
                  onTap: () => _selectSurah(surahNumber),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageSelectorPanel(BuildContext context) {
    final pagesFuture = _availablePagesFuture;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Pages',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
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
                        const Text('Failed to load pages.'),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          key: const ValueKey('reader_page_retry_button'),
                          onPressed: _refreshCurrentView,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final pages = snapshot.data ?? const <int>[];
                if (pages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No page metadata found. Import Page Metadata in Settings.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  key: const ValueKey('reader_page_list'),
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    final selected = page == _selectedPage;
                    return ListTile(
                      key: ValueKey('reader_page_$page'),
                      selected: selected,
                      title: Text('Page $page'),
                      onTap: () => _selectPage(page),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel(BuildContext context) {
    if (_mode == _ReaderMode.page) {
      return _buildPageSelectorPanel(context);
    }
    return _buildSurahSelectorPanel(context);
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
            decoration: const InputDecoration(
              hintText: 'Search Surah',
              isDense: true,
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _mushafSurahSearchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: const ValueKey('reader_mushaf_nav_surah_list'),
            itemCount: filteredSurahs.length,
            itemBuilder: (context, index) {
              final surah = filteredSurahs[index];
              final selected = surah == _selectedSurah;
              return ListTile(
                key: ValueKey('reader_mushaf_nav_surah_$surah'),
                selected: selected,
                title: Text(_surahLabelFor(surah)),
                onTap: () {
                  unawaited(_jumpToSurahStartInMushaf(surah));
                },
              );
            },
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
            decoration: const InputDecoration(
              labelText: 'Surah',
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
            decoration: const InputDecoration(
              hintText: 'Verse number',
              isDense: true,
              prefixIcon: Icon(Icons.search),
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
                return const Center(
                  child: Text('Failed to load verses.'),
                );
              }
              final maxAyah = snapshot.data ?? 0;
              if (maxAyah <= 0) {
                return const Center(
                  child: Text('No verses available for selected surah.'),
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
                    title: Text('Verse $ayah'),
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
            decoration: const InputDecoration(
              hintText: 'Search Juz',
              isDense: true,
              prefixIcon: Icon(Icons.search),
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
                      const Text('Failed to load Juz index.'),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        key: const ValueKey('reader_mushaf_nav_juz_retry'),
                        onPressed: () {
                          setState(() {
                            _juzIndexFuture = _loadMushafJuzIndex();
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              final entries = _filteredJuzEntries(
                snapshot.data ?? const <MushafJuzNavEntry>[],
              );
              if (entries.isEmpty) {
                return const Center(
                  child: Text('No Juz entries found.'),
                );
              }
              return ListView.builder(
                key: const ValueKey('reader_mushaf_nav_juz_list'),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return ListTile(
                    key: ValueKey('reader_mushaf_nav_juz_${entry.juzNumber}'),
                    title: Text('Juz ${entry.juzNumber}'),
                    subtitle: Text('Page ${entry.page}'),
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
            decoration: const InputDecoration(
              hintText: 'Search Page',
              isDense: true,
              prefixIcon: Icon(Icons.search),
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
                      const Text('Failed to load pages.'),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        key: const ValueKey('reader_page_retry_button'),
                        onPressed: _refreshCurrentView,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              final pages = _filteredPageNumbers(
                snapshot.data ?? const <int>[],
              );
              if (pages.isEmpty) {
                return const Center(
                  child: Text('No pages available.'),
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
                    title: Text('Page $page'),
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
                    'Translation settings are coming soon.',
                  ),
                _MushafSettingsTab.wordByWord =>
                  _buildMushafScaffoldSettingsBody(
                    'Word by Word settings are coming soon.',
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
                  child: const Text('Reset'),
                ),
                const Spacer(),
                FilledButton(
                  key: const ValueKey('reader_mushaf_settings_done'),
                  onPressed: () {
                    setState(() {
                      _mushafSettingsOpen = false;
                    });
                  },
                  child: const Text('Done'),
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
        previewWord?.textQpcHafs ?? previewWord?.codeV2 ?? 'Preview';
    final previewTranslation = previewWord == null
        ? 'Translation unavailable'
        : _mushafWordTooltipMessage(previewWord);

    return SingleChildScrollView(
      key: const ValueKey('reader_mushaf_settings_scroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview:',
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
            'Script style',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _buildMushafScriptStyleTabs(),
          const SizedBox(height: 12),
          CheckboxListTile(
            key: const ValueKey('reader_mushaf_tajweed_toggle'),
            value: _arabicRenderMode == _ArabicRenderMode.tajweed,
            contentPadding: EdgeInsets.zero,
            title: const Text('Show Tajweed rules while reading'),
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
                'Font size',
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selected Reciter'),
                SizedBox(height: 6),
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

  Widget _buildSimpleLayout(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildViewToggle(),
                _buildModeToggle(),
                _buildArabicRenderToggle(),
                if (_viewMode == _ReaderViewMode.simple)
                  _buildSimpleTextSourceToggle(),
              ],
            ),
          ),
        ),
        if (_mode == _ReaderMode.page && _selectedPage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Page $_selectedPage',
                key: const ValueKey('reader_page_label'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 240,
                child: _buildLeftPanel(context),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: _buildAyahPanel()),
            ],
          ),
        ),
      ],
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
        Expanded(child: _buildMushafPanel()),
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
      child: _viewMode == _ReaderViewMode.mushaf
          ? _buildMushafLayout(context)
          : _buildSimpleLayout(context),
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

enum _SimpleTextSource {
  local,
  quranCom,
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

enum _SimplePanelEntryKind {
  ayah,
  basmalaHeader,
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

class _SimplePanelEntry {
  const _SimplePanelEntry._({
    required this.kind,
    this.ayah,
  });

  factory _SimplePanelEntry.ayah({
    required AyahData ayah,
  }) {
    return _SimplePanelEntry._(
      kind: _SimplePanelEntryKind.ayah,
      ayah: ayah,
    );
  }

  factory _SimplePanelEntry.basmalaHeader({
    required AyahData ayah,
  }) {
    return _SimplePanelEntry._(
      kind: _SimplePanelEntryKind.basmalaHeader,
      ayah: ayah,
    );
  }

  final _SimplePanelEntryKind kind;
  final AyahData? ayah;
}

class _SimpleQuranComVerseRenderData {
  const _SimpleQuranComVerseRenderData({
    required this.qcfFamilyName,
    required this.words,
  });

  final String qcfFamilyName;
  final List<MushafWord> words;
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
  });

  final NoteData? existing;

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
        _errorMessage = 'Body is required.';
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
      title: Text(widget.existing == null ? 'Add note' : 'Edit note'),
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
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('note_body_field'),
                controller: _bodyController,
                focusNode: _bodyFocusNode,
                maxLines: 6,
                minLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Note body',
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('note_save_button'),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AyahRow extends StatelessWidget {
  const _AyahRow({
    required this.rowKey,
    required this.ayah,
    required this.tajweedHtml,
    this.arabicContent,
    required this.hovered,
    required this.tappedHighlighted,
    required this.jumpHighlighted,
    required this.rangeHighlighted,
    required this.onHoverChanged,
    required this.onTap,
  });

  final GlobalKey rowKey;
  final AyahData ayah;
  final String? tajweedHtml;
  final Widget? arabicContent;
  final bool hovered;
  final bool tappedHighlighted;
  final bool jumpHighlighted;
  final bool rangeHighlighted;
  final ValueChanged<bool> onHoverChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ayahKey = '${ayah.surah}:${ayah.ayah}';
    final colorScheme = Theme.of(context).colorScheme;
    final background = rangeHighlighted
        ? colorScheme.tertiaryContainer.withOpacity(0.85)
        : jumpHighlighted
            ? colorScheme.secondaryContainer.withOpacity(0.7)
            : tappedHighlighted
                ? colorScheme.primaryContainer.withOpacity(0.7)
                : hovered
                    ? colorScheme.primary.withOpacity(0.08)
                    : Colors.transparent;
    final baseArabicStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
              fontFamily: 'UthmanicHafs',
              fontSize: 34,
              height: 1.9,
            ) ??
        const TextStyle(
          fontFamily: 'UthmanicHafs',
          fontSize: 34,
          height: 1.9,
        );
    final fallbackTextColor =
        baseArabicStyle.color ?? Theme.of(context).colorScheme.onSurface;
    final effectiveArabicContent = arabicContent ??
        (tajweedHtml == null
            ? Text(
                ayah.textUthmani,
                textAlign: TextAlign.right,
                style: baseArabicStyle,
              )
            : RichText(
                textAlign: TextAlign.right,
                text: TextSpan(
                  children: buildTajweedSpans(
                    tajweedHtml: tajweedHtml!,
                    baseStyle: baseArabicStyle,
                    classColors: tajweedClassColors,
                    fallbackColor: fallbackTextColor,
                  ),
                ),
              ));

    return KeyedSubtree(
      key: rowKey,
      child: MouseRegion(
        key: ValueKey('ayah_mouse_$ayahKey'),
        onEnter: (_) => onHoverChanged(true),
        onExit: (_) => onHoverChanged(false),
        child: Material(
          key: ValueKey('ayah_material_$ayahKey'),
          color: background,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            key: ValueKey('ayah_row_$ayahKey'),
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${ayah.surah}:${ayah.ayah}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: effectiveArabicContent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
