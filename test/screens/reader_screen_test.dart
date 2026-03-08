import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/app/app_preferences.dart';
import 'package:hifz_planner/app/app_preferences_store.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/data/repositories/bookmark_repo.dart';
import 'package:hifz_planner/data/repositories/note_repo.dart';
import 'package:hifz_planner/data/services/qurancom_api.dart';
import 'package:hifz_planner/data/services/qurancom_chapters_service.dart';
import 'package:hifz_planner/data/services/ayah_audio_service.dart';
import 'package:hifz_planner/data/services/ayah_audio_source.dart';
import 'package:hifz_planner/data/services/tajweed_tags_service.dart';
import 'package:hifz_planner/l10n/app_language.dart';
import 'package:hifz_planner/screens/reader_screen.dart';
import 'package:hifz_planner/ui/qcf/qcf_font_manager.dart';

import '../helpers/pump_until_found.dart';

void main() {
  testWidgets('surah list supports 1..114 and selecting surah reloads ayahs', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await tester.pumpAndSettle();

    final surahList = find.byKey(const ValueKey('reader_surah_list'));
    expect(find.byKey(const ValueKey('surah_tile_1')), findsOneWidget);

    await tester.dragUntilVisible(
      find.byKey(const ValueKey('surah_tile_114')),
      surahList,
      const Offset(0, -350),
    );
    expect(find.byKey(const ValueKey('surah_tile_114')), findsOneWidget);

    await tester.dragUntilVisible(
      find.byKey(const ValueKey('surah_tile_2')),
      surahList,
      const Offset(0, 220),
    );
    await tester.tap(find.text('2. Al-Baqarah'), warnIfMissed: false);
    await tester.pumpAndSettle();

    await pumpUntilFound(tester, find.text('الم'));
    expect(find.text('ٱلْحَمْدُ لِلَّٰهِ'), findsNothing);
  });

  testWidgets('page tab switches to page mode and loads page ayahs', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);

    expect(find.byKey(const ValueKey('reader_surah_list')), findsOneWidget);

    await _switchToPageMode(tester);

    expect(find.byKey(const ValueKey('reader_page_list')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader_page_label')), findsOneWidget);

    final page1Label = tester.widget<Text>(
      find.byKey(const ValueKey('reader_page_label')),
    );
    expect(page1Label.data, 'Page 1');

    await tester.tap(find.byKey(const ValueKey('reader_page_2')));
    await tester.pumpAndSettle();

    final page2Label = tester.widget<Text>(
      find.byKey(const ValueKey('reader_page_label')),
    );
    expect(page2Label.data, 'Page 2');

    expect(find.text('مَٰلِكِ يَوْمِ ٱلدِّينِ'), findsOneWidget);
    expect(find.text('الم'), findsOneWidget);
    expect(find.text('رَبِّ ٱلْعَٰلَمِينَ'), findsNothing);
  });

  testWidgets('page mode without metadata still exposes 1..604 page navigation',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await db.into(db.ayah).insert(
          AyahCompanion.insert(
            surah: 1,
            ayah: 1,
            textUthmani: 'ٱلْحَمْدُ لِلَّٰهِ',
          ),
        );

    await _pumpReader(
      tester,
      container,
      screen: const ReaderScreen(mode: 'page'),
    );

    final pageList = find.byKey(const ValueKey('reader_page_list'));
    expect(pageList, findsOneWidget);
    expect(find.byKey(const ValueKey('reader_page_1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reader_page_2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader_page_2')), findsOneWidget);
  });

  testWidgets('ayah rows use hover wrapper and RTL text', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);

    expect(find.byType(MouseRegion), findsWidgets);

    final rtlAncestor = find.ancestor(
      of: find.text('ٱلْحَمْدُ لِلَّٰهِ'),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Directionality &&
            widget.textDirection == TextDirection.rtl,
      ),
    );
    expect(rtlAncestor, findsOneWidget);
  });

  testWidgets('reader labels localize to French terminology', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        appPreferencesStoreProvider.overrideWithValue(
          _FakeAppPreferencesStore(
            initial: const StoredAppPreferences(languageCode: 'fr'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(
      tester,
      container,
      locale: const Locale('fr'),
    );

    expect(find.text('Ayah par Ayah'), findsOneWidget);
    expect(find.text('Lecture'), findsOneWidget);
    expect(find.text('Sourate'), findsOneWidget);
    expect(find.text('Écouter'), findsOneWidget);
    expect(find.text('Couleurs du Tajwid'), findsOneWidget);
    expect(find.text('Tafsirs'), findsNothing);
    expect(find.text('Leçons'), findsNothing);
    expect(find.text('Réflexions'), findsNothing);
  });

  testWidgets('reader labels localize to Portuguese terminology',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        appPreferencesStoreProvider.overrideWithValue(
          _FakeAppPreferencesStore(
            initial: const StoredAppPreferences(languageCode: 'pt'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(
      tester,
      container,
      locale: const Locale('pt'),
    );

    expect(find.text('Verso por verso'), findsOneWidget);
    expect(find.text('Lendo'), findsOneWidget);
    expect(find.text('Surah'), findsOneWidget);
    expect(find.text('Versículo'), findsOneWidget);
    expect(find.text('Página'), findsWidgets);
    expect(find.text('Ouvir'), findsOneWidget);
    expect(find.text('Cores de Tajweed'), findsOneWidget);
    expect(find.text('Lições'), findsNothing);
    expect(find.text('Reflexões'), findsNothing);
  });

  testWidgets('reader labels localize to Arabic and app direction is RTL', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        appPreferencesStoreProvider.overrideWithValue(
          _FakeAppPreferencesStore(
            initial: const StoredAppPreferences(languageCode: 'ar'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(
      tester,
      container,
      locale: const Locale('ar'),
    );
    await tester.pumpAndSettle();

    expect(find.text('آية بآية'), findsOneWidget);
    expect(find.text('القراءة'), findsOneWidget);
    expect(find.text('سورة'), findsOneWidget);
    expect(find.text('استمع'), findsOneWidget);
    expect(find.text('ألوان التجويد'), findsOneWidget);
    expect(find.text('تفاسير'), findsNothing);
    expect(find.text('فوائد'), findsNothing);
    expect(find.text('تدبرات'), findsNothing);

    final context =
        tester.element(find.byKey(const ValueKey('reader_view_toggle')));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('verse chapter header uses Quran.com title/subtitle and layout',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        appPreferencesStoreProvider.overrideWithValue(
          _FakeAppPreferencesStore(
            initial: const StoredAppPreferences(languageCode: 'en'),
          ),
        ),
        quranComChaptersServiceProvider.overrideWithValue(
          _FakeQuranComChaptersService(
            byLanguageCode: <String, List<QuranComChapterEntry>>{
              'en': const <QuranComChapterEntry>[
                QuranComChapterEntry(
                  id: 1,
                  nameSimple: 'Al-Fatihah',
                  nameArabic: 'الفاتحة',
                  translatedName: 'The Opener',
                  translatedLanguageName: 'english',
                ),
              ],
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    final iconFinder =
        find.byKey(const ValueKey('reader_verse_chapter_icon_1'));
    final titleFinder =
        find.byKey(const ValueKey('reader_verse_chapter_title_1'));
    final subtitleFinder =
        find.byKey(const ValueKey('reader_verse_chapter_subtitle_1'));
    await pumpUntilFound(tester, titleFinder);
    expect(iconFinder, findsOneWidget);
    expect(titleFinder, findsOneWidget);
    expect(subtitleFinder, findsOneWidget);
    final titleText = tester.widget<Text>(titleFinder);
    final subtitleText = tester.widget<Text>(subtitleFinder);
    expect(titleText.data, startsWith('1.'));
    expect(titleText.data, contains('Al-Fatihah'));
    expect(subtitleText.data, contains('Opener'));
    expect(find.text('Surah 1'), findsNothing);
    expect(
      tester.getTopLeft(iconFinder).dx,
      lessThan(tester.getTopLeft(titleFinder).dx),
    );
  });

  testWidgets('tajweed legend appears only in tajweed mode', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);

    expect(find.byKey(const ValueKey('reader_verse_tajweed_legend')),
        findsNothing);
    expect(find.byKey(const ValueKey('reader_verse_tajweed_colors')),
        findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('reader_verse_settings_button')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('reader_mushaf_tajweed_toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader_verse_tajweed_legend')),
        findsOneWidget);
    expect(find.text('Silent letter'), findsOneWidget);
  });

  testWidgets(
      'arabic locale localizes surah search/list and keeps translation LTR',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        appPreferencesStoreProvider.overrideWithValue(
          _FakeAppPreferencesStore(
            initial: const StoredAppPreferences(languageCode: 'ar'),
          ),
        ),
        quranComChaptersServiceProvider.overrideWithValue(
          _FakeQuranComChaptersService(
            byLanguageCode: <String, List<QuranComChapterEntry>>{
              'ar': const <QuranComChapterEntry>[
                QuranComChapterEntry(
                  id: 1,
                  nameSimple: 'Al-Fatihah',
                  nameArabic: 'الفاتحة',
                  translatedName: 'سورة الفاتحة',
                  translatedLanguageName: 'arabic',
                ),
              ],
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(
      tester,
      container,
      locale: const Locale('ar'),
    );
    await pumpUntilFound(tester, find.text('ابحث عن سورة'));
    expect(find.text('ابحث عن سورة'), findsOneWidget);
    final firstSurahTile =
        find.byKey(const ValueKey('reader_mushaf_nav_surah_1'));
    await pumpUntilFound(tester, firstSurahTile);
    final firstSurahLabel = tester.widget<Text>(
      find.descendant(of: firstSurahTile, matching: find.byType(Text)).first,
    );
    expect(firstSurahLabel.data, contains('الفاتحة'));
    expect(find.text('سورة 1'), findsNothing);

    final translationDirection = find.ancestor(
      of: find.byKey(const ValueKey('reader_verse_translation_1:1')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Directionality &&
            widget.textDirection == TextDirection.ltr,
      ),
    );
    expect(translationDirection, findsOneWidget);
  });

  testWidgets(
      'tajweed toggle from settings falls back to plain when mapping is empty',
      (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        tajweedTagsServiceProvider.overrideWithValue(
          TajweedTagsService(
            loadAssetText: (_) async => '{}',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(
      tester,
      container,
    );

    await tester.tap(
      find.byKey(const ValueKey('reader_verse_settings_button')),
    );
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('reader_mushaf_tajweed_toggle')));
    await tester.pumpAndSettle();

    expect(find.text('ٱلْحَمْدُ لِلَّٰهِ'), findsOneWidget);
    expect(tester.takeException(), equals(null));
  });

  testWidgets('verse action icon opens actions sheet', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);

    await tester
        .tap(find.byKey(const ValueKey('reader_verse_action_more_1:1')));
    await tester.pumpAndSettle();

    expect(find.text('Bookmark verse'), findsOneWidget);
    expect(find.text('Add/Edit note'), findsOneWidget);
    expect(find.text('Copy text (Uthmani)'), findsOneWidget);
  });

  testWidgets(
    'verse row play button calls playAyah with verse coordinates',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final fakeAudio = _FakeAyahAudioService();
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            ref.onDispose(db.close);
            return db;
          }),
          ayahAudioServiceProvider.overrideWithValue(fakeAudio),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await fakeAudio.dispose();
      });
      _registerPumpCleanup(tester);

      await _seedAyahs(db);
      await _pumpReader(tester, container);

      await tester
          .tap(find.byKey(const ValueKey('reader_verse_action_play_1:1')));
      await tester.pump();

      expect(fakeAudio.playAyahCalls.length, 1);
      expect(fakeAudio.playAyahCalls.single, const AyahRef(surah: 1, ayah: 1));
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets(
    'verse row play-from-here menu calls playFrom',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final fakeAudio = _FakeAyahAudioService();
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            ref.onDispose(db.close);
            return db;
          }),
          ayahAudioServiceProvider.overrideWithValue(fakeAudio),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await fakeAudio.dispose();
      });
      _registerPumpCleanup(tester);

      await _seedAyahs(db);
      await _pumpReader(tester, container);

      await tester.tap(
        find.byKey(const ValueKey('reader_verse_action_play_from_1:1')),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(fakeAudio.playFromCalls.length, 1);
      expect(fakeAudio.playFromCalls.single, const AyahRef(surah: 1, ayah: 1));
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets(
    'reader mini-player controls call audio service methods',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final fakeAudio = _FakeAyahAudioService();
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            ref.onDispose(db.close);
            return db;
          }),
          ayahAudioServiceProvider.overrideWithValue(fakeAudio),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await fakeAudio.dispose();
      });
      _registerPumpCleanup(tester);

      await _seedAyahs(db);
      await _pumpReader(tester, container);

      fakeAudio.emitState(
        const AyahAudioState(
          currentAyah: AyahRef(surah: 1, ayah: 1),
          isPlaying: true,
          isBuffering: false,
          speed: 1.0,
          repeatCount: 0,
          canNext: true,
          canPrevious: true,
          queueLength: 3,
          position: Duration(seconds: 5),
          bufferedPosition: Duration(seconds: 8),
          duration: Duration(seconds: 20),
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('reader_audio_mini_player')),
          findsOneWidget);

      await tester
          .tap(find.byKey(const ValueKey('reader_audio_play_pause_button')));
      await tester.pump();
      expect(fakeAudio.pauseCalls, 1);

      fakeAudio.emitState(
        const AyahAudioState(
          currentAyah: AyahRef(surah: 1, ayah: 1),
          isPlaying: false,
          isBuffering: false,
          speed: 1.0,
          repeatCount: 0,
          canNext: true,
          canPrevious: true,
          queueLength: 3,
          position: Duration(seconds: 5),
          bufferedPosition: Duration(seconds: 8),
          duration: Duration(seconds: 20),
        ),
      );
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey('reader_audio_play_pause_button')));
      await tester.pump();
      expect(fakeAudio.resumeCalls, 1);

      await tester.tap(find.byKey(const ValueKey('reader_audio_prev_button')));
      await tester.pump();
      expect(fakeAudio.previousCalls, 1);

      await tester.tap(find.byKey(const ValueKey('reader_audio_next_button')));
      await tester.pump();
      expect(fakeAudio.nextCalls, 1);

      final seekSlider = tester.widget<Slider>(
        find.byKey(const ValueKey('reader_audio_seek_slider')),
      );
      seekSlider.onChangeEnd?.call(10000);
      await tester.pump();
      expect(fakeAudio.seekToCalls, 1);
      expect(fakeAudio.lastSeekTo, const Duration(seconds: 10));

      await tester
          .tap(find.byKey(const ValueKey('reader_audio_options_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reader_audio_option_speed')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1.25x').last);
      await tester.pumpAndSettle();
      expect(fakeAudio.speedChanges, isNotEmpty);
      expect(fakeAudio.speedChanges.last, 1.25);

      await tester
          .tap(find.byKey(const ValueKey('reader_audio_options_button')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('reader_audio_option_repeat')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2x').last);
      await tester.pumpAndSettle();
      expect(fakeAudio.repeatChanges, isNotEmpty);
      expect(fakeAudio.repeatChanges.last, 2);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets('reader audio reciter menu option disables while switching',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeAudio = _FakeAyahAudioService();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        ayahAudioServiceProvider.overrideWithValue(fakeAudio),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await fakeAudio.dispose();
    });
    container
        .read(ayahReciterSwitchInProgressProvider.notifier)
        .setInProgress(true);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);

    fakeAudio.emitState(
      const AyahAudioState(
        currentAyah: AyahRef(surah: 1, ayah: 1),
        isPlaying: false,
        isBuffering: false,
        speed: 1.0,
        repeatCount: 0,
        canNext: true,
        canPrevious: true,
        queueLength: 3,
        position: Duration(seconds: 1),
        bufferedPosition: Duration(seconds: 2),
        duration: Duration(seconds: 20),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('reader_audio_options_button')));
    await tester.pumpAndSettle();

    final reciterItem = tester.widget<PopupMenuItem<dynamic>>(
      find.byKey(const ValueKey('reader_audio_option_reciter')),
    );
    expect(reciterItem.enabled, isFalse);
  });

  testWidgets('range highlight marks rows inside inclusive verse range', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(
      tester,
      container,
      screen: const ReaderScreen(
        highlightStartSurah: 1,
        highlightStartAyah: 2,
        highlightEndSurah: 2,
        highlightEndAyah: 1,
      ),
    );

    final row11 = tester.widget<Material>(
      find.byKey(const ValueKey('ayah_material_1:1')),
    );
    final row12 = tester.widget<Material>(
      find.byKey(const ValueKey('ayah_material_1:2')),
    );
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('ayah_material_1:3')),
      find.byKey(const ValueKey('reader_ayah_list')),
      const Offset(0, -300),
    );
    final row13 = tester.widget<Material>(
      find.byKey(const ValueKey('ayah_material_1:3')),
    );

    expect(row11.color, Colors.transparent);
    expect(row12.color, isNot(Colors.transparent));
    expect(row13.color, isNot(Colors.transparent));
  });

  testWidgets('bookmark action persists once and does not duplicate', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    final repo = BookmarkRepo(db);
    await _pumpReader(tester, container);

    await tester
        .tap(find.byKey(const ValueKey('reader_verse_action_bookmark_1:1')));
    await tester.pumpAndSettle();

    final firstCount = await repo.getBookmarks();
    expect(firstCount.length, 1);

    await tester
        .tap(find.byKey(const ValueKey('reader_verse_action_bookmark_1:1')));
    await tester.pumpAndSettle();

    final secondCount = await repo.getBookmarks();
    expect(secondCount.length, 1);
  });

  testWidgets('actions remain functional in page mode', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    final repo = BookmarkRepo(db);
    await _pumpReader(
      tester,
      container,
      screen: const ReaderScreen(mode: 'page', page: 1),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('ayah_row_1:1')),
    );

    await tester
        .tap(find.byKey(const ValueKey('reader_verse_action_bookmark_1:1')));
    await tester.pumpAndSettle();

    final bookmarks = await repo.getBookmarks();
    expect(bookmarks.length, 1);
    expect(bookmarks.first.surah, 1);
    expect(bookmarks.first.ayah, 1);
  });

  testWidgets('add/edit note creates then updates single note', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    final noteRepo = NoteRepo(db);
    await _pumpReader(tester, container);

    await tester
        .tap(find.byKey(const ValueKey('reader_verse_action_note_1:1')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('note_body_field')),
      'First note',
    );
    await tester.tap(find.byKey(const ValueKey('note_save_button')));
    await tester.pumpAndSettle();

    final notesAfterCreate = await noteRepo.getNotesForAyah(surah: 1, ayah: 1);
    expect(notesAfterCreate.length, 1);
    expect(notesAfterCreate.first.body, 'First note');

    await tester
        .tap(find.byKey(const ValueKey('reader_verse_action_note_1:1')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('note_body_field')),
      'Updated note',
    );
    await tester.tap(find.byKey(const ValueKey('note_save_button')));
    await tester.pumpAndSettle();

    final notesAfterUpdate = await noteRepo.getNotesForAyah(surah: 1, ayah: 1);
    expect(notesAfterUpdate.length, 1);
    expect(notesAfterUpdate.first.body, 'Updated note');
  });

  testWidgets('copy action copies text and shows feedback', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('ayah_row_1:1')),
    );

    await tester
        .tap(find.byKey(const ValueKey('reader_verse_action_copy_1:1')));
    await tester.pump();
    final copiedFeedback = find.byWidgetPredicate((widget) {
      if (widget is SnackBar) {
        return true;
      }
      if (widget is Text) {
        final text = widget.data;
        return text != null && text.contains('Copied');
      }
      return false;
    });
    await pumpUntilFound(
      tester,
      copiedFeedback,
      timeout: const Duration(seconds: 3),
    );

    expect(copiedFeedback, findsWidgets);
  });

  testWidgets(
    'route target loads surah, jumps to ayah, and clears jump highlight',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            ref.onDispose(db.close);
            return db;
          }),
        ],
      );
      addTearDown(container.dispose);
      _registerPumpCleanup(tester);

      await _seedAyahs(db);
      await db.batch((batch) {
        batch.insertAll(
          db.ayah,
          [
            for (var i = 4; i <= 40; i++)
              AyahCompanion.insert(
                surah: 1,
                ayah: i,
                textUthmani: 'ayah $i',
              ),
          ],
          mode: InsertMode.insertOrIgnore,
        );
      });

      await _pumpReader(
        tester,
        container,
        screen: const ReaderScreen(
          targetSurah: 1,
          targetAyah: 30,
        ),
      );

      final rowFinder = find.byKey(const ValueKey('ayah_row_1:30'));
      final materialFinder = find.byKey(const ValueKey('ayah_material_1:30'));
      await pumpUntilFound(
        tester,
        rowFinder,
        timeout: const Duration(seconds: 15),
      );
      expect(rowFinder, findsOneWidget);
      expect(materialFinder, findsOneWidget);
      await _pumpUntilAyahHighlighted(tester, materialFinder);

      final highlightedMaterial = tester.widget<Material>(materialFinder);
      expect(highlightedMaterial.color, isNot(Colors.transparent));

      await tester.pump(const Duration(milliseconds: 1700));

      final clearedMaterial = tester.widget<Material>(materialFinder);
      expect(clearedMaterial.color, Colors.transparent);
    },
  );

  testWidgets(
    'page mode target jump highlights row then clears',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            ref.onDispose(db.close);
            return db;
          }),
        ],
      );
      addTearDown(container.dispose);
      _registerPumpCleanup(tester);

      await _seedAyahs(db);
      await _pumpReader(
        tester,
        container,
        screen: const ReaderScreen(
          mode: 'page',
          page: 2,
          targetSurah: 1,
          targetAyah: 3,
        ),
      );

      final materialFinder = find.byKey(const ValueKey('ayah_material_1:3'));
      await pumpUntilFound(
        tester,
        materialFinder,
      );
      expect(materialFinder, findsOneWidget);
      await _pumpUntilAyahHighlighted(tester, materialFinder);

      final highlightedMaterial = tester.widget<Material>(materialFinder);
      expect(highlightedMaterial.color, isNot(Colors.transparent));

      await tester.pump(const Duration(milliseconds: 1700));

      final clearedMaterial = tester.widget<Material>(materialFinder);
      expect(clearedMaterial.color, Colors.transparent);
    },
  );

  testWidgets('verse by verse plain uses mushaf=1 and renders word widgets',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildSimpleQuranComDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('ayah_qurancom_text_1:1')),
    );
    expect(
      find.byKey(const ValueKey('reader_verse_word_1:1_0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('reader_verse_word_1:1_1')),
      findsOneWidget,
    );
    expect(fakeApi.calls, isNotEmpty);
    expect(fakeApi.calls.last.mushafId, 1);
  });

  testWidgets('verse by verse tajweed uses mushaf=19', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildSimpleQuranComDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await tester
        .tap(find.byKey(const ValueKey('reader_verse_settings_button')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('reader_mushaf_tajweed_toggle')));
    await tester.pumpAndSettle();

    expect(fakeApi.calls, isNotEmpty);
    expect(fakeApi.calls.last.mushafId, 19);
  });

  testWidgets(
      'verse by verse hover tooltip uses word translation when available',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildInteractiveMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('reader_verse_word_1:1_0')),
    );

    final tooltipFinder =
        find.byKey(const ValueKey('reader_verse_word_tooltip_1:1_0'));
    expect(tooltipFinder, findsOneWidget);
    final tooltip = tester.widget<Tooltip>(tooltipFinder);
    expect(tooltip.message, 'All praise and thanks');
  });

  testWidgets(
      'verse by verse hover tooltip falls back when translation missing',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildSimpleQuranComDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('reader_verse_word_1:1_1')),
    );

    final tooltipFinder =
        find.byKey(const ValueKey('reader_verse_word_tooltip_1:1_1'));
    expect(tooltipFinder, findsOneWidget);
    final tooltip = tester.widget<Tooltip>(tooltipFinder);
    expect(tooltip.message, 'Translation unavailable');
  });

  testWidgets('verse by verse suppresses end-marker circle tokens',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildSimpleQuranComDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('reader_verse_word_1:1_1')),
    );

    expect(
      find.byKey(const ValueKey('reader_verse_word_1:1_0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('reader_verse_word_1:1_1')),
      findsOneWidget,
    );
  });

  testWidgets('verse by verse basmala words do not overlap', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildSimpleQuranComDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('reader_verse_word_1:2_0')),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('reader_verse_word_1:2_1')),
    );

    final firstWordRect = tester.getRect(
      find.byKey(const ValueKey('reader_verse_word_1:2_0')),
    );
    final secondWordRect = tester.getRect(
      find.byKey(const ValueKey('reader_verse_word_1:2_1')),
    );
    expect(firstWordRect.overlaps(secondWordRect), isFalse);
  });

  testWidgets('mushaf chrome replaces center segmented controls',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    expect(find.byKey(const ValueKey('reader_view_toggle')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader_mode_toggle')), findsNothing);
    expect(
      find.byKey(const ValueKey('reader_arabic_render_toggle')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('reader_simple_text_source_toggle')),
      findsNothing,
    );
    expect(
        find.byKey(const ValueKey('reader_mushaf_nav_tabs')), findsOneWidget);
  });

  testWidgets('mushaf context row shows page juz hizb', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildMushafDataWithContextMetaFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    expect(find.byKey(const ValueKey('reader_mushaf_context_row')),
        findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('reader_page_label'))).data,
      'Page 1',
    );
    expect(find.text('Juz 3'), findsOneWidget);
    expect(find.text('Hizb 5'), findsOneWidget);
  });

  testWidgets('mushaf left nav tabs switch and navigate', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.byPage(
      <int, MushafPageData>{
        1: _buildMushafDataWithContextMetaFixture(),
        2: _buildSurahStartMushafDataFixture(),
        3: _buildSpacingMushafDataFixture(),
      },
      juzEntries: const <MushafJuzNavEntry>[
        MushafJuzNavEntry(juzNumber: 1, page: 1, verseKey: '1:1'),
        MushafJuzNavEntry(juzNumber: 2, page: 2, verseKey: '2:1'),
        MushafJuzNavEntry(juzNumber: 3, page: 3, verseKey: '2:2'),
      ],
    );
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    await tester.tap(find.byKey(const ValueKey('reader_mushaf_nav_tab_surah')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader_mushaf_nav_surah_2')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('reader_page_label'))).data,
      'Page 2',
    );

    await tester.tap(find.byKey(const ValueKey('reader_mushaf_nav_tab_verse')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('reader_mushaf_nav_verse_2_2')),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('reader_page_label'))).data,
      'Page 3',
    );

    await tester.tap(find.byKey(const ValueKey('reader_mushaf_nav_tab_juz')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader_mushaf_nav_juz_3')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('reader_page_label'))).data,
      'Page 3',
    );
    expect(fakeApi.juzCalls, isNotEmpty);

    await tester.tap(find.byKey(const ValueKey('reader_mushaf_nav_tab_page')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader_page_1')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('reader_page_label'))).data,
      'Page 1',
    );
  });

  testWidgets('mushaf settings drawer tabs render', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildInteractiveMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    await tester
        .tap(find.byKey(const ValueKey('reader_mushaf_settings_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader_mushaf_settings_tabs')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('reader_mushaf_settings_preview')),
        findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('reader_mushaf_settings_tab_translation')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Translation settings are coming soon.'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('reader_mushaf_settings_tab_word_by_word')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Word by Word settings are coming soon.'), findsOneWidget);
  });

  testWidgets('mushaf controls render without selected check icons',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildInteractiveMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);
    await tester
        .tap(find.byKey(const ValueKey('reader_mushaf_settings_button')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('reader_view_toggle')),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('reader_mushaf_nav_tabs')),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('reader_mushaf_settings_tabs')),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('reader_mushaf_script_tabs')),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
    );
  });

  testWidgets('mushaf selector labels stay single-line', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildInteractiveMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);
    await tester
        .tap(find.byKey(const ValueKey('reader_mushaf_settings_button')));
    await tester.pumpAndSettle();

    void expectSingleLineLabel({
      required Finder scope,
      required String label,
    }) {
      final finder = find.descendant(
        of: scope,
        matching: find.text(label),
      );
      expect(finder, findsOneWidget);
      final textWidget = tester.widget<Text>(finder);
      expect(textWidget.maxLines, 1);
      expect(textWidget.softWrap, isFalse);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    }

    expectSingleLineLabel(
      scope: find.byKey(const ValueKey('reader_view_toggle')),
      label: 'Reading',
    );
    expectSingleLineLabel(
      scope: find.byKey(const ValueKey('reader_mushaf_nav_tabs')),
      label: 'Surah',
    );
    expectSingleLineLabel(
      scope: find.byKey(const ValueKey('reader_mushaf_settings_tabs')),
      label: 'Word By Word',
    );
    expectSingleLineLabel(
      scope: find.byKey(const ValueKey('reader_mushaf_script_tabs')),
      label: 'IndoPak (Soon)',
    );
  });

  testWidgets('arabic font stepper changes mushaf scale', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);
    await tester
        .tap(find.byKey(const ValueKey('reader_mushaf_settings_button')));
    await tester.pumpAndSettle();

    final baselineHeight = tester
        .getSize(find.byKey(const ValueKey('reader_mushaf_line_1')))
        .height;

    await tester.drag(
      find.byKey(const ValueKey('reader_mushaf_settings_scroll')),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader_mushaf_font_plus')));
    await tester.pumpAndSettle();

    final increasedHeight = tester
        .getSize(find.byKey(const ValueKey('reader_mushaf_line_1')))
        .height;
    expect(increasedHeight, greaterThan(baselineHeight));
  });

  testWidgets('settings done and reset behavior', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);
    await tester
        .tap(find.byKey(const ValueKey('reader_mushaf_settings_button')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('reader_mushaf_script_tab_tajweed')),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('reader_mushaf_settings_scroll')),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader_mushaf_font_plus')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('reader_mushaf_font_step')))
          .data,
      '6',
    );

    await tester
        .tap(find.byKey(const ValueKey('reader_mushaf_settings_reset')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('reader_mushaf_font_step')))
          .data,
      '5',
    );

    await tester.tap(find.byKey(const ValueKey('reader_mushaf_settings_done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader_mushaf_settings_tabs')),
        findsNothing);
  });

  testWidgets('hover preview wiring updates settings preview', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildInteractiveMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);
    await tester
        .tap(find.byKey(const ValueKey('reader_mushaf_settings_button')));
    await tester.pumpAndSettle();

    final hoveredWord =
        find.byKey(const ValueKey('reader_mushaf_word_1_0_1:1'));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(hoveredWord));
    await tester.pump();
    await mouse.moveTo(tester.getCenter(hoveredWord));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('reader_mushaf_settings_preview')),
        matching: find.text('All praise and thanks'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('mushaf words render as independent interactive widgets',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildInteractiveMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    expect(
      find.byKey(const ValueKey('reader_mushaf_word_1_0_1:1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader_mushaf_word_1_1_1:1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader_mushaf_marker_1_1:1_1')),
      findsOneWidget,
    );
  });

  testWidgets('mushaf word hover changes hovered word style', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildInteractiveMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    final hoveredWord =
        find.byKey(const ValueKey('reader_mushaf_word_1_0_1:1'));
    final wordInVerse12 =
        find.byKey(const ValueKey('reader_mushaf_word_2_0_1:2'));
    final beforeHoverColor = _wordTextColor(
      tester,
      wordFinder: hoveredWord,
    );

    await mouse.addPointer(location: tester.getCenter(hoveredWord));
    await tester.pump();

    await mouse.moveTo(tester.getCenter(hoveredWord));
    await tester.pump();

    final afterHoverColor = _wordTextColor(
      tester,
      wordFinder: hoveredWord,
    );
    expect(afterHoverColor, isNot(equals(beforeHoverColor)));

    final highlightedVerse11 = _wordHighlightColor(
      tester,
      wordFinder: hoveredWord,
    );
    final highlightedVerse12 = _wordHighlightColor(
      tester,
      wordFinder: wordInVerse12,
    );
    expect(highlightedVerse11, isNot(equals(null)));
    expect(highlightedVerse12, equals(null));
  });

  testWidgets('mushaf marker click opens existing actions for verse',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildInteractiveMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    await tester.tap(
      find.byKey(
        const ValueKey('reader_mushaf_marker_1_1:1_1'),
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Bookmark verse'), findsOneWidget);
    expect(find.text('Add/Edit note'), findsOneWidget);
    expect(find.text('Copy text (Uthmani)'), findsOneWidget);
  });

  testWidgets('mushaf marker selection clears after actions close',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildInteractiveMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    await tester.tap(
      find.byKey(
        const ValueKey('reader_mushaf_marker_1_1:1_1'),
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final selectedColor = _wordHighlightColor(
      tester,
      wordFinder: find.byKey(const ValueKey('reader_mushaf_word_1_0_1:1')),
    );
    expect(selectedColor, isNot(equals(null)));

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.text('Bookmark verse'), findsNothing);
    final clearedColor = _wordHighlightColor(
      tester,
      wordFinder: find.byKey(const ValueKey('reader_mushaf_word_1_0_1:1')),
    );
    expect(clearedColor, equals(null));
  });

  testWidgets('mushaf marker click uses correct ayah for bookmark',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildInteractiveMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    final bookmarkRepo = BookmarkRepo(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    await tester.tap(
      find.byKey(
        const ValueKey('reader_mushaf_marker_1_1:1_1'),
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bookmark verse'));
    await tester.pumpAndSettle();

    final bookmarks = await bookmarkRepo.getBookmarks();
    expect(bookmarks.length, 1);
    expect(bookmarks.first.surah, 1);
    expect(bookmarks.first.ayah, 1);
  });

  testWidgets('mushaf word click opens word popover not verse actions',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildInteractiveMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    await tester.tap(
      find.byKey(
        const ValueKey('reader_mushaf_word_1_0_1:1'),
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reader_mushaf_word_popover_1_0')),
      findsOneWidget,
    );
    expect(find.text('Bookmark verse'), findsNothing);
  });

  testWidgets('mushaf hover tooltip uses word translation when available',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildInteractiveMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    final tooltipFinder =
        find.byKey(const ValueKey('reader_mushaf_word_tooltip_1_0'));
    expect(tooltipFinder, findsOneWidget);
    final tooltip = tester.widget<Tooltip>(tooltipFinder);
    expect(tooltip.message, 'All praise and thanks');
  });

  testWidgets('mushaf hover tooltip falls back when translation is missing',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildInteractiveQcfLikeMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    final tooltipFinder =
        find.byKey(const ValueKey('reader_mushaf_word_tooltip_1_0'));
    expect(tooltipFinder, findsOneWidget);
    final tooltip = tester.widget<Tooltip>(tooltipFinder);
    expect(tooltip.message, 'Translation unavailable');
  });

  testWidgets('mushaf gap click between words does nothing', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildSpacingMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToPageMode(tester);
    await _switchToMushafView(tester);
    await tester.tap(find.byKey(const ValueKey('reader_page_3')));
    await tester.pumpAndSettle();

    final firstWord = find.byKey(const ValueKey('reader_mushaf_word_1_0_2:2'));
    final secondWord = find.byKey(const ValueKey('reader_mushaf_word_1_1_2:2'));
    expect(firstWord, findsOneWidget);
    expect(secondWord, findsOneWidget);

    final gapPoint =
        (tester.getRect(firstWord).center + tester.getRect(secondWord).center) /
            2;
    await tester.tapAt(gapPoint, kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();

    expect(find.text('Bookmark verse'), findsNothing);
    expect(find.byKey(const ValueKey('reader_mushaf_word_popover_1_0')),
        findsNothing);
  });

  testWidgets('mushaf interaction degrades gracefully on verse mismatch',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildMismatchMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    expect(find.byKey(const ValueKey('reader_mushaf_line_1')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reader_mushaf_marker_1_1:1_1')),
      findsNothing,
    );
    expect(tester.takeException(), equals(null));
  });

  testWidgets(
      'mushaf uses vertical scroll instead of fit-to-height compression',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1200, 340));

    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    final scrollContainer = find.byKey(const ValueKey('reader_mushaf_scroll'));
    expect(scrollContainer, findsOneWidget);

    final scrollableState = _mushafScrollableState(tester);
    expect(scrollableState.position.maxScrollExtent, greaterThan(0));

    final offsetBefore = scrollableState.position.pixels;
    await tester.drag(scrollContainer, const Offset(0, -180));
    await tester.pumpAndSettle();
    final offsetAfter = _mushafScrollableState(tester).position.pixels;

    expect(offsetAfter, greaterThan(offsetBefore));
  });

  testWidgets('mushaf line height remains baseline under constrained height',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1200, 400));

    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    final canvasContext =
        tester.element(find.byKey(const ValueKey('reader_mushaf_canvas')));
    final viewportHeight = MediaQuery.sizeOf(canvasContext).height;
    final lineHeight = tester
        .getSize(find.byKey(const ValueKey('reader_mushaf_line_1')))
        .height;
    expect(lineHeight, closeTo(viewportHeight * 0.061, 1.0));
  });

  testWidgets('mushaf canvas width stays bounded and responsive',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1600, 900));

    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    final canvasFinder = find.byKey(const ValueKey('reader_mushaf_canvas'));
    final wideCanvasWidth = tester.getSize(canvasFinder).width;

    await tester.binding.setSurfaceSize(const Size(980, 900));
    await tester.pumpAndSettle();
    final narrowCanvasWidth = tester.getSize(canvasFinder).width;

    expect(wideCanvasWidth, lessThanOrEqualTo(860.1));
    expect(wideCanvasWidth, greaterThan(400));
    expect(narrowCanvasWidth, lessThanOrEqualTo(wideCanvasWidth));
  });

  testWidgets('mushaf surah-start page uses SurahNames header and svg basmala',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildSurahStartMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToPageMode(tester);
    await _switchToMushafView(tester);
    await tester.tap(find.byKey(const ValueKey('reader_page_2')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reader_mushaf_chapter_header_2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader_mushaf_external_basmala_2')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('reader_mushaf_chapter_header_2')),
        matching: find.byType(SvgPicture),
      ),
      findsOneWidget,
    );
    final icon = tester.widget<Text>(
      find.byKey(const ValueKey('reader_mushaf_chapter_icon_2')),
    );
    expect(icon.style?.fontFamily, 'SurahNames');
    expect(icon.style?.fontSize, 96);
    expect(find.byKey(const ValueKey<String>('basmala_header')), findsNothing);
  });

  testWidgets('mushaf header scrolls with text', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1200, 340));

    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    final headerFinder =
        find.byKey(const ValueKey('reader_mushaf_chapter_header_2'));
    expect(headerFinder, findsOneWidget);
    final headerTopBefore = tester.getTopLeft(headerFinder).dy;

    await tester.drag(
      find.byKey(const ValueKey('reader_mushaf_scroll')),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();

    final headerTopAfter = tester.getTopLeft(headerFinder).dy;
    expect(headerTopAfter, lessThan(headerTopBefore));
  });

  testWidgets('mushaf chapter 1 and 9 headers omit external basmala',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.byPage(
      <int, MushafPageData>{
        1: _buildInteractiveMushafDataFixture(),
        2: _buildChapterNineStartMushafDataFixture(),
      },
    );
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToPageMode(tester);
    await _switchToMushafView(tester);

    await tester.tap(find.byKey(const ValueKey('reader_page_1')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader_mushaf_chapter_header_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader_mushaf_external_basmala_1')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('reader_page_2')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader_mushaf_chapter_header_9')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader_mushaf_external_basmala_9')),
      findsNothing,
    );
  });

  testWidgets('surah-start page does not render synthetic leading blank lines',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildSurahStartMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToPageMode(tester);
    await _switchToMushafView(tester);
    await tester.tap(find.byKey(const ValueKey('reader_page_2')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader_mushaf_line_1')), findsNothing);
    expect(find.byKey(const ValueKey('reader_mushaf_line_2')), findsNothing);
    expect(find.byKey(const ValueKey('reader_mushaf_line_3')), findsOneWidget);
  });

  testWidgets('mushaf preserves verse code_v2 spacing', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildVerseSpacingMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('A  B C'), findsNothing);
  });

  testWidgets('mushaf marker click resolves visible verse with qcf-like glyphs',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildInteractiveQcfLikeMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    await tester.tap(
      find.byKey(const ValueKey('reader_mushaf_marker_1_1:1_1')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Bookmark verse'), findsOneWidget);
    expect(find.text('Add/Edit note'), findsOneWidget);
    expect(find.text('Copy text (Uthmani)'), findsOneWidget);
  });

  testWidgets('mushaf word click does not trigger verse action sheet',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi =
        _FakeQuranComApi.withData(_buildInteractiveQcfLikeMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    await tester.tap(
      find.byKey(const ValueKey('reader_mushaf_word_1_0_1:1')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Bookmark verse'), findsNothing);
    expect(
      find.byKey(const ValueKey('reader_mushaf_word_popover_1_0')),
      findsOneWidget,
    );
  });

  testWidgets('mushaf line size stability between page1 and page2',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1200, 900));

    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.byPage(
      <int, MushafPageData>{
        1: _buildMushafDataFixture(),
        2: _buildSurahStartMushafDataFixture(),
      },
    );
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToPageMode(tester);
    await _switchToMushafView(tester);

    await tester.tap(find.byKey(const ValueKey('reader_page_1')));
    await tester.pumpAndSettle();
    final page1Line3FontSize = _lineQcfFontSize(
      tester,
      lineNumber: 3,
      familyName: 'qcf_test_family',
    );

    await tester.tap(find.byKey(const ValueKey('reader_page_2')));
    await tester.pumpAndSettle();
    final page2Line3FontSize = _lineQcfFontSize(
      tester,
      lineNumber: 3,
      familyName: 'qcf_test_family',
    );

    expect(page2Line3FontSize, greaterThan(page1Line3FontSize * 0.8));
  });

  testWidgets('mushaf mode renders fixed 15 lines', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('reader_view_toggle')),
        matching: find.text('Reading'),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 1; i <= 15; i++) {
      expect(find.byKey(ValueKey('reader_mushaf_line_$i')), findsOneWidget);
    }
  });

  testWidgets('mushaf plain uses mushaf=1 and v2 font', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('reader_view_toggle')),
        matching: find.text('Reading'),
      ),
    );
    await tester.pumpAndSettle();

    expect(fakeApi.calls, isNotEmpty);
    expect(fakeApi.calls.last.mushafId, 1);
    expect(fakeFonts.calls, isNotEmpty);
    expect(fakeFonts.calls.last.variant, QcfFontVariant.v2);
  });

  testWidgets('mushaf tajweed uses mushaf=19 and v4 font', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('reader_view_toggle')),
        matching: find.text('Reading'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('reader_mushaf_settings_button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('reader_mushaf_script_tab_tajweed')),
    );
    await tester.pumpAndSettle();

    expect(fakeApi.calls.last.mushafId, 19);
    expect(fakeFonts.calls.last.variant, QcfFontVariant.v4tajweed);
  });

  testWidgets('mushaf uses QCF font for code_v2 end token', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('reader_view_toggle')),
        matching: find.text('Reading'),
      ),
    );
    await tester.pumpAndSettle();

    final markerWord = find.byKey(const ValueKey('reader_mushaf_word_1_0_2:1'));
    expect(markerWord, findsOneWidget);
    final markerText = tester.widget<Text>(markerWord);
    expect(markerText.style?.fontFamily, 'qcf_test_family');
  });

  testWidgets('each mushaf line renders as a word row', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('reader_view_toggle')),
        matching: find.text('Reading'),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 1; i <= 15; i++) {
      final lineFinder = find.byKey(ValueKey('reader_mushaf_line_$i'));
      final rows = find.descendant(of: lineFinder, matching: find.byType(Row));
      expect(rows, findsOneWidget);
    }
  });

  testWidgets('mushaf default sizing follows calibrated range', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1600, 900));

    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(_buildMushafDataFixture());
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToMushafView(tester);

    final baselineFontSize = _lineQcfFontSize(
      tester,
      lineNumber: 1,
      familyName: 'qcf_test_family',
    );
    final baselineCanvasWidth = tester
        .getSize(find.byKey(const ValueKey('reader_mushaf_canvas')))
        .width;

    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    await tester.pumpAndSettle();

    final largerViewportFontSize = _lineQcfFontSize(
      tester,
      lineNumber: 1,
      familyName: 'qcf_test_family',
    );
    final largerViewportCanvasWidth = tester
        .getSize(find.byKey(const ValueKey('reader_mushaf_canvas')))
        .width;

    expect(baselineCanvasWidth, inInclusiveRange(400.0, 540.0));
    expect(baselineFontSize, inInclusiveRange(16.0, 34.0));
    expect(
        largerViewportCanvasWidth, greaterThanOrEqualTo(baselineCanvasWidth));
    expect(largerViewportFontSize, greaterThanOrEqualTo(baselineFontSize));
  });

  testWidgets('mushaf non-centered line uses spaceBetween word layout',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(720, 820));

    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(
      _buildSpacingMushafDataFixture(),
    );
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToPageMode(tester);
    await _switchToMushafView(tester);
    await tester.tap(find.byKey(const ValueKey('reader_page_3')));
    await tester.pumpAndSettle();

    expect(
      _lineMainAxisAlignment(
        tester,
        lineNumber: 1,
      ),
      MainAxisAlignment.spaceBetween,
    );
  });

  testWidgets('mushaf center map centers page 2 and not page 3 line 1',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1200, 900));

    final db = AppDatabase(NativeDatabase.memory());
    final fakeApi = _FakeQuranComApi.withData(
      _buildDenseMushafDataFixture(denseWordCount: 80),
    );
    final fakeFonts = _FakeQcfFontManager(
      familyName: 'qcf_test_family',
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        quranComApiProvider.overrideWithValue(fakeApi),
        qcfFontManagerProvider.overrideWithValue(fakeFonts),
      ],
    );
    addTearDown(container.dispose);
    _registerPumpCleanup(tester);

    await _seedAyahs(db);
    await _pumpReader(tester, container);
    await _switchToPageMode(tester);
    await _switchToMushafView(tester);
    await tester.tap(find.byKey(const ValueKey('reader_page_2')));
    await tester.pumpAndSettle();

    expect(
      _lineMainAxisAlignment(
        tester,
        lineNumber: 1,
      ),
      MainAxisAlignment.center,
    );

    await tester.tap(find.byKey(const ValueKey('reader_page_3')));
    await tester.pumpAndSettle();

    expect(
      _lineMainAxisAlignment(
        tester,
        lineNumber: 1,
      ),
      MainAxisAlignment.spaceBetween,
    );
  });
}

