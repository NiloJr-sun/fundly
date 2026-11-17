import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cloud_login.dart';
import 'probe_connector.dart';
import 'probe_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final directory = kIsWeb
        ? ''
        : '${(await getApplicationSupportDirectory()).path}/';
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    const endpoint = String.fromEnvironment('POWERSYNC_URL');
    if (supabaseUrl.isNotEmpty && key.isNotEmpty && endpoint.isNotEmpty) {
      await Supabase.initialize(url: supabaseUrl, publishableKey: key);
      runApp(CloudLogin(directory: directory, endpoint: endpoint));
      return;
    }
    final path = '${directory}fundly_sync_probe_raw.sqlite';
    final store = await ProbeStore.open(path, raw: true);
    runApp(ProbeApp(store: store));
  } catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('$error'))),
      ),
    );
  }
}

class ProbeApp extends StatefulWidget {
  const ProbeApp({required this.store, this.connector, super.key});
  final ProbeStore store;
  final ProbeConnector? connector;
  @override
  State<ProbeApp> createState() => _ProbeAppState();
}

class _ProbeAppState extends State<ProbeApp> {
  late String message = widget.connector == null
      ? 'Local checks only. No cloud connection configured.'
      : 'Cloud probe. Verify rows on both clients; an empty queue alone does not prove convergence.';
  bool busy = false;
  late final rows = widget.store.drift
      .select(widget.store.drift.probeParents)
      .watch();

  Future<void> perform(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
      final queued = await widget.store.sync.getNextCrudTransaction();
      if (mounted) {
        setState(
          () => message = queued == null
              ? 'No pending writes. Check both clients for the accepted records.'
              : 'Oldest queued transaction: ${queued.crud.length} operations. '
                    'Pending upload or retry.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => message = '$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Fundly S1 — disposable data')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (widget.connector != null) ...[
              StreamBuilder(
                stream: widget.store.sync.statusStream,
                initialData: widget.store.sync.currentStatus,
                builder: (context, snapshot) => Text('${snapshot.data}'),
              ),
              Wrap(
                children: [
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => perform(widget.store.sync.disconnect),
                    child: const Text('Disconnect (offline)'),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => perform(
                            () => widget.store.sync.connect(
                              connector: widget.connector!,
                            ),
                          ),
                    child: const Text('Reconnect'),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => perform(
                            () => widget.store.drift.createPair(
                              const Uuid().v4(),
                              const Uuid().v4(),
                              reject: true,
                            ),
                          ),
                    child: const Text(
                      'Queue intentional rejection (test last)',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy
                  ? null
                  : () => perform(
                      () => widget.store.drift.createPair(
                        const Uuid().v4(),
                        const Uuid().v4(),
                      ),
                    ),
              child: const Text('Create offline parent + child'),
            ),
            OutlinedButton(
              onPressed: busy ? null : () => perform(() async {}),
              child: const Text('Inspect pending queue'),
            ),
            Expanded(
              child: StreamBuilder(
                stream: rows,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text('${snapshot.error}');
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  return ListView(
                    children: [
                      for (final row in snapshot.requireData)
                        ListTile(
                          title: Text(row.name),
                          subtitle: Text(row.id),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: busy
                                ? null
                                : () => perform(
                                    () => widget.store.drift.transaction(
                                      () async {
                                        await widget.store.drift
                                            .customStatement(
                                              'DELETE FROM probe_entries WHERE parent_id = ?',
                                              [row.id],
                                            );
                                        await widget.store.drift
                                            .customStatement(
                                              'DELETE FROM probe_parents WHERE id = ?',
                                              [row.id],
                                            );
                                      },
                                    ),
                                  ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
