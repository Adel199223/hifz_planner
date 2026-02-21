import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/services/quran_text_importer_service.dart';
import 'package:hifz_planner/data/services/madani_page_index_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('imports valid Tanzil lines into ayah table', () async {
    final importer = QuranTextImporterService(
      db,
      loadAssetText: (_) async => '''
1|1|بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
1|2|الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ
2|1|الم|extra pipe kept
''',
      loadPageIndex: () async => <String, int>{
        verseKey(1, 1): 1,
        verseKey(1, 2): 1,
        verseKey(2, 1): 2,
      },
    );

    final result = await importer.importFromAsset();
    final rows = await (db.select(db.ayah)
          ..orderBy([
            (t) => OrderingTerm.asc(t.surah),
            (t) => OrderingTerm.asc(t.ayah),
          ]))
        .get();

    expect(result.skipped, isFalse);
    expect(result.parsedRows, 3);
    expect(result.insertedRows, 3);
    expect(result.ignoredRows, 0);
    expect(rows.length, 3);
    expect(rows[2].textUthmani, 'الم|extra pipe kept');
    expect(rows.every((row) => row.pageMadina != null), isTrue);
  });

  test('skips import when ayah table has data and force is false', () async {
    await db.into(db.ayah).insert(
          AyahCompanion.insert(
            surah: 1,
            ayah: 1,
            textUthmani: 'existing',
          ),
        );

    var loaderCalled = false;
    var pageLoaderCalled = false;
    final importer = QuranTextImporterService(
      db,
      loadAssetText: (_) async {
        loaderCalled = true;
        return '1|2|new';
      },
      loadPageIndex: () async {
        pageLoaderCalled = true;
        return <String, int>{verseKey(1, 2): 1};
      },
    );

    final result = await importer.importFromAsset(force: false);

    expect(result.skipped, isTrue);
    expect(result.existingBefore, 1);
    expect(result.parsedRows, 0);
    expect(result.insertedRows, 0);
    expect(loaderCalled, isFalse);
    expect(pageLoaderCalled, isFalse);
  });

  test('force import proceeds and ignores duplicates', () async {
    await db.into(db.ayah).insert(
          AyahCompanion.insert(
            surah: 1,
            ayah: 1,
            textUthmani: 'existing',
          ),
        );

    final importer = QuranTextImporterService(
      db,
      loadAssetText: (_) async => '''
1|1|duplicate
1|2|new row
''',
      loadPageIndex: () async => <String, int>{
        verseKey(1, 1): 1,
        verseKey(1, 2): 1,
      },
    );

    final result = await importer.importFromAsset(force: true);
    final countRow =
        await db.customSelect('SELECT COUNT(*) AS c FROM ayah').getSingle();

    expect(result.skipped, isFalse);
    expect(result.existingBefore, 1);
    expect(result.parsedRows, 2);
    expect(result.insertedRows, 1);
    expect(result.ignoredRows, 1);
    expect(countRow.read<int>('c'), 2);
  });

  test('emits monotonically increasing insert progress', () async {
    final progressEvents = <QuranTextImportProgress>[];
    final importer = QuranTextImporterService(
      db,
      loadAssetText: (_) async => '''
1|1|a
1|2|b
1|3|c
''',
      loadPageIndex: () async => <String, int>{
        verseKey(1, 1): 1,
        verseKey(1, 2): 1,
        verseKey(1, 3): 1,
      },
    );

    await importer.importFromAsset(
      batchSize: 1,
      onProgress: progressEvents.add,
    );

    final withTotal = progressEvents.where((e) => e.total > 0).toList();
    expect(withTotal, isNotEmpty);

    var previous = -1;
    for (final event in withTotal) {
      expect(event.processed >= previous, isTrue);
      previous = event.processed;
    }

    final last = withTotal.last;
    expect(last.processed, last.total);
  });

  test('throws FormatException for malformed line', () async {
    final importer = QuranTextImporterService(
      db,
      loadAssetText: (_) async => '''
1|1|ok
هذا_سطر_عربي_غير_صحيح
''',
      loadPageIndex: () async => <String, int>{verseKey(1, 1): 1},
    );

    await expectLater(
      importer.importFromAsset(),
      throwsA(isA<FormatException>()),
    );
  });

  test('throws StateError when verse page mapping is missing', () async {
    final importer = QuranTextImporterService(
      db,
      loadAssetText: (_) async => '1|1|text',
      loadPageIndex: () async => const <String, int>{},
    );

    await expectLater(
      importer.importFromAsset(),
      throwsA(isA<StateError>()),
    );
  });
}
