import 'package:flutter/material.dart';

import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../domain/transaction.dart';
import '../domain/transaction_effects.dart';
import '../domain/transaction_rules.dart';
import '../domain/transaction_type.dart';

/// User-facing name for a [TransactionType].
String transactionTypeLabel(TransactionType type) => switch (type) {
  TransactionType.spending => 'Spending',
  TransactionType.inflow => 'Inflow',
  TransactionType.transfer => 'Transfer',
  TransactionType.creditCardPayment => 'Credit card payment',
};

/// One-line explanation shown in the type picker.
String transactionTypeDescription(TransactionType type) => switch (type) {
  TransactionType.spending => 'Money you spent, including card purchases',
  TransactionType.inflow => 'Money you received, such as salary or a refund',
  TransactionType.transfer => 'Move money between your accounts, or pay a loan',
  TransactionType.creditCardPayment => 'Pay off a credit card',
};

IconData transactionTypeIcon(TransactionType type) => switch (type) {
  TransactionType.spending => Icons.shopping_bag_outlined,
  TransactionType.inflow => Icons.savings_outlined,
  TransactionType.transfer => Icons.swap_horiz,
  TransactionType.creditCardPayment => Icons.credit_score_outlined,
};

/// The amount as shown in a list.
///
/// With [accountId], the sign is the transaction's effect on that account
/// (from [effectsOf]), e.g. `-₱2,000.00` for a transfer out. Without it,
/// spending is negative, inflow positive, and transfers and card payments
/// unsigned because they only move money between the user's own accounts.
String transactionAmountText(
  TransactionDraft transaction, {
  String? accountId,
}) {
  if (accountId != null) {
    final change = effectsOf(transaction)
        .where((effect) => effect.accountId == accountId)
        .fold(
          Money.zero(transaction.amount.currencyCode),
          (total, effect) => total + effect.change,
        );
    return _signed(change);
  }
  return switch (transaction.type) {
    TransactionType.spending => _signed(-transaction.amount),
    TransactionType.inflow => _signed(transaction.amount),
    TransactionType.transfer || TransactionType.creditCardPayment =>
      MoneyFormatter.format(transaction.amount),
  };
}

String _signed(Money money) => money.isNegative || money.isZero
    ? MoneyFormatter.format(money)
    : '+${MoneyFormatter.format(money)}';

/// Payee if given, otherwise the type name, e.g. "Transfer".
String transactionTitle(TransactionDraft transaction) {
  final payee = transaction.payee.trim();
  return payee.isEmpty ? transactionTypeLabel(transaction.type) : payee;
}

String payeeLabel(TransactionType type) => switch (type) {
  TransactionType.spending => 'Paid to',
  TransactionType.inflow => 'Received from',
  TransactionType.transfer ||
  TransactionType.creditCardPayment => 'Description (optional)',
};

String sourceAccountLabel(TransactionType type) =>
    type == TransactionType.spending ? 'Paid from' : 'From';

String destinationAccountLabel(TransactionType type) =>
    type == TransactionType.inflow ? 'Deposited to' : 'To';

/// Which form field an error belongs to.
enum TransactionField {
  amount,
  sourceAccount,
  destinationAccount,
  payee,
  category,
  note,
  form,
}

/// Message and field for each validation error. [type] tailors the wording.
({TransactionField field, String message}) transactionErrorDisplay(
  TransactionValidationError error,
  TransactionType type,
) => switch (error) {
  TransactionValidationError.amountNotPositive => (
    field: TransactionField.amount,
    message: 'Enter an amount greater than zero.',
  ),
  TransactionValidationError.currencyMismatch => (
    field: TransactionField.amount,
    message: "The amount's currency doesn't match the account.",
  ),
  TransactionValidationError.sourceAccountMissing => (
    field: TransactionField.sourceAccount,
    message: 'Choose an account.',
  ),
  TransactionValidationError.sourceAccountNotFound => (
    field: TransactionField.sourceAccount,
    message: 'This account no longer exists.',
  ),
  TransactionValidationError.sourceAccountArchived => (
    field: TransactionField.sourceAccount,
    message: 'This account is archived.',
  ),
  TransactionValidationError.sourceAccountWrongType => (
    field: TransactionField.sourceAccount,
    message: "This account can't be used here.",
  ),
  TransactionValidationError.destinationAccountMissing => (
    field: TransactionField.destinationAccount,
    message: 'Choose an account.',
  ),
  TransactionValidationError.destinationAccountNotFound => (
    field: TransactionField.destinationAccount,
    message: 'This account no longer exists.',
  ),
  TransactionValidationError.destinationAccountArchived => (
    field: TransactionField.destinationAccount,
    message: 'This account is archived.',
  ),
  TransactionValidationError.destinationAccountWrongType => (
    field: TransactionField.destinationAccount,
    message: "This account can't be used here.",
  ),
  TransactionValidationError.sameSourceAndDestination => (
    field: TransactionField.destinationAccount,
    message: "Choose a different account from the 'From' account.",
  ),
  TransactionValidationError.payeeMissing => (
    field: TransactionField.payee,
    message: type == TransactionType.inflow
        ? 'Enter who paid you.'
        : 'Enter who you paid.',
  ),
  TransactionValidationError.payeeTooLong => (
    field: TransactionField.payee,
    message: 'Use $maxPayeeLength characters or fewer.',
  ),
  TransactionValidationError.categoryMissing => (
    field: TransactionField.category,
    message: 'Choose a category.',
  ),
  TransactionValidationError.categoryNotFound => (
    field: TransactionField.category,
    message: 'This category no longer exists.',
  ),
  TransactionValidationError.categoryArchived => (
    field: TransactionField.category,
    message: 'This category is archived. Choose another.',
  ),
  TransactionValidationError.categoryWrongKind ||
  TransactionValidationError.categoryNotAllowed => (
    field: TransactionField.category,
    message: "This category can't be used here.",
  ),
  TransactionValidationError.noteTooLong => (
    field: TransactionField.note,
    message: 'Use $maxNoteLength characters or fewer.',
  ),
  // Not reachable from a create form; shown as a general message.
  TransactionValidationError.sourceAccountNotAllowed ||
  TransactionValidationError.destinationAccountNotAllowed ||
  TransactionValidationError.typeChanged => (
    field: TransactionField.form,
    message: 'This transaction could not be saved.',
  ),
};
