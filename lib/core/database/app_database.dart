import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/accounts/data/accounts_table.dart';
import '../../features/accounts/domain/account_type.dart';
import '../../features/categories/data/categories_table.dart';
import '../../features/categories/data/default_categories.dart';
import '../../features/categories/domain/category.dart';
import '../../features/transactions/data/transactions_table.dart';
import '../../features/transactions/domain/transaction_type.dart';
import '../time/calendar_date.dart';
import 'app_database.steps.dart';
import 'calendar_date_converter.dart';

part 'app_database.g.dart';

/// The app's local SQLite database.
///
/// Schema changes must bump [schemaVersion], add a migration step, and run
/// `dart run drift_dev make-migrations` to snapshot the schema and generate a
/// migration test. Call out every schema change before making it (CLAUDE.md
/// §8).
@DriftDatabase(tables: [Accounts, Categories, Transactions])
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database, or [executor] if given (e.g. in tests).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'fundly'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedDefaultCategories(this);
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
