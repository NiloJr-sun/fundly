import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main.dart';
import 'probe_connector.dart';
import 'probe_database.dart';

/// Test-account login only. Google OAuth is a later production task.
class CloudLogin extends StatefulWidget {
  const CloudLogin({
    required this.directory,
    required this.endpoint,
    super.key,
  });
  final String directory;
  final String endpoint;
  @override
  State<CloudLogin> createState() => _CloudLoginState();
}

class _CloudLoginState extends State<CloudLogin> {
  final email = TextEditingController();
  final password = TextEditingController();
  ProbeStore? store;
  ProbeConnector? connector;
  String? error;
  bool busy = false;

  Future<void> signIn() async {
    setState(() {
      busy = true;
      error = null;
    });
    ProbeStore? opened;
    try {
      final client = Supabase.instance.client;
      final response = await client.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text,
      );
      password.clear();
      final user = response.user!;
      opened = await ProbeStore.open(
        '${widget.directory}fundly_sync_probe_cloud_${user.id}.sqlite',
        raw: true,
      );
      final backend = ProbeConnector(
        client,
        widget.endpoint,
        opened.installationId,
        expectedUserId: user.id,
      );
      await opened.sync.connect(connector: backend);
      if (!mounted) {
        await opened.close();
        return;
      }
      setState(() {
        store = opened;
        connector = backend;
      });
    } catch (failure) {
      await opened?.close();
      if (mounted) setState(() => error = '$failure');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (store != null) return ProbeApp(store: store!, connector: connector);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('S1 cloud probe — test accounts only'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Create disposable email/password users in Supabase first. '
                    'Google login is not implemented in this compatibility probe.',
                  ),
                  TextField(
                    controller: email,
                    decoration: const InputDecoration(labelText: 'Test email'),
                  ),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Test password',
                    ),
                  ),
                  if (error != null) Text(error!),
                  FilledButton(
                    onPressed: busy ? null : signIn,
                    child: Text(busy ? 'Connecting…' : 'Sign in to probe'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
