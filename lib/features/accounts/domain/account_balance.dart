import '../../../core/money/money.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_effects.dart';
import 'account.dart';
import 'account_type.dart';

/// Current balances for [accounts], keyed by account id.
///
/// This is the single place balances are calculated (CLAUDE.md §2, "Ledger-
/// driven"); screens must not do their own arithmetic. Each balance is the
/// opening balance plus the signed effects of every transaction that touches
/// the account (D1). Because balances are always derived, editing or deleting
/// a transaction recalculates them automatically (rule 11).
///
/// Effects on accounts not in [accounts] are ignored.
Map<String, Money> balancesFor(
  Iterable<Account> accounts,
  Iterable<TransactionDraft> transactions,
) {
  final balances = <String, Money>{
    for (final account in accounts) account.id: account.openingBalance,
  };
  for (final effect in transactions.expand(effectsOf)) {
    final balance = balances[effect.accountId];
    if (balance != null) {
      balances[effect.accountId] = balance + effect.change;
    }
  }
  return balances;
}

/// The signed total (D1) of [balances] for [accounts], per account type.
/// Every type is present, zero when it has no accounts. Accounts missing
/// from [balances] are skipped; callers choose which accounts to include.
Map<AccountType, Money> totalsByType(
  Iterable<Account> accounts,
  Map<String, Money> balances, {
  String currencyCode = Account.defaultCurrency,
}) {
  final totals = {
    for (final type in AccountType.values) type: Money.zero(currencyCode),
  };
  for (final account in accounts) {
    final balance = balances[account.id];
    if (balance == null) continue;
    totals[account.type] = totals[account.type]! + balance;
  }
  return totals;
}

/// The signed total (D1) of [balances] for [accounts]. Accounts missing from
/// [balances] are skipped.
Money totalBalance(
  Iterable<Account> accounts,
  Map<String, Money> balances, {
  String currencyCode = Account.defaultCurrency,
}) {
  var total = Money.zero(currencyCode);
  for (final account in accounts) {
    final balance = balances[account.id];
    if (balance != null) total += balance;
  }
  return total;
}

/// Current balance of one [account]; see [balancesFor].
Money currentBalance(
  Account account,
  Iterable<TransactionDraft> transactions,
) => balancesFor([account], transactions)[account.id]!;

/// Whether archiving an account with [balance] needs explicit confirmation:
/// hiding it would hide money held or owed (CLAUDE.md §2).
bool needsArchiveConfirmation(Money balance) => !balance.isZero;
