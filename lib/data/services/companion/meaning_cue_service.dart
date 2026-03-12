import '../quran_wording.dart';
import '../qurancom_api.dart';

class CompanionMeaningCue {
  const CompanionMeaningCue({
    required this.verseKey,
    required this.text,
    required this.sourceLabel,
  });

  final String verseKey;
  final String text;
  final String sourceLabel;
}

class CompanionMeaningCueService {
  CompanionMeaningCueService(this._quranComApi);

  static const int _maxWords = 18;
  static const int _maxChars = 120;
  static const String _fallbackSourceLabel = 'Quran.com translation';

  final QuranComApi _quranComApi;

  Future<CompanionMeaningCue?> getCueForVerse({
    required int page,
    required int mushafId,
    required String verseKey,
    required int? translationResourceId,
  }) async {
    final verseData = await _quranComApi.getVerseDataByPage(
      page: page,
      mushafId: mushafId,
      verseKey: verseKey,
      translationResourceId: translationResourceId,
    );
    return cueFromVerseData(
      verseData,
      translationResourceId: translationResourceId,
    );
  }

  CompanionMeaningCue? cueFromVerseData(
    MushafVerseData verseData, {
    required int? translationResourceId,
  }) {
    final translation = _selectTranslation(
      verseData.translations,
      translationResourceId: translationResourceId,
    );
    if (translation == null) {
      return null;
    }

    final text = _formatCueText(translation.text);
    if (text.isEmpty) {
      return null;
    }

    final sourceLabel = _formatSourceLabel(translation.resourceName);
    return CompanionMeaningCue(
      verseKey: verseData.verseKey,
      text: text,
      sourceLabel: sourceLabel,
    );
  }

  MushafVerseTranslation? _selectTranslation(
    List<MushafVerseTranslation> translations, {
    required int? translationResourceId,
  }) {
    MushafVerseTranslation? firstNonEmpty;
    for (final translation in translations) {
      final cleanedText = cleanTranslationText(translation.text);
      if (cleanedText.isEmpty) {
        continue;
      }
      firstNonEmpty ??= translation;
      if (translationResourceId != null &&
          translation.resourceId == translationResourceId) {
        return translation;
      }
    }
    return firstNonEmpty;
  }

  String _formatCueText(String? rawText) {
    final cleaned = cleanTranslationText(rawText);
    if (cleaned.isEmpty) {
      return '';
    }

    final sentenceMatch = RegExp(r'^(.+?[.!?;:])(?:\s|$)').firstMatch(cleaned);
    final candidate = sentenceMatch == null
        ? cleaned
        : (sentenceMatch.group(1) ?? cleaned).trim();
    final target = candidate.isEmpty ? cleaned : candidate;
    final words = target
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) {
      return '';
    }
    if (words.length <= _maxWords && target.length <= _maxChars) {
      return target;
    }

    final buffer = StringBuffer();
    var usedWords = 0;
    for (final word in words) {
      final nextWordCount = usedWords + 1;
      final nextText = usedWords == 0 ? word : '${buffer.toString()} $word';
      if (nextWordCount > _maxWords || nextText.length > _maxChars) {
        break;
      }
      if (usedWords > 0) {
        buffer.write(' ');
      }
      buffer.write(word);
      usedWords = nextWordCount;
    }

    final truncated = buffer.toString().trim();
    if (truncated.isEmpty || truncated == target) {
      return target.length <= _maxChars
          ? target
          : '${target.substring(0, _maxChars).trimRight()}...';
    }
    return '$truncated...';
  }

  String _formatSourceLabel(String? rawLabel) {
    final cleaned = cleanTranslationText(rawLabel);
    if (cleaned.isEmpty) {
      return _fallbackSourceLabel;
    }
    return cleaned;
  }
}
