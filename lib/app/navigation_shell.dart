import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';
import 'app_preferences.dart';
import 'nav_destination.dart';
import 'navigation_providers.dart';

const double _narrowShellBreakpoint = 840;
const double _wideShellBreakpoint = 1200;
const Set<String> _narrowPrimaryPaths = <String>{
  '/today',
  '/reader',
  '/plan',
  '/settings',
};

class AppNavigationShell extends ConsumerStatefulWidget {
  const AppNavigationShell({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  @override
  ConsumerState<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends ConsumerState<AppNavigationShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openMenuDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _closeMenuDrawer() {
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _navigateFromMenu(String path) {
    _closeMenuDrawer();
    if (widget.location != path) {
      context.go(path);
    }
  }

  String _themeLabel(AppThemeChoice choice, AppStrings strings) {
    return choice == AppThemeChoice.dark
        ? strings.themeDark
        : strings.themeSepia;
  }

  String _resolveNarrowTitle({
    required String location,
    required List<NavDestination> destinations,
    required AppStrings strings,
    required int fallbackIndex,
  }) {
    final resolvedLocation = Uri.tryParse(location)?.path ?? location;
    for (final destination in destinations) {
      if (destination.path == resolvedLocation) {
        return destination.label;
      }
    }

    return switch (resolvedLocation) {
      '/learn' => strings.learn,
      '/my-quran' => strings.myQuran,
      '/quran-radio' => strings.quranRadio,
      '/reciters' => strings.reciters,
      '/similar-verses/rescue' => strings.similarVerseRescueTitle,
      '/companion/chain' => strings.companionProgressiveRevealTitle,
      _ => destinations[fallbackIndex].label,
    };
  }

  @override
  Widget build(BuildContext context) {
    final destinations = ref.watch(navDestinationsProvider);
    final selectedIndex =
        destinations.indexWhere((d) => d.path == widget.location);
    final currentIndex = selectedIndex >= 0 ? selectedIndex : 0;
    final prefs = ref.watch(appPreferencesProvider);
    final isReaderSettingsOpen = ref.watch(readerSettingsPaneOpenProvider);
    final strings = AppStrings.of(prefs.language);
    final isReaderRoute = widget.location == '/reader';
    final shouldShowGlobalMenuButton = !(isReaderRoute && isReaderSettingsOpen);
    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < _narrowShellBreakpoint;
    final isMedium =
        width >= _narrowShellBreakpoint && width < _wideShellBreakpoint;
    final narrowDestinations = destinations
        .where((destination) => _narrowPrimaryPaths.contains(destination.path))
        .toList(growable: false);
    final selectedNarrowIndex = narrowDestinations.indexWhere(
      (destination) => destination.path == widget.location,
    );

    final menuItems = <_GlobalMenuDestination>[
      _GlobalMenuDestination(
        key: const ValueKey('global_menu_item_read'),
        label: strings.read,
        path: '/reader',
        icon: Icons.home_outlined,
      ),
      _GlobalMenuDestination(
        key: const ValueKey('global_menu_item_learn'),
        label: strings.learn,
        path: '/learn',
        icon: Icons.school_outlined,
      ),
      _GlobalMenuDestination(
        key: const ValueKey('global_menu_item_my_quran'),
        label: strings.myQuran,
        path: '/my-quran',
        icon: Icons.bookmark_border,
      ),
      _GlobalMenuDestination(
        key: const ValueKey('global_menu_item_quran_radio'),
        label: strings.quranRadio,
        path: '/quran-radio',
        icon: Icons.headphones_outlined,
      ),
      _GlobalMenuDestination(
        key: const ValueKey('global_menu_item_reciters'),
        label: strings.reciters,
        path: '/reciters',
        icon: Icons.mic_none,
      ),
    ];

    final colorScheme = Theme.of(context).colorScheme;
    final menuButtonBorderColor = colorScheme.outlineVariant;
    final menuButtonBackground = colorScheme.surfaceContainerHighest;
    final drawerBorderColor = colorScheme.outlineVariant;

    final scaffold = Scaffold(
      key: _scaffoldKey,
      appBar: isNarrow
          ? AppBar(
              automaticallyImplyLeading: false,
              title: Text(
                _resolveNarrowTitle(
                  location: widget.location,
                  destinations: destinations,
                  strings: strings,
                  fallbackIndex: currentIndex,
                ),
              ),
              actions: [
                if (shouldShowGlobalMenuButton)
                  IconButton(
                    key: const ValueKey('global_menu_button'),
                    tooltip: strings.menu,
                    onPressed: _openMenuDrawer,
                    icon: const Icon(Icons.menu),
                  ),
              ],
            )
          : null,
      endDrawerEnableOpenDragGesture: false,
      endDrawer: Drawer(
        key: const ValueKey('global_menu_drawer'),
        width: 384,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.menu,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('global_menu_close_button'),
                      tooltip: strings.close,
                      onPressed: _closeMenuDrawer,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: drawerBorderColor),
              Expanded(
                child: ListView.builder(
                  key: const ValueKey('global_menu_list'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        key: item.key,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: Icon(item.icon),
                        title: Text(
                          item.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        onTap: () => _navigateFromMenu(item.path),
                      ),
                    );
                  },
                ),
              ),
              Divider(height: 1, color: drawerBorderColor),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: PopupMenuButton<AppLanguage>(
                        key: const ValueKey('global_menu_language_button'),
                        tooltip: strings.language,
                        initialValue: prefs.language,
                        onSelected: (value) {
                          ref
                              .read(appPreferencesProvider.notifier)
                              .setLanguage(value);
                        },
                        itemBuilder: (context) {
                          return [
                            for (final language in AppLanguage.values)
                              PopupMenuItem<AppLanguage>(
                                key: ValueKey(
                                  'global_menu_language_option_${language.code}',
                                ),
                                value: language,
                                child: Row(
                                  children: [
                                    Icon(
                                      prefs.language == language
                                          ? Icons.check
                                          : Icons.language,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(language.displayName),
                                  ],
                                ),
                              ),
                          ];
                        },
                        child: _DrawerPillButton(
                          borderColor: colorScheme.outlineVariant,
                          icon: Icons.language,
                          label: prefs.language.displayName,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PopupMenuButton<AppThemeChoice>(
                        key: const ValueKey('global_menu_theme_button'),
                        tooltip: strings.changeTheme,
                        initialValue: prefs.theme,
                        onSelected: (value) {
                          ref.read(appPreferencesProvider.notifier).setTheme(
                                value,
                              );
                        },
                        itemBuilder: (context) {
                          return [
                            PopupMenuItem<AppThemeChoice>(
                              key: const ValueKey(
                                'global_menu_theme_option_sepia',
                              ),
                              value: AppThemeChoice.sepia,
                              child: Text(strings.themeSepia),
                            ),
                            PopupMenuItem<AppThemeChoice>(
                              key: const ValueKey(
                                'global_menu_theme_option_dark',
                              ),
                              value: AppThemeChoice.dark,
                              child: Text(strings.themeDark),
                            ),
                          ];
                        },
                        child: _DrawerPillButton(
                          borderColor: colorScheme.outlineVariant,
                          icon: Icons.palette_outlined,
                          label: _themeLabel(prefs.theme, strings),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: isNarrow
          ? widget.child
          : Stack(
              children: [
                Row(
                  children: [
                    NavigationRail(
                      selectedIndex: currentIndex,
                      extended: !isMedium,
                      labelType: isMedium
                          ? NavigationRailLabelType.all
                          : NavigationRailLabelType.none,
                      onDestinationSelected: (index) {
                        context.go(destinations[index].path);
                      },
                      destinations: [
                        for (final destination in destinations)
                          NavigationRailDestination(
                            icon: Icon(destination.icon),
                            label: Text(destination.label),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: widget.child),
                  ],
                ),
                if (shouldShowGlobalMenuButton)
                  PositionedDirectional(
                    top: 8,
                    end: 12,
                    child: SafeArea(
                      child: Material(
                        color: menuButtonBackground,
                        shape: CircleBorder(
                          side: BorderSide(color: menuButtonBorderColor),
                        ),
                        child: IconButton(
                          key: const ValueKey('global_menu_button'),
                          tooltip: strings.menu,
                          onPressed: _openMenuDrawer,
                          icon: const Icon(Icons.menu),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: isNarrow
          ? NavigationBar(
              selectedIndex: selectedNarrowIndex >= 0 ? selectedNarrowIndex : 0,
              onDestinationSelected: (index) {
                context.go(narrowDestinations[index].path);
              },
              destinations: [
                for (final destination in narrowDestinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    label: destination.label,
                  ),
              ],
            )
          : null,
    );

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _closeMenuDrawer,
      },
      child: scaffold,
    );
  }
}

class _GlobalMenuDestination {
  const _GlobalMenuDestination({
    required this.key,
    required this.label,
    required this.path,
    required this.icon,
  });

  final Key key;
  final String label;
  final String path;
  final IconData icon;
}

class _DrawerPillButton extends StatelessWidget {
  const _DrawerPillButton({
    required this.borderColor,
    required this.icon,
    required this.label,
  });

  final Color borderColor;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: StadiumBorder(
          side: BorderSide(color: borderColor),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
