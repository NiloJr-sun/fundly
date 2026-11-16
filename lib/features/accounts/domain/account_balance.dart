import '../../../core/money/money.dart';
import 'account.dart';

/// The account's current balance, signed per the D1 convention.
///
/// This is the single place balances are calculated; screens must not do
/// their own arithmetic. In Phase 1 there are no transactions yet, so the
/// balance is the opening balance. Roadmap task 2.4 adds posted transactions.
Money currentBalance(Account account) => account.openingBalance;

/// Whether archiving [account] needs explicit confirmation: it still has a
/// balance, so hiding it would hide money held or owed (CLAUDE.md §2).
bool needsArchiveConfirmation(Account account) =>
    !currentBalance(account).isZero;
