import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/scheduling/daily_content_allocator.dart';

void main() {
  const allocator = DailyContentAllocator();

  test('review pressure bands reduce new budget progressively', () {
    final normal = allocator.allocate(
      dailyMinutes: 60,
      dueReviewMinutes: 30,
      baseReviewRatio: 0.7,
      forceRevisionOnly: false,
    );
    final moderate = allocator.allocate(
      dailyMinutes: 60,
      dueReviewMinutes: 45,
      baseReviewRatio: 0.7,
      forceRevisionOnly: false,
    );
    final high = allocator.allocate(
      dailyMinutes: 60,
      dueReviewMinutes: 55,
      baseReviewRatio: 0.7,
      forceRevisionOnly: false,
    );
    final recovery = allocator.allocate(
      dailyMinutes: 60,
      dueReviewMinutes: 80,
      baseReviewRatio: 0.7,
      forceRevisionOnly: false,
    );

    expect(normal.newReductionFraction, 0.0);
    expect(moderate.newReductionFraction, 0.25);
    expect(high.newReductionFraction, 0.50);
    expect(recovery.newReductionFraction, 1.0);
    expect(recovery.recoveryMode, isTrue);
    expect(recovery.newBudgetMinutes, 0);
  });

  test('forceRevisionOnly with overflow forces recovery mode', () {
    final allocation = allocator.allocate(
      dailyMinutes: 45,
      dueReviewMinutes: 80,
      baseReviewRatio: 0.7,
      forceRevisionOnly: true,
    );

    expect(allocation.recoveryMode, isTrue);
    expect(allocation.newBudgetMinutes, 0);
    expect(allocation.reviewCapacityMinutes, 45);
  });
}
