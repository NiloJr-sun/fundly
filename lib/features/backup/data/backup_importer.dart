import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/calendar_month.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/account_rules.dart';
import '../../accounts/domain/account_type.dart';
import '../../accounts/domain/custom_account_type_rules.dart';
import '../../categories/data/liability_plan_categories.dart';
import '../../categories/domain/category.dart';
import '../../categories/domain/category_rules.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_rules.dart';
import '../../transactions/domain/transaction_type.dart';
import 'backup_exporter.dart';

/// Why a file cannot be restored.
enum BackupImportProblem {
  /// Not JSON, or not a Fundly backup.
  notABackup,

  /// Written by a newer version of Fundly, with a format this one can't read.
  newerFormat,

  /// A Fundly backup, but a record is missing data or breaks a rule.
  invalidData,
}

class BackupImportException implements Exception {
  const BackupImportException(this.problem, [this.detail = '']);

  final BackupImportProblem problem;

  /// Where the problem is, e.g. `accounts[2].name: expected text`. Empty when
  /// there is nothing more specific to say.
  final String detail;

  @override
  String toString() => 'BackupImportException(${problem.name}: $detail)';
}

/// How many records of each kind a backup or the database holds.
@immutable
final class BackupCounts {
  const BackupCounts({
    required this.customAccountTypes,
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.monthlyPlans,
  });

  final int customAccountTypes;
  final int accounts;
  final int categories;
  final int transactions;
  final int monthlyPlans;

  @override
  bool operator ==(Object other) =>
      other is BackupCounts &&
      other.customAccountTypes == customAccountTypes &&
      other.accounts == accounts &&
      other.categories == categories &&
      other.transactions == transactions &&
      other.monthlyPlans == monthlyPlans;

  @override
  int get hashCode => Object.hash(
    customAccountTypes,
    accounts,
    categories,
    transactions,
    monthlyPlans,
  );
}

/// A backup that passed every check and is ready to restore.
@immutable
final class BackupSnapshot {
  const BackupSnapshot._(
    this.exportedAt,
    this._customAccountTypes,
    this._accounts,
    this._categories,
    this._transactions,
    this._monthlyPlans,
  );

  /// When the backup was made, in UTC.
  final DateTime exportedAt;

  final List<CustomAccountTypesCompanion> _customAccountTypes;
  final List<AccountsCompanion> _accounts;
  final List<CategoriesCompanion> _categories;
  final List<TransactionsCompanion> _transactions;
  final List<MonthlyPlansCompanion> _monthlyPlans;

  BackupCounts get counts => BackupCounts(
    customAccountTypes: _customAccountTypes.length,
    accounts: _accounts.length,
    categories: _categories.length,
    transactions: _transactions.length,
    monthlyPlans: _monthlyPlans.length,
  );
}

/// Restores a backup written by [BackupExporter] (format 1 to 5),
/// replacing all data.
///
/// [parse] checks the whole file before anything is touched: the header,
/// every field's type, enum values, dates, currency, references between
/// records, and the same rules the app applies when records are created. The
/// one exception is that archived accounts and categories may have
/// transactions, as they can in the app. [replaceAll] then swaps every table
/// in one transaction, with the database's own checks as a final safety net;
/// if anything fails, nothing changes.
class BackupImporter {
  BackupImporter(this._database);

  final AppDatabase _database;

  /// Parses and checks [contents]; see [parseBackup].
  BackupSnapshot parse(String contents) => parseBackup(contents);

  /// What the database holds now, to compare with a backup.
  Future<BackupCounts> currentCounts() async => BackupCounts(
    customAccountTypes: await _count(_database.customAccountTypes),
    accounts: await _count(_database.accounts),
    categories: await _count(_database.categories),
    transactions: await _count(_database.transactions),
    monthlyPlans: await _count(_database.monthlyPlans),
  );

