import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Disposable S1 connector: rejected transactions deliberately stay queued.
/// Production rejection recovery is not implemented by this probe.
class ProbeConnector extends PowerSyncBackendConnector {
  ProbeConnector(
    this.client,
    this.endpoint,
    this.installationId, {
    this.expectedUserId,
  });
  final SupabaseClient client;
  final String endpoint;
  final String installationId;
  final String? expectedUserId;

  void _checkIdentity() {
    if (expectedUserId != null &&
        client.auth.currentUser?.id != expectedUserId) {
      throw StateError(
        'User changed. Restart the disposable probe before syncing.',
      );
    }
  }

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    _checkIdentity();
    var session = client.auth.currentSession;
    if (session == null) return null;
    if (session.isExpired) {
      session = (await client.auth.refreshSession()).session;
    }
    if (session == null) return null;
    return PowerSyncCredentials(
      endpoint: endpoint,
      token: session.accessToken,
      userId: session.user.id,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    _checkIdentity();
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;
    // Queue IDs persist across reopen; the installation ID changes on a reset.
    final batchId = const Uuid().v5(
      '0f4e64b5-c606-49d1-94f9-6d9bf1c9fc42',
      '$installationId:${transaction.crud.map((e) => e.clientId).join(',')}',
    );
    await client.rpc(
      'probe_apply_batch',
      params: {
        'p_batch_id': batchId,
        'p_ops': transaction.crud.map((e) => e.toJson()).toList(),
      },
    );
    // Never acknowledge a rejected or interrupted upload.
    await transaction.complete();
  }
}
