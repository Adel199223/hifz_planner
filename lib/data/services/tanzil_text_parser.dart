import '../models/tanzil_line_record.dart';

final RegExp _ayahLine = RegExp(r'^\s*(\d{1,3})\|(\d{1,3})\|(.*)$');
final RegExp _hasArabic = RegExp(r'[\u0600-\u06FF]');
final RegExp _formatCharsPattern = RegExp(r'[\u200C\u200D\uFEFF]');
final RegExp _strictRemovalsPattern = RegExp(
  r'[\u0640\u064B-\u065F\u0670\u06D6-\u06ED]',
);
final RegExp _looseExtraRemovalsPattern =
    RegExp(r'[\u0610-\u061A\u08D3-\u08FF]');
final RegExp _generalCombiningMarksPattern = RegExp(
  r'[\u0300-\u036F\u1AB0-\u1AFF\u1DC0-\u1DFF\u20D0-\u20FF\uFE20-\uFE2F]',
);

const String tanzilBasmala = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';

List<TanzilLineRecord> parseTanzilText(String raw) {
  final normalized = raw.replaceAll('\uFEFF', '');
  final lines = normalized.split(RegExp(r'\r?\n'));
  final parsedRows = <_ParsedTanzilRow>[];

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

    parsedRows.add(
      _ParsedTanzilRow(
        surah: surah,
        ayah: ayah,
        text: text,
      ),
    );
  }

  final rowsBySurah = <int, List<_ParsedTanzilRow>>{};
  for (final row in parsedRows) {
    rowsBySurah.putIfAbsent(row.surah, () => <_ParsedTanzilRow>[]).add(row);
  }

  final result = <TanzilLineRecord>[];
  for (var surah = 1; surah <= 114; surah++) {
    final surahRows = rowsBySurah[surah];
    if (surahRows == null || surahRows.isEmpty) {
      continue;
    }
    result.addAll(_canonicalizeSurahRows(surah, surahRows));
  }

  return result;
}

List<TanzilLineRecord> _canonicalizeSurahRows(
  int surah,
  List<_ParsedTanzilRow> rows,
) {
  if (rows.isEmpty) {
    return const <TanzilLineRecord>[];
  }

  final shouldHandleBasmala = surah > 1 && surah != 9;
  if (!shouldHandleBasmala) {
    return [
      for (final row in rows)
        TanzilLineRecord(
          surah: row.surah,
          ayah: row.ayah,
          text: row.text,
        ),
    ];
  }

  final firstText = rows.first.text.trim();
  final firstIsStandaloneBasmala = firstText == tanzilBasmala ||
      normalizeForCompareLoose(firstText) ==
          normalizeForCompareLoose(tanzilBasmala);
  if (firstIsStandaloneBasmala) {
    final shifted = rows.skip(1).toList(growable: false);
    return [
      for (var i = 0; i < shifted.length; i++)
        TanzilLineRecord(
          surah: surah,
          ayah: i + 1,
          text: shifted[i].text,
        ),
    ];
  }

  if (firstText.startsWith(tanzilBasmala)) {
    final remainder = firstText.substring(tanzilBasmala.length).trimLeft();
    if (remainder.isNotEmpty) {
      return [
        TanzilLineRecord(
          surah: surah,
          ayah: 1,
          text: remainder,
        ),
        for (var i = 1; i < rows.length; i++)
          TanzilLineRecord(
            surah: surah,
            ayah: i + 1,
            text: rows[i].text,
          ),
      ];
    }
  }

  return [
    for (final row in rows)
      TanzilLineRecord(
        surah: row.surah,
        ayah: row.ayah,
        text: row.text,
      ),
  ];
}

String normalizeForCompare(String input) {
  // Dart core doesn't provide NFC normalization without extra packages.
  var normalized = input;
  normalized = normalized.replaceAll(_formatCharsPattern, '');
  normalized = normalized.replaceAll(_strictRemovalsPattern, '');
  normalized = normalized.replaceAll('\u00A0', ' ');
  normalized = normalized
      .replaceAll('ٱ', 'ا')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ا')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي');
  normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  return normalized;
}

String normalizeForCompareLoose(String input) {
  var normalized = normalizeForCompare(input);
  normalized = normalized.replaceAll(_looseExtraRemovalsPattern, '');
  normalized = normalized.replaceAll(_generalCombiningMarksPattern, '');
  normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  return normalized;
}

class _ParsedTanzilRow {
  const _ParsedTanzilRow({
    required this.surah,
    required this.ayah,
    required this.text,
  });

  final int surah;
  final int ayah;
  final String text;
}
