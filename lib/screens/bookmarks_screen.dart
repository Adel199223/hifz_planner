import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_preferences.dart';
import '../data/database/app_database.dart';
import '../data/providers/database_providers.dart';
import '../l10n/app_strings.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkRepo = ref.watch(bookmarkRepoProvider);
    final quranRepo = ref.watch(quranRepoProvider);
    final prefs = ref.watch(appPreferencesProvider);
    final strings = AppStrings.of(prefs.language);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.bookmarksTitle,
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
                    return Center(
                      child: Text(strings.failedToLoadBookmarks),
                    );
                  }

                  final bookmarks = snapshot.data ?? const <BookmarkData>[];
                  if (bookmarks.isEmpty) {
                    return Center(child: Text(strings.noBookmarksYet));
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
                            title: Text(
                              strings.surahAyahListLabel(
                                bookmark.surah,
                                bookmark.ayah,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.savedLabel(
                                    _formatDateTime(bookmark.createdAt),
                                  ),
                                ),
                                if (page != null)
                                  Text(
                                    strings.pageLabel(page),
                                    key: ValueKey('bookmark_page_$ayahKey'),
                                  ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton(
                                      key: ValueKey('bookmark_go_$ayahKey'),
                                      onPressed: () async {
                                        final resolvedPage =
                                            (await quranRepo.getAyah(
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
                                      child: Text(strings.goToVerse),
                                    ),
                                    OutlinedButton(
                                      key:
                                          ValueKey('bookmark_go_page_$ayahKey'),
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
                                      child: Text(strings.goToPage),
                                    ),
                                  ],
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
