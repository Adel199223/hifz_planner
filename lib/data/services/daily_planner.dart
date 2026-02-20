import 'dart:convert';
import 'dart:math' as math;

import '../database/app_database.dart';
import '../repositories/mem_unit_repo.dart';
import '../repositories/progress_repo.dart';
import '../repositories/quran_repo.dart';
import '../repositories/schedule_repo.dart';
import '../repositories/settings_repo.dart';
import 'new_unit_generator.dart';

class TodayPlan {
  const TodayPlan({
    required this.plannedReviews,
    required this.plannedNewUnits,
    required this.revisionOnly,
    required this.minutesPlannedReviews,
    required this.minutesPlannedNew,
    this.message,
  });

  final List<DueUnitRow> plannedReviews;
  final List<MemUnitData> plannedNewUnits;
  final bool revisionOnly;
  final double minutesPlannedReviews;
  final double minutesPlannedNew;
  final String? message;
}

class DailyPlanner {
  DailyPlanner(
    this._db,
    this._settingsRepo,
    this._progressRepo,
    this._scheduleRepo,
    this._quranRepo,
    this._memUnitRepo,
    this._newUnitGenerator,
  );

  final AppDatabase _db;
  final SettingsRepo _settingsRepo;
  final ProgressRepo _progressRepo;
  final ScheduleRepo _scheduleRepo;
  final QuranRepo _quranRepo;
  final MemUnitRepo _memUnitRepo;
  final NewUnitGenerator _newUnitGenerator;

  Future<TodayPlan> planToday({required int todayDay}) {
    return _db.transaction(() async {
      final settings = await _settingsRepo.getSettings();
      final cursor = await _progressRepo.getCursor();
      final dueUnits = await _scheduleRepo.getDueUnits(todayDay);

      final sortedDueUnits = [...dueUnits]
        ..sort((a, b) => _compareDueRows(a, b, todayDay));

      final dailyMinutes = _resolveDailyMinutes(settings, todayDay);
      final reviewBudgetMinutes = dailyMinutes * _reviewBudgetRatio(settings);

      final plannedReviews = <DueUnitRow>[];
      var minutesPlannedReviews = 0.0;
      for (final dueRow in sortedDueUnits) {
        final estimated = await _estimateReviewMinutesForUnit(
          dueRow.unit,
          settings.avgReviewMinutesPerAyah,
        );
        if (minutesPlannedReviews + estimated > reviewBudgetMinutes + 1e-9) {
          continue;
        }
        plannedReviews.add(dueRow);
        minutesPlannedReviews += estimated;
      }

      final dueOverflow = sortedDueUnits.length > plannedReviews.length;
      final revisionOnly = dueOverflow && settings.forceRevisionOnly == 1;

      var plannedNewUnits = <MemUnitData>[];
      var minutesPlannedNew = 0.0;
      String? message;

      if (!revisionOnly) {
        final metadataBlocked = await _isMetadataBlocked(
          settings: settings,
          cursor: cursor,
        );
        if (metadataBlocked) {
          message = 'Import page metadata first';
        } else {
          final remainingNewMinutes =
              math.max(0.0, dailyMinutes - minutesPlannedReviews);
          final generation = await _newUnitGenerator.generate(
            todayDay: todayDay,
            cursor: cursor,
            remainingMinutes: remainingNewMinutes,
            settings: settings,
            initialEf: _initialEfForProfile(settings.profile),
          );
          plannedNewUnits = generation.createdUnits;
          minutesPlannedNew = generation.minutesPlannedNew;

          final cursorMoved = generation.nextSurah != cursor.nextSurah ||
              generation.nextAyah != cursor.nextAyah;
          if (cursorMoved) {
            await _progressRepo.updateCursor(
              nextSurah: generation.nextSurah,
              nextAyah: generation.nextAyah,
              updatedAtDay: todayDay,
            );
          }
        }
      }

      return TodayPlan(
        plannedReviews: plannedReviews,
        plannedNewUnits: plannedNewUnits,
        revisionOnly: revisionOnly,
        minutesPlannedReviews: minutesPlannedReviews,
        minutesPlannedNew: minutesPlannedNew,
        message: message,
      );
    });
  }

