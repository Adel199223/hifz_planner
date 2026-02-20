import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/about_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/plan_screen.dart';
import '../screens/reader_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/today_screen.dart';
import 'navigation_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/today',
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/today',
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppNavigationShell(
            location: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/reader',
            builder: (context, state) {
              final params = state.uri.queryParameters;
              final mode = params['mode'];
              final page = int.tryParse(params['page'] ?? '');

              final targetSurah = int.tryParse(
                params['targetSurah'] ?? params['surah'] ?? '',
              );
              final targetAyah = int.tryParse(
                params['targetAyah'] ?? params['ayah'] ?? '',
              );

              final highlightStartSurah = int.tryParse(
                params['highlightStartSurah'] ?? '',
              );
              final highlightStartAyah = int.tryParse(
                params['highlightStartAyah'] ?? '',
              );
              final highlightEndSurah = int.tryParse(
                params['highlightEndSurah'] ?? '',
              );
              final highlightEndAyah = int.tryParse(
                params['highlightEndAyah'] ?? '',
              );

              return ReaderScreen(
                mode: mode,
                page: page,
                targetSurah: targetSurah,
                targetAyah: targetAyah,
                highlightStartSurah: highlightStartSurah,
                highlightStartAyah: highlightStartAyah,
                highlightEndSurah: highlightEndSurah,
                highlightEndAyah: highlightEndAyah,
              );
            },
          ),
          GoRoute(
            path: '/bookmarks',
            builder: (context, state) => const BookmarksScreen(),
          ),
          GoRoute(
            path: '/notes',
            builder: (context, state) => const NotesScreen(),
          ),
          GoRoute(
            path: '/plan',
            builder: (context, state) => const PlanScreen(),
          ),
          GoRoute(
            path: '/today',
            builder: (context, state) => const TodayScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/about',
            builder: (context, state) => const AboutScreen(),
          ),
        ],
      ),
    ],
  );
});
