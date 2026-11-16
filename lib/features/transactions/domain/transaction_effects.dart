import '../../../core/money/money.dart';
import 'transaction.dart';

/// A signed change to one account's balance (CLAUDE.md §11, D1).
typedef BalanceEffect = ({int accountId, Money change});

/// How [transaction] changes account balances under the signed convention:
///
/// | Type        | Source   | Destination |
/// |-------------|----------|-------------|
/// | Spending    | −amount  | —           |
/// | Inflow      | —        | +amount     |
/// | Transfer    | −amount  | +amount     |
/// | CC Payment  | −amount  | +amount     |
///
/// A card purchase is Spending on the credit account, so its negative balance
/// grows (more owed). A card payment adds to the credit account, so less is
/// owed. The same rule works for every account type.
///
/// Expects a valid transaction; throws [StateError] if a required account is
/// missing.
List<BalanceEffect> effectsOf(TransactionDraft transaction) => [
  if (transaction.type.hasSourceAccount)
    (
      accountId: _require(transaction.sourceAccountId, 'source'),
      change: -transaction.amount,
    ),
  if (transaction.type.hasDestinationAccount)
    (
      accountId: _require(transaction.destinationAccountId, 'destination'),
      change: transaction.amount,
    ),
];

int _require(int? accountId, String role) =>
    accountId ??
    (throw StateError('A valid transaction must have a $role account.'));
