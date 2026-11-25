import 'package:fundly/core/money/money.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_rules.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/domain/account_validation_exception.dart';

/// Records calls for widget tests, which cannot await a real drift database
/// under the fake test clock. Repository behaviour itself is covered by
/// `account_repository_test.dart` against an in-memory database.
class FakeAccountRepository implements AccountRepository {
  final List<
    ({
      String name,
      AccountType type,
      Money entered,
      String? customTypeId,
      String? bankKey,
      String? customBankId,
    })
  >
  created = [];
  final List<
    ({
      String id,
      String? name,
      Money? entered,
      ({String? id})? customType,
      AccountBank? bank,
    })
  >
  updated = [];
  final List<({String id, bool archived})> archivedChanges = [];
  final List<String> deleted = [];

  /// Calls to [setBudgetAccount] and [clearBudgetAccount], with the id.
  final List<({String id, bool isBudget})> budgetAccountChanges = [];

  /// When set, the next create/update/delete throws this instead.
  AccountValidationError? failWith;

  @override
  Future<Account> create({
    required String name,
    required AccountType type,
    required Money enteredOpeningAmount,
    String? customTypeId,
    String? bankKey,
    String? customBankId,
  }) async {
    _maybeFail();
    created.add((
      name: name,
      type: type,
      entered: enteredOpeningAmount,
      customTypeId: customTypeId,
      bankKey: bankKey,
      customBankId: customBankId,
    ));
    return Account(
      id: '${created.length}',
      name: name.trim(),
      type: type,
      openingBalance: openingBalanceFor(type, enteredOpeningAmount),
      createdAt: DateTime.utc(2026, 11, 16),
      customTypeId: customTypeId,
      bankKey: bankKey,
      customBankId: customBankId,
    );
  }

  @override
  Future<Account> update(
    String id, {
    String? name,
    Money? enteredOpeningAmount,
    ({String? id})? customType,
    AccountBank? bank,
  }) async {
    _maybeFail();
    updated.add((
      id: id,
      name: name,
      entered: enteredOpeningAmount,
      customType: customType,
      bank: bank,
    ));
    return Account(
      id: id,
      name: name ?? '',
      type: AccountType.savingsCash,
      openingBalance:
          enteredOpeningAmount ?? const Money.zero(Account.defaultCurrency),
      createdAt: DateTime.utc(2026, 11, 16),
    );
  }

  @override
  Future<void> setArchived(String id, {required bool archived}) async {
    archivedChanges.add((id: id, archived: archived));
  }

  @override
  Future<Account> setBudgetAccount(String id) async {
    _maybeFail();
    budgetAccountChanges.add((id: id, isBudget: true));
    return Account(
      id: id,
      name: '',
      type: AccountType.savingsCash,
      openingBalance: const Money.zero(Account.defaultCurrency),
      createdAt: DateTime.utc(2026, 11, 16),
      isBudgetAccount: true,
    );
  }

  @override
  Future<void> clearBudgetAccount(String id) async {
    _maybeFail();
    budgetAccountChanges.add((id: id, isBudget: false));
  }

  @override
  Future<void> delete(String id) async {
    _maybeFail();
    deleted.add(id);
  }

  void _maybeFail() {
    final error = failWith;
    if (error != null) {
      failWith = null;
      throw AccountValidationException(error);
    }
  }

  @override
  Stream<List<Account>> watchAll({bool includeArchived = false}) =>
      Stream.value(const []);

  @override
  Stream<Account?> watchById(String id) => Stream.value(null);
}
