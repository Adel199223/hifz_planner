import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/note_repo.dart';

void main() {
  late AppDatabase db;
  late NoteRepo repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = NoteRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('create and get note', () async {
    final id = await repo.createNote(
      surah: 1,
      ayah: 1,
      title: 'Start',
      body: 'Memorize this ayah',
    );

    final note = await repo.getNote(id);

    expect(note, isNotNull);
    expect(note!.title, 'Start');
    expect(note.body, 'Memorize this ayah');
  });

  test('getAllNotes returns rows ordered by updated_at descending', () async {
    final firstId = await repo.createNote(
      surah: 1,
      ayah: 1,
      title: 'First',
      body: 'First body',
    );
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final secondId = await repo.createNote(
      surah: 1,
      ayah: 2,
      title: 'Second',
      body: 'Second body',
    );

    final notes = await repo.getAllNotes();

    expect(notes.length, 2);
    expect(notes.first.id, secondId);
    expect(notes.last.id, firstId);
  });

  test('watchAllNotes emits updates after create and update', () async {
    final firstNonEmpty = repo.watchAllNotes().firstWhere(
          (items) => items.isNotEmpty,
        );

    final id = await repo.createNote(
      surah: 2,
      ayah: 3,
      title: null,
      body: 'Initial',
    );
    final created = await firstNonEmpty;

    expect(created.length, 1);
    expect(created.first.id, id);
    expect(created.first.body, 'Initial');

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final updatedStream = repo.watchAllNotes().firstWhere(
          (items) => items.any((row) => row.id == id && row.body == 'Updated'),
        );
    await repo.updateNote(
      id: id,
      title: 'Edited',
      body: 'Updated',
    );
    final updated = await updatedStream;

    expect(updated.first.id, id);
    expect(updated.first.title, 'Edited');
    expect(updated.first.body, 'Updated');
  });

  test('getNotesForAyah and watchNotesForAyah', () async {
    final stream = repo.watchNotesForAyah(surah: 2, ayah: 255);
    final pending = stream.firstWhere((items) => items.isNotEmpty);

    await repo.createNote(
      surah: 2,
      ayah: 255,
      title: null,
      body: 'Ayat al-Kursi note',
    );

    final emitted = await pending;
    final queried = await repo.getNotesForAyah(surah: 2, ayah: 255);

    expect(emitted.length, 1);
    expect(queried.length, 1);
    expect(queried.first.body, 'Ayat al-Kursi note');
  });

  test('updateNote updates body/title and bumps updated_at', () async {
    final id = await repo.createNote(
      surah: 3,
      ayah: 8,
      title: 'Before',
      body: 'Initial body',
    );
    final before = await repo.getNote(id);

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final updated = await repo.updateNote(
      id: id,
      title: 'After',
      body: 'Updated body',
    );
    final after = await repo.getNote(id);

    expect(updated, isTrue);
    expect(before, isNotNull);
    expect(after, isNotNull);
    expect(after!.title, 'After');
    expect(after.body, 'Updated body');
    expect(after.updatedAt.isAfter(before!.updatedAt), isTrue);
  });

  test('deleteNote removes a note', () async {
    final id = await repo.createNote(
      surah: 4,
      ayah: 1,
      title: null,
      body: 'Delete me',
    );

    final deleted = await repo.deleteNote(id);
    final note = await repo.getNote(id);

    expect(deleted, 1);
    expect(note, isNull);
  });
}
