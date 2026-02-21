import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/services/page_metadata_importer_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('imports valid mapping and updates matching ayahs', () async {
    await _seedAyah(db, surah: 1, ayah: 1, text: 'a');
    await _seedAyah(db, surah: 1, ayah: 2, text: 'b', pageMadina: 99);

    final service = PageMetadataImporterService(
      db,
      loadPageIndex: (_) async => <String, int>{
        '1:1': 1,
        '1:2': 2,
        '2:1': 5,
      },
    );

    final result = await service.importFromAsset();
    final first = await _getAyah(db, surah: 1, ayah: 1);
    final second = await _getAyah(db, surah: 1, ayah: 2);

    expect(result.parsedRows, 3);
    expect(result.matchedRows, 2);
    expect(result.updatedRows, 2);
    expect(result.unchangedRows, 0);
    expect(result.missingRows, 1);
    expect(first?.pageMadina, 1);
    expect(second?.pageMadina, 2);
  });

  test('is idempotent on repeated import', () async {
    await _seedAyah(db, surah: 1, ayah: 1, text: 'x');

    final service = PageMetadataImporterService(
      db,
      loadPageIndex: (_) async => <String, int>{'1:1': 7},
    );

    final first = await service.importFromAsset();
    final second = await service.importFromAsset();

    expect(first.updatedRows, 1);
    expect(first.unchangedRows, 0);
    expect(second.updatedRows, 0);
    expect(second.unchangedRows, 1);
  });

  test('counts unchanged rows when page is already current', () async {
    await _seedAyah(db, surah: 1, ayah: 1, text: 'x', pageMadina: 8);

    final service = PageMetadataImporterService(
      db,
      loadPageIndex: (_) async => <String, int>{'1:1': 8},
    );

    final result = await service.importFromAsset();

    expect(result.parsedRows, 1);
    expect(result.matchedRows, 1);
    expect(result.updatedRows, 0);
    expect(result.unchangedRows, 1);
    expect(result.missingRows, 0);
  });

  test('propagates FormatException from page index loader', () async {
    final service = PageMetadataImporterService(
      db,
      loadPageIndex: (_) async {
        throw const FormatException('bad page index');
      },
    );

    await expectLater(
      service.importFromAsset(),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('bad page index'),
        ),
      ),
    );
  });

  test('emits progress callbacks for loading/parsing/updating/completed',
      () async {
    await _seedAyah(db, surah: 1, ayah: 1, text: 'a');
    await _seedAyah(db, surah: 1, ayah: 2, text: 'b');

    final events = <PageMetadataImportProgress>[];
    final service = PageMetadataImporterService(
      db,
      loadPageIndex: (_) async => <String, int>{
        '1:1': 3,
        '1:2': 4,
      },
    );

    await service.importFromAsset(
      batchSize: 1,
      onProgress: events.add,
    );

    expect(
      events.any((e) => e.phase == PageMetadataImportProgress.phaseLoading),
      isTrue,
    );
    expect(
      events.any((e) => e.phase == PageMetadataImportProgress.phaseParsing),
      isTrue,
    );
    expect(
      events.any((e) => e.phase == PageMetadataImportProgress.phaseUpdating),
      isTrue,
    );
    expect(
      events.any((e) => e.phase == PageMetadataImportProgress.phaseCompleted),
      isTrue,
    );

    final updatingEvents = events
        .where((e) => e.phase == PageMetadataImportProgress.phaseUpdating)
        .toList();
    var previous = -1;
    for (final event in updatingEvents) {
      expect(event.processed >= previous, isTrue);
      previous = event.processed;
    }

    expect(updatingEvents.last.processed, updatingEvents.last.total);
  });
}

Future<void> _seedAyah(
  AppDatabase db, {
  required int surah,
  required int ayah,
  required String text,
  int? pageMadina,
}) async {
  await db.into(db.ayah).insert(
        AyahCompanion.insert(
          surah: surah,
          ayah: ayah,
          textUthmani: text,
          pageMadina:
              pageMadina == null ? const Value.absent() : Value(pageMadina),
        ),
      );
}

Future<AyahData?> _getAyah(
  AppDatabase db, {
  required int surah,
  required int ayah,
}) {
  final query = db.select(db.ayah)
    ..where((tbl) => tbl.surah.equals(surah) & tbl.ayah.equals(ayah));
  return query.getSingleOrNull();
}
