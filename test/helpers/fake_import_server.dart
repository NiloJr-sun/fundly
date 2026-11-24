import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fundly/core/sync/dataset_import.dart';
import 'package:fundly/features/backup/data/backup_exporter.dart';
import 'package:fundly/features/backup/data/backup_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'fake_synced_store.dart';

/// Plays `fundly_import_dataset` plus the download that follows: an accepted
/// request replaces every row of [store] with the imported records, in the
/// shape PowerSync downloads them (integers for money and flags, revision 1,
/// year 0000 as `0001-… BC`).
class FakeImportServer {
  FakeImportServer(this.store);

  final FakeSyncedStore store;

  /// Every request received, with its import ID.
  final requests = <({String importId, Map<String, Object?> request})>[];

  /// Thrown instead of accepting, then cleared, when set.
  Object? failNext;

  /// Whether an accepted import reaches [store] (false: the download never
  /// arrives).
  bool downloads = true;

  /// Changes a downloaded row before it is stored, to plant a difference.
  void Function(String table, Map<String, Object?> row)? tamper;

  ImportDataset get importDataset =>
      ({required userId, required importId, required request}) async {
        requests.add((importId: importId, request: request));
        final failure = failNext;
        if (failure != null) {
          failNext = null;
          throw failure;
        }
        final dataset = request['dataset']! as Map<String, Object?>;
        if (downloads) await _download(dataset);
        return {
          'version': 1,
          'import_id': importId,
          'mode': request['mode'],
          'counts': {
            for (final MapEntry(:key, :value) in dataset.entries)
              key: (value! as List<Object?>).length,
          },
        };
      };

  Future<void> _download(Map<String, Object?> dataset) async {
    final database = store.database;
    await database.transaction(() async {
      for (final table in dataset.keys) {
        await database.customUpdate(
          'DELETE FROM $table',
          updates: {
            database.allTables.singleWhere((t) => t.actualTableName == table),
          },
          updateKind: UpdateKind.delete,
        );
      }
    });
    await store.download({
      for (final MapEntry(key: table, value: rows) in dataset.entries)
        table: [
          for (final row in rows! as List<Object?>)
            _downloaded(table, row! as Map<String, Object?>),
        ],
    });
  }

  Map<String, Object?> _downloaded(String table, Map<String, Object?> wire) {
    const now = '2026-11-22T12:00:00.000Z';
    final row = <String, Object?>{
      for (final MapEntry(:key, :value) in wire.entries)
        key: switch (value) {
          final bool flag => flag ? 1 : 0,
          final String text
              when key.endsWith('_minor') &&
                  RegExp(r'^-?\d+$').hasMatch(text) =>
            int.parse(text),
          final String date when key == 'date' && date.startsWith('0000-') =>
            '0001-${date.substring(5)} BC',
          _ => value,
        },
      'revision': 1,
    };
    row['created_at'] ??= now;
    row['updated_at'] ??= row['created_at'];
    tamper?.call(table, row);
    return row;
  }
}

/// Server error [code] the way PostgREST reports a refused import.
PostgrestException importRefusal(String code) =>
    PostgrestException(message: code, code: 'P0001');

/// A test's signed-out records: one of everything, including history on
/// archived records, a linked liability row, the budget account, a
/// plan-deleted row, a year-0000 date and a plan without a Target.
BackupRecords sampleDeviceRecords() {
  final at = DateTime.utc(2026, 11, 1, 8, 30);
  return (
    customAccountTypes: [
      (id: 1, name: 'E-wallet', baseType: 'savingsCash', createdAt: at),
    ],
    accounts: [
      (
        id: 1,
        name: 'BDO Savings',
        type: 'savingsCash',
        customTypeId: null,
        openingBalanceMinor: 1500000,
        currencyCode: 'PHP',
        createdAt: at,
        isArchived: false,
        isBudgetAccount: true,
      ),
      (
        id: 2,
        name: 'GCash',
        type: 'savingsCash',
        customTypeId: 1,
        openingBalanceMinor: 0,
        currencyCode: 'PHP',
        createdAt: at,
        isArchived: false,
        isBudgetAccount: false,
      ),
      (
        id: 3,
        name: 'RCBC Credit',
        type: 'credit',
        customTypeId: null,
        openingBalanceMinor: -300000,
        currencyCode: 'PHP',
        createdAt: at,
        isArchived: false,
        isBudgetAccount: false,
      ),
      (
        id: 4,
        name: 'Old card',
        type: 'credit',
        customTypeId: null,
        openingBalanceMinor: 0,
        currencyCode: 'PHP',
        createdAt: at,
        isArchived: true,
        isBudgetAccount: false,
      ),
    ],
    categories: [
      _category(1, 'Food & Groceries'),
      _category(2, 'Salary', kind: 'inflow'),
      _category(3, 'RCBC Credit', planGroup: 'liability', linkedAccountId: 3),
      _category(
        4,
        'Old card',
        planGroup: 'liability',
        linkedAccountId: 4,
        isArchived: true,
      ),
      _category(
        5,
        'Gone',
        isArchived: true,
        isPlanArchived: true,
        isPlanDeleted: true,
        defaultTargetMinor: 500000,
      ),
    ],
    transactions: [
      _transaction(1, 'spending', 50025, categoryId: 1, sourceAccountId: 3),
      _transaction(2, 'inflow', 4000000, categoryId: 2, destinationId: 1),
      _transaction(3, 'transfer', 200000, sourceAccountId: 1, destinationId: 2),
      _transaction(
        4,
        'creditCardPayment',
        50025,
        sourceAccountId: 1,
        destinationId: 3,
      ),
      _transaction(
        5,
        'spending',
        999,
        categoryId: 5,
        sourceAccountId: 4,
        date: '0000-01-01',
      ),
    ],
    monthlyPlans: [
      (
        id: 1,
        month: '2026-11',
        categoryId: 1,
        targetAmountMinor: 800000,
        assignedAmountMinor: 600000,
        currencyCode: 'PHP',
        createdAt: at,
        updatedAt: at.add(const Duration(days: 1)),
      ),
      (
        id: 2,
        month: '2026-11',
        categoryId: 3,
        targetAmountMinor: null,
        assignedAmountMinor: 0,
        currencyCode: 'PHP',
        createdAt: at,
        updatedAt: at,
      ),
    ],
  );
}

