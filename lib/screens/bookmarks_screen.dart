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
    final quranRepo = ref.watch(quranRepoProvider);

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

                      return FutureBuilder<AyahData?>(
                        future: quranRepo.getAyah(
                          bookmark.surah,
                          bookmark.ayah,
                        ),
                        builder: (context, snapshot) {
                          final page = snapshot.data?.pageMadina;

                          return ListTile(
                            key: ValueKey('bookmark_row_$ayahKey'),
                            isThreeLine: true,
                            title: Text(
                              'Surah ${bookmark.surah}, Ayah ${bookmark.ayah}',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saved ${_formatDateTime(bookmark.createdAt)}',
                                ),
                                if (page != null)
                                  Text(
                                    'Page $page',
                                    key: ValueKey('bookmark_page_$ayahKey'),
                                  ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  key: ValueKey('bookmark_go_$ayahKey'),
                                  onPressed: () async {
                                    final resolvedPage = (await quranRepo.getAyah(
                                      bookmark.surah,
                                      bookmark.ayah,
                                    ))
                                        ?.pageMadina;
                                    if (!context.mounted) {
                                      return;
                                    }
                                    context.go(
                                      _buildGoToVerseRoute(
                                        surah: bookmark.surah,
                                        ayah: bookmark.ayah,
                                        page: resolvedPage,
                                      ),
                                    );
                                  },
                                  child: const Text('Go to verse'),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  key: ValueKey('bookmark_go_page_$ayahKey'),
                                  onPressed: page == null
                                      ? null
                                      : () {
                                          context.go(
                                            _buildGoToPageRoute(
                                              surah: bookmark.surah,
                                              ayah: bookmark.ayah,
                                              page: page,
                                            ),
                                          );
                                        },
                                  child: const Text('Go to page'),
                                ),
                              ],
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
