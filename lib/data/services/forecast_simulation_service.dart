import 'dart:convert';
import 'dart:math' as math;

import '../database/app_database.dart';
import '../repositories/progress_repo.dart';
import '../repositories/quran_repo.dart';
import '../repositories/schedule_repo.dart';
import '../repositories/settings_repo.dart';
import '../time/local_day_time.dart';
import 'spaced_repetition_scheduler.dart';

enum ForecastGradeStrategy {
  distributionCycle,
  defaultFallback,
}

class ForecastWeekPoint {
  const ForecastWeekPoint({
    required this.weekIndex,
    required this.startDay,
    required this.endDay,
    required this.weeklyMinutes,
    required this.revisionOnlyRatio,
    required this.avgNewPagesPerDay,
  });

  final int weekIndex;
  final int startDay;
  final int endDay;
  final double weeklyMinutes;
  final double revisionOnlyRatio;
  final double avgNewPagesPerDay;
}

class ForecastSimulationResult {
  const ForecastSimulationResult({
    required this.estimatedCompletionDate,
    required this.incompleteReason,
    required this.weeklyPoints,
    required this.weeklyMinutesCurve,
    required this.revisionOnlyRatioCurve,
    required this.avgNewPagesPerDayCurve,
    required this.gradeStrategyUsed,
  });

  final DateTime? estimatedCompletionDate;
  final String? incompleteReason;
  final List<ForecastWeekPoint> weeklyPoints;
  final List<double> weeklyMinutesCurve;
  final List<double> revisionOnlyRatioCurve;
  final List<double> avgNewPagesPerDayCurve;
  final ForecastGradeStrategy gradeStrategyUsed;
}

class ForecastSimulationService {
  ForecastSimulationService(
    this._db,
    this._settingsRepo,
    this._progressRepo,
    this._scheduleRepo,
    this._quranRepo,
  );

  final AppDatabase _db;
  final SettingsRepo _settingsRepo;
  final ProgressRepo _progressRepo;
  final ScheduleRepo _scheduleRepo;
  final QuranRepo _quranRepo;

  static const int _captureAllDueDay = 2147483647;
  static final DateTime _localEpochStart = DateTime(1970, 1, 1);

