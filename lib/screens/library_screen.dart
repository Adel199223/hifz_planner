import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_preferences.dart';
import '../l10n/app_strings.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    final strings = AppStrings.of(prefs.language);

    return SafeArea(
      key: const ValueKey('library_screen_root'),
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
                  strings.libraryTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  strings.librarySubtitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _LibraryCard(
                      cardKey: const ValueKey('library_bookmarks_card'),
                      icon: Icons.bookmark_border,
                      title: strings.bookmarks,
                      subtitle: strings.libraryBookmarksDescription,
                      buttonKey: const ValueKey('library_open_bookmarks'),
                      buttonLabel: strings.openBookmarks,
                      onPressed: () {
                        context.go('/bookmarks');
                      },
                    ),
                    _LibraryCard(
                      cardKey: const ValueKey('library_notes_card'),
                      icon: Icons.note_alt_outlined,
                      title: strings.notes,
                      subtitle: strings.libraryNotesDescription,
                      buttonKey: const ValueKey('library_open_notes'),
                      buttonLabel: strings.openNotes,
                      onPressed: () {
                        context.go('/notes');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({
    required this.cardKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonKey,
    required this.buttonLabel,
    required this.onPressed,
  });

  final Key cardKey;
  final IconData icon;
  final String title;
  final String subtitle;
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
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
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
