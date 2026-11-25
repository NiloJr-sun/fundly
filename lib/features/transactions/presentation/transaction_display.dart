import 'package:flutter/material.dart';

import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../domain/transaction.dart';
import '../domain/transaction_effects.dart';
import '../domain/transaction_kind.dart';
import '../domain/transaction_rules.dart';
import '../domain/transaction_type.dart';

/// User-facing name for a [TransactionKind].
String transactionKindLabel(TransactionKind kind) => switch (kind) {
  TransactionKind.spending => 'Spending',
  TransactionKind.inflow => 'Inflow',
  TransactionKind.transfer => 'Transfer',
  TransactionKind.loanPayment => 'Loan payment',
  TransactionKind.creditCardPayment => 'Credit card payment',
};

/// User-facing name for a stored [TransactionType] when the destination
/// account is not known, so a loan payment reads "Transfer".
String transactionTypeLabel(TransactionType type) =>
    transactionKindLabel(TransactionKind.ofType(type));

/// One-line explanation shown in the type picker.
String transactionKindDescription(TransactionKind kind) => switch (kind) {
  TransactionKind.spending => 'Money you spent, including card purchases',
  TransactionKind.inflow => 'Money you received, such as salary or a refund',
  TransactionKind.transfer => 'Move money between your accounts',
  TransactionKind.loanPayment => 'Pay off a loan',
  TransactionKind.creditCardPayment => 'Pay off a credit card',
};

IconData transactionKindIcon(TransactionKind kind) => switch (kind) {
  TransactionKind.spending => Icons.shopping_bag_outlined,
  TransactionKind.inflow => Icons.savings_outlined,
  TransactionKind.transfer => Icons.swap_horiz,
  TransactionKind.loanPayment => Icons.request_quote_outlined,
  TransactionKind.creditCardPayment => Icons.credit_score_outlined,
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

/// Whether a [kind] transaction is titled by its destination account: a loan
/// or credit card payment without a payee, so a list of payments reads
/// "BPI Personal Loan" rather than "Loan payment" on every row.
bool isTitledByDestination(
  TransactionDraft transaction,
  TransactionKind? kind,
) =>
    transaction.payee.trim().isEmpty &&
    (kind == TransactionKind.loanPayment ||
        kind == TransactionKind.creditCardPayment);

/// Payee if given. Otherwise, for a loan or card payment, [destinationName]
/// (the account paid) when known; else the name of [kind], e.g. "Loan
/// payment". Without [kind], the stored type's name, e.g. "Transfer".
String transactionTitle(
  TransactionDraft transaction, {
  TransactionKind? kind,
  String? destinationName,
}) {
  final payee = transaction.payee.trim();
  if (payee.isNotEmpty) return payee;
  if (destinationName != null && isTitledByDestination(transaction, kind)) {
    return destinationName;
  }
  return kind == null
      ? transactionTypeLabel(transaction.type)
      : transactionKindLabel(kind);
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
