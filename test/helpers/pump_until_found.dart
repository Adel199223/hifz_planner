import 'package:flutter_test/flutter_test.dart';

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
  Duration step = const Duration(milliseconds: 50),
}) async {
  var elapsed = Duration.zero;

  while (elapsed <= timeout) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(step);
    elapsed += step;
  }

  throw TestFailure(
    'Timed out after ${timeout.inMilliseconds}ms waiting for $finder.',
  );
}