  Future<ForecastSimulationResult> simulate({
    DateTime? nowLocal,
    int? startDayOverride,
    int maxSimulationDays = 10950,
    int targetSurah = 114,
    int targetAyah = 6,
  }) async {
    if (maxSimulationDays <= 0) {
      throw ArgumentError.value(
        maxSimulationDays,
        'maxSimulationDays',
        'maxSimulationDays must be greater than 0.',
      );
    }
    if (targetSurah <= 0 || targetAyah <= 0) {
      throw ArgumentError(
        'targetSurah and targetAyah must both be positive integers.',
      );
    }

    final effectiveNow = (nowLocal ?? DateTime.now()).toLocal();
    final startDay = startDayOverride ?? localDayIndex(effectiveNow);
    await _db.ensureSingletonRows();

    final settings =
        await _settingsRepo.getSettings(todayDayOverride: startDay);
    final cursor = await _progressRepo.getCursor();
    final lastAyah = await _quranRepo.getLastAyah();
    final gradeSource = _GradeSource.fromJson(
      settings.typicalGradeDistributionJson,
    );

    if (lastAyah == null) {
      return _buildResult(
        completionDay: null,
        incompleteReason: 'No ayah data available for forecast simulation.',
        weeklyPoints: const <ForecastWeekPoint>[],
        gradeStrategyUsed: gradeSource.strategy,
      );
    }

    final dueRows = await _scheduleRepo.getDueUnits(_captureAllDueDay);
    final unitStates = <int, _SimUnitState>{};
    final scheduleStates = <int, _SimScheduleState>{};
    for (final dueRow in dueRows) {
      final ayahCount = await _estimateAyahCount(dueRow.unit);
      unitStates[dueRow.unit.id] = _SimUnitState.fromMemUnit(
        dueRow.unit,
        ayahCount: ayahCount,
      );
      scheduleStates[dueRow.schedule.unitId] =
          _SimScheduleState.fromScheduleState(dueRow.schedule);
    }

    var nextUnitId = unitStates.keys.fold<int>(
          0,
          (maxId, id) => math.max(maxId, id),
        ) +
        1;
    if (nextUnitId < 1) {
      nextUnitId = 1;
    }

    var currentSurah = cursor.nextSurah;
    var currentAyah = cursor.nextAyah;

    final weekdayMinutes = _decodeWeekdayMinutes(settings.minutesByWeekdayJson);
    final metadataBlockCache = <String, bool>{};
    final weeklyPoints = <ForecastWeekPoint>[];

    var weekStartDay = startDay;
    var weekDays = 0;
    var weekMinutes = 0.0;
    var weekRevisionOnlyDays = 0;
    var weekNewPages = 0.0;

    int? completionDay;
    String? incompleteReason;

    if (await _isCompletionReached(
      cursorSurah: currentSurah,
      cursorAyah: currentAyah,
      targetSurah: targetSurah,
      targetAyah: targetAyah,
    )) {
      completionDay = startDay;
    }

    for (var dayOffset = 0;
        completionDay == null && dayOffset < maxSimulationDays;
        dayOffset++) {
      final day = startDay + dayOffset;
      final dailyMinutes = _resolveDailyMinutes(
        defaultMinutes: settings.dailyMinutesDefault.toDouble(),
        weekdayMinutes: weekdayMinutes,
        day: day,
      );
      final reviewBudgetMinutes = dailyMinutes *
          _reviewBudgetRatio(
            settings.profile,
          );

      final dueSchedules = scheduleStates.values
          .where((state) => state.dueDay <= day)
          .toList(growable: false)
        ..sort((a, b) => _compareDueRows(a, b, day));

      final plannedReviews = <_SimScheduleState>[];
      var minutesPlannedReviews = 0.0;
      for (final state in dueSchedules) {
        final unit = unitStates[state.unitId];
        if (unit == null) {
          continue;
        }

        final estimatedMinutes =
            unit.ayahCount * settings.avgReviewMinutesPerAyah;
        if (minutesPlannedReviews + estimatedMinutes >
            reviewBudgetMinutes + 1e-9) {
          continue;
        }

        plannedReviews.add(state);
        minutesPlannedReviews += estimatedMinutes;
      }

      final dueOverflow = dueSchedules.length > plannedReviews.length;
      final revisionOnly = dueOverflow && settings.forceRevisionOnly == 1;

      for (final state in plannedReviews) {
        final reviewQ = gradeSource.nextReviewQ();
        final next = computeNextSchedule(
          currentState: SchedulerStateInput(
            ef: state.ef,
            reps: state.reps,
            intervalDays: state.intervalDays,
            dueDay: state.dueDay,
            lapseCount: state.lapseCount,
          ),
          todayDay: day,
          gradeQ: reviewQ,
        );
        scheduleStates[state.unitId] = state.copyWithOutput(next);
      }

      var minutesPlannedNew = 0.0;
      var newPagesCount = 0;
      if (!revisionOnly) {
        final metadataBlocked = await _isMetadataBlocked(
          settings: settings,
          cursorSurah: currentSurah,
          cursorAyah: currentAyah,
          cache: metadataBlockCache,
        );
        if (!metadataBlocked) {
          final newGeneration = await _generateNewUnitsForDay(
            todayDay: day,
            cursorSurah: currentSurah,
            cursorAyah: currentAyah,
            remainingMinutes:
                math.max(0.0, dailyMinutes - minutesPlannedReviews),
            settings: settings,
            initialEf: _initialEfForProfile(settings.profile),
            nextUnitId: nextUnitId,
            unitStates: unitStates,
            scheduleStates: scheduleStates,
            gradeSource: gradeSource,
            lastAyah: lastAyah,
          );
          minutesPlannedNew = newGeneration.minutesPlannedNew;
          newPagesCount = newGeneration.newPagesCount;
          currentSurah = newGeneration.nextSurah;
          currentAyah = newGeneration.nextAyah;
          nextUnitId = newGeneration.nextUnitId;
        }
      }

      weekDays += 1;
      weekMinutes += minutesPlannedReviews + minutesPlannedNew;
      if (revisionOnly) {
        weekRevisionOnlyDays += 1;
      }
      weekNewPages += newPagesCount;

      final completedToday = await _isCompletionReached(
        cursorSurah: currentSurah,
        cursorAyah: currentAyah,
        targetSurah: targetSurah,
        targetAyah: targetAyah,
      );
      if (completedToday) {
        completionDay = day;
      }

      final weekComplete = weekDays == 7;
      final reachedHorizon = dayOffset == maxSimulationDays - 1;
      if (weekComplete || completionDay != null || reachedHorizon) {
        weeklyPoints.add(
          ForecastWeekPoint(
            weekIndex: weeklyPoints.length,
            startDay: weekStartDay,
            endDay: day,
            weeklyMinutes: weekMinutes,
            revisionOnlyRatio:
                weekDays == 0 ? 0.0 : weekRevisionOnlyDays / weekDays,
            avgNewPagesPerDay: weekDays == 0 ? 0.0 : weekNewPages / weekDays,
          ),
        );
        weekStartDay = day + 1;
        weekDays = 0;
        weekMinutes = 0.0;
        weekRevisionOnlyDays = 0;
        weekNewPages = 0.0;
      }
    }

    if (completionDay == null) {
      incompleteReason =
          'Completion not reached within simulation horizon ($maxSimulationDays days).';
    }

    return _buildResult(
      completionDay: completionDay,
      incompleteReason: incompleteReason,
      weeklyPoints: weeklyPoints,
      gradeStrategyUsed: gradeSource.strategy,
    );
  }