Future<void> _seedAyahs(AppDatabase db) async {
  await db.batch((batch) {
    batch.insertAll(
      db.ayah,
      [
        AyahCompanion.insert(
          surah: 1,
          ayah: 1,
          textUthmani: 'ٱلْحَمْدُ لِلَّٰهِ',
          pageMadina: const Value(1),
        ),
        AyahCompanion.insert(
          surah: 1,
          ayah: 2,
          textUthmani: 'رَبِّ ٱلْعَٰلَمِينَ',
          pageMadina: const Value(1),
        ),
        AyahCompanion.insert(
          surah: 1,
          ayah: 3,
          textUthmani: 'مَٰلِكِ يَوْمِ ٱلدِّينِ',
          pageMadina: const Value(2),
        ),
        AyahCompanion.insert(
          surah: 2,
          ayah: 1,
          textUthmani: 'الم',
          pageMadina: const Value(2),
        ),
        AyahCompanion.insert(
          surah: 2,
          ayah: 2,
          textUthmani: 'ذَٰلِكَ ٱلْكِتَٰبُ',
          pageMadina: const Value(3),
        ),
      ],
    );
  });
}

MushafPageData _buildMushafDataFixture() {
  final words = <MushafWord>[];
  for (var line = 1; line <= 15; line++) {
    words.add(
      MushafWord(
        codeV2: line == 1 ? '۝' : 'C$line',
        textQpcHafs: line == 1 ? 'END' : 'W$line',
        charTypeName: line == 1 ? 'end' : 'word',
        lineNumber: line,
        position: line,
        pageNumber: 1,
      ),
    );
    words.add(
      MushafWord(
        codeV2: '',
        textQpcHafs: 'T$line',
        charTypeName: 'word',
        lineNumber: line,
        position: line + 100,
        pageNumber: 1,
      ),
    );
  }
  return MushafPageData(
    words: words,
    verses: [
      MushafVerseData(
        verseKey: '2:1',
        codeV2: 'X',
        words: words,
      ),
    ],
    meta: const MushafPageMeta(
      firstChapterId: 2,
      firstVerseNumber: 1,
      firstVerseKey: '2:1',
    ),
  );
}

