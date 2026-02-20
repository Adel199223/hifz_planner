import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/data/repositories/bookmark_repo.dart';
import 'package:hifz_planner/data/repositories/note_repo.dart';
import 'package:hifz_planner/screens/reader_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await _seedAyahs(db);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('surah list supports 1..114 and selecting surah reloads ayahs', (
    tester,
  ) async {
    await _pumpReader(tester, db);

    final surahList = find.byKey(const ValueKey('reader_surah_list'));
    expect(find.text('Surah 1'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Surah 114'),
      surahList,
      const Offset(0, -350),
    );
    expect(find.text('Surah 114'), findsOneWidget);

    await tester.tap(find.text('Surah 2'));
    await tester.pumpAndSettle();

    expect(find.text('الم'), findsOneWidget);
    expect(find.text('ٱلْحَمْدُ لِلَّٰهِ'), findsNothing);
  });

  testWidgets('mode toggle switches to page mode and loads page ayahs', (
    tester,
  ) async {
    await _pumpReader(tester, db);

    expect(find.byKey(const ValueKey('reader_mode_toggle')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader_surah_list')), findsOneWidget);

    await tester.tap(find.text('Page Mode'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader_page_list')), findsOneWidget);
    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reader_page_2')));
    await tester.pumpAndSettle();

    expect(find.text('مَٰلِكِ يَوْمِ ٱلدِّينِ'), findsOneWidget);
    expect(find.text('الم'), findsOneWidget);
    expect(find.text('رَبِّ ٱلْعَٰلَمِينَ'), findsNothing);
  });

  testWidgets('page mode without metadata shows import prompt', (tester) async {
    final noMetadataDb = AppDatabase(NativeDatabase.memory());
    addTearDown(noMetadataDb.close);

    await noMetadataDb.into(noMetadataDb.ayah).insert(
          AyahCompanion.insert(
            surah: 1,
            ayah: 1,
            textUthmani: 'ٱلْحَمْدُ لِلَّٰهِ',
          ),
        );

    await _pumpReader(
      tester,
      noMetadataDb,
      screen: const ReaderScreen(mode: 'page'),
    );

    expect(
      find.text('No page metadata found. Import Page Metadata in Settings.'),
      findsWidgets,
    );
  });

  testWidgets('ayah rows use hover wrapper, RTL text, and page badge', (
    tester,
  ) async {
    await _pumpReader(tester, db);

    expect(find.byType(MouseRegion), findsWidgets);
    expect(find.text('Page 1'), findsWidgets);

    final rtlAncestor = find.ancestor(
      of: find.text('ٱلْحَمْدُ لِلَّٰهِ'),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Directionality &&
            widget.textDirection == TextDirection.rtl,
      ),
    );
    expect(rtlAncestor, findsOneWidget);
  });

  testWidgets('tap opens actions and keeps sticky tap highlight', (tester) async {
    await _pumpReader(tester, db);

    await tester.tap(find.byKey(const ValueKey('ayah_row_1:1')));
    await tester.pumpAndSettle();

    expect(find.text('Bookmark verse'), findsOneWidget);
    expect(find.text('Add/Edit note'), findsOneWidget);
    expect(find.text('Copy text (Uthmani)'), findsOneWidget);

    final row11BeforeClose = tester.widget<Material>(
      find.byKey(const ValueKey('ayah_material_1:1')),
    );
    expect(row11BeforeClose.color, isNot(Colors.transparent));

    await tester.tap(find.text('Copy text (Uthmani)'));
    await tester.pumpAndSettle();

    final row11AfterClose = tester.widget<Material>(
      find.byKey(const ValueKey('ayah_material_1:1')),
    );
    expect(row11AfterClose.color, isNot(Colors.transparent));

    await tester.tap(find.byKey(const ValueKey('ayah_row_1:2')));
    await tester.pumpAndSettle();

    final row11AfterSecondTap = tester.widget<Material>(
      find.byKey(const ValueKey('ayah_material_1:1')),
    );
    final row12AfterSecondTap = tester.widget<Material>(
      find.byKey(const ValueKey('ayah_material_1:2')),
    );
    expect(row11AfterSecondTap.color, Colors.transparent);
    expect(row12AfterSecondTap.color, isNot(Colors.transparent));
  });

  testWidgets('range highlight marks rows inside inclusive verse range', (
    tester,
  ) async {
    await _pumpReader(
      tester,
      db,
      screen: const ReaderScreen(
        highlightStartSurah: 1,
        highlightStartAyah: 2,
        highlightEndSurah: 2,
        highlightEndAyah: 1,
      ),
    );

    final row11 = tester.widget<Material>(
      find.byKey(const ValueKey('ayah_material_1:1')),
    );
    final row12 = tester.widget<Material>(
      find.byKey(const ValueKey('ayah_material_1:2')),
    );
    final row13 = tester.widget<Material>(
      find.byKey(const ValueKey('ayah_material_1:3')),
    );

    expect(row11.color, Colors.transparent);
    expect(row12.color, isNot(Colors.transparent));
    expect(row13.color, isNot(Colors.transparent));
  });

  testWidgets('bookmark action persists once and does not duplicate', (
    tester,
  ) async {
    final repo = BookmarkRepo(db);
    await _pumpReader(tester, db);

    await tester.tap(find.byKey(const ValueKey('ayah_row_1:1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bookmark verse'));
    await tester.pumpAndSettle();

    final firstCount = await repo.getBookmarks();
    expect(firstCount.length, 1);

    await tester.tap(find.byKey(const ValueKey('ayah_row_1:1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bookmark verse'));
    await tester.pumpAndSettle();

    final secondCount = await repo.getBookmarks();
    expect(secondCount.length, 1);
  });

  testWidgets('actions remain functional in page mode', (tester) async {
    final repo = BookmarkRepo(db);
    await _pumpReader(
      tester,
      db,
      screen: const ReaderScreen(mode: 'page', page: 1),
    );

    await tester.tap(find.byKey(const ValueKey('ayah_row_1:1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bookmark verse'));
    await tester.pumpAndSettle();

    final bookmarks = await repo.getBookmarks();
    expect(bookmarks.length, 1);
    expect(bookmarks.first.surah, 1);
    expect(bookmarks.first.ayah, 1);
  });

  testWidgets('add/edit note creates then updates single note', (tester) async {
    final noteRepo = NoteRepo(db);
    await _pumpReader(tester, db);

    await tester.tap(find.byKey(const ValueKey('ayah_row_1:1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add/Edit note'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('note_body_field')),
      'First note',
    );
    await tester.tap(find.byKey(const ValueKey('note_save_button')));
    await tester.pumpAndSettle();

    final notesAfterCreate = await noteRepo.getNotesForAyah(surah: 1, ayah: 1);
    expect(notesAfterCreate.length, 1);
    expect(notesAfterCreate.first.body, 'First note');

    await tester.tap(find.byKey(const ValueKey('ayah_row_1:1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add/Edit note'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('note_body_field')),
      'Updated note',
    );
    await tester.tap(find.byKey(const ValueKey('note_save_button')));
    await tester.pumpAndSettle();

    final notesAfterUpdate = await noteRepo.getNotesForAyah(surah: 1, ayah: 1);
    expect(notesAfterUpdate.length, 1);
    expect(notesAfterUpdate.first.body, 'Updated note');
  });

  testWidgets('copy action copies text and shows feedback', (tester) async {
    await _pumpReader(tester, db);

    await tester.tap(find.byKey(const ValueKey('ayah_row_1:1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy text (Uthmani)'));
    await tester.pumpAndSettle();

    final copied = await Clipboard.getData(Clipboard.kTextPlain);
    expect(copied?.text, 'ٱلْحَمْدُ لِلَّٰهِ');
    expect(find.text('Copied verse text.'), findsOneWidget);
  });

  testWidgets(
    'route target loads surah, jumps to ayah, and clears jump highlight',
    (tester) async {
      await db.batch((batch) {
        batch.insertAll(
          db.ayah,
          [
            for (var i = 4; i <= 40; i++)
              AyahCompanion.insert(
                surah: 1,
                ayah: i,
                textUthmani: 'ayah $i',
              ),
          ],
          mode: InsertMode.insertOrIgnore,
        );
      });

      await _pumpReader(
        tester,
        db,
        screen: const ReaderScreen(
          targetSurah: 1,
          targetAyah: 30,
        ),
      );

      final rowFinder = find.byKey(const ValueKey('ayah_row_1:30'));
      final materialFinder = find.byKey(const ValueKey('ayah_material_1:30'));
      expect(rowFinder, findsOneWidget);
      expect(materialFinder, findsOneWidget);

      final highlightedMaterial = tester.widget<Material>(materialFinder);
      expect(highlightedMaterial.color, isNot(Colors.transparent));

      await tester.pump(const Duration(milliseconds: 1700));

      final clearedMaterial = tester.widget<Material>(materialFinder);
      expect(clearedMaterial.color, Colors.transparent);
    },
  );

  testWidgets(
    'page mode target jump highlights row then clears',
    (tester) async {
      await _pumpReader(
        tester,
        db,
        screen: const ReaderScreen(
          mode: 'page',
          page: 2,
          targetSurah: 1,
          targetAyah: 3,
        ),
      );

      final materialFinder = find.byKey(const ValueKey('ayah_material_1:3'));
      expect(materialFinder, findsOneWidget);

      final highlightedMaterial = tester.widget<Material>(materialFinder);
      expect(highlightedMaterial.color, isNot(Colors.transparent));

      await tester.pump(const Duration(milliseconds: 1700));

      final clearedMaterial = tester.widget<Material>(materialFinder);
      expect(clearedMaterial.color, Colors.transparent);
    },
  );
}

Future<void> _seedAyahs(AppDatabase db) async {
  await db.batch((batch) {
    batch.insertAll(
      db.ayah,
      [
        AyahCompanion.insert(
          surah: 1,
          ayah: 1,
          textUthmani: 'ٱلْحَمْدُ لِلَّٰهِ',
          pageMadina: const Value(1),
        ),
        AyahCompanion.insert(
          surah: 1,
          ayah: 2,
          textUthmani: 'رَبِّ ٱلْعَٰلَمِينَ',
          pageMadina: const Value(1),
        ),
        AyahCompanion.insert(
          surah: 1,
          ayah: 3,
          textUthmani: 'مَٰلِكِ يَوْمِ ٱلدِّينِ',
          pageMadina: const Value(2),
        ),
        AyahCompanion.insert(
          surah: 2,
          ayah: 1,
          textUthmani: 'الم',
          pageMadina: const Value(2),
        ),
        AyahCompanion.insert(
          surah: 2,
          ayah: 2,
          textUthmani: 'ذَٰلِكَ ٱلْكِتَٰبُ',
          pageMadina: const Value(3),
        ),
      ],
    );
  });
}

Future<void> _pumpReader(
  WidgetTester tester,
  AppDatabase db, {
  ReaderScreen screen = const ReaderScreen(),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp(
        home: Scaffold(body: screen),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
