import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers/database_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isImporting = false;
  double? _progressFraction;
  String? _progressDetails;
  String _statusMessage = 'Ready to import bundled Qur\'an assets.';

  Future<void> _runTextImport() async {
    if (_isImporting) {
      return;
    }

    _beginImport('Starting Qur\'an text import...');

    try {
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
          ? 'Import skipped: ayah table already has data.'
          : 'Import complete: ${result.insertedRows} inserted, ${result.ignoredRows} ignored.';

      _showStatusMessage(message);
    } catch (error) {
      _showStatusMessage(
        'Qur\'an text import failed: ${_formatError(error)}',
      );
    } finally {
      _finishImport();
    }
  }

  Future<void> _runPageMetadataImport() async {
    if (_isImporting) {
      return;
    }

    _beginImport('Starting page metadata import...');

    try {
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

      final message =
          'Page metadata import complete: ${result.updatedRows} updated, '
          '${result.unchangedRows} unchanged, ${result.missingRows} missing, '
          '${result.parsedRows} parsed.';

      _showStatusMessage(message);
    } catch (error) {
      _showStatusMessage(
        'Page metadata import failed: ${_formatError(error)}',
      );
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _isImporting ? null : _runTextImport,
                  icon: const Icon(Icons.download),
                  label: const Text('Import Qur\'an Text'),
                ),
                FilledButton.icon(
                  onPressed: _isImporting ? null : _runPageMetadataImport,
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Import Page Metadata'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isImporting || _progressDetails != null)
              LinearProgressIndicator(
                value: _progressFraction,
              ),
            const SizedBox(height: 8),
            Text(_statusMessage),
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
    );
  }
}