MushafPageData _buildMushafDataWithContextMetaFixture() {
  final base = _buildMushafDataFixture();
  return MushafPageData(
    words: base.words,
    verses: base.verses,
    meta: const MushafPageMeta(
      firstChapterId: 2,
      firstVerseNumber: 1,
      firstVerseKey: '2:1',
      pageNumber: 1,
      juzNumber: 3,
      hizbNumber: 5,
      rubElHizbNumber: 17,
    ),
  );
}

MushafPageData _buildInteractiveMushafDataFixture() {
  const verse11Words = <MushafWord>[
    MushafWord(
      codeV2: 'A',
      textQpcHafs: 'A',
      translationText: 'All praise and thanks',
      transliterationText: 'Al-hamdu',
      charTypeName: 'word',
      lineNumber: 1,
      position: 1,
      pageNumber: 1,
    ),
    MushafWord(
      codeV2: '۝',
      textQpcHafs: '1',
      charTypeName: 'end',
      lineNumber: 1,
      position: 2,
      pageNumber: 1,
    ),
  ];
  const verse12Words = <MushafWord>[
    MushafWord(
      codeV2: 'B',
      textQpcHafs: 'B',
      charTypeName: 'word',
      lineNumber: 2,
      position: 3,
      pageNumber: 1,
    ),
    MushafWord(
      codeV2: '۝',
      textQpcHafs: '2',
      charTypeName: 'end',
      lineNumber: 2,
      position: 4,
      pageNumber: 1,
    ),
  ];

  return MushafPageData(
    words: const [
      ...verse11Words,
      ...verse12Words,
    ],
    verses: const [
      MushafVerseData(
        verseKey: '1:1',
        codeV2: 'A ۝',
        words: verse11Words,
      ),
      MushafVerseData(
        verseKey: '1:2',
        codeV2: 'B ۝',
        words: verse12Words,
      ),
    ],
    meta: const MushafPageMeta(
      firstChapterId: 1,
      firstVerseNumber: 1,
      firstVerseKey: '1:1',
    ),
  );
}

