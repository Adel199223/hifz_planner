import 'dart:math' as math;
import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../repositories/companion_repo.dart';
import '../repositories/progress_repo.dart';
import '../repositories/quran_repo.dart';
import '../repositories/schedule_repo.dart';
import '../repositories/settings_repo.dart';
import 'scheduling/planning_projection_engine.dart';
import 'scheduling/weekly_plan_generator.dart';
import 'new_unit_generator.dart';

const Object _todayPlanUnset = Object();

enum TodayNewAvailability {
  available,
  blockedStage4,
  blockedSetup,
  blockedReviewHealth,
  noneAvailable,
}

enum TodayPlanNotice {
  noStudySessions,
  holiday,
  finishSetup,
}

class TodayPlan {
  const TodayPlan({
    required this.plannedReviews,
    required this.plannedNewUnits,
    required this.plannedStage4Due,
    required this.revisionOnly,
    required this.minutesPlannedReviews,
    required this.minutesPlannedNew,
    required this.stage4BlocksNewByDefault,
    required this.stage4QualitySnapshot,
    required this.newAvailability,
    this.showStage4CatchUpMessage = false,
    this.sessions = const <PlannedSession>[],
    this.reviewPressure = 0,
    this.recoveryMode = false,
    this.notice,
  });

  final List<PlannedReviewRow> plannedReviews;
  final List<MemUnitData> plannedNewUnits;
  final List<Stage4DueItem> plannedStage4Due;
  final bool revisionOnly;
  final double minutesPlannedReviews;
  final double minutesPlannedNew;
  final bool stage4BlocksNewByDefault;
  final Stage4QualitySnapshot stage4QualitySnapshot;
  final TodayNewAvailability newAvailability;
  final bool showStage4CatchUpMessage;
  final List<PlannedSession> sessions;
  final double reviewPressure;
  final bool recoveryMode;
  final TodayPlanNotice? notice;

  TodayPlan copyWith({
    List<PlannedReviewRow>? plannedReviews,
    List<MemUnitData>? plannedNewUnits,
    List<Stage4DueItem>? plannedStage4Due,
    bool? revisionOnly,
    double? minutesPlannedReviews,
    double? minutesPlannedNew,
    bool? stage4BlocksNewByDefault,
    Stage4QualitySnapshot? stage4QualitySnapshot,
    TodayNewAvailability? newAvailability,
    bool? showStage4CatchUpMessage,
    List<PlannedSession>? sessions,
    double? reviewPressure,
    bool? recoveryMode,
    Object? notice = _todayPlanUnset,
  }) {
    return TodayPlan(
      plannedReviews: plannedReviews ?? this.plannedReviews,
      plannedNewUnits: plannedNewUnits ?? this.plannedNewUnits,
      plannedStage4Due: plannedStage4Due ?? this.plannedStage4Due,
      revisionOnly: revisionOnly ?? this.revisionOnly,
      minutesPlannedReviews:
          minutesPlannedReviews ?? this.minutesPlannedReviews,
      minutesPlannedNew: minutesPlannedNew ?? this.minutesPlannedNew,
      stage4BlocksNewByDefault:
          stage4BlocksNewByDefault ?? this.stage4BlocksNewByDefault,
      stage4QualitySnapshot:
          stage4QualitySnapshot ?? this.stage4QualitySnapshot,
      newAvailability: newAvailability ?? this.newAvailability,
      showStage4CatchUpMessage:
          showStage4CatchUpMessage ?? this.showStage4CatchUpMessage,
      sessions: sessions ?? this.sessions,
      reviewPressure: reviewPressure ?? this.reviewPressure,
      recoveryMode: recoveryMode ?? this.recoveryMode,
      notice:
          identical(notice, _todayPlanUnset) ? this.notice : notice as TodayPlanNotice?,
    );
  }
}

class PlannedReviewRow {
  const PlannedReviewRow({
    required this.unit,
    required this.schedule,
    required this.lifecycleTier,
    required this.reinforcementWeight,
  });

  final MemUnitData unit;
  final ScheduleStateData schedule;
  final String lifecycleTier;
  final double reinforcementWeight;
}

class Stage4DueItem {
  const Stage4DueItem({
    required this.unit,
    required this.lifecycle,
    required this.dueKind,
    required this.dueDay,
    required this.mandatory,
    required this.overdueDays,
    required this.unresolvedTargetsCount,
  });

