import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hifz_planner/app/app_preferences_store.dart';
import 'package:hifz_planner/app/app_preferences.dart';
import 'package:hifz_planner/screens/about_screen.dart';

void main() {
  testWidgets('about screen renders overview sections and current setup',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        appPreferencesStoreProvider.overrideWithValue(
          _FakeAppPreferencesStore(
            initial: const StoredAppPreferences(
              themeCode: 'dark',
              companionAutoReciteEnabled: true,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('about_screen_root')), findsOneWidget);
    expect(find.byKey(const ValueKey('about_quick_actions_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('about_setup_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('about_workflow_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('about_reliability_card')), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Autoplay on'), findsOneWidget);
  });

  testWidgets('about quick actions navigate to core routes', (tester) async {
    final container = ProviderContainer(
      overrides: [
        appPreferencesStoreProvider.overrideWithValue(_FakeAppPreferencesStore()),
      ],
    );
    addTearDown(container.dispose);

    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('about_action_reader')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('about_test_reader_route')), findsOneWidget);

    router.go('/about');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('about_action_settings')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('about_test_settings_route')),
      findsOneWidget,
    );
  });

  testWidgets('about licenses button opens Flutter license page',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        appPreferencesStoreProvider.overrideWithValue(_FakeAppPreferencesStore()),
      ],
    );
    addTearDown(container.dispose);

    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('about_view_licenses_button')),
    );
    await tester.tap(find.byKey(const ValueKey('about_view_licenses_button')));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
    expect(find.text('Hifz Planner'), findsWidgets);
  });
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/about',
    routes: [
      GoRoute(
        path: '/about',
        builder: (context, state) => const Scaffold(body: AboutScreen()),
      ),
      GoRoute(
        path: '/reader',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text(
              'Reader Route',
              key: ValueKey('about_test_reader_route'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/today',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text(
              'Today Route',
              key: ValueKey('about_test_today_route'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/plan',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text(
              'Plan Route',
              key: ValueKey('about_test_plan_route'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/my-quran',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text(
              'My Quran Route',
              key: ValueKey('about_test_my_quran_route'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text(
              'Settings Route',
              key: ValueKey('about_test_settings_route'),
            ),
          ),
        ),
      ),
    ],
  );
}

class _FakeAppPreferencesStore implements AppPreferencesStore {
  _FakeAppPreferencesStore({
    StoredAppPreferences? initial,
  }) : _stored = initial ?? const StoredAppPreferences();

  StoredAppPreferences _stored;

  @override
  Future<StoredAppPreferences> load() async {
    return _stored;
  }

  @override
  Future<void> saveCompanionAutoReciteEnabled(bool value) async {
    _stored = StoredAppPreferences(
      languageCode: _stored.languageCode,
      themeCode: _stored.themeCode,
      companionAutoReciteEnabled: value,
    );
  }

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
}
