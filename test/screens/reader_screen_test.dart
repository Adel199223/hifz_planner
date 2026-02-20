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

  testWidgets('ayah rows use hover wrapper, RTL text, and page badge', (
    tester,
  ) async {
    await _pumpReader(tester, db);

    expect(find.byType(MouseRegion), findsWidgets);
    expect(find.text('Page 1'), findsOneWidget);

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

  testWidgets('tapping ayah opens bottom sheet actions', (tester) async {
    await _pumpReader(tester, db);

    await tester.tap(find.byKey(const ValueKey('ayah_row_1:1')));
    await tester.pumpAndSettle();

    expect(find.text('Bookmark verse'), findsOneWidget);
    expect(find.text('Add/Edit note'), findsOneWidget);
    expect(find.text('Copy text (Uthmani)'), findsOneWidget);
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
        ),
        AyahCompanion.insert(
          surah: 2,
          ayah: 1,
          textUthmani: 'الم',
          pageMadina: const Value(2),
        ),
      ],
    );
  });
}

Future<void> _pumpReader(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ReaderScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
