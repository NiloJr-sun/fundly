import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/dataset_import.dart';
import '../../../core/sync/sync_queue.dart' show newRecordId;
import '../../../core/sync/synced_database.dart';
import '../../../core/sync/synced_store.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../../categories/data/default_categories.dart';
import 'backup_importer.dart';
import 'cloud_dataset_import.dart';

/// Why a cloud reset did not finish.
enum CloudResetProblem {
  /// Another device changed the account after the user saw its counts.
  /// Nothing was deleted; the user starts again.
  datasetChanged,

  /// The server could not be reached, even after retrying. The reset either
  /// did not happen or did, and this device will see it when it syncs.
  unreachable,

  /// The server refused the reset. Nothing was deleted.
  refused,
}

class CloudResetException implements Exception {
  const CloudResetException(this.problem, [this.code = '']);

  final CloudResetProblem problem;

  /// The server's error code, for [CloudResetProblem.refused].
  final String code;

  @override
  String toString() => 'CloudResetException(${problem.name}, $code)';
}

/// Resets a signed-in user's account to a fresh start: every record on the
/// server is deleted (tombstoned, so every device removes it) and the default
/// categories are added again, in one server transaction.
///
/// Uses `fundly_import_dataset` in `replace` mode (supabase/IMPORT_API.md).
/// The defaults get fresh UUIDs and revision 1, so the server afterwards
/// treats the account as empty for a later `into_empty` import.
class CloudDataResetter {
  CloudDataResetter({
    required ImportDataset importDataset,
    required String userId,
    String? spaceId,
    String Function() newId = newRecordId,
    Future<void> Function(Duration) wait = Future<void>.delayed,
    int attempts = 3,
  }) : _newId = newId,
       _import = CloudDatasetImport(
         importDataset: importDataset,
         userId: userId,
         spaceId: spaceId,
         newId: newId,
         wait: wait,
         attempts: attempts,
       );

  final CloudDatasetImport _import;
  final String Function() _newId;

  /// Resets the account if it still holds [expected] (the counts the user
  /// confirmed), and returns the counts the server reports afterwards.
  ///
  /// Throws [CloudResetException]. A lost response is resent with the same
  /// import ID and body, which the server's receipt makes safe: the reset
  /// never applies twice.
  Future<BackupCounts> resetAll({required BackupCounts expected}) async {
    final importId = _newId();
    try {
      return await _import.send(
        resetRequest(expected: expected, newId: _newId),
        importId: importId,
      );
    } on CloudImportException catch (failure) {
      throw switch (failure.problem) {
        CloudImportProblem.datasetChanged => const CloudResetException(
          CloudResetProblem.datasetChanged,
        ),
        CloudImportProblem.unreachable => CloudResetException(
          CloudResetProblem.unreachable,
          failure.code,
        ),
        CloudImportProblem.refused => CloudResetException(
          CloudResetProblem.refused,
          failure.code,
        ),
      };
    }
  }
}

/// The `replace` request that leaves only the default categories, each with
/// an ID from [newId]. [expected] guards against changes made elsewhere.
Map<String, Object?> resetRequest({
  required BackupCounts expected,
  required String Function() newId,
}) => {
  'version': 1,
  'mode': 'replace',
  'expected': {
    'custom_account_types': expected.customAccountTypes,
    'accounts': expected.accounts,
    'categories': expected.categories,
    'transactions': expected.transactions,
    'monthly_plans': expected.monthlyPlans,
    'custom_banks': expected.customBanks,
  },
  'dataset': {
    'custom_account_types': <Object>[],
    'custom_banks': <Object>[],
    'accounts': <Object>[],
    'categories': [
      for (final category in defaultCategories)
        {
          'id': newId(),
          'name': category.name,
          'kind': category.kind.name,
          'is_archived': false,
          'is_plan_archived': false,
          'is_plan_deleted': false,
          'plan_group': 'spending',
          'linked_account_id': null,
        },
    ],
    'transactions': <Object>[],
    'monthly_plans': <Object>[],
  },
};

/// The counts a reset leaves: only the default categories.
final freshAccountCounts = BackupCounts(
  customAccountTypes: 0,
  accounts: 0,
  categories: defaultCategories.length,
  transactions: 0,
  monthlyPlans: 0,
  customBanks: 0,
);

/// How many records the synchronized store holds, as the server counts them
/// (every downloaded row, including any the web app hides).
Stream<BackupCounts> watchSyncedCounts(SyncedDatabase database) => database
    .customSelect(
      'SELECT '
      '(SELECT count(*) FROM custom_account_types) AS custom_account_types, '
      '(SELECT count(*) FROM accounts) AS accounts, '
      '(SELECT count(*) FROM categories) AS categories, '
      '(SELECT count(*) FROM transactions) AS transactions, '
      '(SELECT count(*) FROM monthly_plans) AS monthly_plans, '
      '(SELECT count(*) FROM custom_banks) AS custom_banks',
      readsFrom: {
        database.syncedCustomAccountTypes,
        database.syncedCustomBanks,
        database.syncedAccounts,
        database.syncedCategories,
        database.syncedTransactions,
        database.syncedMonthlyPlans,
      },
    )
    .watchSingle()
    .map(
      (row) => BackupCounts(
        customAccountTypes: row.read<int>('custom_account_types'),
        accounts: row.read<int>('accounts'),
        categories: row.read<int>('categories'),
        transactions: row.read<int>('transactions'),
        monthlyPlans: row.read<int>('monthly_plans'),
        customBanks: row.read<int>('custom_banks'),
      ),
    );

/// Resets the active space (shared spaces C2, Decision C2-8); `null` while
/// signed out or in a build without the cloud configuration.
final cloudDataResetterProvider = Provider<CloudDataResetter?>((ref) {
  final identity = ref.watch(authIdentityProvider);
  final importDataset = ref.watch(importDatasetProvider);
  final store = ref.watch(syncedStoreProvider);
  if (identity is! SignedIn || importDataset == null || store == null) {
    return null;
  }
  return CloudDataResetter(
    importDataset: importDataset,
    userId: identity.userId,
    spaceId: store.spaceId,
  );
});
