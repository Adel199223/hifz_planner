import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_preferences.dart';
import '../data/database/database_storage_status.dart';
import '../data/providers/database_providers.dart';
import '../l10n/app_strings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isImporting = false;
  double? _progressFraction;
  String? _progressDetails;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _statusMessage = AppStrings.of(
      ref.read(appPreferencesProvider).language,
    ).readyToImportBundledQuranAssets;
  }

  Future<void> _runTextImport() async {
    if (_isImporting) {
      return;
    }

    final strings = AppStrings.of(ref.read(appPreferencesProvider).language);
    _beginImport(strings.startingQuranTextImport);

    try {
      final counts = await _loadAyahImportCounts();
      if (counts.totalAyahs > 0) {
        _completeImport(strings.alreadyImported);
        return;
      }

      final importer = ref.read(quranTextImporterServiceProvider);
      final result = await importer.importFromAsset(
        force: false,
        onProgress: (progress) {
          _updateProgress(
            fraction: progress.total > 0 ? progress.fraction : null,
            details:
                '${progress.phase}: ${progress.processed}/${progress.total}',
            statusMessage: progress.message,
          );
        },
      );

      if (!mounted) {
        return;
      }

      final message = result.skipped
          ? strings.importSkippedAyahTableHasData
          : strings.importCompleteSummary(
              result.insertedRows,
              result.ignoredRows,
            );

      _completeImport(message);
    } catch (error) {
      _completeImport(strings.quranTextImportFailed(_formatError(error)));
    } finally {
      _finishImport();
    }
  }

  Future<void> _runPageMetadataImport() async {
    if (_isImporting) {
      return;
    }

    final strings = AppStrings.of(ref.read(appPreferencesProvider).language);
    _beginImport(strings.startingPageMetadataImport);

    try {
      final counts = await _loadAyahImportCounts();
      final nearCompleteThreshold = counts.totalAyahs - 5;
      final metadataAlreadyCurrent = counts.totalAyahs > 0 &&
          (counts.pageMappedAyahs == counts.totalAyahs ||
              counts.pageMappedAyahs >= nearCompleteThreshold);
      if (metadataAlreadyCurrent) {
        _completeImport(strings.pageMetadataAlreadyUpToDate);
        return;
      }

      final importer = ref.read(pageMetadataImporterServiceProvider);
      final result = await importer.importFromAsset(
        onProgress: (progress) {
          _updateProgress(
            fraction: progress.total > 0 ? progress.fraction : null,
            details:
                '${progress.phase}: ${progress.processed}/${progress.total}',
            statusMessage: progress.message,
          );
        },
      );

      if (!mounted) {
        return;
      }

      final message = strings.pageMetadataImportCompleteSummary(
        updatedRows: result.updatedRows,
        unchangedRows: result.unchangedRows,
        missingRows: result.missingRows,
        parsedRows: result.parsedRows,
      );

      _completeImport(message);
    } catch (error) {
      _completeImport(strings.pageMetadataImportFailed(_formatError(error)));
    } finally {
      _finishImport();
    }
  }

  void _beginImport(String statusMessage) {
    setState(() {
      _isImporting = true;
      _progressFraction = null;
      _progressDetails = null;
      _statusMessage = statusMessage;
    });
  }

  void _updateProgress({
    required double? fraction,
    required String details,
    required String statusMessage,
  }) {
    if (!mounted) {
      return;
    }
    setState(() {
      _progressFraction = fraction;
      _progressDetails = details;
      _statusMessage = statusMessage;
    });
  }

  void _showStatusMessage(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _statusMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _completeImport(String message) {
    _updateProgress(
      fraction: 1,
      details:
          AppStrings.of(ref.read(appPreferencesProvider).language).completed,
      statusMessage: message,
    );
    ref.invalidate(quranDataReadinessProvider);
    _showStatusMessage(message);
  }

  Future<_AyahImportCounts> _loadAyahImportCounts() async {
    final db = ref.read(appDatabaseProvider);
    final row = await db
        .customSelect(
          'SELECT COUNT(*) AS total, '
          'SUM(CASE WHEN page_madina IS NOT NULL THEN 1 ELSE 0 END) AS page_count '
          'FROM ayah',
        )
        .getSingle();

    return _AyahImportCounts(
      totalAyahs: row.read<int>('total'),
      pageMappedAyahs: row.read<int?>('page_count') ?? 0,
    );
  }

  void _finishImport() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isImporting = false;
    });
  }

  String _formatError(Object error) {
    if (error is FormatException) {
      return error.message;
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPreferencesProvider);
    final strings = AppStrings.of(prefs.language);
    final storageStatus = ref.watch(databaseStorageStatusProvider);
    final readiness = ref.watch(quranDataReadinessProvider);

    return Semantics(
      container: true,
      label: 'Settings screen',
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.settingsTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _SettingsStatusCard(
                key: const ValueKey('settings_storage_status_card'),
                title: 'Storage status',
                child: storageStatus.when(
                  data: (value) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value.label,
                        key: const ValueKey('settings_storage_status_label'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(value.details),
                      if (value.warningMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          value.warningMessage!,
                          key: const ValueKey('settings_storage_warning'),
                          style: TextStyle(
                            color: value.health ==
                                    DatabaseStorageHealth.transient
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  loading: () => Text(
                    DatabaseStorageStatus.webInitializing().details,
                  ),
                  error: (error, stackTrace) => Text(error.toString()),
                ),
              ),
              const SizedBox(height: 12),
              _SettingsStatusCard(
                key: const ValueKey('settings_quran_data_status_card'),
                title: 'Quran data',
                child: readiness.when(
                  data: (value) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value.needsAnySetup
                            ? strings.readyToImportBundledQuranAssets
                            : strings.pageMetadataAlreadyUpToDate,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        value.needsTextImport
                            ? strings.importQuranText
                            : strings.alreadyImported,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value.needsPageMetadataImport
                            ? strings.importPageMetadata
                            : strings.pageMetadataAlreadyUpToDate,
                      ),
                    ],
                  ),
                  loading: () => Text(strings.readyToImportBundledQuranAssets),
                  error: (error, stackTrace) => Text(error.toString()),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('settings_import_quran_text_button'),
                    onPressed: _isImporting ? null : _runTextImport,
                    icon: const Icon(Icons.download),
                    label: Text(strings.importQuranText),
                  ),
                  FilledButton.icon(
                    key: const ValueKey(
                      'settings_import_page_metadata_button',
                    ),
                    onPressed: _isImporting ? null : _runPageMetadataImport,
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(strings.importPageMetadata),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isImporting || _progressDetails != null)
                LinearProgressIndicator(
                  value: _progressFraction,
                ),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                key: const ValueKey('settings_status_message'),
              ),
              if (_progressDetails != null) ...[
                const SizedBox(height: 8),
                Text(
                  _progressDetails!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsStatusCard extends StatelessWidget {
  const _SettingsStatusCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _AyahImportCounts {
  const _AyahImportCounts({
    required this.totalAyahs,
    required this.pageMappedAyahs,
  });

  final int totalAyahs;
  final int pageMappedAyahs;
}
