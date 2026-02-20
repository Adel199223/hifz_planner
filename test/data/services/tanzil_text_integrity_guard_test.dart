import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/tanzil_text_integrity_guard.dart';

void main() {
  test('checksum matches expected constant', () async {
    final actual = await computeAssetSha256();
    expect(actual, expectedTanzilUthmaniSha256);
  });

  test('asset parses to more than 6000 ayahs', () async {
    final raw = await rootBundle.loadString(tanzilUthmaniAssetPath);
    final count = countParsedAyahs(raw);
    expect(count, greaterThan(6000));
  });

  test('parseTanzilText throws FormatException on malformed line', () {
    expect(
      () => parseTanzilText('1|1|ok\nbad-line\n'),
      throwsA(isA<FormatException>()),
    );
  });
}
