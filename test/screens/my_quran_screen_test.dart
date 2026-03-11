import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/data/repositories/progress_repo.dart';
import 'package:hifz_planner/data/time/local_day_time.dart';
import 'package:hifz_planner/screens/my_quran_screen.dart';

import '../helpers/pump_until_found.dart';

void main() {
  testWidgets('renders My Quran dashboard snapshot and previews',
      (tester) async {
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
    _registerTestCleanup(tester);
    final todayDay = localDayIndex(DateTime.now().toLocal());

    await _seedOverviewData(db, todayDay: todayDay);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: MyQuranScreen()),
        ),
      ),
    );
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('my_quran_stats_section')),
    );

    expect(find.byKey(const ValueKey('my_quran_resume_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('my_quran_stat_units')), findsOneWidget);
    expect(find.byKey(const ValueKey('my_quran_stat_due_reviews')),
        findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('my_quran_stat_units')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('my_quran_stat_due_reviews')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('my_quran_stat_stage4_due')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('my_quran_bookmark_1:2')), findsOneWidget);
    expect(find.byKey(const ValueKey('my_quran_note_1')), findsOneWidget);
  });

  testWidgets('resume and quick actions navigate to existing routes',
      (tester) async {
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
    _registerTestCleanup(tester);
    final todayDay = localDayIndex(DateTime.now().toLocal());

    await _seedOverviewData(db, todayDay: todayDay);
    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('my_quran_stats_section')),
    );

    await tester.tap(find.byKey(const ValueKey('my_quran_open_reader_button')));
    await tester.pumpAndSettle();
    expect(find.text('Reader route target=2:1 page=10'), findsOneWidget);

    router.go('/my-quran');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('my_quran_open_today_button')));
    await tester.pumpAndSettle();
    expect(find.text('Today route'), findsOneWidget);
  });
}

void _registerTestCleanup(WidgetTester tester) {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}

Future<void> _seedOverviewData(
  AppDatabase db, {
  required int todayDay,
}) async {
  await db.batch((batch) {
    batch.insertAll(
      db.ayah,
      [
        AyahCompanion.insert(
          surah: 1,
          ayah: 1,
          textUthmani: 'ayah-1',
          pageMadina: const Value(1),
        ),
        AyahCompanion.insert(
          surah: 1,
          ayah: 2,
          textUthmani: 'ayah-2',
          pageMadina: const Value(2),
        ),
        AyahCompanion.insert(
          surah: 2,
          ayah: 1,
          textUthmani: 'ayah-3',
          pageMadina: const Value(10),
        ),
      ],
    );
  });

  int? firstUnitId;
  for (final spec in <({String key, int dueDay})>[
    (key: 'unit-a', dueDay: todayDay - 1),
    (key: 'unit-b', dueDay: todayDay),
    (key: 'unit-c', dueDay: todayDay + 3),
  ]) {
    final unitId = await db.into(db.memUnit).insert(
          MemUnitCompanion.insert(
            kind: 'ayah_range',
            unitKey: spec.key,
            startSurah: const Value(1),
            startAyah: const Value(1),
            endSurah: const Value(1),
            endAyah: const Value(1),
            createdAtDay: todayDay,
            updatedAtDay: todayDay,
          ),
        );
    firstUnitId ??= unitId;
    await db.into(db.scheduleState).insert(
          ScheduleStateCompanion.insert(
            unitId: Value(unitId),
            ef: 2.5,
            reps: 0,
            intervalDays: 0,
            dueDay: spec.dueDay,
            lapseCount: 0,
          ),
        );
  }

  await db.into(db.bookmark).insert(
        BookmarkCompanion.insert(
          surah: 1,
          ayah: 2,
        ),
      );
  await db.into(db.bookmark).insert(
        BookmarkCompanion.insert(
          surah: 1,
          ayah: 1,
        ),
      );

  await db.into(db.note).insert(
        NoteCompanion.insert(
          surah: 1,
          ayah: 2,
          title: const Value('Reflection'),
          body: 'Keep this verse strong.',
        ),
      );

  await db.into(db.companionLifecycleState).insert(
        CompanionLifecycleStateCompanion.insert(
          unitId: Value(firstUnitId!),
          lifecycleTier: const Value('ready'),
          stage4Status: const Value('pending'),
          stage4NextDayDueDay: Value(todayDay),
          updatedAtDay: todayDay,
          updatedAtSeconds: 100,
        ),
      );

  await ProgressRepo(db).updateCursor(
    nextSurah: 2,
    nextAyah: 1,
    updatedAtDay: todayDay,
  );
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/my-quran',
    routes: [
      GoRoute(
        path: '/my-quran',
        builder: (_, __) => const Scaffold(body: MyQuranScreen()),
      ),
      GoRoute(
        path: '/reader',
        builder: (_, state) {
          final targetSurah =
              state.uri.queryParameters['targetSurah'] ?? 'none';
          final targetAyah = state.uri.queryParameters['targetAyah'] ?? 'none';
          final page = state.uri.queryParameters['page'] ?? 'none';
          return Scaffold(
            body: Center(
              child: Text(
                  'Reader route target=$targetSurah:$targetAyah page=$page'),
            ),
          );
        },
      ),
      GoRoute(
        path: '/today',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Today route')),
        ),
      ),
      GoRoute(
        path: '/plan',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Plan route')),
        ),
      ),
      GoRoute(
        path: '/bookmarks',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Bookmarks route')),
        ),
      ),
      GoRoute(
        path: '/notes',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Notes route')),
        ),
      ),
    ],
  );
}
