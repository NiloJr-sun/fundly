import 'dart:convert';

import '../../../core/money/money.dart';
import '../../../core/sync/sync_queue.dart' show newRecordId;
import '../../../core/time/calendar_date.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/account_balance.dart';
import '../../accounts/domain/account_type.dart';
import '../../categories/data/default_categories.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';
import 'backup_importer.dart';
import 'backup_source.dart';

/// The largest request `fundly_import_dataset` accepts (8 MiB of JSON,
/// supabase/IMPORT_API.md).
const maxImportRequestBytes = 8388608;

/// The tables of an import, in the server's names. `custom_banks` since the
/// banks migration (supabase/IMPORT_API.md).
const importTables = [
  'custom_account_types',
  'custom_banks',
  'accounts',
  'categories',
  'transactions',
  'monthly_plans',
];

/// For each table, the UUID every source record was sent as, keyed by the
/// source ID written as text (`'12'` for a signed-out record).
typedef ImportIdMap = Map<String, Map<String, String>>;

/// A device's records ready for `fundly_import_dataset`.
final class DatasetRequest {
  const DatasetRequest._(this.dataset, this.ids);

  /// The `dataset` part of the request, in the server's wire shape.
  final Map<String, Object?> dataset;

  /// The UUID each source record was given, used to check the copy.
  final ImportIdMap ids;
}

/// Gives every record in [records] a fresh UUID from [newId] (cloud sync S6
/// Decision 5), rewrites every reference to match, and writes the records in
/// the server's wire shape: snake_case, money as decimal strings, UTC
/// timestamps. Timestamps a backup does not keep are left to the server.
DatasetRequest datasetRequestFor(
  BackupRecords records, {
  String Function() newId = newRecordId,
}) {
  final ids = <String, Map<String, String>>{
    for (final table in importTables) table: {},
  };
  String id(String table, Object source) =>
      ids[table]!.putIfAbsent('$source', newId);
  String? ref(String table, Object? source) =>
      source == null ? null : id(table, source);

  // Accounts first, so linked rows and transactions can refer to them.
  final types = [
    for (final type in records.customAccountTypes)
      {
        'id': id('custom_account_types', type.id),
        'name': type.name,
        'base_type': type.baseType,
        'created_at': _timestamp(type.createdAt),
      },
  ];
  final banks = [
    for (final bank in records.customBanks)
      {
        'id': id('custom_banks', bank.id),
        'name': bank.name,
        'created_at': _timestamp(bank.createdAt),
      },
  ];
  final accounts = [
    for (final account in records.accounts)
      {
        'id': id('accounts', account.id),
        'name': account.name,
        'type': account.type,
        'opening_balance_minor': '${account.openingBalanceMinor}',
        'currency_code': account.currencyCode,
        'is_archived': account.isArchived,
        'custom_type_id': ref('custom_account_types', account.customTypeId),
        'is_budget_account': account.isBudgetAccount,
        'created_at': _timestamp(account.createdAt),
        // Sent only when set, so an account without a bank is unchanged.
        'bank_key': ?account.bankKey,
        if (account.customBankId case final bank?)
          'custom_bank_id': id('custom_banks', bank),
      },
  ];
  final categories = [
    for (final category in records.categories)
      {
        'id': id('categories', category.id),
        'name': category.name,
        'kind': category.kind,
        'is_archived': category.isArchived,
        'is_plan_archived': category.isPlanArchived,
        'is_plan_deleted': category.isPlanDeleted,
        'plan_group': category.planGroup,
        'linked_account_id': ref('accounts', category.linkedAccountId),
        // Sent only when set, so a request without one is unchanged.
        if (category.defaultTargetMinor case final target?)
          'default_target_minor': '$target',
      },
  ];
  final transactions = [
    for (final transaction in records.transactions)
      {
        'id': id('transactions', transaction.id),
        'type': transaction.type,
        'amount_minor': '${transaction.amountMinor}',
        'currency_code': transaction.currencyCode,
        'date': transaction.date,
        'payee': transaction.payee,
        'category_id': ref('categories', transaction.categoryId),
        'source_account_id': ref('accounts', transaction.sourceAccountId),
        'destination_account_id': ref(
          'accounts',
          transaction.destinationAccountId,
        ),
        'note': transaction.note,
        'created_at': _timestamp(transaction.createdAt),
        'updated_at': _timestamp(transaction.updatedAt),
      },
  ];
  final plans = [
    for (final plan in records.monthlyPlans)
      {
        'id': id('monthly_plans', plan.id),
        'month': plan.month,
        'category_id': id('categories', plan.categoryId),
        'target_amount_minor': plan.targetAmountMinor?.toString(),
        'assigned_amount_minor': '${plan.assignedAmountMinor}',
        'currency_code': plan.currencyCode,
        'created_at': _timestamp(plan.createdAt),
        'updated_at': _timestamp(plan.updatedAt),
      },
  ];
  return DatasetRequest._({
    'custom_account_types': types,
    'custom_banks': banks,
    'accounts': accounts,
    'categories': categories,
    'transactions': transactions,
    'monthly_plans': plans,
  }, ids);
}

