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
    );
  }

  @override
  Future<void> saveThemeCode(String code) async {
    savedThemeCode = code;
    _stored = StoredAppPreferences(
      languageCode: _stored.languageCode,
      themeCode: code,
    );
  }
}
