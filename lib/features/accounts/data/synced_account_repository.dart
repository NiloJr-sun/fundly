import 'package:drift/drift.dart';

import '../../../core/money/money.dart';
import '../../../core/sync/sync_queue.dart';
import '../../../core/sync/synced_database.dart';
import '../domain/account.dart';
import '../domain/account_rules.dart';
import '../domain/account_type.dart';
import '../domain/account_validation_exception.dart';
import '../domain/custom_account_type.dart';
import '../domain/custom_account_type_rules.dart';
import '../domain/custom_account_type_validation_exception.dart';
import 'account_repository.dart';
import 'custom_account_type_repository.dart';

/// Accounts in the signed-in user's synchronized store. Writes apply locally
/// at once and queue the matching operation for upload (S5.3), with the same
/// rules as the local store. Side effects the server makes in the same
/// operation (the linked Plans row of a Credit/Loan account, the budget flag)
/// are applied locally the same way, so the screens agree before the upload.
class SyncedAccountRepository implements AccountRepository {
  SyncedAccountRepository(this._database, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final SyncedDatabase _database;
  final DateTime Function() _now;

  $SyncedAccountsTable get _accounts => _database.syncedAccounts;

  SimpleSelectStatement<$SyncedAccountsTable, SyncedAccountRow> _select() =>
      _database.select(_accounts)..where(
        (_) => CustomExpression<bool>('NOT (${unsafeAccount('accounts')})'),
      );

  @override
  Stream<List<Account>> watchAll({bool includeArchived = false}) {
    final query = _select();
    if (!includeArchived) {
      query.where((account) => account.isArchived.equals(false));
    }
    return query.watch().map(
      (rows) =>
          rows.map(syncedAccount).toList()
            ..sort(AccountRepository.byTypeThenName),
    );
  }

  @override
  Stream<Account?> watchById(String id) {
    final query = _select()..where((account) => account.id.equals(id));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : syncedAccount(row),
    );
  }

  @override
  Future<Account> create({
    required String name,
    required AccountType type,
    required Money enteredOpeningAmount,
    String? customTypeId,
  }) => _database.writeAndQueue(() async {
    final trimmedName = await _validName(name);
    _requireSupportedCurrency(enteredOpeningAmount);
    final openingBalance = _openingBalance(type, enteredOpeningAmount);
    await _requireMatchingCustomType(customTypeId, type);

    final id = newRecordId();
    final now = syncedTimestamp(_now());
    final row = await _database
        .into(_accounts)
        .insertReturning(
          SyncedAccountsCompanion.insert(
            id: id,
            name: trimmedName,
            type: type.name,
            openingBalanceMinor: openingBalance.minorUnits,
            currencyCode: openingBalance.currencyCode,
            isArchived: false,
            customTypeId: Value(customTypeId),
            isBudgetAccount: false,
            createdAt: now,
            updatedAt: now,
            revision: 1,
          ),
        );
    // The client names the linked Plans row, so plan edits queued before the
    // upload can refer to it.
    final linkedCategoryId = type == AccountType.savingsCash
        ? null
        : newRecordId();
    await _syncLiabilityRow(row, newCategoryId: linkedCategoryId);
    return (
      syncedAccount(row),
      [
        SyncOperation(
          'account.create',
          id,
          data: {
            'name': trimmedName,
            'type': type.name,
            'entered_opening_amount_minor': wireMinor(
              enteredOpeningAmount.minorUnits,
            ),
            'currency_code': openingBalance.currencyCode,
            'custom_type_id': customTypeId,
            'linked_category_id': ?linkedCategoryId,
          },
        ),
      ],
    );
  });

