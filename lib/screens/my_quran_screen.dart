import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_preferences.dart';
import '../data/providers/audio_providers.dart';
import '../data/providers/my_quran_providers.dart';
import '../data/services/my_quran_snapshot_service.dart';
import '../l10n/app_strings.dart';

class MyQuranScreen extends ConsumerWidget {
  const MyQuranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider);
    final audioPreferences = ref.watch(ayahAudioPreferencesProvider);
    final strings = AppStrings.of(preferences.language);
    final dashboardAsync = ref.watch(myQuranDashboardSnapshotProvider);

    return SafeArea(
      key: const ValueKey('my_quran_screen_root'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
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
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                if (!preferences.hasLoaded || !audioPreferences.hasLoaded)
                  const Center(child: CircularProgressIndicator())
                else
                  dashboardAsync.when(
                    data: (snapshot) => Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _MyQuranCard(
                          cardKey: const ValueKey('my_quran_continue_card'),
                          icon: Icons.menu_book_outlined,
                          title: strings.myQuranContinueReadingTitle,
                          summary: _continueReadingSummary(
                            strings,
                            snapshot.lastReaderLocation,
                          ),
                          description: snapshot.lastReaderLocation == null
                              ? strings.myQuranNoRecentReading
                              : strings.myQuranContinueReadingDescription,
                          buttonKey: const ValueKey('my_quran_continue_button'),
                          buttonLabel: snapshot.lastReaderLocation == null
                              ? strings.myQuranOpenReader
                              : strings.myQuranContinueReadingButton,
                          onPressed: () {
                            context.go(
                              _buildContinueReadingRoute(
                                snapshot.lastReaderLocation,
                              ),
                            );
                          },
                          extraContent: _buildContinueReadingPreview(
                            context,
                            strings,
                            snapshot.lastReaderLocation,
                          ),
                        ),
                        _MyQuranCard(
                          cardKey: const ValueKey('my_quran_saved_card'),
                          icon: Icons.bookmark_border,
                          title: strings.myQuranSavedForLaterTitle,
                          summary: strings.myQuranSavedCounts(
                            snapshot.bookmarkCount,
                            snapshot.noteCount,
                          ),
                          description:
                              snapshot.bookmarkCount == 0 &&
                                  snapshot.noteCount == 0
                              ? strings.myQuranNoSavedItems
                              : strings.myQuranSavedForLaterDescription,
                          buttonKey: const ValueKey('my_quran_library_button'),
                          buttonLabel: strings.myQuranOpenLibrary,
                          onPressed: () {
                            context.go('/library');
                          },
                          extraContent: _buildSavedStudyPreview(
                            context,
                            strings,
                            snapshot,
                          ),
                        ),
                        _MyQuranCard(
                          cardKey: const ValueKey('my_quran_listening_card'),
                          icon: Icons.graphic_eq_outlined,
                          title: strings.myQuranListeningSetupTitle,
                          summary: snapshot.reciterDisplayName,
                          description: strings.myQuranListeningSetupSummary(
                            _formatSpeed(snapshot.speed),
                            _repeatLabel(strings, snapshot.repeatCount),
                          ),
                          buttonKey: const ValueKey('my_quran_reciters_button'),
                          buttonLabel: strings.myQuranOpenReciters,
                          onPressed: () {
                            context.go('/reciters');
                          },
                        ),
                      ],
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) =>
                        Center(child: Text(strings.myQuranLoadFailed)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildContinueReadingPreview(
    BuildContext context,
    AppStrings strings,
    ReaderLastLocation? location,
  ) {
    if (location == null ||
        location.targetSurah == null ||
        location.targetAyah == null) {
      return null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          strings.surahAyahListLabel(
            location.targetSurah!,
            location.targetAyah!,
          ),
          key: const ValueKey('my_quran_continue_target'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }

  Widget? _buildSavedStudyPreview(
    BuildContext context,
    AppStrings strings,
    MyQuranDashboardSnapshot snapshot,
  ) {
    if (snapshot.latestBookmark == null && snapshot.latestNote == null) {
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (snapshot.latestBookmark != null)
          _SavedStudyPreviewSection(
            sectionKey: const ValueKey('my_quran_latest_bookmark_section'),
            label: strings.myQuranLatestBookmark,
            title: strings.surahAyahListLabel(
              snapshot.latestBookmark!.bookmark.surah,
              snapshot.latestBookmark!.bookmark.ayah,
            ),
            body: snapshot.latestBookmark!.ayah?.textUthmani,
            trailing: snapshot.latestBookmark!.ayah?.pageMadina == null
                ? null
                : strings.pageLabel(snapshot.latestBookmark!.ayah!.pageMadina!),
            buttonKey: const ValueKey('my_quran_reopen_bookmark_button'),
            buttonLabel: strings.goToVerse,
            onPressed: () {
              context.go(
                _buildVerseRoute(
                  surah: snapshot.latestBookmark!.bookmark.surah,
                  ayah: snapshot.latestBookmark!.bookmark.ayah,
                  page: snapshot.latestBookmark!.ayah?.pageMadina,
                ),
              );
            },
          ),
        if (snapshot.latestBookmark != null && snapshot.latestNote != null)
          const SizedBox(height: 12),
        if (snapshot.latestNote != null)
          _SavedStudyPreviewSection(
            sectionKey: const ValueKey('my_quran_latest_note_section'),
            label: strings.myQuranLatestNote,
            title: strings.surahAyahListLabel(
              snapshot.latestNote!.note.surah,
              snapshot.latestNote!.note.ayah,
            ),
            body: _buildLatestNoteBody(strings, snapshot.latestNote!),
            trailing: snapshot.latestNote!.ayah?.pageMadina == null
                ? null
                : strings.pageLabel(snapshot.latestNote!.ayah!.pageMadina!),
            buttonKey: const ValueKey('my_quran_reopen_note_button'),
            buttonLabel: strings.goToVerse,
            onPressed: () {
              context.go(
                _buildVerseRoute(
                  surah: snapshot.latestNote!.note.surah,
                  ayah: snapshot.latestNote!.note.ayah,
                  page: snapshot.latestNote!.ayah?.pageMadina,
                ),
              );
            },
          ),
      ],
    );
  }

  String _continueReadingSummary(
    AppStrings strings,
    ReaderLastLocation? location,
  ) {
    if (location == null) {
      return strings.myQuranContinueReadingFallback;
    }
    if (location.mode == ReaderLastLocationMode.page && location.page != null) {
      return strings.myQuranResumeFromPage(location.page!);
    }
    if (location.targetSurah != null && location.targetAyah != null) {
      return strings.myQuranResumeVerse(
        location.targetSurah!,
        location.targetAyah!,
      );
    }
    return strings.myQuranContinueReadingFallback;
  }

  String _buildContinueReadingRoute(ReaderLastLocation? location) {
    if (location == null) {
      return '/reader';
    }
    final queryParameters = <String, String>{};
    if (location.mode == ReaderLastLocationMode.page && location.page != null) {
      queryParameters['mode'] = 'page';
      queryParameters['page'] = location.page!.toString();
    }
    if (location.targetSurah != null && location.targetAyah != null) {
      queryParameters['targetSurah'] = location.targetSurah!.toString();
      queryParameters['targetAyah'] = location.targetAyah!.toString();
    }
    if (queryParameters.isEmpty) {
      return '/reader';
    }
    final query = Uri(queryParameters: queryParameters).query;
    return '/reader?$query';
  }

  String _buildVerseRoute({
    required int surah,
    required int ayah,
    int? page,
  }) {
    if (page != null) {
      return '/reader?mode=page&page=$page&targetSurah=$surah&targetAyah=$ayah';
    }
    return '/reader?targetSurah=$surah&targetAyah=$ayah';
  }

  String _buildLatestNoteBody(
    AppStrings strings,
    MyQuranNotePreview preview,
  ) {
    final title = (preview.note.title ?? '').trim();
    final body = preview.note.body.trim();
    if (title.isEmpty) {
      return body;
    }
    if (body.isEmpty) {
      return title;
    }
    return strings.myQuranLatestNoteSummary(title, body);
  }

  String _formatSpeed(double speed) {
    if (speed == speed.roundToDouble()) {
      return '${speed.toStringAsFixed(0)}x';
    }
    return '${speed.toStringAsFixed(2)}x';
  }

  String _repeatLabel(AppStrings strings, int repeatCount) {
    switch (repeatCount) {
      case 1:
        return strings.repeat1x;
      case 2:
        return strings.repeat2x;
      case 3:
        return strings.repeat3x;
      default:
        return strings.repeatOff;
    }
  }
}

class _MyQuranCard extends StatelessWidget {
  const _MyQuranCard({
    required this.cardKey,
    required this.icon,
    required this.title,
    required this.summary,
    required this.description,
    required this.buttonKey,
    required this.buttonLabel,
    required this.onPressed,
    this.extraContent,
  });

  final Key cardKey;
  final IconData icon;
  final String title;
  final String summary;
  final String description;
  final Key buttonKey;
  final String buttonLabel;
  final VoidCallback onPressed;
  final Widget? extraContent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Card(
        key: cardKey,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(summary, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
              if (extraContent != null) ...[
                const SizedBox(height: 16),
                extraContent!,
              ],
              const SizedBox(height: 16),
              FilledButton.tonal(
                key: buttonKey,
                onPressed: onPressed,
                child: Text(buttonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedStudyPreviewSection extends StatelessWidget {
  const _SavedStudyPreviewSection({
    required this.sectionKey,
    required this.label,
    required this.title,
    required this.body,
    required this.buttonKey,
    required this.buttonLabel,
    required this.onPressed,
    this.trailing,
  });

  final Key sectionKey;
  final String label;
  final String title;
  final String? body;
  final String? trailing;
  final Key buttonKey;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: sectionKey,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (body != null && body!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              body!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textDirection: _looksArabic(body!)
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              textAlign: _looksArabic(body!)
                  ? TextAlign.right
                  : TextAlign.start,
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(height: 6),
            Text(trailing!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 10),
          OutlinedButton(
            key: buttonKey,
            onPressed: onPressed,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  bool _looksArabic(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return false;
    }
    return normalized.runes.any(
      (rune) => rune >= 0x0600 && rune <= 0x06FF,
    );
  }
}
