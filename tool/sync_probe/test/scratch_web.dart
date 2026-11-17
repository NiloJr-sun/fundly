import 'package:uuid/uuid.dart';

Future<String> scratchPath() async =>
    'fundly-sync-probe-${const Uuid().v4()}.sqlite';
// Browser test files use unique names. Clear the test origin's storage to remove.
Future<void> removeScratch(String path) async {}