MushafPageData _buildMismatchMushafDataFixture() {
  const words = <MushafWord>[
    MushafWord(
      codeV2: 'A',
      textQpcHafs: 'A',
      charTypeName: 'word',
      lineNumber: 1,
      position: 1,
      pageNumber: 1,
    ),
    MushafWord(
      codeV2: 'B',
      textQpcHafs: 'B',
      charTypeName: 'word',
      lineNumber: 1,
      position: 2,
      pageNumber: 1,
    ),
  ];

  return MushafPageData(
    words: words,
    verses: const [
      MushafVerseData(
        verseKey: '1:1',
        codeV2: 'A B',
        words: <MushafWord>[
          MushafWord(
            codeV2: 'A',
            textQpcHafs: 'A',
            charTypeName: 'word',
            lineNumber: 1,
            position: 1,
            pageNumber: 1,
          ),
        ],
      ),
    ],
    meta: const MushafPageMeta(
      firstChapterId: 1,
      firstVerseNumber: 1,
      firstVerseKey: '1:1',
    ),
  );
}

MushafPageData _buildSimpleQuranComDataFixture() {
  const verse11Words = <MushafWord>[
    MushafWord(
      codeV2: '۝',
      textQpcHafs: '۝',
      charTypeName: 'end',
      lineNumber: 1,
      position: 1,
      pageNumber: 1,
    ),
    MushafWord(
      codeV2: '',
      textQpcHafs: 'ٱلْحَمْدُ',
      charTypeName: 'word',
      lineNumber: 1,
      position: 2,
      pageNumber: 1,
    ),
  ];
  const verse12Words = <MushafWord>[
    MushafWord(
      codeV2: 'A',
      textQpcHafs: 'A',
      charTypeName: 'word',
      lineNumber: 2,
      position: 3,
      pageNumber: 1,
    ),
    MushafWord(
      codeV2: '',
      textQpcHafs: 'رَبِّ',
      charTypeName: 'word',
      lineNumber: 2,
      position: 4,
      pageNumber: 1,
    ),
  ];
  const verse13Words = <MushafWord>[
    MushafWord(
      codeV2: 'B',
      textQpcHafs: 'B',
      charTypeName: 'word',
      lineNumber: 1,
      position: 1,
      pageNumber: 2,
    ),
    MushafWord(
      codeV2: '',
      textQpcHafs: 'مَٰلِكِ',
      charTypeName: 'word',
      lineNumber: 1,
      position: 2,
      pageNumber: 2,
    ),
  ];

  return MushafPageData(
    words: const [
      ...verse11Words,
      ...verse12Words,
      ...verse13Words,
    ],
    verses: const [
      MushafVerseData(
        verseKey: '1:1',
        codeV2: '۝ ٱلْحَمْدُ',
        words: verse11Words,
      ),
      MushafVerseData(
        verseKey: '1:2',
        codeV2: 'A رَبِّ',
        words: verse12Words,
      ),
      MushafVerseData(
        verseKey: '1:3',
        codeV2: 'B مَٰلِكِ',
        words: verse13Words,
      ),
    ],
    meta: const MushafPageMeta(
      firstChapterId: 1,
      firstVerseNumber: 1,
      firstVerseKey: '1:1',
    ),
  );
}

