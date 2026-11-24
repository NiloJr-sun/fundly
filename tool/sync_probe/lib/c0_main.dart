// Shared spaces C0.3 probe screen (docs/SHARED_SPACES_C0_PLAN.md): switch
// between space stores by hand on the iOS simulator and in Chrome, against
// the LOCAL C0 environment only. Not Fundly UI. From tool/sync_probe:
//
//   flutter run -t lib/c0_main.dart -d <device> \
//     --dart-define-from-file=cloud/c0/config.local.json \
//     --dart-define-from-file=<scratch>/c0_users.json
//
// The test users' local passwords are compiled in; never build this for
// anything but the local C0 environment.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'c0/c0_spaces.dart';

void main() => runApp(const MaterialApp(home: C0ProbePage()));

const _users = {
  'A': (
    String.fromEnvironment('C0_TEST_A_EMAIL'),
    String.fromEnvironment('C0_TEST_A_PASSWORD'),
  ),
  'B': (
    String.fromEnvironment('C0_TEST_B_EMAIL'),
    String.fromEnvironment('C0_TEST_B_PASSWORD'),
  ),
};

class C0ProbePage extends StatefulWidget {
  const C0ProbePage({super.key});

  @override
  State<C0ProbePage> createState() => _C0ProbePageState();
}

class _C0ProbePageState extends State<C0ProbePage> {
  final _config = C0Config.fromEnvironment();
  C0User? _user;
  C0Store? _store;
  List<Map<String, dynamic>> _spaces = const [];
  String _status = 'Signed out';
  bool _busy = false;

  Future<void> _run(String label, Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _status = '$label…';
    });
    try {
      await action();
    } catch (error) {
      setState(() => _status = '$label failed: $error');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _signIn(String name) => _run('Signing in as $name', () async {
    await _store?.close();
    _store = null;
    final user = _users[name]!;
    _user = await C0User.signIn(_config, name, user.$1, user.$2);
    await _refreshSpaces();
    _status = 'Signed in as $name';
  });

  Future<void> _refreshSpaces() async {
    final rows = await _user!.client
        .from('c0_spaces')
        .select('id, name')
        .order('name');
    setState(() => _spaces = rows);
  }

  Future<void> _createSpace() => _run('Creating a space', () async {
    final number = _spaces.length + 1;
    await _user!.createSpace(const Uuid().v4(), 'Probe space $number');
    await _refreshSpaces();
    _status = 'Created Probe space $number';
  });

  Future<String> _path(String space) async {
    final name = '${c0StoreName(_user!, space)}.sqlite';
    if (kIsWeb) return name;
    return '${(await getApplicationSupportDirectory()).path}/$name';
  }

  Future<void> _switchTo(String space, String name) =>
      _run('Switching to $name', () async {
        final started = DateTime.now();
        await _store?.close();
        final store = await C0Store.open(
          await _path(space),
          _config,
          _user!,
          space,
        );
        final onDevice = (await store.ids('c0_entries')).length;
        setState(() => _store = store);
        await store.sync();
        final took = DateTime.now().difference(started).inMilliseconds;
        _status =
            '$name: $onDevice entries already on this device; '
            'synced in $took ms';
      });

  Future<void> _addEntry() => _run('Adding an entry', () async {
    await _store!.database.execute(
      'INSERT INTO c0_entries (id, space_id, label, amount_minor, revision) '
      'VALUES (uuid(), ?, ?, ?, 1)',
      [
        _store!.space,
        'From ${_user!.name} at ${TimeOfDay.now().format(context)}',
        100,
      ],
    );
    _status = 'Entry added; it uploads in the background';
  });

  @override
  Widget build(BuildContext context) {
    final store = _store;
    return Scaffold(
      appBar: AppBar(title: Text('C0 spaces · ${_user?.name ?? '-'}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final name in _users.keys)
                FilledButton.tonal(
                  onPressed: _busy || !_config.isComplete
                      ? null
                      : () => _signIn(name),
                  child: Text('Sign in as $name'),
                ),
              if (_user != null)
                OutlinedButton(
                  onPressed: _busy ? null : _createSpace,
                  child: const Text('Create space'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_status, key: const Key('status')),
          const Divider(),
          for (final space in _spaces)
            ListTile(
              title: Text(space['name'] as String),
              trailing: store?.space == space['id']
                  ? const Icon(Icons.check)
                  : null,
              onTap: _busy
                  ? null
                  : () => _switchTo(
                      space['id'] as String,
                      space['name'] as String,
                    ),
            ),
          if (store != null) ...[
            const Divider(),
            Row(
              children: [
                const Expanded(child: Text('Entries in this space')),
                FilledButton(
                  onPressed: _busy ? null : _addEntry,
                  child: const Text('Add entry'),
                ),
              ],
            ),
            StreamBuilder(
              stream: store.database.watch(
                'SELECT label FROM c0_entries ORDER BY created_at, label',
              ),
              builder: (context, snapshot) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final row in snapshot.data ?? const [])
                    Text('• ${row['label']}'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
