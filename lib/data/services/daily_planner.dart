import 'dart:math' as math;

import '../database/app_database.dart';
import '../repositories/progress_repo.dart';
import '../repositories/quran_repo.dart';
import '../repositories/schedule_repo.dart';
import '../repositories/settings_repo.dart';
import 'scheduling/planning_projection_engine.dart';
import 'scheduling/weekly_plan_generator.dart';
import 'new_unit_generator.dart';

class TodayPlan {
  const TodayPlan({
    required this.plannedReviews,
    required this.plannedNewUnits,
    required this.revisionOnly,
    required this.minutesPlannedReviews,
    required this.minutesPlannedNew,
    this.sessions = const <PlannedSession>[],
    this.reviewPressure = 0,
    this.recoveryMode = false,
    this.message,
  });

  final List<DueUnitRow> plannedReviews;
  final List<MemUnitData> plannedNewUnits;
  final bool revisionOnly;
  final double minutesPlannedReviews;
  final double minutesPlannedNew;
  final List<PlannedSession> sessions;
  final double reviewPressure;
  final bool recoveryMode;
  final String? message;
}

class DailyPlanner {
  DailyPlanner(
    this._db,
    this._settingsRepo,
    this._progressRepo,
    this._scheduleRepo,
    this._quranRepo,
    this._newUnitGenerator,
    this._projectionEngine,
  );

  final AppDatabase _db;
  final SettingsRepo _settingsRepo;
  final ProgressRepo _progressRepo;
  final ScheduleRepo _scheduleRepo;
  final QuranRepo _quranRepo;
  final NewUnitGenerator _newUnitGenerator;
  final PlanningProjectionEngine _projectionEngine;