  ForecastSimulationResult _buildResult({
    required int? completionDay,
    required String? incompleteReason,
    required List<ForecastWeekPoint> weeklyPoints,
    required ForecastGradeStrategy gradeStrategyUsed,
  }) {
    final estimatedCompletionDate = completionDay == null
        ? null
        : _localEpochStart.add(Duration(days: completionDay));

    return ForecastSimulationResult(
      estimatedCompletionDate: estimatedCompletionDate,
      incompleteReason: incompleteReason,
      weeklyPoints: List<ForecastWeekPoint>.unmodifiable(weeklyPoints),
      weeklyMinutesCurve: List<double>.unmodifiable(
        weeklyPoints.map((point) => point.weeklyMinutes),
      ),
      revisionOnlyRatioCurve: List<double>.unmodifiable(
        weeklyPoints.map((point) => point.revisionOnlyRatio),
      ),
      avgNewPagesPerDayCurve: List<double>.unmodifiable(
        weeklyPoints.map((point) => point.avgNewPagesPerDay),
      ),
      gradeStrategyUsed: gradeStrategyUsed,
    );
  }

  Future<bool> _isCompletionReached({
    required int cursorSurah,
    required int cursorAyah,
    required int targetSurah,
    required int targetAyah,
  }) async {
    if (cursorSurah != targetSurah || cursorAyah != targetAyah) {
      return false;
    }

    final after = await _quranRepo.getAyahsFromCursor(
      startSurah: cursorSurah,
      startAyah: cursorAyah + 1,
      limit: 1,
    );
    return after.isEmpty;
  }