MushafPageData _buildSurahStartMushafDataFixture() {
  const verse21Words = <MushafWord>[
    MushafWord(
      codeV2: 'ﱁ',
      textQpcHafs: 'الٓمٓ',
      charTypeName: 'word',
      lineNumber: 3,
      position: 1,
      pageNumber: 2,
    ),
    MushafWord(
      codeV2: 'ﱂ',
      textQpcHafs: '١',
      charTypeName: 'end',
      lineNumber: 3,
      position: 2,
      pageNumber: 2,
    ),
  ];
  const verse22Words = <MushafWord>[
    MushafWord(
      codeV2: 'ﱃ',
      textQpcHafs: 'ذَٰلِكَ',
      charTypeName: 'word',
      lineNumber: 3,
      position: 3,
      pageNumber: 2,
    ),
    MushafWord(
      codeV2: 'ﱄ',
      textQpcHafs: 'ٱلْكِتَٰبُ',
      charTypeName: 'word',
      lineNumber: 3,
      position: 4,
      pageNumber: 2,
    ),
    MushafWord(
      codeV2: 'ﱌ',
      textQpcHafs: '٢',
      charTypeName: 'end',
      lineNumber: 4,
      position: 5,
      pageNumber: 2,
    ),
  ];

  return MushafPageData(
    words: const [
      ...verse21Words,
      ...verse22Words,
    ],
    verses: const [
      MushafVerseData(
        verseKey: '2:1',
        codeV2: 'ﱁ ﱂ',
        words: verse21Words,
      ),
      MushafVerseData(
        verseKey: '2:2',
        codeV2: 'ﱃ ﱄ  ﱌ',
        words: verse22Words,
      ),
    ],
    meta: const MushafPageMeta(
      firstChapterId: 2,
      firstVerseNumber: 1,
      firstVerseKey: '2:1',
    ),
  );
}

