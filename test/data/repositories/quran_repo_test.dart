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
          ),
          AyahCompanion.insert(
            surah: 1,
            ayah: 1,
            textUthmani: 'بسم الله الرحمن الرحيم',
          ),
          AyahCompanion.insert(
            surah: 2,
            ayah: 1,
            textUthmani: 'الم',
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

    expect(result.length, 2);
    expect(result[0].ayah, 1);
    expect(result[1].ayah, 2);
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
}
