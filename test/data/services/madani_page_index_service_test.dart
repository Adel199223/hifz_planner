import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/madani_page_index_service.dart';

void main() {
  test('loadMadaniPageIndex loads valid JSON map', () async {
    final bundle = _StringAssetBundle(
      <String, String>{
        madaniPageIndexAssetPath: '{"1:1":1,"114:6":604}',
      },
    );

    final map = await loadMadaniPageIndex(bundle: bundle);

    expect(map['1:1'], 1);
    expect(map['114:6'], 604);
  });

  test('parseMadaniPageIndexJson rejects invalid verse keys', () {
    expect(
      () => parseMadaniPageIndexJson('{"foo":1}'),
      throwsA(isA<FormatException>()),
    );
  });

  test('parseMadaniPageIndexJson rejects out-of-range pages', () {
    expect(
      () => parseMadaniPageIndexJson('{"1:1":605}'),
      throwsA(isA<FormatException>()),
    );
  });

  test('debug validator enforces page bounds across provided verse keys', () {
    expect(
      () => debugValidateMadaniPageCoverage(
        pageIndex: const <String, int>{
          '1:1': 2,
          '114:6': 603,
        },
        appVerseKeys: const <String>['1:1', '114:6'],
      ),
      throwsA(isA<AssertionError>()),
    );
  });
}

class _StringAssetBundle extends CachingAssetBundle {
  _StringAssetBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<ByteData> load(String key) async {
    final value = _assets[key];
    if (value == null) {
      throw StateError('Asset not found: $key');
    }
    final bytes = Uint8List.fromList(utf8.encode(value));
    return ByteData.sublistView(bytes);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = _assets[key];
    if (value == null) {
      throw StateError('Asset not found: $key');
    }
    return value;
  }
}
