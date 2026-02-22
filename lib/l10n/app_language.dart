enum AppLanguage {
  english(code: 'en', displayName: 'English'),
  french(code: 'fr', displayName: 'Français'),
  arabic(code: 'ar', displayName: 'العربية'),
  portuguese(code: 'pt', displayName: 'Português');

  const AppLanguage({
    required this.code,
    required this.displayName,
  });

  final String code;
  final String displayName;

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