MushafPageData _buildChapterNineStartMushafDataFixture() {
  const verse91Words = <MushafWord>[
    MushafWord(
      codeV2: 'Z',
      textQpcHafs: 'بَرَاءَةٌ',
      charTypeName: 'word',
      lineNumber: 2,
      position: 1,
      pageNumber: 2,
    ),
    MushafWord(
      codeV2: '۝',
      textQpcHafs: '١',
      charTypeName: 'end',
      lineNumber: 2,
      position: 2,
      pageNumber: 2,
    ),
  ];
  return MushafPageData(
    words: verse91Words,
    verses: const [
      MushafVerseData(
        verseKey: '9:1',
        codeV2: 'Z ۝',
        words: verse91Words,
      ),
    ],
    meta: const MushafPageMeta(
      firstChapterId: 9,
      firstVerseNumber: 1,
      firstVerseKey: '9:1',
    ),
  );
}

MushafPageData _buildVerseSpacingMushafDataFixture() {
  const verseWords = <MushafWord>[
    MushafWord(
      codeV2: 'A',
      textQpcHafs: 'A',
      charTypeName: 'word',
      lineNumber: 1,
      position: 1,
      pageNumber: 1,
    ),
    MushafWord(
      codeV2: 'B',
      textQpcHafs: 'B',
      charTypeName: 'word',
      lineNumber: 1,
      position: 2,
      pageNumber: 1,
    ),
    MushafWord(
      codeV2: 'C',
      textQpcHafs: 'C',
      charTypeName: 'word',
      lineNumber: 1,
      position: 3,
      pageNumber: 1,
    ),
  ];

  return MushafPageData(
    words: verseWords,
    verses: const [
      MushafVerseData(
        verseKey: '1:1',
        codeV2: 'A  B C',
        words: verseWords,
      ),
    ],
    meta: const MushafPageMeta(
      firstChapterId: 1,
      firstVerseNumber: 1,
      firstVerseKey: '1:1',
    ),
  );
}

