import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/app_database.dart';
import 'package:fundly/core/database/record_id.dart';
import 'package:fundly/core/time/calendar_month.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/data/custom_account_type_repository.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/categories/data/category_repository.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/plans/data/plan_repository.dart';
import 'package:fundly/features/transactions/data/transaction_repository.dart';
import 'package:fundly/features/transactions/domain/transaction_rules.dart';
import 'package:fundly/features/transactions/domain/transaction_validation_exception.dart';

import '../../transactions/domain/transaction_fixtures.dart' show php, spending;

void main() {
  late AppDatabase database;
  late AccountRepository accounts;
  late CategoryRepository categories;
  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    accounts = AccountRepository(database);
    categories = CategoryRepository(database);
  });
  tearDown(() => database.close());

  Future<Category> linked(String accountId) async =>
      (await categories.watchAll().first).singleWhere(
        (c) => c.linkedAccountId == accountId,
      );

  test('credit and loan accounts get one row each; assets do not', () async {
    for (final type in AccountType.values) {
      final account = await accounts.create(
        name: type.name,
        type: type,
        enteredOpeningAmount: php(0),
      );
      if (type.isLiability) {
        final row = await linked(account.id);
        expect(row.name, account.name);
        expect(row.planGroup, PlanGroup.liability);
        expect(row.isArchived, isFalse);
        expect(
          await PlanRepository(database)
              .watchForMonth(CalendarMonth(2026, 11))
              .first,
          isEmpty,
        );
      } else {
        expect(
          (await categories.watchAll().first).where(
            (c) => c.linkedAccountId == account.id,
          ),
          isEmpty,
        );
      }
    }
  });

  test('custom liability types also get a Plans row', () async {
    final type = await CustomAccountTypeRepository(database)
        .create(name: 'Pay later', baseType: AccountType.credit);
    final account = await accounts.create(
      name: 'Shop',
      type: type.baseType,
      customTypeId: type.id,
      enteredOpeningAmount: php(0),
    );
    expect((await linked(account.id)).name, 'Shop');
  });

  test(
    'rename/archive/unarchive retain row ID and monthly assignments',
    () async {
      final account = await accounts.create(
        name: 'Card',
        type: AccountType.credit,
        enteredOpeningAmount: php(0),
      );
      final row = await linked(account.id);
      final month = CalendarMonth(2026, 11);
      await PlanRepository(database).save(
        month: month,
        categoryId: row.id,
        target: null,
        assigned: php(10000),
      );
      await accounts.update(account.id, name: 'New card');
      expect((await linked(account.id)).id, row.id);
      expect((await linked(account.id)).name, 'New card');
      await accounts.setArchived(account.id, archived: true);
      expect((await linked(account.id)).isArchived, isTrue);
      await accounts.setArchived(account.id, archived: false);
      expect((await linked(account.id)).isArchived, isFalse);
      expect(
        (await PlanRepository(
          database,
        ).watchForMonth(month).first).single.assigned,
        php(10000),
      );
    },
  );

  test(
    'a name collision preserves the original category and disambiguates debt',
    () async {
      final original = (await categories.watchAll().first).singleWhere(
        (c) => c.name == 'Utilities',
      );
      final account = await accounts.create(
        name: 'Utilities',
        type: AccountType.loan,
        enteredOpeningAmount: php(0),
      );
      final row = await linked(account.id);
      expect(row.name, startsWith('Utilities (debt '));
      expect(
        (await categories.watchAll().first).singleWhere(
          (c) => c.id == original.id,
        ),
        original,
      );
      await accounts.update(account.id, name: 'Different');
      expect((await linked(account.id)).name, 'Different');
    },
  );

  test(
    'managed rows cannot be renamed, moved, archived or deleted directly',
    () async {
      final account = await accounts.create(
        name: 'Card',
        type: AccountType.credit,
        enteredOpeningAmount: php(0),
      );
      final row = await linked(account.id);
      await expectLater(categories.rename(row.id, 'Other'), throwsStateError);
      await expectLater(
        categories.setPlanGroup(row.id, PlanGroup.spending),
        throwsStateError,
      );
      await expectLater(
        categories.setArchived(row.id, archived: true),
        throwsStateError,
      );
      await expectLater(categories.delete(row.id), throwsStateError);
    },
  );

  test(
    'linked categories reject duplicates and nonexistent accounts in SQLite',
    () async {
      final account = await accounts.create(
        name: 'Card',
        type: AccountType.credit,
        enteredOpeningAmount: php(0),
      );
      Future<int> insert(int id) => database
          .into(database.categories)
          .insert(
            CategoriesCompanion.insert(
              name: 'Invalid',
              kind: CategoryKind.spending,
              planGroup: const Value(PlanGroup.liability),
              linkedAccountId: Value(id),
            ),
          );
      await expectLater(insert(rowIdOf(account.id)), throwsA(isA<Exception>()));
      await expectLater(insert(999), throwsA(isA<Exception>()));
    },
  );

  test('managed rows cannot be selected as a spending category', () async {
    final asset = await accounts.create(
      name: 'Cash',
      type: AccountType.savingsCash,
      enteredOpeningAmount: php(10000),
    );
    final debt = await accounts.create(
      name: 'Card',
      type: AccountType.credit,
      enteredOpeningAmount: php(0),
    );
    final row = await linked(debt.id);
    await expectLater(
      TransactionRepository(database)
          .create(spending(from: asset.id, category: row.id)),
      throwsA(
        isA<TransactionValidationException>().having(
          (e) => e.errors,
          'errors',
          contains(TransactionValidationError.categoryNotAllowed),
        ),
      ),
    );
  });

  test(
    'deleting an unused archived account keeps its archived plan history',
    () async {
      final account = await accounts.create(
        name: 'Unused',
        type: AccountType.loan,
        enteredOpeningAmount: php(0),
      );
      final row = await linked(account.id);
      final month = CalendarMonth(2026, 11);
      await PlanRepository(database).save(
        month: month,
        categoryId: row.id,
        target: null,
        assigned: php(10000),
      );
      await accounts.setArchived(account.id, archived: true);
      await accounts.delete(account.id);
      final retained = (await categories.watchAll().first).singleWhere(
        (c) => c.id == row.id,
      );
      expect(retained.isArchived, isTrue);
      expect(retained.linkedAccountId, isNull);
      expect(
        (await PlanRepository(
          database,
        ).watchForMonth(month).first).single.assigned,
        php(10000),
      );
    },
  );
}
