import 'package:sqlite_async/sqlite_async.dart';
import 'package:sqlite_async/web.dart';

/// The browser databases called [name], wherever PowerSync stored them (OPFS
/// or IndexedDB), deleted when [delete] is true.
Future<bool> _find(
  String name,
  SqliteOptions options, {
  required bool delete,
}) async {
  final sqlite = await WebSqliteOpenFactory(
    path: name,
    sqliteOptions: options,
  ).openWebSqlite(options.webSqliteOptions);
  try {
    final detected = await sqlite.runFeatureDetection(databaseName: name);
    var found = false;
    for (final (storage, existing) in detected.existingDatabases) {
      if (existing != name) continue;
      found = true;
      if (delete) await sqlite.deleteDatabase(name: name, storage: storage);
    }
    return found;
  } finally {
    sqlite.close();
  }
}

Future<bool> storeExists(String path, SqliteOptions options) =>
    _find(path, options, delete: false);

/// Deletes the browser database at [path]. Fails while another tab has it
/// open; missing databases are fine.
Future<void> deleteStore(String path, SqliteOptions options) =>
    _find(path, options, delete: true);
