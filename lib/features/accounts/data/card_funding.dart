import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/money/money.dart';
import '../../../core/sync/synced_store.dart';
import '../../../core/time/calendar_date.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';
import '../domain/account.dart';
import '../domain/account_type.dart';
import 'account_repository.dart';

/// Runs [body] as one database transaction: if anything in it throws,
/// nothing it wrote is kept.
typedef Atomically = Future<T> Function<T>(Future<T> Function() body);

/// The note on a Transfer that brings an account's starting money from a
/// credit card, so the account's history says why it is there.
const cardFundingNote = 'Starting money';

/// Gives an asset account its starting money from a credit card.
///
/// The money is recorded as a Transfer from the card (a cash advance,
/// CLAUDE.md §11, 2026-11-23) dated today, never as an opening balance: an
/// opening balance cannot change another account, and a Transfer keeps both
/// balances derived from the ledger. The account's opening balance is zero.
/// The account and the Transfer are written together or not at all, and the
/// Transfer passes the usual transaction rules (rule 12).
class CardFunding {
  CardFunding({
    required this._accounts,
    required this._transactions,
    required this._atomically,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final AccountRepository _accounts;
  final TransactionRepository _transactions;
  final Atomically _atomically;
  final DateTime Function() _now;

  /// Creates an asset account and moves [amount] into it from the credit
  /// account [cardId].
  ///
  /// Throws [ArgumentError] unless [type] is Savings/Cash and [amount] is
  /// positive; otherwise what [AccountRepository.create] and
  /// [TransactionRepository.create] throw.
  Future<Account> create({
    required String name,
    required AccountType type,
    required Money amount,
    required String cardId,
    String? customTypeId,
    String? bankKey,
    String? customBankId,
  }) {
    _requireAsset(type);
    _requirePositive(amount);
    return _atomically(() async {
      final account = await _accounts.create(
        name: name,
        type: type,
        enteredOpeningAmount: Money.zero(amount.currencyCode),
        customTypeId: customTypeId,
        bankKey: bankKey,
        customBankId: customBankId,
      );
      await _transactions.create(_transfer(cardId, account.id, amount));
      return account;
    });
  }

  /// Edits asset account [id] like [AccountRepository.update], sets its
  /// opening balance to zero and moves [amount] into it from the credit
  /// account [cardId].
  ///
  /// Throws [ArgumentError] unless [amount] is positive; otherwise what
  /// [AccountRepository.update] and [TransactionRepository.create] throw (a
  /// liability account is refused as the Transfer's destination).
  Future<Account> update(
    String id, {
    required Money amount,
    required String cardId,
    String? name,
    ({String? id})? customType,
    AccountBank? bank,
  }) {
    _requirePositive(amount);
    return _atomically(() async {
      final account = await _accounts.update(
        id,
        name: name,
        enteredOpeningAmount: Money.zero(amount.currencyCode),
        customType: customType,
        bank: bank,
      );
      await _transactions.create(_transfer(cardId, id, amount));
      return account;
    });
  }

  TransactionDraft _transfer(String cardId, String accountId, Money amount) =>
      TransactionDraft(
        type: TransactionType.transfer,
        amount: amount,
        date: CalendarDate.today(clock: _now),
        sourceAccountId: cardId,
        destinationAccountId: accountId,
        note: cardFundingNote,
      );

  static void _requireAsset(AccountType type) {
    if (type != AccountType.savingsCash) {
      throw ArgumentError.value(
        type,
        'type',
        'Only an asset account can take money from a card.',
      );
    }
  }

  static void _requirePositive(Money amount) {
    if (amount.minorUnits <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'The amount taken from the card must be positive.',
      );
    }
  }
}

final cardFundingProvider = Provider<CardFunding>((ref) {
  final synced = ref.watch(syncedStoreProvider);
  return CardFunding(
    accounts: ref.watch(accountRepositoryProvider),
    transactions: ref.watch(transactionRepositoryProvider),
    atomically: synced == null
        ? ref.watch(appDatabaseProvider).transaction
        : synced.database.transaction,
  );
});
