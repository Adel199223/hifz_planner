import 'package:drift_flutter/drift_flutter.dart';

enum DatabaseStorageHealth {
  persistent,
  degraded,
  transient,
}

class DatabaseStorageStatus {
  const DatabaseStorageStatus({
    required this.label,
    required this.details,
    required this.health,
    required this.isWeb,
    this.warningMessage,
    this.missingFeatures = const <String>{},
  });

  factory DatabaseStorageStatus.nativePersistent() {
    return const DatabaseStorageStatus(
      label: 'Local SQLite',
      details: 'Persistent local database storage is active.',
      health: DatabaseStorageHealth.persistent,
      isWeb: false,
    );
  }

  factory DatabaseStorageStatus.webInitializing() {
    return const DatabaseStorageStatus(
      label: 'Browser storage',
      details: 'Checking the best available browser storage mode...',
      health: DatabaseStorageHealth.degraded,
      isWeb: true,
    );
  }

  factory DatabaseStorageStatus.fromWasmResult(WasmDatabaseResult result) {
    final implName = result.chosenImplementation.name;
    final missing = result.missingFeatures.map((feature) => feature.name).toSet();

    switch (implName) {
      case 'opfsShared':
        return DatabaseStorageStatus(
          label: 'Browser storage (OPFS shared)',
          details: _details('Persistent browser storage with shared-worker support.', missing),
          health: DatabaseStorageHealth.persistent,
          isWeb: true,
          missingFeatures: missing,
        );
      case 'opfsLocks':
        return DatabaseStorageStatus(
          label: 'Browser storage (OPFS)',
          details: _details('Persistent browser storage is active.', missing),
          health: DatabaseStorageHealth.persistent,
          isWeb: true,
          missingFeatures: missing,
        );
      case 'sharedIndexedDb':
        return DatabaseStorageStatus(
          label: 'Browser storage (IndexedDB shared)',
          details: _details('Persistent browser storage is active in IndexedDB.', missing),
          health: DatabaseStorageHealth.persistent,
          isWeb: true,
          missingFeatures: missing,
        );
      case 'unsafeIndexedDb':
        return DatabaseStorageStatus(
          label: 'Browser storage (IndexedDB fallback)',
          details: _details('Persistent browser storage is available in a weaker fallback mode.', missing),
          health: DatabaseStorageHealth.degraded,
          isWeb: true,
          warningMessage: 'Browser storage is using a weaker IndexedDB fallback. Data should persist, but multi-tab safety is reduced.',
          missingFeatures: missing,
        );
      case 'inMemory':
        return DatabaseStorageStatus(
          label: 'Browser storage (memory only)',
          details: _details('The browser could only open an in-memory database for this session.', missing),
          health: DatabaseStorageHealth.transient,
          isWeb: true,
          warningMessage: 'Browser storage fell back to memory only. Data will be lost after refresh or tab close.',
          missingFeatures: missing,
        );
      default:
        return DatabaseStorageStatus(
          label: 'Browser storage',
          details: _details('Browser storage opened with ${result.chosenImplementation.name}.', missing),
          health: DatabaseStorageHealth.degraded,
          isWeb: true,
          warningMessage: missing.isEmpty
              ? null
              : 'Browser storage is missing some features: ${missing.join(', ')}.',
          missingFeatures: missing,
        );
    }
  }

  final String label;
  final String details;
  final DatabaseStorageHealth health;
  final bool isWeb;
  final String? warningMessage;
  final Set<String> missingFeatures;

  bool get isPersistent => health == DatabaseStorageHealth.persistent;

  static String _details(String base, Set<String> missing) {
    if (missing.isEmpty) {
      return base;
    }
    return '$base Missing browser features: ${missing.join(', ')}.';
  }
}
