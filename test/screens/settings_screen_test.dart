import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/database/database_storage_status.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/data/repositories/settings_repo.dart';
import 'package:hifz_planner/data/services/scheduling/scheduling_preferences_codec.dart';
import 'package:hifz_planner/data/services/page_metadata_importer_service.dart';
import 'package:hifz_planner/data/services/quran_text_importer_service.dart';
import 'package:hifz_planner/data/time/local_day_time.dart';
import 'package:hifz_planner/l10n/app_language.dart';
import 'package:hifz_planner/l10n/app_strings.dart';
import 'package:hifz_planner/screens/settings_screen.dart';

import '../helpers/pump_until_found.dart';

void main() {
  testWidgets('renders both import buttons', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final textService = QuranTextImporterService(
      db,
      loadAssetText: (_) async => '1|1|text',
      loadPageIndex: () async => <String, int>{'1:1': 1},
    );
    final metadataService = PageMetadataImporterService(
      db,
      loadPageIndex: (_) async => <String, int>{'1:1': 1},
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        quranTextImporterServiceProvider.overrideWithValue(textService),
        pageMetadataImporterServiceProvider.overrideWithValue(metadataService),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );

    expect(find.text('Import Qur\'an Text'), findsOneWidget);
    expect(find.text('Import Page Metadata'), findsOneWidget);
    expect(find.byKey(const ValueKey('settings_guided_setup_button')), findsOneWidget);
  });

  testWidgets(
    'tapping text import button runs importer and updates progress/status',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final textService = QuranTextImporterService(
        db,
        loadAssetText: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return '''
1|1|a
1|2|b
''';
        },
        loadPageIndex: () async => <String, int>{
          '1:1': 1,
          '1:2': 1,
        },
      );
      final metadataService = PageMetadataImporterService(
        db,
        loadPageIndex: (_) async => <String, int>{'1:1': 1},
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          quranTextImporterServiceProvider.overrideWithValue(textService),
          pageMetadataImporterServiceProvider
              .overrideWithValue(metadataService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SettingsScreen()),
          ),
        ),
      );

      await tester.tap(find.text('Import Qur\'an Text'));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await pumpUntilFound(
        tester,
        find.textContaining('Import complete'),
      );

      expect(find.textContaining('Import complete'), findsWidgets);
      expect(find.textContaining('completed'), findsWidgets);
    },
  );

  testWidgets('shows already imported message when data already exists',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.into(db.ayah).insert(
          AyahCompanion.insert(
            surah: 1,
            ayah: 1,
            textUthmani: 'existing',
          ),
        );

    final textService = QuranTextImporterService(
      db,
      loadAssetText: (_) async => '1|2|new',
      loadPageIndex: () async => <String, int>{'1:2': 1},
    );
    final metadataService = PageMetadataImporterService(
      db,
      loadPageIndex: (_) async => <String, int>{'1:1': 1},
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        quranTextImporterServiceProvider.overrideWithValue(textService),
        pageMetadataImporterServiceProvider.overrideWithValue(metadataService),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );

    await tester.tap(find.text('Import Qur\'an Text'));
    await pumpUntilFound(
      tester,
      find.textContaining('Already imported'),
    );

    expect(
      find.textContaining('Already imported'),
      findsWidgets,
    );
  });

  testWidgets(
    'tapping page metadata button imports and shows completion summary',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await db.batch((batch) {
        batch.insertAll(
          db.ayah,
          [
            for (var ayah = 1; ayah <= 10; ayah++)
              AyahCompanion.insert(
                surah: 1,
                ayah: ayah,
                textUthmani: 'verse $ayah',
              ),
          ],
        );
      });

      final textService = QuranTextImporterService(
        db,
        loadAssetText: (_) async => '1|1|text',
        loadPageIndex: () async => <String, int>{'1:1': 10},
      );
      final metadataService = PageMetadataImporterService(
        db,
        loadPageIndex: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return <String, int>{'1:1': 10};
        },
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          quranTextImporterServiceProvider.overrideWithValue(textService),
          pageMetadataImporterServiceProvider
              .overrideWithValue(metadataService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SettingsScreen()),
          ),
        ),
      );

      await tester.tap(find.text('Import Page Metadata'));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await pumpUntilFound(
        tester,
        find.textContaining('Page metadata import complete'),
      );

      expect(
          find.textContaining('Page metadata import complete'), findsWidgets);

      final ayah = await (db.select(db.ayah)
            ..where((tbl) => tbl.surah.equals(1) & tbl.ayah.equals(1)))
          .getSingle();
      expect(ayah.pageMadina, 10);
    },
  );

  testWidgets(
      'shows already up-to-date message for metadata when mostly mapped',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.batch((batch) {
      batch.insertAll(
        db.ayah,
        [
          for (var ayah = 1; ayah <= 10; ayah++)
            AyahCompanion.insert(
              surah: 1,
              ayah: ayah,
              textUthmani: 'verse $ayah',
              pageMadina: ayah <= 5 ? Value(ayah) : const Value.absent(),
            ),
        ],
      );
    });

    final textService = QuranTextImporterService(
      db,
      loadAssetText: (_) async => '1|1|text',
      loadPageIndex: () async => <String, int>{'1:1': 1},
    );
    final metadataService = PageMetadataImporterService(
      db,
      loadPageIndex: (_) async => <String, int>{'1:1': 10},
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        quranTextImporterServiceProvider.overrideWithValue(textService),
        pageMetadataImporterServiceProvider.overrideWithValue(metadataService),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );

    await tester.tap(find.text('Import Page Metadata'));
    await pumpUntilFound(
      tester,
      find.textContaining('Page metadata already up to date'),
    );

    expect(
        find.textContaining('Page metadata already up to date'), findsWidgets);
    expect(find.textContaining('completed'), findsWidgets);
  });

  testWidgets('shows storage warning for transient browser storage',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final textService = QuranTextImporterService(
      db,
      loadAssetText: (_) async => '1|1|text',
      loadPageIndex: () async => <String, int>{'1:1': 1},
    );
    final metadataService = PageMetadataImporterService(
      db,
      loadPageIndex: (_) async => <String, int>{'1:1': 1},
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        quranTextImporterServiceProvider.overrideWithValue(textService),
        pageMetadataImporterServiceProvider.overrideWithValue(metadataService),
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(const ValueKey('settings_storage_warning')), findsOneWidget);
  });

  testWidgets(
      'guided setup summary stays visible for structured-pref legacy trap repairs',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final todayDay = localDayIndex(DateTime.now().toLocal());

    await _insertReadyAyah(db);
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
    await _insertMemUnitOnly(
      db,
      unitKey: 'existing-structured-trap',
      todayDay: todayDay,
    );

    final textService = QuranTextImporterService(
      db,
      loadAssetText: (_) async => '1|1|text',
      loadPageIndex: () async => <String, int>{'1:1': 1},
    );
    final metadataService = PageMetadataImporterService(
      db,
      loadPageIndex: (_) async => <String, int>{'1:1': 1},
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        quranTextImporterServiceProvider.overrideWithValue(textService),
        pageMetadataImporterServiceProvider.overrideWithValue(metadataService),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pump();

    final expectedSummary = AppStrings.of(AppLanguage.english)
        .guidedSetupMissingSummary(
          needsTextImport: false,
          needsPageMetadataImport: false,
          needsStarterPlan: true,
          needsStarterUnit: false,
        );

    expect(find.text(expectedSummary), findsOneWidget);
  });

  testWidgets(
      'guided setup does not show starter-plan repair for user-saved revision-only default-shaped plans',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final todayDay = localDayIndex(DateTime.now().toLocal());

    await _insertReadyAyah(db);
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
    await repo.saveSchedulingPreferences(
      preferences: await repo.getSchedulingPreferences(
        todayDayOverride: todayDay,
      ),
      updatedAtDay: todayDay,
    );
    await _insertMemUnitOnly(
      db,
      unitKey: 'user-saved-revision-only-default-shape',
      todayDay: todayDay,
    );

    final textService = QuranTextImporterService(
      db,
      loadAssetText: (_) async => '1|1|text',
      loadPageIndex: () async => <String, int>{'1:1': 1},
    );
    final metadataService = PageMetadataImporterService(
      db,
      loadPageIndex: (_) async => <String, int>{'1:1': 1},
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        quranTextImporterServiceProvider.overrideWithValue(textService),
        pageMetadataImporterServiceProvider.overrideWithValue(metadataService),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pump();

    final expectedSummary = AppStrings.of(AppLanguage.english)
        .guidedSetupMissingSummary(
          needsTextImport: false,
          needsPageMetadataImport: false,
          needsStarterPlan: false,
          needsStarterUnit: false,
        );

    expect(find.text(expectedSummary), findsOneWidget);
  });
}

String _encodeUnmarkedPreferences(SchedulingPreferencesV1 preferences) {
  final json = jsonDecode(preferences.encode()) as Map<String, dynamic>;
  json.remove('starterPlanSource');
  return jsonEncode(json);
}

Future<void> _insertReadyAyah(AppDatabase db) {
  return db.into(db.ayah).insert(
        AyahCompanion.insert(
          surah: 1,
          ayah: 1,
          textUthmani: 'existing',
          pageMadina: const Value(1),
        ),
      );
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
