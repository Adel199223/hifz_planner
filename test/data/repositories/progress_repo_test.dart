import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/repositories/progress_repo.dart';
import 'package:hifz_planner/data/time/local_day_time.dart';

void main() {
  late AppDatabase db;
  late ProgressRepo repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ProgressRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('getCursor returns seeded cursor at (1,1)', () async {
    final cursor = await repo.getCursor();

    expect(cursor.id, 1);
    expect(cursor.nextSurah, 1);
    expect(cursor.nextAyah, 1);
  });

  test('updateCursor persists new values and updated_at_day', () async {
    final explicit = await repo.updateCursor(
      nextSurah: 2,
      nextAyah: 5,
      updatedAtDay: 26000,
    );
    var cursor = await repo.getCursor();

    expect(explicit, isTrue);
    expect(cursor.nextSurah, 2);
    expect(cursor.nextAyah, 5);
    expect(cursor.updatedAtDay, 26000);

    final implicit = await repo.updateCursor(
      nextSurah: 3,
      nextAyah: 8,
    );
    final currentDay = localDayIndex(DateTime.now().toLocal());
    cursor = await repo.getCursor();

    expect(implicit, isTrue);
    expect(cursor.nextSurah, 3);
    expect(cursor.nextAyah, 8);
    expect(cursor.updatedAtDay, currentDay);
  });
}
