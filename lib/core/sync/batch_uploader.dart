import 'package:powersync/powersync.dart' as ps;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_queue.dart';

/// What happened to one upload, following the outcome classes in
/// supabase/SYNC_PROTOCOL.md.
enum UploadOutcome {
  accepted,

  /// Network, server availability or session trouble: retry the same batch.
  transient,

  /// A final rejection, such as a revision conflict or a broken rule. Kept in
  /// the queue until the rejection log arrives (S5.4).
  rejected,

  /// The server cannot process the batch at all (for example an operation it
  /// does not know yet). Kept in the queue; never discarded automatically.
  blocked,
}

/// Why the oldest queued batch did not upload. PowerSync reports it in the
/// sync status and tries again later with the same batch.
class SyncUploadException implements Exception {
  const SyncUploadException(this.outcome, this.code, {this.detail});

  final UploadOutcome outcome;

  /// The server's message code (for example `revision_conflict`) or the
  /// error's type.
  final String code;
  final String? detail;

  /// True when retrying alone will not help: the queue waits for S5.4's
  /// rejection handling or a newer server.
  bool get isStuck =>
      outcome == UploadOutcome.rejected || outcome == UploadOutcome.blocked;

  @override
  String toString() => code;
}

/// Sends one batch to the server. Throws on any failure.
typedef ApplyBatch = Future<void> Function(
  String batchId,
  Map<String, dynamic> operations,
);

/// The real [ApplyBatch]: the `fundly_apply_operations` RPC.
ApplyBatch supabaseApplyBatch(SupabaseClient client) =>
    (batchId, operations) => client.rpc<dynamic>(
      'fundly_apply_operations',
      params: {'batch_id': batchId, 'operations': operations},
    );

/// Uploads the oldest queued batch. Returns false when the queue is empty.
///
/// On success the batch leaves the queue. On failure it stays, unchanged, and
/// a [SyncUploadException] says why; the next attempt resends the same batch
/// ID and payload, which the server's receipts make safe.
Future<bool> uploadNextBatch(
  ps.PowerSyncDatabase sync,
  ApplyBatch apply,
) async {
  final transaction = await sync.getNextCrudTransaction();
  if (transaction == null) return false;
  for (final entry in transaction.crud) {
    if (entry.table != syncBatchType || entry.opData == null) {
      throw SyncUploadException(
        UploadOutcome.blocked,
        'unknown_queue_entry',
        detail: entry.table,
      );
    }
    try {
      await apply(entry.id, entry.opData!);
    } on Object catch (error) {
      throw classifyUploadError(error);
    }
  }
  await transaction.complete();
  return true;
}

/// SQLSTATEs the protocol treats as temporary.
const _transientStates = {'28000', '40001', '40P01', '55P03', '57014', '57P01'};

/// Messages of `P0001` errors that block rather than reject.
const _blockingMessages = {'unsupported_operation', 'batch_key_reused'};

/// Maps an upload error to its outcome class (SYNC_PROTOCOL.md).
SyncUploadException classifyUploadError(Object error) {
  if (error is SyncUploadException) return error;
  if (error is! PostgrestException) {
    // No server answer (network, timeout) or a session that must refresh.
    return SyncUploadException(
      UploadOutcome.transient,
      error.runtimeType.toString(),
    );
  }
  final state = error.code ?? '';
  final detail = error.details?.toString();
  UploadOutcome outcome;
  if (_transientStates.contains(state) ||
      state.startsWith('53') ||
      state.startsWith('08') ||
      // An HTTP 5xx without a database error, or an expired token (PGRST3xx).
      RegExp(r'^5\d\d$').hasMatch(state) ||
      state.startsWith('PGRST3')) {
    outcome = UploadOutcome.transient;
  } else if (state == '22023') {
    outcome = UploadOutcome.rejected;
  } else if (state == 'P0001') {
    outcome = _blockingMessages.contains(error.message)
        ? UploadOutcome.blocked
        : UploadOutcome.rejected;
  } else {
    outcome = UploadOutcome.blocked;
  }
  final code = state == 'P0001' || state == '22023' || state == '28000'
      ? error.message
      : state.isEmpty
      ? error.message
      : state;
  return SyncUploadException(outcome, code, detail: detail);
}
