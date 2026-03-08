import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/app/app_preferences_store.dart';

void main() {
  test('load reports app preference failures and returns defaults', () async {
    final operations = <String>[];
    final store = SharedPrefsAppPreferencesStore(
      loadPreferences: () => Future<Never>.error(
        StateError('prefs unavailable'),
        StackTrace.empty,
      ),
      reportError: (operation, error, stackTrace) {
        operations.add(operation);
      },
    );

    final stored = await store.load();

    expect(stored.languageCode, isNull);
    expect(stored.themeCode, isNull);
    expect(stored.companionAutoReciteEnabled, isNull);
    expect(operations, <String>['load app preferences']);
  });

  test('save reports app preference failures without throwing', () async {
    final operations = <String>[];
    final store = SharedPrefsAppPreferencesStore(
      loadPreferences: () => Future<Never>.error(
        StateError('prefs unavailable'),
        StackTrace.empty,
      ),
      reportError: (operation, error, stackTrace) {
        operations.add(operation);
      },
    );

    await store.saveThemeCode('dark');
    await store.saveLanguageCode('fr');
    await store.saveCompanionAutoReciteEnabled(true);

    expect(operations, <String>[
      'save app theme code',
      'save app language code',
      'save companion auto-recite preference',
    ]);
  });
}
