import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import 'app_preferences.dart';
import 'nav_destination.dart';

final readerSettingsPaneOpenProvider =
    NotifierProvider<_ReaderSettingsPaneOpenNotifier, bool>(
      _ReaderSettingsPaneOpenNotifier.new,
    );

class _ReaderSettingsPaneOpenNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setOpen(bool isOpen) {
    state = isOpen;
  }
}

final navDestinationsProvider = Provider<List<NavDestination>>((ref) {
  final language = ref.watch(
    appPreferencesProvider.select((state) => state.language),
  );
  final strings = AppStrings.of(language);

  return [
    NavDestination(
      label: strings.today,
      path: '/today',
      icon: Icons.today_outlined,
    ),
    NavDestination(
      label: strings.read,
      path: '/reader',
      icon: Icons.menu_book_outlined,
    ),
    NavDestination(
      label: strings.myPlan,
      path: '/plan',
      icon: Icons.event_note_outlined,
    ),
    NavDestination(
      label: strings.library,
      path: '/library',
      icon: Icons.folder_outlined,
      activePaths: const ['/bookmarks', '/notes'],
    ),
  ];
});
