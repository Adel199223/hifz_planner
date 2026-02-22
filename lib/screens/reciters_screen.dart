import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_preferences.dart';
import '../l10n/app_strings.dart';

class RecitersScreen extends ConsumerWidget {
  const RecitersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    final strings = AppStrings.of(prefs.language);

    return SafeArea(
      key: const ValueKey('reciters_screen_root'),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              strings.reciters,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(strings.comingSoon),
          ],
        ),
      ),
    );
  }
}
