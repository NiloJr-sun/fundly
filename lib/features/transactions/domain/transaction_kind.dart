import '../../accounts/domain/account_type.dart';
import 'transaction.dart';
import 'transaction_rules.dart';
import 'transaction_type.dart';

/// How a transaction is offered and shown to the user.
///
/// It matches the stored [TransactionType], except that a loan payment is
/// stored as a Transfer into a Loan account (G4). Keeping it a Transfer means
/// no schema, server, sync or backup change, and balances, totals and the
/// loan's Plans Activity stay exactly as they are; only the screens tell the
/// two apart.
enum TransactionKind {
  spending(TransactionType.spending),
  inflow(TransactionType.inflow),
  transfer(TransactionType.transfer),
  loanPayment(TransactionType.transfer),
  creditCardPayment(TransactionType.creditCardPayment);

  const TransactionKind(this.type);

  /// The type this kind is stored as.
  final TransactionType type;

  /// The kind of [transaction], whose destination account is of type
  /// [destinationType] (`null` when unknown, e.g. not loaded yet).
  static TransactionKind of(
    TransactionDraft transaction, {
    AccountType? destinationType,
  }) => ofType(transaction.type, destinationType: destinationType);

  /// The kind of a [type] transaction into an account of [destinationType].
  static TransactionKind ofType(
    TransactionType type, {
    AccountType? destinationType,
  }) => switch (type) {
    TransactionType.spending => spending,
    TransactionType.inflow => inflow,
    TransactionType.transfer when destinationType == AccountType.loan =>
      loanPayment,
    TransactionType.transfer => transfer,
    TransactionType.creditCardPayment => creditCardPayment,
  };
}

/// Account types a [kind] transaction can come from: a subset of
/// [allowedSourceAccountTypes] for its type. A loan is paid from a
/// Savings/Cash account.
Set<AccountType> sourceAccountTypesFor(TransactionKind kind) => switch (kind) {
  TransactionKind.loanPayment => {AccountType.savingsCash},
  _ => allowedSourceAccountTypes(kind.type),
};

/// Account types a [kind] transaction can go to when its source is of type
/// [source]: a subset of [allowedDestinationAccountTypes] for its type. A
/// Transfer leaves Loan accounts to Loan payment, which only goes to them.
Set<AccountType> destinationAccountTypesFor(
  TransactionKind kind, {
  AccountType? source,
}) => switch (kind) {
  TransactionKind.transfer => allowedDestinationAccountTypes(
    kind.type,
    source: source,
  )..remove(AccountType.loan),
  TransactionKind.loanPayment => allowedDestinationAccountTypes(
    kind.type,
    source: source,
  ).intersection({AccountType.loan}),
  _ => allowedDestinationAccountTypes(kind.type, source: source),
};