  @override
  Future<Account> update(
    String id, {
    String? name,
    Money? enteredOpeningAmount,
    ({String? id})? customType,
  }) => _database.writeAndQueue(() async {
    final existing = await _find(id);
    final type = AccountType.values.byName(existing.type);
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
    final data = {
      'name': ?trimmedName,
      if (enteredOpeningAmount != null)
        'entered_opening_amount_minor': wireMinor(
          enteredOpeningAmount.minorUnits,
        ),
      if (customType != null) 'custom_type_id': customType.id,
    };
    // The server refuses an empty update, and nothing would change.
    if (data.isEmpty) return (syncedAccount(existing), <SyncOperation>[]);

    final rows =
        await (_database.update(
          _accounts,
        )..where((account) => account.id.equals(id))).writeReturning(
          SyncedAccountsCompanion(
            name: Value.absentIfNull(trimmedName),
            openingBalanceMinor: Value.absentIfNull(openingBalance?.minorUnits),
            customTypeId: customType == null
                ? const Value.absent()
                : Value(customType.id),
            updatedAt: Value(syncedTimestamp(_now())),
            revision: Value(nextRevision(existing.revision)),
          ),
        );
    await _syncLiabilityRow(rows.single);
    return (
      syncedAccount(rows.single),
      [
        SyncOperation(
          'account.update',
          id,
          expectedRevision: existing.revision,
          data: data,
        ),
      ],
    );
  });

  @override
  Future<void> setArchived(String id, {required bool archived}) =>
      _database.writeAndQueue(() async {
        final existing = await _find(id);
        final rows =
            await (_database.update(
              _accounts,
            )..where((account) => account.id.equals(id))).writeReturning(
              SyncedAccountsCompanion(
                isArchived: Value(archived),
                isBudgetAccount: archived
                    ? const Value(false)
                    : const Value.absent(),
                updatedAt: Value(syncedTimestamp(_now())),
                revision: Value(nextRevision(existing.revision)),
              ),
            );
        await _syncLiabilityRow(rows.single);
        return (
          null,
          [
            SyncOperation(
              'account.set_archived',
              id,
              expectedRevision: existing.revision,
              data: {'archived': archived},
            ),
          ],
        );
      });

  @override
  Future<Account> setBudgetAccount(String id) =>
      _database.writeAndQueue(() async {
        final existing = await _find(id);
        if (existing.isArchived) {
          throw StateError('An archived account cannot be the budget account.');
        }
        if (existing.type != AccountType.savingsCash.name) {
          throw ArgumentError.value(
            id,
            'id',
            'Only a Savings/Cash account can be the budget account.',
          );
        }
        final previous = await _currentBudget();
        // Already the budget account: the server would change nothing.
        if (previous?.id == id) {
          return (syncedAccount(existing), <SyncOperation>[]);
        }
        if (previous != null) await _setBudgetFlag(previous, false);
        final row = await _setBudgetFlag(existing, true);
        return (
          syncedAccount(row),
          [
            SyncOperation(
              'account.set_budget',
              id,
              expectedRevision: existing.revision,
              data: {
                // The server checks that this is still the budget account.
                'previous_budget': previous == null
                    ? null
                    : {
                        'id': previous.id,
                        'revision': previous.revision.toString(),
                      },
              },
            ),
          ],
        );
      });

  @override
  Future<void> clearBudgetAccount() => _database.writeAndQueue(() async {
    final current = await _currentBudget();
    if (current == null) return (null, <SyncOperation>[]);
    await _setBudgetFlag(current, false);
    return (
      null,
      [
        SyncOperation(
          'account.clear_budget',
          current.id,
          expectedRevision: current.revision,
        ),
      ],
    );
  });

