import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/database/database_storage_status.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/data/repositories/settings_repo.dart';
import 'package:hifz_planner/data/services/scheduling/scheduling_preferences_codec.dart';
import 'package:hifz_planner/data/time/local_day_time.dart';
import 'package:hifz_planner/screens/plan_screen.dart';
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
    expect(
        find.byKey(const ValueKey('today_sessions_section')), findsOneWidget);
    expect(find.byKey(ValueKey('today_review_row_$dueUnitId')), findsOneWidget);
    expect(
      find.byKey(ValueKey('today_open_companion_review_$dueUnitId')),
      findsOneWidget,
    );
    expect(find.textContaining('page_segment'), findsWidgets);
  });

  testWidgets('guided cards render above the queue and summary',
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
    );
    final dueUnitId = await _insertDueReviewUnit(db, todayDay: todayDay);
    await _insertStage4DueLifecycle(
      db,
      unitId: dueUnitId,
      todayDay: todayDay,
    );

    await _pumpToday(tester, container);

    final nextStep = find.byKey(const ValueKey('today_next_step_card'));
    final pathMode = find.byKey(const ValueKey('today_path_mode_card'));
    final stage4 = find.byKey(const ValueKey('today_stage4_section'));
    final reviews = find.byKey(const ValueKey('today_reviews_section'));
    final summary = find.byKey(const ValueKey('today_summary_section'));

    expect(nextStep, findsOneWidget);
    expect(pathMode, findsOneWidget);
    expect(summary, findsOneWidget);
    expect(
      tester.getTopLeft(nextStep).dy,
      lessThan(tester.getTopLeft(pathMode).dy),
    );
    expect(
      tester.getTopLeft(pathMode).dy,
      lessThan(tester.getTopLeft(stage4).dy),
    );
    expect(
      tester.getTopLeft(stage4).dy,
      lessThan(tester.getTopLeft(reviews).dy),
    );
    expect(
      tester.getTopLeft(reviews).dy,
      lessThan(tester.getTopLeft(summary).dy),
    );
    expect(
        find.byKey(const ValueKey('today_new_state_message')), findsOneWidget);
    expect(find.textContaining('Stage-4'), findsWidgets);
  });

  testWidgets('next step updates after grading the current review',
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
    );
    final dueUnitId = await _insertDueReviewUnit(db, todayDay: todayDay);

    await _pumpToday(tester, container);

    final plannedNewUnits = await _fetchPlannedNewUnits(db, todayDay: todayDay);
    expect(plannedNewUnits, isNotEmpty);
    expect(
      find.byKey(const ValueKey('today_next_step_button_dueReview')),
      findsOneWidget,
    );

    final gradeButton =
        find.byKey(ValueKey('today_review_grade_${dueUnitId}_q5'));
    await pumpUntilFound(tester, gradeButton);
    await _tapVisible(tester, gradeButton);

    expect(
      find.byKey(const ValueKey('today_next_step_button_newUnit')),
      findsOneWidget,
    );
  });

  testWidgets('next step button opens stage4 companion route', (tester) async {
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
    );
    final dueUnitId = await _insertDueReviewUnit(db, todayDay: todayDay);
    await _insertStage4DueLifecycle(
      db,
      unitId: dueUnitId,
      todayDay: todayDay,
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
      find.byKey(const ValueKey('today_next_step_button_stage4Due')),
    );

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('today_next_step_button_stage4Due')),
    );

    expect(
      find.text('Companion route unitId=$dueUnitId mode=stage4'),
      findsOneWidget,
    );
  });

  testWidgets('next step falls back to My Quran when nothing is queued',
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
      maxNewUnitsPerDay: 0,
      maxNewPagesPerDay: 0,
    );
    await _insertMemUnitOnly(
      db,
      unitKey: 'resume-only-unit',
      todayDay: todayDay,
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
      find.byKey(const ValueKey('today_next_step_button_resume')),
    );

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('today_next_step_button_resume')),
    );

    expect(find.text('My Quran route'), findsOneWidget);
  });

  testWidgets('zero-unit Today shows guided setup and hides normal queue cards',
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

    await _seedAyahs(db, withPageMetadata: true);
    await _configurePlannerSettings(
      db,
      requirePageMetadata: false,
      maxNewUnitsPerDay: 1,
      maxNewPagesPerDay: 1,
    );

    await _pumpToday(tester, container);

    expect(find.byKey(const ValueKey('today_guided_setup_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('today_next_step_card')), findsNothing);
    expect(find.byKey(const ValueKey('today_path_mode_card')), findsNothing);
    expect(find.byKey(const ValueKey('today_stage4_section')), findsNothing);
    expect(find.byKey(const ValueKey('today_reviews_section')), findsNothing);
    expect(find.byKey(const ValueKey('today_new_section')), findsNothing);
    expect(find.byKey(const ValueKey('today_summary_section')), findsNothing);
    expect(find.byKey(const ValueKey('today_sessions_section')), findsNothing);
  });

  testWidgets('grade buttons use plain-language labels and stable q keys',
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
    );
    final dueUnitId = await _insertDueReviewUnit(db, todayDay: todayDay);

    await _pumpToday(tester, container);

    final q5Button = find.byKey(ValueKey('today_review_grade_${dueUnitId}_q5'));
    final q4Button = find.byKey(ValueKey('today_review_grade_${dueUnitId}_q4'));
    final q2Button = find.byKey(ValueKey('today_review_grade_${dueUnitId}_q2'));
    final q0Button = find.byKey(ValueKey('today_review_grade_${dueUnitId}_q0'));

    expect(
      find.descendant(of: q5Button, matching: find.text('Clean pass')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: q4Button, matching: find.text('Hesitant pass')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: q2Button, matching: find.text('Needed help')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: q0Button, matching: find.text('Wrong / confused')),
      findsOneWidget,
    );
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

    await _tapVisible(tester, gradeButton);

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

    await _tapVisible(tester, gradeButton);

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
    await _tapVisible(tester, openButton);

    final expectedRouteText = 'Reader route mode=page page=${unit.pageMadina} '
        'target=${unit.startSurah}:${unit.startAyah} '
        'highlight=${unit.startSurah}:${unit.startAyah}-${unit.endSurah}:${unit.endAyah}';
    await pumpUntilFound(tester, find.text(expectedRouteText));

    expect(find.text(expectedRouteText), findsOneWidget);
  });

  testWidgets('open companion review action navigates with mode=review',
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
    );
    final dueUnitId = await _insertDueReviewUnit(db, todayDay: todayDay);

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
      find.byKey(const ValueKey('today_reviews_section')),
    );

    final companionButton =
        find.byKey(ValueKey('today_open_companion_review_$dueUnitId'));
    await pumpUntilFound(tester, companionButton);
    await _tapVisible(tester, companionButton);

    expect(
      find.text('Companion route unitId=$dueUnitId mode=review'),
      findsOneWidget,
    );
  });

  testWidgets('planned review rows show lifecycle badge from planner data',
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
    );
    final dueUnitId = await _insertDueReviewUnit(db, todayDay: todayDay);
    await _insertLifecycleState(
      db,
      unitId: dueUnitId,
      lifecycleTier: 'stable',
      todayDay: todayDay,
    );

    await _pumpToday(tester, container);

    expect(
      find.byKey(ValueKey('today_review_lifecycle_badge_$dueUnitId')),
      findsOneWidget,
    );
    expect(find.text('Stable'), findsOneWidget);
  });

  testWidgets(
      'today fallback grading promotes stable lifecycle units and shows lifecycle message',
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
    );
    final dueUnitId = await _insertDueReviewUnit(db, todayDay: todayDay);
    await db.into(db.companionLifecycleState).insert(
          CompanionLifecycleStateCompanion.insert(
            unitId: Value(dueUnitId),
            lifecycleTier: const Value('stable'),
            stage4Status: const Value('passed'),
            updatedAtDay: todayDay,
            updatedAtSeconds: 100,
          ),
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
      find.byKey(const ValueKey('today_reviews_section')),
    );

    final gradeButton =
        find.byKey(ValueKey('today_review_grade_${dueUnitId}_q5'));
    await pumpUntilFound(tester, gradeButton);
    await _tapVisible(tester, gradeButton);

    expect(
      find.text('Grade saved. This unit moved to maintained.'),
      findsOneWidget,
    );

    final lifecycle = await (db.select(db.companionLifecycleState)
          ..where((tbl) => tbl.unitId.equals(dueUnitId)))
        .getSingle();
    expect(lifecycle.lifecycleTier, 'maintained');
    expect(lifecycle.stage4Status, 'passed');
  });

  testWidgets('stage-4 due item opens companion with mode=stage4',
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
    );
    final dueUnitId = await _insertDueReviewUnit(db, todayDay: todayDay);
    await _insertStage4DueLifecycle(
      db,
      unitId: dueUnitId,
      todayDay: todayDay,
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
      find.byKey(const ValueKey('today_stage4_section')),
    );

    final stage4Button =
        find.byKey(ValueKey('today_open_companion_stage4_$dueUnitId'));
    await pumpUntilFound(tester, stage4Button);
    await _tapVisible(tester, stage4Button);

    expect(
      find.text('Companion route unitId=$dueUnitId mode=stage4'),
      findsOneWidget,
    );
  });

  testWidgets('mandatory stage-4 due blocks new until override is confirmed',
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
    final dueUnitId = await _insertDueReviewUnit(db, todayDay: todayDay);
    await _insertStage4DueLifecycle(
      db,
      unitId: dueUnitId,
      todayDay: todayDay,
    );

    await _pumpToday(tester, container);
    expect(find.byKey(const ValueKey('today_stage4_section')), findsOneWidget);
    expect(find.byKey(const ValueKey('today_stage4_override_new_button')),
        findsOneWidget);

    final beforeNewUnits = await _fetchPlannedNewUnits(db, todayDay: todayDay);
    expect(beforeNewUnits, isEmpty);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('today_stage4_override_new_button')),
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('today_stage4_override_confirm')),
    );

    final lifecycle = await (db.select(db.companionLifecycleState)
          ..where((tbl) => tbl.unitId.equals(dueUnitId)))
        .getSingle();
    expect(lifecycle.lastNewOverrideDay, todayDay);
    expect(lifecycle.newOverrideCount, 1);

    final afterNewUnits = await _fetchPlannedNewUnits(db, todayDay: todayDay);
    expect(afterNewUnits, isNotEmpty);
  });

  testWidgets('open companion new action navigates with mode=new',
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

    final unitId = plannedNewUnits.first.id;
    final companionButton =
        find.byKey(ValueKey('today_open_companion_new_$unitId'));
    await pumpUntilFound(tester, companionButton);
    await _tapVisible(tester, companionButton);

    expect(
      find.text('Companion route unitId=$unitId mode=new'),
      findsOneWidget,
    );
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

  testWidgets(
      'guided setup creates one production memorization unit and offers companion',
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
      maxNewUnitsPerDay: 0,
      maxNewPagesPerDay: 0,
    );

    await _pumpToday(tester, container);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('today_guided_setup_button')),
    );

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('today_guided_setup_button')),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('today_open_companion_after_setup')),
    );

    final createdUnits = await _fetchPlannedNewUnits(db, todayDay: todayDay);
    expect(createdUnits.length, 1);

    final createdUnit = createdUnits.single;
    expect(createdUnit.unitKey, isNot(startsWith('debug_seed:')));
    expect(find.byKey(const ValueKey('today_open_companion_after_setup')),
        findsOneWidget);
  });

  testWidgets(
      'revisiting Today after guided setup leaves the zero-unit onboarding state',
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

    await _seedAyahs(db, withPageMetadata: true);
    await _configurePlannerSettings(
      db,
      requirePageMetadata: false,
      maxNewUnitsPerDay: 0,
      maxNewPagesPerDay: 0,
    );

    await _pumpToday(tester, container);
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('today_guided_setup_button')),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('today_open_companion_after_setup')),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await _pumpToday(tester, container);

    expect(find.byKey(const ValueKey('today_guided_setup_card')), findsNothing);
    expect(find.byKey(const ValueKey('today_next_step_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('today_summary_section')), findsOneWidget);
  });

  testWidgets(
      'guided setup stays visible when only the first unit is still missing',
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
    await SettingsRepo(db).ensureZeroUnitStarterPlan(
      todayDayOverride: todayDay,
      updatedAtDay: todayDay,
    );
    await _configurePlannerSettings(
      db,
      requirePageMetadata: false,
      maxNewUnitsPerDay: 1,
      maxNewPagesPerDay: 1,
    );

    await _pumpToday(tester, container);

    expect(
      find.byKey(const ValueKey('today_guided_setup_card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('today_guided_setup_button')),
      findsOneWidget,
    );
  });

  testWidgets(
      'guided setup stays hidden for user-saved revision-only default-shaped plans',
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
    final repo = SettingsRepo(db);

    await _seedAyahs(db, withPageMetadata: true);
    await repo.updateSettings(
      profile: 'standard',
      forceRevisionOnly: 1,
      dailyMinutesDefault: 45,
      maxNewPagesPerDay: 1,
      maxNewUnitsPerDay: 8,
      avgNewMinutesPerAyah: 1.7,
      avgReviewMinutesPerAyah: 0.7,
      requirePageMetadata: 0,
      updatedAtDay: todayDay,
    );
    await repo.saveSchedulingPreferences(
      preferences: await repo.getSchedulingPreferences(
        todayDayOverride: todayDay,
      ),
      updatedAtDay: todayDay,
    );
    await _insertMemUnitOnly(
      db,
      unitKey: 'existing-starter-unit',
      todayDay: todayDay,
    );

    await _pumpToday(tester, container);

    expect(
      find.byKey(const ValueKey('today_guided_setup_card')),
      findsNothing,
    );
  });

  testWidgets('manual plan save clears stale guided setup repair state on Today',
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
    await SettingsRepo(db).updateSettings(
      profile: 'standard',
      forceRevisionOnly: 1,
      dailyMinutesDefault: 45,
      maxNewPagesPerDay: 1,
      maxNewUnitsPerDay: 8,
      avgNewMinutesPerAyah: 1.7,
      avgReviewMinutesPerAyah: 0.7,
      requirePageMetadata: 0,
      schedulingPrefsJson: _encodeUnmarkedPreferences(
        SchedulingPreferencesV1.defaults,
      ),
      updatedAtDay: todayDay,
    );
    final dueUnitId = await _insertDueReviewUnit(db, todayDay: todayDay);

    final readinessSubscription = container.listen(
      soloSetupReadinessProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(readinessSubscription.close);

    final staleReadiness = await container.read(soloSetupReadinessProvider.future);
    expect(staleReadiness.needsStarterPlanRepair, isTrue);

    await _pumpPlanWithContainer(tester, container);
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('plan_activate_button')),
    );

    await _pumpToday(tester, container);

    expect(
      find.byKey(const ValueKey('today_guided_setup_card')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('today_next_step_card')), findsOneWidget);
    expect(find.byKey(ValueKey('today_review_row_$dueUnitId')), findsOneWidget);
  });

  testWidgets(
      'legacy learners with units still keep the normal queue during repair setup',
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
    final repo = SettingsRepo(db);
    await repo.updateSettings(
      profile: 'standard',
      forceRevisionOnly: 1,
      dailyMinutesDefault: 45,
      maxNewPagesPerDay: 1,
      maxNewUnitsPerDay: 8,
      avgNewMinutesPerAyah: 1.7,
      avgReviewMinutesPerAyah: 0.7,
      requirePageMetadata: 0,
      updatedAtDay: todayDay,
    );
    await repo.updateSettings(
      schedulingPrefsJson: _encodeUnmarkedPreferences(
        await repo.getSchedulingPreferences(
          todayDayOverride: todayDay,
        ),
      ),
      updatedAtDay: todayDay,
    );
    await _insertDueReviewUnit(db, todayDay: todayDay);

    await _pumpToday(tester, container);

    expect(find.byKey(const ValueKey('today_guided_setup_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('today_next_step_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('today_reviews_section')), findsOneWidget);
  });

  testWidgets('guided setup stays visible when setup is still blocked',
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

    await _seedAyahs(db, withPageMetadata: true);
    await _configurePlannerSettings(
      db,
      requirePageMetadata: true,
      maxNewUnitsPerDay: 0,
      maxNewPagesPerDay: 0,
    );
    await (db.update(db.ayah)
          ..where((tbl) => tbl.surah.equals(1) & tbl.ayah.equals(1)))
        .write(const AyahCompanion(pageMadina: Value(null)));

    await _pumpToday(tester, container);

    expect(find.byKey(const ValueKey('today_guided_setup_card')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('today_guided_setup_button')),
      findsOneWidget,
    );
  });

  testWidgets('shows guided setup CTA and storage warning on transient web storage',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        databaseStorageStatusProvider.overrideWith(
          (ref) => Stream<DatabaseStorageStatus>.value(
            const DatabaseStorageStatus(
              kind: DatabaseStorageKind.inMemory,
              health: DatabaseStorageHealth.transient,
              isWeb: true,
              implementationName: 'inMemory',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    _registerTestCleanup(tester);

    await _pumpToday(tester, container);

    expect(find.byKey(const ValueKey('today_storage_warning')), findsOneWidget);
    expect(find.byKey(const ValueKey('today_guided_setup_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('today_guided_setup_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('today_next_step_card')), findsNothing);
    expect(find.byKey(const ValueKey('today_reviews_section')), findsNothing);
  });
}

String _encodeUnmarkedPreferences(SchedulingPreferencesV1 preferences) {
  final json = jsonDecode(preferences.encode()) as Map<String, dynamic>;
  json.remove('starterPlanSource');
  return jsonEncode(json);
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

Future<void> _insertStage4DueLifecycle(
  AppDatabase db, {
  required int unitId,
  required int todayDay,
}) async {
  await db.into(db.companionLifecycleState).insert(
        CompanionLifecycleStateCompanion.insert(
          unitId: Value(unitId),
          lifecycleTier: const Value('ready'),
          stage4Status: const Value('pending'),
          stage4NextDayDueDay: Value(todayDay),
          stage4UnresolvedTargetsJson: const Value('[0]'),
          updatedAtDay: todayDay,
          updatedAtSeconds: 100,
        ),
      );
}

Future<void> _insertLifecycleState(
  AppDatabase db, {
  required int unitId,
  required String lifecycleTier,
  required int todayDay,
}) {
  return db.into(db.companionLifecycleState).insert(
        CompanionLifecycleStateCompanion.insert(
          unitId: Value(unitId),
          lifecycleTier: Value(lifecycleTier),
          stage4Status: const Value('passed'),
          updatedAtDay: todayDay,
          updatedAtSeconds: 100,
        ),
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

Future<int> _insertMemUnitOnly(
  AppDatabase db, {
  required String unitKey,
  required int todayDay,
}) {
  return db.into(db.memUnit).insert(
        MemUnitCompanion.insert(
          kind: 'page_segment',
          pageMadina: const Value(1),
          startSurah: const Value(1),
          startAyah: const Value(1),
          endSurah: const Value(1),
          endAyah: const Value(1),
          unitKey: unitKey,
          createdAtDay: todayDay,
          updatedAtDay: todayDay,
        ),
      );
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
    find.byKey(const ValueKey('today_screen_root')),
  );

  const timeout = Duration(seconds: 5);
  const step = Duration(milliseconds: 50);
  var elapsed = Duration.zero;
  while (elapsed <= timeout) {
    final hasGuidedSetup = find
        .byKey(const ValueKey('today_guided_setup_card'))
        .evaluate()
        .isNotEmpty;
    final hasNextStep =
        find.byKey(const ValueKey('today_next_step_card')).evaluate().isNotEmpty;
    final hasError =
        find.byKey(const ValueKey('today_error')).evaluate().isNotEmpty;
    if (hasGuidedSetup || hasNextStep || hasError) {
      return;
    }
    await tester.pump(step);
    elapsed += step;
  }

  throw TestFailure(
    'Timed out after ${timeout.inMilliseconds}ms waiting for Today ready state.',
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pumpPlanWithContainer(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: PlanScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
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
      GoRoute(
        path: '/my-quran',
        builder: (_, __) {
          return const Scaffold(
            body: Center(
              child: Text('My Quran route'),
            ),
          );
        },
      ),
    ],
  );
}
