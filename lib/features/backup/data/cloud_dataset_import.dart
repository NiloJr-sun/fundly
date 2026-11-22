import 'dart:async';

import '../../../core/sync/batch_uploader.dart';
import '../../../core/sync/dataset_import.dart';
import '../../../core/sync/sync_queue.dart' show newRecordId;
import 'backup_importer.dart';

/// Why an import into the account did not finish.
enum CloudImportProblem {
  /// The account changed after the user saw its counts (`dataset_changed`,
  /// or `dataset_not_empty` for a copy into an empty account). Nothing
  /// changed; the user looks at the new counts and starts again.
  datasetChanged,

  /// The server could not be reached, even after retrying. The import either
  /// did not happen or did, and this device will see it when it syncs.
  unreachable,

  /// The server refused the import. Nothing changed.
  refused,
}

class CloudImportException implements Exception {
  const CloudImportException(this.problem, [this.code = '']);

  final CloudImportProblem problem;

  /// The server's error code, for [CloudImportProblem.refused] and
  /// [CloudImportProblem.unreachable].
  final String code;

  @override
  String toString() => 'CloudImportException(${problem.name}, $code)';
}

/// Sends one `fundly_import_dataset` request (supabase/IMPORT_API.md) for the
/// signed-in user, used by Reset all data and by copying this device's data.
class CloudDatasetImport {
  CloudDatasetImport({
    required ImportDataset importDataset,
    required this._userId,
    this._newId = newRecordId,
    this._wait = Future<void>.delayed,
    this.attempts = 3,
  }) : _import = importDataset;

  final ImportDataset _import;
  final String _userId;
  final String Function() _newId;
  final Future<void> Function(Duration) _wait;

  /// How many times one request is sent before giving up on a network or
  /// server-availability failure.
  final int attempts;

  /// Sends [request] under [importId] (a new one by default) and returns the
  /// counts the server reports afterwards. Throws [CloudImportException].
  ///
  /// A lost response is resent with the same import ID and body, which the
  /// server's receipt makes safe: the import never applies twice.
  Future<BackupCounts> send(
    Map<String, Object?> request, {
    String? importId,
  }) async {
    importId ??= _newId();
    for (var attempt = 1; ; attempt++) {
      try {
        final result = await _import(
          userId: _userId,
          importId: importId,
          request: request,
        );
        return _countsFrom(result);
      } on Object catch (error) {
        final failure = classifyUploadError(error);
        if (failure.outcome != UploadOutcome.transient) {
          throw switch (failure.code) {
            'dataset_changed' || 'dataset_not_empty' =>
              const CloudImportException(CloudImportProblem.datasetChanged),
            _ => CloudImportException(CloudImportProblem.refused, failure.code),
          };
        }
        if (attempt >= attempts) {
          throw CloudImportException(
            CloudImportProblem.unreachable,
            failure.code,
          );
        }
        await _wait(Duration(seconds: attempt));
      }
    }
  }

  static BackupCounts _countsFrom(Map<String, Object?> result) {
    final counts = result['counts']! as Map<Object?, Object?>;
    int count(String key) => (counts[key]! as num).toInt();
    return BackupCounts(
      customAccountTypes: count('custom_account_types'),
      accounts: count('accounts'),
      categories: count('categories'),
      transactions: count('transactions'),
      monthlyPlans: count('monthly_plans'),
    );
  }
}
