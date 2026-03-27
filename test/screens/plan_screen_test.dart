import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/data/repositories/progress_repo.dart';
import 'package:hifz_planner/data/repositories/settings_repo.dart';
import 'package:hifz_planner/data/services/scheduling/scheduling_preferences_codec.dart';
import 'package:hifz_planner/data/time/local_day_time.dart';
import 'package:hifz_planner/screens/plan_screen.dart';

void main() {
  testWidgets('renders questionnaire and suggested plan panel', (tester) async {
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

    await _pumpPlan(tester, container);

    expect(find.textContaining('Onboarding Questionnaire'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('plan_scheduling_section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('plan_weekly_calendar_section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('plan_scheduling_two_sessions')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('plan_time_mode')), findsOneWidget);
    expect(find.byKey(const ValueKey('plan_fluency_fluent')), findsOneWidget);
    expect(find.byKey(const ValueKey('plan_profile')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('plan_force_revision_only')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('plan_max_new_pages')), findsOneWidget);
    expect(find.byKey(const ValueKey('plan_max_new_units')), findsOneWidget);
    expect(find.text('Suggested Plan (Editable)'), findsOneWidget);
    expect(find.byKey(const ValueKey('plan_forecast_section')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('plan_forecast_run_button')),
      findsOneWidget,
    );
    expect(find.text('Calibration Mode (Optional)'), findsOneWidget);
    expect(find.byKey(const ValueKey('plan_calibration_new_duration')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('plan_calibration_review_duration')),
        findsOneWidget);
    expect(
      find.byKey(const ValueKey('plan_apply_calibration_button')),
      findsOneWidget,
    );
  });

  testWidgets('running forecast on empty quran data shows incomplete reason',
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

    await _pumpPlan(tester, container);
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('plan_forecast_run_button')),
    );

    expect(
      find.byKey(const ValueKey('plan_forecast_incomplete_reason')),
      findsOneWidget,
    );
  });

  testWidgets('running forecast with seeded data shows completion and curves',
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
            surah: 114,
            ayah: 6,
            textUthmani: 'ayah-114-6',
            pageMadina: const Value(2),
          ),
        ],
      );
    });
    await SettingsRepo(db).updateSettings(
      forceRevisionOnly: 0,
      requirePageMetadata: 0,
      maxNewPagesPerDay: 4,
      maxNewUnitsPerDay: 8,
      avgNewMinutesPerAyah: 1.0,
      avgReviewMinutesPerAyah: 1.0,
      dailyMinutesDefault: 60,
    );

    await _pumpPlan(tester, container);
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('plan_forecast_run_button')),
    );

    expect(
      find.byKey(const ValueKey('plan_forecast_completion_date')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('plan_forecast_weekly_minutes')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('plan_forecast_revision_ratio')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('plan_forecast_new_pages_per_day')),
      findsOneWidget,
    );
  });

  testWidgets('weekly mode computes weekday chips from weekly minutes',
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
    await _pumpPlan(tester, container);

    await tester.enterText(
      find.byKey(const ValueKey('plan_weekly_minutes')),
      '10',
    );
    await tester.pump();

    expect(find.text('mon: 2'), findsOneWidget);
    expect(find.text('tue: 2'), findsOneWidget);
    expect(find.text('wed: 2'), findsOneWidget);
    expect(find.text('thu: 1'), findsOneWidget);
  });

  testWidgets(
      'advanced minute fields mirror weekly input and stay read-only',
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
    await _pumpPlan(tester, container);

    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_weekly_minutes')),
      '350',
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('plan_scheduling_advanced_mode')),
    );
    await tester.pump();

    final minutesPerDay = tester.widget<TextField>(
      find.byKey(const ValueKey('plan_scheduling_minutes_per_day')),
    );
    final minutesPerWeek = tester.widget<TextField>(
      find.byKey(const ValueKey('plan_scheduling_minutes_per_week')),
    );

    expect(minutesPerDay.controller?.text, '50');
    expect(minutesPerWeek.controller?.text, '350');
    expect(minutesPerDay.readOnly, isTrue);
    expect(minutesPerWeek.readOnly, isTrue);
  });

  testWidgets('weekly calendar renders day cards with default session rows',
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

    await _pumpPlan(tester, container);

    expect(
      find.byKey(const ValueKey('plan_weekly_day_0')),
      findsOneWidget,
    );
  });

  testWidgets('per-weekday mode uses direct entered values', (tester) async {
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
    await _pumpPlan(tester, container);

    await _tapVisible(tester, find.text('Per weekday'));

    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_weekday_mon')),
      '11',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_weekday_tue')),
      '12',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_weekday_wed')),
      '13',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_weekday_thu')),
      '14',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_weekday_fri')),
      '15',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_weekday_sat')),
      '16',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_weekday_sun')),
      '17',
    );

    expect(find.text('mon: 11'), findsOneWidget);
    expect(find.text('sun: 17'), findsOneWidget);
  });

  testWidgets(
      'advanced minute fields mirror weekday input and stay read-only',
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
    await _pumpPlan(tester, container);

    await _tapVisible(tester, find.text('Per weekday'));
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_weekday_mon')),
      '11',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_weekday_tue')),
      '12',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_weekday_wed')),
      '13',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_weekday_thu')),
      '14',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_weekday_fri')),
      '15',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_weekday_sat')),
      '16',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_weekday_sun')),
      '17',
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('plan_scheduling_advanced_mode')),
    );
    await tester.pump();

    final minutesPerDay = tester.widget<TextField>(
      find.byKey(const ValueKey('plan_scheduling_minutes_per_day')),
    );
    final minutesPerWeek = tester.widget<TextField>(
      find.byKey(const ValueKey('plan_scheduling_minutes_per_week')),
    );

    expect(minutesPerDay.controller?.text, '14');
    expect(minutesPerWeek.controller?.text, '98');
    expect(minutesPerDay.readOnly, isTrue);
    expect(minutesPerWeek.readOnly, isTrue);
  });

  testWidgets('fluency selection updates suggested avg defaults',
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
    await _pumpPlan(tester, container);

    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('plan_avg_new_minutes')))
          .controller
          ?.text,
      '2.0',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('plan_avg_review_minutes')),
          )
          .controller
          ?.text,
      '0.8',
    );

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('plan_fluency_fluent')),
    );

    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('plan_avg_new_minutes')))
          .controller
          ?.text,
      '1.6',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('plan_avg_review_minutes')),
          )
          .controller
          ?.text,
      '0.6',
    );
  });

  testWidgets('activate persists settings row with expected values',
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
    await _pumpPlan(tester, container);

    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_weekly_minutes')),
      '140',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_max_new_pages')),
      '2',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_max_new_units')),
      '9',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_avg_new_minutes')),
      '2.3',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_avg_review_minutes')),
      '0.9',
    );
    await tester.pump();

    await _tapVisible(
        tester, find.byKey(const ValueKey('plan_activate_button')));

    final settings = await SettingsRepo(db).getSettings();
    expect(settings.profile, 'standard');
    expect(settings.forceRevisionOnly, 0);
    expect(settings.maxNewPagesPerDay, 2);
    expect(settings.maxNewUnitsPerDay, 9);
    expect(settings.avgNewMinutesPerAyah, 2.3);
    expect(settings.avgReviewMinutesPerAyah, 0.9);
    expect(settings.requirePageMetadata, 1);
    expect(settings.dailyMinutesDefault, 20);
    expect(settings.minutesByWeekdayJson, isNotNull);

    final weekday = jsonDecode(settings.minutesByWeekdayJson!);
    expect(weekday['mon'], 20);
    expect(weekday['sun'], 20);

    final prefs = await SettingsRepo(db).getSchedulingPreferences();
    expect(prefs.minutesPerWeekDefault, 140);
    expect(prefs.minutesByWeekday[DateTime.monday], 20);
    expect(prefs.minutesByWeekday[DateTime.sunday], 20);
  });

  testWidgets(
      'reload restores beginner values from structured scheduling prefs first',
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
    await _pumpPlan(tester, container);

    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_weekly_minutes')),
      '350',
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('plan_activate_button')),
    );

    await SettingsRepo(db).updateSettings(
      dailyMinutesDefault: 5,
      minutesByWeekdayJson:
          '{"mon":1,"tue":2,"wed":3,"thu":4,"fri":5,"sat":6,"sun":7}',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await _pumpPlan(tester, container);

    final weeklyField =
        tester.widget<TextField>(find.byKey(const ValueKey('plan_weekly_minutes')));
    expect(weeklyField.controller?.text, '350');
  });

  testWidgets('activate ensures cursor exists and preserves existing cursor',
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
    final progressRepo = ProgressRepo(db);

    await progressRepo.updateCursor(
      nextSurah: 2,
      nextAyah: 5,
      updatedAtDay: 22222,
    );
    await _pumpPlan(tester, container);

    await _tapVisible(
        tester, find.byKey(const ValueKey('plan_activate_button')));

    final cursor = await progressRepo.getCursor();
    expect(cursor.nextSurah, 2);
    expect(cursor.nextAyah, 5);
  });

  testWidgets('force revision toggle defaults OFF and persists edited value',
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
    await _pumpPlan(tester, container);

    final forceSwitch = find.byKey(const ValueKey('plan_force_revision_only'));
    expect(
      (tester.widget<SwitchListTile>(forceSwitch)).value,
      isFalse,
    );

    await _tapVisible(tester, forceSwitch);
    await _tapVisible(
        tester, find.byKey(const ValueKey('plan_activate_button')));

    final settings = await SettingsRepo(db).getSettings();
    expect(settings.forceRevisionOnly, 1);
  });

  testWidgets(
      'custom legacy revision-only plan without structured prefs still loads switch ON',
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

    await SettingsRepo(db).updateSettings(
      profile: 'standard',
      forceRevisionOnly: 1,
      dailyMinutesDefault: 55,
      minutesByWeekdayJson:
          '{"mon":55,"tue":55,"wed":55,"thu":55,"fri":55,"sat":55,"sun":55}',
      maxNewPagesPerDay: 2,
      maxNewUnitsPerDay: 3,
      avgNewMinutesPerAyah: 1.7,
      avgReviewMinutesPerAyah: 0.7,
    );

    await _pumpPlan(tester, container);

    final forceSwitch = find.byKey(const ValueKey('plan_force_revision_only'));
    expect(
      (tester.widget<SwitchListTile>(forceSwitch)).value,
      isTrue,
    );
  });

  testWidgets(
      'explicitly enabling revision-only marks the saved plan as user-saved',
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
    await _pumpPlan(tester, container);
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('plan_force_revision_only')),
    );

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('plan_activate_button')),
    );

    final repo = SettingsRepo(db);
    final settings = await repo.getSettings();
    final prefs = await repo.getSchedulingPreferences();

    expect(settings.forceRevisionOnly, 1);
    expect(prefs.starterPlanSource, StarterPlanSource.userSaved);
    expect(repo.assessStarterPlanHealth(settings), StarterPlanHealth.healthy);
  });

  testWidgets('manual plan save invalidates stale solo setup readiness',
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
    final todayDay = localDayIndex(DateTime.now().toLocal());
    final repo = SettingsRepo(db);

    await _seedReadyQuranData(db);
    await _insertExistingMemUnit(
      db,
      unitKey: 'stale-readiness-unit',
      todayDay: todayDay,
    );
    await repo.updateSettings(
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

    final readinessSubscription = container.listen(
      soloSetupReadinessProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(readinessSubscription.close);

    final staleReadiness = await container.read(soloSetupReadinessProvider.future);
    expect(staleReadiness.needsStarterPlanRepair, isTrue);

    await _pumpPlan(tester, container);
    final forceSwitch = find.byKey(const ValueKey('plan_force_revision_only'));
    expect(
      (tester.widget<SwitchListTile>(forceSwitch)).value,
      isFalse,
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('plan_activate_button')),
    );

    final settings = await repo.getSettings();
    final refreshedReadiness = await container.read(
      soloSetupReadinessProvider.future,
    );
    expect(settings.forceRevisionOnly, 0);
    expect(refreshedReadiness.needsStarterPlanRepair, isFalse);
    expect(refreshedReadiness.needsGuidedSetup, isFalse);
    expect(
      repo.assessStarterPlanHealth(settings),
      StarterPlanHealth.healthy,
    );
  });

  testWidgets('require page metadata defaults ON and persists edited value',
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
    await _pumpPlan(tester, container);

    final metadataSwitch =
        find.byKey(const ValueKey('plan_require_page_metadata'));
    expect(
      (tester.widget<SwitchListTile>(metadataSwitch)).value,
      isTrue,
    );

    await _tapVisible(tester, metadataSwitch);
    await _tapVisible(
        tester, find.byKey(const ValueKey('plan_activate_button')));

    final settings = await SettingsRepo(db).getSettings();
    expect(settings.requirePageMetadata, 0);
  });

  testWidgets('adding calibration samples persists rows and refreshes preview',
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
    await _pumpPlan(tester, container);

    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_calibration_new_duration')),
      '2',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_calibration_new_ayah_count')),
      '1',
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('plan_calibration_add_new')),
    );

    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_calibration_review_duration')),
      '1',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_calibration_review_ayah_count')),
      '2',
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('plan_calibration_add_review')),
    );

    final rows = await (db.select(db.calibrationSample)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
        .get();
    expect(rows.length, 2);
    expect(rows.first.sampleKind, 'new_memorization');
    expect(rows.last.sampleKind, 'review');

    final newPreview = tester
        .widget<Text>(
            find.byKey(const ValueKey('plan_calibration_preview_new')))
        .data!;
    final reviewPreview = tester
        .widget<Text>(
          find.byKey(const ValueKey('plan_calibration_preview_review')),
        )
        .data!;
    expect(newPreview.contains('New samples: 1'), isTrue);
    expect(reviewPreview.contains('Review samples: 1'), isTrue);
  });

  testWidgets('apply calibration now updates settings and grade distribution',
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
    await _pumpPlan(tester, container);

    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_calibration_new_duration')),
      '2',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_calibration_new_ayah_count')),
      '1',
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('plan_calibration_add_new')),
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_calibration_review_duration')),
      '1',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_calibration_review_ayah_count')),
      '2',
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('plan_calibration_add_review')),
    );

    await _enterTextVisible(
        tester, find.byKey(const ValueKey('plan_grade_q5')), '40');
    await _enterTextVisible(
        tester, find.byKey(const ValueKey('plan_grade_q4')), '30');
    await _enterTextVisible(
        tester, find.byKey(const ValueKey('plan_grade_q3')), '20');
    await _enterTextVisible(
        tester, find.byKey(const ValueKey('plan_grade_q2')), '8');
    await _enterTextVisible(
        tester, find.byKey(const ValueKey('plan_grade_q0')), '2');

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('plan_apply_calibration_button')),
    );

    final settings = await SettingsRepo(db).getSettings();
    final pending = await SettingsRepo(db).getPendingCalibrationUpdate();

    expect(settings.avgNewMinutesPerAyah, 2.0);
    expect(settings.avgReviewMinutesPerAyah, 0.5);
    expect(settings.typicalGradeDistributionJson, isNotNull);
    final decoded = jsonDecode(settings.typicalGradeDistributionJson!);
    expect(decoded['5'], 40);
    expect(decoded['0'], 2);
    expect(pending, isNull);
  });

  testWidgets(
      'apply calibration from tomorrow creates pending update and keeps active settings',
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
    final settingsRepo = SettingsRepo(db);

    await settingsRepo.updateSettings(
      avgNewMinutesPerAyah: 2.2,
      avgReviewMinutesPerAyah: 0.9,
      updatedAtDay: 12345,
    );
    await _pumpPlan(tester, container);

    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_calibration_new_duration')),
      '3',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_calibration_new_ayah_count')),
      '1',
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('plan_calibration_add_new')),
    );

    await _tapVisible(tester, find.text('Apply from tomorrow'));
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('plan_apply_calibration_button')),
    );

    final today = localDayIndex(DateTime.now().toLocal());
    final settings = await settingsRepo.getSettings(todayDayOverride: today);
    final pending = await settingsRepo.getPendingCalibrationUpdate();

    expect(settings.avgNewMinutesPerAyah, 2.2);
    expect(settings.avgReviewMinutesPerAyah, 0.9);
    expect(pending, isNotNull);
    expect(pending!.effectiveDay, today + 1);
    expect(pending.avgNewMinutesPerAyah, 3.0);
  });

  testWidgets('invalid grade distribution blocks calibration apply',
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
    final settingsRepo = SettingsRepo(db);
    await _pumpPlan(tester, container);

    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_calibration_new_duration')),
      '2',
    );
    await _enterTextVisible(
      tester,
      find.byKey(const ValueKey('plan_calibration_new_ayah_count')),
      '1',
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('plan_calibration_add_new')),
    );

    await _enterTextVisible(
        tester, find.byKey(const ValueKey('plan_grade_q5')), '50');
    await _enterTextVisible(
        tester, find.byKey(const ValueKey('plan_grade_q4')), '20');
    await _enterTextVisible(
        tester, find.byKey(const ValueKey('plan_grade_q3')), '20');
    await _enterTextVisible(
        tester, find.byKey(const ValueKey('plan_grade_q2')), '5');
    await _enterTextVisible(
        tester, find.byKey(const ValueKey('plan_grade_q0')), '1');
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('plan_apply_calibration_button')),
    );

    final settings = await settingsRepo.getSettings();
    final pending = await settingsRepo.getPendingCalibrationUpdate();
    expect(settings.typicalGradeDistributionJson, isNull);
    expect(pending, isNull);
  });
}

Future<void> _pumpPlan(
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

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enterTextVisible(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

Future<void> _seedReadyQuranData(AppDatabase db) async {
  await db.into(db.ayah).insert(
        AyahCompanion.insert(
          surah: 1,
          ayah: 1,
          textUthmani: 'ayah-1',
          pageMadina: const Value(1),
        ),
      );
}

Future<int> _insertExistingMemUnit(
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

String _encodeUnmarkedPreferences(SchedulingPreferencesV1 preferences) {
  final json = jsonDecode(preferences.encode()) as Map<String, dynamic>;
  json.remove('starterPlanSource');
  return jsonEncode(json);
}
