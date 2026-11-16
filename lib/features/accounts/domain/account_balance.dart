import '../../../core/money/money.dart';
import 'account.dart';

/// The account's current balance, signed per the D1 convention.
///
/// This is the single place balances are calculated; screens must not do
/// their own arithmetic. In Phase 1 there are no transactions yet, so the
/// balance is the opening balance. Roadmap task 2.4 adds posted transactions.
Money currentBalance(Account account) => account.openingBalance;
