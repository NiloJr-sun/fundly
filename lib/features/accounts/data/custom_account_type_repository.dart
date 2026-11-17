import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/account_rules.dart';
import '../domain/account_type.dart';
import '../domain/custom_account_type.dart';
import '../domain/custom_account_type_rules.dart';
import '../domain/custom_account_type_validation_exception.dart';
import 'account_row_mapping.dart';

/// Reads and writes [CustomAccountType]s, enforcing their rules before
/// anything reaches the database.
class CustomAccountTypeRepository {
  CustomAccountTypeRepository(this._database, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _now;

  $CustomAccountTypesTable get _types => _database.customAccountTypes;

  /// Every custom type, ordered by name ignoring case.
  Stream<List<CustomAccountType>> watchAll() => _database
      .select(_types)
      .watch()
      .map(
        (rows) => [
          for (final row in rows) row.toDomain(),
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
      );

  /// Creates a type whose accounts follow [baseType]'s rules.
  ///
  /// Throws [CustomAccountTypeValidationException] when a rule is broken.
  Future<CustomAccountType> create({
    required String name,
    required AccountType baseType,
  }) async {
    final trimmedName = await _validName(name);
    final row = await _database
        .into(_types)
        .insertReturning(
          CustomAccountTypesCompanion.insert(
            name: trimmedName,
            baseType: baseType,
            createdAt: _now().toUtc(),
          ),
        );
    return row.toDomain();
  }

  /// Renames type [id] and/or changes its [baseType]. The base type (and so
  /// its class) can change only while no account, active or archived, uses
  /// the type: changing it would change those accounts' balances and could
  /// make their transactions invalid.
  ///
  /// Throws [CustomAccountTypeValidationException] when a rule is broken, or
  /// [StateError] if the type does not exist.
  Future<CustomAccountType> update(
    int id, {
    String? name,
    AccountType? baseType,
  }) => _database.transaction(() async {
    final existing = await (_database.select(
      _types,
    )..where((type) => type.id.equals(id))).getSingleOrNull();
    if (existing == null) throw StateError('Account type $id does not exist.');

    final trimmedName = name == null
        ? null
        : await _validName(name, excludingId: id);
    final changesBase = baseType != null && baseType != existing.baseType;
    if (changesBase && await _accountCount(id) > 0) {
      throw const CustomAccountTypeValidationException(
        CustomAccountTypeValidationError.baseTypeInUse,
      );
    }

    final rows =
        await (_database.update(
          _types,
        )..where((type) => type.id.equals(id))).writeReturning(
          CustomAccountTypesCompanion(
            name: Value.absentIfNull(trimmedName),
            baseType: changesBase ? Value(baseType) : const Value.absent(),
          ),
        );
    return rows.single.toDomain();
  });

  /// Deletes type [id] if no account, active or archived, uses it.
  ///
  /// Throws [CustomAccountTypeValidationException] with
  /// [CustomAccountTypeValidationError.inUse] if an account uses it, or
  /// [StateError] if the type does not exist.
  Future<void> delete(int id) => _database.transaction(() async {
    if (await _accountCount(id) > 0) {
      throw const CustomAccountTypeValidationException(
        CustomAccountTypeValidationError.inUse,
      );
    }
    final deleted = await (_database.delete(
      _types,
    )..where((type) => type.id.equals(id))).go();
    if (deleted == 0) throw StateError('Account type $id does not exist.');
  });

  /// How many accounts, active or archived, use type [id].
  Future<int> _accountCount(int id) {
    final accounts = _database.accounts;
    final usage = accounts.id.count();
    return (_database.selectOnly(accounts)
          ..addColumns([usage])
          ..where(accounts.customTypeId.equals(id)))
        .map((row) => row.read(usage)!)
        .getSingle();
  }

  /// Returns the trimmed name, or throws if it is invalid or already used.
  /// Names follow the account-name rules.
  Future<String> _validName(String name, {int? excludingId}) async {
    switch (validateAccountName(name)) {
      case AccountNameError.empty:
        throw const CustomAccountTypeValidationException(
          CustomAccountTypeValidationError.nameEmpty,
        );
      case AccountNameError.tooLong:
        throw const CustomAccountTypeValidationException(
          CustomAccountTypeValidationError.nameTooLong,
        );
      case null:
        break;
    }

    final trimmed = name.trim();
    if (isBuiltInAccountTypeName(trimmed)) {
      throw const CustomAccountTypeValidationException(
        CustomAccountTypeValidationError.nameTaken,
      );
    }
    // The column is COLLATE NOCASE, so this comparison ignores case.
    final query = _database.select(_types)
      ..where((type) {
        final sameName = type.name.equals(trimmed);
        return excludingId == null
            ? sameName
            : sameName & type.id.equals(excludingId).not();
      });
    if (await query.getSingleOrNull() != null) {
      throw const CustomAccountTypeValidationException(
        CustomAccountTypeValidationError.nameTaken,
      );
    }
    return trimmed;
  }
}

final customAccountTypeRepositoryProvider =
    Provider<CustomAccountTypeRepository>(
      (ref) => CustomAccountTypeRepository(ref.watch(appDatabaseProvider)),
    );
