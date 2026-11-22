import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'batch_uploader.dart';

/// Sends one request to `fundly_import_dataset` (supabase/IMPORT_API.md) for
/// the signed-in user [userId] and returns the server's result. Throws on any
/// failure, the way [ApplyBatch] does.
typedef ImportDataset = Future<Map<String, Object?>> Function({
  required String userId,
  required String importId,
  required Map<String, Object?> request,
});

/// The real [ImportDataset], through [client]. Never sends one user's
/// request with another user's session.
ImportDataset supabaseImportDataset(SupabaseClient client) =>
    ({required userId, required importId, required request}) async {
      if (client.auth.currentSession?.user.id != userId) {
        throw const SyncUploadException(UploadOutcome.transient, 'signed_out');
      }
      final result = await client.rpc<dynamic>(
        'fundly_import_dataset',
        params: {'import_id': importId, 'request': request},
      );
      return Map<String, Object?>.from(result as Map);
    };

/// Set in `main.dart` when the build carries the cloud configuration; `null`
/// otherwise (and in tests unless overridden).
final importDatasetProvider = Provider<ImportDataset?>((ref) => null);