  @override
  Future<void> delete(String id) => _database.writeAndQueue(() async {
    final existing = await _find(id);
    if (!existing.isArchived) {
      throw StateError('Account $id must be archived before deleting.');
    }
    final transactions = _database.syncedTransactions;
    final usage = transactions.id.count();
    final count =
        await (_database.selectOnly(transactions)
              ..addColumns([usage])
              ..where(
                transactions.sourceAccountId.equals(id) |
                    transactions.destinationAccountId.equals(id),
              ))
            .map((row) => row.read(usage)!)
            .getSingle();
    if (count > 0) {
      throw const AccountValidationException(
        AccountValidationError.hasTransactions,
      );
    }
    // The server keeps the linked Plans row and its history, detached.
    final categories = _database.syncedCategories;
    final linked = await (_database.select(
      categories,
    )..where((c) => c.linkedAccountId.equals(id))).getSingleOrNull();
    if (linked != null) {
      await (_database.update(
        categories,
      )..where((c) => c.id.equals(linked.id))).write(
        SyncedCategoriesCompanion(
          linkedAccountId: const Value(null),
          updatedAt: Value(syncedTimestamp(_now())),
          revision: Value(nextRevision(linked.revision)),
        ),
      );
    }
    await (_database.delete(
      _accounts,
    )..where((account) => account.id.equals(id))).go();
    return (
      null,
      [
        SyncOperation(
          'account.delete',
          id,
          expectedRevision: existing.revision,
        ),
      ],
    );
  });

  Future<SyncedAccountRow> _find(String id) async {
    final row = await (_database.select(
      _accounts,
    )..where((account) => account.id.equals(id))).getSingleOrNull();
    if (row == null) throw StateError('Account $id does not exist.');
    return row;
  }

  Future<SyncedAccountRow?> _currentBudget() =>
      (_database.select(_accounts)
            ..where((account) => account.isBudgetAccount.equals(true)))
          .getSingleOrNull();

  Future<SyncedAccountRow> _setBudgetFlag(
    SyncedAccountRow account,
    bool isBudget,
  ) async {
    final rows =
        await (_database.update(
          _accounts,
        )..where((a) => a.id.equals(account.id))).writeReturning(
          SyncedAccountsCompanion(
            isBudgetAccount: Value(isBudget),
            updatedAt: Value(syncedTimestamp(_now())),
            revision: Value(nextRevision(account.revision)),
          ),
        );
    return rows.single;
  }

