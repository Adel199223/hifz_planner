import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import 'database_storage_status.dart';

class AppDatabaseConnectionFactory {
  AppDatabaseConnectionFactory({
    this.databaseName = 'hifz_planner.sqlite',
    Uri? sqlite3WasmUri,
    Uri? driftWorkerUri,
  })  : sqlite3WasmUri = sqlite3WasmUri ?? Uri.parse('sqlite3.wasm'),
        driftWorkerUri = driftWorkerUri ?? Uri.parse('drift_worker.js') {
    if (!kIsWeb) {
      _currentStatus = DatabaseStorageStatus.nativePersistent();
    }
  }

  final String databaseName;
  final Uri sqlite3WasmUri;
  final Uri driftWorkerUri;
  final StreamController<DatabaseStorageStatus> _statusController =
      StreamController<DatabaseStorageStatus>.broadcast();

  DatabaseStorageStatus _currentStatus =
      DatabaseStorageStatus.webInitializing();

  DatabaseStorageStatus get currentStatus => _currentStatus;

  Stream<DatabaseStorageStatus> get statusStream => _statusController.stream;

  QueryExecutor createExecutor() {
    if (kIsWeb) {
      _update(DatabaseStorageStatus.webInitializing());
      return driftDatabase(
        name: databaseName,
        web: DriftWebOptions(
          sqlite3Wasm: sqlite3WasmUri,
          driftWorker: driftWorkerUri,
          onResult: (result) {
            _update(DatabaseStorageStatus.fromWasmResult(result));
          },
        ),
      );
    }

    _update(DatabaseStorageStatus.nativePersistent());
    return driftDatabase(
      name: databaseName,
      native: const DriftNativeOptions(),
    );
  }

  void dispose() {
    _statusController.close();
  }

  void _update(DatabaseStorageStatus next) {
    _currentStatus = next;
    if (!_statusController.isClosed) {
      _statusController.add(next);
    }
  }
}

QueryExecutor openAppDatabaseConnection() {
  return AppDatabaseConnectionFactory().createExecutor();
}
