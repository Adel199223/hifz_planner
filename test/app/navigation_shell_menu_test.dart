import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/app/app_preferences.dart';
import 'package:hifz_planner/app/app_preferences_store.dart';
import 'package:hifz_planner/data/database/app_database.dart';
import 'package:hifz_planner/data/providers/database_providers.dart';
import 'package:hifz_planner/main.dart';

import '../helpers/pump_until_found.dart';

void main() {
  testWidgets('global menu drawer shows only required destinations',
      (tester) async {
    final fakeStore = _FakeAppPreferencesStore();
    final container = _createContainer(fakeStore);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HifzPlannerApp(),
      ),
    );
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('today_screen_root')),
    );

    await tester.tap(find.byKey(const ValueKey('global_menu_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('global_menu_drawer')), findsOneWidget);
    expect(find.byKey(const ValueKey('global_menu_item_read')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('global_menu_item_learn')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('global_menu_item_my_quran')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('global_menu_item_quran_radio')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('global_menu_item_reciters')),
      findsOneWidget,
    );
  });

  testWidgets('menu destinations navigate to expected routes', (tester) async {
    final fakeStore = _FakeAppPreferencesStore();
    final container = _createContainer(fakeStore);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HifzPlannerApp(),
      ),
    );
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('today_screen_root')),
    );

    Future<void> openMenu() async {
      await tester.tap(find.byKey(const ValueKey('global_menu_button')));
      await tester.pumpAndSettle();
    }

    await openMenu();
    await tester.tap(find.byKey(const ValueKey('global_menu_item_my_quran')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('my_quran_screen_root')), findsOneWidget);

    await openMenu();
    await tester
        .tap(find.byKey(const ValueKey('global_menu_item_quran_radio')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('quran_radio_screen_root')),
      findsOneWidget,
    );

    await openMenu();
    await tester.tap(find.byKey(const ValueKey('global_menu_item_reciters')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reciters_screen_root')), findsOneWidget);

    await openMenu();
    await tester.tap(find.byKey(const ValueKey('global_menu_item_read')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader_view_toggle')), findsOneWidget);
  });

  testWidgets('narrow shell app bar title matches menu destinations',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(720, 900));

    final fakeStore = _FakeAppPreferencesStore();
    final container = _createContainer(fakeStore);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HifzPlannerApp(),
      ),
    );
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('today_screen_root')),
    );

    Future<void> openMenu() async {
      await tester.tap(find.byKey(const ValueKey('global_menu_button')));
      await tester.pumpAndSettle();
    }

    await openMenu();
    await tester.tap(find.byKey(const ValueKey('global_menu_item_learn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('learn_screen_root')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Learn'),
      ),
      findsOneWidget,
    );

    await openMenu();
    await tester.tap(find.byKey(const ValueKey('global_menu_item_my_quran')));
    await tester.pumpAndSettle();
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('my_quran_screen_root')),
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('My Quran'),
      ),
      findsOneWidget,
    );

    await openMenu();
    await tester.tap(find.byKey(const ValueKey('global_menu_item_reciters')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reciters_screen_root')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Reciters'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Learn menu route opens Learn screen and Hifz Plan',
      (tester) async {
    final fakeStore = _FakeAppPreferencesStore();
    final container = _createContainer(fakeStore);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HifzPlannerApp(),
      ),
    );
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('today_screen_root')),
    );

    await tester.tap(find.byKey(const ValueKey('global_menu_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('global_menu_item_learn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('learn_screen_root')), findsOneWidget);
    expect(find.byKey(const ValueKey('learn_hifz_plan_card')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('learn_hifz_plan_open')));
    await tester.pumpAndSettle();

    expect(find.text('Suggested Plan (Editable)'), findsOneWidget);
  });

  testWidgets('language selector shows four options and updates state',
      (tester) async {
    final fakeStore = _FakeAppPreferencesStore();
    final container = _createContainer(fakeStore);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HifzPlannerApp(),
      ),
    );
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('today_screen_root')),
    );

    await tester.tap(find.byKey(const ValueKey('global_menu_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('global_menu_language_button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('global_menu_language_option_en')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('global_menu_language_option_fr')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('global_menu_language_option_ar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('global_menu_language_option_pt')),
      findsOneWidget,
    );

    await tester
        .tap(find.byKey(const ValueKey('global_menu_language_option_fr')));
    await tester.pumpAndSettle();

    final prefs = container.read(appPreferencesProvider);
    expect(prefs.language.code, 'fr');
    expect(fakeStore.savedLanguageCode, 'fr');
  });

  testWidgets('rail labels update when language changes', (tester) async {
    final fakeStore = _FakeAppPreferencesStore();
    final container = _createContainer(fakeStore);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HifzPlannerApp(),
      ),
    );
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('today_screen_root')),
    );

    expect(find.text('Reader'), findsOneWidget);

    Future<void> ensureMenuOpen() async {
      if (find.byKey(const ValueKey('global_menu_drawer')).evaluate().isEmpty) {
        await tester.tap(
          find.byKey(const ValueKey('global_menu_button')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
      }
    }

    await ensureMenuOpen();
    await tester.tap(find.byKey(const ValueKey('global_menu_language_button')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('global_menu_language_option_fr')));
    await tester.pumpAndSettle();

    expect(find.text('Lecteur'), findsOneWidget);
    expect(find.text('Signets'), findsOneWidget);

    await ensureMenuOpen();
    await tester.tap(find.byKey(const ValueKey('global_menu_language_button')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('global_menu_language_option_ar')));
    await tester.pumpAndSettle();

    expect(find.text('القارئ'), findsOneWidget);
    expect(find.text('العلامات'), findsOneWidget);
  });

  testWidgets('theme selector shows sepia and dark and applies dark mode',
      (tester) async {
    final fakeStore = _FakeAppPreferencesStore();
    final container = _createContainer(fakeStore);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HifzPlannerApp(),
      ),
    );
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('today_screen_root')),
    );

    await tester.tap(find.byKey(const ValueKey('global_menu_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('global_menu_theme_button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('global_menu_theme_option_sepia')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('global_menu_theme_option_dark')),
      findsOneWidget,
    );

    await tester
        .tap(find.byKey(const ValueKey('global_menu_theme_option_dark')));
    await tester.pumpAndSettle();

    final prefs = container.read(appPreferencesProvider);
    expect(prefs.theme, AppThemeChoice.dark);
    expect(fakeStore.savedThemeCode, AppThemeChoice.dark.code);

    final railElement = tester.element(find.byType(NavigationRail));
    expect(Theme.of(railElement).brightness, Brightness.dark);
  });

  testWidgets('reader settings open hides global menu button', (tester) async {
    final fakeStore = _FakeAppPreferencesStore();
    final container = _createContainer(fakeStore);
    addTearDown(container.dispose);
    await _seedReaderAyahs(container.read(appDatabaseProvider));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HifzPlannerApp(),
      ),
    );
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('today_screen_root')),
    );

    await tester.tap(find.byKey(const ValueKey('global_menu_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('global_menu_item_read')));
    await tester.pumpAndSettle();
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('reader_verse_settings_button')),
    );

    expect(find.byKey(const ValueKey('global_menu_button')), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('reader_verse_settings_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('global_menu_button')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('reader_mushaf_settings_done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('global_menu_button')), findsOneWidget);
  });

  testWidgets('reader top-right controls do not overlap global menu',
      (tester) async {
    final fakeStore = _FakeAppPreferencesStore();
    final container = _createContainer(fakeStore);
    addTearDown(container.dispose);
    await _seedReaderAyahs(container.read(appDatabaseProvider));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HifzPlannerApp(),
      ),
    );
    await tester.pump();
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('today_screen_root')),
    );

    await tester.tap(find.byKey(const ValueKey('global_menu_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('global_menu_item_read')));
    await tester.pumpAndSettle();
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('reader_verse_settings_button')),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('global_menu_button')),
    );

    final menuRect =
        tester.getRect(find.byKey(const ValueKey('global_menu_button')));
    final readerSettingsRect = tester
        .getRect(find.byKey(const ValueKey('reader_verse_settings_button')));
    expect(menuRect.overlaps(readerSettingsRect), isFalse);
  });
}

