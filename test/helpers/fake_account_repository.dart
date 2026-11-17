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
    ({String name, AccountType type, Money entered, int? customTypeId})
  >
  created = [];
  final List<({int id, String? name, Money? entered, ({int? id})? customType})>
  updated = [];
  final List<({int id, bool archived})> archivedChanges = [];

  /// When set, the next create/update throws this instead of saving.
  AccountValidationError? failWith;

  @override
  Future<Account> create({
    required String name,
    required AccountType type,
    required Money enteredOpeningAmount,
    int? customTypeId,
  }) async {
    _maybeFail();
    created.add((
      name: name,
      type: type,
      entered: enteredOpeningAmount,
      customTypeId: customTypeId,
    ));
    return Account(
      id: created.length,
      name: name.trim(),
      type: type,
      openingBalance: openingBalanceFor(type, enteredOpeningAmount),
      createdAt: DateTime.utc(2026, 11, 16),
      customTypeId: customTypeId,
    );
  }

  @override
  Future<Account> update(
    int id, {
    String? name,
    Money? enteredOpeningAmount,
    ({int? id})? customType,
  }) async {
    _maybeFail();
    updated.add((
      id: id,
      name: name,
      entered: enteredOpeningAmount,
      customType: customType,
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
  Future<void> setArchived(int id, {required bool archived}) async {
    archivedChanges.add((id: id, archived: archived));
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
  Stream<Account?> watchById(int id) => Stream.value(null);
}
