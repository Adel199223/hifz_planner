import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/data/repositories/bookmark_repo.dart';
import 'package:hifz_planner/data/repositories/note_repo.dart';
import 'package:hifz_planner/data/services/qurancom_api.dart';
import 'package:hifz_planner/data/services/tajweed_tags_service.dart';
import 'package:hifz_planner/screens/reader_screen.dart';
import 'package:hifz_planner/ui/qcf/qcf_font_manager.dart';

import '../helpers/pump_until_found.dart';

void main() {
  testWidgets('surah list supports 1..114 and selecting surah reloads ayahs', (
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
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);

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
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);

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
    _registerPumpCleanup(tester);

    await db.into(db.ayah).insert(
          AyahCompanion.insert(
            surah: 1,
            ayah: 1,
            textUthmani: 'ٱلْحَمْدُ لِلَّٰهِ',
          ),
        );

    await _pumpReader(
      tester,
      container,
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
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);

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
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        tajweedTagsServiceProvider.overrideWithValue(
          TajweedTagsService(
            loadAssetText: (_) async => '{}',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(
      tester,
      container,
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
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);

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
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(
      tester,
      container,
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
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    final repo = BookmarkRepo(db);
    await _pumpReader(tester, container);

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
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    final repo = BookmarkRepo(db);
    await _pumpReader(
      tester,
      container,
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
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    final noteRepo = NoteRepo(db);
    await _pumpReader(tester, container);

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
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
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
      _registerPumpCleanup(tester);

      await _seedAyahs(db);
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
        container,
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
      _registerPumpCleanup(tester);

      await _seedAyahs(db);
      await _pumpReader(
        tester,
        container,
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

  testWidgets('mushaf mode renders fixed 15 lines', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('reader_view_toggle')),
        matching: find.text('Mushaf (Quran.com)'),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 1; i <= 15; i++) {
      expect(find.byKey(ValueKey('reader_mushaf_line_$i')), findsOneWidget);
    }
  });

  testWidgets('mushaf plain uses mushaf=1 and v2 font', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('reader_view_toggle')),
        matching: find.text('Mushaf (Quran.com)'),
      ),
    );
    await tester.pumpAndSettle();

    expect(fakeApi.calls, isNotEmpty);
    expect(fakeApi.calls.last.mushafId, 1);
    expect(fakeFonts.calls, isNotEmpty);
    expect(fakeFonts.calls.last.variant, QcfFontVariant.v2);
  });

  testWidgets('mushaf tajweed uses mushaf=19 and v4 font', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('reader_view_toggle')),
        matching: find.text('Mushaf (Quran.com)'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('reader_arabic_render_toggle')),
        matching: find.text('Tajweed'),
      ),
    );
    await tester.pumpAndSettle();

    expect(fakeApi.calls.last.mushafId, 19);
    expect(fakeFonts.calls.last.variant, QcfFontVariant.v4tajweed);
  });

  testWidgets('mushaf uses QCF font for code_v2 end token', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('reader_view_toggle')),
        matching: find.text('Mushaf (Quran.com)'),
      ),
    );
    await tester.pumpAndSettle();

    final richText = find.descendant(
      of: find.byKey(const ValueKey('reader_mushaf_line_1')),
      matching: find.byType(RichText),
    );
    expect(richText, findsOneWidget);

    final rendered = tester.widget<RichText>(richText);
    final rootSpan = rendered.text as TextSpan;
    final spans = rootSpan.children!.cast<TextSpan>().toList(growable: false);
    final endSpan = spans.firstWhere((span) => span.text == '۝');
    expect(endSpan.style?.fontFamily, 'qcf_test_family');
  });

  testWidgets('each mushaf line renders as one RichText', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('reader_view_toggle')),
        matching: find.text('Mushaf (Quran.com)'),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 1; i <= 15; i++) {
      final lineFinder = find.byKey(ValueKey('reader_mushaf_line_$i'));
      final richTexts =
          find.descendant(of: lineFinder, matching: find.byType(RichText));
      expect(richTexts, findsOneWidget);
    }
  });

  testWidgets('mushaf typography scales proportionally with viewport height',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1200, 700));

    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    final smallFontSize = _lineQcfFontSize(
      tester,
      lineNumber: 1,
      familyName: 'qcf_test_family',
    );

    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    await tester.pumpAndSettle();

    final largeFontSize = _lineQcfFontSize(
      tester,
      lineNumber: 1,
      familyName: 'qcf_test_family',
    );

    expect(largeFontSize, greaterThan(smallFontSize));
    expect(smallFontSize, isNot(closeTo(38.0, 0.1)));
  });

  testWidgets('mushaf dense non-centered line applies positive QCF spacing',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(720, 820));

    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(
      _buildSpacingMushafDataFixture(),
    );
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToPageMode(tester);
    await _switchToMushafView(tester);
    await tester.tap(find.byKey(const ValueKey('reader_page_3')));
    await tester.pumpAndSettle();

    expect(
      _lineAlignment(tester, lineNumber: 1),
      Alignment.centerRight,
    );

    final spacing = _lineQcfLetterSpacing(
      tester,
      lineNumber: 1,
      familyName: 'qcf_test_family',
    );
    expect(spacing, isNot(equals(null)));
    expect(spacing!, greaterThan(0.0));
  });

  testWidgets('mushaf center map centers page 2 and not page 3 line 1',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1200, 900));

    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(
      _buildDenseMushafDataFixture(denseWordCount: 80),
    );
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToPageMode(tester);
    await _switchToMushafView(tester);
    await tester.tap(find.byKey(const ValueKey('reader_page_2')));
    await tester.pumpAndSettle();

    expect(
      _lineAlignment(tester, lineNumber: 1),
      Alignment.center,
    );

    await tester.tap(find.byKey(const ValueKey('reader_page_3')));
    await tester.pumpAndSettle();

    expect(
      _lineAlignment(tester, lineNumber: 1),
      Alignment.centerRight,
    );
  });
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

