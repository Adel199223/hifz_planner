import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/screens/bookmarks_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('shows empty state when there are no bookmarks', (tester) async {
    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No bookmarks yet.'), findsOneWidget);
  });

  testWidgets('go to verse navigates to reader with query params', (tester) async {
    await db.into(db.bookmark).insert(
          BookmarkCompanion.insert(
            surah: 2,
            ayah: 255,
          ),
        );

    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Surah 2, Ayah 255'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bookmark_go_2:255')));
    await tester.pumpAndSettle();

    expect(find.text('Reader target 2:255'), findsOneWidget);
  });
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/bookmarks',
    routes: [
      GoRoute(
        path: '/bookmarks',
        builder: (_, __) => const Scaffold(body: BookmarksScreen()),
      ),
      GoRoute(
        path: '/reader',
        builder: (context, state) {
          final surah = state.uri.queryParameters['surah'] ?? '';
          final ayah = state.uri.queryParameters['ayah'] ?? '';
          return Scaffold(
            body: Center(
              child: Text('Reader target $surah:$ayah'),
            ),
          );
        },
      ),
    ],
  );
}
