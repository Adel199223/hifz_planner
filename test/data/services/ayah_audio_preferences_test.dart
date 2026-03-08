import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/ayah_audio_preferences.dart';

void main() {
  test('load reports audio preference failures and returns defaults', () async {
    final operations = <String>[];
    final store = SharedPrefsAyahAudioPreferencesStore(
      loadPreferences: () => Future<Never>.error(
        StateError('prefs unavailable'),
        StackTrace.empty,
      ),
      reportError: (operation, error, stackTrace) {
        operations.add(operation);
      },
    );

    final stored = await store.load();

    expect(stored.edition, isNull);
    expect(stored.bitrate, isNull);
    expect(stored.speed, isNull);
    expect(stored.repeatCount, isNull);
    expect(stored.reciterDisplayName, isNull);
    expect(operations, <String>['load reader audio preferences']);
  });

  test('save reports audio preference failures without throwing', () async {
    final operations = <String>[];
    final store = SharedPrefsAyahAudioPreferencesStore(
      loadPreferences: () => Future<Never>.error(
        StateError('prefs unavailable'),
        StackTrace.empty,
      ),
      reportError: (operation, error, stackTrace) {
        operations.add(operation);
      },
    );

    await store.saveEdition('ar.hudhaify');
    await store.saveBitrate(64);
    await store.saveSpeed(1.25);
    await store.saveRepeatCount(2);
    await store.saveReciterDisplayName('Hudhaify');

    expect(operations, <String>[
      'save reader audio edition',
      'save reader audio bitrate',
      'save reader audio speed',
      'save reader audio repeat count',
      'save reader audio reciter display name',
    ]);
  });
}
