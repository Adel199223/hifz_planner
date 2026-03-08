import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/screens/learn_screen.dart';

import '../helpers/pump_until_found.dart';

void main() {
  testWidgets(
    'learn practice buttons fall back to Today when no direct session exists',
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

      final router = _buildLearnRouter();
      addTearDown(router.dispose);

      await _pumpLearn(tester, container, router);

      expect(find.byKey(const ValueKey('learn_practice_card')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('learn_practice_fallback_note')),
        findsOneWidget,
      );

      await _tapVisible(
        tester,
        find.byKey(const ValueKey('learn_practice_new_button')),
      );

      expect(find.text('Today route'), findsOneWidget);
    },
  );

  testWidgets(
    'learn review practice button opens direct review session when due work exists',
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
      final todayDay = DateTime.now().toLocal();
      final dayIndex = _localDayIndex(todayDay);

      final reviewUnitId = await _insertUnit(
        db,
        unitKey: 'learn-review-$dayIndex',
        createdAtDay: dayIndex,
      );
      await db
          .into(db.scheduleState)
          .insert(
            ScheduleStateCompanion.insert(
              unitId: Value(reviewUnitId),
              ef: 2.5,
              reps: 1,
              intervalDays: 1,
              dueDay: dayIndex - 1,
              lapseCount: 0,
            ),
          );

      final router = _buildLearnRouter();
      addTearDown(router.dispose);

      await _pumpLearn(tester, container, router);

      await _tapVisible(
        tester,
        find.byKey(const ValueKey('learn_practice_review_button')),
      );

      expect(
        find.text('Companion route unitId=$reviewUnitId mode=review'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'learn delayed check button opens direct delayed check when due work exists',
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
      final dayIndex = _localDayIndex(DateTime.now().toLocal());

      final unitId = await _insertUnit(
        db,
        unitKey: 'learn-stage4-$dayIndex',
        createdAtDay: dayIndex,
      );
      await db
          .into(db.companionLifecycleState)
          .insert(
            CompanionLifecycleStateCompanion.insert(
              unitId: Value(unitId),
              lifecycleTier: const Value('ready'),
              stage4Status: const Value('pending'),
              stage4NextDayDueDay: Value(dayIndex),
              stage4UnresolvedTargetsJson: const Value('[0]'),
              updatedAtDay: dayIndex,
              updatedAtSeconds: 100,
            ),
          );

      final router = _buildLearnRouter();
      addTearDown(router.dispose);

      await _pumpLearn(tester, container, router);

      await _tapVisible(
        tester,
        find.byKey(const ValueKey('learn_practice_stage4_button')),
      );

      expect(
        find.text('Companion route unitId=$unitId mode=stage4'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'learn new practice button opens direct new session when a new unit is already planned',
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
      final dayIndex = _localDayIndex(DateTime.now().toLocal());

      final unitId = await _insertUnit(
        db,
        unitKey: 'learn-new-$dayIndex',
        createdAtDay: dayIndex,
        kind: 'page_segment',
      );
      await db
          .into(db.scheduleState)
          .insert(
            ScheduleStateCompanion.insert(
              unitId: Value(unitId),
              ef: 2.5,
              reps: 0,
              intervalDays: 0,
              dueDay: dayIndex,
              lapseCount: 0,
            ),
          );

      final router = _buildLearnRouter();
      addTearDown(router.dispose);

      await _pumpLearn(tester, container, router);

      await _tapVisible(
        tester,
        find.byKey(const ValueKey('learn_practice_new_button')),
      );

      expect(
        find.text('Companion route unitId=$unitId mode=new'),
        findsOneWidget,
      );
    },
  );
}

void _registerTestCleanup(WidgetTester tester) {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}

Future<void> _pumpLearn(
  WidgetTester tester,
  ProviderContainer container,
  GoRouter router,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await pumpUntilFound(tester, find.byKey(const ValueKey('learn_screen_root')));
  await tester.pumpAndSettle();
}

GoRouter _buildLearnRouter() {
  return GoRouter(
    initialLocation: '/learn',
    routes: [
      GoRoute(
        path: '/learn',
        builder: (_, __) => const Scaffold(body: LearnScreen()),
      ),
      GoRoute(
        path: '/today',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('Today route'))),
      ),
      GoRoute(
        path: '/plan',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('Plan route'))),
      ),
      GoRoute(
        path: '/companion/chain',
        builder: (_, state) {
          final unitId = state.uri.queryParameters['unitId'] ?? 'missing';
          final mode = state.uri.queryParameters['mode'] ?? 'missing';
          return Scaffold(
            body: Center(
              child: Text('Companion route unitId=$unitId mode=$mode'),
            ),
          );
        },
      ),
    ],
  );
}

Future<int> _insertUnit(
  AppDatabase db, {
  required String unitKey,
  required int createdAtDay,
  String kind = 'ayah_range',
}) {
  return db
      .into(db.memUnit)
      .insert(
        MemUnitCompanion.insert(
          kind: kind,
          pageMadina: const Value(1),
          startSurah: const Value(1),
          startAyah: const Value(1),
          endSurah: const Value(1),
          endAyah: const Value(1),
          unitKey: unitKey,
          createdAtDay: createdAtDay,
          updatedAtDay: createdAtDay,
        ),
      );
}

int _localDayIndex(DateTime dateTime) {
  final local = DateTime(dateTime.year, dateTime.month, dateTime.day);
  return local.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
