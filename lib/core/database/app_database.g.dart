// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CustomAccountTypesTable extends CustomAccountTypes
    with TableInfo<$CustomAccountTypesTable, CustomAccountTypeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomAccountTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE COLLATE NOCASE',
  );
  @override
  late final GeneratedColumnWithTypeConverter<AccountType, String> baseType =
      GeneratedColumn<String>(
        'base_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AccountType>($CustomAccountTypesTable.$converterbaseType);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, baseType, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_account_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomAccountTypeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomAccountTypeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomAccountTypeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      baseType: $CustomAccountTypesTable.$converterbaseType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}base_type'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CustomAccountTypesTable createAlias(String alias) {
    return $CustomAccountTypesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccountType, String, String> $converterbaseType =
      const EnumNameConverter<AccountType>(AccountType.values);
}

class CustomAccountTypeRow extends DataClass
    implements Insertable<CustomAccountTypeRow> {
  final int id;
  final String name;

  /// The built-in type whose rules accounts of this type follow. Stored by
  /// enum name, like `accounts.type`.
  final AccountType baseType;

  /// UTC instant.
  final DateTime createdAt;
  const CustomAccountTypeRow({
    required this.id,
    required this.name,
    required this.baseType,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['base_type'] = Variable<String>(
        $CustomAccountTypesTable.$converterbaseType.toSql(baseType),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CustomAccountTypesCompanion toCompanion(bool nullToAbsent) {
    return CustomAccountTypesCompanion(
      id: Value(id),
      name: Value(name),
      baseType: Value(baseType),
      createdAt: Value(createdAt),
    );
  }

  factory CustomAccountTypeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomAccountTypeRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      baseType: $CustomAccountTypesTable.$converterbaseType.fromJson(
        serializer.fromJson<String>(json['baseType']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'baseType': serializer.toJson<String>(
        $CustomAccountTypesTable.$converterbaseType.toJson(baseType),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CustomAccountTypeRow copyWith({
    int? id,
    String? name,
    AccountType? baseType,
    DateTime? createdAt,
  }) => CustomAccountTypeRow(
    id: id ?? this.id,
    name: name ?? this.name,
    baseType: baseType ?? this.baseType,
    createdAt: createdAt ?? this.createdAt,
  );
  CustomAccountTypeRow copyWithCompanion(CustomAccountTypesCompanion data) {
    return CustomAccountTypeRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      baseType: data.baseType.present ? data.baseType.value : this.baseType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomAccountTypeRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseType: $baseType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, baseType, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomAccountTypeRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.baseType == this.baseType &&
          other.createdAt == this.createdAt);
}

class CustomAccountTypesCompanion
    extends UpdateCompanion<CustomAccountTypeRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<AccountType> baseType;
  final Value<DateTime> createdAt;
  const CustomAccountTypesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.baseType = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CustomAccountTypesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required AccountType baseType,
    required DateTime createdAt,
  }) : name = Value(name),
       baseType = Value(baseType),
       createdAt = Value(createdAt);
  static Insertable<CustomAccountTypeRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? baseType,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (baseType != null) 'base_type': baseType,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CustomAccountTypesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<AccountType>? baseType,
    Value<DateTime>? createdAt,
  }) {
    return CustomAccountTypesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      baseType: baseType ?? this.baseType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (baseType.present) {
      map['base_type'] = Variable<String>(
        $CustomAccountTypesTable.$converterbaseType.toSql(baseType.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomAccountTypesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseType: $baseType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CustomBanksTable extends CustomBanks
    with TableInfo<$CustomBanksTable, CustomBankRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomBanksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE COLLATE NOCASE',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_banks';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomBankRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomBankRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomBankRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CustomBanksTable createAlias(String alias) {
    return $CustomBanksTable(attachedDatabase, alias);
  }
}

class CustomBankRow extends DataClass implements Insertable<CustomBankRow> {
  final int id;
  final String name;

  /// UTC instant.
  final DateTime createdAt;
  const CustomBankRow({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CustomBanksCompanion toCompanion(bool nullToAbsent) {
    return CustomBanksCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory CustomBankRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomBankRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CustomBankRow copyWith({int? id, String? name, DateTime? createdAt}) =>
      CustomBankRow(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
  CustomBankRow copyWithCompanion(CustomBanksCompanion data) {
    return CustomBankRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomBankRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomBankRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class CustomBanksCompanion extends UpdateCompanion<CustomBankRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  const CustomBanksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CustomBanksCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required DateTime createdAt,
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<CustomBankRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CustomBanksCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
  }) {
    return CustomBanksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomBanksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE COLLATE NOCASE',
  );
  @override
  late final GeneratedColumnWithTypeConverter<AccountType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AccountType>($AccountsTable.$convertertype);
  static const VerificationMeta _openingBalanceMinorMeta =
      const VerificationMeta('openingBalanceMinor');
  @override
  late final GeneratedColumn<int> openingBalanceMinor = GeneratedColumn<int>(
    'opening_balance_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PHP'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _customTypeIdMeta = const VerificationMeta(
    'customTypeId',
  );
  @override
  late final GeneratedColumn<int> customTypeId = GeneratedColumn<int>(
    'custom_type_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES custom_account_types (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _isBudgetAccountMeta = const VerificationMeta(
    'isBudgetAccount',
  );
  @override
  late final GeneratedColumn<bool> isBudgetAccount = GeneratedColumn<bool>(
    'is_budget_account',
    aliasedName,
    false,
    check: () =>
        BooleanExpressionOperators(isBudgetAccount).not() |
        type.equals('savingsCash'),
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_budget_account" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _bankKeyMeta = const VerificationMeta(
    'bankKey',
  );
  @override
  late final GeneratedColumn<String> bankKey = GeneratedColumn<String>(
    'bank_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (bank_key IS NULL OR (length(bank_key) BETWEEN 1 AND 32 AND bank_key NOT GLOB \'*[^a-z0-9]*\'))',
  );
  static const VerificationMeta _customBankIdMeta = const VerificationMeta(
    'customBankId',
  );
  @override
  late final GeneratedColumn<int> customBankId = GeneratedColumn<int>(
    'custom_bank_id',
    aliasedName,
    true,
    check: () => customBankId.isNull() | bankKey.isNull(),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES custom_banks (id) ON DELETE RESTRICT',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    openingBalanceMinor,
    currencyCode,
    createdAt,
    isArchived,
    customTypeId,
    isBudgetAccount,
    bankKey,
    customBankId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('opening_balance_minor')) {
      context.handle(
        _openingBalanceMinorMeta,
        openingBalanceMinor.isAcceptableOrUnknown(
          data['opening_balance_minor']!,
          _openingBalanceMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingBalanceMinorMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('custom_type_id')) {
      context.handle(
        _customTypeIdMeta,
        customTypeId.isAcceptableOrUnknown(
          data['custom_type_id']!,
          _customTypeIdMeta,
        ),
      );
    }
    if (data.containsKey('is_budget_account')) {
      context.handle(
        _isBudgetAccountMeta,
        isBudgetAccount.isAcceptableOrUnknown(
          data['is_budget_account']!,
          _isBudgetAccountMeta,
        ),
      );
    }
    if (data.containsKey('bank_key')) {
      context.handle(
        _bankKeyMeta,
        bankKey.isAcceptableOrUnknown(data['bank_key']!, _bankKeyMeta),
      );
    }
    if (data.containsKey('custom_bank_id')) {
      context.handle(
        _customBankIdMeta,
        customBankId.isAcceptableOrUnknown(
          data['custom_bank_id']!,
          _customBankIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $AccountsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      openingBalanceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_balance_minor'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      customTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}custom_type_id'],
      ),
      isBudgetAccount: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_budget_account'],
      )!,
      bankKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_key'],
      ),
      customBankId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}custom_bank_id'],
      ),
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccountType, String, String> $convertertype =
      const EnumNameConverter<AccountType>(AccountType.values);
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final int id;
  final String name;

  /// Stored by enum name (e.g. `credit`), so reordering [AccountType] is safe.
  /// Renaming a value requires a migration.
  final AccountType type;

  /// Signed minor units (centavos for PHP).
  final int openingBalanceMinor;
  final String currencyCode;

  /// UTC instant.
  final DateTime createdAt;
  final bool isArchived;

  /// The custom type the account is shown under, or null for its built-in
  /// [type]. When set, [type] equals that custom type's base type; the
  /// repository enforces this, because SQLite checks cannot see other tables.
  final int? customTypeId;

  /// Whether money coming into this account funds Ready to assign on Plans.
  /// Any number of Savings/Cash accounts can be budget accounts.
  final bool isBudgetAccount;

  /// The built-in bank the account belongs to (`Bank.key`), or null. Same
  /// shape as the server's check, `^[a-z0-9]{1,32}$`, which SQLite has no
  /// regular expressions for.
  final String? bankKey;

  /// The custom bank the account belongs to, or null; never together with
  /// [bankKey]. Column-level, so the v15 migration can add it to existing
  /// tables.
  final int? customBankId;
  const AccountRow({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalanceMinor,
    required this.currencyCode,
    required this.createdAt,
    required this.isArchived,
    this.customTypeId,
    required this.isBudgetAccount,
    this.bankKey,
    this.customBankId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>($AccountsTable.$convertertype.toSql(type));
    }
    map['opening_balance_minor'] = Variable<int>(openingBalanceMinor);
    map['currency_code'] = Variable<String>(currencyCode);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || customTypeId != null) {
      map['custom_type_id'] = Variable<int>(customTypeId);
    }
    map['is_budget_account'] = Variable<bool>(isBudgetAccount);
    if (!nullToAbsent || bankKey != null) {
      map['bank_key'] = Variable<String>(bankKey);
    }
    if (!nullToAbsent || customBankId != null) {
      map['custom_bank_id'] = Variable<int>(customBankId);
    }
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      openingBalanceMinor: Value(openingBalanceMinor),
      currencyCode: Value(currencyCode),
      createdAt: Value(createdAt),
      isArchived: Value(isArchived),
      customTypeId: customTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(customTypeId),
      isBudgetAccount: Value(isBudgetAccount),
      bankKey: bankKey == null && nullToAbsent
          ? const Value.absent()
          : Value(bankKey),
      customBankId: customBankId == null && nullToAbsent
          ? const Value.absent()
          : Value(customBankId),
    );
  }

  factory AccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $AccountsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      openingBalanceMinor: serializer.fromJson<int>(
        json['openingBalanceMinor'],
      ),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      customTypeId: serializer.fromJson<int?>(json['customTypeId']),
      isBudgetAccount: serializer.fromJson<bool>(json['isBudgetAccount']),
      bankKey: serializer.fromJson<String?>(json['bankKey']),
      customBankId: serializer.fromJson<int?>(json['customBankId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $AccountsTable.$convertertype.toJson(type),
      ),
      'openingBalanceMinor': serializer.toJson<int>(openingBalanceMinor),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isArchived': serializer.toJson<bool>(isArchived),
      'customTypeId': serializer.toJson<int?>(customTypeId),
      'isBudgetAccount': serializer.toJson<bool>(isBudgetAccount),
      'bankKey': serializer.toJson<String?>(bankKey),
      'customBankId': serializer.toJson<int?>(customBankId),
    };
  }

  AccountRow copyWith({
    int? id,
    String? name,
    AccountType? type,
    int? openingBalanceMinor,
    String? currencyCode,
    DateTime? createdAt,
    bool? isArchived,
    Value<int?> customTypeId = const Value.absent(),
    bool? isBudgetAccount,
    Value<String?> bankKey = const Value.absent(),
    Value<int?> customBankId = const Value.absent(),
  }) => AccountRow(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
    currencyCode: currencyCode ?? this.currencyCode,
    createdAt: createdAt ?? this.createdAt,
    isArchived: isArchived ?? this.isArchived,
    customTypeId: customTypeId.present ? customTypeId.value : this.customTypeId,
    isBudgetAccount: isBudgetAccount ?? this.isBudgetAccount,
    bankKey: bankKey.present ? bankKey.value : this.bankKey,
    customBankId: customBankId.present ? customBankId.value : this.customBankId,
  );
  AccountRow copyWithCompanion(AccountsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      openingBalanceMinor: data.openingBalanceMinor.present
          ? data.openingBalanceMinor.value
          : this.openingBalanceMinor,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      customTypeId: data.customTypeId.present
          ? data.customTypeId.value
          : this.customTypeId,
      isBudgetAccount: data.isBudgetAccount.present
          ? data.isBudgetAccount.value
          : this.isBudgetAccount,
      bankKey: data.bankKey.present ? data.bankKey.value : this.bankKey,
      customBankId: data.customBankId.present
          ? data.customBankId.value
          : this.customBankId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('openingBalanceMinor: $openingBalanceMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('customTypeId: $customTypeId, ')
          ..write('isBudgetAccount: $isBudgetAccount, ')
          ..write('bankKey: $bankKey, ')
          ..write('customBankId: $customBankId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    openingBalanceMinor,
    currencyCode,
    createdAt,
    isArchived,
    customTypeId,
    isBudgetAccount,
    bankKey,
    customBankId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.openingBalanceMinor == this.openingBalanceMinor &&
          other.currencyCode == this.currencyCode &&
          other.createdAt == this.createdAt &&
          other.isArchived == this.isArchived &&
          other.customTypeId == this.customTypeId &&
          other.isBudgetAccount == this.isBudgetAccount &&
          other.bankKey == this.bankKey &&
          other.customBankId == this.customBankId);
}

class AccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<AccountType> type;
  final Value<int> openingBalanceMinor;
  final Value<String> currencyCode;
  final Value<DateTime> createdAt;
  final Value<bool> isArchived;
  final Value<int?> customTypeId;
  final Value<bool> isBudgetAccount;
  final Value<String?> bankKey;
  final Value<int?> customBankId;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.openingBalanceMinor = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.customTypeId = const Value.absent(),
    this.isBudgetAccount = const Value.absent(),
    this.bankKey = const Value.absent(),
    this.customBankId = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required AccountType type,
    required int openingBalanceMinor,
    this.currencyCode = const Value.absent(),
    required DateTime createdAt,
    this.isArchived = const Value.absent(),
    this.customTypeId = const Value.absent(),
    this.isBudgetAccount = const Value.absent(),
    this.bankKey = const Value.absent(),
    this.customBankId = const Value.absent(),
  }) : name = Value(name),
       type = Value(type),
       openingBalanceMinor = Value(openingBalanceMinor),
       createdAt = Value(createdAt);
  static Insertable<AccountRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? openingBalanceMinor,
    Expression<String>? currencyCode,
    Expression<DateTime>? createdAt,
    Expression<bool>? isArchived,
    Expression<int>? customTypeId,
    Expression<bool>? isBudgetAccount,
    Expression<String>? bankKey,
    Expression<int>? customBankId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (openingBalanceMinor != null)
        'opening_balance_minor': openingBalanceMinor,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (createdAt != null) 'created_at': createdAt,
      if (isArchived != null) 'is_archived': isArchived,
      if (customTypeId != null) 'custom_type_id': customTypeId,
      if (isBudgetAccount != null) 'is_budget_account': isBudgetAccount,
      if (bankKey != null) 'bank_key': bankKey,
      if (customBankId != null) 'custom_bank_id': customBankId,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<AccountType>? type,
    Value<int>? openingBalanceMinor,
    Value<String>? currencyCode,
    Value<DateTime>? createdAt,
    Value<bool>? isArchived,
    Value<int?>? customTypeId,
    Value<bool>? isBudgetAccount,
    Value<String?>? bankKey,
    Value<int?>? customBankId,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
      customTypeId: customTypeId ?? this.customTypeId,
      isBudgetAccount: isBudgetAccount ?? this.isBudgetAccount,
      bankKey: bankKey ?? this.bankKey,
      customBankId: customBankId ?? this.customBankId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $AccountsTable.$convertertype.toSql(type.value),
      );
    }
    if (openingBalanceMinor.present) {
      map['opening_balance_minor'] = Variable<int>(openingBalanceMinor.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (customTypeId.present) {
      map['custom_type_id'] = Variable<int>(customTypeId.value);
    }
    if (isBudgetAccount.present) {
      map['is_budget_account'] = Variable<bool>(isBudgetAccount.value);
    }
    if (bankKey.present) {
      map['bank_key'] = Variable<String>(bankKey.value);
    }
    if (customBankId.present) {
      map['custom_bank_id'] = Variable<int>(customBankId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('openingBalanceMinor: $openingBalanceMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('customTypeId: $customTypeId, ')
          ..write('isBudgetAccount: $isBudgetAccount, ')
          ..write('bankKey: $bankKey, ')
          ..write('customBankId: $customBankId')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE COLLATE NOCASE',
  );
  @override
  late final GeneratedColumnWithTypeConverter<CategoryKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CategoryKind>($CategoriesTable.$converterkind);
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPlanArchivedMeta = const VerificationMeta(
    'isPlanArchived',
  );
  @override
  late final GeneratedColumn<bool> isPlanArchived = GeneratedColumn<bool>(
    'is_plan_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_plan_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPlanDeletedMeta = const VerificationMeta(
    'isPlanDeleted',
  );
  @override
  late final GeneratedColumn<bool> isPlanDeleted = GeneratedColumn<bool>(
    'is_plan_deleted',
    aliasedName,
    false,
    check: () =>
        isPlanDeleted.equals(false) |
        (isPlanArchived.equals(true) & kind.equals('spending')),
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_plan_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<PlanGroup, String> planGroup =
      GeneratedColumn<String>(
        'plan_group',
        aliasedName,
        false,
        check: () => planGroup.isIn(const ['spending', 'savings', 'liability']),
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('spending'),
      ).withConverter<PlanGroup>($CategoriesTable.$converterplanGroup);
  static const VerificationMeta _linkedAccountIdMeta = const VerificationMeta(
    'linkedAccountId',
  );
  @override
  late final GeneratedColumn<int> linkedAccountId = GeneratedColumn<int>(
    'linked_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES accounts (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _defaultTargetMinorMeta =
      const VerificationMeta('defaultTargetMinor');
  @override
  late final GeneratedColumn<int> defaultTargetMinor = GeneratedColumn<int>(
    'default_target_minor',
    aliasedName,
    true,
    check: () =>
        defaultTargetMinor.isNull() |
        (ComparableExpr(defaultTargetMinor).isBiggerOrEqualValue(0) &
            kind.equals('spending')),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    isArchived,
    isPlanArchived,
    isPlanDeleted,
    planGroup,
    linkedAccountId,
    defaultTargetMinor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('is_plan_archived')) {
      context.handle(
        _isPlanArchivedMeta,
        isPlanArchived.isAcceptableOrUnknown(
          data['is_plan_archived']!,
          _isPlanArchivedMeta,
        ),
      );
    }
    if (data.containsKey('is_plan_deleted')) {
      context.handle(
        _isPlanDeletedMeta,
        isPlanDeleted.isAcceptableOrUnknown(
          data['is_plan_deleted']!,
          _isPlanDeletedMeta,
        ),
      );
    }
    if (data.containsKey('linked_account_id')) {
      context.handle(
        _linkedAccountIdMeta,
        linkedAccountId.isAcceptableOrUnknown(
          data['linked_account_id']!,
          _linkedAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('default_target_minor')) {
      context.handle(
        _defaultTargetMinorMeta,
        defaultTargetMinor.isAcceptableOrUnknown(
          data['default_target_minor']!,
          _defaultTargetMinorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: $CategoriesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      isPlanArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_plan_archived'],
      )!,
      isPlanDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_plan_deleted'],
      )!,
      planGroup: $CategoriesTable.$converterplanGroup.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}plan_group'],
        )!,
      ),
      linkedAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}linked_account_id'],
      ),
      defaultTargetMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_target_minor'],
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CategoryKind, String, String> $converterkind =
      const EnumNameConverter<CategoryKind>(CategoryKind.values);
  static JsonTypeConverter2<PlanGroup, String, String> $converterplanGroup =
      const EnumNameConverter<PlanGroup>(PlanGroup.values);
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final int id;
  final String name;

  /// Stored by enum name (`spending` or `inflow`).
  final CategoryKind kind;
  final bool isArchived;

  /// Hides only the Plans row, independently of category/account archiving.
  final bool isPlanArchived;

  /// Keeps a permanently deleted Plans row from being recreated.
  final bool isPlanDeleted;

  /// The Plans page section, stored by enum name. Inflow categories keep the
  /// default; the repository only lets spending categories change it.
  final PlanGroup planGroup;

  /// Managed Plans row for one liability account; normal categories have none.
  final int? linkedAccountId;

  /// The Target, in minor units, for months without their own plan; `null`
  /// for no Target. Only spending categories have one, debt rows included.
  final int? defaultTargetMinor;
  const CategoryRow({
    required this.id,
    required this.name,
    required this.kind,
    required this.isArchived,
    required this.isPlanArchived,
    required this.isPlanDeleted,
    required this.planGroup,
    this.linkedAccountId,
    this.defaultTargetMinor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['kind'] = Variable<String>(
        $CategoriesTable.$converterkind.toSql(kind),
      );
    }
    map['is_archived'] = Variable<bool>(isArchived);
    map['is_plan_archived'] = Variable<bool>(isPlanArchived);
    map['is_plan_deleted'] = Variable<bool>(isPlanDeleted);
    {
      map['plan_group'] = Variable<String>(
        $CategoriesTable.$converterplanGroup.toSql(planGroup),
      );
    }
    if (!nullToAbsent || linkedAccountId != null) {
      map['linked_account_id'] = Variable<int>(linkedAccountId);
    }
    if (!nullToAbsent || defaultTargetMinor != null) {
      map['default_target_minor'] = Variable<int>(defaultTargetMinor);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      isArchived: Value(isArchived),
      isPlanArchived: Value(isPlanArchived),
      isPlanDeleted: Value(isPlanDeleted),
      planGroup: Value(planGroup),
      linkedAccountId: linkedAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedAccountId),
      defaultTargetMinor: defaultTargetMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultTargetMinor),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: $CategoriesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      isPlanArchived: serializer.fromJson<bool>(json['isPlanArchived']),
      isPlanDeleted: serializer.fromJson<bool>(json['isPlanDeleted']),
      planGroup: $CategoriesTable.$converterplanGroup.fromJson(
        serializer.fromJson<String>(json['planGroup']),
      ),
      linkedAccountId: serializer.fromJson<int?>(json['linkedAccountId']),
      defaultTargetMinor: serializer.fromJson<int?>(json['defaultTargetMinor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(
        $CategoriesTable.$converterkind.toJson(kind),
      ),
      'isArchived': serializer.toJson<bool>(isArchived),
      'isPlanArchived': serializer.toJson<bool>(isPlanArchived),
      'isPlanDeleted': serializer.toJson<bool>(isPlanDeleted),
      'planGroup': serializer.toJson<String>(
        $CategoriesTable.$converterplanGroup.toJson(planGroup),
      ),
      'linkedAccountId': serializer.toJson<int?>(linkedAccountId),
      'defaultTargetMinor': serializer.toJson<int?>(defaultTargetMinor),
    };
  }

  CategoryRow copyWith({
    int? id,
    String? name,
    CategoryKind? kind,
    bool? isArchived,
    bool? isPlanArchived,
    bool? isPlanDeleted,
    PlanGroup? planGroup,
    Value<int?> linkedAccountId = const Value.absent(),
    Value<int?> defaultTargetMinor = const Value.absent(),
  }) => CategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    isArchived: isArchived ?? this.isArchived,
    isPlanArchived: isPlanArchived ?? this.isPlanArchived,
    isPlanDeleted: isPlanDeleted ?? this.isPlanDeleted,
    planGroup: planGroup ?? this.planGroup,
    linkedAccountId: linkedAccountId.present
        ? linkedAccountId.value
        : this.linkedAccountId,
    defaultTargetMinor: defaultTargetMinor.present
        ? defaultTargetMinor.value
        : this.defaultTargetMinor,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      isPlanArchived: data.isPlanArchived.present
          ? data.isPlanArchived.value
          : this.isPlanArchived,
      isPlanDeleted: data.isPlanDeleted.present
          ? data.isPlanDeleted.value
          : this.isPlanDeleted,
      planGroup: data.planGroup.present ? data.planGroup.value : this.planGroup,
      linkedAccountId: data.linkedAccountId.present
          ? data.linkedAccountId.value
          : this.linkedAccountId,
      defaultTargetMinor: data.defaultTargetMinor.present
          ? data.defaultTargetMinor.value
          : this.defaultTargetMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('isArchived: $isArchived, ')
          ..write('isPlanArchived: $isPlanArchived, ')
          ..write('isPlanDeleted: $isPlanDeleted, ')
          ..write('planGroup: $planGroup, ')
          ..write('linkedAccountId: $linkedAccountId, ')
          ..write('defaultTargetMinor: $defaultTargetMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    isArchived,
    isPlanArchived,
    isPlanDeleted,
    planGroup,
    linkedAccountId,
    defaultTargetMinor,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.isArchived == this.isArchived &&
          other.isPlanArchived == this.isPlanArchived &&
          other.isPlanDeleted == this.isPlanDeleted &&
          other.planGroup == this.planGroup &&
          other.linkedAccountId == this.linkedAccountId &&
          other.defaultTargetMinor == this.defaultTargetMinor);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<CategoryKind> kind;
  final Value<bool> isArchived;
  final Value<bool> isPlanArchived;
  final Value<bool> isPlanDeleted;
  final Value<PlanGroup> planGroup;
  final Value<int?> linkedAccountId;
  final Value<int?> defaultTargetMinor;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isPlanArchived = const Value.absent(),
    this.isPlanDeleted = const Value.absent(),
    this.planGroup = const Value.absent(),
    this.linkedAccountId = const Value.absent(),
    this.defaultTargetMinor = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required CategoryKind kind,
    this.isArchived = const Value.absent(),
    this.isPlanArchived = const Value.absent(),
    this.isPlanDeleted = const Value.absent(),
    this.planGroup = const Value.absent(),
    this.linkedAccountId = const Value.absent(),
    this.defaultTargetMinor = const Value.absent(),
  }) : name = Value(name),
       kind = Value(kind);
  static Insertable<CategoryRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<bool>? isArchived,
    Expression<bool>? isPlanArchived,
    Expression<bool>? isPlanDeleted,
    Expression<String>? planGroup,
    Expression<int>? linkedAccountId,
    Expression<int>? defaultTargetMinor,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (isArchived != null) 'is_archived': isArchived,
      if (isPlanArchived != null) 'is_plan_archived': isPlanArchived,
      if (isPlanDeleted != null) 'is_plan_deleted': isPlanDeleted,
      if (planGroup != null) 'plan_group': planGroup,
      if (linkedAccountId != null) 'linked_account_id': linkedAccountId,
      if (defaultTargetMinor != null)
        'default_target_minor': defaultTargetMinor,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<CategoryKind>? kind,
    Value<bool>? isArchived,
    Value<bool>? isPlanArchived,
    Value<bool>? isPlanDeleted,
    Value<PlanGroup>? planGroup,
    Value<int?>? linkedAccountId,
    Value<int?>? defaultTargetMinor,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      isArchived: isArchived ?? this.isArchived,
      isPlanArchived: isPlanArchived ?? this.isPlanArchived,
      isPlanDeleted: isPlanDeleted ?? this.isPlanDeleted,
      planGroup: planGroup ?? this.planGroup,
      linkedAccountId: linkedAccountId ?? this.linkedAccountId,
      defaultTargetMinor: defaultTargetMinor ?? this.defaultTargetMinor,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $CategoriesTable.$converterkind.toSql(kind.value),
      );
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (isPlanArchived.present) {
      map['is_plan_archived'] = Variable<bool>(isPlanArchived.value);
    }
    if (isPlanDeleted.present) {
      map['is_plan_deleted'] = Variable<bool>(isPlanDeleted.value);
    }
    if (planGroup.present) {
      map['plan_group'] = Variable<String>(
        $CategoriesTable.$converterplanGroup.toSql(planGroup.value),
      );
    }
    if (linkedAccountId.present) {
      map['linked_account_id'] = Variable<int>(linkedAccountId.value);
    }
    if (defaultTargetMinor.present) {
      map['default_target_minor'] = Variable<int>(defaultTargetMinor.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('isArchived: $isArchived, ')
          ..write('isPlanArchived: $isPlanArchived, ')
          ..write('isPlanDeleted: $isPlanDeleted, ')
          ..write('planGroup: $planGroup, ')
          ..write('linkedAccountId: $linkedAccountId, ')
          ..write('defaultTargetMinor: $defaultTargetMinor')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TransactionType>($TransactionsTable.$convertertype);
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CalendarDate, String> date =
      GeneratedColumn<String>(
        'date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CalendarDate>($TransactionsTable.$converterdate);
  static const VerificationMeta _payeeMeta = const VerificationMeta('payee');
  @override
  late final GeneratedColumn<String> payee = GeneratedColumn<String>(
    'payee',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _sourceAccountIdMeta = const VerificationMeta(
    'sourceAccountId',
  );
  @override
  late final GeneratedColumn<int> sourceAccountId = GeneratedColumn<int>(
    'source_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _destinationAccountIdMeta =
      const VerificationMeta('destinationAccountId');
  @override
  late final GeneratedColumn<int> destinationAccountId = GeneratedColumn<int>(
    'destination_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    amountMinor,
    currencyCode,
    date,
    payee,
    categoryId,
    sourceAccountId,
    destinationAccountId,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('payee')) {
      context.handle(
        _payeeMeta,
        payee.isAcceptableOrUnknown(data['payee']!, _payeeMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('source_account_id')) {
      context.handle(
        _sourceAccountIdMeta,
        sourceAccountId.isAcceptableOrUnknown(
          data['source_account_id']!,
          _sourceAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('destination_account_id')) {
      context.handle(
        _destinationAccountIdMeta,
        destinationAccountId.isAcceptableOrUnknown(
          data['destination_account_id']!,
          _destinationAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: $TransactionsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      date: $TransactionsTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}date'],
        )!,
      ),
      payee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payee'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      sourceAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_account_id'],
      ),
      destinationAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}destination_account_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionType, String, String> $convertertype =
      const EnumNameConverter<TransactionType>(TransactionType.values);
  static TypeConverter<CalendarDate, String> $converterdate =
      const CalendarDateConverter();
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final int id;

  /// Stored by enum name, e.g. `creditCardPayment`.
  final TransactionType type;

  /// Positive minor units (rule 8); [type] decides the sign of its effect.
  final int amountMinor;
  final String currencyCode;

  /// Local calendar date as `YYYY-MM-DD` (G9).
  final CalendarDate date;
  final String payee;
  final int? categoryId;
  final int? sourceAccountId;
  final int? destinationAccountId;
  final String note;

  /// UTC instants (G9).
  final DateTime createdAt;
  final DateTime updatedAt;
  const TransactionRow({
    required this.id,
    required this.type,
    required this.amountMinor,
    required this.currencyCode,
    required this.date,
    required this.payee,
    this.categoryId,
    this.sourceAccountId,
    this.destinationAccountId,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['type'] = Variable<String>(
        $TransactionsTable.$convertertype.toSql(type),
      );
    }
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency_code'] = Variable<String>(currencyCode);
    {
      map['date'] = Variable<String>(
        $TransactionsTable.$converterdate.toSql(date),
      );
    }
    map['payee'] = Variable<String>(payee);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || sourceAccountId != null) {
      map['source_account_id'] = Variable<int>(sourceAccountId);
    }
    if (!nullToAbsent || destinationAccountId != null) {
      map['destination_account_id'] = Variable<int>(destinationAccountId);
    }
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      type: Value(type),
      amountMinor: Value(amountMinor),
      currencyCode: Value(currencyCode),
      date: Value(date),
      payee: Value(payee),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      sourceAccountId: sourceAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceAccountId),
      destinationAccountId: destinationAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationAccountId),
      note: Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<int>(json['id']),
      type: $TransactionsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      date: serializer.fromJson<CalendarDate>(json['date']),
      payee: serializer.fromJson<String>(json['payee']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      sourceAccountId: serializer.fromJson<int?>(json['sourceAccountId']),
      destinationAccountId: serializer.fromJson<int?>(
        json['destinationAccountId'],
      ),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(
        $TransactionsTable.$convertertype.toJson(type),
      ),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'date': serializer.toJson<CalendarDate>(date),
      'payee': serializer.toJson<String>(payee),
      'categoryId': serializer.toJson<int?>(categoryId),
      'sourceAccountId': serializer.toJson<int?>(sourceAccountId),
      'destinationAccountId': serializer.toJson<int?>(destinationAccountId),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TransactionRow copyWith({
    int? id,
    TransactionType? type,
    int? amountMinor,
    String? currencyCode,
    CalendarDate? date,
    String? payee,
    Value<int?> categoryId = const Value.absent(),
    Value<int?> sourceAccountId = const Value.absent(),
    Value<int?> destinationAccountId = const Value.absent(),
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TransactionRow(
    id: id ?? this.id,
    type: type ?? this.type,
    amountMinor: amountMinor ?? this.amountMinor,
    currencyCode: currencyCode ?? this.currencyCode,
    date: date ?? this.date,
    payee: payee ?? this.payee,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    sourceAccountId: sourceAccountId.present
        ? sourceAccountId.value
        : this.sourceAccountId,
    destinationAccountId: destinationAccountId.present
        ? destinationAccountId.value
        : this.destinationAccountId,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      date: data.date.present ? data.date.value : this.date,
      payee: data.payee.present ? data.payee.value : this.payee,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      sourceAccountId: data.sourceAccountId.present
          ? data.sourceAccountId.value
          : this.sourceAccountId,
      destinationAccountId: data.destinationAccountId.present
          ? data.destinationAccountId.value
          : this.destinationAccountId,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('date: $date, ')
          ..write('payee: $payee, ')
          ..write('categoryId: $categoryId, ')
          ..write('sourceAccountId: $sourceAccountId, ')
          ..write('destinationAccountId: $destinationAccountId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    amountMinor,
    currencyCode,
    date,
    payee,
    categoryId,
    sourceAccountId,
    destinationAccountId,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.amountMinor == this.amountMinor &&
          other.currencyCode == this.currencyCode &&
          other.date == this.date &&
          other.payee == this.payee &&
          other.categoryId == this.categoryId &&
          other.sourceAccountId == this.sourceAccountId &&
          other.destinationAccountId == this.destinationAccountId &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<int> id;
  final Value<TransactionType> type;
  final Value<int> amountMinor;
  final Value<String> currencyCode;
  final Value<CalendarDate> date;
  final Value<String> payee;
  final Value<int?> categoryId;
  final Value<int?> sourceAccountId;
  final Value<int?> destinationAccountId;
  final Value<String> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.date = const Value.absent(),
    this.payee = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.sourceAccountId = const Value.absent(),
    this.destinationAccountId = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required TransactionType type,
    required int amountMinor,
    required String currencyCode,
    required CalendarDate date,
    this.payee = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.sourceAccountId = const Value.absent(),
    this.destinationAccountId = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : type = Value(type),
       amountMinor = Value(amountMinor),
       currencyCode = Value(currencyCode),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TransactionRow> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<int>? amountMinor,
    Expression<String>? currencyCode,
    Expression<String>? date,
    Expression<String>? payee,
    Expression<int>? categoryId,
    Expression<int>? sourceAccountId,
    Expression<int>? destinationAccountId,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (date != null) 'date': date,
      if (payee != null) 'payee': payee,
      if (categoryId != null) 'category_id': categoryId,
      if (sourceAccountId != null) 'source_account_id': sourceAccountId,
      if (destinationAccountId != null)
        'destination_account_id': destinationAccountId,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<TransactionType>? type,
    Value<int>? amountMinor,
    Value<String>? currencyCode,
    Value<CalendarDate>? date,
    Value<String>? payee,
    Value<int?>? categoryId,
    Value<int?>? sourceAccountId,
    Value<int?>? destinationAccountId,
    Value<String>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      amountMinor: amountMinor ?? this.amountMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      date: date ?? this.date,
      payee: payee ?? this.payee,
      categoryId: categoryId ?? this.categoryId,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $TransactionsTable.$convertertype.toSql(type.value),
      );
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(
        $TransactionsTable.$converterdate.toSql(date.value),
      );
    }
    if (payee.present) {
      map['payee'] = Variable<String>(payee.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (sourceAccountId.present) {
      map['source_account_id'] = Variable<int>(sourceAccountId.value);
    }
    if (destinationAccountId.present) {
      map['destination_account_id'] = Variable<int>(destinationAccountId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('date: $date, ')
          ..write('payee: $payee, ')
          ..write('categoryId: $categoryId, ')
          ..write('sourceAccountId: $sourceAccountId, ')
          ..write('destinationAccountId: $destinationAccountId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MonthlyPlansTable extends MonthlyPlans
    with TableInfo<$MonthlyPlansTable, MonthlyPlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthlyPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CalendarMonth, String> month =
      GeneratedColumn<String>(
        'month',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CalendarMonth>($MonthlyPlansTable.$convertermonth);
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _targetAmountMinorMeta = const VerificationMeta(
    'targetAmountMinor',
  );
  @override
  late final GeneratedColumn<int> targetAmountMinor = GeneratedColumn<int>(
    'target_amount_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assignedAmountMinorMeta =
      const VerificationMeta('assignedAmountMinor');
  @override
  late final GeneratedColumn<int> assignedAmountMinor = GeneratedColumn<int>(
    'assigned_amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    month,
    categoryId,
    targetAmountMinor,
    assignedAmountMinor,
    currencyCode,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'monthly_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<MonthlyPlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('target_amount_minor')) {
      context.handle(
        _targetAmountMinorMeta,
        targetAmountMinor.isAcceptableOrUnknown(
          data['target_amount_minor']!,
          _targetAmountMinorMeta,
        ),
      );
    }
    if (data.containsKey('assigned_amount_minor')) {
      context.handle(
        _assignedAmountMinorMeta,
        assignedAmountMinor.isAcceptableOrUnknown(
          data['assigned_amount_minor']!,
          _assignedAmountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_assignedAmountMinorMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {month, categoryId},
  ];
  @override
  MonthlyPlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthlyPlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      month: $MonthlyPlansTable.$convertermonth.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}month'],
        )!,
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      targetAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_amount_minor'],
      ),
      assignedAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}assigned_amount_minor'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MonthlyPlansTable createAlias(String alias) {
    return $MonthlyPlansTable(attachedDatabase, alias);
  }

  static TypeConverter<CalendarMonth, String> $convertermonth =
      const CalendarMonthConverter();
}

class MonthlyPlanRow extends DataClass implements Insertable<MonthlyPlanRow> {
  final int id;

  /// `YYYY-MM`.
  final CalendarMonth month;
  final int categoryId;

  /// The budget for the month: zero or positive minor units (centavos for
  /// PHP), or `NULL` when the category has no target. Named
  /// `planned_amount_minor` before v6.
  final int? targetAmountMinor;

  /// Money set aside for the category this month, in minor units. Zero or
  /// positive; entered by the user and not checked against income.
  final int assignedAmountMinor;
  final String currencyCode;

  /// UTC instants.
  final DateTime createdAt;
  final DateTime updatedAt;
  const MonthlyPlanRow({
    required this.id,
    required this.month,
    required this.categoryId,
    this.targetAmountMinor,
    required this.assignedAmountMinor,
    required this.currencyCode,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['month'] = Variable<String>(
        $MonthlyPlansTable.$convertermonth.toSql(month),
      );
    }
    map['category_id'] = Variable<int>(categoryId);
    if (!nullToAbsent || targetAmountMinor != null) {
      map['target_amount_minor'] = Variable<int>(targetAmountMinor);
    }
    map['assigned_amount_minor'] = Variable<int>(assignedAmountMinor);
    map['currency_code'] = Variable<String>(currencyCode);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MonthlyPlansCompanion toCompanion(bool nullToAbsent) {
    return MonthlyPlansCompanion(
      id: Value(id),
      month: Value(month),
      categoryId: Value(categoryId),
      targetAmountMinor: targetAmountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(targetAmountMinor),
      assignedAmountMinor: Value(assignedAmountMinor),
      currencyCode: Value(currencyCode),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MonthlyPlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthlyPlanRow(
      id: serializer.fromJson<int>(json['id']),
      month: serializer.fromJson<CalendarMonth>(json['month']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      targetAmountMinor: serializer.fromJson<int?>(json['targetAmountMinor']),
      assignedAmountMinor: serializer.fromJson<int>(
        json['assignedAmountMinor'],
      ),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'month': serializer.toJson<CalendarMonth>(month),
      'categoryId': serializer.toJson<int>(categoryId),
      'targetAmountMinor': serializer.toJson<int?>(targetAmountMinor),
      'assignedAmountMinor': serializer.toJson<int>(assignedAmountMinor),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MonthlyPlanRow copyWith({
    int? id,
    CalendarMonth? month,
    int? categoryId,
    Value<int?> targetAmountMinor = const Value.absent(),
    int? assignedAmountMinor,
    String? currencyCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MonthlyPlanRow(
    id: id ?? this.id,
    month: month ?? this.month,
    categoryId: categoryId ?? this.categoryId,
    targetAmountMinor: targetAmountMinor.present
        ? targetAmountMinor.value
        : this.targetAmountMinor,
    assignedAmountMinor: assignedAmountMinor ?? this.assignedAmountMinor,
    currencyCode: currencyCode ?? this.currencyCode,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MonthlyPlanRow copyWithCompanion(MonthlyPlansCompanion data) {
    return MonthlyPlanRow(
      id: data.id.present ? data.id.value : this.id,
      month: data.month.present ? data.month.value : this.month,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      targetAmountMinor: data.targetAmountMinor.present
          ? data.targetAmountMinor.value
          : this.targetAmountMinor,
      assignedAmountMinor: data.assignedAmountMinor.present
          ? data.assignedAmountMinor.value
          : this.assignedAmountMinor,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyPlanRow(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('categoryId: $categoryId, ')
          ..write('targetAmountMinor: $targetAmountMinor, ')
          ..write('assignedAmountMinor: $assignedAmountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    month,
    categoryId,
    targetAmountMinor,
    assignedAmountMinor,
    currencyCode,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthlyPlanRow &&
          other.id == this.id &&
          other.month == this.month &&
          other.categoryId == this.categoryId &&
          other.targetAmountMinor == this.targetAmountMinor &&
          other.assignedAmountMinor == this.assignedAmountMinor &&
          other.currencyCode == this.currencyCode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MonthlyPlansCompanion extends UpdateCompanion<MonthlyPlanRow> {
  final Value<int> id;
  final Value<CalendarMonth> month;
  final Value<int> categoryId;
  final Value<int?> targetAmountMinor;
  final Value<int> assignedAmountMinor;
  final Value<String> currencyCode;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const MonthlyPlansCompanion({
    this.id = const Value.absent(),
    this.month = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.targetAmountMinor = const Value.absent(),
    this.assignedAmountMinor = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MonthlyPlansCompanion.insert({
    this.id = const Value.absent(),
    required CalendarMonth month,
    required int categoryId,
    this.targetAmountMinor = const Value.absent(),
    required int assignedAmountMinor,
    required String currencyCode,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : month = Value(month),
       categoryId = Value(categoryId),
       assignedAmountMinor = Value(assignedAmountMinor),
       currencyCode = Value(currencyCode),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MonthlyPlanRow> custom({
    Expression<int>? id,
    Expression<String>? month,
    Expression<int>? categoryId,
    Expression<int>? targetAmountMinor,
    Expression<int>? assignedAmountMinor,
    Expression<String>? currencyCode,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (month != null) 'month': month,
      if (categoryId != null) 'category_id': categoryId,
      if (targetAmountMinor != null) 'target_amount_minor': targetAmountMinor,
      if (assignedAmountMinor != null)
        'assigned_amount_minor': assignedAmountMinor,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MonthlyPlansCompanion copyWith({
    Value<int>? id,
    Value<CalendarMonth>? month,
    Value<int>? categoryId,
    Value<int?>? targetAmountMinor,
    Value<int>? assignedAmountMinor,
    Value<String>? currencyCode,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return MonthlyPlansCompanion(
      id: id ?? this.id,
      month: month ?? this.month,
      categoryId: categoryId ?? this.categoryId,
      targetAmountMinor: targetAmountMinor ?? this.targetAmountMinor,
      assignedAmountMinor: assignedAmountMinor ?? this.assignedAmountMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (month.present) {
      map['month'] = Variable<String>(
        $MonthlyPlansTable.$convertermonth.toSql(month.value),
      );
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (targetAmountMinor.present) {
      map['target_amount_minor'] = Variable<int>(targetAmountMinor.value);
    }
    if (assignedAmountMinor.present) {
      map['assigned_amount_minor'] = Variable<int>(assignedAmountMinor.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyPlansCompanion(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('categoryId: $categoryId, ')
          ..write('targetAmountMinor: $targetAmountMinor, ')
          ..write('assignedAmountMinor: $assignedAmountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CustomAccountTypesTable customAccountTypes =
      $CustomAccountTypesTable(this);
  late final $CustomBanksTable customBanks = $CustomBanksTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $MonthlyPlansTable monthlyPlans = $MonthlyPlansTable(this);
  late final Index transactionsDate = Index(
    'transactions_date',
    'CREATE INDEX transactions_date ON transactions (date)',
  );
  late final Index transactionsSourceAccount = Index(
    'transactions_source_account',
    'CREATE INDEX transactions_source_account ON transactions (source_account_id)',
  );
  late final Index transactionsDestinationAccount = Index(
    'transactions_destination_account',
    'CREATE INDEX transactions_destination_account ON transactions (destination_account_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    customAccountTypes,
    customBanks,
    accounts,
    categories,
    transactions,
    monthlyPlans,
    transactionsDate,
    transactionsSourceAccount,
    transactionsDestinationAccount,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('categories', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('monthly_plans', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$CustomAccountTypesTableCreateCompanionBuilder =
    CustomAccountTypesCompanion Function({
      Value<int> id,
      required String name,
      required AccountType baseType,
      required DateTime createdAt,
    });
typedef $$CustomAccountTypesTableUpdateCompanionBuilder =
    CustomAccountTypesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<AccountType> baseType,
      Value<DateTime> createdAt,
    });

final class $$CustomAccountTypesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CustomAccountTypesTable,
          CustomAccountTypeRow
        > {
  $$CustomAccountTypesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$AccountsTable, List<AccountRow>>
  _accountsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.accounts,
    aliasName: 'custom_account_types__id__accounts__custom_type_id',
  );

  $$AccountsTableProcessedTableManager get accountsRefs {
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.customTypeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_accountsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CustomAccountTypesTableFilterComposer
    extends Composer<_$AppDatabase, $CustomAccountTypesTable> {
  $$CustomAccountTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AccountType, AccountType, String>
  get baseType => $composableBuilder(
    column: $table.baseType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> accountsRefs(
    Expression<bool> Function($$AccountsTableFilterComposer f) f,
  ) {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.customTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomAccountTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomAccountTypesTable> {
  $$CustomAccountTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseType => $composableBuilder(
    column: $table.baseType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomAccountTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomAccountTypesTable> {
  $$CustomAccountTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AccountType, String> get baseType =>
      $composableBuilder(column: $table.baseType, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> accountsRefs<T extends Object>(
    Expression<T> Function($$AccountsTableAnnotationComposer a) f,
  ) {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.customTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomAccountTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomAccountTypesTable,
          CustomAccountTypeRow,
          $$CustomAccountTypesTableFilterComposer,
          $$CustomAccountTypesTableOrderingComposer,
          $$CustomAccountTypesTableAnnotationComposer,
          $$CustomAccountTypesTableCreateCompanionBuilder,
          $$CustomAccountTypesTableUpdateCompanionBuilder,
          (CustomAccountTypeRow, $$CustomAccountTypesTableReferences),
          CustomAccountTypeRow,
          PrefetchHooks Function({bool accountsRefs})
        > {
  $$CustomAccountTypesTableTableManager(
    _$AppDatabase db,
    $CustomAccountTypesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomAccountTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomAccountTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomAccountTypesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<AccountType> baseType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CustomAccountTypesCompanion(
                id: id,
                name: name,
                baseType: baseType,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required AccountType baseType,
                required DateTime createdAt,
              }) => CustomAccountTypesCompanion.insert(
                id: id,
                name: name,
                baseType: baseType,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CustomAccountTypesTable, CustomAccountTypeRow>(
                    table,
                  ),
                  $$CustomAccountTypesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (accountsRefs) db.accounts],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (accountsRefs)
                    await $_getPrefetchedDataByColumns<
                      CustomAccountTypeRow,
                      $CustomAccountTypesTable,
                      AccountRow,
                      $AccountsTable
                    >(
                      currentTable: table,
                      referencedTable: $$CustomAccountTypesTableReferences
                          ._accountsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CustomAccountTypesTableReferences(
                            db,
                            table,
                            p0,
                          ).accountsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'custom_type_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CustomAccountTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomAccountTypesTable,
      CustomAccountTypeRow,
      $$CustomAccountTypesTableFilterComposer,
      $$CustomAccountTypesTableOrderingComposer,
      $$CustomAccountTypesTableAnnotationComposer,
      $$CustomAccountTypesTableCreateCompanionBuilder,
      $$CustomAccountTypesTableUpdateCompanionBuilder,
      (CustomAccountTypeRow, $$CustomAccountTypesTableReferences),
      CustomAccountTypeRow,
      PrefetchHooks Function({bool accountsRefs})
    >;
typedef $$CustomBanksTableCreateCompanionBuilder =
    CustomBanksCompanion Function({
      Value<int> id,
      required String name,
      required DateTime createdAt,
    });
typedef $$CustomBanksTableUpdateCompanionBuilder =
    CustomBanksCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> createdAt,
    });

final class $$CustomBanksTableReferences
    extends BaseReferences<_$AppDatabase, $CustomBanksTable, CustomBankRow> {
  $$CustomBanksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AccountsTable, List<AccountRow>>
  _accountsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.accounts,
    aliasName: 'custom_banks__id__accounts__custom_bank_id',
  );

  $$AccountsTableProcessedTableManager get accountsRefs {
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.customBankId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_accountsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CustomBanksTableFilterComposer
    extends Composer<_$AppDatabase, $CustomBanksTable> {
  $$CustomBanksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> accountsRefs(
    Expression<bool> Function($$AccountsTableFilterComposer f) f,
  ) {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.customBankId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomBanksTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomBanksTable> {
  $$CustomBanksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomBanksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomBanksTable> {
  $$CustomBanksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> accountsRefs<T extends Object>(
    Expression<T> Function($$AccountsTableAnnotationComposer a) f,
  ) {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.customBankId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomBanksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomBanksTable,
          CustomBankRow,
          $$CustomBanksTableFilterComposer,
          $$CustomBanksTableOrderingComposer,
          $$CustomBanksTableAnnotationComposer,
          $$CustomBanksTableCreateCompanionBuilder,
          $$CustomBanksTableUpdateCompanionBuilder,
          (CustomBankRow, $$CustomBanksTableReferences),
          CustomBankRow,
          PrefetchHooks Function({bool accountsRefs})
        > {
  $$CustomBanksTableTableManager(_$AppDatabase db, $CustomBanksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomBanksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomBanksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomBanksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) => CustomBanksCompanion(id: id, name: name, createdAt: createdAt),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required DateTime createdAt,
              }) => CustomBanksCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CustomBanksTable, CustomBankRow>(table),
                  $$CustomBanksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (accountsRefs) db.accounts],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (accountsRefs)
                    await $_getPrefetchedDataByColumns<
                      CustomBankRow,
                      $CustomBanksTable,
                      AccountRow,
                      $AccountsTable
                    >(
                      currentTable: table,
                      referencedTable: $$CustomBanksTableReferences
                          ._accountsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CustomBanksTableReferences(
                            db,
                            table,
                            p0,
                          ).accountsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'custom_bank_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CustomBanksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomBanksTable,
      CustomBankRow,
      $$CustomBanksTableFilterComposer,
      $$CustomBanksTableOrderingComposer,
      $$CustomBanksTableAnnotationComposer,
      $$CustomBanksTableCreateCompanionBuilder,
      $$CustomBanksTableUpdateCompanionBuilder,
      (CustomBankRow, $$CustomBanksTableReferences),
      CustomBankRow,
      PrefetchHooks Function({bool accountsRefs})
    >;
typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  required String name,
  required AccountType type,
  required int openingBalanceMinor,
  Value<String> currencyCode,
  required DateTime createdAt,
  Value<bool> isArchived,
  Value<int?> customTypeId,
  Value<bool> isBudgetAccount,
  Value<String?> bankKey,
  Value<int?> customBankId,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<AccountType> type,
  Value<int> openingBalanceMinor,
  Value<String> currencyCode,
  Value<DateTime> createdAt,
  Value<bool> isArchived,
  Value<int?> customTypeId,
  Value<bool> isBudgetAccount,
  Value<String?> bankKey,
  Value<int?> customBankId,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, AccountRow> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CustomAccountTypesTable _customTypeIdTable(_$AppDatabase db) => db
      .customAccountTypes
      .createAlias('accounts__custom_type_id__custom_account_types__id');

  $$CustomAccountTypesTableProcessedTableManager? get customTypeId {
    final $_column = $_itemColumn<int>('custom_type_id');
    if ($_column == null) return null;
    final manager = $$CustomAccountTypesTableTableManager(
      $_db,
      $_db.customAccountTypes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customTypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CustomBanksTable _customBankIdTable(_$AppDatabase db) =>
      db.customBanks.createAlias('accounts__custom_bank_id__custom_banks__id');

  $$CustomBanksTableProcessedTableManager? get customBankId {
    final $_column = $_itemColumn<int>('custom_bank_id');
    if ($_column == null) return null;
    final manager = $$CustomBanksTableTableManager(
      $_db,
      $_db.customBanks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customBankIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CategoriesTable, List<CategoryRow>>
  _categoriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.categories,
    aliasName: 'accounts__id__categories__linked_account_id',
  );

  $$CategoriesTableProcessedTableManager get categoriesRefs {
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.linkedAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_categoriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AccountType, AccountType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBudgetAccount => $composableBuilder(
    column: $table.isBudgetAccount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankKey => $composableBuilder(
    column: $table.bankKey,
    builder: (column) => ColumnFilters(column),
  );

  $$CustomAccountTypesTableFilterComposer get customTypeId {
    final $$CustomAccountTypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customTypeId,
      referencedTable: $db.customAccountTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomAccountTypesTableFilterComposer(
            $db: $db,
            $table: $db.customAccountTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomBanksTableFilterComposer get customBankId {
    final $$CustomBanksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customBankId,
      referencedTable: $db.customBanks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomBanksTableFilterComposer(
            $db: $db,
            $table: $db.customBanks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> categoriesRefs(
    Expression<bool> Function($$CategoriesTableFilterComposer f) f,
  ) {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.linkedAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBudgetAccount => $composableBuilder(
    column: $table.isBudgetAccount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankKey => $composableBuilder(
    column: $table.bankKey,
    builder: (column) => ColumnOrderings(column),
  );

  $$CustomAccountTypesTableOrderingComposer get customTypeId {
    final $$CustomAccountTypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customTypeId,
      referencedTable: $db.customAccountTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomAccountTypesTableOrderingComposer(
            $db: $db,
            $table: $db.customAccountTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomBanksTableOrderingComposer get customBankId {
    final $$CustomBanksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customBankId,
      referencedTable: $db.customBanks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomBanksTableOrderingComposer(
            $db: $db,
            $table: $db.customBanks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AccountType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBudgetAccount => $composableBuilder(
    column: $table.isBudgetAccount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bankKey =>
      $composableBuilder(column: $table.bankKey, builder: (column) => column);

  $$CustomAccountTypesTableAnnotationComposer get customTypeId {
    final $$CustomAccountTypesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.customTypeId,
          referencedTable: $db.customAccountTypes,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomAccountTypesTableAnnotationComposer(
                $db: $db,
                $table: $db.customAccountTypes,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$CustomBanksTableAnnotationComposer get customBankId {
    final $$CustomBanksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customBankId,
      referencedTable: $db.customBanks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomBanksTableAnnotationComposer(
            $db: $db,
            $table: $db.customBanks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> categoriesRefs<T extends Object>(
    Expression<T> Function($$CategoriesTableAnnotationComposer a) f,
  ) {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.linkedAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          AccountRow,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (AccountRow, $$AccountsTableReferences),
          AccountRow,
          PrefetchHooks Function({
            bool customTypeId,
            bool customBankId,
            bool categoriesRefs,
          })
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<AccountType> type = const Value.absent(),
                Value<int> openingBalanceMinor = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int?> customTypeId = const Value.absent(),
                Value<bool> isBudgetAccount = const Value.absent(),
                Value<String?> bankKey = const Value.absent(),
                Value<int?> customBankId = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                name: name,
                type: type,
                openingBalanceMinor: openingBalanceMinor,
                currencyCode: currencyCode,
                createdAt: createdAt,
                isArchived: isArchived,
                customTypeId: customTypeId,
                isBudgetAccount: isBudgetAccount,
                bankKey: bankKey,
                customBankId: customBankId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required AccountType type,
                required int openingBalanceMinor,
                Value<String> currencyCode = const Value.absent(),
                required DateTime createdAt,
                Value<bool> isArchived = const Value.absent(),
                Value<int?> customTypeId = const Value.absent(),
                Value<bool> isBudgetAccount = const Value.absent(),
                Value<String?> bankKey = const Value.absent(),
                Value<int?> customBankId = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                name: name,
                type: type,
                openingBalanceMinor: openingBalanceMinor,
                currencyCode: currencyCode,
                createdAt: createdAt,
                isArchived: isArchived,
                customTypeId: customTypeId,
                isBudgetAccount: isBudgetAccount,
                bankKey: bankKey,
                customBankId: customBankId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountsTable, AccountRow>(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                customTypeId = false,
                customBankId = false,
                categoriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (categoriesRefs) db.categories],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (customTypeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.customTypeId,
                            referencedTable: $$AccountsTableReferences
                                ._customTypeIdTable(db),
                            referencedColumn: $$AccountsTableReferences
                                ._customTypeIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (customBankId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.customBankId,
                            referencedTable: $$AccountsTableReferences
                                ._customBankIdTable(db),
                            referencedColumn: $$AccountsTableReferences
                                ._customBankIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (categoriesRefs)
                        await $_getPrefetchedDataByColumns<
                          AccountRow,
                          $AccountsTable,
                          CategoryRow,
                          $CategoriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._categoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).categoriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'linked_account_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      AccountRow,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (AccountRow, $$AccountsTableReferences),
      AccountRow,
      PrefetchHooks Function({
        bool customTypeId,
        bool customBankId,
        bool categoriesRefs,
      })
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String name,
  required CategoryKind kind,
  Value<bool> isArchived,
  Value<bool> isPlanArchived,
  Value<bool> isPlanDeleted,
  Value<PlanGroup> planGroup,
  Value<int?> linkedAccountId,
  Value<int?> defaultTargetMinor,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<CategoryKind> kind,
  Value<bool> isArchived,
  Value<bool> isPlanArchived,
  Value<bool> isPlanDeleted,
  Value<PlanGroup> planGroup,
  Value<int?> linkedAccountId,
  Value<int?> defaultTargetMinor,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _linkedAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('categories__linked_account_id__accounts__id');

  $$AccountsTableProcessedTableManager? get linkedAccountId {
    final $_column = $_itemColumn<int>('linked_account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_linkedAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'categories__id__transactions__category_id',
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MonthlyPlansTable, List<MonthlyPlanRow>>
  _monthlyPlansRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.monthlyPlans,
    aliasName: 'categories__id__monthly_plans__category_id',
  );

  $$MonthlyPlansTableProcessedTableManager get monthlyPlansRefs {
    final manager = $$MonthlyPlansTableTableManager(
      $_db,
      $_db.monthlyPlans,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_monthlyPlansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CategoryKind, CategoryKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPlanArchived => $composableBuilder(
    column: $table.isPlanArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPlanDeleted => $composableBuilder(
    column: $table.isPlanDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PlanGroup, PlanGroup, String> get planGroup =>
      $composableBuilder(
        column: $table.planGroup,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get defaultTargetMinor => $composableBuilder(
    column: $table.defaultTargetMinor,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get linkedAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> monthlyPlansRefs(
    Expression<bool> Function($$MonthlyPlansTableFilterComposer f) f,
  ) {
    final $$MonthlyPlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.monthlyPlans,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthlyPlansTableFilterComposer(
            $db: $db,
            $table: $db.monthlyPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPlanArchived => $composableBuilder(
    column: $table.isPlanArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPlanDeleted => $composableBuilder(
    column: $table.isPlanDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planGroup => $composableBuilder(
    column: $table.planGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultTargetMinor => $composableBuilder(
    column: $table.defaultTargetMinor,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get linkedAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CategoryKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPlanArchived => $composableBuilder(
    column: $table.isPlanArchived,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPlanDeleted => $composableBuilder(
    column: $table.isPlanDeleted,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PlanGroup, String> get planGroup =>
      $composableBuilder(column: $table.planGroup, builder: (column) => column);

  GeneratedColumn<int> get defaultTargetMinor => $composableBuilder(
    column: $table.defaultTargetMinor,
    builder: (column) => column,
  );

  $$AccountsTableAnnotationComposer get linkedAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> monthlyPlansRefs<T extends Object>(
    Expression<T> Function($$MonthlyPlansTableAnnotationComposer a) f,
  ) {
    final $$MonthlyPlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.monthlyPlans,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthlyPlansTableAnnotationComposer(
            $db: $db,
            $table: $db.monthlyPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryRow, $$CategoriesTableReferences),
          CategoryRow,
          PrefetchHooks Function({
            bool linkedAccountId,
            bool transactionsRefs,
            bool monthlyPlansRefs,
          })
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<CategoryKind> kind = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isPlanArchived = const Value.absent(),
                Value<bool> isPlanDeleted = const Value.absent(),
                Value<PlanGroup> planGroup = const Value.absent(),
                Value<int?> linkedAccountId = const Value.absent(),
                Value<int?> defaultTargetMinor = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                kind: kind,
                isArchived: isArchived,
                isPlanArchived: isPlanArchived,
                isPlanDeleted: isPlanDeleted,
                planGroup: planGroup,
                linkedAccountId: linkedAccountId,
                defaultTargetMinor: defaultTargetMinor,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required CategoryKind kind,
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isPlanArchived = const Value.absent(),
                Value<bool> isPlanDeleted = const Value.absent(),
                Value<PlanGroup> planGroup = const Value.absent(),
                Value<int?> linkedAccountId = const Value.absent(),
                Value<int?> defaultTargetMinor = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                isArchived: isArchived,
                isPlanArchived: isPlanArchived,
                isPlanDeleted: isPlanDeleted,
                planGroup: planGroup,
                linkedAccountId: linkedAccountId,
                defaultTargetMinor: defaultTargetMinor,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, CategoryRow>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                linkedAccountId = false,
                transactionsRefs = false,
                monthlyPlansRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsRefs) db.transactions,
                    if (monthlyPlansRefs) db.monthlyPlans,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (linkedAccountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.linkedAccountId,
                            referencedTable: $$CategoriesTableReferences
                                ._linkedAccountIdTable(db),
                            referencedColumn: $$CategoriesTableReferences
                                ._linkedAccountIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsRefs)
                        await $_getPrefetchedDataByColumns<
                          CategoryRow,
                          $CategoriesTable,
                          TransactionRow,
                          $TransactionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'category_id',
                          typedResults: items,
                        ),
                      if (monthlyPlansRefs)
                        await $_getPrefetchedDataByColumns<
                          CategoryRow,
                          $CategoriesTable,
                          MonthlyPlanRow,
                          $MonthlyPlansTable
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._monthlyPlansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).monthlyPlansRefs,
                          currentColumn: 'id',
                          referencedColumn: 'category_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryRow, $$CategoriesTableReferences),
      CategoryRow,
      PrefetchHooks Function({
        bool linkedAccountId,
        bool transactionsRefs,
        bool monthlyPlansRefs,
      })
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      required TransactionType type,
      required int amountMinor,
      required String currencyCode,
      required CalendarDate date,
      Value<String> payee,
      Value<int?> categoryId,
      Value<int?> sourceAccountId,
      Value<int?> destinationAccountId,
      Value<String> note,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<TransactionType> type,
      Value<int> amountMinor,
      Value<String> currencyCode,
      Value<CalendarDate> date,
      Value<String> payee,
      Value<int?> categoryId,
      Value<int?> sourceAccountId,
      Value<int?> destinationAccountId,
      Value<String> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('transactions__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _sourceAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('transactions__source_account_id__accounts__id');

  $$AccountsTableProcessedTableManager? get sourceAccountId {
    final $_column = $_itemColumn<int>('source_account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _destinationAccountIdTable(_$AppDatabase db) => db
      .accounts
      .createAlias('transactions__destination_account_id__accounts__id');

  $$AccountsTableProcessedTableManager? get destinationAccountId {
    final $_column = $_itemColumn<int>('destination_account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _destinationAccountIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionType, TransactionType, String>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CalendarDate, CalendarDate, String> get date =>
      $composableBuilder(
        column: $table.date,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get payee => $composableBuilder(
    column: $table.payee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get sourceAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get destinationAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.destinationAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payee => $composableBuilder(
    column: $table.payee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get sourceAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get destinationAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.destinationAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CalendarDate, String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get payee =>
      $composableBuilder(column: $table.payee, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get sourceAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get destinationAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.destinationAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (TransactionRow, $$TransactionsTableReferences),
          TransactionRow,
          PrefetchHooks Function({
            bool categoryId,
            bool sourceAccountId,
            bool destinationAccountId,
          })
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<TransactionType> type = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<CalendarDate> date = const Value.absent(),
                Value<String> payee = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int?> sourceAccountId = const Value.absent(),
                Value<int?> destinationAccountId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                type: type,
                amountMinor: amountMinor,
                currencyCode: currencyCode,
                date: date,
                payee: payee,
                categoryId: categoryId,
                sourceAccountId: sourceAccountId,
                destinationAccountId: destinationAccountId,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required TransactionType type,
                required int amountMinor,
                required String currencyCode,
                required CalendarDate date,
                Value<String> payee = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int?> sourceAccountId = const Value.absent(),
                Value<int?> destinationAccountId = const Value.absent(),
                Value<String> note = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => TransactionsCompanion.insert(
                id: id,
                type: type,
                amountMinor: amountMinor,
                currencyCode: currencyCode,
                date: date,
                payee: payee,
                categoryId: categoryId,
                sourceAccountId: sourceAccountId,
                destinationAccountId: destinationAccountId,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionsTable, TransactionRow>(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                sourceAccountId = false,
                destinationAccountId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$TransactionsTableReferences
                                ._categoryIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._categoryIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (sourceAccountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sourceAccountId,
                            referencedTable: $$TransactionsTableReferences
                                ._sourceAccountIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._sourceAccountIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (destinationAccountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.destinationAccountId,
                            referencedTable: $$TransactionsTableReferences
                                ._destinationAccountIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._destinationAccountIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (TransactionRow, $$TransactionsTableReferences),
      TransactionRow,
      PrefetchHooks Function({
        bool categoryId,
        bool sourceAccountId,
        bool destinationAccountId,
      })
    >;
typedef $$MonthlyPlansTableCreateCompanionBuilder =
    MonthlyPlansCompanion Function({
      Value<int> id,
      required CalendarMonth month,
      required int categoryId,
      Value<int?> targetAmountMinor,
      required int assignedAmountMinor,
      required String currencyCode,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$MonthlyPlansTableUpdateCompanionBuilder =
    MonthlyPlansCompanion Function({
      Value<int> id,
      Value<CalendarMonth> month,
      Value<int> categoryId,
      Value<int?> targetAmountMinor,
      Value<int> assignedAmountMinor,
      Value<String> currencyCode,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$MonthlyPlansTableReferences
    extends BaseReferences<_$AppDatabase, $MonthlyPlansTable, MonthlyPlanRow> {
  $$MonthlyPlansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('monthly_plans__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MonthlyPlansTableFilterComposer
    extends Composer<_$AppDatabase, $MonthlyPlansTable> {
  $$MonthlyPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CalendarMonth, CalendarMonth, String>
  get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get targetAmountMinor => $composableBuilder(
    column: $table.targetAmountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get assignedAmountMinor => $composableBuilder(
    column: $table.assignedAmountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MonthlyPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $MonthlyPlansTable> {
  $$MonthlyPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetAmountMinor => $composableBuilder(
    column: $table.targetAmountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get assignedAmountMinor => $composableBuilder(
    column: $table.assignedAmountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MonthlyPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $MonthlyPlansTable> {
  $$MonthlyPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CalendarMonth, String> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get targetAmountMinor => $composableBuilder(
    column: $table.targetAmountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get assignedAmountMinor => $composableBuilder(
    column: $table.assignedAmountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MonthlyPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MonthlyPlansTable,
          MonthlyPlanRow,
          $$MonthlyPlansTableFilterComposer,
          $$MonthlyPlansTableOrderingComposer,
          $$MonthlyPlansTableAnnotationComposer,
          $$MonthlyPlansTableCreateCompanionBuilder,
          $$MonthlyPlansTableUpdateCompanionBuilder,
          (MonthlyPlanRow, $$MonthlyPlansTableReferences),
          MonthlyPlanRow,
          PrefetchHooks Function({bool categoryId})
        > {
  $$MonthlyPlansTableTableManager(_$AppDatabase db, $MonthlyPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonthlyPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MonthlyPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MonthlyPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<CalendarMonth> month = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<int?> targetAmountMinor = const Value.absent(),
                Value<int> assignedAmountMinor = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => MonthlyPlansCompanion(
                id: id,
                month: month,
                categoryId: categoryId,
                targetAmountMinor: targetAmountMinor,
                assignedAmountMinor: assignedAmountMinor,
                currencyCode: currencyCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required CalendarMonth month,
                required int categoryId,
                Value<int?> targetAmountMinor = const Value.absent(),
                required int assignedAmountMinor,
                required String currencyCode,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => MonthlyPlansCompanion.insert(
                id: id,
                month: month,
                categoryId: categoryId,
                targetAmountMinor: targetAmountMinor,
                assignedAmountMinor: assignedAmountMinor,
                currencyCode: currencyCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MonthlyPlansTable, MonthlyPlanRow>(table),
                  $$MonthlyPlansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$MonthlyPlansTableReferences
                            ._categoryIdTable(db),
                        referencedColumn: $$MonthlyPlansTableReferences
                            ._categoryIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MonthlyPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MonthlyPlansTable,
      MonthlyPlanRow,
      $$MonthlyPlansTableFilterComposer,
      $$MonthlyPlansTableOrderingComposer,
      $$MonthlyPlansTableAnnotationComposer,
      $$MonthlyPlansTableCreateCompanionBuilder,
      $$MonthlyPlansTableUpdateCompanionBuilder,
      (MonthlyPlanRow, $$MonthlyPlansTableReferences),
      MonthlyPlanRow,
      PrefetchHooks Function({bool categoryId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CustomAccountTypesTableTableManager get customAccountTypes =>
      $$CustomAccountTypesTableTableManager(_db, _db.customAccountTypes);
  $$CustomBanksTableTableManager get customBanks =>
      $$CustomBanksTableTableManager(_db, _db.customBanks);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$MonthlyPlansTableTableManager get monthlyPlans =>
      $$MonthlyPlansTableTableManager(_db, _db.monthlyPlans);
}
