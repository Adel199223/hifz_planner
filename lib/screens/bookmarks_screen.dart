import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/database/app_database.dart';
import '../data/providers/database_providers.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkRepo = ref.watch(bookmarkRepoProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bookmarks',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<BookmarkData>>(
                stream: bookmarkRepo.watchBookmarks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Failed to load bookmarks.'),
                    );
                  }

                  final bookmarks = snapshot.data ?? const <BookmarkData>[];
                  if (bookmarks.isEmpty) {
                    return const Center(child: Text('No bookmarks yet.'));
                  }

                  return ListView.separated(
                    key: const ValueKey('bookmarks_list'),
                    itemCount: bookmarks.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final bookmark = bookmarks[index];
                      final ayahKey = '${bookmark.surah}:${bookmark.ayah}';

                      return ListTile(
                        key: ValueKey('bookmark_row_$ayahKey'),
                        title: Text(
                          'Surah ${bookmark.surah}, Ayah ${bookmark.ayah}',
                        ),
                        subtitle: Text(
                          'Saved ${_formatDateTime(bookmark.createdAt)}',
                        ),
                        trailing: OutlinedButton(
                          key: ValueKey('bookmark_go_$ayahKey'),
                          onPressed: () {
                            context.go(
                              '/reader?surah=${bookmark.surah}&ayah=${bookmark.ayah}',
                            );
                          },
                          child: const Text('Go to verse'),
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

  String _formatDateTime(DateTime timestamp) {
    final year = timestamp.year.toString().padLeft(4, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}
