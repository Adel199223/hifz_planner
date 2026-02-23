import 'package:flutter/widgets.dart';

enum AppLanguage {
  english(
    code: 'en',
    displayName: 'English',
    locale: Locale('en'),
    isRtl: false,
  ),
  french(
    code: 'fr',
    displayName: 'Français',
    locale: Locale('fr'),
    isRtl: false,
  ),
  arabic(
    code: 'ar',
    displayName: 'العربية',
    locale: Locale('ar'),
    isRtl: true,
  ),
  portuguese(
    code: 'pt',
    displayName: 'Português',
    locale: Locale('pt'),
    isRtl: false,
  );

  const AppLanguage({
    required this.code,
    required this.displayName,
    required this.locale,
    required this.isRtl,
  });

  final String code;
  final String displayName;
  final Locale locale;
  final bool isRtl;

  static AppLanguage? fromCode(String? code) {
    if (code == null) {
      return null;
    }
    for (final language in values) {
      if (language.code == code) {
        return language;
      }
    }
    return null;
  }
}
