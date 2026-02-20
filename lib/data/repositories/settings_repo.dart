import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../time/local_day_time.dart';

typedef AppSettingsData = AppSetting;

class SettingsRepo {
  SettingsRepo(this._db);

  final AppDatabase _db;

  Future<AppSettingsData> getSettings({int? todayDayOverride}) async {
    await _db.ensureSingletonRows();
    await _applyDuePendingCalibration(todayDayOverride: todayDayOverride);
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
    String? typicalGradeDistributionJson,
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
        typicalGradeDistributionJson: typicalGradeDistributionJson == null
            ? const Value.absent()
            : Value(typicalGradeDistributionJson),
        updatedAtDay: Value(
          updatedAtDay ?? localDayIndex(DateTime.now().toLocal()),
        ),
      ),
    );
    return rows > 0;
  }

  Future<void> upsertPendingCalibrationUpdate({
    double? avgNewMinutesPerAyah,
    double? avgReviewMinutesPerAyah,
    String? typicalGradeDistributionJson,
    required int effectiveDay,
    int? createdAtDay,
  }) async {
    final nowDay = createdAtDay ?? localDayIndex(DateTime.now().toLocal());
    await _db.into(_db.pendingCalibrationUpdate).insert(
          PendingCalibrationUpdateCompanion.insert(
            id: const Value(1),
            avgNewMinutesPerAyah: Value(avgNewMinutesPerAyah),
            avgReviewMinutesPerAyah: Value(avgReviewMinutesPerAyah),
            typicalGradeDistributionJson: Value(typicalGradeDistributionJson),
            effectiveDay: effectiveDay,
            createdAtDay: nowDay,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<PendingCalibrationUpdateData?> getPendingCalibrationUpdate() {
    return (_db.select(_db.pendingCalibrationUpdate)
          ..where((tbl) => tbl.id.equals(1))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> clearPendingCalibrationUpdate() async {
    await (_db.delete(_db.pendingCalibrationUpdate)
          ..where((tbl) => tbl.id.equals(1)))
        .go();
  }

  Future<void> _applyDuePendingCalibration({int? todayDayOverride}) async {
    final todayDay =
        todayDayOverride ?? localDayIndex(DateTime.now().toLocal());
    await _db.transaction(() async {
      final pending = await (_db.select(_db.pendingCalibrationUpdate)
            ..where((tbl) => tbl.id.equals(1))
            ..limit(1))
          .getSingleOrNull();
      if (pending == null || pending.effectiveDay > todayDay) {
        return;
      }

      await (_db.update(_db.appSettings)..where((tbl) => tbl.id.equals(1)))
          .write(
        AppSettingsCompanion(
          avgNewMinutesPerAyah: pending.avgNewMinutesPerAyah == null
              ? const Value.absent()
              : Value(pending.avgNewMinutesPerAyah!),
          avgReviewMinutesPerAyah: pending.avgReviewMinutesPerAyah == null
              ? const Value.absent()
              : Value(pending.avgReviewMinutesPerAyah!),
          typicalGradeDistributionJson:
              pending.typicalGradeDistributionJson == null
                  ? const Value.absent()
                  : Value(pending.typicalGradeDistributionJson),
          updatedAtDay: Value(pending.effectiveDay),
        ),
      );

      await (_db.delete(_db.pendingCalibrationUpdate)
            ..where((tbl) => tbl.id.equals(1)))
          .go();
    });
  }
}
