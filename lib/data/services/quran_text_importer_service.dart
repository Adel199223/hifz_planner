import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../database/app_database.dart';

typedef QuranTextImportProgressCallback = void Function(
  QuranTextImportProgress progress,
);

typedef _AssetTextLoader = Future<String> Function(String assetPath);

class QuranTextImportProgress {
  const QuranTextImportProgress({
    required this.processed,
    required this.total,
    required this.phase,
    required this.message,
  });

  static const String phaseLoading = 'loading';
  static const String phaseParsing = 'parsing';
  static const String phaseInserting = 'inserting';
  static const String phaseCompleted = 'completed';
  static const String phaseSkipped = 'skipped';

  final int processed;
  final int total;
  final String phase;
  final String message;

  double get fraction => total <= 0 ? 0 : processed / total;
}

class QuranTextImportResult {
  const QuranTextImportResult({
    required this.skipped,
    required this.existingBefore,
    required this.parsedRows,
    required this.insertedRows,
    required this.ignoredRows,
  });

  final bool skipped;
  final int existingBefore;
  final int parsedRows;
  final int insertedRows;
  final int ignoredRows;
}

class QuranTextImporterService {
  QuranTextImporterService(
    this._db, {
    Future<String> Function(String assetPath)? loadAssetText,
  }) : _loadAssetText = loadAssetText ?? rootBundle.loadString;

  final AppDatabase _db;
  final _AssetTextLoader _loadAssetText;

  Future<QuranTextImportResult> importFromAsset({
    String assetPath = 'assets/quran/tanzil_uthmani.txt',
    bool force = false,
    int batchSize = 500,
    QuranTextImportProgressCallback? onProgress,
  }) async {
    if (batchSize <= 0) {
      throw ArgumentError.value(batchSize, 'batchSize', 'Must be greater than 0');
    }

    final existingBefore = await _getAyahCount();
    if (existingBefore > 0 && !force) {
      _emitProgress(
        onProgress,
        const QuranTextImportProgress(
          processed: 0,
          total: 0,
          phase: QuranTextImportProgress.phaseSkipped,
          message: 'Import skipped: ayah table already has data.',
        ),
      );
      return QuranTextImportResult(
        skipped: true,
        existingBefore: existingBefore,
        parsedRows: 0,
        insertedRows: 0,
        ignoredRows: 0,
      );
    }

    _emitProgress(
      onProgress,
      const QuranTextImportProgress(
        processed: 0,
        total: 0,
        phase: QuranTextImportProgress.phaseLoading,
        message: 'Loading asset file...',
      ),
    );

    final rawText = await _loadAssetText(assetPath);

    _emitProgress(
      onProgress,
      const QuranTextImportProgress(
        processed: 0,
        total: 0,
        phase: QuranTextImportProgress.phaseParsing,
        message: 'Parsing lines...',
      ),
    );

    final rows = _parseTanzilLines(rawText);
    final parsedRows = rows.length;

    _emitProgress(
      onProgress,
      QuranTextImportProgress(
        processed: 0,
        total: parsedRows,
        phase: QuranTextImportProgress.phaseInserting,
        message: 'Inserting verses...',
      ),
    );

    var processed = 0;
    for (var start = 0; start < rows.length; start += batchSize) {
      final end = (start + batchSize < rows.length)
          ? start + batchSize
          : rows.length;
      final chunk = rows.sublist(start, end);

      await _db.batch((batch) {
        batch.insertAll(
          _db.ayah,
          chunk,
          mode: InsertMode.insertOrIgnore,
        );
      });

      processed = end;
      _emitProgress(
        onProgress,
        QuranTextImportProgress(
          processed: processed,
          total: parsedRows,
          phase: QuranTextImportProgress.phaseInserting,
          message: 'Inserted $processed of $parsedRows...',
        ),
      );
    }

    final finalCount = await _getAyahCount();
    final insertedRows = finalCount - existingBefore;
    final ignoredRows = parsedRows - insertedRows;

    _emitProgress(
      onProgress,
      QuranTextImportProgress(
        processed: parsedRows,
        total: parsedRows,
        phase: QuranTextImportProgress.phaseCompleted,
        message: 'Import completed.',
      ),
    );

    return QuranTextImportResult(
      skipped: false,
      existingBefore: existingBefore,
      parsedRows: parsedRows,
      insertedRows: insertedRows,
      ignoredRows: ignoredRows,
    );
  }

  Future<int> _getAyahCount() async {
    final row =
        await _db.customSelect('SELECT COUNT(*) AS c FROM ayah').getSingle();
    return row.read<int>('c');
  }

  List<AyahCompanion> _parseTanzilLines(String rawText) {
    final lines = const LineSplitter().convert(rawText);
    final rows = <AyahCompanion>[];

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
        AyahCompanion.insert(
          surah: surah,
          ayah: ayah,
          textUthmani: text,
          pageMadina: const Value.absent(),
        ),
      );
    }

    return rows;
  }

  void _emitProgress(
    QuranTextImportProgressCallback? onProgress,
    QuranTextImportProgress progress,
  ) {
    onProgress?.call(progress);
  }
}
