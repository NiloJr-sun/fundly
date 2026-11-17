import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/money/money.dart';
import '../domain/account.dart';
import '../domain/account_rules.dart';
import '../domain/account_type.dart';
import '../domain/account_validation_exception.dart';
import 'account_row_mapping.dart';

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
          rows.map((row) => row.toDomain()).toList()..sort(_byTypeThenName),
    );
  }

  /// Emits `null` if the account does not exist.
  Stream<Account?> watchById(int id) {
    final query = _database.select(_accounts)
      ..where((account) => account.id.equals(id));
    return query.watchSingleOrNull().map((row) => row?.toDomain());
  }

  /// Creates an account. [enteredOpeningAmount] is the zero or positive amount
  /// the user typed; its sign is set from [type] (D1). With [customTypeId],
  /// the account is shown under that custom type, whose base type must be
  /// [type].
  ///
  /// Throws [AccountValidationException] when a rule is broken, or
  /// [ArgumentError] if the custom type does not exist or has another base
  /// type.
  Future<Account> create({
    required String name,
    required AccountType type,
    required Money enteredOpeningAmount,
    int? customTypeId,
  }) async {
    final trimmedName = await _validName(name);
    _requireSupportedCurrency(enteredOpeningAmount);
    final openingBalance = _openingBalance(type, enteredOpeningAmount);
    await _requireMatchingCustomType(customTypeId, type);

    final row = await _database
        .into(_accounts)
        .insertReturning(
          AccountsCompanion.insert(
            name: trimmedName,
            type: type,
            openingBalanceMinor: openingBalance.minorUnits,
            currencyCode: Value(openingBalance.currencyCode),
            createdAt: _now().toUtc(),
            customTypeId: Value(customTypeId),
          ),
        );
    return row.toDomain();
  }

  /// Updates the editable fields of account [id]. The type cannot change.
  ///
  /// [customType] moves the account to another custom type with the same base
  /// type, or back to its built-in type with `(id: null)`; leave it `null` to
  /// keep the current one.
  ///
  /// Throws [AccountValidationException] when a rule is broken,
  /// [ArgumentError] if the custom type does not exist or has another base
  /// type, or [StateError] if the account does not exist.
  Future<Account> update(
    int id, {
    String? name,
    Money? enteredOpeningAmount,
    ({int? id})? customType,
  }) async {
    final existing = await (_database.select(
      _accounts,
    )..where((account) => account.id.equals(id))).getSingleOrNull();
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

    final rows =
        await (_database.update(
          _accounts,
        )..where((account) => account.id.equals(id))).writeReturning(
          AccountsCompanion(
            name: Value.absentIfNull(trimmedName),
            openingBalanceMinor: Value.absentIfNull(openingBalance?.minorUnits),
            customTypeId: customType == null
                ? const Value.absent()
                : Value(customType.id),
          ),
        );
    return rows.single.toDomain();
  }

  /// Archives or restores account [id]. Archived accounts keep their history
  /// but are hidden from the active list and pickers (G7).
  ///
  /// Whether the user must confirm first is a UI decision; see
  /// `needsArchiveConfirmation`. Throws [StateError] if the account does not
  /// exist.
  Future<void> setArchived(int id, {required bool archived}) async {
    final changed =
        await (_database.update(_accounts)
              ..where((account) => account.id.equals(id)))
            .write(AccountsCompanion(isArchived: Value(archived)));
    if (changed == 0) throw StateError('Account $id does not exist.');
  }

  /// Returns the trimmed name, or throws if it is invalid or already used.
  Future<String> _validName(String name, {int? excludingId}) async {
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
            : sameName & account.id.equals(excludingId).not();
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
    int? customTypeId,
    AccountType type,
  ) async {
    if (customTypeId == null) return;
    final customType = await (_database.select(
      _database.customAccountTypes,
    )..where((custom) => custom.id.equals(customTypeId))).getSingleOrNull();
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

  static int _byTypeThenName(Account a, Account b) {
    final byType = a.type.index.compareTo(b.type.index);
    if (byType != 0) return byType;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(appDatabaseProvider)),
);