  Future<bool> _isMetadataBlocked({
    required AppSettingsData settings,
    required int cursorSurah,
    required int cursorAyah,
    required Map<String, bool> cache,
  }) async {
    if (settings.requirePageMetadata != 1) {
      return false;
    }

    final cacheKey = '$cursorSurah:$cursorAyah';
    final cached = cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final cursorAyahRow = await _quranRepo.getAyah(cursorSurah, cursorAyah);
    if (cursorAyahRow == null || cursorAyahRow.pageMadina == null) {
      cache[cacheKey] = true;
      return true;
    }

    final coverageWindow = await _quranRepo.getAyahsFromCursor(
      startSurah: cursorSurah,
      startAyah: cursorAyah,
      limit: 20,
    );
    if (coverageWindow.isEmpty) {
      cache[cacheKey] = true;
      return true;
    }

    final withPage =
        coverageWindow.where((ayah) => ayah.pageMadina != null).length;
    final coverage = withPage / coverageWindow.length;
    final blocked = coverage < 0.90;
    cache[cacheKey] = blocked;
    return blocked;
  }

  Future<_SimNewGenerationResult> _generateNewUnitsForDay({
    required int todayDay,
    required int cursorSurah,
    required int cursorAyah,
    required double remainingMinutes,
    required AppSettingsData settings,
    required double initialEf,
    required int nextUnitId,
    required Map<int, _SimUnitState> unitStates,
    required Map<int, _SimScheduleState> scheduleStates,
    required _GradeSource gradeSource,
    required AyahData lastAyah,
  }) async {
    if (remainingMinutes <= 0 ||
        settings.maxNewUnitsPerDay <= 0 ||
        settings.maxNewPagesPerDay <= 0 ||
        settings.avgNewMinutesPerAyah <= 0) {
      return _SimNewGenerationResult(
        minutesPlannedNew: 0.0,
        nextSurah: cursorSurah,
        nextAyah: cursorAyah,
        nextUnitId: nextUnitId,
        newPagesCount: 0,
      );
    }

    var currentSurah = cursorSurah;
    var currentAyah = cursorAyah;
    var minutesPlanned = 0.0;
    var localNextUnitId = nextUnitId;
    var createdUnits = 0;
    final touchedPages = <int>{};

    while (createdUnits < settings.maxNewUnitsPerDay) {
      final minutesLeft = remainingMinutes - minutesPlanned;
      final maxAyahsByTime =
          (minutesLeft / settings.avgNewMinutesPerAyah).floor();
      if (maxAyahsByTime < 1) {
        break;
      }

      final window = await _quranRepo.getAyahsFromCursor(
        startSurah: currentSurah,
        startAyah: currentAyah,
        limit: maxAyahsByTime,
      );
      if (window.isEmpty) {
        currentSurah = lastAyah.surah;
        currentAyah = lastAyah.ayah;
        break;
      }

      final anchor = window.first;
      final anchorPage = anchor.pageMadina;
      final normalizedPage = anchorPage ?? -1;
      final isNewPage = !touchedPages.contains(normalizedPage);
      if (isNewPage && touchedPages.length >= settings.maxNewPagesPerDay) {
        break;
      }

      final unitAyahs = _takeUnitAyahs(window, anchorPage);
      final ayahCount = unitAyahs.length;
      final estimatedMinutes = ayahCount * settings.avgNewMinutesPerAyah;
      if (estimatedMinutes > minutesLeft + 1e-9) {
        break;
      }

      final start = unitAyahs.first;
      final end = unitAyahs.last;

      final unitState = _SimUnitState(
        unitId: localNextUnitId,
        pageMadina: anchorPage,
        startSurah: start.surah,
        startAyah: start.ayah,
        endSurah: end.surah,
        endAyah: end.ayah,
        ayahCount: ayahCount,
      );
      unitStates[localNextUnitId] = unitState;

      final initialState = _SimScheduleState(
        unitId: localNextUnitId,
        ef: initialEf,
        reps: 0,
        intervalDays: 0,
        dueDay: todayDay,
        lapseCount: 0,
      );
      final selfCheckQ = gradeSource.nextSelfCheckQ();
      final scheduled = computeNextSchedule(
        currentState: SchedulerStateInput(
          ef: initialState.ef,
          reps: initialState.reps,
          intervalDays: initialState.intervalDays,
          dueDay: initialState.dueDay,
          lapseCount: initialState.lapseCount,
        ),
        todayDay: todayDay,
        gradeQ: selfCheckQ,
      );
      scheduleStates[localNextUnitId] = initialState.copyWithOutput(scheduled);

      localNextUnitId += 1;
      createdUnits += 1;
      touchedPages.add(normalizedPage);
      minutesPlanned += estimatedMinutes;

      final nextAyahs = await _quranRepo.getAyahsFromCursor(
        startSurah: end.surah,
        startAyah: end.ayah + 1,
        limit: 1,
      );
      if (nextAyahs.isEmpty) {
        currentSurah = lastAyah.surah;
        currentAyah = lastAyah.ayah;
        break;
      }

      currentSurah = nextAyahs.first.surah;
      currentAyah = nextAyahs.first.ayah;
    }

    return _SimNewGenerationResult(
      minutesPlannedNew: minutesPlanned,
      nextSurah: currentSurah,
      nextAyah: currentAyah,
      nextUnitId: localNextUnitId,
      newPagesCount: touchedPages.length,
    );
  }

