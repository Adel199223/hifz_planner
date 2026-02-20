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

  testWidgets('go to verse button navigates to reader target', (tester) async {
    final id = await _insertNote(
      db,
      surah: 3,
      ayah: 8,
      title: null,
      body: 'Navigate me',
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

    expect(find.text('Reader target 3:8'), findsOneWidget);
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
          final surah = state.uri.queryParameters['surah'] ?? '';
          final ayah = state.uri.queryParameters['ayah'] ?? '';
          return Scaffold(
            body: Center(
              child: Text('Reader target $surah:$ayah'),
            ),
          );
        },
      ),
    ],
  );
}
