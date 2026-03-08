import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/scheduling/daily_content_allocator.dart';

void main() {
  const allocator = DailyContentAllocator();

  test('weighted stress bands reduce new budget and classify health', () {
    final onTrack = allocator.allocate(
      dailyMinutes: 60,
      dueReviewMinutes: 30,
      baseReviewRatio: 0.7,
      forceRevisionOnly: false,
    );
    final tight = allocator.allocate(
      dailyMinutes: 60,
      dueReviewMinutes: 45,
      baseReviewRatio: 0.7,
      forceRevisionOnly: false,
    );
    final overloaded = allocator.allocate(
      dailyMinutes: 60,
      dueReviewMinutes: 55,
      baseReviewRatio: 0.7,
      forceRevisionOnly: false,
    );

    expect(onTrack.health, DailyAllocationHealth.onTrack);
    expect(onTrack.newReductionFraction, 0.0);
    expect(onTrack.newAssignmentsAllowed, isTrue);

    expect(tight.health, DailyAllocationHealth.tight);
    expect(tight.newReductionFraction, 0.50);
    expect(tight.newBudgetMinutes, greaterThan(0));

    expect(overloaded.health, DailyAllocationHealth.overloaded);
    expect(overloaded.newReductionFraction, 1.0);
    expect(overloaded.recoveryMode, isTrue);
    expect(overloaded.newBudgetMinutes, 0);
    expect(overloaded.newAssignmentsAllowed, isFalse);
  });

  test('mandatory stage-4 pressure reserves time and suggests minimum day', () {
    final allocation = allocator.allocate(
      dailyMinutes: 30,
      dueReviewMinutes: 10,
      baseReviewRatio: 0.7,
      forceRevisionOnly: false,
      mandatoryStage4Minutes: 6,
    );

    expect(allocation.mandatoryStage4Minutes, 6);
    expect(allocation.health, isNot(DailyAllocationHealth.onTrack));
    expect(allocation.minimumDaySuggested, isTrue);
    expect(allocation.reviewCapacityMinutes, greaterThan(20));
  });

  test('forceRevisionOnly always produces a revision-only day', () {
    final allocation = allocator.allocate(
      dailyMinutes: 45,
      dueReviewMinutes: 20,
      baseReviewRatio: 0.7,
      forceRevisionOnly: true,
    );

    expect(allocation.recoveryMode, isTrue);
    expect(allocation.newBudgetMinutes, 0);
    expect(allocation.newAssignmentsAllowed, isFalse);
    expect(allocation.reviewCapacityMinutes, 45);
    expect(allocation.learnerMode, DailyAllocationLearnerMode.revisionOnly);
  });
}
