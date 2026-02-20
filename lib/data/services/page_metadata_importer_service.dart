import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../database/app_database.dart';

const String tanzilPageMetadataAssetPath = 'assets/quran/tanzil_page_metadata.csv';

typedef PageMetadataImportProgressCallback = void Function(
  PageMetadataImportProgress progress,
);

typedef _AssetTextLoader = Future<String> Function(String assetPath);

class PageMetadataImportProgress {
  const PageMetadataImportProgress({
    required this.processed,
    required this.total,
    required this.phase,
    required this.message,
  });

  static const String phaseLoading = 'loading';
  static const String phaseParsing = 'parsing';
  static const String phaseUpdating = 'updating';
  static const String phaseCompleted = 'completed';

  final int processed;
  final int total;
  final String phase;
  final String message;

  double get fraction => total <= 0 ? 0 : processed / total;
}

class PageMetadataImportResult {
  const PageMetadataImportResult({
    required this.parsedRows,
    required this.matchedRows,
    required this.updatedRows,
    required this.unchangedRows,
    required this.missingRows,
  });

  final int parsedRows;
  final int matchedRows;
  final int updatedRows;
  final int unchangedRows;
  final int missingRows;
}

class PageMetadataImporterService {
  PageMetadataImporterService(
    this._db, {
    Future<String> Function(String assetPath)? loadAssetText,
  }) : _loadAssetText = loadAssetText ?? rootBundle.loadString;

  final AppDatabase _db;
  final _AssetTextLoader _loadAssetText;

  Future<PageMetadataImportResult> importFromAsset({
    String assetPath = tanzilPageMetadataAssetPath,
    int batchSize = 500,
    PageMetadataImportProgressCallback? onProgress,
  }) async {
    if (batchSize <= 0) {
      throw ArgumentError.value(batchSize, 'batchSize', 'Must be greater than 0');
    }

    _emitProgress(
      onProgress,
      const PageMetadataImportProgress(
        processed: 0,
        total: 0,
        phase: PageMetadataImportProgress.phaseLoading,
        message: 'Loading page metadata file...',
      ),
    );

    final rawText = await _loadAssetText(assetPath);

    _emitProgress(
      onProgress,
      const PageMetadataImportProgress(
        processed: 0,
        total: 0,
        phase: PageMetadataImportProgress.phaseParsing,
        message: 'Parsing page metadata...',
      ),
    );

    final parsed = _parseMetadataCsv(rawText);
    final parsedRows = parsed.parsedRows;
    final records = parsed.rowsByAyah.values.toList(growable: false);

    final ayahs = await _db.select(_db.ayah).get();
    final ayahByKey = <String, AyahData>{
      for (final ayah in ayahs) '${ayah.surah}:${ayah.ayah}': ayah,
    };

    var matchedRows = 0;
    var unchangedRows = 0;
    var missingRows = 0;
    final pendingUpdates = <_PendingPageUpdate>[];

    for (final record in records) {
      final key = '${record.surah}:${record.ayah}';
      final existing = ayahByKey[key];
      if (existing == null) {
        missingRows += 1;
        continue;
      }

      matchedRows += 1;
      if (existing.pageMadina == record.pageMadina) {
        unchangedRows += 1;
        continue;
      }

      pendingUpdates.add(
        _PendingPageUpdate(
          id: existing.id,
          pageMadina: record.pageMadina,
        ),
      );
    }

    _emitProgress(
      onProgress,
      PageMetadataImportProgress(
        processed: 0,
        total: pendingUpdates.length,
        phase: PageMetadataImportProgress.phaseUpdating,
        message: 'Updating page metadata...',
      ),
    );

    await _db.transaction(() async {
      var processed = 0;
      for (var start = 0; start < pendingUpdates.length; start += batchSize) {
        final end = (start + batchSize < pendingUpdates.length)
            ? start + batchSize
            : pendingUpdates.length;
        final chunk = pendingUpdates.sublist(start, end);

        await _db.batch((batch) {
          for (final update in chunk) {
            batch.update(
              _db.ayah,
              AyahCompanion(
                pageMadina: Value(update.pageMadina),
              ),
              where: (tbl) => tbl.id.equals(update.id),
            );
          }
        });

        processed = end;
        _emitProgress(
          onProgress,
          PageMetadataImportProgress(
            processed: processed,
            total: pendingUpdates.length,
            phase: PageMetadataImportProgress.phaseUpdating,
            message: 'Updated $processed of ${pendingUpdates.length} rows...',
          ),
        );
      }
    });

    _emitProgress(
      onProgress,
      PageMetadataImportProgress(
        processed: pendingUpdates.length,
        total: pendingUpdates.length,
        phase: PageMetadataImportProgress.phaseCompleted,
        message: 'Page metadata import completed.',
      ),
    );

    return PageMetadataImportResult(
      parsedRows: parsedRows,
      matchedRows: matchedRows,
      updatedRows: pendingUpdates.length,
      unchangedRows: unchangedRows,
      missingRows: missingRows,
    );
  }