  /// Replaces every record with [snapshot]'s, keeping their IDs. All or
  /// nothing: throws [BackupImportException] with
  /// [BackupImportProblem.invalidData] if the database rejects anything, and
  /// leaves the existing data unchanged.
  Future<void> replaceAll(BackupSnapshot snapshot) async {
    try {
      await _database.transaction(() async {
        // Children before parents, so foreign keys never dangle.
        await _database.delete(_database.monthlyPlans).go();
        await _database.delete(_database.transactions).go();
        await _database.delete(_database.categories).go();
        await _database.delete(_database.accounts).go();
        await _database.delete(_database.customAccountTypes).go();

        await _database.batch((batch) {
          batch
            ..insertAll(
              _database.customAccountTypes,
              snapshot._customAccountTypes,
            )
            ..insertAll(_database.accounts, snapshot._accounts)
            ..insertAll(_database.categories, snapshot._categories)
            ..insertAll(_database.transactions, snapshot._transactions)
            ..insertAll(_database.monthlyPlans, snapshot._monthlyPlans);
        });
        await syncLiabilityPlanCategories(_database);
      });
    } on BackupImportException {
      rethrow;
    } on Object catch (error) {
      throw BackupImportException(
        BackupImportProblem.invalidData,
        'rejected by the database: $error',
      );
    }
  }

  Future<int> _count(TableInfo<Table, Object?> table) {
    final count = countAll();
    return (_database.selectOnly(
      table,
    )..addColumns([count])).map((row) => row.read(count)!).getSingle();
  }
}

/// Parses and checks a backup file's [contents] without touching the
/// database. Throws [BackupImportException] when it cannot be restored.
BackupSnapshot parseBackup(String contents) {
  final Object? decoded;
  try {
    decoded = jsonDecode(contents);
  } on FormatException {
    throw const BackupImportException(BackupImportProblem.notABackup);
  }
  if (decoded is! Map<String, Object?> || decoded['app'] != 'fundly') {
    throw const BackupImportException(BackupImportProblem.notABackup);
  }
  final header = _Reader(decoded, 'backup');
  final formatVersion = header.integer('formatVersion');
  if (formatVersion > BackupExporter.formatVersion) {
    throw const BackupImportException(BackupImportProblem.newerFormat);
  }
  if (formatVersion < 1) header.fail('formatVersion', 'unknown version');
  return _Parser(header, formatVersion).parse();
}

/// Turns the checked JSON into database rows, record by record.
class _Parser {
  _Parser(this.header, this.formatVersion);

  final _Reader header;

  /// Format 1 has no category `planGroup`; those categories restore into
  /// the default group. Formats 1 and 2 have no `isBudgetAccount`; they
  /// restore with no budget account. Formats 1–4 have no independent Plans
  /// archive flag, which defaults to false.
  final int formatVersion;

  bool _hasBudgetAccount = false;

  final _customTypes = <int, AccountType>{};
  final _customTypeNames = <String>{};
  final _accounts = <int, Account>{};
  final _categories = <int, Category>{};
  final _seenIds = <String, Set<int>>{};

  BackupSnapshot parse() {
    final exportedAt = header.timestamp('exportedAt');
    final customTypes = [
      for (final (i, json) in header.list('customAccountTypes').indexed)
        _customType(_Reader.of(json, 'customAccountTypes[$i]')),
    ];
    final accounts = [
      for (final (i, json) in header.list('accounts').indexed)
        _account(_Reader.of(json, 'accounts[$i]')),
    ];
    final categories = [
      for (final (i, json) in header.list('categories').indexed)
        _category(_Reader.of(json, 'categories[$i]')),
    ];
    final transactions = [
      for (final (i, json) in header.list('transactions').indexed)
        _transaction(_Reader.of(json, 'transactions[$i]')),
    ];
    final plans = <MonthlyPlansCompanion>[];
    final planKeys = <(String, int)>{};
    for (final (i, json) in header.list('monthlyPlans').indexed) {
      final reader = _Reader.of(json, 'monthlyPlans[$i]');
      final plan = _plan(reader);
      final key = (plan.month.value.toIsoString(), plan.categoryId.value);
      if (!planKeys.add(key)) {
        reader.fail('month', 'two plans for one category in one month');
      }
      plans.add(plan);
    }
    // Include generated liability rows in the preview counts too. Do this
    // after checking original references so synthesis cannot repair a broken
    // transaction or plan reference in the file.
    _addMissingLiabilityRows(categories);
    return BackupSnapshot._(
      exportedAt,
      customTypes,
      accounts,
      categories,
      transactions,
      plans,
    );
  }

