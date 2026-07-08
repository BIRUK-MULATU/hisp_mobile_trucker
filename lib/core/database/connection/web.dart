import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

import '../../utils/app_logger.dart';

/// Served from web/ (downloaded to match pubspec.lock's sqlite3/drift
/// versions — re-download both when upgrading drift).
final Uri _sqlite3Wasm = Uri.parse('sqlite3.wasm');
final Uri _driftWorker = Uri.parse('drift_worker.js');

String _dbName(String userKey) => 'hisp_$userKey';

/// [userKey] must already be sanitized (AppDatabase.sanitizeUserKey).
QueryExecutor openConnectionFor(String userKey) {
  return DatabaseConnection.delayed(Future(() async {
    final result = await WasmDatabase.open(
      databaseName: _dbName(userKey),
      sqlite3Uri: _sqlite3Wasm,
      driftWorkerUri: _driftWorker,
    );
    if (result.missingFeatures.isNotEmpty) {
      // Still works, but persistence may fall back to a weaker storage
      // (e.g. IndexedDB instead of OPFS) on this browser.
      log.w('[db/web] using ${result.chosenImplementation}; '
          'missing: ${result.missingFeatures}');
    }
    return result.resolvedExecutor;
  }));
}

/// True if this user has logged in on this device (browser) before —
/// the gate for allowing OFFLINE login.
Future<bool> databaseExistsFor(String userKey) async {
  final probe = await WasmDatabase.probe(
    sqlite3Uri: _sqlite3Wasm,
    driftWorkerUri: _driftWorker,
    databaseName: _dbName(userKey),
  );
  final name = _dbName(userKey);
  return probe.existingDatabases.any((db) => db.$2 == name);
}

/// Delete a user's database entirely — part of WIPE.
Future<void> deleteDatabaseFor(String userKey) async {
  final probe = await WasmDatabase.probe(
    sqlite3Uri: _sqlite3Wasm,
    driftWorkerUri: _driftWorker,
    databaseName: _dbName(userKey),
  );
  final name = _dbName(userKey);
  for (final db in probe.existingDatabases) {
    if (db.$2 == name) {
      await probe.deleteDatabase(db);
    }
  }
}
