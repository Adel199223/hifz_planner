import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_preferences.dart';
import '../data/database/database_storage_status.dart';
import '../data/providers/database_providers.dart';
import '../data/services/solo_setup_flow.dart';
import '../l10n/app_strings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isImporting = false;
  bool _isRunningGuidedSetup = false;
  double? _progressFraction;
  double? _guidedSetupProgressFraction;
  String? _progressDetails;
  GuidedSetupStepKind? _guidedSetupStep;
  String? _guidedSetupCompanionRoute;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _statusMessage = AppStrings.of(
      ref.read(appPreferencesProvider).language,
    ).readyToImportBundledQuranAssets;
  }

  Future<void> _runTextImport() async {
    if (_isImporting || _isRunningGuidedSetup) {
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
          final phaseLabel = strings.quranTextImportPhaseLabel(progress.phase);
          _updateProgress(
            fraction: progress.total > 0 ? progress.fraction : null,
            details: strings.importProgressDetails(
              phaseLabel,
              progress.processed,
              progress.total,
            ),
            statusMessage: phaseLabel,
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
    if (_isImporting || _isRunningGuidedSetup) {
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
          final phaseLabel = strings.pageMetadataImportPhaseLabel(
            progress.phase,
          );
          _updateProgress(
            fraction: progress.total > 0 ? progress.fraction : null,
            details: strings.importProgressDetails(
              phaseLabel,
              progress.processed,
              progress.total,
            ),
            statusMessage: phaseLabel,
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

  Future<void> _runGuidedSetup() async {
    if (_isImporting || _isRunningGuidedSetup) {
      return;
    }

    final strings = AppStrings.of(ref.read(appPreferencesProvider).language);
    setState(() {
      _isRunningGuidedSetup = true;
      _guidedSetupCompanionRoute = null;
      _guidedSetupProgressFraction = null;
      _guidedSetupStep = null;
      _statusMessage = strings.guidedSetupInProgress;
    });

    try {
      final outcome = await ref.read(guidedSetupFlowServiceProvider).run(
            onProgress: (progress) {
              if (!mounted) {
                return;
              }
              setState(() {
                _guidedSetupStep = progress.step;
                _guidedSetupProgressFraction = progress.fraction;
                _statusMessage = _guidedSetupStepLabel(strings, progress);
              });
            },
          );

      if (!mounted) {
        return;
      }

      ref.invalidate(quranDataReadinessProvider);
      ref.invalidate(soloSetupReadinessProvider);

      final message = outcome.companionRoute != null
          ? strings.guidedSetupStarterUnitReady
          : outcome.readiness.needsGuidedSetup
              ? strings.guidedSetupNeedsAttention
              : strings.guidedSetupComplete;

      setState(() {
        _guidedSetupCompanionRoute = outcome.companionRoute;
        _guidedSetupStep = GuidedSetupStepKind.complete;
        _guidedSetupProgressFraction = 1;
        _statusMessage = message;
      });

      _showStatusMessage(message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showStatusMessage(strings.guidedSetupFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isRunningGuidedSetup = false;
        });
      }
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
    ref.invalidate(soloSetupReadinessProvider);
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

  String _guidedSetupStepLabel(
    AppStrings strings,
    GuidedSetupProgress progress,
  ) {
    return switch (progress.step) {
      GuidedSetupStepKind.importText => strings.guidedSetupStepImportText(
          progress.processed,
          progress.total,
        ),
      GuidedSetupStepKind.importPageMetadata =>
        strings.guidedSetupStepImportPageMetadata(
          progress.processed,
          progress.total,
        ),
      GuidedSetupStepKind.saveStarterPlan => strings.guidedSetupStepSaveStarterPlan,
      GuidedSetupStepKind.createStarterUnit =>
        strings.guidedSetupStepCreateStarterUnit,
      GuidedSetupStepKind.complete => strings.guidedSetupStepComplete,
    };
  }

  String _guidedSetupSummary(
    AppStrings strings,
    SoloSetupReadiness readiness,
  ) {
    return strings.guidedSetupMissingSummary(
      needsTextImport: readiness.quranData.needsTextImport,
      needsPageMetadataImport: readiness.quranData.needsPageMetadataImport,
      needsStarterPlan: readiness.needsStarterPlanRepair,
      needsStarterUnit: !readiness.hasAnyMemUnits,
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPreferencesProvider);
    final strings = AppStrings.of(prefs.language);
    final storageStatus = ref.watch(databaseStorageStatusProvider);
    final readiness = ref.watch(quranDataReadinessProvider);
    final setupReadiness = ref.watch(soloSetupReadinessProvider);

    return Semantics(
      container: true,
      label: strings.settingsScreenSemanticsLabel,
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
                title: strings.storageStatusTitle,
                child: storageStatus.when(
                  data: (value) {
                    final warning = strings.storageStatusWarning(value);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.storageStatusLabel(value),
                          key: const ValueKey('settings_storage_status_label'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(strings.storageStatusDetails(value)),
                        if (warning != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            warning,
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
                    );
                  },
                  loading: () => Text(strings.checkingBrowserStorage),
                  error: (error, stackTrace) => Text(error.toString()),
                ),
              ),
              const SizedBox(height: 12),
              _SettingsStatusCard(
                key: const ValueKey('settings_guided_setup_card'),
                title: strings.guidedSetupTitle,
                child: setupReadiness.when(
                  data: (value) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _guidedSetupCompanionRoute != null
                            ? strings.guidedSetupStarterUnitReady
                            : _guidedSetupSummary(strings, value),
                      ),
                      if (_isRunningGuidedSetup ||
                          _guidedSetupProgressFraction != null) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _guidedSetupProgressFraction,
                        ),
                      ],
                      if (_guidedSetupStep != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _guidedSetupStepLabel(
                            strings,
                            GuidedSetupProgress(
                              step: _guidedSetupStep!,
                              processed:
                                  ((_guidedSetupProgressFraction ?? 0) * 100)
                                      .round(),
                              total: _guidedSetupProgressFraction == null
                                  ? 0
                                  : 100,
                            ),
                          ),
                          key: const ValueKey('settings_guided_setup_status'),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (_guidedSetupCompanionRoute != null)
                        FilledButton.icon(
                          key: const ValueKey(
                            'settings_guided_setup_open_companion',
                          ),
                          onPressed: () {
                            context.go(_guidedSetupCompanionRoute!);
                          },
                          icon: const Icon(Icons.play_circle_outline),
                          label: Text(strings.guidedSetupOpenCompanionAction),
                        )
                      else
                        FilledButton.icon(
                          key: const ValueKey('settings_guided_setup_button'),
                          onPressed: (_isImporting || _isRunningGuidedSetup)
                              ? null
                              : _runGuidedSetup,
                          icon: const Icon(Icons.auto_fix_high_outlined),
                          label: Text(strings.guidedSetupAction),
                        ),
                    ],
                  ),
                  loading: () => Text(strings.guidedSetupInProgress),
                  error: (error, stackTrace) => Text(error.toString()),
                ),
              ),
              const SizedBox(height: 12),
              _SettingsStatusCard(
                key: const ValueKey('settings_quran_data_status_card'),
                title: strings.quranDataStatusTitle,
                child: readiness.when(
                  data: (value) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value.needsAnySetup
                            ? strings.quranDataNeedsSetupSummary
                            : strings.quranDataReadySummary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        value.needsTextImport
                            ? strings.quranTextMissing
                            : strings.quranTextReady,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value.needsPageMetadataImport
                            ? strings.pageMetadataMissing
                            : strings.pageMetadataReady,
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
                    onPressed: (_isImporting || _isRunningGuidedSetup)
                        ? null
                        : _runTextImport,
                    icon: const Icon(Icons.download),
                    label: Text(strings.importQuranText),
                  ),
                  FilledButton.icon(
                    key: const ValueKey(
                      'settings_import_page_metadata_button',
                    ),
                    onPressed: (_isImporting || _isRunningGuidedSetup)
                        ? null
                        : _runPageMetadataImport,
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