  void _addMissingLiabilityRows(List<CategoriesCompanion> rows) {
    var nextId =
        rows.fold<int>(
          0,
          (maxId, row) => row.id.value > maxId ? row.id.value : maxId,
        ) +
        1;
    for (final account in _accounts.values) {
      if (!account.type.isLiability ||
          account.isArchived ||
          _linkedAccounts.contains(account.id)) {
        continue;
      }
      var name = account.name;
      var suffixIndex = 0;
      while (_categoryNames.contains(name.toLowerCase())) {
        final suffix =
            ' (debt ${account.id}${suffixIndex == 0 ? '' : '-$suffixIndex'})';
        final prefixLength = 40 - suffix.length;
        name =
            '${account.name.substring(0, account.name.length > prefixLength ? prefixLength : account.name.length)}$suffix';
        suffixIndex++;
      }
      _categoryNames.add(name.toLowerCase());
      _linkedAccounts.add(account.id);
      rows.add(
        CategoriesCompanion.insert(
          id: Value(nextId++),
          name: name,
          kind: CategoryKind.spending,
          planGroup: const Value(PlanGroup.liability),
          linkedAccountId: Value(account.id),
        ),
      );
    }
  }

  int _id(_Reader reader, String kind) {
    final id = reader.integer('id');
    if (id <= 0) reader.fail('id', 'must be positive');
    if (!_seenIds.putIfAbsent(kind, () => {}).add(id)) {
      reader.fail('id', 'used twice');
    }
    return id;
  }

  String _name(_Reader reader, Set<String> used) {
    final name = reader.string('name');
    if (validateAccountName(name) != null || name.trim() != name) {
      reader.fail('name', 'must be 1-$maxAccountNameLength characters');
    }
    if (!used.add(name.toLowerCase())) reader.fail('name', 'used twice');
    return name;
  }

  CustomAccountTypesCompanion _customType(_Reader reader) {
    final id = _id(reader, 'customAccountTypes');
    final name = _name(reader, _customTypeNames);
    if (isBuiltInAccountTypeName(name)) {
      reader.fail('name', 'is a built-in type name');
    }
    final baseType = reader.enumValue('baseType', AccountType.values);
    _customTypes[id] = baseType;
    return CustomAccountTypesCompanion.insert(
      id: Value(id),
      name: name,
      baseType: baseType,
      createdAt: reader.timestamp('createdAt'),
    );
  }

  final _accountNames = <String>{};

  AccountsCompanion _account(_Reader reader) {
    final id = _id(reader, 'accounts');
    final name = _name(reader, _accountNames);
    final type = reader.enumValue('type', AccountType.values);
    final customTypeId = reader.integerOrNull('customTypeId');
    if (customTypeId != null) {
      final base = _customTypes[customTypeId];
      if (base == null) reader.fail('customTypeId', 'no such account type');
      if (base != type) {
        reader.fail('customTypeId', 'account type is based on another type');
      }
    }
    final opening = reader.money('openingBalanceMinor');
    if (type.isLiability ? opening.minorUnits > 0 : opening.isNegative) {
      reader.fail('openingBalanceMinor', 'wrong sign for a ${type.name}');
    }
    final createdAt = reader.timestamp('createdAt');
    final isArchived = reader.boolean('isArchived');
    final isBudgetAccount =
        formatVersion >= 3 && reader.boolean('isBudgetAccount');
    if (isBudgetAccount) {
      if (_hasBudgetAccount) {
        reader.fail('isBudgetAccount', 'only one budget account is allowed');
      }
      if (type != AccountType.savingsCash || isArchived) {
        reader.fail(
          'isBudgetAccount',
          'must be an active Savings/Cash account',
        );
      }
      _hasBudgetAccount = true;
    }
    _accounts[id] = Account(
      id: id,
      name: name,
      type: type,
      openingBalance: opening,
      createdAt: createdAt,
      isArchived: isArchived,
      customTypeId: customTypeId,
      isBudgetAccount: isBudgetAccount,
    );
    return AccountsCompanion.insert(
      id: Value(id),
      name: name,
      type: type,
      openingBalanceMinor: opening.minorUnits,
      currencyCode: Value(opening.currencyCode),
      createdAt: createdAt,
      isArchived: Value(isArchived),
      customTypeId: Value(customTypeId),
      isBudgetAccount: Value(isBudgetAccount),
    );
  }

