import '../models/tanzil_line_record.dart';

final RegExp _ayahLine = RegExp(r'^\s*(\d{1,3})\|(\d{1,3})\|(.*)$');
final RegExp _hasArabic = RegExp(r'[\u0600-\u06FF]');

List<TanzilLineRecord> parseTanzilText(String raw) {
  var normalized = raw.replaceAll('\uFEFF', '');
  final lines = normalized.split(RegExp(r'\r?\n'));
  final result = <TanzilLineRecord>[];

  for (var i = 0; i < lines.length; i++) {
    final lineNo = i + 1;
    final line = lines[i].trimRight();

    if (line.trim().isEmpty) {
      continue;
    }

    final match = _ayahLine.firstMatch(line);
    if (match == null) {
      if (!_hasArabic.hasMatch(line)) {
        continue;
      }

      throw FormatException(
        'Invalid Tanzil format at line $lineNo. Expected sura|ayah|text.',
      );
    }

    final surah = int.parse(match.group(1)!);
    final ayah = int.parse(match.group(2)!);
    final text = match.group(3)!;

    if (surah < 1 || surah > 114 || ayah < 1) {
      throw FormatException(
        'Invalid surah/ayah numbers at line $lineNo: $surah|$ayah',
      );
    }

    result.add(TanzilLineRecord(surah: surah, ayah: ayah, text: text));
  }

  return result;
}
