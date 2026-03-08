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
    expect(find.byKey(const ValueKey('today_coaching_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('today_reviews_section')), findsOneWidget);
    expect(find.byKey(const ValueKey('today_new_section')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('today_sessions_section')),
      findsOneWidget,
    );
    expect(find.byKey(ValueKey('today_review_row_$dueUnitId')), findsOneWidget);
    expect(
      find.byKey(ValueKey('today_open_companion_review_$dueUnitId')),
      findsOneWidget,
    );
    expect(find.textContaining('page_segment'), findsWidgets);
  });

  testWidgets('grading planned review writes review_log and updates schedule', (
    tester,
  ) async {
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

    final schedule = await (db.select(
      db.scheduleState,
    )..where((tbl) => tbl.unitId.equals(dueUnitId)))
        .getSingle();
    expect(schedule.lastGradeQ, 5);
    expect(schedule.lastReviewDay, todayDay);
    expect(schedule.dueDay, todayDay + 1);

    expect(find.byKey(ValueKey('today_review_row_$dueUnitId')), findsNothing);
  });

  testWidgets('self-check grade for new unit writes review_log and schedules', (
    tester,
  ) async {
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

    final schedule = await (db.select(
      db.scheduleState,
    )..where((tbl) => tbl.unitId.equals(unitId)))
        .getSingle();
    expect(schedule.lastGradeQ, 4);
    expect(schedule.lastReviewDay, todayDay);
    expect(schedule.dueDay, todayDay + 1);

    expect(find.byKey(ValueKey('today_new_row_$unitId')), findsNothing);
  });

  testWidgets('open in reader navigates with page mode and highlight range', (
    tester,
  ) async {
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

  testWidgets('open companion review action navigates with mode=review', (
    tester,
  ) async {
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

    final companionButton = find.byKey(
      ValueKey('today_open_companion_review_$dueUnitId'),
    );
    await pumpUntilFound(tester, companionButton);
    expect(find.text('Continue review practice'), findsWidgets);
    await _tapVisible(tester, companionButton);

    expect(
      find.text('Companion route unitId=$dueUnitId mode=review'),
      findsOneWidget,
    );
  });

  testWidgets('stage-4 due item opens companion with mode=stage4', (
    tester,
  ) async {
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
    await _insertStage4DueLifecycle(db, unitId: dueUnitId, todayDay: todayDay);

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

    final stage4Button = find.byKey(
      ValueKey('today_open_companion_stage4_$dueUnitId'),
    );
    await pumpUntilFound(tester, stage4Button);
    expect(find.text('Do delayed check'), findsWidgets);
    await _tapVisible(tester, stage4Button);

    expect(
      find.text('Companion route unitId=$dueUnitId mode=stage4'),
      findsOneWidget,
    );
  });

  testWidgets('coaching card prioritizes stage-4 work and exposes recovery', (
    tester,
  ) async {
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
    await _insertStage4DueLifecycle(db, unitId: dueUnitId, todayDay: todayDay);

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
      find.byKey(const ValueKey('today_coaching_card')),
    );

    expect(find.text('Protect yesterday’s memorization first'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('today_plan_health_badge')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('today_explanation_packet')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('today_goal_focus_card')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('today_goal_focus_badge')),
      findsOneWidget,
    );
    expect(find.text('Recovery and stabilize'), findsOneWidget);
    expect(find.byKey(const ValueKey('today_goal_good_day')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('today_goal_coaching_card')),
      findsOneWidget,
    );
    expect(find.text('Reopen My Plan and lighten the setup'), findsOneWidget);
    expect(
      find.text(
        'A good day means doing the safest essential work without forcing a full load.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('today_short_day_hint')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('today_minimum_day_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('today_stage4_explanation')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('today_recovery_entry')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('today_recovery_wizard_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('today_other_practice_modes')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('today_other_practice_mode_review')),
      findsOneWidget,
    );
    expect(find.text('Do delayed check'), findsWidgets);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('today_coaching_primary_action')),
    );

    expect(
      find.text('Companion route unitId=$dueUnitId mode=stage4'),
      findsOneWidget,
    );
  });

  testWidgets('coaching card shows steady-progress daily wins on a light day', (
    tester,
  ) async {
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
    );

    await _pumpToday(tester, container);

    expect(find.byKey(const ValueKey('today_goal_focus_card')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('today_weekly_progress_card')),
      findsOneWidget,
    );
    expect(find.text('Steady progress'), findsOneWidget);
    expect(
      find.text(
        'A good day means finishing the main task and, if time allows, the rest of today\'s planned work.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Start building consistency with one real practice, review, or delayed check today.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'On a short day, the top planned task still counts as a real win.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('today_goal_coaching_card')),
      findsOneWidget,
    );
    expect(find.text('Stay steady'), findsOneWidget);
    expect(
      find.text(
        'Only real completed practice, review, or delayed check work counts. Opening a screen alone does not.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('weekly progress card summarizes recent real work', (
    tester,
  ) async {
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
    await _seedWeeklyProgressActivity(db, todayDay: todayDay);

    await _pumpToday(tester, container);

    expect(
      find.byKey(const ValueKey('today_weekly_progress_card')),
      findsOneWidget,
    );
    expect(find.text('3 active days in the last 7 days.'), findsOneWidget);
    expect(
      find.text('2 reviews, 1 delayed checks, 2 practice completions.'),
      findsOneWidget,
    );
    expect(find.text('Mostly steady'), findsOneWidget);
    expect(
      find.text('Keep repeating the main task and let steady days add up.'),
      findsOneWidget,
    );
  });

  testWidgets('weekly progress card handles sparse returning activity calmly', (
    tester,
  ) async {
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
    await _seedSparseWeeklyProgressActivity(db, todayDay: todayDay);

    await _pumpToday(tester, container);

    expect(
      find.text(
        'You are getting back into rhythm. A few calm, real sessions are enough this week.',
      ),
      findsOneWidget,
    );
    expect(find.text('1 active days in the last 7 days.'), findsOneWidget);
    expect(
      find.text(
        'A gentle return still counts. Keep the next few sessions simple and repeatable.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'coaching card exposes other practice modes when review is primary',
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
      await _insertDueReviewUnit(db, todayDay: todayDay);

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
        find.byKey(const ValueKey('today_coaching_card')),
      );

      expect(
        find.byKey(const ValueKey('today_other_practice_modes')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('today_other_practice_mode_new')),
        findsOneWidget,
      );
      expect(find.text('Start new practice'), findsWidgets);
    },
  );

  testWidgets('recovery wizard opens from Today and can route to My Plan', (
    tester,
  ) async {
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
    await _insertStage4DueLifecycle(db, unitId: dueUnitId, todayDay: todayDay);

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
      find.byKey(const ValueKey('today_recovery_wizard_button')),
    );

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('today_recovery_wizard_button')),
    );
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.byKey(const ValueKey('recovery_wizard_recommendation')),
      findsOneWidget,
    );

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('recovery_wizard_open_plan')),
    );

    expect(find.text('Plan route'), findsOneWidget);
  });

  testWidgets('mandatory stage-4 due blocks new until override is confirmed', (
    tester,
  ) async {
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
    await _insertStage4DueLifecycle(db, unitId: dueUnitId, todayDay: todayDay);

    await _pumpToday(tester, container);
    expect(find.byKey(const ValueKey('today_stage4_section')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('today_stage4_override_new_button')),
      findsOneWidget,
    );

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

    final lifecycle = await (db.select(
      db.companionLifecycleState,
    )..where((tbl) => tbl.unitId.equals(dueUnitId)))
        .getSingle();
    expect(lifecycle.lastNewOverrideDay, todayDay);
    expect(lifecycle.newOverrideCount, 1);

    final afterNewUnits = await _fetchPlannedNewUnits(db, todayDay: todayDay);
    expect(afterNewUnits, isNotEmpty);
  });

  testWidgets('open companion new action navigates with mode=new', (
    tester,
  ) async {
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
    final companionButton = find.byKey(
      ValueKey('today_open_companion_new_$unitId'),
    );
    await pumpUntilFound(tester, companionButton);
    expect(find.text('Start new practice'), findsWidgets);
    await _tapVisible(tester, companionButton);

    expect(
      find.text('Companion route unitId=$unitId mode=new'),
      findsOneWidget,
    );
  });

  testWidgets('coaching card routes new focus into practice flow', (
    tester,
  ) async {
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
      find.byKey(const ValueKey('today_coaching_card')),
    );

    final plannedNewUnits = await _fetchPlannedNewUnits(
      db,
      todayDay: localDayIndex(DateTime.now().toLocal()),
    );
    expect(plannedNewUnits, isNotEmpty);
    final unitId = plannedNewUnits.first.id;

    expect(find.text('Start new practice'), findsWidgets);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('today_coaching_primary_action')),
    );

    expect(
      find.text('Companion route unitId=$unitId mode=new'),
      findsOneWidget,
    );
  });

  testWidgets('empty today state routes users to My Plan', (tester) async {
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
      find.byKey(const ValueKey('today_empty_state')),
    );
    expect(find.text('Nothing is scheduled yet'), findsOneWidget);
    expect(
      find.text(
        'Open My Plan to set a realistic daily rhythm and see today’s next steps here.',
      ),
      findsOneWidget,
    );

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('today_empty_open_plan')),
    );

    expect(find.text('Plan route'), findsOneWidget);
  });

  testWidgets('completion card appears after finishing the last new unit', (
    tester,
  ) async {
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

    await _pumpToday(tester, container);

    final plannedNewUnits = await _fetchPlannedNewUnits(db, todayDay: todayDay);
    expect(plannedNewUnits, isNotEmpty);
    final unitId = plannedNewUnits.first.id;
    final gradeButton = find.byKey(ValueKey('today_new_grade_${unitId}_q4'));
    await pumpUntilFound(tester, gradeButton);

    await _tapVisible(tester, gradeButton);

    expect(find.byKey(const ValueKey('today_completion_card')), findsOneWidget);
    expect(find.text('A real start counts'), findsOneWidget);
    expect(
      find.text(
        'You finished a real day of practice. That is enough to start building consistency.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'open in reader button is disabled when page metadata is missing',
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

      final plannedNewUnits = await _fetchPlannedNewUnits(
        db,
        todayDay: todayDay,
      );
      final unit = plannedNewUnits.firstWhere((row) => row.pageMadina == null);
      final openButtonFinder = find.byKey(
        ValueKey('today_open_reader_${unit.id}'),
      );
      await pumpUntilFound(tester, openButtonFinder);

      final openButton = tester.widget<OutlinedButton>(openButtonFinder);
      expect(openButton.onPressed, isNull);
      expect(
        find.text('Page metadata required to open in Reader.'),
        findsWidgets,
      );
    },
  );

  testWidgets('debug seed button generates one new memorization unit', (
    tester,
  ) async {
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
    expect(find.text('No planned new units left.'), findsOneWidget);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('today_debug_seed_new_unit')),
    );

    final seededUnits = await (db.select(db.memUnit)
          ..where(
            (tbl) =>
                tbl.kind.equals('page_segment') &
                tbl.createdAtDay.equals(todayDay),
          )
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
        .get();
    expect(seededUnits, isNotEmpty);

    final seededUnit = seededUnits.first;
    expect(
      find.byKey(ValueKey('today_new_row_${seededUnit.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('today_open_companion_new_${seededUnit.id}')),
      findsOneWidget,
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

Future<void> _seedWeeklyProgressActivity(
  AppDatabase db, {
  required int todayDay,
}) async {
  final practiceUnitA = await db.into(db.memUnit).insert(
        MemUnitCompanion.insert(
          kind: 'ayah_range',
          pageMadina: const Value(1),
          startSurah: const Value(1),
          startAyah: const Value(10),
          endSurah: const Value(1),
          endAyah: const Value(10),
          unitKey: 'weekly-progress-a',
          createdAtDay: todayDay - 2,
          updatedAtDay: todayDay - 2,
        ),
      );
  final practiceUnitB = await db.into(db.memUnit).insert(
        MemUnitCompanion.insert(
          kind: 'ayah_range',
          pageMadina: const Value(1),
          startSurah: const Value(1),
          startAyah: const Value(11),
          endSurah: const Value(1),
          endAyah: const Value(11),
          unitKey: 'weekly-progress-b',
          createdAtDay: todayDay - 1,
          updatedAtDay: todayDay - 1,
        ),
      );
  final reviewUnit = await db.into(db.memUnit).insert(
        MemUnitCompanion.insert(
          kind: 'ayah_range',
          pageMadina: const Value(1),
          startSurah: const Value(1),
          startAyah: const Value(12),
          endSurah: const Value(1),
          endAyah: const Value(12),
          unitKey: 'weekly-progress-review',
          createdAtDay: todayDay - 3,
          updatedAtDay: todayDay - 3,
        ),
      );
  final stage4Unit = await db.into(db.memUnit).insert(
        MemUnitCompanion.insert(
          kind: 'ayah_range',
          pageMadina: const Value(1),
          startSurah: const Value(1),
          startAyah: const Value(13),
          endSurah: const Value(1),
          endAyah: const Value(13),
          unitKey: 'weekly-progress-stage4',
          createdAtDay: todayDay - 1,
          updatedAtDay: todayDay - 1,
        ),
      );

  await db.batch((batch) {
    batch.insertAll(db.companionChainSession, [
      CompanionChainSessionCompanion.insert(
        unitId: practiceUnitA,
        targetVerseCount: 1,
        passedVerseCount: const Value(1),
        chainResult: 'completed',
        retrievalStrength: const Value(0.8),
        createdAtDay: todayDay - 2,
        updatedAtDay: todayDay - 2,
        startedAtSeconds: const Value(100),
        endedAtSeconds: const Value(180),
      ),
      CompanionChainSessionCompanion.insert(
        unitId: practiceUnitB,
        targetVerseCount: 1,
        passedVerseCount: const Value(1),
        chainResult: 'completed',
        retrievalStrength: const Value(0.85),
        createdAtDay: todayDay - 1,
        updatedAtDay: todayDay - 1,
        startedAtSeconds: const Value(100),
        endedAtSeconds: const Value(180),
      ),
    ]);
    batch.insertAll(db.reviewLog, [
      ReviewLogCompanion.insert(
        unitId: reviewUnit,
        tsDay: todayDay - 3,
        tsSeconds: const Value(200),
        gradeQ: 5,
      ),
      ReviewLogCompanion.insert(
        unitId: reviewUnit,
        tsDay: todayDay - 1,
        tsSeconds: const Value(210),
        gradeQ: 4,
      ),
    ]);
    batch.insertAll(db.companionStage4Session, [
      CompanionStage4SessionCompanion.insert(
        unitId: stage4Unit,
        dueKind: 'next_day_required',
        startedDay: todayDay - 1,
        startedSeconds: const Value(300),
        endedDay: Value(todayDay - 1),
        endedSeconds: const Value(340),
        outcome: const Value('pass'),
      ),
    ]);
  });
}

Future<void> _seedSparseWeeklyProgressActivity(
  AppDatabase db, {
  required int todayDay,
}) async {
  final practiceUnit = await db.into(db.memUnit).insert(
        MemUnitCompanion.insert(
          kind: 'ayah_range',
          pageMadina: const Value(1),
          startSurah: const Value(1),
          startAyah: const Value(40),
          endSurah: const Value(1),
          endAyah: const Value(40),
          unitKey: 'weekly-progress-sparse',
          createdAtDay: todayDay - 1,
          updatedAtDay: todayDay - 1,
        ),
      );

  await db.batch((batch) {
    batch.insert(
      db.companionChainSession,
      CompanionChainSessionCompanion.insert(
        unitId: practiceUnit,
        targetVerseCount: 1,
        passedVerseCount: const Value(1),
        chainResult: 'completed',
        retrievalStrength: const Value(0.7),
        createdAtDay: todayDay - 1,
        updatedAtDay: todayDay - 1,
        startedAtSeconds: const Value(100),
        endedAtSeconds: const Value(160),
      ),
    );
    batch.insert(
      db.reviewLog,
      ReviewLogCompanion.insert(
        unitId: practiceUnit,
        tsDay: todayDay - 1,
        tsSeconds: const Value(200),
        gradeQ: 4,
      ),
    );
  });
}

Future<void> _pumpToday(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: TodayScreen())),
    ),
  );
  await tester.pump();
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('today_reviews_section')),
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
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
        path: '/plan',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('Plan route'))),
      ),
    ],
  );
}
