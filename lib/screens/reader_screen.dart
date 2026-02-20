import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/providers/database_providers.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    this.targetSurah,
    this.targetAyah,
  });

  final int? targetSurah;
  final int? targetAyah;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  static final List<String> _surahLabels = List<String>.generate(
    114,
    (index) => 'Surah ${index + 1}',
  );

  int _selectedSurah = 1;
  Future<List<AyahData>>? _ayahsFuture;
  String? _hoveredAyahKey;
  String? _jumpHighlightedAyahKey;
  int? _pendingJumpSurah;
  int? _pendingJumpAyah;
  bool _jumpScheduled = false;

  final ScrollController _ayahScrollController = ScrollController();
  final Map<String, GlobalKey> _ayahRowKeys = <String, GlobalKey>{};
  Timer? _jumpHighlightTimer;

  @override
  void initState() {
    super.initState();

    final initialTarget = _normalizeTarget(
      surah: widget.targetSurah,
      ayah: widget.targetAyah,
    );
    if (initialTarget != null) {
      _selectedSurah = initialTarget.surah;
      _pendingJumpSurah = initialTarget.surah;
      _pendingJumpAyah = initialTarget.ayah;
    }

    _ayahsFuture = _loadAyahs(_selectedSurah);
  }

  @override
  void didUpdateWidget(covariant ReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.targetSurah == widget.targetSurah &&
        oldWidget.targetAyah == widget.targetAyah) {
      return;
    }

    final target = _normalizeTarget(
      surah: widget.targetSurah,
      ayah: widget.targetAyah,
    );
    if (target == null) {
      return;
    }

    setState(() {
      _pendingJumpSurah = target.surah;
      _pendingJumpAyah = target.ayah;
      _hoveredAyahKey = null;

      if (_selectedSurah != target.surah) {
        _selectedSurah = target.surah;
      }
      _ayahsFuture = _loadAyahs(_selectedSurah);
    });
  }

  @override
  void dispose() {
    _jumpHighlightTimer?.cancel();
    _ayahScrollController.dispose();
    super.dispose();
  }

  Future<List<AyahData>> _loadAyahs(int surah) {
    return ref.read(quranRepoProvider).getAyahsBySurah(surah);
  }

  void _selectSurah(int surah) {
    if (surah == _selectedSurah) {
      return;
    }
    setState(() {
      _selectedSurah = surah;
      _hoveredAyahKey = null;
      _pendingJumpSurah = null;
      _pendingJumpAyah = null;
      _jumpHighlightedAyahKey = null;
      _ayahsFuture = _loadAyahs(surah);
    });
    _jumpHighlightTimer?.cancel();
  }

  void _refreshSurah() {
    setState(() {
      _ayahsFuture = _loadAyahs(_selectedSurah);
    });
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

  void _queuePendingJump(List<AyahData> ayahs) {
    if (_jumpScheduled || _pendingJumpAyah == null || _pendingJumpSurah == null) {
      return;
    }
    if (_pendingJumpSurah != _selectedSurah) {
      return;
    }

    _jumpScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _jumpScheduled = false;
      await _performPendingJump(ayahs);
    });
  }

  Future<void> _performPendingJump(List<AyahData> ayahs) async {
    final pendingAyah = _pendingJumpAyah;
    if (!mounted || pendingAyah == null || _pendingJumpSurah != _selectedSurah) {
      return;
    }

    final targetIndex = ayahs.indexWhere((row) => row.ayah == pendingAyah);
    if (targetIndex < 0) {
      setState(() {
        _pendingJumpAyah = null;
        _pendingJumpSurah = null;
      });
      _showSnackBar('Ayah $pendingAyah was not found in Surah $_selectedSurah.');
      return;
    }

    final targetAyah = ayahs[targetIndex];
    final targetKey = _ayahKey(targetAyah);

    if (_ayahScrollController.hasClients) {
      final maxExtent = _ayahScrollController.position.maxScrollExtent;
      final estimatedOffset = (targetIndex * 140.0).clamp(0.0, maxExtent);
      _ayahScrollController.jumpTo(estimatedOffset);
    }

    BuildContext? rowContext = _ayahRowKey(targetKey).currentContext;
    for (var attempt = 0; attempt < 3 && rowContext == null; attempt++) {
      if (_ayahScrollController.hasClients) {
        final maxExtent = _ayahScrollController.position.maxScrollExtent;
        final probeOffset = ((targetIndex * 140.0) + (attempt * 320.0)).clamp(
          0.0,
          maxExtent,
        );
        _ayahScrollController.jumpTo(probeOffset);
      }
      await Future<void>.delayed(const Duration(milliseconds: 16));
      rowContext = _ayahRowKey(targetKey).currentContext;
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
      _pendingJumpAyah = null;
      _pendingJumpSurah = null;
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
                onTap: () => Navigator.of(sheetContext).pop(_AyahAction.bookmark),
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
    await Clipboard.setData(
      ClipboardData(text: ayah.textUthmani),
    );
    _showSnackBar('Copied verse text.');
  }

  Future<_NoteDraft?> _showNoteDialog(NoteData? existing) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final bodyController = TextEditingController(text: existing?.body ?? '');
    String? errorMessage;

    final result = await showDialog<_NoteDraft>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add note' : 'Edit note'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      key: const ValueKey('note_title_field'),
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('note_body_field'),
                      controller: bodyController,
                      maxLines: 6,
                      minLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Note body',
                        alignLabelWithHint: true,
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Theme.of(dialogContext).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  key: const ValueKey('note_save_button'),
                  onPressed: () {
                    final body = bodyController.text.trim();
                    if (body.isEmpty) {
                      setDialogState(() {
                        errorMessage = 'Body is required.';
                      });
                      return;
                    }

                    final title = titleController.text.trim();
                    Navigator.of(dialogContext).pop(
                      _NoteDraft(
                        title: title.isEmpty ? null : title,
                        body: body,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    bodyController.dispose();
    return result;
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
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
                  onPressed: _refreshSurah,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final ayahs = snapshot.data ?? const <AyahData>[];
        if (ayahs.isEmpty) {
          return Center(
            child: Text('No ayahs found for Surah $_selectedSurah.'),
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
              jumpHighlighted: _jumpHighlightedAyahKey == key,
              onHoverChanged: (isHovered) {
                setState(() {
                  if (isHovered) {
                    _hoveredAyahKey = key;
                  } else if (_hoveredAyahKey == key) {
                    _hoveredAyahKey = null;
                  }
                });
              },
              onTap: () => _showAyahActions(ayah),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: ayahs.length,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: DecoratedBox(
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
                          selected: selected,
                          title: Text(_surahLabels[index]),
                          onTap: () => _selectSurah(surahNumber),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _buildAyahPanel()),
        ],
      ),
    );
  }
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

class _AyahRow extends StatelessWidget {
  const _AyahRow({
    required this.rowKey,
    required this.ayah,
    required this.hovered,
    required this.jumpHighlighted,
    required this.onHoverChanged,
    required this.onTap,
  });

  final GlobalKey rowKey;
  final AyahData ayah;
  final bool hovered;
  final bool jumpHighlighted;
  final ValueChanged<bool> onHoverChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ayahKey = '${ayah.surah}:${ayah.ayah}';
    final colorScheme = Theme.of(context).colorScheme;
    final background = jumpHighlighted
        ? colorScheme.secondaryContainer.withOpacity(0.7)
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
                      const SizedBox(width: 8),
                      if (ayah.pageMadina != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Page ${ayah.pageMadina}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      ayah.textUthmani,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.titleLarge,
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
