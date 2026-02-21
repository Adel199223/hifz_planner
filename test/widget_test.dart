import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/data/repositories/bookmark_repo.dart';
import 'package:hifz_planner/main.dart';
import 'package:hifz_planner/screens/bookmarks_screen.dart';

import 'helpers/pump_until_found.dart';

void main() {
  testWidgets('loads Today screen with NavigationRail', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        bookmarkRepoProvider.overrideWith(
          (ref) => _FakeBookmarkRepo(ref.read(appDatabaseProvider)),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HifzPlannerApp(),
      ),
    );
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('today_screen_root')),
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byKey(const ValueKey('today_screen_root')), findsOneWidget);
    expect(find.text('Planned Reviews'), findsOneWidget);
  });

  testWidgets('navigates to Bookmarks from rail', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HifzPlannerApp(),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(BookmarksScreen), findsOneWidget);
    expect(find.text('No bookmarks yet.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.today_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

class _FakeBookmarkRepo extends BookmarkRepo {
  _FakeBookmarkRepo(super.db);

  @override
  Stream<List<BookmarkData>> watchBookmarks() {
    return Stream.value(const <BookmarkData>[]);
  }
}
