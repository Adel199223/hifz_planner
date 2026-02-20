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
                              Text('Surah ${note.surah}, Ayah ${note.ayah}'),
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
    final titleController = TextEditingController(text: note.title ?? '');
    final bodyController = TextEditingController(text: note.body);
    String? errorMessage;

    final result = await showDialog<_NoteEditorResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Edit note'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      key: const ValueKey('notes_editor_title_field'),
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('notes_editor_body_field'),
                      controller: bodyController,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Body',
                        alignLabelWithHint: true,
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text('Linked verse: Surah ${note.surah}, Ayah ${note.ayah}'),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      key: const ValueKey('notes_editor_go_button'),
                      onPressed: () {
                        Navigator.of(dialogContext).pop(
                          const _NoteEditorResult.goToVerse(),
                        );
                      },
                      child: const Text('Go to verse'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  key: const ValueKey('notes_editor_save_button'),
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
                      _NoteEditorResult.save(
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

    if (result == null || !context.mounted) {
      return;
    }

    if (result.action == _NoteEditorAction.goToVerse) {
      context.go('/reader?surah=${note.surah}&ayah=${note.ayah}');
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
}

enum _NoteEditorAction {
  save,
  goToVerse,
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

  final _NoteEditorAction action;
  final String? title;
  final String? body;
}