  final _categoryNames = <String>{};
  final _linkedAccounts = <int>{};

  CategoriesCompanion _category(_Reader reader) {
    final id = _id(reader, 'categories');
    final name = reader.string('name');
    if (validateCategoryName(name) != null || name.trim() != name) {
      reader.fail('name', 'must be 1-$maxCategoryNameLength characters');
    }
    if (!_categoryNames.add(name.toLowerCase())) {
      reader.fail('name', 'used twice');
    }
    final kind = reader.enumValue('kind', CategoryKind.values);
    final isArchived = reader.boolean('isArchived');
    final isPlanArchived =
        formatVersion >= 5 && reader.boolean('isPlanArchived');
    if (isPlanArchived && kind != CategoryKind.spending) {
      reader.fail('isPlanArchived', 'only spending categories have Plans rows');
    }
    final planGroup = formatVersion < 2
        ? PlanGroup.spending
        : reader.enumValue('planGroup', PlanGroup.values);
    if (kind == CategoryKind.inflow && planGroup != PlanGroup.spending) {
      reader.fail('planGroup', 'inflow categories have no group');
    }
    final linkedAccountId = formatVersion >= 4
        ? reader.integerOrNull('linkedAccountId')
        : null;
    if (linkedAccountId != null) {
      final account = _accounts[linkedAccountId];
      if (account == null ||
          !account.type.isLiability ||
          kind != CategoryKind.spending ||
          planGroup != PlanGroup.liability ||
          isArchived != account.isArchived ||
          !_linkedAccounts.add(linkedAccountId)) {
        reader.fail(
          'linkedAccountId',
          'must uniquely link a liability account with matching archive status',
        );
      }
    }
    _categories[id] = Category(
      id: id,
      name: name,
      kind: kind,
      isArchived: isArchived,
      isPlanArchived: isPlanArchived,
      planGroup: planGroup,
      linkedAccountId: linkedAccountId,
    );
    return CategoriesCompanion.insert(
      id: Value(id),
      name: name,
      kind: kind,
      isArchived: Value(isArchived),
      isPlanArchived: Value(isPlanArchived),
      planGroup: Value(planGroup),
      linkedAccountId: Value(linkedAccountId),
    );
  }

  /// Archived accounts and categories may hold history, so being archived is
  /// not a reason to reject a restored transaction.
  static const _allowedOnRestore = {
    TransactionValidationError.sourceAccountArchived,
    TransactionValidationError.destinationAccountArchived,
    TransactionValidationError.categoryArchived,
  };

  TransactionsCompanion _transaction(_Reader reader) {
    final id = _id(reader, 'transactions');
    final draft = TransactionDraft(
      type: reader.enumValue('type', TransactionType.values),
      amount: reader.money('amountMinor', currencyKey: 'currencyCode'),
      date: reader.date('date'),
      payee: reader.string('payee'),
      categoryId: reader.integerOrNull('categoryId'),
      sourceAccountId: reader.integerOrNull('sourceAccountId'),
      destinationAccountId: reader.integerOrNull('destinationAccountId'),
      note: reader.string('note'),
    );
    final errors = validateTransaction(
      draft,
      accounts: _accounts,
      categories: _categories,
    ).difference(_allowedOnRestore);
    if (errors.isNotEmpty) {
      reader.fail('', errors.map((error) => error.name).join(', '));
    }
    return TransactionsCompanion.insert(
      id: Value(id),
      type: draft.type,
      amountMinor: draft.amount.minorUnits,
      currencyCode: draft.amount.currencyCode,
      date: draft.date,
      payee: Value(draft.payee),
      categoryId: Value(draft.categoryId),
      sourceAccountId: Value(draft.sourceAccountId),
      destinationAccountId: Value(draft.destinationAccountId),
      note: Value(draft.note),
      createdAt: reader.timestamp('createdAt'),
      updatedAt: reader.timestamp('updatedAt'),
    );
  }

