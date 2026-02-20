import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../time/local_day_time.dart';

typedef AppSettingsData = AppSetting;

class SettingsRepo {
  SettingsRepo(this._db);

  final AppDatabase _db;

  Future<AppSettingsData> getSettings() async {
    await _db.ensureSingletonRows();
    return (_db.select(_db.appSettings)..where((tbl) => tbl.id.equals(1)))
        .getSingle();
  }

  Future<bool> updateSettings({
    String? profile,
    int? forceRevisionOnly,
    int? dailyMinutesDefault,
    String? minutesByWeekdayJson,
    int? maxNewPagesPerDay,
    int? maxNewUnitsPerDay,
    double? avgNewMinutesPerAyah,
    double? avgReviewMinutesPerAyah,
    int? requirePageMetadata,
    int? updatedAtDay,
  }) async {
    await _db.ensureSingletonRows();
    final rows = await (_db.update(_db.appSettings)
          ..where((tbl) => tbl.id.equals(1)))
        .write(
      AppSettingsCompanion(
        profile: profile == null ? const Value.absent() : Value(profile),
        forceRevisionOnly: forceRevisionOnly == null
            ? const Value.absent()
            : Value(forceRevisionOnly),
        dailyMinutesDefault: dailyMinutesDefault == null
            ? const Value.absent()
            : Value(dailyMinutesDefault),
        minutesByWeekdayJson: minutesByWeekdayJson == null
            ? const Value.absent()
            : Value(minutesByWeekdayJson),
        maxNewPagesPerDay: maxNewPagesPerDay == null
            ? const Value.absent()
            : Value(maxNewPagesPerDay),
        maxNewUnitsPerDay: maxNewUnitsPerDay == null
            ? const Value.absent()
            : Value(maxNewUnitsPerDay),
        avgNewMinutesPerAyah: avgNewMinutesPerAyah == null
            ? const Value.absent()
            : Value(avgNewMinutesPerAyah),
        avgReviewMinutesPerAyah: avgReviewMinutesPerAyah == null
            ? const Value.absent()
            : Value(avgReviewMinutesPerAyah),
        requirePageMetadata: requirePageMetadata == null
            ? const Value.absent()
            : Value(requirePageMetadata),
        updatedAtDay: Value(
          updatedAtDay ?? localDayIndex(DateTime.now().toLocal()),
        ),
      ),
    );
    return rows > 0;
  }
}
