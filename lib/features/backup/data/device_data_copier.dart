import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_name.dart';
import '../../../core/money/money.dart';
import '../../../core/sync/dataset_import.dart';
import '../../../core/sync/sync_queue.dart' show newRecordId;
import '../../../core/sync/synced_database.dart';
import '../../../core/sync/synced_store.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../../categories/data/default_categories.dart';
import 'backup_importer.dart';
import 'backup_source.dart';
import 'cloud_data_resetter.dart' show watchSyncedCounts;
import 'cloud_dataset_import.dart';
import 'dataset_request.dart';
import 'synced_backup_source.dart';

/// Reads this device's signed-out database while signed in (cloud sync
/// S6.2). That database is otherwise closed while signed in
/// (`appDatabaseProvider`), so each read opens it, reads every record in one
/// transaction and closes it again. It is never written.
class DeviceDataReader {
  DeviceDataReader(this._open);

  final AppDatabase Function() _open;
  Future<void> _previous = Future.value();

  /// Every signed-out record on this device. Reads run one at a time, so the
  /// database is never open twice.
  Future<BackupRecords> read() {
    final result = _previous.then((_) async {
      final database = _open();
      try {
        return await LocalBackupSource(database).read();
      } finally {
        await database.close();
      }
    });
    _previous = result.then<void>((_) {}, onError: (_) {});
    return result;
  }
}

final deviceDataReaderProvider = Provider<DeviceDataReader>(
  (ref) => DeviceDataReader(
    () => ref.read(databaseOpenerProvider)(localDatabaseName),
  ),
);

/// What the copy screen shows before the user chooses.
final class CopyPreview {
  const CopyPreview({
    required this.source,
    required this.account,
    required this.accountIsEmpty,
  });

  /// The records to send: this device's signed-out records as read for this
  /// preview, or a checked backup's (cloud sync S6.3).
  final BackupRecords source;

  /// The account's counts, as this device downloaded them.
  final BackupCounts account;

  /// Whether the account holds only untouched default categories, so the
  /// data can be copied without replacing anything.
  final bool accountIsEmpty;

  BackupCounts get sourceCounts => countsOf(source);
}

/// The copy the server accepted, before it is checked.
final class CopySent {
  const CopySent({required this.ids, required this.counts});

  /// The UUID each device record was sent as.
  final ImportIdMap ids;

  /// The account's counts afterwards, as the server reported them.
  final BackupCounts counts;
}

/// The result of comparing the account with this device after a copy.
final class CopyCheck {
  const CopyCheck({
    required this.difference,
    required this.sourceBalances,
    required this.accountBalances,
  });

  /// The first record and field that differs, or `null` when every record of
  /// the account matches this device's.
  final String? difference;

  /// Each account's balance in the source and in the account, by name.
  final Map<String, Money> sourceBalances;
  final Map<String, Money> accountBalances;

  bool get passed => difference == null;
}

/// The request would be larger than the server accepts.
class CopyTooLargeException implements Exception {
  const CopyTooLargeException(this.bytes);

  final int bytes;

  @override
  String toString() => 'CopyTooLargeException($bytes bytes)';
}

/// Copies this device's signed-out data into the signed-in account with
/// `fundly_import_dataset` (supabase/IMPORT_API.md), and checks the result
/// record by record (cloud sync S6.2). The device's data is only read.
class DeviceDataCopier {
  DeviceDataCopier({
    required this._import,
    required this._synced,
    required this._device,
    this._newId = newRecordId,
  });

  final CloudDatasetImport _import;
  final SyncedDatabase _synced;
  final DeviceDataReader _device;
  final String Function() _newId;

  /// Reads both sides for the preview: [backup]'s records when given,
  /// otherwise this device's.
  Future<CopyPreview> preview({BackupRecords? backup}) async {
    final source = backup ?? await _device.read();
    final account = await watchSyncedCounts(_synced).first;
    return CopyPreview(
      source: source,
      account: account,
      accountIsEmpty: await accountHoldsOnlyDefaults(_synced),
    );
  }

