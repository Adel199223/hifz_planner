import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_preferences.dart';
import '../data/providers/database_providers.dart';
import '../data/services/my_quran_overview_service.dart';
import '../data/time/local_day_time.dart';
import '../l10n/app_strings.dart';

class MyQuranScreen extends ConsumerStatefulWidget {
  const MyQuranScreen({super.key});

  @override
  ConsumerState<MyQuranScreen> createState() => _MyQuranScreenState();
}

class _MyQuranScreenState extends ConsumerState<MyQuranScreen> {
  late Future<MyQuranOverview> _overviewFuture;

  @override
  void initState() {
    super.initState();
    _overviewFuture = _loadOverview();
  }

  Future<MyQuranOverview> _loadOverview() {
    final todayDay = localDayIndex(DateTime.now().toLocal());
    return ref.read(myQuranOverviewServiceProvider).loadOverview(
          todayDay: todayDay,
        );
  }

  void _refreshOverview() {
    setState(() {
      _overviewFuture = _loadOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPreferencesProvider);
    final strings = AppStrings.of(prefs.language);

    return SafeArea(
      key: const ValueKey('my_quran_screen_root'),
      child: FutureBuilder<MyQuranOverview>(
        future: _overviewFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                key: ValueKey('my_quran_loading'),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              key: const ValueKey('my_quran_error'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.failedToLoadMyQuran),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    key: const ValueKey('my_quran_retry_button'),
                    onPressed: _refreshOverview,
                    child: Text(strings.retry),
                  ),
                ],
              ),
            );
          }

          final overview = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.myQuran,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  strings.myQuranSubtitle,
                  key: const ValueKey('my_quran_subtitle'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                _buildResumeCard(strings, overview),
                const SizedBox(height: 16),
                _buildStatsSection(strings, overview),
                const SizedBox(height: 16),
                _buildQuickActionsSection(strings),
                const SizedBox(height: 16),
                _buildRecentBookmarksSection(strings, overview),
                const SizedBox(height: 16),
                _buildRecentNotesSection(strings, overview),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumeCard(
    AppStrings strings,
    MyQuranOverview overview,
  ) {
    final cursor = overview.cursor;

    return Card(
      key: const ValueKey('my_quran_resume_card'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.myQuranResumeTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              strings.myQuranNextTarget(
                cursor.surah,
                cursor.ayah,
              ),
              key: const ValueKey('my_quran_next_target'),
            ),
            if (cursor.pageMadina != null) ...[
              const SizedBox(height: 4),
              Text(strings.pageLabel(cursor.pageMadina!)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: const ValueKey('my_quran_open_reader_button'),
                  onPressed: () {
                    context.go(
                      _buildCursorReaderRoute(cursor),
                    );
                  },
                  child: Text(strings.myQuranOpenReaderAction),
                ),
                OutlinedButton(
                  key: const ValueKey('my_quran_open_today_button'),
                  onPressed: () => context.go('/today'),
                  child: Text(strings.myQuranOpenTodayAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(
    AppStrings strings,
    MyQuranOverview overview,
  ) {
    return Card(
      key: const ValueKey('my_quran_stats_section'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.myQuranStatsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildStatTile(
                  key: const ValueKey('my_quran_stat_units'),
                  label: strings.myQuranStatMemorizationUnits,
                  value: overview.totalMemorizationUnits,
                ),
                _buildStatTile(
                  key: const ValueKey('my_quran_stat_due_reviews'),
                  label: strings.myQuranStatDueReviews,
                  value: overview.dueReviewCount,
                ),
                _buildStatTile(
                  key: const ValueKey('my_quran_stat_stage4_due'),
                  label: strings.myQuranStatStage4Due,
                  value: overview.stage4DueCount,
                ),
                _buildStatTile(
                  key: const ValueKey('my_quran_stat_bookmarks'),
                  label: strings.myQuranStatBookmarks,
                  value: overview.bookmarkCount,
                ),
                _buildStatTile(
                  key: const ValueKey('my_quran_stat_notes'),
                  label: strings.myQuranStatNotes,
                  value: overview.noteCount,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required Key key,
    required String label,
    required int value,
  }) {
    return SizedBox(
      width: 172,
      child: DecoratedBox(
        key: key,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(AppStrings strings) {
    return Card(
      key: const ValueKey('my_quran_quick_actions_section'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.myQuranQuickActionsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const ValueKey('my_quran_open_plan_button'),
                  onPressed: () => context.go('/plan'),
                  child: Text(strings.myQuranOpenPlanAction),
                ),
                OutlinedButton(
                  key: const ValueKey('my_quran_open_bookmarks_button'),
                  onPressed: () => context.go('/bookmarks'),
                  child: Text(strings.myQuranOpenBookmarksAction),
                ),
                OutlinedButton(
                  key: const ValueKey('my_quran_open_notes_button'),
                  onPressed: () => context.go('/notes'),
                  child: Text(strings.myQuranOpenNotesAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookmarksSection(
    AppStrings strings,
    MyQuranOverview overview,
  ) {
    return Card(
      key: const ValueKey('my_quran_recent_bookmarks_section'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.myQuranRecentBookmarksTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (overview.recentBookmarks.isEmpty)
              Text(strings.noBookmarksYet)
            else
              Column(
                children: [
                  for (final preview in overview.recentBookmarks)
                    _buildBookmarkPreviewRow(strings, preview),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkPreviewRow(
    AppStrings strings,
    MyQuranBookmarkPreview preview,
  ) {
    final ayahKey = '${preview.bookmark.surah}:${preview.bookmark.ayah}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        key: ValueKey('my_quran_bookmark_$ayahKey'),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          title: Text(
            strings.surahAyahListLabel(
              preview.bookmark.surah,
              preview.bookmark.ayah,
            ),
          ),
          subtitle: preview.pageMadina == null
              ? null
              : Text(strings.pageLabel(preview.pageMadina!)),
          trailing: OutlinedButton(
            key: ValueKey('my_quran_bookmark_open_$ayahKey'),
            onPressed: () {
              context.go(
                _buildVerseRoute(
                  surah: preview.bookmark.surah,
                  ayah: preview.bookmark.ayah,
                  page: preview.pageMadina,
                ),
              );
            },
            child: Text(strings.goToVerse),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentNotesSection(
    AppStrings strings,
    MyQuranOverview overview,
  ) {
    return Card(
      key: const ValueKey('my_quran_recent_notes_section'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.myQuranRecentNotesTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (overview.recentNotes.isEmpty)
              Text(strings.noNotesYet)
            else
              Column(
                children: [
                  for (final preview in overview.recentNotes)
                    _buildNotePreviewRow(strings, preview),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotePreviewRow(
    AppStrings strings,
    MyQuranNotePreview preview,
  ) {
    final note = preview.note;
    final title = (note.title ?? '').trim();
    final displayTitle = title.isEmpty ? strings.untitled : title;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        key: ValueKey('my_quran_note_${note.id}'),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          title: Text(displayTitle),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Text(
                note.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(strings.surahAyahListLabel(note.surah, note.ayah)),
              if (preview.pageMadina != null)
                Text(strings.pageLabel(preview.pageMadina!)),
            ],
          ),
          trailing: OutlinedButton(
            key: ValueKey('my_quran_note_open_${note.id}'),
            onPressed: () {
              context.go(
                _buildVerseRoute(
                  surah: note.surah,
                  ayah: note.ayah,
                  page: preview.pageMadina,
                ),
              );
            },
            child: Text(strings.goToVerse),
          ),
        ),
      ),
    );
  }

  String _buildCursorReaderRoute(MyQuranCursorTarget cursor) {
    return _buildVerseRoute(
      surah: cursor.surah,
      ayah: cursor.ayah,
      page: cursor.pageMadina,
    );
  }

  String _buildVerseRoute({
    required int surah,
    required int ayah,
    required int? page,
  }) {
    if (page != null) {
      return '/reader?mode=page&page=$page&targetSurah=$surah&targetAyah=$ayah';
    }
    return '/reader?targetSurah=$surah&targetAyah=$ayah';
  }
}
