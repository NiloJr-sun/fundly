import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/sync/sync_rejections.dart';
import 'package:fundly/features/sync/presentation/refused_change_description.dart';

const account = '00000000-0000-4000-8000-00000000000a';
const category = '00000000-0000-4000-8000-00000000000c';
const record = '00000000-0000-4000-8000-000000000001';

SyncRejection rejection(
  List<Map<String, Object?>> items, {
  String? code = 'revision_conflict',
  RejectionKind kind = RejectionKind.rejected,
  Map<String, String> labels = const {},
}) => SyncRejection(
  batchId: 'b',
  kind: kind,
  code: kind == RejectionKind.rejected ? code : null,
  items: items,
  labels: labels,
  rejectedAt: DateTime.utc(2026, 11, 22),
);

Map<String, Object?> item(
  String operation, [
  Map<String, Object?>? data,
  String id = record,
]) => {'operation': operation, 'id': id, 'data': ?data};

void main() {
  test('an edited transaction shows what was entered', () {
    final description = describeRefusedChange(
      rejection(
        [
          item('transaction.update', {
            'amount_minor': '25000',
            'currency_code': 'PHP',
            'date': '2026-11-20',
            'payee': 'Jollibee',
            'note': '',
            'category_id': category,
            'source_account_id': account,
            'destination_account_id': null,
          }),
        ],
        labels: {record: 'Jollibee', account: 'BDO Savings'},
      ),
    );

    expect(description.title, 'Edit transaction · Jollibee');
    expect(description.reason, 'Changed on another device first');
    expect(description.details, [
      ('Amount', '₱250.00'),
      ('Date', 'Nov 20, 2026'),
      ('Payee', 'Jollibee'),
      ('Category', 'A record no longer on this device'),
      ('From', 'BDO Savings'),
      ('To', 'None'),
    ]);
  });

  group('a refused delete is named (F.1)', () {
    test('by its label, with no details', () {
      final description = describeRefusedChange(
        rejection([item('transaction.delete')], labels: {record: 'Edit'}),
      );
      expect(description.title, 'Delete transaction · Edit');
      expect(description.details, isEmpty);
    });

    test('by type, amount and date without a payee', () {
      final description = describeRefusedChange(
        rejection(
          [item('transaction.delete')],
          labels: {
            '$record$transactionFactsSuffix': 'transfer|260000|PHP|2026-11-10',
          },
        ),
      );
      expect(
        description.title,
        'Delete transaction · Transfer ₱2,600.00 · Nov 10, 2026',
      );
      expect(description.details, isEmpty);
    });
  });

  test('an edit without a payee is named by type, amount and date', () {
    final description = describeRefusedChange(
      rejection(
        [
          item('transaction.update', {
            'amount_minor': '300000',
            'currency_code': 'PHP',
            'date': '2026-11-12',
            'payee': '',
            'note': '',
            'category_id': null,
            'source_account_id': account,
            'destination_account_id': category,
          }),
        ],
        labels: {
          '$record$transactionFactsSuffix':
              'creditCardPayment|300000|PHP|2026-11-12',
        },
      ),
    );
    expect(
      description.title,
      'Edit transaction · Credit card payment ₱3,000.00 · Nov 12, 2026',
    );
  });

  test('facts that cannot be read leave the title plain', () {
    for (final facts in [
      'transfer|abc|PHP|2026-11-10',
      'unknown|1|PHP|2026-11-10',
    ]) {
      final description = describeRefusedChange(
        rejection(
          [item('transaction.delete')],
          labels: {'$record$transactionFactsSuffix': facts},
        ),
      );
      expect(description.title, 'Delete transaction');
    }
  });

  test('a created record is named from its own data', () {
    expect(
      describeRefusedChange(
        rejection([
          item('account.create', {
            'name': 'BPI Savings',
            'type': 'savingsCash',
            'entered_opening_amount_minor': '100000',
            'currency_code': 'PHP',
            'custom_type_id': null,
          }),
        ], code: 'name_taken'),
      ),
      isA<RefusedChangeDescription>()
          .having((d) => d.title, 'title', 'Add account · BPI Savings')
          .having(
            (d) => d.reason,
            'reason',
            'The name is already used, possibly added on another device',
          )
          .having((d) => d.details, 'details', [
            ('Name', 'BPI Savings'),
            ('Type', 'Savings / Cash'),
            ('Opening balance', '₱1,000.00'),
            ('Account type', 'None'),
          ]),
    );
    expect(
      describeRefusedChange(
        rejection([
          item('transaction.create', {
            'type': 'creditCardPayment',
            'amount_minor': '300000',
            'currency_code': 'PHP',
            'date': '2026-11-20',
            'payee': '',
            'note': 'November bill',
          }),
        ]),
      ).details,
      [
        ('Type', 'Credit card payment'),
        ('Amount', '₱3,000.00'),
        ('Date', 'Nov 20, 2026'),
        ('Note', 'November bill'),
      ],
    );
  });

  test('a plan is named after its category', () {
    final description = describeRefusedChange(
      rejection(
        [
          item('plan.save', {
            'category_id': category,
            'month': '2026-11',
            'target_amount_minor': null,
            'assigned_amount_minor': '500000',
            'previous': {'id': record, 'revision': '2'},
          }),
        ],
        code: 'plan_conflict',
        labels: {category: 'Fuel'},
      ),
    );
    expect(description.title, 'Save plan · Fuel');
    expect(description.details, [
      ('Category', 'Fuel'),
      ('Month', 'November 2026'),
      ('Target', 'None'),
      ('Assigned', '₱5,000.00'),
    ]);
  });

  test('every operation has a title', () {
    String title(String operation, [Map<String, Object?>? data]) =>
        describeRefusedChange(rejection([item(operation, data)])).title;

    expect(title('transaction.create'), 'Add transaction');
    expect(title('transaction.delete'), 'Delete transaction');
    expect(title('account.update'), 'Edit account');
    expect(
      title('account.set_archived', {'archived': true}),
      'Archive account',
    );
    expect(
      title('account.set_archived', {'archived': false}),
      'Unarchive account',
    );
    expect(title('account.delete'), 'Delete account');
    expect(title('account.set_budget'), 'Use as budget account');
    expect(title('account.clear_budget'), 'Stop using as budget account');
    expect(title('custom_type.create'), 'Add account type');
    expect(title('custom_type.update'), 'Edit account type');
    expect(title('custom_type.delete'), 'Delete account type');
    expect(title('category.create'), 'Add category');
    expect(title('category.update'), 'Edit category');
    expect(
      title('category.set_archived', {'archived': true}),
      'Archive category',
    );
    expect(title('category.delete'), 'Delete category');
    expect(title('plan.set_archived', {'archived': true}), 'Archive plan');
    expect(title('plan.set_archived', {'archived': false}), 'Unarchive plan');
    expect(title('plan.delete_permanently'), 'Delete plan permanently');
    expect(title('dataset.initialize'), 'Add default categories');
    expect(title('something.new'), 'something.new');
  });

  test('a batch of several items says how many more', () {
    expect(
      describeRefusedChange(
        rejection([item('account.delete'), item('category.delete')]),
      ).title,
      'Delete account (+1 more)',
    );
  });

  test('every reason is in plain words', () {
    String reason(
      String? code, {
      RejectionKind kind = RejectionKind.rejected,
    }) => refusalReason(rejection(const [], code: code, kind: kind));

    expect(
      reason(null, kind: RejectionKind.dependencyRejected),
      'It relied on another change that was refused',
    );
    for (final code in [
      'revision_conflict',
      'plan_conflict',
      'budget_conflict',
    ]) {
      expect(reason(code), 'Changed on another device first');
    }
    expect(reason('record_deleted'), 'Deleted on another device');
    // Shared spaces (C3).
    expect(
      reason('not_space_member'),
      "You're no longer a member of this space",
    );
    expect(
      reason('space_read_only'),
      'View only: your role in this space cannot change it',
    );
    expect(
      reason('space_owner_only'),
      'Only an owner of this space can do this',
    );
    expect(reason('record_not_accessible'), 'The record no longer exists');
    for (final code in [
      'category_in_use',
      'custom_type_in_use',
      'account_has_transactions',
    ]) {
      expect(
        reason(code),
        'Still in use, possibly after changes on another device',
      );
    }
    expect(
      reason('plan_allocation_remaining'),
      'The plan still holds money for this or a later month',
    );
    expect(
      reason('invalid_transaction'),
      "The server's rules refused it (invalid_transaction)",
    );
  });
}
