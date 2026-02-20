import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/mem_unit_repo.dart';

void main() {
  late AppDatabase db;
  late MemUnitRepo repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = MemUnitRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('create/get/list returns inserted units', () async {
    final id1 = await repo.create(
      MemUnitCompanion.insert(
        kind: 'ayah_range',
        unitKey: 'u:1',
        createdAtDay: 20000,
        updatedAtDay: 20000,
      ),
    );
    final id2 = await repo.create(
      MemUnitCompanion.insert(
        kind: 'page_segment',
        unitKey: 'u:2',
        pageMadina: const Value(12),
        createdAtDay: 20001,
        updatedAtDay: 20001,
      ),
    );

    final unit1 = await repo.get(id1);
    final units = await repo.list();

    expect(unit1, isNotNull);
    expect(unit1!.unitKey, 'u:1');
    expect(units.length, 2);
    expect(units.first.id, id1);
    expect(units.last.id, id2);
  });

  test('ensureUniqueByUnitKey returns existing row for duplicate key',
      () async {
    final first = await repo.ensureUniqueByUnitKey(
      MemUnitCompanion.insert(
        kind: 'ayah_range',
        unitKey: 'dedupe-key',
        createdAtDay: 21000,
        updatedAtDay: 21000,
      ),
    );

    final second = await repo.ensureUniqueByUnitKey(
      MemUnitCompanion.insert(
        kind: 'custom',
        unitKey: 'dedupe-key',
        title: const Value('should not insert'),
        createdAtDay: 22000,
        updatedAtDay: 22000,
      ),
    );

    final rows = await repo.list();

    expect(rows.length, 1);
    expect(second.id, first.id);
    expect(second.kind, first.kind);
    expect(second.title, isNull);
  });
}
