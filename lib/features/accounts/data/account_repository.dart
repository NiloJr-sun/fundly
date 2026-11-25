import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/record_id.dart';
import '../../../core/money/money.dart';
import '../../../core/sync/synced_store.dart';
import '../../categories/data/liability_plan_categories.dart';
import '../domain/account.dart';
import '../domain/account_rules.dart';
import '../domain/account_type.dart';
import '../domain/account_validation_exception.dart';
import '../domain/bank.dart';
import 'account_row_mapping.dart';
import 'synced_account_repository.dart';

/// Reads and writes [Account]s, enforcing the account rules before anything
/// reaches the database.
class AccountRepository {
  AccountRepository(this._database, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _now;

  $AccountsTable get _accounts => _database.accounts;

  /// Accounts ordered by type (Savings/Cash, Credit, Loan) then name.
  /// Archived accounts are excluded unless [includeArchived] is true.
  Stream<List<Account>> watchAll({bool includeArchived = false}) {
    final query = _database.select(_accounts);
    if (!includeArchived) {
      query.where((account) => account.isArchived.equals(false));
    }
    return query.watch().map(
      (rows) =>
          rows.map((row) => row.toDomain()).toList()..sort(byTypeThenName),
    );
  }

  /// Emits `null` if the account does not exist.
  Stream<Account?> watchById(String id) {
    final query = _database.select(_accounts)
      ..where((account) => account.id.equals(rowIdOf(id)));
    return query.watchSingleOrNull().map((row) => row?.toDomain());
  }

  /// Creates an account. [enteredOpeningAmount] is the zero or positive amount
  /// the user typed; its sign is set from [type] (D1). With [customTypeId],
  /// the account is shown under that custom type, whose base type must be
  /// [type]. The account belongs to the built-in bank [bankKey], the custom
  /// bank [customBankId], or neither (never both).
  ///
  /// Throws [AccountValidationException] when a rule is broken, or
  /// [ArgumentError] if the custom type does not exist or has another base
  /// type, or the bank is unknown, missing or given twice.
  Future<Account> create({
    required String name,
    required AccountType type,
    required Money enteredOpeningAmount,
    String? customTypeId,
    String? bankKey,
    String? customBankId,
  }) => _database.transaction(() async {
    final trimmedName = await _validName(name);
    _requireSupportedCurrency(enteredOpeningAmount);
    final openingBalance = _openingBalance(type, enteredOpeningAmount);
    await _requireMatchingCustomType(customTypeId, type);
    await _requireValidBank((bankKey: bankKey, customBankId: customBankId));

    final row = await _database
        .into(_accounts)
        .insertReturning(
          AccountsCompanion.insert(
            name: trimmedName,
            type: type,
            openingBalanceMinor: openingBalance.minorUnits,
            currencyCode: Value(openingBalance.currencyCode),
            createdAt: _now().toUtc(),
            customTypeId: Value(rowIdOrNull(customTypeId)),
            bankKey: Value(bankKey),
            customBankId: Value(rowIdOrNull(customBankId)),
          ),
        );
    await syncLiabilityPlanCategories(_database);
    return row.toDomain();
  });

  /// Updates the editable fields of account [id]. The type cannot change.
  ///
  /// [customType] moves the account to another custom type with the same base
  /// type, or back to its built-in type with `(id: null)`; leave it `null` to
  /// keep the current one.
  ///
  /// [bank] replaces the account's bank (`(bankKey: null, customBankId: null)`
  /// for none); leave it `null` to keep the current one. A bank is a label
  /// only: no balance changes.
  ///
  /// Throws [AccountValidationException] when a rule is broken,
  /// [ArgumentError] if the custom type does not exist or has another base
  /// type, or the bank is unknown, missing or given twice, or [StateError] if
  /// the account does not exist.
  Future<Account> update(
    String id, {
    String? name,
    Money? enteredOpeningAmount,
    ({String? id})? customType,
    AccountBank? bank,
  }) => _database.transaction(() async {
    final existing = await (_database.select(
      _accounts,
    )..where((account) => account.id.equals(rowIdOf(id)))).getSingleOrNull();
    if (existing == null) throw StateError('Account $id does not exist.');

    final type = existing.type;
    final trimmedName = name == null
        ? null
        : await _validName(name, excludingId: id);
    Money? openingBalance;
    if (enteredOpeningAmount != null) {
      _requireSupportedCurrency(enteredOpeningAmount);
      openingBalance = _openingBalance(type, enteredOpeningAmount);
    }
    if (customType != null) {
      await _requireMatchingCustomType(customType.id, type);
    }
    if (bank != null) await _requireValidBank(bank);

    final rows =
        await (_database.update(
          _accounts,
        )..where((account) => account.id.equals(rowIdOf(id)))).writeReturning(
          AccountsCompanion(
            name: Value.absentIfNull(trimmedName),
            openingBalanceMinor: Value.absentIfNull(openingBalance?.minorUnits),
            customTypeId: customType == null
                ? const Value.absent()
                : Value(rowIdOrNull(customType.id)),
            bankKey: bank == null ? const Value.absent() : Value(bank.bankKey),
            customBankId: bank == null
                ? const Value.absent()
                : Value(rowIdOrNull(bank.customBankId)),
          ),
        );
    await syncLiabilityPlanCategories(_database);
    return rows.single.toDomain();
  });

  /// Archives or restores account [id]. Archived accounts keep their history
  /// but are hidden from the active list and pickers (G7).
  ///
  /// Whether the user must confirm first is a UI decision; see
  /// `needsArchiveConfirmation`. Throws [StateError] if the account does not
  /// exist.
  ///
  /// Archiving a budget account also stops it being one: archived accounts
  /// are left out of summaries (G7).
  Future<void> setArchived(String id, {required bool archived}) =>
      _database.transaction(() async {
        final changed =
            await (_database.update(
              _accounts,
            )..where((account) => account.id.equals(rowIdOf(id)))).write(
              AccountsCompanion(
                isArchived: Value(archived),
                isBudgetAccount: archived
                    ? const Value(false)
                    : const Value.absent(),
              ),
            );
        if (changed == 0) throw StateError('Account $id does not exist.');
        await syncLiabilityPlanCategories(_database);
      });

  /// Makes account [id] a budget account, whose money in funds Ready to
  /// assign on Plans. Other budget accounts stay budget accounts.
  ///
  /// Throws [ArgumentError] unless it is a Savings/Cash account (custom asset
  /// types included), or [StateError] if it does not exist or is archived.
  /// The UI only offers active asset accounts, so these are programming
  /// errors.
  Future<Account> setBudgetAccount(String id) => _database.transaction(
    () async {
      final existing = await (_database.select(
        _accounts,
      )..where((account) => account.id.equals(rowIdOf(id)))).getSingleOrNull();
      if (existing == null) throw StateError('Account $id does not exist.');
      if (existing.isArchived) {
        throw StateError('An archived account cannot be the budget account.');
      }
      if (existing.type != AccountType.savingsCash) {
        throw ArgumentError.value(
          id,
          'id',
          'Only a Savings/Cash account can be the budget account.',
        );
      }
      final rows =
          await (_database.update(
            _accounts,
          )..where((account) => account.id.equals(rowIdOf(id)))).writeReturning(
            const AccountsCompanion(isBudgetAccount: Value(true)),
          );
      return rows.single.toDomain();
    },
  );

  /// Stops account [id] being a budget account. Does nothing if it is not
  /// one or does not exist.
  Future<void> clearBudgetAccount(String id) =>
      (_database.update(_accounts)
            ..where((account) => account.id.equals(rowIdOf(id))))
          .write(const AccountsCompanion(isBudgetAccount: Value(false)));

  /// Permanently deletes archived account [id]. Only an account no
  /// transaction uses can be deleted (G7): its history and the balances of
  /// the accounts it traded with stay intact.
  ///
  /// Throws [AccountValidationException] with
  /// [AccountValidationError.hasTransactions] if a transaction uses it, or
  /// [StateError] if the account does not exist or is not archived.
  Future<void> delete(String id) => _database.transaction(() async {
    final existing = await (_database.select(
      _accounts,
    )..where((account) => account.id.equals(rowIdOf(id)))).getSingleOrNull();
    if (existing == null) throw StateError('Account $id does not exist.');
    if (!existing.isArchived) {
      throw StateError('Account $id must be archived before deleting.');
    }

    final transactions = _database.transactions;
    final usage = transactions.id.count();
    final count =
        await (_database.selectOnly(transactions)
              ..addColumns([usage])
              ..where(
                transactions.sourceAccountId.equals(rowIdOf(id)) |
                    transactions.destinationAccountId.equals(rowIdOf(id)),
              ))
            .map((row) => row.read(usage)!)
            .getSingle();
    if (count > 0) {
      throw const AccountValidationException(
        AccountValidationError.hasTransactions,
      );
    }
    await (_database.delete(
      _accounts,
    )..where((account) => account.id.equals(rowIdOf(id)))).go();
  });

  /// Returns the trimmed name, or throws if it is invalid or already used.
  Future<String> _validName(String name, {String? excludingId}) async {
    switch (validateAccountName(name)) {
      case AccountNameError.empty:
        throw const AccountValidationException(
          AccountValidationError.nameEmpty,
        );
      case AccountNameError.tooLong:
        throw const AccountValidationException(
          AccountValidationError.nameTooLong,
        );
      case null:
        break;
    }

    final trimmed = name.trim();
    // The column is COLLATE NOCASE, so this comparison ignores case.
    final query = _database.select(_accounts)
      ..where((account) {
        final sameName = account.name.equals(trimmed);
        return excludingId == null
            ? sameName
            : sameName & account.id.equals(rowIdOf(excludingId)).not();
      });
    if (await query.getSingleOrNull() != null) {
      throw const AccountValidationException(AccountValidationError.nameTaken);
    }
    return trimmed;
  }

  /// An account can only use a custom type based on its own [type], so every
  /// accounting rule can keep reading [Account.type]. The UI only offers
  /// matching types, so a mismatch is a programming error.
  Future<void> _requireMatchingCustomType(
    String? customTypeId,
    AccountType type,
  ) async {
    if (customTypeId == null) return;
    final customType =
        await (_database.select(_database.customAccountTypes)
              ..where((custom) => custom.id.equals(rowIdOf(customTypeId))))
            .getSingleOrNull();
    if (customType == null) {
      throw ArgumentError.value(
        customTypeId,
        'customTypeId',
        'No such account type.',
      );
    }
    if (customType.baseType != type) {
      throw ArgumentError.value(
        customTypeId,
        'customTypeId',
        'Account type "${customType.name}" is based on '
            '${customType.baseType.name}, not ${type.name}.',
      );
    }
  }

  /// The UI only offers built-in banks and existing custom banks, one at a
  /// time, so anything else is a programming error.
  Future<void> _requireValidBank(AccountBank bank) async {
    checkBankChoice(bank);
    final customBankId = bank.customBankId;
    if (customBankId == null) return;
    final exists =
        await (_database.select(_database.customBanks)
              ..where((custom) => custom.id.equals(rowIdOf(customBankId))))
            .getSingleOrNull();
    if (exists == null) {
      throw ArgumentError.value(customBankId, 'customBankId', 'No such bank.');
    }
  }

  Money _openingBalance(AccountType type, Money enteredAmount) {
    if (enteredAmount.isNegative) {
      throw const AccountValidationException(
        AccountValidationError.negativeOpeningBalance,
      );
    }
    return openingBalanceFor(type, enteredAmount);
  }

  /// All accounts are PHP in the MVP (G6); anything else is a programming
  /// error rather than user input.
  void _requireSupportedCurrency(Money amount) {
    if (amount.currencyCode != Account.defaultCurrency) {
      throw ArgumentError.value(
        amount.currencyCode,
        'currencyCode',
        'Only ${Account.defaultCurrency} accounts are supported.',
      );
    }
  }

  static int byTypeThenName(Account a, Account b) {
    final byType = a.type.index.compareTo(b.type.index);
    if (byType != 0) return byType;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final synced = ref.watch(syncedStoreProvider);
  return synced == null
      ? AccountRepository(ref.watch(appDatabaseProvider))
      : SyncedAccountRepository(synced.database);
});

/// Throws [ArgumentError] when [bank] names both a built-in and a custom bank,
/// or a built-in key this app does not know. Whether a custom bank exists is
/// for the store to check.
void checkBankChoice(AccountBank bank) {
  if (bank.bankKey != null && bank.customBankId != null) {
    throw ArgumentError('An account belongs to one bank, not two.');
  }
  final key = bank.bankKey;
  if (key != null && builtInBankByKey(key) == null) {
    throw ArgumentError.value(key, 'bankKey', 'No such bank.');
  }
}