  /// Mirrors the server's linked Plans row upkeep for a Credit/Loan
  /// [account]: create it (with [newCategoryId]) or keep its name and archive
  /// status in step. A row the server will create with its own ID (an
  /// unarchived account that lost its row) arrives by download instead.
  Future<void> _syncLiabilityRow(
    SyncedAccountRow account, {
    String? newCategoryId,
  }) async {
    if (account.type == AccountType.savingsCash.name) return;
    final categories = _database.syncedCategories;
    final existing = await (_database.select(
      categories,
    )..where((c) => c.linkedAccountId.equals(account.id))).getSingleOrNull();
    if (existing == null && (account.isArchived || newCategoryId == null)) {
      return;
    }
    final name = await liabilityRowName(
      _database,
      account,
      categoryId: existing?.id,
    );
    final now = syncedTimestamp(_now());
    if (existing == null) {
      await _database
          .into(categories)
          .insert(
            SyncedCategoriesCompanion.insert(
              id: newCategoryId!,
              name: name,
              kind: 'spending',
              isArchived: account.isArchived,
              isPlanArchived: false,
              isPlanDeleted: false,
              planGroup: 'liability',
              linkedAccountId: Value(account.id),
              createdAt: now,
              updatedAt: now,
              revision: 1,
            ),
          );
    } else if (existing.name != name ||
        existing.isArchived != account.isArchived) {
      await (_database.update(
        categories,
      )..where((c) => c.id.equals(existing.id))).write(
        SyncedCategoriesCompanion(
          name: Value(name),
          isArchived: Value(account.isArchived),
          updatedAt: Value(now),
          revision: Value(nextRevision(existing.revision)),
        ),
      );
    }
  }

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
    final query = _database.select(_accounts)
      ..where((account) {
        final sameName = sameNameAs(account.name, trimmed);
        return excludingId == null
            ? sameName
            : sameName & account.id.equals(excludingId).not();
      });
    if ((await query.get()).isNotEmpty) {
      throw const AccountValidationException(AccountValidationError.nameTaken);
    }
    return trimmed;
  }

  Future<void> _requireMatchingCustomType(
    String? customTypeId,
    AccountType type,
  ) async {
    if (customTypeId == null) return;
    final customType = await (_database.select(
      _database.syncedCustomAccountTypes,
    )..where((custom) => custom.id.equals(customTypeId))).getSingleOrNull();
    if (customType == null) {
      throw ArgumentError.value(
        customTypeId,
        'customTypeId',
        'No such account type.',
      );
    }
    if (customType.baseType != type.name) {
      throw ArgumentError.value(
        customTypeId,
        'customTypeId',
        'Account type "${customType.name}" is based on '
            '${customType.baseType}, not ${type.name}.',
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

  void _requireSupportedCurrency(Money amount) {
    if (amount.currencyCode != Account.defaultCurrency) {
      throw ArgumentError.value(
        amount.currencyCode,
        'currencyCode',
        'Only ${Account.defaultCurrency} accounts are supported.',
      );
    }
  }
}

/// The linked Plans row's name for [account], as the server chooses it: the
/// account name, or on a clash (ignoring ASCII case) the name shortened to
/// fit ` (debt <first 8 ID characters>)`, then `-1`, `-2`… inside it.
Future<String> liabilityRowName(
  SyncedDatabase database,
  SyncedAccountRow account, {
  String? categoryId,
}) async {
  final categories = database.syncedCategories;
  Future<bool> taken(String name) async =>
      (await (database.select(categories)..where(
                (c) =>
                    sameNameAs(c.name, name) &
                    (categoryId == null
                        ? const Constant(true)
                        : c.id.equals(categoryId).not()),
              ))
              .get())
          .isNotEmpty;

  var name = account.name;
  for (var counter = 0; await taken(name); counter++) {
    final suffix =
        ' (debt ${account.id.substring(0, 8)}'
        '${counter == 0 ? '' : '-$counter'})';
    name = '${_utf16Prefix(account.name, 40 - suffix.length)}$suffix';
  }
  return name;
}

/// At most [length] UTF-16 units of [text], never splitting a surrogate pair.
String _utf16Prefix(String text, int length) {
  if (text.length <= length) return text;
  var end = length;
  final last = text.codeUnitAt(end - 1);
  if (last >= 0xD800 && last <= 0xDBFF) end--;
  return text.substring(0, end);
}

/// Custom account types in the synchronized store; writes queue uploads like
/// [SyncedAccountRepository].
class SyncedCustomAccountTypeRepository implements CustomAccountTypeRepository {
  SyncedCustomAccountTypeRepository(
    this._database, {
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final SyncedDatabase _database;
  final DateTime Function() _now;

  $SyncedCustomAccountTypesTable get _types =>
      _database.syncedCustomAccountTypes;

  @override
  Stream<List<CustomAccountType>> watchAll() =>
      (_database.select(_types)..where(
            (_) => CustomExpression<bool>(
              'NOT (${unsafe('custom_account_types.revision')})',
            ),
          ))
          .watch()
          .map(
            (rows) => rows.map(_toDomain).toList()
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              ),
          );

  @override
  Future<CustomAccountType> create({
    required String name,
    required AccountType baseType,
  }) => _database.writeAndQueue(() async {
    final trimmedName = await _validName(name);
    final id = newRecordId();
    final now = syncedTimestamp(_now());
    final row = await _database
        .into(_types)
        .insertReturning(
          SyncedCustomAccountTypesCompanion.insert(
            id: id,
            name: trimmedName,
            baseType: baseType.name,
            createdAt: now,
            updatedAt: now,
            revision: 1,
          ),
        );
    return (
      _toDomain(row),
      [
        SyncOperation(
          'custom_type.create',
          id,
          data: {'name': trimmedName, 'base_type': baseType.name},
        ),
      ],
    );
  });

  @override
  Future<CustomAccountType> update(
    String id, {
    String? name,
    AccountType? baseType,
  }) => _database.writeAndQueue(() async {
    final existing = await (_database.select(
      _types,
    )..where((type) => type.id.equals(id))).getSingleOrNull();
    if (existing == null) throw StateError('Account type $id does not exist.');
    final trimmedName = name == null
        ? null
        : await _validName(name, excludingId: id);
    final changesBase = baseType != null && baseType.name != existing.baseType;
    if (changesBase && await _accountCount(id) > 0) {
      throw const CustomAccountTypeValidationException(
        CustomAccountTypeValidationError.baseTypeInUse,
      );
    }
    final data = {
      'name': ?trimmedName,
      if (changesBase) 'base_type': baseType.name,
    };
    if (data.isEmpty) return (_toDomain(existing), <SyncOperation>[]);
    final rows =
        await (_database.update(
          _types,
        )..where((type) => type.id.equals(id))).writeReturning(
          SyncedCustomAccountTypesCompanion(
            name: Value.absentIfNull(trimmedName),
            baseType: changesBase ? Value(baseType.name) : const Value.absent(),
            updatedAt: Value(syncedTimestamp(_now())),
            revision: Value(nextRevision(existing.revision)),
          ),
        );
    return (
      _toDomain(rows.single),
      [
        SyncOperation(
          'custom_type.update',
          id,
          expectedRevision: existing.revision,
          data: data,
        ),
      ],
    );
  });

  @override
  Future<void> delete(String id) => _database.writeAndQueue(() async {
    if (await _accountCount(id) > 0) {
      throw const CustomAccountTypeValidationException(
        CustomAccountTypeValidationError.inUse,
      );
    }
    final existing = await (_database.select(
      _types,
    )..where((type) => type.id.equals(id))).getSingleOrNull();
    if (existing == null) throw StateError('Account type $id does not exist.');
    await (_database.delete(_types)..where((type) => type.id.equals(id))).go();
    return (
      null,
      [
        SyncOperation(
          'custom_type.delete',
          id,
          expectedRevision: existing.revision,
        ),
      ],
    );
  });

  Future<int> _accountCount(String id) {
    final accounts = _database.syncedAccounts;
    final usage = accounts.id.count();
    return (_database.selectOnly(accounts)
          ..addColumns([usage])
          ..where(accounts.customTypeId.equals(id)))
        .map((row) => row.read(usage)!)
        .getSingle();
  }

  Future<String> _validName(String name, {String? excludingId}) async {
    switch (validateAccountName(name)) {
      case AccountNameError.empty:
        throw const CustomAccountTypeValidationException(
          CustomAccountTypeValidationError.nameEmpty,
        );
      case AccountNameError.tooLong:
        throw const CustomAccountTypeValidationException(
          CustomAccountTypeValidationError.nameTooLong,
        );
      case null:
        break;
    }
    final trimmed = name.trim();
    if (isBuiltInAccountTypeName(trimmed)) {
      throw const CustomAccountTypeValidationException(
        CustomAccountTypeValidationError.nameTaken,
      );
    }
    final query = _database.select(_types)
      ..where((type) {
        final sameName = sameNameAs(type.name, trimmed);
        return excludingId == null
            ? sameName
            : sameName & type.id.equals(excludingId).not();
      });
    if ((await query.get()).isNotEmpty) {
      throw const CustomAccountTypeValidationException(
        CustomAccountTypeValidationError.nameTaken,
      );
    }
    return trimmed;
  }
}

CustomAccountType _toDomain(SyncedCustomAccountTypeRow row) =>
    CustomAccountType(
      id: row.id,
      name: row.name,
      baseType: AccountType.values.byName(row.baseType),
      createdAt: parseSyncedTimestamp(row.createdAt),
    );

Account syncedAccount(SyncedAccountRow row) => Account(
  id: row.id,
  name: row.name,
  type: AccountType.values.byName(row.type),
  openingBalance: Money(
    minorUnits: row.openingBalanceMinor,
    currencyCode: row.currencyCode,
  ),
  createdAt: parseSyncedTimestamp(row.createdAt),
  isArchived: row.isArchived,
  customTypeId: row.customTypeId,
  isBudgetAccount: row.isBudgetAccount,
);
