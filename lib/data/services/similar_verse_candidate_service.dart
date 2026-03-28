import 'dart:math' as math;

import '../database/app_database.dart';
import '../repositories/mem_unit_repo.dart';
import '../repositories/quran_repo.dart';
import 'tanzil_text_parser.dart';

const double _similarVerseConfidenceThreshold = 0.60;
const int _similarVerseMaxCandidates = 3;

enum SimilarVerseDifferenceCueKind { openingSplit, endingLeadIn }

class SimilarVerseDifferenceCue {
  const SimilarVerseDifferenceCue({
    required this.kind,
    required this.currentToken,
    required this.candidateToken,
  });

  final SimilarVerseDifferenceCueKind kind;
  final String currentToken;
  final String candidateToken;
}

class SimilarVerseCandidateMatch {
  const SimilarVerseCandidateMatch({
    required this.unit,
    required this.excerpt,
    required this.score,
    required this.pageDistance,
    required this.differenceCue,
  });

  final MemUnitData unit;
  final String excerpt;
  final double score;
  final int? pageDistance;
  final SimilarVerseDifferenceCue? differenceCue;

  bool get isNearbyPage => pageDistance != null && pageDistance! <= 2;
}

class SimilarVerseRepairData {
  const SimilarVerseRepairData({
    required this.targetUnit,
    required this.targetExcerpt,
    required this.candidates,
  });

  final MemUnitData targetUnit;
  final String targetExcerpt;
  final List<SimilarVerseCandidateMatch> candidates;

  bool get hasConfidentCandidate => candidates.isNotEmpty;
}

class SimilarVerseCandidateService {
  SimilarVerseCandidateService(this._memUnitRepo, this._quranRepo);

  final MemUnitRepo _memUnitRepo;
  final QuranRepo _quranRepo;