  MonthlyPlansCompanion _plan(_Reader reader) {
    final id = _id(reader, 'monthlyPlans');
    final categoryId = reader.integer('categoryId');
    final category = _categories[categoryId];
    if (category == null) reader.fail('categoryId', 'no such category');
    if (category.kind != CategoryKind.spending) {
      reader.fail('categoryId', 'plans need a spending category');
    }
    final assigned = reader.money(
      'assignedAmountMinor',
      currencyKey: 'currencyCode',
    );
    final target = reader.integerOrNull('targetAmountMinor');
    if (assigned.isNegative || (target != null && target < 0)) {
      reader.fail('assignedAmountMinor', 'amounts cannot be negative');
    }
    return MonthlyPlansCompanion.insert(
      id: Value(id),
      month: reader.month('month'),
      categoryId: categoryId,
      targetAmountMinor: Value(target),
      assignedAmountMinor: assigned.minorUnits,
      currencyCode: assigned.currencyCode,
      createdAt: reader.timestamp('createdAt'),
      updatedAt: reader.timestamp('updatedAt'),
    );
  }
}

/// Reads typed fields from one JSON object, naming [where] in every error.
class _Reader {
  _Reader(this._json, this.where);

  factory _Reader.of(Object? json, String where) {
    if (json is! Map<String, Object?>) {
      throw BackupImportException(
        BackupImportProblem.invalidData,
        '$where: expected an object',
      );
    }
    return _Reader(json, where);
  }

  final Map<String, Object?> _json;
  final String where;

  Never fail(String key, String message) => throw BackupImportException(
    BackupImportProblem.invalidData,
    key.isEmpty ? '$where: $message' : '$where.$key: $message',
  );

  T _field<T>(String key, String expected) {
    if (!_json.containsKey(key)) fail(key, 'missing');
    final value = _json[key];
    if (value is! T) fail(key, 'expected $expected');
    return value;
  }

  int integer(String key) => _field<int>(key, 'a whole number');
  int? integerOrNull(String key) => _field<int?>(key, 'a whole number or null');
  String string(String key) => _field<String>(key, 'text');
  bool boolean(String key) => _field<bool>(key, 'true or false');

  List<Object?> list(String key) => _field<List<Object?>>(key, 'a list');

  T enumValue<T extends Enum>(String key, List<T> values) {
    final name = string(key);
    for (final value in values) {
      if (value.name == name) return value;
    }
    fail(key, 'unknown value "$name"');
  }

  /// A UTC ISO-8601 timestamp, e.g. `2026-11-17T01:02:03.000Z`.
  DateTime timestamp(String key) {
    final text = string(key);
    final parsed = DateTime.tryParse(text);
    if (parsed == null || !parsed.isUtc) fail(key, 'expected a UTC timestamp');
    return parsed;
  }

  CalendarDate date(String key) {
    try {
      return CalendarDate.parse(string(key));
    } on FormatException {
      fail(key, 'expected YYYY-MM-DD');
    }
  }

  CalendarMonth month(String key) {
    try {
      return CalendarMonth.parse(string(key));
    } on FormatException {
      fail(key, 'expected YYYY-MM');
    }
  }

  /// Minor units in [key] with the currency in [currencyKey]. Only the
  /// app's currency is accepted (G6).
  Money money(String key, {String currencyKey = 'currencyCode'}) {
    final minorUnits = integer(key);
    final currency = string(currencyKey);
    if (currency != Account.defaultCurrency) {
      fail(currencyKey, 'only ${Account.defaultCurrency} is supported');
    }
    return Money(minorUnits: minorUnits, currencyCode: currency);
  }
}

final backupImporterProvider = Provider<BackupImporter>(
  (ref) => BackupImporter(ref.watch(appDatabaseProvider)),
);