BackupCategory _category(
  int id,
  String name, {
  String kind = 'spending',
  String planGroup = 'spending',
  int? linkedAccountId,
  bool isArchived = false,
  bool isPlanArchived = false,
  bool isPlanDeleted = false,
  int? defaultTargetMinor,
}) => (
  id: id,
  name: name,
  kind: kind,
  isArchived: isArchived,
  isPlanArchived: isPlanArchived,
  isPlanDeleted: isPlanDeleted,
  planGroup: planGroup,
  linkedAccountId: linkedAccountId,
  defaultTargetMinor: defaultTargetMinor,
);

BackupTransaction _transaction(
  int id,
  String type,
  int amountMinor, {
  int? categoryId,
  int? sourceAccountId,
  int? destinationId,
  String date = '2026-11-10',
}) => (
  id: id,
  type: type,
  amountMinor: amountMinor,
  currencyCode: 'PHP',
  date: date,
  payee: type == 'spending' || type == 'inflow' ? 'Payee $id' : '',
  categoryId: categoryId,
  sourceAccountId: sourceAccountId,
  destinationAccountId: destinationId,
  note: id.isEven ? 'Note $id' : '',
  createdAt: DateTime.utc(2026, 11, 10, 9, 0, id),
  updatedAt: DateTime.utc(2026, 11, 11, 9, 0, id, 123),
);

/// Only the defaults, as the server creates them.
List<Map<String, Object?>> serverDefaults() => [
  for (final (index, (name, kind)) in const [
    ('Rent', 'spending'),
    ('Utilities', 'spending'),
    ('Internet', 'spending'),
    ('Subscriptions', 'spending'),
    ('Food & Groceries', 'spending'),
    ('Fuel', 'spending'),
    ('Miscellaneous', 'spending'),
    ('Salary', 'inflow'),
    ('Other income', 'inflow'),
  ].indexed)
    SyncedRows.category('d$index', name, kind: kind),
];

/// Fixed records as a backup source.
class RecordsSource implements BackupSource {
  RecordsSource(this.records);

  final BackupRecords records;

  @override
  int get schemaVersion => 12;

  @override
  Future<BackupRecords> read() async => records;
}

/// [sampleDeviceRecords] exported as a backup file's JSON (format 7).
Future<Map<String, Object?>> sampleBackupJson() async => jsonDecode(
  jsonEncode(
    await BackupExporter.from(
      RecordsSource(sampleDeviceRecords()),
      clock: () => DateTime.utc(2026, 11, 17, 9),
    ).export(),
  ),
) as Map<String, Object?>;

/// [sampleBackupJson] as an old format 3 file: integer IDs, no linked
/// liability rows (the importer adds them), no Plans archive or deletion
/// flags, and no plans on rows that format 3 could not hold.
Future<Map<String, Object?>> sampleFormat3Json() async {
  final backup = await sampleBackupJson();
  const idFields = {
    'id',
    'customTypeId',
    'linkedAccountId',
    'categoryId',
    'sourceAccountId',
    'destinationAccountId',
  };
  Map<String, Object?> integers(Map<String, Object?> record) => {
    for (final MapEntry(:key, :value) in record.entries)
      if (!const {
        'linkedAccountId',
        'isPlanArchived',
        'isPlanDeleted',
      }.contains(key))
        key: idFields.contains(key) && value is String
            ? int.parse(value)
            : value,
  };
  List<Map<String, Object?>> rows(String table) => [
    for (final record in (backup[table]! as List<Object?>))
      record! as Map<String, Object?>,
  ];
  final linked = {
    for (final category in rows('categories'))
      if (category['linkedAccountId'] != null) category['id'],
  };
  final planDeleted = {
    for (final category in rows('categories'))
      if (category['isPlanDeleted'] == true) category['id'],
  };
  return {
    ...backup,
    'formatVersion': 3,
    'customAccountTypes': [
      for (final r in rows('customAccountTypes')) integers(r),
    ],
    'accounts': [for (final r in rows('accounts')) integers(r)],
    'categories': [
      for (final r in rows('categories'))
        if (!linked.contains(r['id'])) integers(r),
    ],
    'transactions': [
      for (final r in rows('transactions'))
        if (!planDeleted.contains(r['categoryId'])) integers(r),
    ],
    'monthlyPlans': [
      for (final r in rows('monthlyPlans'))
        if (!linked.contains(r['categoryId'])) integers(r),
    ],
  };
}
