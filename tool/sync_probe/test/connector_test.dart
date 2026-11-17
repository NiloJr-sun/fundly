import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fundly_sync_probe/probe_connector.dart';
import 'package:fundly_sync_probe/probe_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// A local HTTP stand-in tests the acknowledgement boundary against the real
// SQLite queue. It does not validate PostgreSQL, RLS or PowerSync downloads.
void main() {
  test(
    'RPC rejection retains queue; retry reuses batch ID after reopening',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'fundly-probe-http-',
      );
      final path = '${directory.path}/probe.sqlite';
      var store = await ProbeStore.open(path, raw: true);
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var reject = true;
      final batches = <Map<String, dynamic>>[];
      final requests = server.listen((request) async {
        batches.add(
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>,
        );
        request.response.headers.contentType = ContentType.json;
        request.response.statusCode = reject ? 400 : 200;
        request.response.write(
          reject
              ? jsonEncode({
                  'code': '23514',
                  'message': 'Intentional rejection',
                })
              : 'null',
        );
        await request.response.close();
      });
      final client = SupabaseClient(
        'http://127.0.0.1:${server.port}',
        'public-probe-key',
        accessToken: () async => 'disposable-test-token',
      );
      try {
        await store.drift.createPair(const Uuid().v4(), const Uuid().v4());
        final installation = store.installationId;
        await expectLater(
          ProbeConnector(client, 'unused', installation).uploadData(store.sync),
          throwsA(isA<PostgrestException>()),
        );
        expect(await store.sync.getNextCrudTransaction(), isNotNull);
        await store.close();
        store = await ProbeStore.open(path, raw: true);
        expect(store.installationId, installation);
        reject = false;
        await ProbeConnector(
          client,
          'unused',
          store.installationId,
        ).uploadData(store.sync);
        expect(await store.sync.getNextCrudTransaction(), isNull);
        expect(batches, hasLength(2));
        expect(batches.last['p_batch_id'], batches.first['p_batch_id']);
        expect(batches.last['p_ops'], batches.first['p_ops']);
        expect(batches.first['p_ops'], hasLength(2));
      } finally {
        await store.close();
        await client.dispose();
        await requests.cancel();
        await server.close(force: true);
        await directory.delete(recursive: true);
      }
    },
  );
}
