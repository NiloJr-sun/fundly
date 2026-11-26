import 'package:flutter/foundation.dart';

import '../../../core/time/date_range.dart';
import '../../accounts/domain/account_type.dart';
import 'transaction.dart';
import 'transaction_kind.dart';
import 'transaction_type.dart';

/// A choice in the Type filter of the transactions list. Display only: each
/// one is read from the stored type and, where needed, an account's type.
enum TransactionTypeFilter {
  /// Every Spending, card purchases included (the Spending totals' outflows).
  spending,

  /// Spending charged to a Credit account, custom credit types included.
  cardPurchase,

  inflow,

  /// Transfers other than loan payments; cash advances are transfers.
  transfer,

  /// Transfers into a Loan account (G4).
  loanPayment,

  cardPayment;

  /// Whether [transaction] is of this type. [accountTypes] gives each
  /// account's base type; an unknown account is neither a card nor a loan.
  bool matches(
    TransactionDraft transaction,
    Map<String, AccountType> accountTypes,
  ) {
    final kind = TransactionKind.of(
      transaction,
      destinationType: accountTypes[transaction.destinationAccountId],
    );
    return switch (this) {
      spending => kind == TransactionKind.spending,
      cardPurchase =>
        kind == TransactionKind.spending &&
            accountTypes[transaction.sourceAccountId] == AccountType.credit,
      inflow => kind == TransactionKind.inflow,
      transfer => kind == TransactionKind.transfer,
      loanPayment => kind == TransactionKind.loanPayment,
      cardPayment => kind == TransactionKind.creditCardPayment,
    };
  }
}

/// Optional filters for a transaction list. A `null` field (or an empty
/// [types]) means "any". All set fields must match.
@immutable
final class TransactionFilter {
  const TransactionFilter({
    this.dateRange,
    this.accountId,
    this.categoryId,
    this.paymentAccountId,
    this.types = const {},
    this.uncategorized = false,
  }) : assert(
         !uncategorized || categoryId == null,
         'No category and a category cannot both be set',
       );

  static const TransactionFilter none = TransactionFilter();

  /// Inclusive range of transaction dates.
  final DateRange? dateRange;

  /// Matches transactions where this account is the source or destination.
  final String? accountId;

  /// Matches transactions in this category. Transfers and card payments have
  /// no category, so they never match a category filter.
  final String? categoryId;

  /// Only transfers and credit-card payments into this liability account.
  final String? paymentAccountId;

  /// Matches a transaction of any of these types; empty means any type.
  final Set<TransactionTypeFilter> types;

  /// Only Spending and Inflow without a category.
  final bool uncategorized;

  bool get isEmpty =>
      dateRange == null &&
      accountId == null &&
      categoryId == null &&
      paymentAccountId == null &&
      types.isEmpty &&
      !uncategorized;

  /// Whether [transaction] passes every set filter. [accountTypes] is
  /// needed only for the card purchase and loan payment types.
  bool matches(
    TransactionDraft transaction, {
    Map<String, AccountType> accountTypes = const {},
  }) {
    final paymentAccount = paymentAccountId;
    if (paymentAccount != null &&
        (transaction.destinationAccountId != paymentAccount ||
            (transaction.type != TransactionType.transfer &&
                transaction.type != TransactionType.creditCardPayment))) {
      return false;
    }
    final range = dateRange;
    if (range != null && !range.contains(transaction.date)) return false;
    final account = accountId;
    if (account != null &&
        transaction.sourceAccountId != account &&
        transaction.destinationAccountId != account) {
      return false;
    }
    final category = categoryId;
    if (category != null && transaction.categoryId != category) return false;
    if (uncategorized &&
        (transaction.categoryId != null ||
            (transaction.type != TransactionType.spending &&
                transaction.type != TransactionType.inflow))) {
      return false;
    }
    if (types.isNotEmpty &&
        !types.any((type) => type.matches(transaction, accountTypes))) {
      return false;
    }
    return true;
  }

  /// Keeps the matching [transactions], preserving their order.
  List<T> apply<T extends TransactionDraft>(
    Iterable<T> transactions, {
    Map<String, AccountType> accountTypes = const {},
  }) => transactions
      .where((t) => matches(t, accountTypes: accountTypes))
      .toList();

  TransactionFilter withDateRange(DateRange? value) =>
      _copy(dateRange: () => value);

  TransactionFilter withAccount(String? value) => _copy(
    accountId: () => value,
    paymentAccountId: () => value == accountId ? paymentAccountId : null,
  );

  /// A category replaces No category.
  TransactionFilter withCategory(String? value) => _copy(
    categoryId: () => value,
    uncategorized: value == null ? uncategorized : false,
    paymentAccountId: () => value == null ? paymentAccountId : null,
  );

  /// No category replaces a category; payments never match it.
  TransactionFilter withUncategorized(bool value) => _copy(
    uncategorized: value,
    categoryId: () => value ? null : categoryId,
    paymentAccountId: () => value ? null : paymentAccountId,
  );

  TransactionFilter withTypes(Set<TransactionTypeFilter> value) =>
      _copy(types: Set.unmodifiable(value));

  TransactionFilter withoutPaymentFilter() =>
      _copy(paymentAccountId: () => null);

  /// A copy with the given fields replaced; nullable fields take a function
  /// so they can be set to null.
  TransactionFilter _copy({
    DateRange? Function()? dateRange,
    String? Function()? accountId,
    String? Function()? categoryId,
    String? Function()? paymentAccountId,
    Set<TransactionTypeFilter>? types,
    bool? uncategorized,
  }) => TransactionFilter(
    dateRange: dateRange == null ? this.dateRange : dateRange(),
    accountId: accountId == null ? this.accountId : accountId(),
    categoryId: categoryId == null ? this.categoryId : categoryId(),
    paymentAccountId: paymentAccountId == null
        ? this.paymentAccountId
        : paymentAccountId(),
    types: types ?? this.types,
    uncategorized: uncategorized ?? this.uncategorized,
  );

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.dateRange == dateRange &&
      other.accountId == accountId &&
      other.categoryId == categoryId &&
      other.paymentAccountId == paymentAccountId &&
      setEquals(other.types, types) &&
      other.uncategorized == uncategorized;

  @override
  int get hashCode => Object.hash(
    dateRange,
    accountId,
    categoryId,
    paymentAccountId,
    Object.hashAllUnordered(types),
    uncategorized,
  );

  @override
  String toString() =>
      'TransactionFilter(dates: $dateRange, account: $accountId, '
      'category: $categoryId, payments to: $paymentAccountId, '
      'types: $types, uncategorized: $uncategorized)';
}
