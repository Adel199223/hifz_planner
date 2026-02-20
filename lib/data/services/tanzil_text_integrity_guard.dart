import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

const String tanzilUthmaniAssetPath = 'assets/quran/tanzil_uthmani.txt';
const String expectedTanzilUthmaniSha256 = 'REPLACE_ME';

class TanzilLineRecord {
  const TanzilLineRecord({
    required this.surah,
    required this.ayah,
    required this.text,
  });

  final int surah;
  final int ayah;
  final String text;
}

String sha256HexFromBytes(List<int> bytes) {
  return sha256.convert(bytes).toString();
}

Future<String> computeAssetSha256({
  AssetBundle? bundle,
  String assetPath = tanzilUthmaniAssetPath,
}) async {
  final sourceBundle = bundle ?? rootBundle;
  final data = await sourceBundle.load(assetPath);
  final bytes = data.buffer.asUint8List(
    data.offsetInBytes,
    data.lengthInBytes,
  );
  return sha256HexFromBytes(bytes);
}

List<TanzilLineRecord> parseTanzilText(String rawText) {
  final lines = const LineSplitter().convert(rawText);
  final rows = <TanzilLineRecord>[];

  for (var index = 0; index < lines.length; index++) {
    var line = lines[index];
    final lineNumber = index + 1;

    if (index == 0 && line.startsWith('\ufeff')) {
      line = line.substring(1);
    }

    if (line.trim().isEmpty) {
      continue;
    }

    final firstPipe = line.indexOf('|');
    final secondPipe = line.indexOf('|', firstPipe + 1);

    if (firstPipe <= 0 || secondPipe <= firstPipe + 1) {
      throw FormatException(
        'Invalid Tanzil format at line $lineNumber. Expected sura|ayah|text.',
      );
    }

    final surahText = line.substring(0, firstPipe).trim();
    final ayahText = line.substring(firstPipe + 1, secondPipe).trim();
    final text = line.substring(secondPipe + 1);

    final surah = int.tryParse(surahText);
    final ayah = int.tryParse(ayahText);
    if (surah == null || ayah == null) {
      throw FormatException(
        'Invalid numeric surah/ayah at line $lineNumber.',
      );
    }

    rows.add(
      TanzilLineRecord(
        surah: surah,
        ayah: ayah,
        text: text,
      ),
    );
  }

  return rows;
}

int countParsedAyahs(String rawText) {
  return parseTanzilText(rawText).length;
}
