import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('creates ayah, bookmark, and note tables', () async {
    final result = await db.customSelect('''
      SELECT name FROM sqlite_master
      WHERE type = 'table'
    ''').get();

    final tableNames = result.map((row) => row.read<String>('name')).toSet();

    expect(tableNames.contains('ayah'), isTrue);
    expect(tableNames.contains('bookmark'), isTrue);
    expect(tableNames.contains('note'), isTrue);
  });

  test('enforces unique(surah, ayah) on ayah table', () async {
    await db.into(db.ayah).insert(
          AyahCompanion.insert(
            surah: 1,
            ayah: 1,
            textUthmani: 'In the name of Allah',
          ),
        );

    await expectLater(
      db.into(db.ayah).insert(
            AyahCompanion.insert(
              surah: 1,
              ayah: 1,
              textUthmani: 'Duplicate ayah should fail',
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });
}
