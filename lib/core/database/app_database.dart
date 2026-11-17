import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/accounts/data/accounts_table.dart';
import '../../features/accounts/data/custom_account_types_table.dart';
import '../../features/accounts/domain/account_type.dart';
import '../../features/categories/data/categories_table.dart';
import '../../features/categories/data/default_categories.dart';
import '../../features/categories/data/liability_plan_categories.dart';
import '../../features/categories/domain/category.dart';
import '../../features/plans/data/monthly_plans_table.dart';
import '../../features/transactions/data/transactions_table.dart';
import '../../features/transactions/domain/transaction_type.dart';
import '../time/calendar_date.dart';
import '../time/calendar_month.dart';
import 'app_database.steps.dart';
import 'calendar_date_converter.dart';
import 'calendar_month_converter.dart';

part 'app_database.g.dart';

/// The app's local SQLite database.
///
/// Schema changes must bump [schemaVersion], add a migration step, and run
/// `dart run drift_dev make-migrations` to snapshot the schema and generate a
/// migration test. Call out every schema change before making it (CLAUDE.md
/// §8).
@DriftDatabase(
  tables: [
    CustomAccountTypes,
    Accounts,
    Categories,
    Transactions,
    MonthlyPlans,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database, or [executor] if given (e.g. in tests).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'fundly'));

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await addCurrentDefaultCategories(this);
    },
    onUpgrade: stepByStep(
      // v2: add categories with the fixed seeded list (G1).
      from1To2: (m, schema) async {
        await m.createTable(schema.categories);
        await seedDefaultCategories(this);
      },
      // v3: add transactions and their lookup indexes.
      from2To3: (m, schema) async {
        await m.createTable(schema.transactions);
        await m.createIndex(schema.transactionsDate);
        await m.createIndex(schema.transactionsSourceAccount);
        await m.createIndex(schema.transactionsDestinationAccount);
      },
      // v4: categories can be archived (task 4.1).
      from3To4: (m, schema) async {
        await m.addColumn(schema.categories, schema.categories.isArchived);
      },
      // v5: monthly plans per spending category (task 4.2).
      from4To5: (m, schema) async {
        await m.createTable(schema.monthlyPlans);
      },
      // v6: planned amount becomes an optional target, and plans gain an
      // assigned amount. Existing plans keep their amount as both, so what
      // was "left" before is "available" now. SQLite cannot make a column
      // nullable in place, so the table is rebuilt.
      from5To6: (m, schema) async {
        await m.alterTable(
          TableMigration(
            schema.monthlyPlans,
            columnTransformer: {
              schema.monthlyPlans.targetAmountMinor:
                  const CustomExpression<int>('planned_amount_minor'),
              schema.monthlyPlans.assignedAmountMinor:
                  const CustomExpression<int>('planned_amount_minor'),
            },
          ),
        );
      },
      // v7: user-created account types. Existing accounts keep their
      // built-in type (no custom type).
      from6To7: (m, schema) async {
        await m.createTable(schema.customAccountTypes);
        await m.addColumn(schema.accounts, schema.accounts.customTypeId);
      },
      // v8: spending categories get a Plans page group. Existing categories
      // join the default Spending group.
      from7To8: (m, schema) async {
        await m.addColumn(schema.categories, schema.categories.planGroup);
      },
      // v9: one asset account can be the budget account that funds Ready to
      // assign. No account is one until the user chooses.
      from8To9: (m, schema) async {
        await m.addColumn(schema.accounts, schema.accounts.isBudgetAccount);
        await m.createIndex(schema.accountsOneBudgetAccount);
      },
      // v10: stable links between liability accounts and their Plans rows.
      from9To10: (m, schema) async {
        await m.alterTable(
          TableMigration(
            schema.categories,
            newColumns: [schema.categories.linkedAccountId],
          ),
        );
        await addCurrentDefaultCategories(this);
        await syncLiabilityPlanCategories(this);
      },
      // v11: Plans rows can be archived independently across all months.
      from10To11: (m, schema) async {
        await m.addColumn(schema.categories, schema.categories.isPlanArchived);
      },
      // v12: permanent Plans deletion leaves its category/account intact.
      from11To12: (m, schema) async {
        await m.addColumn(schema.categories, schema.categories.isPlanDeleted);
      },
    ),
    beforeOpen: (details) async {
      // SQLite leaves foreign keys off by default.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// The single [AppDatabase] for the app. Override it in tests.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
