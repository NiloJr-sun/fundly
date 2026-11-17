import 'dart:io';

Future<String> scratchPath() async {
  final directory = await Directory.systemTemp.createTemp('fundly-sync-probe-');
  return '${directory.path}/probe.sqlite';
}

Future<void> removeScratch(String path) =>
    File(path).parent.delete(recursive: true);
