import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/providers/database_providers.dart';

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
  static final List<String> _surahLabels = List<String>.generate(
    114,
    (index) => 'Surah ${index + 1}',
  );

  _ReaderMode _mode = _ReaderMode.surah;
  int _selectedSurah = 1;
  int? _selectedPage;
  Future<List<int>>? _availablePagesFuture;
  Future<List<AyahData>>? _ayahsFuture;
  String? _hoveredAyahKey;
  String? _tappedAyahKey;
  String? _jumpHighlightedAyahKey;
  _VerseJumpTarget? _pendingJumpTarget;
  _VerseRange? _rangeHighlight;
  bool _jumpScheduled = false;
  int _pageLoadGeneration = 0;

  final ScrollController _ayahScrollController = ScrollController();
  final Map<String, GlobalKey> _ayahRowKeys = <String, GlobalKey>{};
  Timer? _jumpHighlightTimer;

  @override
  void initState() {
    super.initState();
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
    final resolvedMode = _resolveMode(
      mode: widget.mode,
      page: widget.page,
    );
    final target = _normalizeTarget(
      surah: widget.targetSurah,
      ayah: widget.targetAyah,
    );

    _mode = resolvedMode;
    _rangeHighlight = _normalizeRange();
    _pendingJumpTarget = target;
    _clearInteractiveHighlights();
    _jumpScheduled = false;

    if (_mode == _ReaderMode.surah) {
      _pageLoadGeneration += 1;
      _selectedPage = null;
      _availablePagesFuture = null;
      if (target != null) {
        _selectedSurah = target.surah;
      }
      _ayahsFuture = _loadAyahsBySurah(_selectedSurah);
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
    });
  }

  void _clearInteractiveHighlights() {
    _hoveredAyahKey = null;
    _tappedAyahKey = null;
    _jumpHighlightedAyahKey = null;
    _jumpHighlightTimer?.cancel();
  }

  void _switchMode(_ReaderMode mode) {
    if (mode == _mode) {
      return;
    }

    setState(() {
      _mode = mode;
      _pendingJumpTarget = null;
      _clearInteractiveHighlights();
      _jumpScheduled = false;

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
    }
  }

  void _selectSurah(int surah) {
    if (surah == _selectedSurah) {
      return;
    }
    setState(() {
      _selectedSurah = surah;
      _pendingJumpTarget = null;
      _clearInteractiveHighlights();
      _jumpScheduled = false;
      _ayahsFuture = _loadAyahsBySurah(surah);
    });
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
    });
  }

  void _refreshCurrentView() {
    setState(() {
      _clearInteractiveHighlights();
      _jumpScheduled = false;
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

    if (_mode == _ReaderMode.page && _selectedPage == null) {
      _resolvePageSelection(
        requestedPage: widget.page,
        target: null,
        showMissingTargetMessage: false,
      );
    }
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

  Widget _buildAyahPanel() {
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

        return ListView.separated(
          key: const ValueKey('reader_ayah_list'),
          controller: _ayahScrollController,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final ayah = ayahs[index];
            final key = _ayahKey(ayah);
            return _AyahRow(
              rowKey: _ayahRowKey(key),
              ayah: ayah,
              hovered: _hoveredAyahKey == key,
              tappedHighlighted: _tappedAyahKey == key,
              jumpHighlighted: _jumpHighlightedAyahKey == key,
              rangeHighlighted: _isRangeHighlighted(ayah),
              onHoverChanged: (isHovered) {
                setState(() {
                  if (isHovered) {
                    _hoveredAyahKey = key;
                  } else if (_hoveredAyahKey == key) {
                    _hoveredAyahKey = null;
                  }
                });
              },
              onTap: () async {
                setState(() {
                  _tappedAyahKey = key;
                });
                await _showAyahActions(ayah);
              },
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: ayahs.length,
        );
      },
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
      onSelectionChanged: (selection) {
        if (selection.isEmpty) {
          return;
        }
        _switchMode(selection.first);
      },
    );
  }

  Widget _buildSurahSelectorPanel(BuildContext context) {
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
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              key: const ValueKey('reader_surah_list'),
              itemCount: _surahLabels.length,
              itemBuilder: (context, index) {
                final surahNumber = index + 1;
                final selected = surahNumber == _selectedSurah;
                return ListTile(
                  key: ValueKey('surah_tile_$surahNumber'),
                  selected: selected,
                  title: Text(_surahLabels[index]),
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildModeToggle(),
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
      ),
    );
  }
}

enum _ReaderMode {
  surah,
  page,
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
    required this.hovered,
    required this.tappedHighlighted,
    required this.jumpHighlighted,
    required this.rangeHighlighted,
    required this.onHoverChanged,
    required this.onTap,
  });

  final GlobalKey rowKey;
  final AyahData ayah;
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
                    child: Text(
                      ayah.textUthmani,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontFamily: 'UthmanicHafs',
                            fontSize: 34,
                            height: 1.9,
                          ),
                    ),
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
