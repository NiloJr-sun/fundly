// Development only (shared spaces C2): runs Fundly against the LOCAL Supabase
// stack and local sync (tool/sync_probe/cloud/fundly-local), signing in with a
// local test user, since the local stack has no Google sign-in. Never used
// for a release; refuses any server but the local one. See tool/dev/README.md.
import 'package:fundly/main.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart';

const _url = String.fromEnvironment('FUNDLY_SUPABASE_URL');
const _email = String.fromEnvironment('FUNDLY_DEV_EMAIL');
const _password = String.fromEnvironment('FUNDLY_DEV_PASSWORD');

Future<void> main() async {
  if (!_url.startsWith('http://127.0.0.1:') &&
      !_url.startsWith('http://localhost:')) {
    throw StateError('local_main.dart only runs against the local stack');
  }
  await app.main();
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession == null && _email.isNotEmpty) {
    await auth.signInWithPassword(email: _email, password: _password);
  }
}
