// Shared spaces C1.3 rehearsal (docs/SHARED_SPACES_C1_PLAN.md): downloads one
// user's rows through the production sync config from the migrated copy of
// production, and writes each table's (id, revision) pairs to a file for the
// rehearsal to compare with the database. Skipped unless C1_TOKEN,
// C1_POWERSYNC_URL and C1_OUT are set. The token and the output hold private
// data: keep both in the private rehearsal folder. Run from tool/sync_probe:
//
//   C1_TOKEN=... C1_POWERSYNC_URL=http://127.0.0.1:57380 C1_OUT=<private>/stream.json \
//     flutter test test/c1_rehearsal_stream_test.dart
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/powersync.dart' as ps;

import 'fundly_stream_test.dart' show fundlyStreamSchema;

final _environment = Platform.environment;

class _TokenConnector extends ps.PowerSyncBackendConnector {
  _TokenConnector(this.endpoint, this.token);
  final String endpoint;
  final String token;

  @override
  Future<ps.PowerSyncCredentials?> fetchCredentials() async =>
      ps.PowerSyncCredentials(endpoint: endpoint, token: token);

  @override
  Future<void> uploadData(ps.PowerSyncDatabase database) async {}
}

void main() {
  final token = _environment['C1_TOKEN'] ?? '';
  final endpoint = _environment['C1_POWERSYNC_URL'] ?? '';
  final out = _environment['C1_OUT'] ?? '';
  final skip = token.isEmpty || endpoint.isEmpty || out.isEmpty
      ? 'C1 rehearsal: set C1_TOKEN, C1_POWERSYNC_URL and C1_OUT'
      : null;

  test(
    'one user\'s stream from the migrated copy',
    () async {
      if (!endpoint.startsWith('http://127.0.0.1:')) {
        fail('The rehearsal stream check runs only against a local service');
      }
      final directory = await Directory.systemTemp.createTemp('fundly-c1-');
      final database = ps.PowerSyncDatabase(
        schema: fundlyStreamSchema,
        path: '${directory.path}/rehearsal.sqlite',
      );
      try {
        await database.initialize();
        await database.connect(connector: _TokenConnector(endpoint, token));
        await database.waitForFirstSync().timeout(const Duration(seconds: 60));
        final result = <String, List<List<Object?>>>{};
        for (final table in [
          'custom_account_types',
          'accounts',
          'categories',
          'transactions',
          'monthly_plans',
        ]) {
          result[table] = [
            for (final row in await database.getAll(
              'SELECT id, revision FROM $table ORDER BY id',
            ))
              [row['id'], row['revision']],
          ];
        }
        File(out).writeAsStringSync(jsonEncode(result));
      } finally {
        await database.disconnectAndClear();
        await database.close();
        await directory.delete(recursive: true);
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
