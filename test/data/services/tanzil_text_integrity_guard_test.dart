import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/data/services/tanzil_text_integrity_guard.dart';
import 'package:hifz_planner/data/models/tanzil_line_record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final hasRealAsset = File(tanzilUthmaniAssetPath).existsSync();
  const missingAssetSkipReason =
      'Tanzil asset file is not present locally at assets/quran/tanzil_uthmani.txt.';

  late List<TanzilLineRecord> parsedRows;
  late Set<String> ayahKeys;
  late Set<int> surahNumbers;
  late bool duplicateFound;

  setUpAll(() async {
    if (!hasRealAsset) {
      return;
    }

    final raw = await rootBundle.loadString(tanzilUthmaniAssetPath);
    parsedRows = parseTanzilText(raw);

    ayahKeys = <String>{};
    surahNumbers = <int>{};
    duplicateFound = false;

    for (final row in parsedRows) {
      final key = '${row.surah}:${row.ayah}';
      surahNumbers.add(row.surah);
      if (!ayahKeys.add(key)) {
        duplicateFound = true;
      }
    }
  });

  test('checksum matches expected constant', () async {
    final actual = await computeAssetSha256();
    expect(actual, expectedTanzilUthmaniSha256);
  }, skip: hasRealAsset ? false : missingAssetSkipReason);

  test('parsed ayah count matches expected constant', () {
    expect(parsedRows.length, expectedTanzilUthmaniAyahCount);
  }, skip: hasRealAsset ? false : missingAssetSkipReason);

  test('parsed surah count equals 114', () {
    expect(surahNumbers.length, 114);
  }, skip: hasRealAsset ? false : missingAssetSkipReason);

  test('first and last ayah keys exist', () {
    expect(ayahKeys.contains('1:1'), isTrue);
    expect(ayahKeys.contains('114:6'), isTrue);
  }, skip: hasRealAsset ? false : missingAssetSkipReason);

  test('parsed content has no duplicate surah/ayah keys', () {
    expect(duplicateFound, isFalse);
  }, skip: hasRealAsset ? false : missingAssetSkipReason);

  test('parseTanzilText throws FormatException on malformed line', () {
  expect(
    () => parseTanzilText('1|1|ok\nهذا_سطر_عربي_غير_صحيح\n'),
    throwsA(isA<FormatException>()),
  );
});
}
