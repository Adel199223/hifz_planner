import 'dart:math' as math;

import 'availability_interpreter.dart';
import 'daily_content_allocator.dart';
import 'planner_quality_signal.dart';
import 'scheduling_preferences_codec.dart';

enum PlannedSessionFocus {
  newAndReview(code: 'new_and_review'),
  reviewOnly(code: 'review_only');

  const PlannedSessionFocus({required this.code});

  final String code;
}

enum PlannedSessionStatus {
  pending(code: 'pending'),
  completed(code: 'completed'),
  missed(code: 'missed'),
  dueSoon(code: 'due_soon');

  const PlannedSessionStatus({required this.code});

  final String code;
}

class PlannedSession {
  const PlannedSession({
    required this.sessionLabel,
    required this.focus,
    required this.plannedMinutes,
    required this.plannedReviewMinutes,
    required this.plannedNewMinutes,
    required this.isTimed,
    required this.startMinuteOfDay,
    required this.status,
  });

  final String sessionLabel;
  final PlannedSessionFocus focus;
  final int plannedMinutes;
  final int plannedReviewMinutes;
  final int plannedNewMinutes;
  final bool isTimed;
  final int? startMinuteOfDay;
  final PlannedSessionStatus status;
}

class WeeklyPlanDay {
  const WeeklyPlanDay({
    required this.dayIndex,
    required this.weekday,
    required this.enabledStudyDay,
    required this.skipDay,
    required this.revisionOnlyDay,
    required this.totalPlannedMinutes,
    required this.reviewPressure,
    required this.recoveryMode,
    required this.sessions,
  });

  final int dayIndex;
  final int weekday;
  final bool enabledStudyDay;
  final bool skipDay;
  final bool revisionOnlyDay;
  final int totalPlannedMinutes;
  final double reviewPressure;
  final bool recoveryMode;
  final List<PlannedSession> sessions;
}

class WeeklyPlan {
  const WeeklyPlan({required this.startDay, required this.days});

  final int startDay;
  final List<WeeklyPlanDay> days;
}

class WeeklyPlanGenerator {
  const WeeklyPlanGenerator({
    AvailabilityInterpreter availabilityInterpreter =
        const AvailabilityInterpreter(),
    DailyContentAllocator dailyContentAllocator = const DailyContentAllocator(),
  }) : _availabilityInterpreter = availabilityInterpreter,
       _dailyContentAllocator = dailyContentAllocator;

  final AvailabilityInterpreter _availabilityInterpreter;
  final DailyContentAllocator _dailyContentAllocator;

  WeeklyPlan generate({
    required int startDay,
    required int horizonDays,
    required SchedulingPreferencesV1 preferences,
    required SchedulingOverridesV1 overrides,
    required Map<int, double> dueReviewMinutesByDay,
    required double reviewBudgetRatio,
    required bool forceRevisionOnly,
    PlannerQualitySignal qualitySignal = const PlannerQualitySignal.neutral(),
  }) {
    final minutesByDay = _availabilityInterpreter
        .resolveTargetMinutesForHorizon(
          startDay: startDay,
          horizonDays: horizonDays,
          preferences: preferences,
          overrides: overrides,
        );

    final days = <WeeklyPlanDay>[];

    for (var offset = 0; offset < horizonDays; offset++) {
      final dayIndex = startDay + offset;
      final availability = _availabilityInterpreter.resolveDay(
        dayIndex: dayIndex,
        preferences: preferences,
        overrides: overrides,
        minutesByDay: minutesByDay,
      );

      if (!availability.enabledStudyDay || availability.targetMinutes <= 0) {
        days.add(
          WeeklyPlanDay(
            dayIndex: dayIndex,
            weekday: availability.weekday,
            enabledStudyDay: availability.enabledStudyDay,
            skipDay: availability.skipDay,
            revisionOnlyDay: availability.revisionOnlyDay,
            totalPlannedMinutes: 0,
            reviewPressure: 0,
            recoveryMode: false,
            sessions: const <PlannedSession>[],
          ),
        );
        continue;
      }

      final dueReviewMinutes = dueReviewMinutesByDay[dayIndex] ?? 0;
      final allocation = _dailyContentAllocator.allocate(
        dailyMinutes: availability.targetMinutes.toDouble(),
        dueReviewMinutes: dueReviewMinutes,
        baseReviewRatio: reviewBudgetRatio,
        forceRevisionOnly: forceRevisionOnly || availability.revisionOnlyDay,
        qualitySignal: qualitySignal,
      );

      final desiredSessions = preferences.sessionsPerDay.clamp(1, 2);
      final effectiveSessions = availability.targetMinutes < 24
          ? 1
          : desiredSessions;
      final sessionMinutes = _splitSessionMinutes(
        totalMinutes: availability.targetMinutes,
        sessionCount: effectiveSessions,
      );

      final timedMinutes = _resolveSessionStartTimes(
        dayIndex: dayIndex,
        preferences: preferences,
        overrides: overrides,
        windows: availability.windows,
        sessionCount: effectiveSessions,
      );

      final sessions = <PlannedSession>[];
      var consumedReview = 0;
      for (var i = 0; i < effectiveSessions; i++) {
        final label = i == 0 ? 'Session A' : 'Session B';
        final minutes = sessionMinutes[i];

        final reviewRemaining = math.max(
          0,
          allocation.reviewCapacityMinutes.round() - consumedReview,
        );
        final sessionReview = math.min(reviewRemaining, minutes);
        consumedReview += sessionReview;
        final sessionNew = math.max(0, minutes - sessionReview);

        final focus =
            !allocation.newAssignmentsAllowed || availability.revisionOnlyDay
            ? PlannedSessionFocus.reviewOnly
            : PlannedSessionFocus.newAndReview;
        final status = allocation.health != DailyAllocationHealth.onTrack
            ? PlannedSessionStatus.dueSoon
            : PlannedSessionStatus.pending;

        sessions.add(
          PlannedSession(
            sessionLabel: label,
            focus: focus,
            plannedMinutes: minutes,
            plannedReviewMinutes: sessionReview,
            plannedNewMinutes: focus == PlannedSessionFocus.reviewOnly
                ? 0
                : sessionNew,
            isTimed: timedMinutes[i] != null,
            startMinuteOfDay: timedMinutes[i],
            status: status,
          ),
        );
      }

      days.add(
        WeeklyPlanDay(
          dayIndex: dayIndex,
          weekday: availability.weekday,
          enabledStudyDay: true,
          skipDay: availability.skipDay,
          revisionOnlyDay: availability.revisionOnlyDay,
          totalPlannedMinutes: availability.targetMinutes,
          reviewPressure: allocation.reviewPressure,
          recoveryMode: allocation.recoveryMode,
          sessions: sessions,
        ),
      );
    }

    return WeeklyPlan(startDay: startDay, days: days);
  }

