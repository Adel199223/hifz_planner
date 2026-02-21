import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/data/repositories/settings_repo.dart';
import 'package:hifz_planner/data/time/local_day_time.dart';
import 'package:hifz_planner/screens/today_screen.dart';

import '../helpers/pump_until_found.dart';

void main() {
  testWidgets('loads plan snapshot and renders both sections', (tester) async {
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

    await _seedAyahs(db, withPageMetadata: true);
    await _configurePlannerSettings(
      db,
      requirePageMetadata: false,
      maxNewUnitsPerDay: 2,
    );
    final dueUnitId = await _insertDueReviewUnit(db, todayDay: todayDay);

    await _pumpToday(tester, container);

    expect(find.byKey(const ValueKey('today_screen_root')), findsOneWidget);
    expect(find.byKey(const ValueKey('today_reviews_section')), findsOneWidget);
    expect(find.byKey(const ValueKey('today_new_section')), findsOneWidget);
    expect(find.byKey(ValueKey('today_review_row_$dueUnitId')), findsOneWidget);
    expect(find.textContaining('page_segment'), findsWidgets);
  });

  testWidgets('grading planned review writes review_log and updates schedule',
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

    await _seedAyahs(db, withPageMetadata: true);
    await _configurePlannerSettings(
      db,
      requirePageMetadata: false,
      maxNewUnitsPerDay: 2,
    );
    final dueUnitId = await _insertDueReviewUnit(db, todayDay: todayDay);

    await _pumpToday(tester, container);
    final gradeButton = find.byKey(
      ValueKey('today_review_grade_${dueUnitId}_q5'),
    );
    await pumpUntilFound(tester, gradeButton);

    await tester.tap(gradeButton);
    await tester.pumpAndSettle();

    final logs = await (db.select(db.reviewLog)
          ..where((tbl) => tbl.unitId.equals(dueUnitId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
        .get();
    expect(logs.length, 1);
    expect(logs.single.tsDay, todayDay);
    expect(logs.single.tsSeconds, isNotNull);
    expect(logs.single.gradeQ, 5);
    expect(logs.single.durationSeconds, isNull);
    expect(logs.single.mistakesCount, isNull);

    final schedule = await (db.select(db.scheduleState)
          ..where((tbl) => tbl.unitId.equals(dueUnitId)))
        .getSingle();
    expect(schedule.lastGradeQ, 5);
    expect(schedule.lastReviewDay, todayDay);
    expect(schedule.dueDay, todayDay + 1);

    expect(find.byKey(ValueKey('today_review_row_$dueUnitId')), findsNothing);
  });

  testWidgets('self-check grade for new unit writes review_log and schedules',
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

    await _seedAyahs(db, withPageMetadata: true);
    await _configurePlannerSettings(
      db,
      requirePageMetadata: false,
      maxNewUnitsPerDay: 2,
    );

    await _pumpToday(tester, container);

    final plannedNewUnits = await _fetchPlannedNewUnits(db, todayDay: todayDay);
    expect(plannedNewUnits, isNotEmpty);
    final unitId = plannedNewUnits.first.id;
    final gradeButton = find.byKey(ValueKey('today_new_grade_${unitId}_q4'));
    await pumpUntilFound(tester, gradeButton);

    await tester.tap(gradeButton);
    await tester.pumpAndSettle();

    final logs = await (db.select(db.reviewLog)
          ..where((tbl) => tbl.unitId.equals(unitId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
        .get();
    expect(logs.length, 1);
    expect(logs.single.tsDay, todayDay);
    expect(logs.single.tsSeconds, isNotNull);
    expect(logs.single.gradeQ, 4);
    expect(logs.single.durationSeconds, isNull);
    expect(logs.single.mistakesCount, isNull);

    final schedule = await (db.select(db.scheduleState)
          ..where((tbl) => tbl.unitId.equals(unitId)))
        .getSingle();
    expect(schedule.lastGradeQ, 4);
    expect(schedule.lastReviewDay, todayDay);
    expect(schedule.dueDay, todayDay + 1);

    expect(find.byKey(ValueKey('today_new_row_$unitId')), findsNothing);
  });

  testWidgets('open in reader navigates with page mode and highlight range',
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

    await _seedAyahs(db, withPageMetadata: true);
    await _configurePlannerSettings(
      db,
      requirePageMetadata: false,
      maxNewUnitsPerDay: 1,
      maxNewPagesPerDay: 1,
    );

    final router = _buildTodayRouter();
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
      find.byKey(const ValueKey('today_new_section')),
    );

    final plannedNewUnits = await _fetchPlannedNewUnits(db, todayDay: todayDay);
    expect(plannedNewUnits, isNotEmpty);
    final unit = plannedNewUnits.first;
    final openButton = find.byKey(ValueKey('today_open_reader_${unit.id}'));
    await pumpUntilFound(tester, openButton);
    await tester.tap(openButton);

    final expectedRouteText = 'Reader route mode=page page=${unit.pageMadina} '
        'target=${unit.startSurah}:${unit.startAyah} '
        'highlight=${unit.startSurah}:${unit.startAyah}-${unit.endSurah}:${unit.endAyah}';
    await pumpUntilFound(tester, find.text(expectedRouteText));

    expect(find.text(expectedRouteText), findsOneWidget);
  });

  testWidgets('open in reader button is disabled when page metadata is missing',
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

    await _seedAyahs(db, withPageMetadata: false);
    await _configurePlannerSettings(
      db,
      requirePageMetadata: false,
      maxNewUnitsPerDay: 1,
      maxNewPagesPerDay: 1,
    );

    await _pumpToday(tester, container);

    final plannedNewUnits = await _fetchPlannedNewUnits(db, todayDay: todayDay);
    final unit = plannedNewUnits.firstWhere((row) => row.pageMadina == null);
    final openButtonFinder =
        find.byKey(ValueKey('today_open_reader_${unit.id}'));
    await pumpUntilFound(tester, openButtonFinder);

    final openButton = tester.widget<OutlinedButton>(openButtonFinder);
    expect(openButton.onPressed, isNull);
    expect(
      find.text('Page metadata required to open in Reader.'),
      findsWidgets,
    );
  });
}

void _registerTestCleanup(WidgetTester tester) {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}

Future<void> _seedAyahs(
  AppDatabase db, {
  required bool withPageMetadata,
}) async {
  final rows = <AyahCompanion>[];
  for (var ayah = 1; ayah <= 24; ayah++) {
    final page = ((ayah - 1) ~/ 6) + 1;
    rows.add(
      AyahCompanion.insert(
        surah: 1,
        ayah: ayah,
        textUthmani: 'ayah-$ayah',
        pageMadina: withPageMetadata ? Value(page) : const Value.absent(),
      ),
    );
  }
  await db.batch((batch) {
    batch.insertAll(db.ayah, rows);
  });
}

Future<void> _configurePlannerSettings(
  AppDatabase db, {
  required bool requirePageMetadata,
  required int maxNewUnitsPerDay,
  int maxNewPagesPerDay = 2,
}) async {
  await SettingsRepo(db).updateSettings(
    profile: 'standard',
    forceRevisionOnly: 0,
    dailyMinutesDefault: 60,
    maxNewPagesPerDay: maxNewPagesPerDay,
    maxNewUnitsPerDay: maxNewUnitsPerDay,
    avgNewMinutesPerAyah: 1.0,
    avgReviewMinutesPerAyah: 1.0,
    requirePageMetadata: requirePageMetadata ? 1 : 0,
  );
}

Future<int> _insertDueReviewUnit(
  AppDatabase db, {
  required int todayDay,
}) async {
  final unitId = await db.into(db.memUnit).insert(
        MemUnitCompanion.insert(
          kind: 'ayah_range',
          pageMadina: const Value(1),
          startSurah: const Value(1),
          startAyah: const Value(1),
          endSurah: const Value(1),
          endAyah: const Value(1),
          unitKey: 'due-review-$todayDay',
          createdAtDay: todayDay,
          updatedAtDay: todayDay,
        ),
      );

  await db.into(db.scheduleState).insert(
        ScheduleStateCompanion.insert(
          unitId: Value(unitId),
          ef: 2.5,
          reps: 0,
          intervalDays: 0,
          dueDay: todayDay - 1,
          lapseCount: 0,
        ),
      );
  return unitId;
}

Future<List<MemUnitData>> _fetchPlannedNewUnits(
  AppDatabase db, {
  required int todayDay,
}) {
  return (db.select(db.memUnit)
        ..where(
          (tbl) =>
              tbl.kind.equals('page_segment') &
              tbl.createdAtDay.equals(todayDay),
        )
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
      .get();
}

Future<void> _pumpToday(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: TodayScreen()),
      ),
    ),
  );
  await tester.pump();
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('today_reviews_section')),
  );
}

GoRouter _buildTodayRouter() {
  return GoRouter(
    initialLocation: '/today',
    routes: [
      GoRoute(
        path: '/today',
        builder: (_, __) => const Scaffold(body: TodayScreen()),
      ),
      GoRoute(
        path: '/reader',
        builder: (_, state) {
          final params = state.uri.queryParameters;
          final mode = params['mode'] ?? 'none';
          final page = params['page'] ?? 'none';
          final targetSurah = params['targetSurah'] ?? 'none';
          final targetAyah = params['targetAyah'] ?? 'none';
          final highlightStartSurah = params['highlightStartSurah'] ?? 'none';
          final highlightStartAyah = params['highlightStartAyah'] ?? 'none';
          final highlightEndSurah = params['highlightEndSurah'] ?? 'none';
          final highlightEndAyah = params['highlightEndAyah'] ?? 'none';

          return Scaffold(
            body: Center(
              child: Text(
                'Reader route mode=$mode page=$page '
                'target=$targetSurah:$targetAyah '
                'highlight=$highlightStartSurah:$highlightStartAyah-'
                '$highlightEndSurah:$highlightEndAyah',
              ),
            ),
          );
        },
      ),
    ],
  );
}