  List<AyahData> _takeUnitAyahs(List<AyahData> window, int? anchorPage) {
    if (window.isEmpty) {
      return const <AyahData>[];
    }
    if (anchorPage == null) {
      return window;
    }

    final unitAyahs = <AyahData>[];
    for (final ayah in window) {
      if (ayah.pageMadina != anchorPage) {
        break;
      }
      unitAyahs.add(ayah);
    }
    return unitAyahs.isEmpty ? <AyahData>[window.first] : unitAyahs;
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

  Map<String, double>? _decodeWeekdayMinutes(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) {
        return null;
      }

      final result = <String, double>{};
      for (final key in const [
        'mon',
        'tue',
        'wed',
        'thu',
        'fri',
        'sat',
        'sun'
      ]) {
        final value = decoded[key];
        if (value is num) {
          result[key] = value.toDouble();
        }
      }
      return result;
    } catch (_) {
      return null;
    }
  }

  double _resolveDailyMinutes({
    required double defaultMinutes,
    required Map<String, double>? weekdayMinutes,
    required int day,
  }) {
    if (weekdayMinutes == null) {
      return defaultMinutes;
    }

    return weekdayMinutes[_weekdayKeyForDay(day)] ?? defaultMinutes;
  }

  String _weekdayKeyForDay(int day) {
    final date = _localEpochStart.add(Duration(days: day));
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

  int _compareDueRows(_SimScheduleState a, _SimScheduleState b, int todayDay) {
    final overdueA = todayDay - a.dueDay;
    final overdueB = todayDay - b.dueDay;
    final overdueCompare = overdueB.compareTo(overdueA);
    if (overdueCompare != 0) {
      return overdueCompare;
    }

    final repsCompare = a.reps.compareTo(b.reps);
    if (repsCompare != 0) {
      return repsCompare;
    }

    final lapseCompare = b.lapseCount.compareTo(a.lapseCount);
    if (lapseCompare != 0) {
      return lapseCompare;
    }

    return a.unitId.compareTo(b.unitId);
  }

  double _reviewBudgetRatio(String profile) {
    return switch (profile) {
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
}

class _GradeSource {
  _GradeSource._({
    required this.strategy,
    required this.cycle,
  });

  factory _GradeSource.fromJson(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) {
      return _GradeSource._(
        strategy: ForecastGradeStrategy.defaultFallback,
        cycle: const <int>[],
      );
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) {
        return _GradeSource._(
          strategy: ForecastGradeStrategy.defaultFallback,
          cycle: const <int>[],
        );
      }

      const gradeOrder = <int>[5, 4, 3, 2, 0];
      final parsed = <int, int>{};
      for (final grade in gradeOrder) {
        final rawValue = decoded['$grade'] ?? decoded[grade];
        if (rawValue is! num) {
          return _GradeSource._(
            strategy: ForecastGradeStrategy.defaultFallback,
            cycle: const <int>[],
          );
        }
        final value = rawValue.toInt();
        if (value < 0 || value > 100) {
          return _GradeSource._(
            strategy: ForecastGradeStrategy.defaultFallback,
            cycle: const <int>[],
          );
        }
        parsed[grade] = value;
      }

      final total = parsed.values.fold<int>(0, (sum, value) => sum + value);
      if (total != 100) {
        return _GradeSource._(
          strategy: ForecastGradeStrategy.defaultFallback,
          cycle: const <int>[],
        );
      }

      final cycle = <int>[];
      for (final grade in gradeOrder) {
        final count = parsed[grade]!;
        for (var i = 0; i < count; i++) {
          cycle.add(grade);
        }
      }

      if (cycle.isEmpty) {
        return _GradeSource._(
          strategy: ForecastGradeStrategy.defaultFallback,
          cycle: const <int>[],
        );
      }

      return _GradeSource._(
        strategy: ForecastGradeStrategy.distributionCycle,
        cycle: cycle,
      );
    } catch (_) {
      return _GradeSource._(
        strategy: ForecastGradeStrategy.defaultFallback,
        cycle: const <int>[],
      );
    }
  }

  final ForecastGradeStrategy strategy;
  final List<int> cycle;
  int _cycleIndex = 0;

  int nextReviewQ() {
    if (strategy == ForecastGradeStrategy.defaultFallback) {
      return 4;
    }
    return _nextCycleQ();
  }

  int nextSelfCheckQ() {
    if (strategy == ForecastGradeStrategy.defaultFallback) {
      return 3;
    }
    return _nextCycleQ();
  }

  int _nextCycleQ() {
    if (cycle.isEmpty) {
      return 4;
    }
    final value = cycle[_cycleIndex % cycle.length];
    _cycleIndex += 1;
    return value;
  }
}

