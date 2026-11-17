import 'package:fundly/features/accounts/data/custom_account_type_repository.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/accounts/domain/custom_account_type.dart';
import 'package:fundly/features/accounts/domain/custom_account_type_validation_exception.dart';

/// Records calls for widget tests. Repository behaviour itself is covered by
/// `custom_account_type_repository_test.dart` against an in-memory database.
class FakeCustomAccountTypeRepository implements CustomAccountTypeRepository {
  FakeCustomAccountTypeRepository({this.firstId = 100});

  /// Id given to the first created type.
  final int firstId;

  final List<CustomAccountType> created = [];
  final List<({int id, String? name, AccountType? baseType})> updated = [];
  final List<int> deleted = [];

  /// When set, the next call throws this instead of saving.
  CustomAccountTypeValidationError? failWith;

  @override
  Future<CustomAccountType> create({
    required String name,
    required AccountType baseType,
  }) async {
    _maybeFail();
    final type = CustomAccountType(
      id: firstId + created.length,
      name: name.trim(),
      baseType: baseType,
      createdAt: DateTime.utc(2026, 11, 17),
    );
    created.add(type);
    return type;
  }

  @override
  Future<CustomAccountType> update(
    int id, {
    String? name,
    AccountType? baseType,
  }) async {
    _maybeFail();
    updated.add((id: id, name: name, baseType: baseType));
    return CustomAccountType(
      id: id,
      name: name?.trim() ?? '',
      baseType: baseType ?? AccountType.savingsCash,
      createdAt: DateTime.utc(2026, 11, 17),
    );
  }

  @override
  Future<void> delete(int id) async {
    _maybeFail();
    deleted.add(id);
  }

  @override
  Stream<List<CustomAccountType>> watchAll() => Stream.value(const []);

  void _maybeFail() {
    final error = failWith;
    if (error != null) {
      failWith = null;
      throw CustomAccountTypeValidationException(error);
    }
  }
}
