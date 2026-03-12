import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_preferences.dart';
import '../l10n/app_strings.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  String _themeLabel(AppThemeChoice choice, AppStrings strings) {
    return choice == AppThemeChoice.dark
        ? strings.themeDark
        : strings.themeSepia;
  }

  String _companionAutoplayLabel(bool enabled, AppStrings strings) {
    return enabled ? strings.companionAutoplayOn : strings.companionAutoplayOff;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    final strings = AppStrings.of(prefs.language);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      key: const ValueKey('about_screen_root'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wideLayout = constraints.maxWidth >= 820;
                final topCardWidth = wideLayout
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        border: Border.all(color: colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Icon(
                                  Icons.auto_stories_outlined,
                                  size: 28,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strings.aboutTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    strings.aboutSubtitle,
                                    key: const ValueKey('about_subtitle'),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: topCardWidth,
                          child: _AboutSectionCard(
                            cardKey: const ValueKey('about_quick_actions_card'),
                            title: strings.aboutQuickActionsTitle,
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _AboutActionButton(
                                  buttonKey:
                                      const ValueKey('about_action_reader'),
                                  icon: Icons.menu_book_outlined,
                                  label: strings.reader,
                                  onPressed: () => context.go('/reader'),
                                ),
                                _AboutActionButton(
                                  buttonKey:
                                      const ValueKey('about_action_today'),
                                  icon: Icons.today_outlined,
                                  label: strings.today,
                                  onPressed: () => context.go('/today'),
                                ),
                                _AboutActionButton(
                                  buttonKey:
                                      const ValueKey('about_action_plan'),
                                  icon: Icons.event_note_outlined,
                                  label: strings.plan,
                                  onPressed: () => context.go('/plan'),
                                ),
                                _AboutActionButton(
                                  buttonKey:
                                      const ValueKey('about_action_my_quran'),
                                  icon: Icons.bookmark_border,
                                  label: strings.myQuran,
                                  onPressed: () => context.go('/my-quran'),
                                ),
                                _AboutActionButton(
                                  buttonKey:
                                      const ValueKey('about_action_settings'),
                                  icon: Icons.settings_outlined,
                                  label: strings.settings,
                                  onPressed: () => context.go('/settings'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: topCardWidth,
                          child: _AboutSectionCard(
                            cardKey: const ValueKey('about_setup_card'),
                            title: strings.aboutCurrentSetupTitle,
                            child: Column(
                              children: [
                                _AboutMetaTile(
                                  tileKey:
                                      const ValueKey('about_language_tile'),
                                  icon: Icons.language,
                                  label: strings.language,
                                  value: prefs.language.displayName,
                                ),
                                const SizedBox(height: 10),
                                _AboutMetaTile(
                                  tileKey: const ValueKey('about_theme_tile'),
                                  icon: Icons.palette_outlined,
                                  label: strings.changeTheme,
                                  value: _themeLabel(prefs.theme, strings),
                                ),
                                const SizedBox(height: 10),
                                _AboutMetaTile(
                                  tileKey: const ValueKey(
                                    'about_companion_autoplay_tile',
                                  ),
                                  icon: Icons.play_circle_outline,
                                  label: strings.companionAutoplayNextAyah,
                                  value: _companionAutoplayLabel(
                                    prefs.companionAutoReciteEnabled,
                                    strings,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _AboutSectionCard(
                      cardKey: const ValueKey('about_workflow_card'),
                      title: strings.aboutHowItWorksTitle,
                      child: Column(
                        children: [
                          _AboutStepTile(
                            icon: Icons.menu_book_outlined,
                            title: strings.reader,
                            description: strings.aboutHowItWorksReader,
                          ),
                          const SizedBox(height: 12),
                          _AboutStepTile(
                            icon: Icons.event_note_outlined,
                            title: strings.plan,
                            description: strings.aboutHowItWorksPlan,
                          ),
                          const SizedBox(height: 12),
                          _AboutStepTile(
                            icon: Icons.today_outlined,
                            title: strings.today,
                            description: strings.aboutHowItWorksToday,
                          ),
                          const SizedBox(height: 12),
                          _AboutStepTile(
                            icon: Icons.school_outlined,
                            title: strings.companionProgressiveRevealTitle,
                            description: strings.aboutHowItWorksCompanion,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AboutSectionCard(
                      cardKey: const ValueKey('about_reliability_card'),
                      title: strings.aboutReliabilityTitle,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.aboutReliabilityBody),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            key: const ValueKey('about_view_licenses_button'),
                            onPressed: () {
                              showLicensePage(
                                context: context,
                                applicationName: 'Hifz Planner',
                              );
                            },
                            icon: const Icon(Icons.description_outlined),
                            label: Text(strings.aboutViewLicensesAction),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutSectionCard extends StatelessWidget {
  const _AboutSectionCard({
    required this.cardKey,
    required this.title,
    required this.child,
  });

  final Key cardKey;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: cardKey,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _AboutActionButton extends StatelessWidget {
  const _AboutActionButton({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      key: buttonKey,
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _AboutMetaTile extends StatelessWidget {
  const _AboutMetaTile({
    required this.tileKey,
    required this.icon,
    required this.label,
    required this.value,
  });

  final Key tileKey;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: tileKey,
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutStepTile extends StatelessWidget {
  const _AboutStepTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(description),
            ],
          ),
        ),
      ],
    );
  }
}
