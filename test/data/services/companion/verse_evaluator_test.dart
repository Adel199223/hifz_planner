import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/companion/companion_models.dart';
import 'package:hifz_planner/data/services/companion/verse_evaluator.dart';

void main() {
  const verse = ChainVerse(
    surah: 1,
    ayah: 1,
    text: 'الحمد لله رب العالمين',
  );

  test('manual submission constructor sets manual fallback source', () {
    const submission = VerseEvaluationSubmission.manual(passed: true);

    expect(submission.sourceMode, EvaluatorMode.manualFallback);
    expect(submission.manualFallbackPass, isTrue);
    expect(submission.asrTranscript, isNull);
    expect(submission.asrConfidence, isNull);
    expect(submission.asrProvider, isNull);
  });

  test(
      'manual fallback evaluator uses submission payload and preserves confidence',
      () async {
    const evaluator = ManualFallbackVerseEvaluator();

    final result = await evaluator.evaluate(
      const VerseEvaluationRequest(
        verse: verse,
        submission: VerseEvaluationSubmission(
          sourceMode: EvaluatorMode.manualFallback,
          manualFallbackPass: true,
          asrTranscript: 'future transcript',
          asrConfidence: 0.84,
          asrProvider: 'future-provider',
        ),
      ),
    );

    expect(result.passed, isTrue);
    expect(result.mode, EvaluatorMode.manualFallback);
    expect(result.confidence, 0.84);
  });
}
