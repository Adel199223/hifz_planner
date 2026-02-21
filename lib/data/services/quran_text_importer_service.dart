import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../database/app_database.dart';
import 'madani_page_index_service.dart';
import '../models/tanzil_line_record.dart';
import 'tanzil_text_integrity_guard.dart'
    show expectedTanzilUthmaniAyahCount, parseTanzilText;

typedef QuranTextImportProgressCallback = void Function(
  QuranTextImportProgress progress,
);

typedef _AssetTextLoader = Future<String> Function(String assetPath);
typedef _PageIndexLoader = Future<Map<String, int>> Function();

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
    Future<Map<String, int>> Function()? loadPageIndex,
  })  : _loadAssetText = loadAssetText ?? rootBundle.loadString,
        _loadPageIndex = loadPageIndex ?? (() => loadMadaniPageIndex());

  final AppDatabase _db;
  final _AssetTextLoader _loadAssetText;
  final _PageIndexLoader _loadPageIndex;

  Future<QuranTextImportResult> importFromAsset({
    String assetPath = 'assets/quran/tanzil_uthmani.txt',
    bool force = false,
    int batchSize = 500,
    QuranTextImportProgressCallback? onProgress,
  }) async {
    if (batchSize <= 0) {
      throw ArgumentError.value(
          batchSize, 'batchSize', 'Must be greater than 0');
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
    final pageIndex = await _loadPageIndex();
    final mappedRows = _mapRowsToPages(
      rows: rows,
      pageIndex: pageIndex,
    );
    _debugAssertMappedRows(
      rows: rows,
      mappedRows: mappedRows,
      pageIndex: pageIndex,
    );

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
      final end = (start + batchSize < mappedRows.length)
          ? start + batchSize
          : mappedRows.length;
      final chunk = mappedRows.sublist(start, end);
      final companions = [
        for (final mapped in chunk)
          AyahCompanion.insert(
            surah: mapped.row.surah,
            ayah: mapped.row.ayah,
            textUthmani: mapped.row.text,
            pageMadina: Value(mapped.page),
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

  List<_MappedAyahRow> _mapRowsToPages({
    required List<TanzilLineRecord> rows,
    required Map<String, int> pageIndex,
  }) {
    final mappedRows = <_MappedAyahRow>[];
    for (final row in rows) {
      final key = verseKey(row.surah, row.ayah);
      final page = pageIndex[key];
      if (page == null) {
        throw StateError('Missing Madani page mapping for verse "$key".');
      }
      mappedRows.add(_MappedAyahRow(row: row, page: page));
    }
    return mappedRows;
  }

  void _debugAssertMappedRows({
    required List<TanzilLineRecord> rows,
    required List<_MappedAyahRow> mappedRows,
    required Map<String, int> pageIndex,
  }) {
    assert(() {
      if (mappedRows.length != rows.length) {
        throw AssertionError(
          'Mapped row count ${mappedRows.length} does not match parsed row count ${rows.length}.',
        );
      }

      final pages = mappedRows.map((item) => item.page).toList(growable: false);
      if (pages.any((page) => page < 1 || page > madaniPageCount)) {
        throw AssertionError(
            'Mapped rows include page outside 1..$madaniPageCount.');
      }

      if (rows.length == expectedTanzilUthmaniAyahCount) {
        final minPage = pages.reduce((a, b) => a < b ? a : b);
        final maxPage = pages.reduce((a, b) => a > b ? a : b);
        if (minPage != 1 || maxPage != madaniPageCount) {
          throw AssertionError(
            'Mapped page bounds are $minPage..$maxPage, expected 1..$madaniPageCount.',
          );
        }

        debugValidateMadaniPageCoverage(
          pageIndex: pageIndex,
          appVerseKeys: rows.map((row) => verseKey(row.surah, row.ayah)),
          expectedVerseCount: expectedTanzilUthmaniAyahCount,
        );
      }

      return true;
    }());
  }

  void _emitProgress(
    QuranTextImportProgressCallback? onProgress,
    QuranTextImportProgress progress,
  ) {
    onProgress?.call(progress);
  }
}

class _MappedAyahRow {
  const _MappedAyahRow({
    required this.row,
    required this.page,
  });

  final TanzilLineRecord row;
  final int page;
}
