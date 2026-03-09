import 'dart:io';

class LocalizationValidator {
  LocalizationValidator({
    required this.rootDirectory,
  });

  final Directory rootDirectory;

  List<String> validate() {
    final issues = <String>[];
    _validateRequiredFiles(issues);
    _validateAppLanguage(issues);
    _validateAppStrings(issues);
    _validateReaderTranslationMapping(issues);
    return issues;
  }

  void _validateRequiredFiles(List<String> issues) {
    const requiredFiles = <String>[
      'lib/l10n/app_language.dart',
      'lib/l10n/app_strings.dart',
      'lib/screens/reader_screen.dart',
    ];
    for (final relativePath in requiredFiles) {
      if (!_file(relativePath).existsSync()) {
        issues.add('Missing required localization file: $relativePath');
      }
    }
  }

  void _validateAppLanguage(List<String> issues) {
    const path = 'lib/l10n/app_language.dart';
    final file = _file(path);
    if (!file.existsSync()) {
      return;
    }

    final content = file.readAsStringSync();

    final languagePatterns = <String, RegExp>{
      'english': RegExp(
        r"english\(\s*code:\s*'en'[\s\S]*?locale:\s*Locale\('en'\)[\s\S]*?isRtl:\s*false",
      ),
      'french': RegExp(
        r"french\(\s*code:\s*'fr'[\s\S]*?locale:\s*Locale\('fr'\)[\s\S]*?isRtl:\s*false",
      ),
      'portuguese': RegExp(
        r"portuguese\(\s*code:\s*'pt'[\s\S]*?locale:\s*Locale\('pt'\)[\s\S]*?isRtl:\s*false",
      ),
      'arabic': RegExp(
        r"arabic\(\s*code:\s*'ar'[\s\S]*?locale:\s*Locale\('ar'\)[\s\S]*?isRtl:\s*true",
      ),
    };

    languagePatterns.forEach((language, pattern) {
      if (!pattern.hasMatch(content)) {
        issues.add(
          'AppLanguage entry "$language" is missing required code/locale/isRtl metadata in $path.',
        );
      }
    });
  }

  void _validateAppStrings(List<String> issues) {
    const path = 'lib/l10n/app_strings.dart';
    final file = _file(path);
    if (!file.existsSync()) {
      return;
    }
    final content = file.readAsStringSync();

    final requiredKeys = <String>[
      'verse_by_verse',
      'reading',
      'surah',
      'verse',
      'juz',
      'page',
      'listen',
      'tajweed_colors',
      'tafsirs',
      'lessons',
      'reflections',
      'retry',
      'done',
      'reader',
      'bookmarks',
      'notes',
      'plan',
      'today',
      'settings',
      'about',
      'read',
      'learn',
      'my_quran',
      'reciters',
    ];

    final localeBlocks = <String, String>{
      'french': _extractLocaleBlock(content, 'french'),
      'portuguese': _extractLocaleBlock(content, 'portuguese'),
      'arabic': _extractLocaleBlock(content, 'arabic'),
    };

    localeBlocks.forEach((locale, block) {
      if (block.isEmpty) {
        issues.add(
          'Could not find AppStrings override block for AppLanguage.$locale in $path.',
        );
        return;
      }
      for (final key in requiredKeys) {
        final keyPattern = RegExp("'$key'\\s*:");
        if (!keyPattern.hasMatch(block)) {
          issues.add(
            'Missing localization key "$key" in AppStrings override for AppLanguage.$locale.',
          );
        }
      }
    });
  }

  void _validateReaderTranslationMapping(List<String> issues) {
    const path = 'lib/screens/reader_screen.dart';
    final file = _file(path);
    if (!file.existsSync()) {
      return;
    }
    final content = file.readAsStringSync();

    const requiredSnippets = <String>[
      'const int _translationResourceEnglish = 85;',
      'const int _translationResourceFrench = 31;',
      'const int _translationResourcePortuguese = 43;',
      'case AppLanguage.english:',
      'return _translationResourceEnglish;',
      'case AppLanguage.french:',
      'return _translationResourceFrench;',
      'case AppLanguage.portuguese:',
      'return _translationResourcePortuguese;',
      'case AppLanguage.arabic:',
    ];

    for (final snippet in requiredSnippets) {
      if (!content.contains(snippet)) {
        issues.add(
          'Reader translation mapping contract missing snippet in $path: $snippet',
        );
      }
    }

    final arabicFallbackPattern = RegExp(
      r'case AppLanguage\.arabic:[\s\S]*?return _translationResourceEnglish;',
    );
    if (!arabicFallbackPattern.hasMatch(content)) {
      issues.add(
        'Reader translation mapping must keep Arabic fallback to _translationResourceEnglish (85).',
      );
    }
  }

  String _extractLocaleBlock(String source, String locale) {
    final pattern = RegExp(
      'AppLanguage\\.$locale: <String, String>\\{([\\s\\S]*?)\\n\\s*\\},',
    );
    final match = pattern.firstMatch(source);
    if (match == null) {
      return '';
    }
    return match.group(1) ?? '';
  }

  File _file(String relativePath) {
    final normalized = relativePath.replaceAll('/', Platform.pathSeparator);
    return File('${rootDirectory.path}${Platform.pathSeparator}$normalized');
  }
}

int main() {
  final validator = LocalizationValidator(rootDirectory: Directory.current);
  final issues = validator.validate();
  if (issues.isEmpty) {
    stdout.writeln('Localization validation passed.');
    return 0;
  }

  stderr.writeln(
    'Localization validation failed (${issues.length} issue(s)):',
  );
  for (final issue in issues) {
    stderr.writeln('- $issue');
  }
  return 1;
}
