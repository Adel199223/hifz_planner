import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/data/repositories/bookmark_repo.dart';
import 'package:hifz_planner/data/repositories/note_repo.dart';
import 'package:hifz_planner/data/services/tajweed_tags_service.dart';
import 'package:hifz_planner/screens/reader_screen.dart';

import '../helpers/pump_until_found.dart';

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
    expect(find.byKey(const ValueKey('surah_tile_1')), findsOneWidget);

    await tester.dragUntilVisible(
      find.byKey(const ValueKey('surah_tile_114')),
      surahList,
      const Offset(0, -350),
    );
    expect(find.byKey(const ValueKey('surah_tile_114')), findsOneWidget);

    await tester.dragUntilVisible(
      find.byKey(const ValueKey('surah_tile_2')),
      surahList,
      const Offset(0, 350),
    );
    await tester.tap(find.byKey(const ValueKey('surah_tile_2')));
    await tester.pumpAndSettle();

    expect(find.text('الم'), findsOneWidget);
    expect(find.text('ٱلْحَمْدُ لِلَّٰهِ'), findsNothing);
  });

  testWidgets('mode toggle switches to page mode and loads page ayahs', (
    tester,
  ) async {
    await _pumpReader(tester, db);

    final modeToggle = find.byKey(const ValueKey('reader_mode_toggle'));
    expect(modeToggle, findsOneWidget);
    expect(find.byKey(const ValueKey('reader_surah_list')), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: modeToggle,
        matching: find.text('Page Mode'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader_page_list')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader_page_label')), findsOneWidget);

    final page1Label = tester.widget<Text>(
      find.byKey(const ValueKey('reader_page_label')),
    );
    expect(page1Label.data, 'Page 1');

    await tester.tap(find.byKey(const ValueKey('reader_page_2')));
    await tester.pumpAndSettle();

    final page2Label = tester.widget<Text>(
      find.byKey(const ValueKey('reader_page_label')),
    );
    expect(page2Label.data, 'Page 2');

    expect(find.text('مَٰلِكِ يَوْمِ ٱلدِّينِ'), findsOneWidget);
    expect(find.text('الم'), findsOneWidget);
    expect(find.text('رَبِّ ٱلْعَٰلَمِينَ'), findsNothing);
  });

  testWidgets('page mode without metadata still exposes 1..604 page navigation',
      (tester) async {
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

    final pageList = find.byKey(const ValueKey('reader_page_list'));
    expect(pageList, findsOneWidget);
    expect(find.byKey(const ValueKey('reader_page_1')), findsOneWidget);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('reader_page_label')),
    );

    final page1Label = tester.widget<Text>(
      find.byKey(const ValueKey('reader_page_label')),
    );
    expect(page1Label.data, 'Page 1');

    await tester.tap(find.byKey(const ValueKey('reader_page_2')));
    await tester.pumpAndSettle();

    final page2Label = tester.widget<Text>(
      find.byKey(const ValueKey('reader_page_label')),
    );
    expect(page2Label.data, 'Page 2');
  });

  testWidgets('ayah rows use hover wrapper and RTL text', (
    tester,
  ) async {
    await _pumpReader(tester, db);

    expect(find.byType(MouseRegion), findsWidgets);

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

  testWidgets('tajweed toggle falls back to plain when mapping is empty', (
    tester,
  ) async {
    await _pumpReader(
      tester,
      db,
      tajweedTagsService: TajweedTagsService(
        loadAssetText: (_) async => '{}',
      ),
    );

    final renderToggle =
        find.byKey(const ValueKey('reader_arabic_render_toggle'));
    expect(renderToggle, findsOneWidget);

    await tester.tap(
      find.descendant(
        of: renderToggle,
        matching: find.text('Tajweed'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ٱلْحَمْدُ لِلَّٰهِ'), findsOneWidget);
    expect(tester.takeException(), equals(null));
  });

  testWidgets('tap opens actions and keeps sticky tap highlight',
      (tester) async {
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
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('ayah_row_1:1')),
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
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('ayah_row_1:1')),
    );

    await tester.tap(find.byKey(const ValueKey('ayah_row_1:1')));
    final copyActionFinder = find.byKey(const ValueKey('action_copy'));
    await pumpUntilFound(
      tester,
      copyActionFinder,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(copyActionFinder, warnIfMissed: false);
    await tester.pump();
    final copiedFeedback = find.byWidgetPredicate((widget) {
      if (widget is SnackBar) {
        return true;
      }
      if (widget is Text) {
        final text = widget.data;
        return text != null && text.contains('Copied');
      }
      return false;
    });
    await pumpUntilFound(
      tester,
      copiedFeedback,
      timeout: const Duration(seconds: 3),
    );

    expect(copiedFeedback, findsWidgets);
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
      await pumpUntilFound(
        tester,
        rowFinder,
        timeout: const Duration(seconds: 15),
      );
      expect(rowFinder, findsOneWidget);
      expect(materialFinder, findsOneWidget);
      await _pumpUntilAyahHighlighted(tester, materialFinder);

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
      await pumpUntilFound(
        tester,
        materialFinder,
      );
      expect(materialFinder, findsOneWidget);
      await _pumpUntilAyahHighlighted(tester, materialFinder);

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
  TajweedTagsService? tajweedTagsService,
}) async {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        if (tajweedTagsService != null)
          tajweedTagsServiceProvider.overrideWithValue(tajweedTagsService),
      ],
      child: MaterialApp(
        home: Scaffold(body: screen),
      ),
    ),
  );
  await tester.pump();
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('reader_mode_toggle')),
  );
}

Future<void> _pumpUntilAyahHighlighted(
  WidgetTester tester,
  Finder materialFinder, {
  Duration timeout = const Duration(seconds: 5),
  Duration step = const Duration(milliseconds: 50),
}) async {
  var elapsed = Duration.zero;
  while (elapsed <= timeout) {
    if (materialFinder.evaluate().isNotEmpty) {
      final material = tester.widget<Material>(materialFinder);
      if (material.color != Colors.transparent) {
        return;
      }
    }
    await tester.pump(step);
    elapsed += step;
  }

  throw TestFailure(
    'Timed out after ${timeout.inMilliseconds}ms waiting for highlight on $materialFinder.',
  );
}
