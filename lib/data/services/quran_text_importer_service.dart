import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../database/app_database.dart';
import 'tanzil_text_integrity_guard.dart';

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
      final companions = [
        for (final row in chunk)
          AyahCompanion.insert(
            surah: row.surah,
            ayah: row.ayah,
            textUthmani: row.text,
            pageMadina: const Value.absent(),
          ),
      ];

      await _db.batch((batch) {
        batch.insertAll(
          _db.ayah,
          companions,
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

  List<TanzilLineRecord> _parseTanzilLines(String rawText) =>
      parseTanzilText(rawText);

  void _emitProgress(
    QuranTextImportProgressCallback? onProgress,
    QuranTextImportProgress progress,
  ) {
    onProgress?.call(progress);
  }
}
