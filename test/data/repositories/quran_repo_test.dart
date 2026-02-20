import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/quran_repo.dart';

void main() {
  late AppDatabase db;
  late QuranRepo repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = QuranRepo(db);

    await db.batch((batch) {
      batch.insertAll(
        db.ayah,
        [
          AyahCompanion.insert(
            surah: 1,
            ayah: 2,
            textUthmani: 'الحمد لله رب العالمين',
            pageMadina: const Value(5),
          ),
          AyahCompanion.insert(
            surah: 1,
            ayah: 1,
            textUthmani: 'بسم الله الرحمن الرحيم',
            pageMadina: const Value(5),
          ),
          AyahCompanion.insert(
            surah: 2,
            ayah: 1,
            textUthmani: 'الم',
            pageMadina: const Value(10),
          ),
          AyahCompanion.insert(
            surah: 1,
            ayah: 3,
            textUthmani: 'مالك يوم الدين',
            pageMadina: const Value(10),
          ),
          AyahCompanion.insert(
            surah: 2,
            ayah: 2,
            textUthmani: 'ذلك الكتاب لا ريب فيه',
          ),
        ],
      );
    });
  });

  tearDown(() async {
    await db.close();
  });

  test('getAyahsBySurah returns rows ordered by ayah', () async {
    final result = await repo.getAyahsBySurah(1);

    expect(result.length, 3);
    expect(result[0].ayah, 1);
    expect(result[1].ayah, 2);
    expect(result[2].ayah, 3);
  });

  test('searchAyahs finds matches and returns empty for empty query', () async {
    final matched = await repo.searchAyahs('الله');
    final empty = await repo.searchAyahs('   ');

    expect(matched, isNotEmpty);
    expect(matched.every((item) => item.textUthmani.contains('الله')), isTrue);
    expect(empty, isEmpty);
  });

  test('getAyah returns exact match or null', () async {
    final found = await repo.getAyah(2, 1);
    final missing = await repo.getAyah(2, 255);

    expect(found, isNotNull);
    expect(found!.textUthmani, 'الم');
    expect(missing, isNull);
  });

  test('getPagesAvailable returns distinct sorted non-null pages', () async {
    final pages = await repo.getPagesAvailable();

    expect(pages, <int>[5, 10]);
  });

  test('getAyahsByPage returns rows ordered by surah and ayah', () async {
    final pageRows = await repo.getAyahsByPage(10);

    expect(pageRows.length, 2);
    expect(pageRows[0].surah, 1);
    expect(pageRows[0].ayah, 3);
    expect(pageRows[1].surah, 2);
    expect(pageRows[1].ayah, 1);
  });

  test('getAyahsFromCursor includes cursor ayah in canonical order', () async {
    final rows = await repo.getAyahsFromCursor(
      startSurah: 1,
      startAyah: 2,
    );
    final limited = await repo.getAyahsFromCursor(
      startSurah: 1,
      startAyah: 2,
      limit: 2,
    );

    expect(
      rows.map((row) => '${row.surah}:${row.ayah}').toList(),
      ['1:2', '1:3', '2:1', '2:2'],
    );
    expect(
      limited.map((row) => '${row.surah}:${row.ayah}').toList(),
      ['1:2', '1:3'],
    );
  });

  test('countAyahsInRange returns inclusive range count', () async {
    final count = await repo.countAyahsInRange(
      startSurah: 1,
      startAyah: 2,
      endSurah: 2,
      endAyah: 1,
    );
    final reversed = await repo.countAyahsInRange(
      startSurah: 2,
      startAyah: 2,
      endSurah: 1,
      endAyah: 1,
    );

    expect(count, 3);
    expect(reversed, 0);
  });

  test('getLastAyah returns highest surah/ayah pair', () async {
    final last = await repo.getLastAyah();

    expect(last, isNotNull);
    expect(last!.surah, 2);
    expect(last.ayah, 2);
  });
}
