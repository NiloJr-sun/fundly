import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/features/transactions/data/transaction_repository.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_rules.dart';
import 'package:fundly/features/transactions/domain/transaction_validation_exception.dart';

/// Records calls for widget tests, which cannot await a real drift database
/// under the fake test clock. Repository behaviour is covered by
/// `transaction_repository_test.dart` against an in-memory database.
class FakeTransactionRepository implements TransactionRepository {
  final List<TransactionDraft> created = [];
  final List<({String id, TransactionDraft draft})> updated = [];
  final List<String> deleted = [];

  /// When set, the next write throws a validation exception with these.
  Set<TransactionValidationError>? failWith;

  @override
  Future<Transaction> create(TransactionDraft draft) async {
    _maybeFail();
    created.add(draft);
    return _saved('${created.length}', draft);
  }

  @override
  Future<Transaction> update(String id, TransactionDraft draft) async {
    _maybeFail();
    updated.add((id: id, draft: draft));
    return _saved(id, draft);
  }

  @override
  Future<void> delete(String id) async => deleted.add(id);

  @override
  Stream<List<Transaction>> watchAll({
    String? accountId,
    CalendarDate? from,
    CalendarDate? to,
  }) => Stream.value(const []);

  @override
  Stream<Transaction?> watchById(String id) => Stream.value(null);

  void _maybeFail() {
    final errors = failWith;
    if (errors != null) {
      failWith = null;
      throw TransactionValidationException(errors);
    }
  }

  static Transaction _saved(String id, TransactionDraft draft) => Transaction(
    id: id,
    type: draft.type,
    amount: draft.amount,
    date: draft.date,
    payee: draft.payee,
    categoryId: draft.categoryId,
    sourceAccountId: draft.sourceAccountId,
    destinationAccountId: draft.destinationAccountId,
    note: draft.note,
    createdAt: DateTime.utc(2026, 11, 16),
    updatedAt: DateTime.utc(2026, 11, 16),
  );
}
