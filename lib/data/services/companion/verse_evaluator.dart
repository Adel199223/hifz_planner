import 'companion_models.dart';

class VerseEvaluationSubmission {
  const VerseEvaluationSubmission({
    required this.sourceMode,
    this.manualFallbackPass,
    this.asrTranscript,
    this.asrConfidence,
    this.asrProvider,
  });

  const VerseEvaluationSubmission.manual({
    required bool passed,
  }) : this(
          sourceMode: EvaluatorMode.manualFallback,
          manualFallbackPass: passed,
        );

  final EvaluatorMode sourceMode;
  final bool? manualFallbackPass;
  final String? asrTranscript;
  final double? asrConfidence;
  final String? asrProvider;
}

class VerseEvaluationRequest {
  const VerseEvaluationRequest({
    required this.verse,
    required this.submission,
  });

  final ChainVerse verse;
  final VerseEvaluationSubmission submission;
}

class VerseEvaluationResult {
  const VerseEvaluationResult({
    required this.passed,
    required this.confidence,
    required this.mode,
  });

  final bool passed;
  final double? confidence;
  final EvaluatorMode mode;
}

abstract class VerseEvaluator {
  Future<VerseEvaluationResult> evaluate(VerseEvaluationRequest request);
}

class ManualFallbackVerseEvaluator implements VerseEvaluator {
  const ManualFallbackVerseEvaluator();

  @override
  Future<VerseEvaluationResult> evaluate(VerseEvaluationRequest request) async {
    final passed = request.submission.manualFallbackPass ?? false;
    return VerseEvaluationResult(
      passed: passed,
      confidence: request.submission.asrConfidence,
      mode: EvaluatorMode.manualFallback,
    );
  }
}
