import 'dart:convert';
import 'dart:io';

import 'package:hifz_planner/data/services/tanzil_text_integrity_guard.dart';

Future<void> main() async {
  final file = File(tanzilUthmaniAssetPath);
  if (!await file.exists()) {
    stderr.writeln('Asset not found: $tanzilUthmaniAssetPath');
    exitCode = 1;
    return;
  }

  final bytes = await file.readAsBytes();
  final rawText = utf8.decode(bytes);
  final checksum = sha256HexFromBytes(bytes);
  final rows = parseTanzilText(rawText);
  final ayahCount = rows.length;
  final surahCount = rows.map((row) => row.surah).toSet().length;
  final keys = rows.map((row) => '${row.surah}:${row.ayah}').toSet();
  final hasFirstAyah = keys.contains('1:1');
  final hasLastAyah = keys.contains('114:6');

  stdout.writeln('Asset: $tanzilUthmaniAssetPath');
  stdout.writeln('SHA-256: $checksum');
  stdout.writeln('Ayah count: $ayahCount');
  stdout.writeln('Surah count: $surahCount');
  stdout.writeln('Has 1:1: $hasFirstAyah');
  stdout.writeln('Has 114:6: $hasLastAyah');
  stdout.writeln(
    "Paste into code: const String expectedTanzilUthmaniSha256 = '$checksum';",
  );
  stdout.writeln(
    'Paste into code: const int expectedTanzilUthmaniAyahCount = $ayahCount; '
    '// REPLACE_ME_COUNT',
  );
}
