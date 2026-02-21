import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'madani_page_index_service.dart';

const String tanzilPageMetadataAssetPath = madaniPageIndexAssetPath;

typedef PageMetadataImportProgressCallback = void Function(
  PageMetadataImportProgress progress,
);

typedef _PageIndexLoader = Future<Map<String, int>> Function(String assetPath);

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
    Future<Map<String, int>> Function(String assetPath)? loadPageIndex,
  }) : _loadPageIndex = loadPageIndex ?? ((_) => loadMadaniPageIndex());

  final AppDatabase _db;
  final _PageIndexLoader _loadPageIndex;

  Future<PageMetadataImportResult> importFromAsset({
    String assetPath = tanzilPageMetadataAssetPath,
    int batchSize = 500,
    PageMetadataImportProgressCallback? onProgress,
  }) async {
    if (batchSize <= 0) {
      throw ArgumentError.value(
        batchSize,
        'batchSize',
        'Must be greater than 0',
      );
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

    final pageIndex = await _loadPageIndex(assetPath);
    final parsedRows = pageIndex.length;

    _emitProgress(
      onProgress,
      PageMetadataImportProgress(
        processed: 0,
        total: parsedRows,
        phase: PageMetadataImportProgress.phaseParsing,
        message: 'Parsing page metadata...',
      ),
    );

    final records = _recordsFromPageIndex(pageIndex);

    final ayahs = await _db.select(_db.ayah).get();
    final ayahByKey = <String, AyahData>{
      for (final ayah in ayahs) verseKey(ayah.surah, ayah.ayah): ayah,
    };

    var matchedRows = 0;
    var unchangedRows = 0;
    var missingRows = 0;
    final pendingUpdates = <_PendingPageUpdate>[];

    for (final record in records) {
      final key = verseKey(record.surah, record.ayah);
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

  List<_PageMetadataRow> _recordsFromPageIndex(Map<String, int> pageIndex) {
    final rows = <_PageMetadataRow>[];
    for (final entry in pageIndex.entries) {
      final keyParts = entry.key.split(':');
      if (keyParts.length != 2) {
        throw FormatException('Invalid verse key format: "${entry.key}".');
      }

      final surah = int.tryParse(keyParts[0]);
      final ayah = int.tryParse(keyParts[1]);
      if (surah == null || ayah == null || surah < 1 || ayah < 1) {
        throw FormatException('Invalid verse key values: "${entry.key}".');
      }

      rows.add(
        _PageMetadataRow(
          surah: surah,
          ayah: ayah,
          pageMadina: entry.value,
        ),
      );
    }
    return rows;
  }

  void _emitProgress(
    PageMetadataImportProgressCallback? onProgress,
    PageMetadataImportProgress progress,
  ) {
    onProgress?.call(progress);
  }
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
