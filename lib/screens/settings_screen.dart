import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers/database_providers.dart';
import '../data/services/quran_text_importer_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isImporting = false;
  QuranTextImportProgress? _progress;
  String _statusMessage = 'Ready to import Tanzil Uthmani text.';

  Future<void> _runImport() async {
    if (_isImporting) {
      return;
    }

    setState(() {
      _isImporting = true;
      _progress = null;
      _statusMessage = 'Starting import...';
    });

    try {
      final importer = ref.read(quranTextImporterServiceProvider);
      final result = await importer.importFromAsset(
        force: false,
        onProgress: (progress) {
          if (!mounted) {
            return;
          }
          setState(() {
            _progress = progress;
            _statusMessage = progress.message;
          });
        },
      );

      if (!mounted) {
        return;
      }

      final message = result.skipped
          ? 'Import skipped: ayah table already has data.'
          : 'Import complete: ${result.insertedRows} inserted, ${result.ignoredRows} ignored.';

      setState(() {
        _statusMessage = message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = 'Import failed: $error';
      setState(() {
        _statusMessage = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
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
            FilledButton.icon(
              onPressed: _isImporting ? null : _runImport,
              icon: const Icon(Icons.download),
              label: Text(_isImporting ? 'Importing...' : 'Import Qur\'an Text'),
            ),
            const SizedBox(height: 16),
            if (_progress != null)
              LinearProgressIndicator(
                value: _progress!.total > 0 ? _progress!.fraction : null,
              ),
            const SizedBox(height: 8),
            Text(_statusMessage),
            if (_progress != null) ...[
              const SizedBox(height: 8),
              Text(
                '${_progress!.phase}: ${_progress!.processed}/${_progress!.total}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
