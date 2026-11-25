import 'package:fundly/features/accounts/data/custom_bank_repository.dart';
import 'package:fundly/features/accounts/domain/custom_bank.dart';

/// Records calls for widget tests. Repository behaviour itself is covered by
/// `custom_bank_repository_test.dart` against an in-memory database.
class FakeCustomBankRepository implements CustomBankRepository {
  FakeCustomBankRepository({this.firstId = 200});

  /// Id given to the first created bank.
  final int firstId;

  final List<CustomBank> created = [];
  final List<({String id, String name})> renamed = [];
  final List<String> deleted = [];

  /// When set, the next call throws this instead of saving.
  CustomBankValidationError? failWith;

  @override
  Future<CustomBank> create(String name) async {
    _maybeFail();
    final bank = CustomBank(
      id: '${firstId + created.length}',
      name: name.trim(),
      createdAt: DateTime.utc(2026, 11, 25),
    );
    created.add(bank);
    return bank;
  }

  @override
  Future<CustomBank> rename(String id, String name) async {
    _maybeFail();
    renamed.add((id: id, name: name));
    return CustomBank(
      id: id,
      name: name.trim(),
      createdAt: DateTime.utc(2026, 11, 25),
    );
  }

  @override
  Future<void> delete(String id) async {
    _maybeFail();
    deleted.add(id);
  }

  @override
  Stream<List<CustomBank>> watchAll() => Stream.value(const []);

  void _maybeFail() {
    final error = failWith;
    if (error != null) {
      failWith = null;
      throw CustomBankValidationException(error);
    }
  }
}
