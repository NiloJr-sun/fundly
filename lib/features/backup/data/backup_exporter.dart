import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';

/// What a backup file is for; only its name differs.
enum BackupFileKind {
  /// An ordinary backup from Export backup.
  backup,

  /// The export required before Reset all data.
  resetCheckpoint,
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
/// The format is the contract a future import will read, so field names are
/// written out here rather than taken from the database columns. Money is in
/// integer minor units, transaction dates are `YYYY-MM-DD`, plan months are
/// `YYYY-MM` and timestamps are UTC ISO-8601. IDs are kept so references
/// between records survive. Balances and totals are left out: they are
/// always derived from the opening balances and transactions.
///
/// Bump [formatVersion] whenever the shape of the backup changes.
class BackupExporter {
  BackupExporter(this._database, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  /// Version of the backup format, independent of the database schema.
  /// 2 added `planGroup` to categories; 3 added `isBudgetAccount` to
  /// accounts. Format 4 adds category `linkedAccountId`; 5 adds `isPlanArchived`;
  /// 6 adds `isPlanDeleted`.
  static const int formatVersion = 6;

  final AppDatabase _database;
  final DateTime Function() _now;

  /// The backup as a JSON-ready map, read in one transaction so it is a
  /// consistent snapshot.
  Future<Map<String, Object?>> export() => _database.transaction(() async {
    final customTypes = await _all(_database.customAccountTypes);
    final accounts = await _all(_database.accounts);
    final categories = await _all(_database.categories);
    final transactions = await _all(_database.transactions);
    final plans = await _all(_database.monthlyPlans);
    return {
      'app': 'fundly',
      'formatVersion': formatVersion,
      'schemaVersion': _database.schemaVersion,
      'exportedAt': _timestamp(_now()),
      'customAccountTypes': [
        for (final type in customTypes)
          {
            'id': type.id,
            'name': type.name,
            'baseType': type.baseType.name,
            'createdAt': _timestamp(type.createdAt),
          },
      ],
      'accounts': [
        for (final account in accounts)
          {
            'id': account.id,
            'name': account.name,
            'type': account.type.name,
            'customTypeId': account.customTypeId,
            'openingBalanceMinor': account.openingBalanceMinor,
            'currencyCode': account.currencyCode,
            'createdAt': _timestamp(account.createdAt),
            'isArchived': account.isArchived,
            'isBudgetAccount': account.isBudgetAccount,
          },
      ],
      'categories': [
        for (final category in categories)
          {
            'id': category.id,
            'name': category.name,
            'kind': category.kind.name,
            'isArchived': category.isArchived,
            'isPlanArchived': category.isPlanArchived,
            'isPlanDeleted': category.isPlanDeleted,
            'planGroup': category.planGroup.name,
            'linkedAccountId': category.linkedAccountId,
          },
      ],
      'transactions': [
        for (final transaction in transactions)
          {
            'id': transaction.id,
            'type': transaction.type.name,
            'amountMinor': transaction.amountMinor,
            'currencyCode': transaction.currencyCode,
            'date': transaction.date.toIsoString(),
            'payee': transaction.payee,
            'categoryId': transaction.categoryId,
            'sourceAccountId': transaction.sourceAccountId,
            'destinationAccountId': transaction.destinationAccountId,
            'note': transaction.note,
            'createdAt': _timestamp(transaction.createdAt),
            'updatedAt': _timestamp(transaction.updatedAt),
          },
      ],
      'monthlyPlans': [
        for (final plan in plans)
          {
            'id': plan.id,
            'month': plan.month.toIsoString(),
            'categoryId': plan.categoryId,
            'targetAmountMinor': plan.targetAmountMinor,
            'assignedAmountMinor': plan.assignedAmountMinor,
            'currencyCode': plan.currencyCode,
            'createdAt': _timestamp(plan.createdAt),
            'updatedAt': _timestamp(plan.updatedAt),
          },
      ],
    };
  });

  /// The backup as an indented JSON file named after the local date:
  /// `fundly-backup-2026-11-17.json` for a [BackupFileKind.backup], and
  /// `2026-11-22_1430_reset_checkpoint.json` (with the local time, so several
  /// checkpoints in a day keep their order) for a
  /// [BackupFileKind.resetCheckpoint]. The contents are the same.
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
      },
      contents: '${const JsonEncoder.withIndent('  ').convert(backup)}\n',
    );
  }

  /// Every row of [table], in id order.
  Future<List<Row>> _all<T extends HasResultSet, Row>(
    ResultSetImplementation<T, Row> table,
  ) {
    final query = _database.select(
      table,
    )..orderBy([(_) => OrderingTerm(expression: const CustomExpression('id'))]);
    return query.get();
  }

  static String _timestamp(DateTime instant) =>
      instant.toUtc().toIso8601String();
}

final backupExporterProvider = Provider<BackupExporter>(
  (ref) => BackupExporter(ref.watch(appDatabaseProvider)),
);
