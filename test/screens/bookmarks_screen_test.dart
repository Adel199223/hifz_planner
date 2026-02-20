import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/data/repositories/bookmark_repo.dart';
import 'package:hifz_planner/screens/bookmarks_screen.dart';

import '../helpers/pump_until_found.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  testWidgets('shows empty state when there are no bookmarks', (tester) async {
    _registerTestCleanup(tester, db);
    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          bookmarkRepoProvider.overrideWithValue(_FakeBookmarkRepo(db)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpUntilFound(
      tester,
      find.text('No bookmarks yet.'),
    );

    expect(find.text('No bookmarks yet.'), findsOneWidget);
  });

  testWidgets('go to verse prefers page mode when page metadata exists', (
    tester,
  ) async {
    _registerTestCleanup(tester, db);
    await db.into(db.ayah).insert(
          AyahCompanion.insert(
            surah: 2,
            ayah: 255,
            textUthmani: 'Ayah',
            pageMadina: const Value(42),
          ),
        );

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
          bookmarkRepoProvider.overrideWithValue(_FakeBookmarkRepo(db)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpUntilFound(
      tester,
      find.text('Surah 2, Ayah 255'),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('bookmark_page_2:255')),
    );

    expect(find.text('Surah 2, Ayah 255'), findsOneWidget);
    expect(find.byKey(const ValueKey('bookmark_page_2:255')), findsOneWidget);
    expect(find.text('Page 42'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bookmark_go_2:255')));
    await pumpUntilFound(
      tester,
      find.text('Reader route mode=page page=42 target=2:255'),
    );

    expect(find.text('Reader route mode=page page=42 target=2:255'),
        findsOneWidget);
  });

  testWidgets('go to page navigates to page mode route', (tester) async {
    _registerTestCleanup(tester, db);
    await db.into(db.ayah).insert(
          AyahCompanion.insert(
            surah: 36,
            ayah: 58,
            textUthmani: 'Ayah',
            pageMadina: const Value(445),
          ),
        );
    await db.into(db.bookmark).insert(
          BookmarkCompanion.insert(
            surah: 36,
            ayah: 58,
          ),
        );

    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          bookmarkRepoProvider.overrideWithValue(_FakeBookmarkRepo(db)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('bookmark_go_page_36:58')),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('bookmark_page_36:58')),
    );

    await tester.tap(find.byKey(const ValueKey('bookmark_go_page_36:58')));
    await pumpUntilFound(
      tester,
      find.text('Reader route mode=page page=445 target=36:58'),
    );

    expect(find.text('Reader route mode=page page=445 target=36:58'),
        findsOneWidget);
  });

  testWidgets('missing page metadata falls back and disables go to page', (
    tester,
  ) async {
    _registerTestCleanup(tester, db);
    await db.into(db.ayah).insert(
          AyahCompanion.insert(
            surah: 3,
            ayah: 7,
            textUthmani: 'Ayah',
          ),
        );
    await db.into(db.bookmark).insert(
          BookmarkCompanion.insert(
            surah: 3,
            ayah: 7,
          ),
        );

    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          bookmarkRepoProvider.overrideWithValue(_FakeBookmarkRepo(db)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('bookmark_go_page_3:7')),
    );

    final goToPage = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('bookmark_go_page_3:7')),
    );
    expect(goToPage.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('bookmark_go_3:7')));
    await pumpUntilFound(
      tester,
      find.text('Reader route mode=none page=none target=3:7'),
    );

    expect(find.text('Reader route mode=none page=none target=3:7'),
        findsOneWidget);
  });
}

void _registerTestCleanup(WidgetTester tester, AppDatabase db) {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await db.close();
    await tester.pump(const Duration(milliseconds: 1));
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
          final params = state.uri.queryParameters;
          final mode = params['mode'] ?? 'none';
          final page = params['page'] ?? 'none';
          final surah = params['targetSurah'] ?? '';
          final ayah = params['targetAyah'] ?? '';
          return Scaffold(
            body: Center(
              child: Text(
                'Reader route mode=$mode page=$page target=$surah:$ayah',
              ),
            ),
          );
        },
      ),
    ],
  );
}

class _FakeBookmarkRepo extends BookmarkRepo {
  _FakeBookmarkRepo(super.db);

  @override
  Stream<List<BookmarkData>> watchBookmarks() {
    return Stream.fromFuture(getBookmarks());
  }
}
