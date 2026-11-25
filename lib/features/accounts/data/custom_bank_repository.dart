import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/record_id.dart';
import '../../../core/sync/synced_store.dart';
import '../domain/account_rules.dart';
import '../domain/bank.dart';
import '../domain/custom_bank.dart';
import 'account_row_mapping.dart';
import 'synced_custom_bank_repository.dart';

/// Reads and writes [CustomBank]s, enforcing their rules before anything
/// reaches the database (docs/BANKS_PLAN.md, B-5).
class CustomBankRepository {
  CustomBankRepository(this._database, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _now;

  $CustomBanksTable get _banks => _database.customBanks;

  /// Every custom bank, ordered by name ignoring case.
  Stream<List<CustomBank>> watchAll() => _database
      .select(_banks)
      .watch()
      .map((rows) => sortedBanks([for (final row in rows) row.toDomain()]));

  /// Adds a bank named [name].
  ///
  /// Throws [CustomBankValidationException] when a rule is broken.
  Future<CustomBank> create(String name) => _database.transaction(() async {
    final trimmedName = await _validName(name);
    final row = await _database
        .into(_banks)
        .insertReturning(
          CustomBanksCompanion.insert(
            name: trimmedName,
            createdAt: _now().toUtc(),
          ),
        );
    return row.toDomain();
  });

  /// Renames bank [id].
  ///
  /// Throws [CustomBankValidationException] when a rule is broken, or
  /// [StateError] if the bank does not exist.
  Future<CustomBank> rename(String id, String name) =>
      _database.transaction(() async {
        final trimmedName = await _validName(name, excludingId: id);
        final rows =
            await (_database.update(_banks)
                  ..where((bank) => bank.id.equals(rowIdOf(id))))
                .writeReturning(CustomBanksCompanion(name: Value(trimmedName)));
        if (rows.isEmpty) throw StateError('Bank $id does not exist.');
        return rows.single.toDomain();
      });

  /// Deletes bank [id] if no account, active or archived, belongs to it.
  ///
  /// Throws [CustomBankValidationException] with
  /// [CustomBankValidationError.inUse] if an account uses it, or [StateError]
  /// if the bank does not exist.
  Future<void> delete(String id) => _database.transaction(() async {
    final accounts = _database.accounts;
    final usage = accounts.id.count();
    final used =
        await (_database.selectOnly(accounts)
              ..addColumns([usage])
              ..where(accounts.customBankId.equals(rowIdOf(id))))
            .map((row) => row.read(usage)!)
            .getSingle();
    if (used > 0) {
      throw const CustomBankValidationException(
        CustomBankValidationError.inUse,
      );
    }
    final deleted = await (_database.delete(
      _banks,
    )..where((bank) => bank.id.equals(rowIdOf(id)))).go();
    if (deleted == 0) throw StateError('Bank $id does not exist.');
  });

  /// Returns the trimmed name, or throws if it is invalid or already used.
  Future<String> _validName(String name, {String? excludingId}) async {
    final trimmed = checkedCustomBankName(name);
    // The column is COLLATE NOCASE, so this comparison ignores case.
    final query = _database.select(_banks)
      ..where((bank) {
        final sameName = bank.name.equals(trimmed);
        return excludingId == null
            ? sameName
            : sameName & bank.id.equals(rowIdOf(excludingId)).not();
      });
    if (await query.getSingleOrNull() != null) {
      throw const CustomBankValidationException(
        CustomBankValidationError.nameTaken,
      );
    }
    return trimmed;
  }
}

/// [name] trimmed, after the rules that need no other records: the
/// account-name rules, and not a built-in bank's name. Throws
/// [CustomBankValidationException] otherwise.
String checkedCustomBankName(String name) {
  switch (validateAccountName(name)) {
    case AccountNameError.empty:
      throw const CustomBankValidationException(
        CustomBankValidationError.nameEmpty,
      );
    case AccountNameError.tooLong:
      throw const CustomBankValidationException(
        CustomBankValidationError.nameTooLong,
      );
    case null:
      break;
  }
  final trimmed = name.trim();
  if (isBuiltInBankName(trimmed)) {
    throw const CustomBankValidationException(
      CustomBankValidationError.nameTaken,
    );
  }
  return trimmed;
}

/// [banks] ordered by name ignoring case.
List<CustomBank> sortedBanks(List<CustomBank> banks) =>
    banks..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

/// The active store's custom banks: the signed-in space's synchronized store,
/// or this device's database.
final customBankRepositoryProvider = Provider<CustomBankRepository>((ref) {
  final synced = ref.watch(syncedStoreProvider);
  return synced == null
      ? CustomBankRepository(ref.watch(appDatabaseProvider))
      : SyncedCustomBankRepository(synced.database);
});