/// A whole `fundly_import_dataset` request. [expected] is required for
/// `replace`: the account counts the user confirmed.
Map<String, Object?> importRequest({
  required bool replace,
  required Map<String, Object?> dataset,
  BackupCounts? expected,
}) => {
  'version': 1,
  'mode': replace ? 'replace' : 'into_empty',
  if (expected != null) 'expected': countsJson(expected),
  'dataset': dataset,
};

/// [counts] in the server's table names.
Map<String, int> countsJson(BackupCounts counts) => {
  'custom_account_types': counts.customAccountTypes,
  'accounts': counts.accounts,
  'categories': counts.categories,
  'transactions': counts.transactions,
  'monthly_plans': counts.monthlyPlans,
  'custom_banks': counts.customBanks,
};

/// The size of [request] as the server measures it (UTF-8 JSON).
int requestBytes(Map<String, Object?> request) =>
    utf8.encode(jsonEncode(request)).length;

/// How many records of each kind [records] holds.
BackupCounts countsOf(BackupRecords records) => BackupCounts(
  customAccountTypes: records.customAccountTypes.length,
  accounts: records.accounts.length,
  categories: records.categories.length,
  transactions: records.transactions.length,
  monthlyPlans: records.monthlyPlans.length,
  customBanks: records.customBanks.length,
);

final _defaultNames = {
  for (final category in [...defaultCategories, ...legacyDefaultCategories])
    (category.name, category.kind.name),
};

/// Whether [records] hold anything worth copying: any record besides
/// default categories that were never changed (renamed, archived, regrouped
/// or linked). Both the current and the original default lists count, since
/// older installs started with the original one.
bool hasDeviceData(BackupRecords records) =>
    records.customAccountTypes.isNotEmpty ||
    records.customBanks.isNotEmpty ||
    records.accounts.isNotEmpty ||
    records.transactions.isNotEmpty ||
    records.monthlyPlans.isNotEmpty ||
    records.categories.any(
      (category) =>
          category.isArchived ||
          category.isPlanArchived ||
          category.isPlanDeleted ||
          category.planGroup != 'spending' ||
          category.linkedAccountId != null ||
          category.defaultTargetMinor != null ||
          !_defaultNames.contains((category.name, category.kind)),
    );

/// The first way [copy] (records read back from the account, with UUID IDs)
/// differs from [source] (the device's records sent with [ids]), or `null`
/// when every record and every field is the same. For example
/// `transactions 12: amountMinor`.
String? firstDifference(
  BackupRecords source,
  BackupRecords copy,
  ImportIdMap ids,
) {
  String? mapped(String table, Object? id) =>
      id == null ? null : ids[table]?['$id'];
  final tables = {
    'custom_account_types': (
      source: [
        for (final r in source.customAccountTypes) _customType(r, mapped),
      ],
      copy: [for (final r in copy.customAccountTypes) _customType(r, _same)],
    ),
    'custom_banks': (
      source: [for (final r in source.customBanks) _customBank(r, mapped)],
      copy: [for (final r in copy.customBanks) _customBank(r, _same)],
    ),
    'accounts': (
      source: [for (final r in source.accounts) _account(r, mapped)],
      copy: [for (final r in copy.accounts) _account(r, _same)],
    ),
    'categories': (
      source: [for (final r in source.categories) _category(r, mapped)],
      copy: [for (final r in copy.categories) _category(r, _same)],
    ),
    'transactions': (
      source: [for (final r in source.transactions) _transaction(r, mapped)],
      copy: [for (final r in copy.transactions) _transaction(r, _same)],
    ),
    'monthly_plans': (
      source: [for (final r in source.monthlyPlans) _plan(r, mapped)],
      copy: [for (final r in copy.monthlyPlans) _plan(r, _same)],
    ),
  };
  for (final MapEntry(key: table, value: (:source, :copy)) in tables.entries) {
    final copied = {for (final record in copy) record['id']: record};
    final sourceIdOf = {
      for (final MapEntry(:key, :value) in (ids[table] ?? const {}).entries)
        value: key,
    };
    for (final record in source) {
      final match = copied.remove(record['id']);
      final original = sourceIdOf[record['id']] ?? '?';
      if (match == null) return '$table $original: missing';
      for (final field in record.keys) {
        if (record[field] != match[field]) return '$table $original: $field';
      }
    }
    if (copied.isNotEmpty) return '$table: ${copied.length} unexpected';
  }
  return null;
}

