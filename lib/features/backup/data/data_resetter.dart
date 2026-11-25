import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../categories/data/default_categories.dart';

/// Deletes every record on this device's signed-out database, leaving it as a
/// fresh install: no accounts, account types, banks, transactions or plans, and only
/// the default categories.
class DataResetter {
  DataResetter(this._database);

  final AppDatabase _database;

  /// All or nothing: one transaction, so if anything fails the existing data
  /// is left unchanged and the error is rethrown.
  Future<void> resetAll() => _database.transaction(() async {
    // Children before parents, so foreign keys never dangle.
    await _database.delete(_database.monthlyPlans).go();
    await _database.delete(_database.transactions).go();
    await _database.delete(_database.categories).go();
    await _database.delete(_database.accounts).go();
    await _database.delete(_database.customAccountTypes).go();
    await _database.delete(_database.customBanks).go();
    await addCurrentDefaultCategories(_database);
  });
}

final dataResetterProvider = Provider<DataResetter>(
  (ref) => DataResetter(ref.watch(appDatabaseProvider)),
);