  final MemUnitData unit;
  final CompanionLifecycleStateData lifecycle;
  final String dueKind;
  final int dueDay;
  final bool mandatory;
  final int overdueDays;
  final int unresolvedTargetsCount;
}

class Stage4QualitySnapshot {
  const Stage4QualitySnapshot({
    this.emergingCount = 0,
    this.readyCount = 0,
    this.stableCount = 0,
    this.maintainedCount = 0,
    this.qualityStreakDays = 0,
    this.todayQuests = const <String>[],
  });

  final int emergingCount;
  final int readyCount;
  final int stableCount;
  final int maintainedCount;
  final int qualityStreakDays;
  final List<String> todayQuests;
}

enum StarterUnitCreationStatus {
  created,
  alreadyInitialized,
  blockedByMetadata,
  unavailable,
}

class StarterUnitCreationResult {
  const StarterUnitCreationResult({
    required this.status,
    this.createdUnit,
    this.minutesPlannedNew = 0,
    this.sessions = const <PlannedSession>[],
  });

  final StarterUnitCreationStatus status;
  final MemUnitData? createdUnit;
  final double minutesPlannedNew;
  final List<PlannedSession> sessions;
}

class DailyPlanner {
  DailyPlanner(
    this._db,
    this._settingsRepo,
    this._progressRepo,
    this._scheduleRepo,
    this._quranRepo,
    this._companionRepo,
    this._newUnitGenerator,
    this._projectionEngine,
  );

  final AppDatabase _db;
  final SettingsRepo _settingsRepo;
  final ProgressRepo _progressRepo;
  final ScheduleRepo _scheduleRepo;
  final QuranRepo _quranRepo;
  final CompanionRepo _companionRepo;
  final NewUnitGenerator _newUnitGenerator;
  final PlanningProjectionEngine _projectionEngine;

