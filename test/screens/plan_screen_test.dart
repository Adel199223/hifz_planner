import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/data/repositories/progress_repo.dart';
import 'package:hifz_planner/data/repositories/settings_repo.dart';
import 'package:hifz_planner/screens/plan_screen.dart';

void main() {
  testWidgets('renders questionnaire and suggested plan panel', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await _pumpPlan(tester, db);

    expect(find.textContaining('Onboarding Questionnaire'), findsOneWidget);
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
  });

  testWidgets('weekly mode computes weekday chips from weekly minutes',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _pumpPlan(tester, db);

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

  testWidgets('per-weekday mode uses direct entered values', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _pumpPlan(tester, db);

    await tester.tap(find.text('Per weekday'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('plan_weekday_mon')), '11');
    await tester.enterText(
        find.byKey(const ValueKey('plan_weekday_tue')), '12');
    await tester.enterText(
        find.byKey(const ValueKey('plan_weekday_wed')), '13');
    await tester.enterText(
        find.byKey(const ValueKey('plan_weekday_thu')), '14');
    await tester.enterText(
        find.byKey(const ValueKey('plan_weekday_fri')), '15');
    await tester.enterText(
        find.byKey(const ValueKey('plan_weekday_sat')), '16');
    await tester.enterText(
        find.byKey(const ValueKey('plan_weekday_sun')), '17');
    await tester.pump();

    expect(find.text('mon: 11'), findsOneWidget);
    expect(find.text('sun: 17'), findsOneWidget);
  });

  testWidgets('fluency selection updates suggested avg defaults',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _pumpPlan(tester, db);

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

    await tester.tap(find.byKey(const ValueKey('plan_fluency_fluent')));
    await tester.pump();

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
    addTearDown(db.close);
    await _pumpPlan(tester, db);

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

    await _tapVisible(tester, find.byKey(const ValueKey('plan_activate_button')));

    final settings = await SettingsRepo(db).getSettings();
    expect(settings.profile, 'standard');
    expect(settings.forceRevisionOnly, 1);
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
  });

  testWidgets('activate ensures cursor exists and preserves existing cursor',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final progressRepo = ProgressRepo(db);

    await progressRepo.updateCursor(
      nextSurah: 2,
      nextAyah: 5,
      updatedAtDay: 22222,
    );
    await _pumpPlan(tester, db);

    await _tapVisible(tester, find.byKey(const ValueKey('plan_activate_button')));

    final cursor = await progressRepo.getCursor();
    expect(cursor.nextSurah, 2);
    expect(cursor.nextAyah, 5);
  });

  testWidgets('force revision toggle defaults ON and persists edited value',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _pumpPlan(tester, db);

    final forceSwitch = find.byKey(const ValueKey('plan_force_revision_only'));
    expect(
      (tester.widget<SwitchListTile>(forceSwitch)).value,
      isTrue,
    );

    await _tapVisible(tester, forceSwitch);
    await _tapVisible(tester, find.byKey(const ValueKey('plan_activate_button')));

    final settings = await SettingsRepo(db).getSettings();
    expect(settings.forceRevisionOnly, 0);
  });

  testWidgets('require page metadata defaults ON and persists edited value',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _pumpPlan(tester, db);

    final metadataSwitch =
        find.byKey(const ValueKey('plan_require_page_metadata'));
    expect(
      (tester.widget<SwitchListTile>(metadataSwitch)).value,
      isTrue,
    );

    await _tapVisible(tester, metadataSwitch);
    await _tapVisible(tester, find.byKey(const ValueKey('plan_activate_button')));

    final settings = await SettingsRepo(db).getSettings();
    expect(settings.requirePageMetadata, 0);
  });
}

Future<void> _pumpPlan(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
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
