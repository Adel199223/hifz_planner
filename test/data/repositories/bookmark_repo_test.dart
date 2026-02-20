import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/bookmark_repo.dart';

void main() {
  late AppDatabase db;
  late BookmarkRepo repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = BookmarkRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('add and list bookmarks', () async {
    await repo.addBookmark(surah: 1, ayah: 1);
    await repo.addBookmark(surah: 2, ayah: 255);

    final bookmarks = await repo.getBookmarks();

    expect(bookmarks.length, 2);
    expect(
      bookmarks.any((b) => b.surah == 1 && b.ayah == 1),
      isTrue,
    );
    expect(
      bookmarks.any((b) => b.surah == 2 && b.ayah == 255),
      isTrue,
    );
  });

  test('getBookmarkByAyah returns matching row or null', () async {
    await repo.addBookmark(surah: 1, ayah: 5);

    final found = await repo.getBookmarkByAyah(surah: 1, ayah: 5);
    final missing = await repo.getBookmarkByAyah(surah: 1, ayah: 6);

    expect(found, isNotNull);
    expect(found!.surah, 1);
    expect(found.ayah, 5);
    expect(missing, isNull);
  });

  test('watchBookmarks emits new values', () async {
    final stream = repo.watchBookmarks();
    final pending = stream.firstWhere((items) => items.isNotEmpty);

    await repo.addBookmark(surah: 3, ayah: 18);

    final emitted = await pending;
    expect(emitted.length, 1);
    expect(emitted.first.surah, 3);
    expect(emitted.first.ayah, 18);
  });

  test('removeBookmark and removeBookmarkByAyah delete rows', () async {
    final firstId = await repo.addBookmark(surah: 1, ayah: 7);
    await repo.addBookmark(surah: 18, ayah: 10);

    final removedById = await repo.removeBookmark(firstId);
    final removedByAyah = await repo.removeBookmarkByAyah(surah: 18, ayah: 10);
    final remaining = await repo.getBookmarks();

    expect(removedById, 1);
    expect(removedByAyah, 1);
    expect(remaining, isEmpty);
  });
}
