import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_preferences.dart';
import '../data/providers/audio_providers.dart';
import '../data/services/ayah_reciter_catalog_service.dart';
import '../l10n/app_strings.dart';
import '../ui/audio/reciter_selection_list.dart';

class RecitersScreen extends ConsumerWidget {
  const RecitersScreen({super.key});

  Future<void> _applyReciterSelection({
    required BuildContext context,
    required WidgetRef ref,
    required AppStrings strings,
    required AyahReciterOption option,
  }) async {
    if (ref.read(ayahReciterSwitchInProgressProvider)) {
      return;
    }
    final result = await ref
        .read(ayahReciterSwitchCoordinatorProvider)
        .switchReciter(option);
    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    switch (result.status) {
      case ReciterSelectionStatus.applied:
        if (result.didChangeBitrate && result.resolvedBitrate != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                strings.reciterAppliedWithBitrate(
                  option.englishName,
                  result.resolvedBitrate!,
                ),
              ),
            ),
          );
        }
        return;
      case ReciterSelectionStatus.unavailable:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              strings.reciterNotAvailableForStreaming(option.englishName),
            ),
          ),
        );
        return;
      case ReciterSelectionStatus.failed:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              strings
                  .audioLoadFailed(result.error?.toString() ?? strings.unknown),
            ),
          ),
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    final strings = AppStrings.of(prefs.language);
    final selectedReciter = ref.watch(selectedReciterProvider);
    final recitersAsync = ref.watch(ayahReciterCatalogProvider);
    final isSwitchingReciter = ref.watch(ayahReciterSwitchInProgressProvider);

    return SafeArea(
      key: const ValueKey('reciters_screen_root'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.selectReciter,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: recitersAsync.when(
                data: (options) => ReciterSelectionList(
                  strings: strings,
                  options: options,
                  selectedEdition: selectedReciter.edition,
                  enabled: !isSwitchingReciter,
                  onSelected: (option) {
                    unawaited(
                      _applyReciterSelection(
                        context: context,
                        ref: ref,
                        strings: strings,
                        option: option,
                      ),
                    );
                  },
                  searchFieldKey: const ValueKey('reciters_search_field'),
                  listKey: const ValueKey('reciters_list'),
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (_, __) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(strings.failedToLoadReciters),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        key: const ValueKey('reciters_retry_button'),
                        onPressed: () {
                          ref.invalidate(ayahReciterCatalogProvider);
                        },
                        child: Text(strings.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