  _ParsedPageMetadataCsv _parseMetadataCsv(String rawText) {
    final lines = const LineSplitter().convert(rawText);
    final rowsByAyah = <String, _PageMetadataRow>{};
    var parsedRows = 0;

    for (var index = 0; index < lines.length; index++) {
      var line = lines[index];
      final lineNumber = index + 1;

      if (index == 0 && line.startsWith('\ufeff')) {
        line = line.substring(1);
      }

      if (line.trim().isEmpty) {
        continue;
      }

      final normalized = line.trim().toLowerCase().replaceAll(' ', '');
      if (normalized == 'surah,ayah,page_madina') {
        continue;
      }

      final firstComma = line.indexOf(',');
      final secondComma = line.indexOf(',', firstComma + 1);

      if (firstComma <= 0 || secondComma <= firstComma + 1) {
        throw FormatException(
          'Invalid page metadata format at line $lineNumber. '
          'Expected surah,ayah,page_madina.',
        );
      }

      final surahText = line.substring(0, firstComma).trim();
      final ayahText = line.substring(firstComma + 1, secondComma).trim();
      final pageText = line.substring(secondComma + 1).trim();

      final surah = int.tryParse(surahText);
      final ayah = int.tryParse(ayahText);
      final pageMadina = int.tryParse(pageText);

      if (surah == null || ayah == null || pageMadina == null) {
        throw FormatException(
          'Invalid numeric values at line $lineNumber.',
        );
      }
      if (surah <= 0 || ayah <= 0 || pageMadina <= 0) {
        throw FormatException(
          'Values must be positive integers at line $lineNumber.',
        );
      }

      parsedRows += 1;
      rowsByAyah['$surah:$ayah'] = _PageMetadataRow(
        surah: surah,
        ayah: ayah,
        pageMadina: pageMadina,
      );
    }

    return _ParsedPageMetadataCsv(
      parsedRows: parsedRows,
      rowsByAyah: rowsByAyah,
    );
  }

  void _emitProgress(
    PageMetadataImportProgressCallback? onProgress,
    PageMetadataImportProgress progress,
  ) {
    onProgress?.call(progress);
  }
}

class _ParsedPageMetadataCsv {
  const _ParsedPageMetadataCsv({
    required this.parsedRows,
    required this.rowsByAyah,
  });

  final int parsedRows;
  final Map<String, _PageMetadataRow> rowsByAyah;
}

class _PageMetadataRow {
  const _PageMetadataRow({
    required this.surah,
    required this.ayah,
    required this.pageMadina,
  });

  final int surah;
  final int ayah;
  final int pageMadina;
}

class _PendingPageUpdate {
  const _PendingPageUpdate({
    required this.id,
    required this.pageMadina,
  });

  final int id;
  final int pageMadina;
}
