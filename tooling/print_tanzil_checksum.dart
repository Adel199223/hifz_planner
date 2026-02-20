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
  final checksum = sha256HexFromBytes(bytes);

  stdout.writeln('Asset: $tanzilUthmaniAssetPath');
  stdout.writeln('SHA-256: $checksum');
  stdout.writeln(
    "Paste into code: const String expectedTanzilUthmaniSha256 = '$checksum';",
  );
}
