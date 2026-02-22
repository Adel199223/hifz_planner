import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_preferences.dart';
import '../l10n/app_strings.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    final strings = AppStrings.of(prefs.language);

    return SafeArea(
      key: const ValueKey('learn_screen_root'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.learnTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              strings.learnSubtitle,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Card(
              key: const ValueKey('learn_hifz_plan_card'),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          strings.hifzPlanTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(strings.hifzPlanSubtitle),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey('learn_hifz_plan_open'),
                      onPressed: () {
                        context.go('/plan');
                      },
                      child: Text(strings.openHifzPlan),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
