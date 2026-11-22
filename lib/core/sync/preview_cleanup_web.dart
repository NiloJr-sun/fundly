import 'package:drift/wasm.dart';

/// Deletes the browser drift database called [name], wherever drift stored it
/// (OPFS or IndexedDB). Missing databases are fine.
Future<void> deletePreviewDatabase(String name) async {
  final probe = await WasmDatabase.probe(
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
    databaseName: name,
  );
  for (final existing in probe.existingDatabases) {
    if (existing.$2 == name) await probe.deleteDatabase(existing);
  }
}
