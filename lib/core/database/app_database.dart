import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/accounts/data/accounts_table.dart';
import '../../features/accounts/domain/account_type.dart';

part 'app_database.g.dart';

/// The app's local SQLite database.
///
/// Schema changes must bump [schemaVersion], add a migration step, and run
/// `dart run drift_dev make-migrations` to snapshot the schema and generate a
/// migration test. Call out every schema change before making it (CLAUDE.md
/// §8).
@DriftDatabase(tables: [Accounts])
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database, or [executor] if given (e.g. in tests).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'fundly'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
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
