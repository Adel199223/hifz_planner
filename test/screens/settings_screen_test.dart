import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/data/services/quran_text_importer_service.dart';
import 'package:hifz_planner/screens/settings_screen.dart';

void main() {
  testWidgets('renders Import Qur\'an Text button', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final service = QuranTextImporterService(
      db,
      loadAssetText: (_) async => '1|1|text',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          quranTextImporterServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );

    expect(find.text('Import Qur\'an Text'), findsOneWidget);
  });

  testWidgets(
    'tapping import button runs importer and updates progress/status',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final service = QuranTextImporterService(
        db,
        loadAssetText: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return '''
1|1|a
1|2|b
''';
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            quranTextImporterServiceProvider.overrideWithValue(service),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SettingsScreen()),
          ),
        ),
      );

      await tester.tap(find.text('Import Qur\'an Text'));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

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

    final service = QuranTextImporterService(
      db,
      loadAssetText: (_) async => '1|2|new',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          quranTextImporterServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );

    await tester.tap(find.text('Import Qur\'an Text'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Import skipped: ayah table already has data.'),
      findsWidgets,
    );
  });
}
