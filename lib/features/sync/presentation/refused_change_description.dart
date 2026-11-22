import 'package:intl/intl.dart';

import '../../../core/formatting/date_formatter.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/sync/sync_rejections.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/calendar_month.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/account_type.dart';
import '../../accounts/presentation/account_display.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_display.dart';
import '../../transactions/domain/transaction_type.dart';
import '../../transactions/presentation/transaction_display.dart';

/// A refused change in words, for the Refused changes screen.
class RefusedChangeDescription {
  const RefusedChangeDescription({
    required this.title,
    required this.reason,
    required this.details,
  });

  /// What was tried, for example `Edit transaction · Jollibee`.
  final String title;

  /// Why it did not happen.
  final String reason;

  /// The values that were entered, to redo the change by hand.
  final List<(String, String)> details;
}

RefusedChangeDescription describeRefusedChange(SyncRejection rejection) {
  final items = rejection.items;
  final titles = [for (final item in items) _title(item, rejection.labels)];
  return RefusedChangeDescription(
    title: titles.isEmpty
        ? 'Change'
        : titles.length == 1
        ? titles.single
        : '${titles.first} (+${titles.length - 1} more)',
    reason: refusalReason(rejection),
    details: [for (final item in items) ..._details(item, rejection.labels)],
  );
}

/// Why a change was refused, in plain words.
String refusalReason(SyncRejection rejection) => switch (rejection) {
  SyncRejection(kind: RejectionKind.dependencyRejected) =>
    'It relied on another change that was refused',
  SyncRejection(
    code: 'revision_conflict' || 'plan_conflict' || 'budget_conflict',
  ) =>
    'Changed on another device first',
  SyncRejection(code: 'record_deleted') => 'Deleted on another device',
  SyncRejection(code: 'record_not_accessible') => 'The record no longer exists',
  SyncRejection(code: 'name_taken') =>
    'The name is already used, possibly added on another device',
  SyncRejection(
    code: 'category_in_use' ||
        'custom_type_in_use' ||
        'account_has_transactions',
  ) =>
    'Still in use, possibly after changes on another device',
  SyncRejection(code: 'plan_allocation_remaining' || 'has_assigned_money') =>
    'The plan still holds money for this or a later month',
  SyncRejection(:final code) => "The server's rules refused it ($code)",
};

String _title(Map<String, Object?> item, Map<String, String> labels) {
  final operation = item['operation']! as String;
  final data = (item['data'] as Map<String, Object?>?) ?? const {};
  final archived = data['archived'] == true;
  final action = switch (operation) {
    'transaction.create' => 'Add transaction',
    'transaction.update' => 'Edit transaction',
    'transaction.delete' => 'Delete transaction',
    'account.create' => 'Add account',
    'account.update' => 'Edit account',
    'account.set_archived' =>
      archived ? 'Archive account' : 'Unarchive account',
    'account.delete' => 'Delete account',
    'account.set_budget' => 'Use as budget account',
    'account.clear_budget' => 'Stop using as budget account',
    'custom_type.create' => 'Add account type',
    'custom_type.update' => 'Edit account type',
    'custom_type.delete' => 'Delete account type',
    'category.create' => 'Add category',
    'category.update' => 'Edit category',
    'category.set_archived' =>
      archived ? 'Archive category' : 'Unarchive category',
    'category.delete' => 'Delete category',
    'plan.save' => 'Save plan',
    'plan.set_archived' => archived ? 'Archive plan' : 'Unarchive plan',
    'plan.delete_permanently' => 'Delete plan permanently',
    'dataset.initialize' => 'Add default categories',
    _ => operation,
  };
  final subject = switch (operation) {
    'plan.save' => labels[data['category_id']],
    _ => labels[item['id']] ?? data['name'] ?? data['payee'],
  };
  return subject is String && subject.isNotEmpty
      ? '$action · $subject'
      : action;
}

List<(String, String)> _details(
  Map<String, Object?> item,
  Map<String, String> labels,
) {
  final data = (item['data'] as Map<String, Object?>?) ?? const {};
  final currency = data['currency_code'] as String? ?? Account.defaultCurrency;
  String money(Object? minor) => minor == null
      ? 'None'
      : MoneyFormatter.format(
          Money(minorUnits: int.parse(minor as String), currencyCode: currency),
        );
  String record(Object? id) =>
      id == null ? 'None' : labels[id] ?? 'A record no longer on this device';
  return [
    for (final MapEntry(:key, :value) in data.entries)
      ?switch (key) {
        'type' when item['operation'] == 'transaction.create' => (
          'Type',
          transactionTypeLabel(TransactionType.values.byName(value! as String)),
        ),
        'type' => (
          'Type',
          accountTypeLabel(AccountType.values.byName(value! as String)),
        ),
        'base_type' => (
          'Works like',
          accountTypeLabel(AccountType.values.byName(value! as String)),
        ),
        'kind' => (
          'Kind',
          categoryKindLabel(CategoryKind.values.byName(value! as String)),
        ),
        'plan_group' => (
          'Plans group',
          planGroupLabel(PlanGroup.values.byName(value! as String)),
        ),
        'name' => ('Name', value! as String),
        'payee' when value != '' => ('Payee', value! as String),
        'note' when value != '' => ('Note', value! as String),
        'amount_minor' => ('Amount', money(value)),
        'entered_opening_amount_minor' => ('Opening balance', money(value)),
        'target_amount_minor' => ('Target', money(value)),
        'assigned_amount_minor' => ('Assigned', money(value)),
        'date' => (
          'Date',
          DateFormat.yMMMd().format(
            CalendarDate.parse(value! as String).toLocalDateTime(),
          ),
        ),
        'month' => (
          'Month',
          switch (CalendarMonth.parse(value! as String)) {
            final month => DateFormatter.monthYear(month.year, month.month),
          },
        ),
        'category_id' => ('Category', record(value)),
        'source_account_id' => ('From', record(value)),
        'destination_account_id' => ('To', record(value)),
        'custom_type_id' => ('Account type', record(value)),
        _ => null,
      },
  ];
}