  int _compareDueRows(DueUnitRow a, DueUnitRow b, int todayDay) {
    final overdueA = todayDay - a.schedule.dueDay;
    final overdueB = todayDay - b.schedule.dueDay;
    final overdueCompare = overdueB.compareTo(overdueA);
    if (overdueCompare != 0) {
      return overdueCompare;
    }

    final repsCompare = a.schedule.reps.compareTo(b.schedule.reps);
    if (repsCompare != 0) {
      return repsCompare;
    }

    final lapseCompare = b.schedule.lapseCount.compareTo(a.schedule.lapseCount);
    if (lapseCompare != 0) {
      return lapseCompare;
    }

    return a.schedule.unitId.compareTo(b.schedule.unitId);
  }

  double _resolveDailyMinutes(AppSettingsData settings, int todayDay) {
    final defaultMinutes = settings.dailyMinutesDefault.toDouble();
    final rawJson = settings.minutesByWeekdayJson;
    if (rawJson == null || rawJson.trim().isEmpty) {
      return defaultMinutes;
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) {
        return defaultMinutes;
      }

      final weekdayKey = _weekdayKeyForDay(todayDay);
      final value = decoded[weekdayKey];
      if (value is num) {
        return value.toDouble();
      }
      return defaultMinutes;
    } catch (_) {
      return defaultMinutes;
    }
  }

  String _weekdayKeyForDay(int todayDay) {
    final date = DateTime(1970, 1, 1).add(Duration(days: todayDay));
    return switch (date.weekday) {
      DateTime.monday => 'mon',
      DateTime.tuesday => 'tue',
      DateTime.wednesday => 'wed',
      DateTime.thursday => 'thu',
      DateTime.friday => 'fri',
      DateTime.saturday => 'sat',
      DateTime.sunday => 'sun',
      _ => 'mon',
    };
  }

  double _reviewBudgetRatio(AppSettingsData settings) {
    return switch (settings.profile) {
      'support' => 0.80,
      'standard' => 0.70,
      'accelerated' => 0.60,
      _ => 0.70,
    };
  }

  double _initialEfForProfile(String profile) {
    return switch (profile) {
      'support' => 2.4,
      'standard' => 2.5,
      'accelerated' => 2.6,
      _ => 2.5,
    };
  }

  Future<double> _estimateReviewMinutesForUnit(
    MemUnitData unit,
    double avgReviewMinutesPerAyah,
  ) async {
    final ayahCount = await _estimateAyahCount(unit);
    return ayahCount * avgReviewMinutesPerAyah;
  }

  Future<int> _estimateAyahCount(MemUnitData unit) async {
    final startSurah = unit.startSurah;
    final startAyah = unit.startAyah;
    final endSurah = unit.endSurah;
    final endAyah = unit.endAyah;

    if (startSurah == null ||
        startAyah == null ||
        endSurah == null ||
        endAyah == null) {
      return 1;
    }

    final startsAfterEnd = (startSurah > endSurah) ||
        (startSurah == endSurah && startAyah > endAyah);
    if (startsAfterEnd) {
      return 1;
    }

    final count = await _quranRepo.countAyahsInRange(
      startSurah: startSurah,
      startAyah: startAyah,
      endSurah: endSurah,
      endAyah: endAyah,
    );
    return count > 0 ? count : 1;
  }

  Future<bool> _isMetadataBlocked({
    required AppSettingsData settings,
    required MemProgressData cursor,
  }) async {
    if (settings.requirePageMetadata != 1) {
      return false;
    }

    final cursorAyah = await _quranRepo.getAyah(
      cursor.nextSurah,
      cursor.nextAyah,
    );
    if (cursorAyah == null || cursorAyah.pageMadina == null) {
      return true;
    }

    final coverageWindow = await _quranRepo.getAyahsFromCursor(
      startSurah: cursor.nextSurah,
      startAyah: cursor.nextAyah,
      limit: 20,
    );
    if (coverageWindow.isEmpty) {
      return true;
    }

    final withPage = coverageWindow.where((ayah) => ayah.pageMadina != null);
    final coverage = withPage.length / coverageWindow.length;
    return coverage < 0.90;
  }
}
