import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/database/app_database.dart';
import '../data/providers/database_providers.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteRepo = ref.watch(noteRepoProvider);
    final quranRepo = ref.watch(quranRepoProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<NoteData>>(
                stream: noteRepo.watchAllNotes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Failed to load notes.'),
                    );
                  }

                  final notes = snapshot.data ?? const <NoteData>[];
                  if (notes.isEmpty) {
                    return const Center(child: Text('No notes yet.'));
                  }

                  return ListView.separated(
                    key: const ValueKey('notes_list'),
                    itemCount: notes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      final title = (note.title ?? '').trim();
                      final displayTitle = title.isEmpty ? 'Untitled' : title;

                      return FutureBuilder<AyahData?>(
                        future: quranRepo.getAyah(note.surah, note.ayah),
                        builder: (context, snapshot) {
                          final page = snapshot.data?.pageMadina;

                          return ListTile(
                            key: ValueKey('note_row_${note.id}'),
                            title: Text(displayTitle),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                      'Surah ${note.surah}, Ayah ${note.ayah}'),
                                  if (page != null)
                                    Text(
                                      'Page $page',
                                      key: ValueKey('note_page_${note.id}'),
                                    ),
                                ],
                              ),
                            ),
                            trailing: Text(
                              _formatDateTime(note.updatedAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: () => _openNoteEditor(
                              context: context,
                              ref: ref,
                              note: note,
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
        ),
      ),
    );
  }

  Future<void> _openNoteEditor({
    required BuildContext context,
    required WidgetRef ref,
    required NoteData note,
  }) async {
    final page =
        (await ref.read(quranRepoProvider).getAyah(note.surah, note.ayah))
            ?.pageMadina;
    if (!context.mounted) {
      return;
    }

    final result = await showDialog<_NoteEditorResult>(
      context: context,
      builder: (dialogContext) {
        return _NotesEditorDialog(
          note: note,
          page: page,
        );
      },
    );

    if (result == null || !context.mounted) {
      return;
    }

    if (result.action == _NoteEditorAction.goToVerse) {
      final route = _buildGoToVerseRoute(
        surah: note.surah,
        ayah: note.ayah,
        page: page,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        context.go(route);
      });
      return;
    }

    if (result.action == _NoteEditorAction.goToPage) {
      if (page != null) {
        final route = _buildGoToPageRoute(
          surah: note.surah,
          ayah: note.ayah,
          page: page,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }
          context.go(route);
        });
      }
      return;
    }

    try {
      final updated = await ref.read(noteRepoProvider).updateNote(
            id: note.id,
            title: result.title,
            body: result.body!,
          );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updated ? 'Note updated.' : 'Note update failed.'),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update note.')),
      );
    }
  }

  String _formatDateTime(DateTime timestamp) {
    final year = timestamp.year.toString().padLeft(4, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  String _buildGoToVerseRoute({
    required int surah,
    required int ayah,
    required int? page,
  }) {
    if (page != null) {
      return _buildGoToPageRoute(
        surah: surah,
        ayah: ayah,
        page: page,
      );
    }
    return '/reader?targetSurah=$surah&targetAyah=$ayah';
  }

  String _buildGoToPageRoute({
    required int surah,
    required int ayah,
    required int page,
  }) {
    return '/reader?mode=page&page=$page&targetSurah=$surah&targetAyah=$ayah';
  }
}

enum _NoteEditorAction {
  save,
  goToVerse,
  goToPage,
}

class _NotesEditorDialog extends StatefulWidget {
  const _NotesEditorDialog({
    required this.note,
    required this.page,
  });

  final NoteData note;
  final int? page;

  @override
  State<_NotesEditorDialog> createState() => _NotesEditorDialogState();
}

class _NotesEditorDialogState extends State<_NotesEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _bodyFocusNode = FocusNode();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title ?? '');
    _bodyController = TextEditingController(text: widget.note.body);
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();
    _bodyFocusNode.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _popWithResult([_NoteEditorResult? result]) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(result);
  }

  void _onSave() {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      setState(() {
        _errorMessage = 'Body is required.';
      });
      return;
    }

    final title = _titleController.text.trim();
    _popWithResult(
      _NoteEditorResult.save(
        title: title.isEmpty ? null : title,
        body: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.page;

    return AlertDialog(
      title: const Text('Edit note'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 460,
          maxHeight: 420,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const ValueKey('notes_editor_title_field'),
                controller: _titleController,
                focusNode: _titleFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('notes_editor_body_field'),
                controller: _bodyController,
                focusNode: _bodyFocusNode,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  alignLabelWithHint: true,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                page == null
                    ? 'Linked verse: Surah ${widget.note.surah}, Ayah ${widget.note.ayah}'
                    : 'Linked verse: Surah ${widget.note.surah}, Ayah ${widget.note.ayah} (Page $page)',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    key: const ValueKey('notes_editor_go_button'),
                    onPressed: () {
                      _popWithResult(const _NoteEditorResult.goToVerse());
                    },
                    child: const Text('Go to verse'),
                  ),
                  OutlinedButton(
                    key: const ValueKey('notes_editor_go_page_button'),
                    onPressed: page == null
                        ? null
                        : () {
                            _popWithResult(const _NoteEditorResult.goToPage());
                          },
                    child: const Text('Go to page'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _popWithResult,
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('notes_editor_save_button'),
          onPressed: _onSave,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _NoteEditorResult {
  const _NoteEditorResult.save({
    required this.title,
    required this.body,
  }) : action = _NoteEditorAction.save;

  const _NoteEditorResult.goToVerse()
      : action = _NoteEditorAction.goToVerse,
        title = null,
        body = null;

  const _NoteEditorResult.goToPage()
      : action = _NoteEditorAction.goToPage,
        title = null,
        body = null;

  final _NoteEditorAction action;
  final String? title;
  final String? body;
}
