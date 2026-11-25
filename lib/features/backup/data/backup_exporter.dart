import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/synced_store.dart';
import 'backup_source.dart';
import 'synced_backup_source.dart';

/// What a backup file is for; only its name differs.
enum BackupFileKind {
  /// An ordinary backup from Export backup.
  backup,

  /// The export required before Reset all data.
  resetCheckpoint,

  /// The export of the account required before replacing its data with
  /// this device's (cloud sync S6.2).
  replaceCheckpoint,
}

/// A backup ready to save or share: a file name and its JSON text.
@immutable
final class BackupFile {
  const BackupFile({required this.fileName, required this.contents});

  final String fileName;
  final String contents;
}

/// Builds a JSON backup of everything the user has recorded.
///
/// The format is the contract an import reads, so field names are written out
/// here rather than taken from the database columns. Money is in integer
/// minor units, transaction dates are `YYYY-MM-DD`, plan months are `YYYY-MM`
/// and timestamps are UTC ISO-8601. IDs are kept so references between
/// records survive. Balances and totals are left out: they are always derived
/// from the opening balances and transactions.
///
/// Every ID is written as text (format 7): the signed-out database's integers
/// as decimal strings, a signed-in account's UUIDs as they are. Bump
/// [formatVersion] whenever the shape of the backup changes.
class BackupExporter {
  /// Exports this device's signed-out [database].
  BackupExporter(AppDatabase database, {DateTime Function()? clock})
    : this.from(LocalBackupSource(database), clock: clock);

  /// Exports the records [source] reads.
  BackupExporter.from(this._source, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  /// Version of the backup format, independent of the database schema.
  /// 2 added `planGroup` to categories; 3 added `isBudgetAccount` to
  /// accounts. Format 4 adds category `linkedAccountId`; 5 adds
  /// `isPlanArchived`; 6 adds `isPlanDeleted`; 7 writes every ID and
  /// reference as text (cloud sync S6, Decision 6); 8 adds category
  /// `defaultTargetMinor`; 9 adds `customBanks` and account `bankKey` and
  /// `customBankId` (docs/BANKS_PLAN.md); 10 allows a Spending with no
  /// `categoryId` when paid from a Credit account (R.18), so older apps
  /// refuse such a file as too new rather than as invalid.
  static const int formatVersion = 10;

  final BackupSource _source;
  final DateTime Function() _now;

  /// The backup as a JSON-ready map, from one consistent snapshot.
  Future<Map<String, Object?>> export() async {
    final records = await _source.read();
    return {
      'app': 'fundly',
      'formatVersion': formatVersion,
      'schemaVersion': _source.schemaVersion,
      'exportedAt': _timestamp(_now()),
      'customAccountTypes': [
        for (final type in records.customAccountTypes)
          {
            'id': _id(type.id),
            'name': type.name,
            'baseType': type.baseType,
            'createdAt': _timestamp(type.createdAt),
          },
      ],
      'customBanks': [
        for (final bank in records.customBanks)
          {
            'id': _id(bank.id),
            'name': bank.name,
            'createdAt': _timestamp(bank.createdAt),
          },
      ],
      'accounts': [
        for (final account in records.accounts)
          {
            'id': _id(account.id),
            'name': account.name,
            'type': account.type,
            'customTypeId': _id(account.customTypeId),
            'openingBalanceMinor': account.openingBalanceMinor,
            'currencyCode': account.currencyCode,
            'createdAt': _timestamp(account.createdAt),
            'isArchived': account.isArchived,
            'isBudgetAccount': account.isBudgetAccount,
            'bankKey': account.bankKey,
            'customBankId': _id(account.customBankId),
          },
      ],
      'categories': [
        for (final category in records.categories)
          {
            'id': _id(category.id),
            'name': category.name,
            'kind': category.kind,
            'isArchived': category.isArchived,
            'isPlanArchived': category.isPlanArchived,
            'isPlanDeleted': category.isPlanDeleted,
            'planGroup': category.planGroup,
            'linkedAccountId': _id(category.linkedAccountId),
            'defaultTargetMinor': category.defaultTargetMinor,
          },
      ],
      'transactions': [
        for (final transaction in records.transactions)
          {
            'id': _id(transaction.id),
            'type': transaction.type,
            'amountMinor': transaction.amountMinor,
            'currencyCode': transaction.currencyCode,
            'date': transaction.date,
            'payee': transaction.payee,
            'categoryId': _id(transaction.categoryId),
            'sourceAccountId': _id(transaction.sourceAccountId),
            'destinationAccountId': _id(transaction.destinationAccountId),
            'note': transaction.note,
            'createdAt': _timestamp(transaction.createdAt),
            'updatedAt': _timestamp(transaction.updatedAt),
          },
      ],
      'monthlyPlans': [
        for (final plan in records.monthlyPlans)
          {
            'id': _id(plan.id),
            'month': plan.month,
            'categoryId': _id(plan.categoryId),
            'targetAmountMinor': plan.targetAmountMinor,
            'assignedAmountMinor': plan.assignedAmountMinor,
            'currencyCode': plan.currencyCode,
            'createdAt': _timestamp(plan.createdAt),
            'updatedAt': _timestamp(plan.updatedAt),
          },
      ],
    };
  }

  /// The backup as an indented JSON file named after the local date:
  /// `fundly-backup-2026-11-17.json` for a [BackupFileKind.backup], and
  /// `2026-11-22_1430_reset_checkpoint.json` (with the local time, so several
  /// checkpoints in a day keep their order) for a
  /// [BackupFileKind.resetCheckpoint] (`_replace_checkpoint` for a
  /// [BackupFileKind.replaceCheckpoint]). The contents are the same.
  Future<BackupFile> createFile({
    BackupFileKind kind = BackupFileKind.backup,
  }) async {
    final backup = await export();
    final now = _now().toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    final date = '${now.year}-${two(now.month)}-${two(now.day)}';
    return BackupFile(
      fileName: switch (kind) {
        BackupFileKind.backup => 'fundly-backup-$date.json',
        BackupFileKind.resetCheckpoint =>
          '${date}_${two(now.hour)}${two(now.minute)}_reset_checkpoint.json',
        BackupFileKind.replaceCheckpoint =>
          '${date}_${two(now.hour)}${two(now.minute)}_replace_checkpoint.json',
      },
      contents: '${const JsonEncoder.withIndent('  ').convert(backup)}\n',
    );
  }

  /// An ID or reference as text; `null` stays `null`.
  static String? _id(Object? id) => id?.toString();

  static String _timestamp(DateTime instant) =>
      instant.toUtc().toIso8601String();
}

/// Exports the synchronized store while signed in, this device's database
/// otherwise.
final backupExporterProvider = Provider<BackupExporter>((ref) {
  final store = ref.watch(syncedStoreProvider);
  return store == null
      ? BackupExporter(ref.watch(appDatabaseProvider))
      : BackupExporter.from(SyncedBackupSource(store.database));
});
