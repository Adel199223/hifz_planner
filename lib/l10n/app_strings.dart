import 'app_language.dart';

/// New shell/menu strings are routed through this class so future
/// localization can replace the values without touching widget code.
class AppStrings {
  const AppStrings._(this.currentLanguage);

  final AppLanguage currentLanguage;

  static AppStrings of(AppLanguage language) => AppStrings._(language);

  static const Map<AppLanguage, Map<String, String>> _values =
      <AppLanguage, Map<String, String>>{
    AppLanguage.english: <String, String>{
      'menu': 'Menu',
      'read': 'Read',
      'learn': 'Learn',
      'my_quran': 'My Quran',
      'quran_radio': 'Quran Radio',
      'reciters': 'Reciters',
      'language': 'Language',
      'change_theme': 'Change Theme',
      'theme_sepia': 'Sepia',
      'theme_dark': 'Dark',
      'learn_title': 'Learn',
      'learn_subtitle':
          'Keep growing with structured learning tracks and your Hifz workflow.',
      'hifz_plan_title': 'Hifz Plan',
      'hifz_plan_subtitle':
          'Open your existing Hifz planner and continue where you left off.',
      'open_hifz_plan': 'Open Hifz Plan',
      'coming_soon': 'Coming soon.',
    },
    AppLanguage.french: <String, String>{
      'menu': 'Menu',
      'read': 'Read',
      'learn': 'Learn',
      'my_quran': 'My Quran',
      'quran_radio': 'Quran Radio',
      'reciters': 'Reciters',
      'language': 'Language',
      'change_theme': 'Change Theme',
      'theme_sepia': 'Sepia',
      'theme_dark': 'Dark',
      'learn_title': 'Learn',
      'learn_subtitle':
          'Keep growing with structured learning tracks and your Hifz workflow.',
      'hifz_plan_title': 'Hifz Plan',
      'hifz_plan_subtitle':
          'Open your existing Hifz planner and continue where you left off.',
      'open_hifz_plan': 'Open Hifz Plan',
      'coming_soon': 'Coming soon.',
    },
    AppLanguage.arabic: <String, String>{
      'menu': 'Menu',
      'read': 'Read',
      'learn': 'Learn',
      'my_quran': 'My Quran',
      'quran_radio': 'Quran Radio',
      'reciters': 'Reciters',
      'language': 'Language',
      'change_theme': 'Change Theme',
      'theme_sepia': 'Sepia',
      'theme_dark': 'Dark',
      'learn_title': 'Learn',
      'learn_subtitle':
          'Keep growing with structured learning tracks and your Hifz workflow.',
      'hifz_plan_title': 'Hifz Plan',
      'hifz_plan_subtitle':
          'Open your existing Hifz planner and continue where you left off.',
      'open_hifz_plan': 'Open Hifz Plan',
      'coming_soon': 'Coming soon.',
    },
    AppLanguage.portuguese: <String, String>{
      'menu': 'Menu',
      'read': 'Read',
      'learn': 'Learn',
      'my_quran': 'My Quran',
      'quran_radio': 'Quran Radio',
      'reciters': 'Reciters',
      'language': 'Language',
      'change_theme': 'Change Theme',
      'theme_sepia': 'Sepia',
      'theme_dark': 'Dark',
      'learn_title': 'Learn',
      'learn_subtitle':
          'Keep growing with structured learning tracks and your Hifz workflow.',
      'hifz_plan_title': 'Hifz Plan',
      'hifz_plan_subtitle':
          'Open your existing Hifz planner and continue where you left off.',
      'open_hifz_plan': 'Open Hifz Plan',
      'coming_soon': 'Coming soon.',
    },
  };

  String get menu => _get('menu');
  String get read => _get('read');
  String get learn => _get('learn');
  String get myQuran => _get('my_quran');
  String get quranRadio => _get('quran_radio');
  String get reciters => _get('reciters');
  String get language => _get('language');
  String get changeTheme => _get('change_theme');
  String get themeSepia => _get('theme_sepia');
  String get themeDark => _get('theme_dark');
  String get learnTitle => _get('learn_title');
  String get learnSubtitle => _get('learn_subtitle');
  String get hifzPlanTitle => _get('hifz_plan_title');
  String get hifzPlanSubtitle => _get('hifz_plan_subtitle');
  String get openHifzPlan => _get('open_hifz_plan');
  String get comingSoon => _get('coming_soon');

  String _get(String key) {
    final localized = _values[currentLanguage] ?? _values[AppLanguage.english]!;
    return localized[key] ?? _values[AppLanguage.english]![key]!;
  }
}
