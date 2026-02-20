import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/data/services/page_metadata_importer_service.dart';
import 'package:hifz_planner/data/services/quran_text_importer_service.dart';
import 'package:hifz_planner/screens/settings_screen.dart';

import '../helpers/pump_until_found.dart';

void main() {
  testWidgets('renders both import buttons', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final textService = QuranTextImporterService(
      db,
      loadAssetText: (_) async => '1|1|text',
    );
    final metadataService = PageMetadataImporterService(
      db,
      loadAssetText: (_) async => 'surah,ayah,page_madina\n1,1,1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          quranTextImporterServiceProvider.overrideWithValue(textService),
          pageMetadataImporterServiceProvider
              .overrideWithValue(metadataService),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );

    expect(find.text('Import Qur\'an Text'), findsOneWidget);
    expect(find.text('Import Page Metadata'), findsOneWidget);
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
      );
      final metadataService = PageMetadataImporterService(
        db,
        loadAssetText: (_) async => 'surah,ayah,page_madina\n1,1,1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            quranTextImporterServiceProvider.overrideWithValue(textService),
            pageMetadataImporterServiceProvider
                .overrideWithValue(metadataService),
          ],
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

  testWidgets('shows skipped message when data already exists', (tester) async {
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
    );
    final metadataService = PageMetadataImporterService(
      db,
      loadAssetText: (_) async => 'surah,ayah,page_madina\n1,1,1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          quranTextImporterServiceProvider.overrideWithValue(textService),
          pageMetadataImporterServiceProvider
              .overrideWithValue(metadataService),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );

    await tester.tap(find.text('Import Qur\'an Text'));
    await pumpUntilFound(
      tester,
      find.textContaining('Import skipped: ayah table already has data.'),
    );

    expect(
      find.textContaining('Import skipped: ayah table already has data.'),
      findsWidgets,
    );
  });

  testWidgets(
    'tapping page metadata button imports and shows completion summary',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await db.into(db.ayah).insert(
            AyahCompanion.insert(
              surah: 1,
              ayah: 1,
              textUthmani: 'verse',
            ),
          );

      final textService = QuranTextImporterService(
        db,
        loadAssetText: (_) async => '1|1|text',
      );
      final metadataService = PageMetadataImporterService(
        db,
        loadAssetText: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return '''
surah,ayah,page_madina
1,1,10
''';
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            quranTextImporterServiceProvider.overrideWithValue(textService),
            pageMetadataImporterServiceProvider
                .overrideWithValue(metadataService),
          ],
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
}