  Future<TodayPlan> planToday({
    required int todayDay,
    bool allowStage4Override = false,
    bool materializeNewUnits = true,
  }) {
    return _db.transaction(() async {
      final settings =
          await _settingsRepo.getSettings(todayDayOverride: todayDay);
      final cursor = await _progressRepo.getCursor();
      final dueUnits = await _scheduleRepo.getDueUnits(todayDay);
      final lifecycleTierByUnitId = await _loadLifecycleTierByUnitId(
        dueUnits.map((row) => row.unit.id),
      );
      final reinforcementByUnitId = await _loadReinforcementProfileByUnitId(
        dueUnits.map((row) => row.unit.id),
      );
      final stage4DueItems = await _buildStage4DueItems(todayDay: todayDay);
      final stage4QualitySnapshot = await _buildStage4QualitySnapshot();
      final mandatoryStage4DueExists =
          stage4DueItems.any((item) => item.mandatory);

      final sortedDueUnits = [...dueUnits]..sort(
          (a, b) => _compareDueRows(
            a,
            b,
            todayDay,
            lifecycleTierByUnitId,
            reinforcementByUnitId,
          ),
        );
      final reviewMinutesByUnitId = await _estimateReviewMinutesByUnitId(
        sortedDueUnits.map((row) => row.unit),
        settings.avgReviewMinutesPerAyah,
      );

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
          plannedReviews: const <PlannedReviewRow>[],
          plannedNewUnits: const <MemUnitData>[],
          plannedStage4Due: stage4DueItems,
          revisionOnly: false,
          minutesPlannedReviews: 0,
          minutesPlannedNew: 0,
          stage4BlocksNewByDefault:
              mandatoryStage4DueExists && !allowStage4Override,
        stage4QualitySnapshot: stage4QualitySnapshot,
        newAvailability: mandatoryStage4DueExists && !allowStage4Override
              ? TodayNewAvailability.blockedStage4
              : TodayNewAvailability.noneAvailable,
        showStage4CatchUpMessage: mandatoryStage4DueExists,
          sessions: todaySchedule?.sessions ?? const <PlannedSession>[],
          notice: todaySchedule?.skipDay == true
              ? TodayPlanNotice.holiday
              : TodayPlanNotice.noStudySessions,
        );
      }

      final dueReviewMinutes = _weightedReviewDemandMinutes(
        dueRows: sortedDueUnits,
        reviewMinutesByUnitId: reviewMinutesByUnitId,
        reinforcementByUnitId: reinforcementByUnitId,
      );
      final allocation = _projectionEngine.allocateDailyContent(
        dailyMinutes: dailyMinutes,
        dueReviewMinutes: dueReviewMinutes,
        profile: settings.profile,
        forceRevisionOnly: settings.forceRevisionOnly == 1 ||
            (todaySchedule?.revisionOnlyDay ?? false),
      );
      final reviewBudgetMinutes = allocation.reviewCapacityMinutes;

      final plannedReviews = <PlannedReviewRow>[];
      var minutesPlannedReviews = 0.0;
      for (final dueRow in sortedDueUnits) {
        final estimated = reviewMinutesByUnitId[dueRow.unit.id] ??
            await _estimateReviewMinutesForUnit(
              dueRow.unit,
              settings.avgReviewMinutesPerAyah,
            );
        if (minutesPlannedReviews + estimated > reviewBudgetMinutes + 1e-9) {
          continue;
        }
        plannedReviews.add(
          PlannedReviewRow(
            unit: dueRow.unit,
            schedule: dueRow.schedule,
            lifecycleTier: _resolveLifecycleTier(
              dueRow.unit.id,
              lifecycleTierByUnitId,
            ),
            reinforcementWeight:
                reinforcementByUnitId[dueRow.unit.id]?.weight ?? 0.0,
          ),
        );
        minutesPlannedReviews += estimated;
      }

      final stage4BlocksNew = mandatoryStage4DueExists && !allowStage4Override;
      final revisionOnly =
          (todaySchedule?.revisionOnlyDay ?? false) || allocation.recoveryMode;
      final effectiveRevisionOnly = revisionOnly || stage4BlocksNew;

      var plannedNewUnits = <MemUnitData>[];
      var minutesPlannedNew = 0.0;
      TodayPlanNotice? notice;

      if (!effectiveRevisionOnly) {
        final metadataBlocked = await _isMetadataBlocked(
          settings: settings,
          cursor: cursor,
        );
        if (metadataBlocked) {
          notice = TodayPlanNotice.finishSetup;
        } else if (materializeNewUnits) {
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
        revisionOnly: effectiveRevisionOnly,
      );

      final TodayNewAvailability newAvailability;
      if (stage4BlocksNew) {
        newAvailability = TodayNewAvailability.blockedStage4;
      } else if (notice == TodayPlanNotice.finishSetup) {
        newAvailability = TodayNewAvailability.blockedSetup;
      } else if (effectiveRevisionOnly) {
        newAvailability = TodayNewAvailability.blockedReviewHealth;
      } else if (plannedNewUnits.isNotEmpty) {
        newAvailability = TodayNewAvailability.available;
      } else {
        newAvailability = TodayNewAvailability.noneAvailable;
      }

      return TodayPlan(
        plannedReviews: plannedReviews,
        plannedNewUnits: plannedNewUnits,
        plannedStage4Due: stage4DueItems,
        revisionOnly: effectiveRevisionOnly,
        minutesPlannedReviews: minutesPlannedReviews,
        minutesPlannedNew: minutesPlannedNew,
        stage4BlocksNewByDefault: stage4BlocksNew,
        stage4QualitySnapshot: stage4QualitySnapshot,
        newAvailability: newAvailability,
        showStage4CatchUpMessage: mandatoryStage4DueExists,
        sessions: syncedSessions,
        reviewPressure: allocation.reviewPressure,
        recoveryMode: allocation.recoveryMode,
        notice: notice,
      );
    });
  }

  Future<StarterUnitCreationResult> createStarterUnitForToday({
    required int todayDay,
    required TodayPlan plan,
  }) {
    return _db.transaction(() async {
      if (await _hasAnyMemUnits()) {
        return const StarterUnitCreationResult(
          status: StarterUnitCreationStatus.alreadyInitialized,
        );
      }

      final settings =
          await _settingsRepo.getSettings(todayDayOverride: todayDay);
      final cursor = await _progressRepo.getCursor();
      final metadataBlocked = await _isMetadataBlocked(
        settings: settings,
        cursor: cursor,
      );
      if (metadataBlocked) {
        return const StarterUnitCreationResult(
          status: StarterUnitCreationStatus.blockedByMetadata,
        );
      }

      final generation = await _newUnitGenerator.generateOneUnit(
        todayDay: todayDay,
        cursor: cursor,
        settings: settings,
        initialEf: _initialEfForProfile(settings.profile),
      );
      final createdUnit = generation.createdUnits.isEmpty
          ? null
          : generation.createdUnits.first;
      if (createdUnit == null) {
        return const StarterUnitCreationResult(
          status: StarterUnitCreationStatus.unavailable,
        );
      }

      final cursorMoved = generation.nextSurah != cursor.nextSurah ||
          generation.nextAyah != cursor.nextAyah;
      if (cursorMoved) {
        await _progressRepo.updateCursor(
          nextSurah: generation.nextSurah,
          nextAyah: generation.nextAyah,
          updatedAtDay: todayDay,
        );
      }

      return StarterUnitCreationResult(
        status: StarterUnitCreationStatus.created,
        createdUnit: createdUnit,
        minutesPlannedNew: generation.minutesPlannedNew,
        sessions: _syncSessionsWithActualMinutes(
          template: plan.sessions,
          minutesPlannedReviews: plan.minutesPlannedReviews,
          minutesPlannedNew: generation.minutesPlannedNew,
          revisionOnly: false,
        ),
      );
    });
  }

  int _compareDueRows(
    DueUnitRow a,
    DueUnitRow b,
    int todayDay,
    Map<int, String> lifecycleTierByUnitId,
    Map<int, _UnitReinforcementProfile> reinforcementByUnitId,
  ) {
    final overdueA = todayDay - a.schedule.dueDay;
    final overdueB = todayDay - b.schedule.dueDay;
    final weightA = reinforcementByUnitId[a.unit.id]?.weight ?? 0.0;
    final weightB = reinforcementByUnitId[b.unit.id]?.weight ?? 0.0;
    final reinforcementCompare = weightB.compareTo(weightA);
    final weightGap = (weightA - weightB).abs();
    final overdueGap = (overdueA - overdueB).abs();

    if (overdueGap <= 1 && weightGap >= 0.15 && reinforcementCompare != 0) {
      return reinforcementCompare;
    }

    final overdueCompare = overdueB.compareTo(overdueA);
    if (overdueCompare != 0) {
      return overdueCompare;
    }

    if (reinforcementCompare != 0) {
      return reinforcementCompare;
    }

    final lifecycleCompare = _lifecycleSortRank(
      _resolveLifecycleTier(a.unit.id, lifecycleTierByUnitId),
    ).compareTo(
      _lifecycleSortRank(
        _resolveLifecycleTier(b.unit.id, lifecycleTierByUnitId),
      ),
    );
    if (lifecycleCompare != 0) {
      return lifecycleCompare;
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

  Future<Map<int, _UnitReinforcementProfile>> _loadReinforcementProfileByUnitId(
    Iterable<int> unitIds,
  ) async {
    final ids = unitIds.toSet().toList(growable: false);
    if (ids.isEmpty) {
      return const <int, _UnitReinforcementProfile>{};
    }

    final rows = await (_db.select(_db.companionStepProficiency)
          ..where((tbl) => tbl.unitId.isIn(ids)))
        .get();

    final grouped = <int, List<CompanionStepProficiencyData>>{};
    for (final row in rows) {
      final unitRows = grouped.putIfAbsent(
        row.unitId,
        () => <CompanionStepProficiencyData>[],
      );
      unitRows.add(row);
    }

    return <int, _UnitReinforcementProfile>{
      for (final unitId in ids)
        unitId: _buildReinforcementProfile(grouped[unitId] ?? const []),
    };
  }

  Future<Map<int, String>> _loadLifecycleTierByUnitId(
    Iterable<int> unitIds,
  ) async {
    final ids = unitIds.toSet().toList(growable: false);
    if (ids.isEmpty) {
      return const <int, String>{};
    }

    final rows = await (_db.select(_db.companionLifecycleState)
          ..where((tbl) => tbl.unitId.isIn(ids)))
        .get();
    return <int, String>{
      for (final row in rows) row.unitId: row.lifecycleTier,
    };
  }

  String _resolveLifecycleTier(
    int unitId,
    Map<int, String> lifecycleTierByUnitId,
  ) {
    return lifecycleTierByUnitId[unitId] ?? 'emerging';
  }

  int _lifecycleSortRank(String lifecycleTier) {
    return switch (lifecycleTier) {
      'emerging' => 0,
      'ready' => 1,
      'stable' => 2,
      'maintained' => 3,
      _ => 0,
    };
  }

  _UnitReinforcementProfile _buildReinforcementProfile(
    List<CompanionStepProficiencyData> rows,
  ) {
    if (rows.isEmpty) {
      return const _UnitReinforcementProfile();
    }

    var proficiencyTotal = 0.0;
    var passRateTotal = 0.0;
    var confidenceTotal = 0.0;
    var confidenceCount = 0;
    var weakStepCount = 0;

    for (final row in rows) {
      final proficiency = row.proficiencyEma.clamp(0.0, 1.0);
      final attempts = row.attemptsCount;
      final passRate =
          attempts <= 0 ? 1.0 : (row.passesCount / attempts).clamp(0.0, 1.0);
      final confidence = row.lastEvaluatorConfidence?.clamp(0.0, 1.0);

      proficiencyTotal += proficiency;
      passRateTotal += passRate;
      if (confidence != null) {
        confidenceTotal += confidence;
        confidenceCount += 1;
      }

      final weakByProficiency = proficiency < 0.55;
      final weakByPassRate = passRate < 0.70;
      final weakByConfidence = confidence != null && confidence < 0.60;
      if (weakByProficiency || weakByPassRate || weakByConfidence) {
        weakStepCount += 1;
      }
    }

    final stepCount = rows.length;
    final averageProficiency = proficiencyTotal / stepCount;
    final averagePassRate = passRateTotal / stepCount;
    final averageConfidence =
        confidenceCount == 0 ? null : confidenceTotal / confidenceCount;
    final weakStepFraction = weakStepCount / stepCount;

    final proficiencyDeficit = 1.0 - averageProficiency;
    final passRateDeficit = 1.0 - averagePassRate;
    final confidenceDeficit =
        averageConfidence == null ? 0.0 : (1.0 - averageConfidence);

    final weight = (proficiencyDeficit * 0.45) +
        (passRateDeficit * 0.30) +
        (weakStepFraction * 0.20) +
        (confidenceDeficit * 0.05);

    return _UnitReinforcementProfile(
      averageProficiency: averageProficiency,
      averagePassRate: averagePassRate,
      averageConfidence: averageConfidence,
      weakStepFraction: weakStepFraction,
      weight: weight.clamp(0.0, 1.0),
    );
  }

  Future<List<Stage4DueItem>> _buildStage4DueItems({
    required int todayDay,
  }) async {
    final rows = await _companionRepo.getDueLifecycleStates(todayDay: todayDay);
    if (rows.isEmpty) {
      return const <Stage4DueItem>[];
    }

    final unitIds =
        rows.map((row) => row.unitId).toSet().toList(growable: false);
    final units = await (_db.select(_db.memUnit)
          ..where((tbl) => tbl.id.isIn(unitIds)))
        .get();
    final unitById = <int, MemUnitData>{
      for (final unit in units) unit.id: unit
    };

    final dueItems = <Stage4DueItem>[];
    for (final row in rows) {
      final unit = unitById[row.unitId];
      if (unit == null) {
        continue;
      }
      final dueResolution = _resolveDueKind(row, todayDay);
      if (dueResolution == null) {
        continue;
      }
      dueItems.add(
        Stage4DueItem(
          unit: unit,
          lifecycle: row,
          dueKind: dueResolution.dueKind,
          dueDay: dueResolution.dueDay,
          mandatory: dueResolution.mandatory,
          overdueDays: (todayDay - dueResolution.dueDay).clamp(0, 3650),
          unresolvedTargetsCount:
              _countTargetsFromJson(row.stage4UnresolvedTargetsJson),
        ),
      );
    }

    dueItems.sort((a, b) {
      final overdueCompare = b.overdueDays.compareTo(a.overdueDays);
      if (overdueCompare != 0) {
        return overdueCompare;
      }
      final mandatoryCompare =
          (b.mandatory ? 1 : 0).compareTo(a.mandatory ? 1 : 0);
      if (mandatoryCompare != 0) {
        return mandatoryCompare;
      }
      final unresolvedCompare =
          b.unresolvedTargetsCount.compareTo(a.unresolvedTargetsCount);
      if (unresolvedCompare != 0) {
        return unresolvedCompare;
      }
      return a.unit.id.compareTo(b.unit.id);
    });

    return dueItems;
  }

  Future<Stage4QualitySnapshot> _buildStage4QualitySnapshot() async {
    final rows = await _db.select(_db.companionLifecycleState).get();
    var emerging = 0;
    var ready = 0;
    var stable = 0;
    var maintained = 0;
    for (final row in rows) {
      switch (row.lifecycleTier) {
        case 'ready':
          ready += 1;
        case 'stable':
          stable += 1;
        case 'maintained':
          maintained += 1;
        default:
          emerging += 1;
      }
    }
    return Stage4QualitySnapshot(
      emergingCount: emerging,
      readyCount: ready,
      stableCount: stable,
      maintainedCount: maintained,
      qualityStreakDays: 0,
      todayQuests: const <String>[
        'Complete today\'s Stage-4 check',
        '1 successful random-start probe',
        '1 rabt linking check',
        '1 discrimination set',
      ],
    );
  }

  _Stage4DueResolution? _resolveDueKind(
    CompanionLifecycleStateData row,
    int todayDay,
  ) {
    final retryDay = row.stage4RetryDueDay;
    if (retryDay != null && retryDay <= todayDay) {
      return _Stage4DueResolution(
        dueKind: 'retry_required',
        dueDay: retryDay,
        mandatory: true,
      );
    }
    final nextDay = row.stage4NextDayDueDay;
    if (nextDay != null && nextDay <= todayDay) {
      return _Stage4DueResolution(
        dueKind: 'next_day_required',
        dueDay: nextDay,
        mandatory: true,
      );
    }
    final preSleepDay = row.stage4PreSleepDueDay;
    if (preSleepDay != null && preSleepDay <= todayDay) {
      return _Stage4DueResolution(
        dueKind: 'pre_sleep_optional',
        dueDay: preSleepDay,
        mandatory: false,
      );
    }
    return null;
  }

  int _countTargetsFromJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 0;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.length;
      }
      if (decoded is Map<String, dynamic>) {
        final unresolved = decoded['targets'];
        if (unresolved is List) {
          return unresolved.length;
        }
      }
    } catch (_) {
      return 0;
    }
    return 0;
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

  Future<Map<int, double>> _estimateReviewMinutesByUnitId(
    Iterable<MemUnitData> units,
    double avgReviewMinutesPerAyah,
  ) async {
    final result = <int, double>{};
    for (final unit in units) {
      result[unit.id] = await _estimateReviewMinutesForUnit(
        unit,
        avgReviewMinutesPerAyah,
      );
    }
    return result;
  }

  double _weightedReviewDemandMinutes({
    required List<DueUnitRow> dueRows,
    required Map<int, double> reviewMinutesByUnitId,
    required Map<int, _UnitReinforcementProfile> reinforcementByUnitId,
  }) {
    var total = 0.0;
    for (final dueRow in dueRows) {
      final reviewMinutes = reviewMinutesByUnitId[dueRow.unit.id] ?? 0.0;
      final multiplier =
          reinforcementByUnitId[dueRow.unit.id]?.demandMultiplier ?? 1.0;
      total += reviewMinutes * multiplier;
    }
    return total;
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

  Future<bool> _hasAnyMemUnits() async {
    final countExp = _db.memUnit.id.count();
    final row =
        await (_db.selectOnly(_db.memUnit)..addColumns([countExp])).getSingle();
    return (row.read(countExp) ?? 0) > 0;
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

class _Stage4DueResolution {
  const _Stage4DueResolution({
    required this.dueKind,
    required this.dueDay,
    required this.mandatory,
  });

  final String dueKind;
  final int dueDay;
  final bool mandatory;
}

class _UnitReinforcementProfile {
  const _UnitReinforcementProfile({
    this.averageProficiency = 1.0,
    this.averagePassRate = 1.0,
    this.averageConfidence,
    this.weakStepFraction = 0.0,
    this.weight = 0.0,
  });

  final double averageProficiency;
  final double averagePassRate;
  final double? averageConfidence;
  final double weakStepFraction;
  final double weight;

  double get demandMultiplier => 1.0 + weight;
}
