import 'package:drift_flutter/drift_flutter.dart';

enum DatabaseStorageHealth {
  persistent,
  degraded,
  transient,
}

enum DatabaseStorageKind {
  nativePersistent,
  webInitializing,
  opfsShared,
  opfs,
  indexedDbShared,
  indexedDbFallback,
  inMemory,
  other,
}

class DatabaseStorageStatus {
  const DatabaseStorageStatus({
    required this.kind,
    required this.health,
    required this.isWeb,
    this.implementationName,
    this.missingFeatures = const <String>{},
  });

  factory DatabaseStorageStatus.nativePersistent() {
    return const DatabaseStorageStatus(
      kind: DatabaseStorageKind.nativePersistent,
      health: DatabaseStorageHealth.persistent,
      isWeb: false,
    );
  }

  factory DatabaseStorageStatus.webInitializing() {
    return const DatabaseStorageStatus(
      kind: DatabaseStorageKind.webInitializing,
      health: DatabaseStorageHealth.degraded,
      isWeb: true,
    );
  }

  factory DatabaseStorageStatus.fromWasmResult(WasmDatabaseResult result) {
    final implName = result.chosenImplementation.name;
    final missing =
        result.missingFeatures.map((feature) => feature.name).toSet();

    switch (implName) {
      case 'opfsShared':
        return DatabaseStorageStatus(
          kind: DatabaseStorageKind.opfsShared,
          health: DatabaseStorageHealth.persistent,
          isWeb: true,
          implementationName: implName,
          missingFeatures: missing,
        );
      case 'opfsLocks':
        return DatabaseStorageStatus(
          kind: DatabaseStorageKind.opfs,
          health: DatabaseStorageHealth.persistent,
          isWeb: true,
          implementationName: implName,
          missingFeatures: missing,
        );
      case 'sharedIndexedDb':
        return DatabaseStorageStatus(
          kind: DatabaseStorageKind.indexedDbShared,
          health: DatabaseStorageHealth.persistent,
          isWeb: true,
          implementationName: implName,
          missingFeatures: missing,
        );
      case 'unsafeIndexedDb':
        return DatabaseStorageStatus(
          kind: DatabaseStorageKind.indexedDbFallback,
          health: DatabaseStorageHealth.degraded,
          isWeb: true,
          implementationName: implName,
          missingFeatures: missing,
        );
      case 'inMemory':
        return DatabaseStorageStatus(
          kind: DatabaseStorageKind.inMemory,
          health: DatabaseStorageHealth.transient,
          isWeb: true,
          implementationName: implName,
          missingFeatures: missing,
        );
      default:
        return DatabaseStorageStatus(
          kind: DatabaseStorageKind.other,
          health: DatabaseStorageHealth.degraded,
          isWeb: true,
          implementationName: implName,
          missingFeatures: missing,
        );
    }
  }

  final DatabaseStorageKind kind;
  final DatabaseStorageHealth health;
  final bool isWeb;
  final String? implementationName;
  final Set<String> missingFeatures;

  bool get isPersistent => health == DatabaseStorageHealth.persistent;
}
