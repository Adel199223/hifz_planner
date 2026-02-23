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
  final language =
      ref.watch(appPreferencesProvider.select((state) => state.language));
  final strings = AppStrings.of(language);

  return [
    NavDestination(
      label: strings.reader,
      path: '/reader',
      icon: Icons.menu_book_outlined,
    ),
    NavDestination(
      label: strings.bookmarks,
      path: '/bookmarks',
      icon: Icons.bookmark_border,
    ),
    NavDestination(
      label: strings.notes,
      path: '/notes',
      icon: Icons.note_alt_outlined,
    ),
    NavDestination(
      label: strings.plan,
      path: '/plan',
      icon: Icons.event_note_outlined,
    ),
    NavDestination(
      label: strings.today,
      path: '/today',
      icon: Icons.today_outlined,
    ),
    NavDestination(
      label: strings.settings,
      path: '/settings',
      icon: Icons.settings_outlined,
    ),
    NavDestination(
      label: strings.about,
      path: '/about',
      icon: Icons.info_outline,
    ),
  ];
});
