import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_preferences.dart';
import '../data/providers/audio_providers.dart';
import '../data/providers/my_quran_providers.dart';
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
      return strings.surahAyahListLabel(
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
  });

  final Key cardKey;
  final IconData icon;
  final String title;
  final String summary;
  final String description;
  final Key buttonKey;
  final String buttonLabel;
  final VoidCallback onPressed;

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
