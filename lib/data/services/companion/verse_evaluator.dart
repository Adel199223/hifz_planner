import 'companion_models.dart';

class VerseEvaluationRequest {
  const VerseEvaluationRequest({
    required this.verse,
    this.manualFallbackPass,
    this.asrConfidence,
  });

  final ChainVerse verse;
  final bool? manualFallbackPass;
  final double? asrConfidence;
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
    final passed = request.manualFallbackPass ?? false;
    return VerseEvaluationResult(
      passed: passed,
      confidence: request.asrConfidence,
      mode: EvaluatorMode.manualFallback,
    );
  }
}
