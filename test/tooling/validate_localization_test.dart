import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tooling/validate_localization.dart';

void main() {
  test('localization validator passes for current repository', () {
    final validator = LocalizationValidator(rootDirectory: Directory.current);
    final issues = validator.validate();
    expect(
      issues,
      isEmpty,
      reason: issues.isEmpty ? null : issues.join('\n'),
    );
  });

  test('validator fails when a required locale key is missing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final appStrings = File(
      _join(fixture.path, 'lib/l10n/app_strings.dart'),
    );
    final content = appStrings.readAsStringSync();
    appStrings.writeAsStringSync(
      content.replaceFirst("'listen': 'Écouter',", ''),
    );

    final validator = LocalizationValidator(rootDirectory: fixture);
    final issues = validator.validate();
    expect(
      issues.any(
        (issue) =>
            issue.contains('Missing localization key "listen"') &&
            issue.contains('AppLanguage.french'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when Arabic RTL metadata is broken', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final appLanguage = File(
      _join(fixture.path, 'lib/l10n/app_language.dart'),
    );
    final content = appLanguage.readAsStringSync();
    appLanguage.writeAsStringSync(
      content.replaceFirst('isRtl: true', 'isRtl: false'),
    );

    final validator = LocalizationValidator(rootDirectory: fixture);
    final issues = validator.validate();
    expect(
      issues.any((issue) => issue.contains('AppLanguage entry "arabic"')),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when Arabic fallback mapping is removed', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final readerScreen = File(
      _join(fixture.path, 'lib/screens/reader_screen.dart'),
    );
    final content = readerScreen.readAsStringSync();
    readerScreen.writeAsStringSync(
      content.replaceFirst(
        'case AppLanguage.arabic:',
        'case AppLanguage.arabic_disabled:',
      ),
    );

    final validator = LocalizationValidator(rootDirectory: fixture);
    final issues = validator.validate();
    expect(
      issues.any(
        (issue) =>
            issue.contains('Arabic fallback to _translationResourceEnglish') ||
            issue.contains(
              'Reader translation mapping contract missing snippet in lib/screens/reader_screen.dart: case AppLanguage.arabic:',
            ) ||
            issue.contains(
              'Reader translation mapping contract missing snippet in lib/screens/reader_screen.dart: return _translationResourceEnglish;',
            ),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });
}

Directory _createValidFixture() {
  final root = Directory.systemTemp.createTempSync(
    'localization-validator-fixture-',
  );

  void writeFile(String relativePath, String content) {
    final file = File(_join(root.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  writeFile(
    'lib/l10n/app_language.dart',
    '''
import 'package:flutter/widgets.dart';

enum AppLanguage {
  english(code: 'en', displayName: 'English', locale: Locale('en'), isRtl: false),
  french(code: 'fr', displayName: 'Français', locale: Locale('fr'), isRtl: false),
  arabic(code: 'ar', displayName: 'العربية', locale: Locale('ar'), isRtl: true),
  portuguese(code: 'pt', displayName: 'Português', locale: Locale('pt'), isRtl: false);

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
}
''',
  );

  writeFile(
    'lib/l10n/app_strings.dart',
    '''
import 'app_language.dart';

class AppStrings {
  static const Map<AppLanguage, Map<String, String>> _overrides = <AppLanguage, Map<String, String>>{
    AppLanguage.french: <String, String>{
      'verse_by_verse': 'Ayah par Ayah',
      'reading': 'Lecture',
      'surah': 'Sourate',
      'verse': 'Ayah',
      'juz': 'Juz',
      'page': 'Page',
      'listen': 'Écouter',
      'tajweed_colors': 'Couleurs du Tajwid',
      'tafsirs': 'Tafsirs',
      'lessons': 'Leçons',
      'reflections': 'Réflexions',
      'retry': 'Réessayer',
      'done': 'Fait',
      'reader': 'Lecteur',
      'bookmarks': 'Signets',
      'notes': 'Notes',
      'plan': 'Plan',
      'today': "Aujourd'hui",
      'settings': 'Paramètres',
      'about': 'À propos',
      'read': 'Lire',
      'learn': 'Apprendre',
      'my_quran': 'Mon Coran',
      'reciters': 'Récitateurs',
    },
    AppLanguage.portuguese: <String, String>{
      'verse_by_verse': 'Verso por verso',
      'reading': 'Lendo',
      'surah': 'Surah',
      'verse': 'Versículo',
      'juz': 'Juz',
      'page': 'Página',
      'listen': 'Ouvir',
      'tajweed_colors': 'Cores de Tajweed',
      'tafsirs': 'Tafsirs',
      'lessons': 'Lições',
      'reflections': 'Reflexões',
      'retry': 'Tentar novamente',
      'done': 'Feito',
      'reader': 'Leitor',
      'bookmarks': 'Favoritos',
      'notes': 'Notas',
      'plan': 'Plano',
      'today': 'Hoje',
      'settings': 'Configurações',
      'about': 'Sobre',
      'read': 'Ler',
      'learn': 'Aprender',
      'my_quran': 'Meu Alcorão',
      'reciters': 'Recitadores',
    },
    AppLanguage.arabic: <String, String>{
      'verse_by_verse': 'آية بآية',
      'reading': 'القراءة',
      'surah': 'سورة',
      'verse': 'آية',
      'juz': 'جزء',
      'page': 'صفحة',
      'listen': 'استمع',
      'tajweed_colors': 'ألوان التجويد',
      'tafsirs': 'تفاسير',
      'lessons': 'فوائد',
      'reflections': 'تدبرات',
      'retry': 'أعد المحاولة',
      'done': 'تم',
      'reader': 'القارئ',
      'bookmarks': 'العلامات',
      'notes': 'الملاحظات',
      'plan': 'الخطة',
      'today': 'اليوم',
      'settings': 'الإعدادات',
      'about': 'حول',
      'read': 'اقرأ',
      'learn': 'تعلّم',
      'my_quran': 'قرآني',
      'reciters': 'القرّاء',
    },
  };
}
''',
  );

  writeFile(
    'lib/screens/reader_screen.dart',
    '''
const int _translationResourceEnglish = 85;
const int _translationResourceFrench = 31;
const int _translationResourcePortuguese = 43;

int _translationResourceIdForLanguage(AppLanguage language) {
  switch (language) {
    case AppLanguage.english:
      return _translationResourceEnglish;
    case AppLanguage.french:
      return _translationResourceFrench;
    case AppLanguage.portuguese:
      return _translationResourcePortuguese;
    case AppLanguage.arabic:
      return _translationResourceEnglish;
  }
}
''',
  );

  return root;
}

String _join(String left, String right) {
  final normalizedRight = right.replaceAll('/', Platform.pathSeparator);
  if (left.endsWith(Platform.pathSeparator)) {
    return '$left$normalizedRight';
  }
  return '$left${Platform.pathSeparator}$normalizedRight';
}
