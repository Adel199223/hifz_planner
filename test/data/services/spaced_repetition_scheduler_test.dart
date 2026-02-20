import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/spaced_repetition_scheduler.dart';

void main() {
  test('grade enum maps to expected q values', () {
    expect(gradeToQ(Grade.good), 5);
    expect(gradeToQ(Grade.medium), 4);
    expect(gradeToQ(Grade.hard), 3);
    expect(gradeToQ(Grade.veryHard), 2);
    expect(gradeToQ(Grade.fail), 0);
  });

  test('q values map back to expected enum grades', () {
    expect(gradeFromQ(5), Grade.good);
    expect(gradeFromQ(4), Grade.medium);
    expect(gradeFromQ(3), Grade.hard);
    expect(gradeFromQ(2), Grade.veryHard);
    expect(gradeFromQ(0), Grade.fail);
  });

  test('gradeFromQ throws for unsupported q', () {
    expect(() => gradeFromQ(1), throwsA(isA<ArgumentError>()));
  });

  test('computeNextSchedule fail reset behavior', () {
    const input = SchedulerStateInput(
      ef: 2.4,
      reps: 5,
      intervalDays: 19,
      dueDay: 100,
      lapseCount: 2,
    );

    final result = computeNextSchedule(
      currentState: input,
      todayDay: 200,
      gradeQ: 0,
    );

    expect(result.ef, 2.4);
    expect(result.reps, 0);
    expect(result.intervalDays, 1);
    expect(result.dueDay, 201);
    expect(result.lapseCount, 3);
    expect(result.lastReviewDay, 200);
    expect(result.lastGradeQ, 0);
  });

  test('computeNextSchedule clamps EF at minimum 1.3', () {
    const input = SchedulerStateInput(
      ef: 1.31,
      reps: 2,
      intervalDays: 10,
      dueDay: 100,
      lapseCount: 0,
    );

    final result = computeNextSchedule(
      currentState: input,
      todayDay: 50,
      gradeQ: 3,
    );

    expect(result.ef, 1.3);
    expect(result.reps, 3);
    expect(result.intervalDays, 13);
    expect(result.dueDay, 63);
    expect(result.lapseCount, 0);
    expect(result.lastReviewDay, 50);
    expect(result.lastGradeQ, 3);
  });

  test('computeNextSchedule interval behavior for reps 1,2,>=3', () {
    final firstRep = computeNextSchedule(
      currentState: const SchedulerStateInput(
        ef: 2.5,
        reps: 0,
        intervalDays: 7,
        dueDay: 10,
        lapseCount: 0,
      ),
      todayDay: 300,
      gradeQ: 5,
    );
    expect(firstRep.reps, 1);
    expect(firstRep.intervalDays, 1);
    expect(firstRep.dueDay, 301);

    final secondRep = computeNextSchedule(
      currentState: const SchedulerStateInput(
        ef: 2.5,
        reps: 1,
        intervalDays: 7,
        dueDay: 10,
        lapseCount: 0,
      ),
      todayDay: 300,
      gradeQ: 4,
    );
    expect(secondRep.reps, 2);
    expect(secondRep.intervalDays, 6);
    expect(secondRep.dueDay, 306);

    final thirdRepPlus = computeNextSchedule(
      currentState: const SchedulerStateInput(
        ef: 2.0,
        reps: 2,
        intervalDays: 10,
        dueDay: 10,
        lapseCount: 0,
      ),
      todayDay: 300,
      gradeQ: 4,
    );
    expect(thirdRepPlus.reps, 3);
    expect(thirdRepPlus.ef, 2.0);
    expect(thirdRepPlus.intervalDays, 20);
    expect(thirdRepPlus.dueDay, 320);
  });

  test('computeNextSchedule throws for unsupported grade_q', () {
    expect(
      () => computeNextSchedule(
        currentState: const SchedulerStateInput(
          ef: 2.5,
          reps: 0,
          intervalDays: 0,
          dueDay: 0,
          lapseCount: 0,
        ),
        todayDay: 1,
        gradeQ: 1,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