MushafPageData _buildInteractiveQcfLikeMushafDataFixture() {
  const verseWords = <MushafWord>[
    MushafWord(
      codeV2: 'ﱁ',
      textQpcHafs: 'الٓمٓ',
      charTypeName: 'word',
      lineNumber: 1,
      position: 1,
      pageNumber: 1,
    ),
    MushafWord(
      codeV2: 'ﱂ',
      textQpcHafs: '١',
      charTypeName: 'end',
      lineNumber: 1,
      position: 2,
      pageNumber: 1,
    ),
  ];

  return MushafPageData(
    words: verseWords,
    verses: const [
      MushafVerseData(
        verseKey: '1:1',
        codeV2: 'ﱁ ﱂ',
        words: verseWords,
      ),
    ],
    meta: const MushafPageMeta(
      firstChapterId: 1,
      firstVerseNumber: 1,
      firstVerseKey: '1:1',
    ),
  );
}

MushafPageData _buildDenseMushafDataFixture({required int denseWordCount}) {
  final words = <MushafWord>[];
  for (var i = 0; i < denseWordCount; i++) {
    words.add(
      MushafWord(
        codeV2: 'G',
        textQpcHafs: 'G',
        charTypeName: 'word',
        lineNumber: 1,
        position: i + 1,
        pageNumber: 3,
      ),
    );
  }
  for (var line = 2; line <= 15; line++) {
    words.add(
      MushafWord(
        codeV2: 'C$line',
        textQpcHafs: 'W$line',
        charTypeName: 'word',
        lineNumber: line,
        position: line + 100,
        pageNumber: 3,
      ),
    );
  }
  return MushafPageData(
    words: words,
    verses: [
      MushafVerseData(
        verseKey: '2:2',
        codeV2: 'G i i G',
        words: words,
      ),
    ],
    meta: const MushafPageMeta(
      firstChapterId: 2,
      firstVerseNumber: 2,
      firstVerseKey: '2:2',
    ),
  );
}

MushafPageData _buildSpacingMushafDataFixture() {
  final words = <MushafWord>[
    const MushafWord(
      codeV2: 'G',
      textQpcHafs: 'G',
      charTypeName: 'word',
      lineNumber: 1,
      position: 1,
      pageNumber: 3,
    ),
    const MushafWord(
      codeV2: '',
      textQpcHafs: 'iiiiiiii',
      charTypeName: 'word',
      lineNumber: 1,
      position: 2,
      pageNumber: 3,
    ),
    const MushafWord(
      codeV2: '',
      textQpcHafs: 'iiiiiiii',
      charTypeName: 'word',
      lineNumber: 1,
      position: 3,
      pageNumber: 3,
    ),
    const MushafWord(
      codeV2: 'G',
      textQpcHafs: 'G',
      charTypeName: 'word',
      lineNumber: 1,
      position: 4,
      pageNumber: 3,
    ),
  ];
  for (var line = 2; line <= 15; line++) {
    words.add(
      MushafWord(
        codeV2: 'C$line',
        textQpcHafs: 'W$line',
        charTypeName: 'word',
        lineNumber: line,
        position: line + 100,
        pageNumber: 3,
      ),
    );
  }
  return MushafPageData(
    words: words,
    verses: [
      MushafVerseData(
        verseKey: '2:2',
        codeV2: 'G iiiiiiii iiiiiiii G',
        words: words,
      ),
    ],
    meta: const MushafPageMeta(
      firstChapterId: 2,
      firstVerseNumber: 2,
      firstVerseKey: '2:2',
    ),
  );
}

class _FakeAyahAudioService implements AyahAudioService {
  final StreamController<AyahAudioState> _stateController =
      StreamController<AyahAudioState>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  AyahAudioState _state = const AyahAudioState.initial();
  final List<AyahRef> playAyahCalls = <AyahRef>[];
  final List<AyahRef> playFromCalls = <AyahRef>[];
  final List<double> speedChanges = <double>[];
  final List<int> repeatChanges = <int>[];
  int pauseCalls = 0;
  int resumeCalls = 0;
  int nextCalls = 0;
  int previousCalls = 0;
  int stopCalls = 0;
  int seekToCalls = 0;
  Duration? lastSeekTo;

  @override
  Stream<AyahAudioState> get stateStream async* {
    yield _state;
    yield* _stateController.stream;
  }

  @override
  Stream<String> get errorStream => _errorController.stream;

  @override
  AyahAudioState get currentState => _state;

  @override
  Future<void> updateSource(
    AyahAudioSource source, {
    bool stopPlayback = true,
  }) async {}

  void emitState(AyahAudioState state) {
    _state = state;
    _stateController.add(state);
  }

  @override
  Future<void> next() async {
    nextCalls += 1;
  }

  @override
  Future<void> pause() async {
    pauseCalls += 1;
  }

  @override
  Future<void> playAyah(int surah, int ayah) async {
    playAyahCalls.add(AyahRef(surah: surah, ayah: ayah));
  }

  @override
  Future<void> playFrom(int surah, int ayah) async {
    playFromCalls.add(AyahRef(surah: surah, ayah: ayah));
  }

  @override
  Future<void> previous() async {
    previousCalls += 1;
  }

  @override
  Future<void> seekTo(Duration position) async {
    seekToCalls += 1;
    lastSeekTo = position;
  }

  @override
  Future<void> resume() async {
    resumeCalls += 1;
  }

  @override
  Future<void> setRepeatCount(int repeatCount) async {
    repeatChanges.add(repeatCount);
  }

  @override
  Future<void> setSpeed(double speed) async {
    speedChanges.add(speed);
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _errorController.close();
  }
}

class _FakeQuranComApiCall {
  const _FakeQuranComApiCall({
    required this.page,
    required this.mushafId,
    this.translationResourceId,
  });

  final int page;
  final int mushafId;
  final int? translationResourceId;
}

class _FakeQuranComApi extends QuranComApi {
  _FakeQuranComApi.withData(
    this._data, {
    List<MushafJuzNavEntry>? juzEntries,
    bool throwJuzError = false,
  })  : _byPage = null,
        _juzEntries = juzEntries,
        _throwJuzError = throwJuzError;

  _FakeQuranComApi.byPage(
    Map<int, MushafPageData> byPage, {
    List<MushafJuzNavEntry>? juzEntries,
    bool throwJuzError = false,
  })  : assert(byPage.isNotEmpty),
        _data = byPage.values.first,
        _byPage = Map<int, MushafPageData>.from(byPage),
        _juzEntries = juzEntries,
        _throwJuzError = throwJuzError;