class _SimUnitState {
  const _SimUnitState({
    required this.unitId,
    required this.pageMadina,
    required this.startSurah,
    required this.startAyah,
    required this.endSurah,
    required this.endAyah,
    required this.ayahCount,
  });

  factory _SimUnitState.fromMemUnit(
    MemUnitData unit, {
    required int ayahCount,
  }) {
    return _SimUnitState(
      unitId: unit.id,
      pageMadina: unit.pageMadina,
      startSurah: unit.startSurah,
      startAyah: unit.startAyah,
      endSurah: unit.endSurah,
      endAyah: unit.endAyah,
      ayahCount: ayahCount,
    );
  }

  final int unitId;
  final int? pageMadina;
  final int? startSurah;
  final int? startAyah;
  final int? endSurah;
  final int? endAyah;
  final int ayahCount;
}

class _SimScheduleState {
  const _SimScheduleState({
    required this.unitId,
    required this.ef,
    required this.reps,
    required this.intervalDays,
    required this.dueDay,
    required this.lapseCount,
  });

  factory _SimScheduleState.fromScheduleState(ScheduleStateData row) {
    return _SimScheduleState(
      unitId: row.unitId,
      ef: row.ef,
      reps: row.reps,
      intervalDays: row.intervalDays,
      dueDay: row.dueDay,
      lapseCount: row.lapseCount,
    );
  }

  final int unitId;
  final double ef;
  final int reps;
  final int intervalDays;
  final int dueDay;
  final int lapseCount;

  _SimScheduleState copyWithOutput(SchedulerStateOutput output) {
    return _SimScheduleState(
      unitId: unitId,
      ef: output.ef,
      reps: output.reps,
      intervalDays: output.intervalDays,
      dueDay: output.dueDay,
      lapseCount: output.lapseCount,
    );
  }
}

class _SimNewGenerationResult {
  const _SimNewGenerationResult({
    required this.minutesPlannedNew,
    required this.nextSurah,
    required this.nextAyah,
    required this.nextUnitId,
    required this.newPagesCount,
  });

  final double minutesPlannedNew;
  final int nextSurah;
  final int nextAyah;
  final int nextUnitId;
  final int newPagesCount;
}
