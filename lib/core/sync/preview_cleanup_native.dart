import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Deletes the native drift database called [name] (drift_flutter keeps it as
/// `<documents>/<name>.sqlite`, with SQLite's journal files beside it).
/// Missing files are fine: the preview may never have been opened.
Future<void> deletePreviewDatabase(String name) async {
  final directory = await getApplicationDocumentsDirectory();
  for (final suffix in [
    '.sqlite',
    '.sqlite-wal',
    '.sqlite-shm',
    '.sqlite-journal',
  ]) {
    final file = File('${directory.path}/$name$suffix');
    if (file.existsSync()) await file.delete();
  }
}