  Future<TodayPlan> planToday({required int todayDay}) {
    return _db.transaction(() async {
      final settings =
          await _settingsRepo.getSettings(todayDayOverride: todayDay);
      final cursor = await _progressRepo.getCursor();
      final dueUnits = await _scheduleRepo.getDueUnits(todayDay);

      final sortedDueUnits = [...dueUnits]
        ..sort((a, b) => _compareDueRows(a, b, todayDay));

      final schedulingPreferences =
          _projectionEngine.preferencesFromSettings(settings);
      final schedulingOverrides =
          _projectionEngine.overridesFromSettings(settings);
      final weeklyPlan = await _projectionEngine.generateWeeklyPlan(
        startDay: todayDay,
        horizonDays: 1,
        settings: settings,
        scheduleRepo: _scheduleRepo,
        quranRepo: _quranRepo,
        preferences: schedulingPreferences,
        overrides: schedulingOverrides,
      );
      final todaySchedule =
          weeklyPlan.days.isNotEmpty ? weeklyPlan.days.first : null;

      final dailyMinutes = (todaySchedule?.totalPlannedMinutes ??
              _projectionEngine.resolveMinutesForDay(
                dayIndex: todayDay,
                preferences: schedulingPreferences,
                overrides: schedulingOverrides,
              ))
          .toDouble();

      if (dailyMinutes <= 0 ||
          (todaySchedule != null && !todaySchedule.enabledStudyDay)) {
        return TodayPlan(
          plannedReviews: const <DueUnitRow>[],
          plannedNewUnits: const <MemUnitData>[],
          revisionOnly: false,
          minutesPlannedReviews: 0,
          minutesPlannedNew: 0,
          sessions: todaySchedule?.sessions ?? const <PlannedSession>[],
          message: todaySchedule?.skipDay == true
              ? 'Day marked as holiday'
              : 'No study sessions planned for today',
        );
      }

      final dueReviewMinutes =
          await _projectionEngine.estimateReviewMinutesForRows(
        dueRows: sortedDueUnits,
        quranRepo: _quranRepo,
        avgReviewMinutesPerAyah: settings.avgReviewMinutesPerAyah,
      );
      final allocation = _projectionEngine.allocateDailyContent(
        dailyMinutes: dailyMinutes,
        dueReviewMinutes: dueReviewMinutes,
        profile: settings.profile,
        forceRevisionOnly: settings.forceRevisionOnly == 1 ||
            (todaySchedule?.revisionOnlyDay ?? false),
      );
      final reviewBudgetMinutes = allocation.reviewCapacityMinutes;

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

      final revisionOnly =
          (todaySchedule?.revisionOnlyDay ?? false) || allocation.recoveryMode;

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
          final remainingNewMinutes = math.max(
            0.0,
            math.min(
              allocation.newBudgetMinutes,
              dailyMinutes - minutesPlannedReviews,
            ),
          );
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

      final syncedSessions = _syncSessionsWithActualMinutes(
        template: todaySchedule?.sessions ?? const <PlannedSession>[],
        minutesPlannedReviews: minutesPlannedReviews,
        minutesPlannedNew: minutesPlannedNew,
        revisionOnly: revisionOnly,
      );

      return TodayPlan(
        plannedReviews: plannedReviews,
        plannedNewUnits: plannedNewUnits,
        revisionOnly: revisionOnly,
        minutesPlannedReviews: minutesPlannedReviews,
        minutesPlannedNew: minutesPlannedNew,
        sessions: syncedSessions,
        reviewPressure: allocation.reviewPressure,
        recoveryMode: allocation.recoveryMode,
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

  List<PlannedSession> _syncSessionsWithActualMinutes({
    required List<PlannedSession> template,
    required double minutesPlannedReviews,
    required double minutesPlannedNew,
    required bool revisionOnly,
  }) {
    if (template.isEmpty) {
      return const <PlannedSession>[];
    }

    final reviewTotal = minutesPlannedReviews.round();
    final newTotal = revisionOnly ? 0 : minutesPlannedNew.round();

    final totalTemplateReview = template
        .map((session) => session.plannedReviewMinutes)
        .fold<int>(0, (sum, value) => sum + value);
    final totalTemplateNew = template
        .map((session) => session.plannedNewMinutes)
        .fold<int>(0, (sum, value) => sum + value);

    var reviewAssigned = 0;
    var newAssigned = 0;

    final sessions = <PlannedSession>[];
    for (var i = 0; i < template.length; i++) {
      final session = template[i];
      final isLast = i == template.length - 1;

      int assignedReview;
      if (isLast) {
        assignedReview = reviewTotal - reviewAssigned;
      } else if (totalTemplateReview > 0) {
        final weight = session.plannedReviewMinutes / totalTemplateReview;
        assignedReview = (reviewTotal * weight).round();
      } else {
        assignedReview = (reviewTotal / template.length).round();
      }
      assignedReview = assignedReview.clamp(0, reviewTotal - reviewAssigned);
      reviewAssigned += assignedReview;

      int assignedNew = 0;
      if (!revisionOnly) {
        if (isLast) {
          assignedNew = newTotal - newAssigned;
        } else if (totalTemplateNew > 0) {
          final weight = session.plannedNewMinutes / totalTemplateNew;
          assignedNew = (newTotal * weight).round();
        } else {
          assignedNew = (newTotal / template.length).round();
        }
        assignedNew = assignedNew.clamp(0, newTotal - newAssigned);
        newAssigned += assignedNew;
      }

      final focus = revisionOnly || assignedNew == 0
          ? PlannedSessionFocus.reviewOnly
          : PlannedSessionFocus.newAndReview;

      sessions.add(
        PlannedSession(
          sessionLabel: session.sessionLabel,
          focus: focus,
          plannedMinutes: assignedReview + assignedNew,
          plannedReviewMinutes: assignedReview,
          plannedNewMinutes: assignedNew,
          isTimed: session.isTimed,
          startMinuteOfDay: session.startMinuteOfDay,
          status: session.status,
        ),
      );
    }

    return sessions;
  }
}
