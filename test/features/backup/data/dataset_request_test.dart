import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/backup/data/backup_importer.dart';
import 'package:fundly/features/backup/data/backup_source.dart';
import 'package:fundly/features/backup/data/dataset_request.dart';

import '../../../helpers/fake_import_server.dart';

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

// The server's timestamp rule (supabase/IMPORT_API.md).
final _utc = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?Z$');

/// [records] with every ID replaced through [ids], as the account holds them
/// after a copy.
BackupRecords copied(BackupRecords records, ImportIdMap ids) {
  String id(String table, Object source) => ids[table]!['$source']!;
  String? ref(String table, Object? source) =>
      source == null ? null : id(table, source);
  return (
    customAccountTypes: [
      for (final r in records.customAccountTypes)
        (
          id: id('custom_account_types', r.id),
          name: r.name,
          baseType: r.baseType,
          createdAt: r.createdAt,
        ),
    ],
    accounts: [
      for (final r in records.accounts)
        (
          id: id('accounts', r.id),
          name: r.name,
          type: r.type,
          customTypeId: ref('custom_account_types', r.customTypeId),
          openingBalanceMinor: r.openingBalanceMinor,
          currencyCode: r.currencyCode,
          // Same instant, other time zone flag: still equal.
          createdAt: r.createdAt.toLocal(),
          isArchived: r.isArchived,
          isBudgetAccount: r.isBudgetAccount,
        ),
    ],
    categories: [
      for (final r in records.categories)
        (
          id: id('categories', r.id),
          name: r.name,
          kind: r.kind,
          isArchived: r.isArchived,
          isPlanArchived: r.isPlanArchived,
          isPlanDeleted: r.isPlanDeleted,
          planGroup: r.planGroup,
          linkedAccountId: ref('accounts', r.linkedAccountId),
        ),
    ],
    transactions: [
      for (final r in records.transactions)
        (
          id: id('transactions', r.id),
          type: r.type,
          amountMinor: r.amountMinor,
          currencyCode: r.currencyCode,
          date: r.date,
          payee: r.payee,
          categoryId: ref('categories', r.categoryId),
          sourceAccountId: ref('accounts', r.sourceAccountId),
          destinationAccountId: ref('accounts', r.destinationAccountId),
          note: r.note,
          createdAt: r.createdAt,
          updatedAt: r.updatedAt,
        ),
    ],
    monthlyPlans: [
      for (final r in records.monthlyPlans)
        (
          id: id('monthly_plans', r.id),
          month: r.month,
          categoryId: id('categories', r.categoryId),
          targetAmountMinor: r.targetAmountMinor,
          assignedAmountMinor: r.assignedAmountMinor,
          currencyCode: r.currencyCode,
          createdAt: r.createdAt,
          updatedAt: r.updatedAt,
        ),
    ],
  );
}

BackupRecords withRecords(
  BackupRecords records, {
  List<BackupAccount>? accounts,
  List<BackupCategory>? categories,
  List<BackupTransaction>? transactions,
}) => (
  customAccountTypes: records.customAccountTypes,
  accounts: accounts ?? records.accounts,
  categories: categories ?? records.categories,
  transactions: transactions ?? records.transactions,
  monthlyPlans: records.monthlyPlans,
);

BackupRecords onlyCategories(List<BackupCategory> categories) => (
  customAccountTypes: const [],
  accounts: const [],
  categories: categories,
  transactions: const [],
  monthlyPlans: const [],
);

BackupCategory category(
  String name, {
  String kind = 'spending',
  bool archived = false,
  String group = 'spending',
}) => (
  id: name.hashCode,
  name: name,
  kind: kind,
  isArchived: archived,
  isPlanArchived: false,
  isPlanDeleted: false,
  planGroup: group,
  linkedAccountId: null,
);

