import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/mem_unit_repo.dart';
import 'package:hifz_planner/data/repositories/quran_repo.dart';
import 'package:hifz_planner/data/services/similar_verse_candidate_service.dart';

void main() {
  late AppDatabase db;
  late SimilarVerseCandidateService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = SimilarVerseCandidateService(MemUnitRepo(db), QuranRepo(db));
  });

  tearDown(() async {
    await db.close();
  });

  test('returns a confident candidate for a clear shared-opening split', () async {
    await _insertAyah(
      db,
      surah: 1,
      ayah: 1,
      text:
          'قالوا امنا بالله وباليوم الاخر وما هم بمؤمنين ثم رجعوا خاشعين',
      pageMadina: 1,
    );
    await _insertAyah(
      db,
      surah: 1,
      ayah: 2,
      text:
          'قالوا امنا بالله وباليوم الاخر وما هم بمسلمين ثم رجعوا خاشعين',
      pageMadina: 2,
    );
    final targetUnitId = await _insertUnit(
      db,
      unitKey: 'target',
      startAyah: 1,
      endAyah: 1,
      pageMadina: 1,
    );
    final candidateUnitId = await _insertUnit(
      db,
      unitKey: 'candidate',
      startAyah: 2,
      endAyah: 2,
      pageMadina: 2,
    );

    final result = await service.buildRescueData(targetUnitId);

    expect(result, isNotNull);
    expect(result!.hasConfidentCandidate, isTrue);
    expect(result.candidates, hasLength(1));
    expect(result.candidates.first.unit.id, candidateUnitId);
    expect(result.candidates.first.score, greaterThanOrEqualTo(0.60));
    expect(result.candidates.first.differenceCue, isNotNull);
    expect(
      result.candidates.first.differenceCue!.kind,
      SimilarVerseDifferenceCueKind.openingSplit,
    );
  });

  test('returns no confident candidate when overlap is too weak', () async {
    await _insertAyah(
      db,
      surah: 1,
      ayah: 1,
      text: 'واذ قال ربك للملائكة اني جاعل في الارض خليفة',
      pageMadina: 1,
    );
    await _insertAyah(
      db,
      surah: 1,
      ayah: 2,
      text: 'الحمد لله رب العالمين الرحمن الرحيم مالك يوم الدين',
      pageMadina: 10,
    );
    final targetUnitId = await _insertUnit(
      db,
      unitKey: 'target-weak',
      startAyah: 1,
      endAyah: 1,
      pageMadina: 1,
    );
    await _insertUnit(
      db,
      unitKey: 'candidate-weak',
      startAyah: 2,
      endAyah: 2,
      pageMadina: 10,
    );

    final result = await service.buildRescueData(targetUnitId);

    expect(result, isNotNull);
    expect(result!.hasConfidentCandidate, isFalse);
    expect(result.candidates, isEmpty);
  });

  test('never returns the target unit as its own candidate', () async {
    await _insertAyah(
      db,
      surah: 1,
      ayah: 1,
      text: 'وما هم بمؤمنين وما هم بموقنين',
      pageMadina: 1,
    );
    final targetUnitId = await _insertUnit(
      db,
      unitKey: 'self-target',
      startAyah: 1,
      endAyah: 1,
      pageMadina: 1,
    );

    final result = await service.buildRescueData(targetUnitId);

    expect(result, isNotNull);
    expect(
      result!.candidates.any((candidate) => candidate.unit.id == targetUnitId),
      isFalse,
    );
  });
}

Future<void> _insertAyah(
  AppDatabase db, {
  required int surah,
  required int ayah,
  required String text,
  required int pageMadina,
}) async {
  await db.into(db.ayah).insert(
        AyahCompanion.insert(
          surah: surah,
          ayah: ayah,
          textUthmani: text,
          pageMadina: Value(pageMadina),
        ),
      );
}

Future<int> _insertUnit(
  AppDatabase db, {
  required String unitKey,
  required int startAyah,
  required int endAyah,
  required int pageMadina,
}) {
  return db.into(db.memUnit).insert(
        MemUnitCompanion.insert(
          kind: 'ayah_range',
          pageMadina: Value(pageMadina),
          startSurah: const Value(1),
          startAyah: Value(startAyah),
          endSurah: const Value(1),
          endAyah: Value(endAyah),
          unitKey: unitKey,
          createdAtDay: 100,
          updatedAtDay: 100,
        ),
      );
}