/// Each account's balance in [records] by name, from [balancesFor], in the
/// records' order.
Map<String, Money> balancesByName(BackupRecords records) {
  final accounts = [
    for (final account in records.accounts)
      Account(
        id: '${account.id}',
        name: account.name,
        type: AccountType.values.byName(account.type),
        openingBalance: Money(
          minorUnits: account.openingBalanceMinor,
          currencyCode: account.currencyCode,
        ),
        createdAt: account.createdAt,
        isArchived: account.isArchived,
      ),
  ];
  final balances = balancesFor(accounts, [
    for (final transaction in records.transactions)
      TransactionDraft(
        type: TransactionType.values.byName(transaction.type),
        amount: Money(
          minorUnits: transaction.amountMinor,
          currencyCode: transaction.currencyCode,
        ),
        date: CalendarDate.parse(transaction.date),
        payee: transaction.payee,
        categoryId: _text(transaction.categoryId),
        sourceAccountId: _text(transaction.sourceAccountId),
        destinationAccountId: _text(transaction.destinationAccountId),
        note: transaction.note,
      ),
  ]);
  return {for (final account in accounts) account.name: balances[account.id]!};
}

String? _text(Object? id) => id?.toString();

String _timestamp(DateTime instant) => instant.toUtc().toIso8601String();

typedef _Ref = String? Function(String table, Object? id);

String? _same(String table, Object? id) => id?.toString();

// One map per record, with IDs through [ref] and instants as microseconds
// (a DateTime's == also compares its time zone flag).

Map<String, Object?> _customType(BackupCustomType r, _Ref ref) => {
  'id': ref('custom_account_types', r.id),
  'name': r.name,
  'baseType': r.baseType,
  'createdAt': r.createdAt.microsecondsSinceEpoch,
};

Map<String, Object?> _customBank(BackupCustomBank r, _Ref ref) => {
  'id': ref('custom_banks', r.id),
  'name': r.name,
  'createdAt': r.createdAt.microsecondsSinceEpoch,
};

Map<String, Object?> _account(BackupAccount r, _Ref ref) => {
  'id': ref('accounts', r.id),
  'name': r.name,
  'type': r.type,
  'customTypeId': ref('custom_account_types', r.customTypeId),
  'openingBalanceMinor': r.openingBalanceMinor,
  'currencyCode': r.currencyCode,
  'createdAt': r.createdAt.microsecondsSinceEpoch,
  'isArchived': r.isArchived,
  'isBudgetAccount': r.isBudgetAccount,
  'bankKey': r.bankKey,
  'customBankId': ref('custom_banks', r.customBankId),
};

Map<String, Object?> _category(BackupCategory r, _Ref ref) => {
  'id': ref('categories', r.id),
  'name': r.name,
  'kind': r.kind,
  'isArchived': r.isArchived,
  'isPlanArchived': r.isPlanArchived,
  'isPlanDeleted': r.isPlanDeleted,
  'planGroup': r.planGroup,
  'linkedAccountId': ref('accounts', r.linkedAccountId),
  'defaultTargetMinor': r.defaultTargetMinor,
};

Map<String, Object?> _transaction(BackupTransaction r, _Ref ref) => {
  'id': ref('transactions', r.id),
  'type': r.type,
  'amountMinor': r.amountMinor,
  'currencyCode': r.currencyCode,
  'date': r.date,
  'payee': r.payee,
  'categoryId': ref('categories', r.categoryId),
  'sourceAccountId': ref('accounts', r.sourceAccountId),
  'destinationAccountId': ref('accounts', r.destinationAccountId),
  'note': r.note,
  'createdAt': r.createdAt.microsecondsSinceEpoch,
  'updatedAt': r.updatedAt.microsecondsSinceEpoch,
};

Map<String, Object?> _plan(BackupPlan r, _Ref ref) => {
  'id': ref('monthly_plans', r.id),
  'month': r.month,
  'categoryId': ref('categories', r.categoryId),
  'targetAmountMinor': r.targetAmountMinor,
  'assignedAmountMinor': r.assignedAmountMinor,
  'currencyCode': r.currencyCode,
  'createdAt': r.createdAt.microsecondsSinceEpoch,
  'updatedAt': r.updatedAt.microsecondsSinceEpoch,
};
