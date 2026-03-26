import '../database/app_database.dart';

class QuranDataReadiness {
  const QuranDataReadiness({
    required this.totalAyahs,
    required this.pageMappedAyahs,
  });

  final int totalAyahs;
  final int pageMappedAyahs;

  bool get hasTextData => totalAyahs > 0;

  bool get hasPageMetadata {
    if (!hasTextData) {
      return false;
    }
    final nearCompleteThreshold = totalAyahs <= 5 ? totalAyahs : totalAyahs - 5;
    return pageMappedAyahs >= nearCompleteThreshold;
  }

  bool get needsTextImport => !hasTextData;
  bool get needsPageMetadataImport => hasTextData && !hasPageMetadata;
  bool get needsAnySetup => needsTextImport || needsPageMetadataImport;
}

class QuranDataReadinessService {
  const QuranDataReadinessService(this._db);

  final AppDatabase _db;

  Future<QuranDataReadiness> load() async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS total, '
          'SUM(CASE WHEN page_madina IS NOT NULL THEN 1 ELSE 0 END) AS page_count '
          'FROM ayah',
        )
        .getSingle();

    return QuranDataReadiness(
      totalAyahs: row.read<int>('total'),
      pageMappedAyahs: row.read<int?>('page_count') ?? 0,
    );
  }
}