  Future<SimilarVerseRepairData?> buildRescueData(int unitId) async {
    final targetUnit = await _memUnitRepo.get(unitId);
    if (targetUnit == null || !_hasRange(targetUnit)) {
      return null;
    }

    final targetText = await _loadUnitText(targetUnit);
    if (targetText == null) {
      return null;
    }

    final units = await _memUnitRepo.list();
    final candidates = <SimilarVerseCandidateMatch>[];

    for (final unit in units) {
      if (unit.id == targetUnit.id || !_hasRange(unit)) {
        continue;
      }

      final candidateText = await _loadUnitText(unit);
      if (candidateText == null) {
        continue;
      }

      final openingShared = _sharedPrefixCount(
        targetText.normalizedTokens,
        candidateText.normalizedTokens,
      );
      final endingShared = _sharedSuffixCount(
        targetText.normalizedTokens,
        candidateText.normalizedTokens,
      );
      final hasStrongAnchor = openingShared >= 2 || endingShared >= 2;
      if (!hasStrongAnchor) {
        continue;
      }

      final score = _scoreCandidate(
        target: targetText,
        candidate: candidateText,
        openingShared: openingShared,
        endingShared: endingShared,
      );
      if (score < _similarVerseConfidenceThreshold) {
        continue;
      }

      candidates.add(
        SimilarVerseCandidateMatch(
          unit: unit,
          excerpt: candidateText.excerpt,
          score: score,
          pageDistance: _pageDistance(targetUnit, unit),
          differenceCue: _deriveDifferenceCue(
            target: targetText,
            candidate: candidateText,
            openingShared: openingShared,
            endingShared: endingShared,
          ),
        ),
      );
    }

    candidates.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) {
        return byScore;
      }
      final aDistance = a.pageDistance ?? 9999;
      final bDistance = b.pageDistance ?? 9999;
      final byDistance = aDistance.compareTo(bDistance);
      if (byDistance != 0) {
        return byDistance;
      }
      return a.unit.id.compareTo(b.unit.id);
    });

    return SimilarVerseRepairData(
      targetUnit: targetUnit,
      targetExcerpt: targetText.excerpt,
      candidates: List<SimilarVerseCandidateMatch>.unmodifiable(
        candidates.take(_similarVerseMaxCandidates),
      ),
    );
  }

  bool _hasRange(MemUnitData unit) {
    return unit.startSurah != null &&
        unit.startAyah != null &&
        unit.endSurah != null &&
        unit.endAyah != null;
  }

  Future<_LoadedUnitText?> _loadUnitText(MemUnitData unit) async {
    final startSurah = unit.startSurah;
    final startAyah = unit.startAyah;
    final endSurah = unit.endSurah;
    final endAyah = unit.endAyah;
    if (startSurah == null ||
        startAyah == null ||
        endSurah == null ||
        endAyah == null) {
      return null;
    }

    final ayahs = await _quranRepo.getAyahsInRange(
      startSurah: startSurah,
      startAyah: startAyah,
      endSurah: endSurah,
      endAyah: endAyah,
    );
    if (ayahs.isEmpty) {
      return null;
    }

    final joinedText = ayahs.map((ayah) => ayah.textUthmani).join(' ').trim();
    if (joinedText.isEmpty) {
      return null;
    }
    final normalizedText = normalizeForCompareLoose(joinedText);
    final normalizedTokens = _tokenize(normalizedText);
    if (normalizedTokens.isEmpty) {
      return null;
    }

    return _LoadedUnitText(
      ayahCount: ayahs.length,
      pageMadina: unit.pageMadina,
      displayTokens: _tokenize(joinedText),
      normalizedTokens: normalizedTokens,
      tokenSet: normalizedTokens.toSet(),
      excerpt: _buildExcerpt(joinedText),
    );
  }

  List<String> _tokenize(String text) {
    return text
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }

  String _buildExcerpt(String text) {
    final tokens = _tokenize(text);
    if (tokens.length <= 18) {
      return tokens.join(' ');
    }
    return '${tokens.take(18).join(' ')}...';
  }

  int _sharedPrefixCount(List<String> a, List<String> b) {
    final limit = math.min(a.length, b.length);
    var count = 0;
    while (count < limit && a[count] == b[count]) {
      count += 1;
    }
    return count;
  }

  int _sharedSuffixCount(List<String> a, List<String> b) {
    final limit = math.min(a.length, b.length);
    var count = 0;
    while (count < limit &&
        a[a.length - 1 - count] == b[b.length - 1 - count]) {
      count += 1;
    }
    return count;
  }

  double _scoreCandidate({
    required _LoadedUnitText target,
    required _LoadedUnitText candidate,
    required int openingShared,
    required int endingShared,
  }) {
    final openingScore = openingShared >= 3
        ? 1.0
        : openingShared == 2
            ? 0.75
            : openingShared == 1
                ? 0.25
                : 0.0;
    final endingScore = endingShared >= 3
        ? 1.0
        : endingShared == 2
            ? 0.75
            : endingShared == 1
                ? 0.25
                : 0.0;
    final overlapScore = _tokenOverlapRatio(target.tokenSet, candidate.tokenSet);
    final ayahCountGap = (target.ayahCount - candidate.ayahCount).abs();
    final ayahCountScore = ayahCountGap == 0
        ? 1.0
        : ayahCountGap == 1
            ? 0.5
            : 0.0;
    final pageScore = _pageProximityScore(
      target.pageMadina,
      candidate.pageMadina,
    );

    return (0.35 * openingScore +
            0.25 * endingScore +
            0.30 * overlapScore +
            0.05 * ayahCountScore +
            0.05 * pageScore)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double _tokenOverlapRatio(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) {
      return 0.0;
    }
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    if (union == 0) {
      return 0.0;
    }
    return intersection / union;
  }

  double _pageProximityScore(int? targetPage, int? candidatePage) {
    if (targetPage == null || candidatePage == null) {
      return 0.0;
    }
    final distance = (targetPage - candidatePage).abs();
    if (distance == 0) {
      return 1.0;
    }
    if (distance == 1) {
      return 0.8;
    }
    if (distance == 2) {
      return 0.6;
    }
    if (distance <= 5) {
      return 0.3;
    }
    return 0.0;
  }

  int? _pageDistance(MemUnitData target, MemUnitData candidate) {
    final targetPage = target.pageMadina;
    final candidatePage = candidate.pageMadina;
    if (targetPage == null || candidatePage == null) {
      return null;
    }
    return (targetPage - candidatePage).abs();
  }

  SimilarVerseDifferenceCue? _deriveDifferenceCue({
    required _LoadedUnitText target,
    required _LoadedUnitText candidate,
    required int openingShared,
    required int endingShared,
  }) {
    if (openingShared >= 2 &&
        openingShared < target.displayTokens.length &&
        openingShared < candidate.displayTokens.length &&
        openingShared <= 6) {
      final currentToken = target.displayTokens[openingShared];
      final candidateToken = candidate.displayTokens[openingShared];
      if (currentToken.isNotEmpty &&
          candidateToken.isNotEmpty &&
          currentToken != candidateToken) {
        return SimilarVerseDifferenceCue(
          kind: SimilarVerseDifferenceCueKind.openingSplit,
          currentToken: currentToken,
          candidateToken: candidateToken,
        );
      }
    }

    if (endingShared >= 2) {
      final currentIndex = target.displayTokens.length - endingShared - 1;
      final candidateIndex = candidate.displayTokens.length - endingShared - 1;
      if (currentIndex >= 0 &&
          candidateIndex >= 0 &&
          currentIndex < target.displayTokens.length &&
          candidateIndex < candidate.displayTokens.length) {
        final currentToken = target.displayTokens[currentIndex];
        final candidateToken = candidate.displayTokens[candidateIndex];
        if (currentToken.isNotEmpty &&
            candidateToken.isNotEmpty &&
            currentToken != candidateToken) {
          return SimilarVerseDifferenceCue(
            kind: SimilarVerseDifferenceCueKind.endingLeadIn,
            currentToken: currentToken,
            candidateToken: candidateToken,
          );
        }
      }
    }

    return null;
  }
}

class _LoadedUnitText {
  const _LoadedUnitText({
    required this.ayahCount,
    required this.pageMadina,
    required this.displayTokens,
    required this.normalizedTokens,
    required this.tokenSet,
    required this.excerpt,
  });

  final int ayahCount;
  final int? pageMadina;
  final List<String> displayTokens;
  final List<String> normalizedTokens;
  final Set<String> tokenSet;
  final String excerpt;
}
