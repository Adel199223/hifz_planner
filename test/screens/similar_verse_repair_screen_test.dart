import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/l10n/app_language.dart';
import 'package:hifz_planner/l10n/app_strings.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/screens/similar_verse_repair_screen.dart';

void main() {
  testWidgets('renders confident similar-verse candidates with a cue',
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

    await _insertAyah(
      db,
      surah: 1,
      ayah: 1,
      text:
          'قالوا امنا بالله وباليوم الاخر وما هم بمؤمنين ثم رجعوا خاشعين',
      pageMadina: 1,
    );
    await _insertAyah(
      db,
      surah: 1,
      ayah: 2,
      text:
          'قالوا امنا بالله وباليوم الاخر وما هم بمسلمين ثم رجعوا خاشعين',
      pageMadina: 2,
    );
    final unitId = await _insertUnit(
      db,
      unitKey: 'repair-target',
      startAyah: 1,
      endAyah: 1,
      pageMadina: 1,
    );
    await _insertUnit(
      db,
      unitKey: 'repair-candidate',
      startAyah: 2,
      endAyah: 2,
      pageMadina: 2,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: SimilarVerseRepairScreen(unitId: unitId),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final strings = AppStrings.of(AppLanguage.english);
    expect(
      find.byKey(const ValueKey('similar_verse_repair_screen')),
      findsOneWidget,
    );
    expect(find.byType(AppBar), findsNothing);
    expect(find.text(strings.similarVerseRescueTitle), findsOneWidget);
    expect(
      find.byKey(const ValueKey('similar_verse_candidate_2')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('similar_verse_cue_2')), findsOneWidget);
    expect(find.textContaining('They begin similarly'), findsOneWidget);
    expect(
      find.byKey(ValueKey('similar_verse_open_reader_$unitId')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('similar_verse_open_reader_2')),
      findsOneWidget,
    );
  });

  testWidgets('renders an honest no-candidate state when no strong match exists',
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

    await _insertAyah(
      db,
      surah: 1,
      ayah: 1,
      text: 'واذ قال ربك للملائكة اني جاعل في الارض خليفة',
      pageMadina: 1,
    );
    await _insertAyah(
      db,
      surah: 1,
      ayah: 2,
      text: 'الحمد لله رب العالمين الرحمن الرحيم مالك يوم الدين',
      pageMadina: 10,
    );
    final unitId = await _insertUnit(
      db,
      unitKey: 'repair-target-weak',
      startAyah: 1,
      endAyah: 1,
      pageMadina: 1,
    );
    await _insertUnit(
      db,
      unitKey: 'repair-candidate-weak',
      startAyah: 2,
      endAyah: 2,
      pageMadina: 10,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: SimilarVerseRepairScreen(unitId: unitId),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final strings = AppStrings.of(AppLanguage.english);
    expect(find.byType(AppBar), findsNothing);
    expect(find.text(strings.similarVerseRescueTitle), findsOneWidget);
    expect(
      find.byKey(const ValueKey('similar_verse_repair_no_candidate')),
      findsOneWidget,
    );
    expect(
      find.text('No strong similar match yet'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('similar_verse_target_card')), findsOneWidget);
    expect(
      find.byKey(ValueKey('similar_verse_open_reader_$unitId')),
      findsOneWidget,
    );
  });

  testWidgets('renders shell-friendly invalid content for a missing unit id',
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SimilarVerseRepairScreen(unitId: null),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final strings = AppStrings.of(AppLanguage.english);
    expect(
      find.byKey(const ValueKey('similar_verse_repair_screen')),
      findsOneWidget,
    );
    expect(find.byType(AppBar), findsNothing);
    expect(find.text(strings.similarVerseRescueTitle), findsOneWidget);
    expect(
      find.byKey(const ValueKey('similar_verse_repair_invalid')),
      findsOneWidget,
    );
  });
}

Future<void> _insertAyah(
  AppDatabase db, {
  required int surah,
  required int ayah,
  required String text,
  required int pageMadina,
}) async {
  await db.into(db.ayah).insert(
        AyahCompanion.insert(
          surah: surah,
          ayah: ayah,
          textUthmani: text,
          pageMadina: Value(pageMadina),
        ),
      );
}

Future<int> _insertUnit(
  AppDatabase db, {
  required String unitKey,
  required int startAyah,
  required int endAyah,
  required int pageMadina,
}) {
  return db.into(db.memUnit).insert(
        MemUnitCompanion.insert(
          kind: 'ayah_range',
          pageMadina: Value(pageMadina),
          startSurah: const Value(1),
          startAyah: Value(startAyah),
          endSurah: const Value(1),
          endAyah: Value(endAyah),
          unitKey: unitKey,
          createdAtDay: 100,
          updatedAtDay: 100,
        ),
      );
}