MushafPageData _buildMushafDataFixture() {
  final words = <MushafWord>[];
  for (var line = 1; line <= 15; line++) {
    words.add(
      MushafWord(
        codeV2: line == 1 ? '۝' : 'C$line',
        textQpcHafs: line == 1 ? 'END' : 'W$line',
        charTypeName: line == 1 ? 'end' : 'word',
        lineNumber: line,
        position: line,
        pageNumber: 1,
      ),
    );
    words.add(
      MushafWord(
        codeV2: '',
        textQpcHafs: 'T$line',
        charTypeName: 'word',
        lineNumber: line,
        position: line + 100,
        pageNumber: 1,
      ),
    );
  }
  return MushafPageData(
    words: words,
    meta: const MushafPageMeta(
      firstChapterId: 2,
      firstVerseNumber: 1,
      firstVerseKey: '2:1',
    ),
  );
}

MushafPageData _buildDenseMushafDataFixture({required int denseWordCount}) {
  final words = <MushafWord>[];
  for (var i = 0; i < denseWordCount; i++) {
    words.add(
      MushafWord(
        codeV2: 'G',
        textQpcHafs: 'G',
        charTypeName: 'word',
        lineNumber: 1,
        position: i + 1,
        pageNumber: 3,
      ),
    );
  }
  for (var line = 2; line <= 15; line++) {
    words.add(
      MushafWord(
        codeV2: 'C$line',
        textQpcHafs: 'W$line',
        charTypeName: 'word',
        lineNumber: line,
        position: line + 100,
        pageNumber: 3,
      ),
    );
  }
  return MushafPageData(
    words: words,
    meta: const MushafPageMeta(
      firstChapterId: 2,
      firstVerseNumber: 2,
      firstVerseKey: '2:2',
    ),
  );
}

MushafPageData _buildSpacingMushafDataFixture() {
  final words = <MushafWord>[
    const MushafWord(
      codeV2: 'G',
      textQpcHafs: 'G',
      charTypeName: 'word',
      lineNumber: 1,
      position: 1,
      pageNumber: 3,
    ),
    const MushafWord(
      codeV2: '',
      textQpcHafs: 'iiiiiiii',
      charTypeName: 'word',
      lineNumber: 1,
      position: 2,
      pageNumber: 3,
    ),
    const MushafWord(
      codeV2: '',
      textQpcHafs: 'iiiiiiii',
      charTypeName: 'word',
      lineNumber: 1,
      position: 3,
      pageNumber: 3,
    ),
    const MushafWord(
      codeV2: 'G',
      textQpcHafs: 'G',
      charTypeName: 'word',
      lineNumber: 1,
      position: 4,
      pageNumber: 3,
    ),
  ];
  for (var line = 2; line <= 15; line++) {
    words.add(
      MushafWord(
        codeV2: 'C$line',
        textQpcHafs: 'W$line',
        charTypeName: 'word',
        lineNumber: line,
        position: line + 100,
        pageNumber: 3,
      ),
    );
  }
  return MushafPageData(
    words: words,
    meta: const MushafPageMeta(
      firstChapterId: 2,
      firstVerseNumber: 2,
      firstVerseKey: '2:2',
    ),
  );
}

