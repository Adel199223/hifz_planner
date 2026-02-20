import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/screens/notes_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('renders notes list from stream', (tester) async {
    final id = await _insertNote(
      db,
      surah: 1,
      ayah: 3,
      title: 'Daily',
      body: 'Review this verse',
    );
    await _insertAyah(
      db,
      surah: 1,
      ayah: 3,
      textUthmani: 'Ayah',
      pageMadina: 7,
    );
    expect(id, greaterThan(0));

    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('notes_list')), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Review this verse'), findsOneWidget);
    expect(find.text('Surah 1, Ayah 3'), findsOneWidget);
    expect(find.byKey(ValueKey('note_page_$id')), findsOneWidget);
    expect(find.text('Page 7'), findsOneWidget);
  });

  testWidgets('editor saves updated title/body and validates empty body', (
    tester,
  ) async {
    final id = await _insertNote(
      db,
      surah: 2,
      ayah: 5,
      title: 'Old title',
      body: 'Old body',
    );

    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('note_row_$id')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('notes_editor_body_field')),
      '',
    );
    await tester.tap(find.byKey(const ValueKey('notes_editor_save_button')));
    await tester.pumpAndSettle();
    expect(find.text('Body is required.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('notes_editor_title_field')),
      'Updated title',
    );
    await tester.enterText(
      find.byKey(const ValueKey('notes_editor_body_field')),
      'Updated body',
    );
    await tester.tap(find.byKey(const ValueKey('notes_editor_save_button')));
    await tester.pumpAndSettle();

    final updated = await (db.select(db.note)..where((tbl) => tbl.id.equals(id)))
        .getSingle();
    expect(updated.title, 'Updated title');
    expect(updated.body, 'Updated body');
  });

  testWidgets('go to verse prefers page mode when page metadata exists', (
    tester,
  ) async {
    final id = await _insertNote(
      db,
      surah: 3,
      ayah: 8,
      title: null,
      body: 'Navigate me',
    );
    await _insertAyah(
      db,
      surah: 3,
      ayah: 8,
      textUthmani: 'Ayah',
      pageMadina: 77,
    );

    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('note_row_$id')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('notes_editor_go_button')));
    await tester.pumpAndSettle();

    expect(find.text('Reader route mode=page page=77 target=3:8'), findsOneWidget);
  });

  testWidgets('go to page button navigates to reader page target', (
    tester,
  ) async {
    final id = await _insertNote(
      db,
      surah: 18,
      ayah: 10,
      title: 'Cave',
      body: 'Navigate by page',
    );
    await _insertAyah(
      db,
      surah: 18,
      ayah: 10,
      textUthmani: 'Ayah',
      pageMadina: 294,
    );

    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('note_row_$id')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('notes_editor_go_page_button')));
    await tester.pumpAndSettle();

    expect(find.text('Reader route mode=page page=294 target=18:10'), findsOneWidget);
  });

  testWidgets('go to page button is disabled when page metadata is missing', (
    tester,
  ) async {
    final id = await _insertNote(
      db,
      surah: 55,
      ayah: 1,
      title: null,
      body: 'No page metadata',
    );

    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('note_row_$id')));
    await tester.pumpAndSettle();

    final goToPageButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('notes_editor_go_page_button')),
    );
    expect(goToPageButton.onPressed, isNull);
  });
}

Future<int> _insertNote(
  AppDatabase db, {
  required int surah,
  required int ayah,
  required String? title,
  required String body,
}) {
  return db.into(db.note).insert(
        NoteCompanion.insert(
          surah: surah,
          ayah: ayah,
          title: Value(title),
          body: body,
        ),
      );
}

Future<int> _insertAyah(
  AppDatabase db, {
  required int surah,
  required int ayah,
  required String textUthmani,
  int? pageMadina,
}) {
  return db.into(db.ayah).insert(
        AyahCompanion.insert(
          surah: surah,
          ayah: ayah,
          textUthmani: textUthmani,
          pageMadina: pageMadina == null ? const Value.absent() : Value(pageMadina),
        ),
      );
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/notes',
    routes: [
      GoRoute(
        path: '/notes',
        builder: (_, __) => const Scaffold(body: NotesScreen()),
      ),
      GoRoute(
        path: '/reader',
        builder: (_, state) {
          final params = state.uri.queryParameters;
          final mode = params['mode'] ?? 'none';
          final page = params['page'] ?? 'none';
          final surah = params['targetSurah'] ?? '';
          final ayah = params['targetAyah'] ?? '';
          return Scaffold(
            body: Center(
              child: Text(
                'Reader route mode=$mode page=$page target=$surah:$ayah',
              ),
            ),
          );
        },
      ),
    ],
  );
}
