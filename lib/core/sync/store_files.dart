import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:sqlite_async/sqlite_async.dart';

import '../database/database_name.dart';
import 'store_files_native.dart'
    if (dart.library.js_interop) 'store_files_web.dart'
    as platform;

/// Where the store called [name] lives: a file in [directory] on native
/// platforms, a browser database on the web.
String syncedStorePath(String name, String directory) =>
    kIsWeb ? '$name.db' : '$directory/$name.db';

/// How a store's SQLite is opened. Absolute URLs: the web worker fetches the
/// wasm itself, and a relative path there resolves against the worker's
/// folder (powersync/), not the page.
SqliteOptions syncedSqliteOptions() => SqliteOptions(
  webSqliteOptions: WebSqliteOptions(
    wasmUri: Uri.base.resolve('powersync/sqlite3.wasm').toString(),
    workerUri: Uri.base.resolve('powersync/powersync_db.worker.js').toString(),
  ),
);

/// The app's documents folder, which holds the stores on native platforms.
Future<String> documentsDirectory() async =>
    (await getApplicationDocumentsDirectory()).path;

/// Changes in a store that never reached the server.
@immutable
final class StoreChanges {
  const StoreChanges({required this.unsent, required this.refused});

  /// Queued batches not yet uploaded.
  final int unsent;

  /// Entries in the refused-changes log.
  final int refused;

  bool get isEmpty => unsent == 0 && refused == 0;
}

/// The stores of a user's spaces as files on this device (shared spaces
/// C3): whether one is there, what it still holds, and deleting it. Only for
/// stores that are not open.
abstract interface class SpaceStoreFiles {
  Future<bool> exists(String userId, String spaceId);

  /// Opens the store without connecting (so nothing uploads) to count its
  /// changes, then closes it.
  Future<StoreChanges> changesIn(String userId, String spaceId);

  /// Deletes the store. On the web this fails while another tab has it
  /// open; the caller tries again on a later start.
  Future<void> delete(String userId, String spaceId);
}

/// The real [SpaceStoreFiles], for [PowerSyncStore]'s files.
class PowerSyncStoreFiles implements SpaceStoreFiles {
  /// [directory] holds the stores on native platforms; the documents folder
  /// unless given (tests).
  PowerSyncStoreFiles({Future<String> Function()? directory})
    : _directory = directory ?? documentsDirectory;

  final Future<String> Function() _directory;

  Future<String> _path(String userId, String spaceId) async => syncedStorePath(
    syncedDatabaseNameFor(userId, spaceId),
    kIsWeb ? '' : await _directory(),
  );

  @override
  Future<bool> exists(String userId, String spaceId) async =>
      platform.storeExists(await _path(userId, spaceId), syncedSqliteOptions());

  @override
  Future<StoreChanges> changesIn(String userId, String spaceId) async {
    final database = ps.PowerSyncDatabase(
      schema: const ps.Schema([]),
      path: await _path(userId, spaceId),
      sqliteOptions: syncedSqliteOptions(),
    );
    try {
      await database.initialize();
      final unsent = await database.get('SELECT count(*) AS n FROM ps_crud');
      final hasLog = await database.getOptional(
        "SELECT 1 FROM sqlite_master WHERE name = 'sync_rejections'",
      );
      final refused = hasLog == null
          ? 0
          : (await database.get(
                  'SELECT count(*) AS n FROM sync_rejections',
                ))['n']
                as int;
      return StoreChanges(unsent: unsent['n'] as int, refused: refused);
    } finally {
      await database.close();
    }
  }

  @override
  Future<void> delete(String userId, String spaceId) async =>
      platform.deleteStore(await _path(userId, spaceId), syncedSqliteOptions());
}