Future<void> _seedReaderAyahs(AppDatabase db) async {
  await db.batch((batch) {
    batch.insertAll(
      db.ayah,
      [
        AyahCompanion.insert(
          surah: 1,
          ayah: 1,
          textUthmani: 'ٱلْحَمْدُ لِلَّٰهِ',
        ),
        AyahCompanion.insert(
          surah: 1,
          ayah: 2,
          textUthmani: 'رَبِّ ٱلْعَٰلَمِينَ',
        ),
      ],
    );
  });
}

ProviderContainer _createContainer(_FakeAppPreferencesStore fakeStore) {
  final db = AppDatabase(NativeDatabase.memory());
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith((ref) {
        ref.onDispose(db.close);
        return db;
      }),
      appPreferencesStoreProvider.overrideWithValue(fakeStore),
    ],
  );
}

class _FakeAppPreferencesStore implements AppPreferencesStore {
  _FakeAppPreferencesStore({
    StoredAppPreferences? initial,
  }) : _stored = initial ?? const StoredAppPreferences();

  StoredAppPreferences _stored;
  String? savedLanguageCode;
  String? savedThemeCode;
  bool? savedCompanionAutoReciteEnabled;

  @override
  Future<StoredAppPreferences> load() async {
    return _stored;
  }

  @override
  Future<void> saveLanguageCode(String code) async {
    savedLanguageCode = code;
    _stored = StoredAppPreferences(
      languageCode: code,
      themeCode: _stored.themeCode,
      companionAutoReciteEnabled: _stored.companionAutoReciteEnabled,
    );
  }

  @override
  Future<void> saveThemeCode(String code) async {
    savedThemeCode = code;
    _stored = StoredAppPreferences(
      languageCode: _stored.languageCode,
      themeCode: code,
      companionAutoReciteEnabled: _stored.companionAutoReciteEnabled,
    );
  }

  @override
  Future<void> saveCompanionAutoReciteEnabled(bool value) async {
    savedCompanionAutoReciteEnabled = value;
    _stored = StoredAppPreferences(
      languageCode: _stored.languageCode,
      themeCode: _stored.themeCode,
      companionAutoReciteEnabled: value,
    );
  }
}
