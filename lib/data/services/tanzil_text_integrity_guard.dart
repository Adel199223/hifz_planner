import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../models/tanzil_line_record.dart';
import 'tanzil_text_parser.dart' as tanzil_parser;

const String tanzilUthmaniAssetPath = 'assets/quran/tanzil_uthmani.txt';

// Replace these after running tooling\inspect_tanzil_text.py
const String expectedTanzilUthmaniSha256 =
    '7f30c647331a61100ebf24a80507dc0fcdd9f2df97f1312b5b2dfcb982a7f326';
const int expectedTanzilUthmaniAyahCount = 6236;

Future<String> computeAssetSha256(
    {String assetPath = tanzilUthmaniAssetPath}) async {
  final data = await rootBundle.load(assetPath);
  final bytes = data.buffer.asUint8List();
  return sha256.convert(bytes).toString();
}

List<TanzilLineRecord> parseTanzilText(String raw) =>
    tanzil_parser.parseTanzilText(raw);
