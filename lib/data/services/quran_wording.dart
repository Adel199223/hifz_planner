import '../../l10n/app_language.dart';
import 'qurancom_api.dart';

const int translationResourceEnglish = 85;
const int translationResourceFrench = 31;
const int translationResourcePortuguese = 43;

int translationResourceIdForLanguage(AppLanguage language) {
  return switch (language) {
    AppLanguage.english => translationResourceEnglish,
    AppLanguage.french => translationResourceFrench,
    AppLanguage.portuguese => translationResourcePortuguese,
    // Arabic app language currently falls back to English translation.
    AppLanguage.arabic => translationResourceEnglish,
  };
}

String cleanTranslationText(String? rawText) {
  if (rawText == null) {
    return '';
  }
  var text = rawText.replaceAll(RegExp(r'<[^>]*>'), ' ');
  text = text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', '\'');
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool isEndMarkerWord(MushafWord word) {
  return (word.charTypeName ?? '').trim().toLowerCase() == 'end';
}

String wordDisplayText(MushafWord word) {
  final code = (word.codeV2 ?? '').trim();
  if (code.isNotEmpty) {
    return code;
  }
  return (word.textQpcHafs ?? '').trim();
}

String wordTooltipMessage(
  MushafWord word, {
  required String fallback,
}) {
  final translation = cleanTranslationText(word.translationText);
  if (translation.isNotEmpty) {
    return translation;
  }
  return fallback;
}
