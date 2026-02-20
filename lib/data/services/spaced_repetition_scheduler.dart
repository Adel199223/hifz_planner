enum Grade {
  good,
  medium,
  hard,
  veryHard,
  fail,
}

class SchedulerStateInput {
  const SchedulerStateInput({
    required this.ef,
    required this.reps,
    required this.intervalDays,
    required this.dueDay,
    required this.lapseCount,
  });

  final double ef;
  final int reps;
  final int intervalDays;
  final int dueDay;
  final int lapseCount;
}

class SchedulerStateOutput {
  const SchedulerStateOutput({
    required this.ef,
    required this.reps,
    required this.intervalDays,
    required this.dueDay,
    required this.lapseCount,
    required this.lastReviewDay,
    required this.lastGradeQ,
  });

  final double ef;
  final int reps;
  final int intervalDays;
  final int dueDay;
  final int lapseCount;
  final int lastReviewDay;
  final int lastGradeQ;
}

const Set<int> _supportedQs = {5, 4, 3, 2, 0};

int gradeToQ(Grade grade) {
  switch (grade) {
    case Grade.good:
      return 5;
    case Grade.medium:
      return 4;
    case Grade.hard:
      return 3;
    case Grade.veryHard:
      return 2;
    case Grade.fail:
      return 0;
  }
}

Grade gradeFromQ(int q) {
  switch (q) {
    case 5:
      return Grade.good;
    case 4:
      return Grade.medium;
    case 3:
      return Grade.hard;
    case 2:
      return Grade.veryHard;
    case 0:
      return Grade.fail;
  }
  throw ArgumentError.value(
    q,
    'q',
    'Unsupported q value. Expected one of 5,4,3,2,0.',
  );
}

SchedulerStateOutput computeNextSchedule({
  required SchedulerStateInput currentState,
  required int todayDay,
  required int gradeQ,
}) {
  if (!_supportedQs.contains(gradeQ)) {
    throw ArgumentError.value(
      gradeQ,
      'gradeQ',
      'Unsupported grade_q value. Expected one of 5,4,3,2,0.',
    );
  }

  if (gradeQ < 3) {
    return SchedulerStateOutput(
      ef: currentState.ef,
      reps: 0,
      intervalDays: 1,
      dueDay: todayDay + 1,
      lapseCount: currentState.lapseCount + 1,
      lastReviewDay: todayDay,
      lastGradeQ: gradeQ,
    );
  }

  final nextReps = currentState.reps + 1;
  final distanceFromFive = 5 - gradeQ;
  final nextEfUnclamped = currentState.ef +
      (0.1 - (distanceFromFive * (0.08 + (distanceFromFive * 0.02))));
  final nextEf = nextEfUnclamped < 1.3 ? 1.3 : nextEfUnclamped;

  final intervalDays = switch (nextReps) {
    1 => 1,
    2 => 6,
    _ => (currentState.intervalDays * nextEf).round(),
  };

  return SchedulerStateOutput(
    ef: nextEf,
    reps: nextReps,
    intervalDays: intervalDays,
    dueDay: todayDay + intervalDays,
    lapseCount: currentState.lapseCount,
    lastReviewDay: todayDay,
    lastGradeQ: gradeQ,
  );
}
