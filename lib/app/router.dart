import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/about_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/companion_chain_screen.dart';
import '../data/services/companion/companion_models.dart';
import '../screens/learn_screen.dart';
import '../screens/my_quran_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/plan_screen.dart';
import '../screens/quran_radio_screen.dart';
import '../screens/reader_screen.dart';
import '../screens/reciters_screen.dart';
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
            path: '/learn',
            builder: (context, state) => const LearnScreen(),
          ),
          GoRoute(
            path: '/my-quran',
            builder: (context, state) => const MyQuranScreen(),
          ),
          GoRoute(
            path: '/quran-radio',
            builder: (context, state) => const QuranRadioScreen(),
          ),
          GoRoute(
            path: '/reciters',
            builder: (context, state) => const RecitersScreen(),
          ),
          GoRoute(
            path: '/today',
            builder: (context, state) => const TodayScreen(),
          ),
          GoRoute(
            path: '/companion/chain',
            builder: (context, state) {
              final unitId = int.tryParse(
                state.uri.queryParameters['unitId'] ?? '',
              );
              final launchMode = CompanionLaunchMode.fromCode(
                state.uri.queryParameters['mode'],
              );
              if (unitId == null || unitId <= 0) {
                return const Scaffold(
                  body: SafeArea(
                    child: Center(
                      child: Text('Missing or invalid unitId'),
                    ),
                  ),
                );
              }
              return CompanionChainScreen(
                unitId: unitId,
                launchMode: launchMode,
              );
            },
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