void main() {
  final records = sampleDeviceRecords();

  group('datasetRequestFor', () {
    final request = datasetRequestFor(records);
    final dataset = request.dataset;
    List<Map<String, Object?>> rows(String table) =>
        (dataset[table]! as List<Object?>).cast<Map<String, Object?>>();

    test('gives every record a fresh UUID and keeps the map', () {
      for (final table in importTables) {
        final ids = [for (final row in rows(table)) row['id']! as String];
        expect(ids, everyElement(matches(_uuid)), reason: table);
        expect(ids.toSet(), hasLength(ids.length), reason: table);
        expect(request.ids[table]!.values.toSet(), ids.toSet(), reason: table);
      }
      expect(request.ids['accounts']!.keys, ['1', '2', '3', '4']);
      // A second request gives new IDs (cloud sync S6 Decision 5).
      expect(
        datasetRequestFor(records).ids['accounts']!['1'],
        isNot(request.ids['accounts']!['1']),
      );
    });

    test('rewrites every reference through the same map', () {
      final ids = request.ids;
      final gcash = rows('accounts')[1];
      expect(gcash['custom_type_id'], ids['custom_account_types']!['1']);
      final linked = rows('categories')[2];
      expect(linked['linked_account_id'], ids['accounts']!['3']);
      final payment = rows('transactions')[3];
      expect(payment['source_account_id'], ids['accounts']!['1']);
      expect(payment['destination_account_id'], ids['accounts']!['3']);
      expect(rows('transactions')[0]['category_id'], ids['categories']!['1']);
      expect(rows('monthly_plans')[1]['category_id'], ids['categories']!['3']);
      // No integer ID is left anywhere.
      expect(jsonEncode(dataset), isNot(contains('"id":1')));
    });

    test('writes the server wire shape', () {
      expect(rows('accounts')[2], {
        'id': request.ids['accounts']!['3'],
        'name': 'RCBC Credit',
        'type': 'credit',
        'opening_balance_minor': '-300000',
        'currency_code': 'PHP',
        'is_archived': false,
        'custom_type_id': null,
        'is_budget_account': false,
        'created_at': '2026-11-01T08:30:00.000Z',
      });
      expect(rows('transactions')[4]['date'], '0000-01-01');
      expect(rows('transactions')[0]['amount_minor'], '50025');
      expect(rows('monthly_plans')[1]['target_amount_minor'], isNull);
      expect(rows('monthly_plans')[0]['assigned_amount_minor'], '600000');
      expect(rows('categories')[4], containsPair('is_plan_deleted', true));
      // Backups keep no category timestamps: the server sets them.
      expect(rows('categories')[0].containsKey('created_at'), isFalse);
      for (final table in importTables) {
        for (final row in rows(table)) {
          for (final key in ['created_at', 'updated_at']) {
            if (row.containsKey(key)) {
              expect(row[key], matches(_utc), reason: '$table.$key');
            }
          }
        }
      }
    });

    test('a whole request names its mode and, to replace, the counts', () {
      expect(importRequest(replace: false, dataset: dataset), {
        'version': 1,
        'mode': 'into_empty',
        'dataset': dataset,
      });
      const seen = BackupCounts(
        customAccountTypes: 0,
        accounts: 2,
        categories: 9,
        transactions: 3,
        monthlyPlans: 0,
      );
      final replace = importRequest(
        replace: true,
        dataset: dataset,
        expected: seen,
      );
      expect(replace['mode'], 'replace');
      expect(replace['expected'], {
        'custom_account_types': 0,
        'accounts': 2,
        'categories': 9,
        'transactions': 3,
        'monthly_plans': 0,
      });
      expect(requestBytes(replace), greaterThan(1000));
    });
  });

  group('hasDeviceData', () {
    test('untouched default categories are not data', () {
      expect(
        hasDeviceData(
          onlyCategories([
            category('Rent'),
            category('Salary', kind: 'inflow'),
          ]),
        ),
        isFalse,
      );
      // An older install's defaults count as defaults too.
      expect(
        hasDeviceData(onlyCategories([category('Food'), category('Other')])),
        isFalse,
      );
    });

    test('a changed default or any other record is data', () {
      expect(hasDeviceData(onlyCategories([category('Housing')])), isTrue);
      expect(
        hasDeviceData(onlyCategories([category('Rent', archived: true)])),
        isTrue,
      );
      expect(
        hasDeviceData(onlyCategories([category('Rent', group: 'savings')])),
        isTrue,
      );
      expect(
        hasDeviceData(onlyCategories([category('Rent', kind: 'inflow')])),
        isTrue,
      );
      expect(hasDeviceData(records), isTrue);
    });
  });

  group('firstDifference', () {
    final request = datasetRequestFor(records);
    final ids = request.ids;

    test('is null when every record and field matches', () {
      expect(firstDifference(records, copied(records, ids), ids), isNull);
    });

    test('names the record and the field that differ', () {
      final copy = copied(records, ids);
      final changed = withRecords(
        copy,
        transactions: [
          for (final t in copy.transactions)
            t.id == ids['transactions']!['3']
                ? (
                    id: t.id,
                    type: t.type,
                    amountMinor: t.amountMinor + 1,
                    currencyCode: t.currencyCode,
                    date: t.date,
                    payee: t.payee,
                    categoryId: t.categoryId,
                    sourceAccountId: t.sourceAccountId,
                    destinationAccountId: t.destinationAccountId,
                    note: t.note,
                    createdAt: t.createdAt,
                    updatedAt: t.updatedAt,
                  )
                : t,
        ],
      );
      expect(
        firstDifference(records, changed, ids),
        'transactions 3: amountMinor',
      );
    });

    test('finds a wrong reference, a missing record and an extra one', () {
      final copy = copied(records, ids);
      final relinked = withRecords(
        copy,
        categories: [
          for (final c in copy.categories)
            c.linkedAccountId == null
                ? c
                : (
                    id: c.id,
                    name: c.name,
                    kind: c.kind,
                    isArchived: c.isArchived,
                    isPlanArchived: c.isPlanArchived,
                    isPlanDeleted: c.isPlanDeleted,
                    planGroup: c.planGroup,
                    linkedAccountId: ids['accounts']!['1'],
                  ),
        ],
      );
      expect(
        firstDifference(records, relinked, ids),
        'categories 3: linkedAccountId',
      );
      final missing = withRecords(copy, accounts: copy.accounts.sublist(1));
      expect(firstDifference(records, missing, ids), 'accounts 1: missing');
      final extra = withRecords(
        copy,
        categories: [...copy.categories, category('Surprise')],
      );
      expect(firstDifference(records, extra, ids), 'categories: 1 unexpected');
    });
  });

  test('balancesByName uses the ledger rules', () {
    Money php(int minor) => Money(minorUnits: minor, currencyCode: 'PHP');
    expect(balancesByName(records), {
      // Opening + inflow - transfer - card payment.
      'BDO Savings': php(1500000 + 4000000 - 200000 - 50025),
      'GCash': php(200000),
      // Owed: opening - purchase + payment.
      'RCBC Credit': php(-300000 - 50025 + 50025),
      'Old card': php(-999),
    });
  });
}
