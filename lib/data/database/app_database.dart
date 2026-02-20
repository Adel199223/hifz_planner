import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Ayah extends Table {
  @override
  String get tableName => 'ayah';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get surah => integer()();

  IntColumn get ayah => integer()();

  TextColumn get textUthmani => text().named('text_uthmani')();

  IntColumn get pageMadina => integer().named('page_madina').nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {surah, ayah},
      ];
}

class Bookmark extends Table {
  @override
  String get tableName => 'bookmark';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get surah => integer()();

  IntColumn get ayah => integer()();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
}

class Note extends Table {
  @override
  String get tableName => 'note';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get surah => integer()();

  IntColumn get ayah => integer()();

  TextColumn get title => text().nullable()();

  TextColumn get body => text()();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Ayah, Bookmark, Note])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Reserved for future migrations.
          }
        },
        beforeOpen: (OpeningDetails details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'hifz_planner.sqlite');
}
