import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nav_destination.dart';

final navDestinationsProvider = Provider<List<NavDestination>>((ref) {
  return const [
    NavDestination(
      label: 'Reader',
      path: '/reader',
      icon: Icons.menu_book_outlined,
    ),
    NavDestination(
      label: 'Bookmarks',
      path: '/bookmarks',
      icon: Icons.bookmark_border,
    ),
    NavDestination(
      label: 'Notes',
      path: '/notes',
      icon: Icons.note_alt_outlined,
    ),
    NavDestination(
      label: 'Plan',
      path: '/plan',
      icon: Icons.event_note_outlined,
    ),
    NavDestination(
      label: 'Today',
      path: '/today',
      icon: Icons.today_outlined,
    ),
    NavDestination(
      label: 'Settings',
      path: '/settings',
      icon: Icons.settings_outlined,
    ),
    NavDestination(
      label: 'About',
      path: '/about',
      icon: Icons.info_outline,
    ),
  ];
});
