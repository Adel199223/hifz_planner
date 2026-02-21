import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../models/tanzil_line_record.dart';
import 'package:hifz_planner/data/models/tanzil_line_record.dart';

const String tanzilUthmaniAssetPath = 'assets/quran/tanzil_uthmani.txt';

// Replace these after running tooling\inspect_tanzil_text.py
const String expectedTanzilUthmaniSha256 =
    '7f30c647331a61100ebf24a80507dc0fcdd9f2df97f1312b5b2dfcb982a7f326';
const int expectedTanzilUthmaniAyahCount = 6236;

final RegExp _ayahLine = RegExp(r'^\s*(\d{1,3})\|(\d{1,3})\|(.*)$');
final RegExp _hasArabic = RegExp(r'[\u0600-\u06FF]'); // Arabic Unicode block

Future<String> computeAssetSha256({String assetPath = tanzilUthmaniAssetPath}) async {
  final data = await rootBundle.load(assetPath);
  final bytes = data.buffer.asUint8List();
  return sha256.convert(bytes).toString();
}

List<TanzilLineRecord> parseTanzilText(String raw) {
  // Strip UTF-8 BOM if present
  raw = raw.replaceAll('\uFEFF', '');

  final lines = raw.split(RegExp(r'\r?\n'));
  final result = <TanzilLineRecord>[];

  for (var i = 0; i < lines.length; i++) {
    final lineNo = i + 1;
    final line = lines[i].trimRight();

    if (line.trim().isEmpty) continue;

    final m = _ayahLine.firstMatch(line);
    if (m == null) {
      // Skip ONLY non-ayah informational/footer lines that contain NO Arabic letters.
      if (!_hasArabic.hasMatch(line)) continue;

      // If Arabic exists but format is wrong, fail hard (do not silently ignore).
      throw FormatException(
        'Invalid Tanzil format at line $lineNo. Expected sura|ayah|text.',
      );
    }

    final surah = int.parse(m.group(1)!);
    final ayah = int.parse(m.group(2)!);
    final text = m.group(3)!;

    if (surah < 1 || surah > 114 || ayah < 1) {
      throw FormatException('Invalid surah/ayah numbers at line $lineNo: $surah|$ayah');
    }

    result.add(TanzilLineRecord(surah: surah, ayah: ayah, text: text));
  }

  return result;
}