  List<int?> _resolveSessionStartTimes({
    required int dayIndex,
    required SchedulingPreferencesV1 preferences,
    required SchedulingOverridesV1 overrides,
    required List<TimeWindow> windows,
    required int sessionCount,
  }) {
    if (preferences.timingStrategy == TimingStrategy.untimed &&
        !preferences.exactTimesEnabled) {
      return List<int?>.filled(sessionCount, null);
    }

    final override = overrides[dayIndex];
    final preferred = <int?>[
      override?.sessionATimeMinute ?? preferences.sessionATimeMinute,
      override?.sessionBTimeMinute ?? preferences.sessionBTimeMinute,
    ];

    if (preferences.timingStrategy == TimingStrategy.fixedTimes ||
        preferences.exactTimesEnabled) {
      return _clampToWindows(
        preferredTimes: preferred,
        windows: windows,
        flexOutsideWindows: preferences.flexOutsideWindows,
        sessionCount: sessionCount,
      );
    }

    final autoPlaced = _autoPlaceWithinWindows(
      windows: windows,
      sessionCount: sessionCount,
      fallbackTimes: preferred,
      flexOutsideWindows: preferences.flexOutsideWindows,
    );
    return autoPlaced;
  }

  List<int?> _autoPlaceWithinWindows({
    required List<TimeWindow> windows,
    required int sessionCount,
    required List<int?> fallbackTimes,
    required bool flexOutsideWindows,
  }) {
    if (windows.isEmpty) {
      return List<int?>.generate(sessionCount, (index) => fallbackTimes[index]);
    }

    final orderedWindows = [...windows]
      ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
    final firstWindow = orderedWindows.first;
    final lastWindow = orderedWindows.last;

    if (sessionCount == 1) {
      final midpoint = (firstWindow.startMinute + firstWindow.endMinute) ~/ 2;
      return [
        _nearestValidMinute(
          requested: midpoint,
          windows: orderedWindows,
          flexOutsideWindows: flexOutsideWindows,
        ),
      ];
    }

    final firstStart = _nearestValidMinute(
      requested: firstWindow.startMinute,
      windows: orderedWindows,
      flexOutsideWindows: flexOutsideWindows,
    );

    final secondRequested =
        math.max(
          firstStart ?? firstWindow.startMinute,
          firstWindow.startMinute,
        ) +
        90;
    final secondStart = _nearestValidMinute(
      requested: secondRequested,
      windows: orderedWindows,
      flexOutsideWindows: flexOutsideWindows,
      fallbackRequested: lastWindow.startMinute,
    );

    if (firstStart != null && secondStart != null) {
      return [firstStart, secondStart];
    }

    if (firstStart != null && secondStart == null) {
      return [firstStart, null];
    }

    return [fallbackTimes[0], fallbackTimes[1]];
  }

  List<int?> _clampToWindows({
    required List<int?> preferredTimes,
    required List<TimeWindow> windows,
    required bool flexOutsideWindows,
    required int sessionCount,
  }) {
    if (windows.isEmpty) {
      return List<int?>.generate(
        sessionCount,
        (index) => preferredTimes[index],
      );
    }

    return List<int?>.generate(sessionCount, (index) {
      final requested = preferredTimes[index];
      if (requested == null) {
        return null;
      }
      return _nearestValidMinute(
        requested: requested,
        windows: windows,
        flexOutsideWindows: flexOutsideWindows,
      );
    });
  }

  int? _nearestValidMinute({
    required int requested,
    required List<TimeWindow> windows,
    required bool flexOutsideWindows,
    int? fallbackRequested,
  }) {
    if (windows.isEmpty) {
      return requested.clamp(0, 1439);
    }

    for (final window in windows) {
      if (requested >= window.startMinute && requested < window.endMinute) {
        return requested.clamp(0, 1439);
      }
    }

    if (flexOutsideWindows) {
      return requested.clamp(0, 1439);
    }

    var bestMinute = fallbackRequested;
    var bestDistance = 1 << 30;

    void consider(int candidate) {
      final distance = (candidate - requested).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestMinute = candidate;
      }
    }

    for (final window in windows) {
      consider(window.startMinute);
      consider(math.max(window.startMinute, window.endMinute - 1));
    }

    return bestMinute?.clamp(0, 1439);
  }

  List<int> _splitSessionMinutes({
    required int totalMinutes,
    required int sessionCount,
  }) {
    if (sessionCount <= 1) {
      return <int>[totalMinutes];
    }

    final first = (totalMinutes / 2).ceil();
    final second = totalMinutes - first;
    return <int>[first, second];
  }
}
