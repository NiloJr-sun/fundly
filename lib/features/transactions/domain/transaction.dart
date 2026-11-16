import 'package:flutter/foundation.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import 'transaction_type.dart';

/// The user-entered fields of a transaction, before it is saved.
///
/// [amount] is always positive at input (rule 8); [type] decides the
/// accounting effect. Which of [sourceAccountId], [destinationAccountId] and
/// [categoryId] apply depends on [type]; see `validateTransaction`.
@immutable
class TransactionDraft {
  const TransactionDraft({
    required this.type,
    required this.amount,
    required this.date,
    this.payee = '',
    this.categoryId,
    this.sourceAccountId,
    this.destinationAccountId,
    this.note = '',
  });

  final TransactionType type;
  final Money amount;
  final CalendarDate date;

  /// Payee, merchant, source of income, or a description.
  final String payee;
  final int? categoryId;

  /// Account money leaves. Used by spending, transfer and card payment.
  final int? sourceAccountId;

  /// Account money arrives in. Used by inflow, transfer and card payment.
  final int? destinationAccountId;
  final String note;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is TransactionDraft &&
      other.type == type &&
      other.amount == amount &&
      other.date == date &&
      other.payee == payee &&
      other.categoryId == categoryId &&
      other.sourceAccountId == sourceAccountId &&
      other.destinationAccountId == destinationAccountId &&
      other.note == note;

  @override
  int get hashCode => Object.hash(
    type,
    amount,
    date,
    payee,
    categoryId,
    sourceAccountId,
    destinationAccountId,
    note,
  );

  @override
  String toString() =>
      'TransactionDraft(${type.name}, $amount, $date, '
      'from: $sourceAccountId, to: $destinationAccountId)';
}

/// A saved transaction.
@immutable
final class Transaction extends TransactionDraft {
  const Transaction({
    required this.id,
    required super.type,
    required super.amount,
    required super.date,
    super.payee,
    super.categoryId,
    super.sourceAccountId,
    super.destinationAccountId,
    super.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;

  /// UTC instants (G9).
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      super == other &&
      other is Transaction &&
      other.id == id &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(super.hashCode, id, createdAt, updatedAt);

  @override
  String toString() =>
      'Transaction($id, ${type.name}, $amount, $date, '
      'from: $sourceAccountId, to: $destinationAccountId)';
}