  final MushafPageData _data;
  final Map<int, MushafPageData>? _byPage;
  final List<MushafJuzNavEntry>? _juzEntries;
  final bool _throwJuzError;
  final List<_FakeQuranComApiCall> calls = <_FakeQuranComApiCall>[];
  final List<int> juzCalls = <int>[];

  MushafPageData _resolve(int page) {
    return _withVerseKeys(_byPage?[page] ?? _data);
  }

  MushafPageData _withVerseKeys(MushafPageData data) {
    final hasVerseKeys = data.words.every(
      (word) => (word.verseKey ?? '').trim().isNotEmpty,
    );
    if (hasVerseKeys || data.verses.isEmpty) {
      return data;
    }

    final rebuiltWords = <MushafWord>[];
    final rebuiltVerses = <MushafVerseData>[];
    for (final verse in data.verses) {
      final verseWords = <MushafWord>[
        for (final word in verse.words)
          MushafWord(
            verseKey: verse.verseKey,
            codeV2: word.codeV2,
            textQpcHafs: word.textQpcHafs,
            translationText: word.translationText,
            transliterationText: word.transliterationText,
            charTypeName: word.charTypeName,
            lineNumber: word.lineNumber,
            position: word.position,
            pageNumber: word.pageNumber,
          ),
      ];
      rebuiltWords.addAll(verseWords);
      rebuiltVerses.add(
        MushafVerseData(
          verseKey: verse.verseKey,
          codeV2: verse.codeV2,
          words: verseWords,
          translations: verse.translations,
        ),
      );
    }

    if (rebuiltWords.length != data.words.length) {
      return data;
    }
    return MushafPageData(
      words: rebuiltWords,
      verses: rebuiltVerses,
      meta: data.meta,
    );
  }

  @override
  Future<MushafPageData> getPage({
    required int page,
    required int mushafId,
  }) async {
    calls.add(
      _FakeQuranComApiCall(
        page: page,
        mushafId: mushafId,
      ),
    );
    return _resolve(page);
  }

  @override
  Future<MushafPageData> getPageWithVerses({
    required int page,
    required int mushafId,
    bool requireWordTooltipData = false,
    int? translationResourceId,
  }) async {
    calls.add(
      _FakeQuranComApiCall(
        page: page,
        mushafId: mushafId,
        translationResourceId: translationResourceId,
      ),
    );
    return _resolve(page);
  }

  @override
  Future<MushafVerseData> getVerseDataByPage({
    required int page,
    required int mushafId,
    required String verseKey,
    int? translationResourceId,
  }) async {
    calls.add(
      _FakeQuranComApiCall(
        page: page,
        mushafId: mushafId,
        translationResourceId: translationResourceId,
      ),
    );
    final data = _resolve(page);
    for (final verse in data.verses) {
      if (verse.verseKey == verseKey) {
        return verse;
      }
    }
    throw QuranComApiException('Verse $verseKey not found in page $page.');
  }

  @override
  Future<List<MushafJuzNavEntry>> getJuzIndex({
    required int mushafId,
  }) async {
    juzCalls.add(mushafId);
    if (_throwJuzError) {
      throw const QuranComApiException('Failed to load juz index.');
    }
    return _juzEntries ??
        List<MushafJuzNavEntry>.generate(
          30,
          (index) => MushafJuzNavEntry(
            juzNumber: index + 1,
            page: index + 1,
            verseKey: '${index + 1}:1',
          ),
        );
  }
}

class _FakeQuranComChaptersService extends QuranComChaptersService {
  _FakeQuranComChaptersService({
    required Map<String, List<QuranComChapterEntry>> byLanguageCode,
  })  : _byLanguageCode = byLanguageCode,
        super();

  final Map<String, List<QuranComChapterEntry>> _byLanguageCode;

  @override
  Future<List<QuranComChapterEntry>> getChapters({
    required String languageCode,
  }) async {
    return _byLanguageCode[languageCode] ?? const <QuranComChapterEntry>[];
  }

  @override
  Future<QuranComChapterEntry?> getChapter({
    required int chapterId,
    required String languageCode,
  }) async {
    final chapters = await getChapters(languageCode: languageCode);
    for (final chapter in chapters) {
      if (chapter.id == chapterId) {
        return chapter;
      }
    }
    return null;
  }
}

class _FakeQcfFontCall {
  const _FakeQcfFontCall({
    required this.page,
    required this.variant,
  });

  final int page;
  final QcfFontVariant variant;
}

class _FakeQcfFontManager extends QcfFontManager {
  _FakeQcfFontManager({
    required this.familyName,
  });

  final String familyName;
  final List<_FakeQcfFontCall> calls = <_FakeQcfFontCall>[];

  @override
  Future<QcfFontSelection> ensurePageFont({
    required int page,
    required QcfFontVariant variant,
  }) async {
    calls.add(_FakeQcfFontCall(page: page, variant: variant));
    return QcfFontSelection(
      familyName: familyName,
      requestedVariant: variant,
      effectiveVariant: variant,
    );
  }
}

class _FakeAppPreferencesStore implements AppPreferencesStore {
  _FakeAppPreferencesStore({
    StoredAppPreferences? initial,
  }) : _stored = initial ?? const StoredAppPreferences();

  StoredAppPreferences _stored;

  @override
  Future<StoredAppPreferences> load() async => _stored;

  @override
  Future<void> saveLanguageCode(String code) async {
    _stored = StoredAppPreferences(
      languageCode: code,
      themeCode: _stored.themeCode,
      companionAutoReciteEnabled: _stored.companionAutoReciteEnabled,
    );
  }

  @override
  Future<void> saveThemeCode(String code) async {
    _stored = StoredAppPreferences(
      languageCode: _stored.languageCode,
      themeCode: code,
      companionAutoReciteEnabled: _stored.companionAutoReciteEnabled,
    );
  }

  @override
  Future<void> saveCompanionAutoReciteEnabled(bool value) async {
    _stored = StoredAppPreferences(
      languageCode: _stored.languageCode,
      themeCode: _stored.themeCode,
      companionAutoReciteEnabled: value,
    );
  }
}

Future<void> _pumpReader(
  WidgetTester tester,
  ProviderContainer container, {
  ReaderScreen screen = const ReaderScreen(),
  Locale? locale,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLanguage.values
            .map((language) => language.locale)
            .toList(growable: false),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: screen),
      ),
    ),
  );
  await tester.pump();
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('reader_view_toggle')),
  );
}

Future<void> _switchToMushafView(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const ValueKey('reader_view_toggle')),
      matching: find.text('Reading'),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _switchToPageTab(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('reader_mushaf_nav_tab_page')));
  await tester.pumpAndSettle();
}

Future<void> _switchToPageMode(WidgetTester tester) async {
  await _switchToPageTab(tester);
}

MainAxisAlignment _lineMainAxisAlignment(
  WidgetTester tester, {
  required int lineNumber,
}) {
  final lineFinder = find.byKey(ValueKey('reader_mushaf_line_$lineNumber'));
  final rowFinder = find.descendant(of: lineFinder, matching: find.byType(Row));
  expect(rowFinder, findsOneWidget);
  return tester.widget<Row>(rowFinder).mainAxisAlignment;
}

double _lineQcfFontSize(
  WidgetTester tester, {
  required int lineNumber,
  required String familyName,
}) {
  final lineFinder = find.byKey(ValueKey('reader_mushaf_line_$lineNumber'));
  final textFinder =
      find.descendant(of: lineFinder, matching: find.byType(Text));
  final texts = tester.widgetList<Text>(textFinder).toList(growable: false);
  final qcfText = texts.firstWhere(
    (text) => text.style?.fontFamily == familyName,
  );
  return qcfText.style!.fontSize!;
}

ScrollableState _mushafScrollableState(WidgetTester tester) {
  final scrollFinder = find.descendant(
    of: find.byKey(const ValueKey('reader_mushaf_scroll')),
    matching: find.byType(Scrollable),
  );
  expect(scrollFinder, findsOneWidget);
  return tester.state<ScrollableState>(scrollFinder);
}

Color? _wordHighlightColor(
  WidgetTester tester, {
  required Finder wordFinder,
}) {
  final containerFinder = find.ancestor(
    of: wordFinder,
    matching: find.byType(AnimatedContainer),
  );
  expect(containerFinder, findsWidgets);
  final container = tester.widget<AnimatedContainer>(containerFinder.first);
  final decoration = container.decoration;
  if (decoration is! BoxDecoration) {
    return null;
  }
  return decoration.color;
}

Color? _wordTextColor(
  WidgetTester tester, {
  required Finder wordFinder,
}) {
  final text = tester.widget<Text>(wordFinder);
  return text.style?.color;
}

void _registerPumpCleanup(WidgetTester tester) {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}

Future<void> _pumpUntilAyahHighlighted(
  WidgetTester tester,
  Finder materialFinder, {
  Duration timeout = const Duration(seconds: 5),
  Duration step = const Duration(milliseconds: 50),
}) async {
  var elapsed = Duration.zero;
  while (elapsed <= timeout) {
    if (materialFinder.evaluate().isNotEmpty) {
      final material = tester.widget<Material>(materialFinder);
      if (material.color != Colors.transparent) {
        return;
      }
    }
    await tester.pump(step);
    elapsed += step;
  }

  throw TestFailure(
    'Timed out after ${timeout.inMilliseconds}ms waiting for highlight on $materialFinder.',
  );
}