class _FakeQuranComApiCall {
  const _FakeQuranComApiCall({
    required this.page,
    required this.mushafId,
  });

  final int page;
  final int mushafId;
}

class _FakeQuranComApi extends QuranComApi {
  _FakeQuranComApi.withData(this._data);

  final MushafPageData _data;
  final List<_FakeQuranComApiCall> calls = <_FakeQuranComApiCall>[];

  @override
  Future<MushafPageData> getPage({
    required int page,
    required int mushafId,
  }) async {
    calls.add(_FakeQuranComApiCall(page: page, mushafId: mushafId));
    return _data;
  }
}

class _FakeQcfFontCall {
  const _FakeQcfFontCall({
    required this.page,
    required this.variant,
  });

  final int page;
  final QcfFontVariant variant;
}

class _FakeQcfFontManager extends QcfFontManager {
  _FakeQcfFontManager({
    required this.familyName,
  });

  final String familyName;
  final List<_FakeQcfFontCall> calls = <_FakeQcfFontCall>[];

  @override
  Future<QcfFontSelection> ensurePageFont({
    required int page,
    required QcfFontVariant variant,
  }) async {
    calls.add(_FakeQcfFontCall(page: page, variant: variant));
    return QcfFontSelection(
      familyName: familyName,
      requestedVariant: variant,
      effectiveVariant: variant,
    );
  }
}

Future<void> _pumpReader(
  WidgetTester tester,
  ProviderContainer container, {
  ReaderScreen screen = const ReaderScreen(),
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
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

Future<void> _switchToMushafView(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const ValueKey('reader_view_toggle')),
      matching: find.text('Mushaf (Quran.com)'),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _switchToPageMode(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const ValueKey('reader_mode_toggle')),
      matching: find.text('Page Mode'),
    ),
  );
  await tester.pumpAndSettle();
}

Alignment _lineAlignment(
  WidgetTester tester, {
  required int lineNumber,
}) {
  final lineFinder = find.byKey(ValueKey('reader_mushaf_line_$lineNumber'));
  final alignFinder =
      find.descendant(of: lineFinder, matching: find.byType(Align));
  expect(alignFinder, findsOneWidget);
  return tester.widget<Align>(alignFinder).alignment as Alignment;
}

TextSpan _lineRootSpan(
  WidgetTester tester, {
  required int lineNumber,
}) {
  final lineFinder = find.byKey(ValueKey('reader_mushaf_line_$lineNumber'));
  final richTextFinder =
      find.descendant(of: lineFinder, matching: find.byType(RichText));
  expect(richTextFinder, findsOneWidget);
  final richText = tester.widget<RichText>(richTextFinder);
  return richText.text as TextSpan;
}

double _lineQcfFontSize(
  WidgetTester tester, {
  required int lineNumber,
  required String familyName,
}) {
  final rootSpan = _lineRootSpan(tester, lineNumber: lineNumber);
  final spans = rootSpan.children!.cast<TextSpan>().toList(growable: false);
  final qcfSpan = spans.firstWhere(
    (span) => span.style?.fontFamily == familyName,
  );
  return qcfSpan.style!.fontSize!;
}

double? _lineQcfLetterSpacing(
  WidgetTester tester, {
  required int lineNumber,
  required String familyName,
}) {
  final rootSpan = _lineRootSpan(tester, lineNumber: lineNumber);
  final spans = rootSpan.children!.cast<TextSpan>().toList(growable: false);
  final qcfSpan = spans.firstWhere(
    (span) => span.style?.fontFamily == familyName,
  );
  return qcfSpan.style?.letterSpacing;
}

void _registerPumpCleanup(WidgetTester tester) {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
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