  /// Sends [preview]'s records: `into_empty` when the account was
  /// empty, otherwise `replace` with the counts the user confirmed. Throws
  /// [CopyTooLargeException] before sending anything too large, and
  /// [CloudImportException] when the server does not accept it.
  Future<CopySent> send(CopyPreview preview) async {
    final request = datasetRequestFor(preview.source, newId: _newId);
    final body = importRequest(
      replace: !preview.accountIsEmpty,
      dataset: request.dataset,
      expected: preview.accountIsEmpty ? null : preview.account,
    );
    final bytes = requestBytes(body);
    if (bytes > maxImportRequestBytes) throw CopyTooLargeException(bytes);
    final counts = await _import.send(body);
    return CopySent(ids: request.ids, counts: counts);
  }

  /// Waits up to [wait] for this device to download [counts], then compares
  /// every record of the account with [source] (the device records that were
  /// sent with [ids]). Returns `null` when the download did not arrive in
  /// time; the check can then run again later.
  Future<CopyCheck?> check({
    required BackupRecords source,
    required ImportIdMap ids,
    required BackupCounts counts,
    required Duration wait,
  }) async {
    try {
      await watchSyncedCounts(_synced)
          .firstWhere((current) => current == counts)
          .timeout(wait);
    } on TimeoutException {
      return null;
    }
    final copy = await SyncedBackupSource(_synced).read();
    return CopyCheck(
      difference: firstDifference(source, copy, ids),
      sourceBalances: balancesByName(source),
      accountBalances: balancesByName(copy),
    );
  }
}

/// Whether the account holds nothing but the default categories as the
/// server creates them (revision 1, no flags, no link): the server's test for
/// an `into_empty` import.
Future<bool> accountHoldsOnlyDefaults(SyncedDatabase database) async {
  final others = await database
      .customSelect(
        'SELECT (SELECT count(*) FROM custom_account_types) '
        '+ (SELECT count(*) FROM accounts) '
        '+ (SELECT count(*) FROM transactions) '
        '+ (SELECT count(*) FROM monthly_plans) AS n',
      )
      .getSingle();
  if (others.read<int>('n') > 0) return false;
  final defaults = {
    for (final category in defaultCategories)
      (category.name, category.kind.name),
  };
  final categories = await database.select(database.syncedCategories).get();
  return categories.every(
    (category) =>
        category.revision == 1 &&
        !category.isArchived &&
        !category.isPlanArchived &&
        !category.isPlanDeleted &&
        category.planGroup == 'spending' &&
        category.linkedAccountId == null &&
        defaults.contains((category.name, category.kind)),
  );
}

/// Copies this device's data into the signed-in account; `null` while signed
/// out or in a build without the cloud configuration.
final deviceDataCopierProvider = Provider<DeviceDataCopier?>((ref) {
  final identity = ref.watch(authIdentityProvider);
  final importDataset = ref.watch(importDatasetProvider);
  final store = ref.watch(syncedStoreProvider);
  if (identity is! SignedIn || importDataset == null || store == null) {
    return null;
  }
  return DeviceDataCopier(
    import: CloudDatasetImport(
      importDataset: importDataset,
      userId: identity.userId,
    ),
    synced: store.database,
    device: ref.watch(deviceDataReaderProvider),
  );
});

/// How long the copy screen waits for this device to download the copied
/// account before checking it later. Overridden in tests.
final copyCheckWaitProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 60),
);

/// Whether this device holds signed-out data worth copying into the signed-in
/// account ([hasDeviceData]). False while signed out and in builds that
/// cannot copy, where the device's database is never opened for it.
final deviceHasDataProvider = FutureProvider<bool>((ref) async {
  if (ref.watch(deviceDataCopierProvider) == null) return false;
  return hasDeviceData(await ref.watch(deviceDataReaderProvider).read());
});
