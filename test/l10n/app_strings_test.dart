import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/l10n/app_language.dart';
import 'package:hifz_planner/l10n/app_strings.dart';

void main() {
  test('reader terminology matches Quran.com-aligned terms for fr/pt/ar', () {
    final fr = AppStrings.of(AppLanguage.french);
    final pt = AppStrings.of(AppLanguage.portuguese);
    final ar = AppStrings.of(AppLanguage.arabic);

    expect(fr.verseByVerse, 'Ayah par Ayah');
    expect(pt.verseByVerse, 'Verso por verso');
    expect(ar.verseByVerse, 'آية بآية');

    expect(fr.reading, 'Lecture');
    expect(pt.reading, 'Lendo');
    expect(ar.reading, 'القراءة');

    expect(fr.surah, 'Sourate');
    expect(pt.surah, 'Surah');
    expect(ar.surah, 'سورة');

    expect(fr.verse, 'Ayah');
    expect(pt.verse, 'Versículo');
    expect(ar.verse, 'آية');

    expect(fr.juz, 'Juz');
    expect(pt.juz, 'Juz');
    expect(ar.juz, 'جزء');

    expect(fr.page, 'Page');
    expect(pt.page, 'Página');
    expect(ar.page, 'صفحة');

    expect(fr.listen, 'Écouter');
    expect(pt.listen, 'Ouvir');
    expect(ar.listen, 'استمع');

    expect(fr.tajweedColors, 'Couleurs du Tajwid');
    expect(pt.tajweedColors, 'Cores de Tajweed');
    expect(ar.tajweedColors, 'ألوان التجويد');

    expect(fr.tafsirs, 'Tafsirs');
    expect(pt.tafsirs, 'Tafsirs');
    expect(ar.tafsirs, 'تفاسير');

    expect(fr.lessons, 'Leçons');
    expect(pt.lessons, 'Lições');
    expect(ar.lessons, 'فوائد');

    expect(fr.reflections, 'Réflexions');
    expect(pt.reflections, 'Reflexões');
    expect(ar.reflections, 'تدبرات');

    expect(fr.retry, 'Réessayer');
    expect(pt.retry, 'Tentar novamente');
    expect(ar.retry, 'أعد المحاولة');

    expect(fr.done, 'Fait');
    expect(pt.done, 'Feito');
    expect(ar.done, 'تم');
  });

  test('interpolation methods format correctly', () {
    final en = AppStrings.of(AppLanguage.english);
    final ar = AppStrings.of(AppLanguage.arabic);

    expect(en.pageLabel(50), 'Page 50');
    expect(ar.pageLabel(50), 'صفحة 50');

    expect(en.juzLabel(3), 'Juz 3');
    expect(ar.juzLabel(3), 'جزء 3');

    expect(en.hizbLabel(5), 'Hizb 5');
    expect(ar.hizbLabel(5), 'حزب 5');

    expect(en.surahAyahLabel(2, 7), '2:7');
    expect(ar.surahAyahLabel(2, 7), '2:7');

    expect(en.failedToLoadAyahs, 'Failed to load ayahs.');
  });

  test('all languages expose locale metadata and non-empty shell labels', () {
    for (final language in AppLanguage.values) {
      final strings = AppStrings.of(language);
      expect(strings.reader, isNotEmpty);
      expect(strings.bookmarks, isNotEmpty);
      expect(strings.notes, isNotEmpty);
      expect(strings.plan, isNotEmpty);
      expect(strings.today, isNotEmpty);
      expect(strings.settings, isNotEmpty);
      expect(strings.about, isNotEmpty);
      expect(language.locale, isA<Locale>());
    }

    expect(AppLanguage.arabic.isRtl, isTrue);
    expect(AppLanguage.english.isRtl, isFalse);
    expect(AppLanguage.french.isRtl, isFalse);
    expect(AppLanguage.portuguese.isRtl, isFalse);
  });
}
