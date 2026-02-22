import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_preferences.dart';
import '../l10n/app_strings.dart';

class MyQuranScreen extends ConsumerWidget {
  const MyQuranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    final strings = AppStrings.of(prefs.language);

    return SafeArea(
      key: const ValueKey('my_quran_screen_root'),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              strings.myQuran,
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
