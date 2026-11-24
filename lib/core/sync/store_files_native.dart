import 'dart:io';

import 'package:sqlite_async/sqlite_async.dart';

/// SQLite's files for the database at [path].
List<File> _files(String path) => [
  for (final suffix in ['', '-wal', '-shm', '-journal']) File('$path$suffix'),
];

Future<bool> storeExists(String path, SqliteOptions options) =>
    File(path).exists();

/// Deletes the database at [path] and SQLite's files beside it. Missing
/// files are fine.
Future<void> deleteStore(String path, SqliteOptions options) async {
  for (final file in _files(path)) {
    if (file.existsSync()) await file.delete();
  }
}
