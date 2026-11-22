// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'synced_database.dart';

// ignore_for_file: type=lint
class $SyncedCustomAccountTypesTable extends SyncedCustomAccountTypes
    with TableInfo<$SyncedCustomAccountTypesTable, SyncedCustomAccountTypeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncedCustomAccountTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseTypeMeta = const VerificationMeta(
    'baseType',
  );
  @override
  late final GeneratedColumn<String> baseType = GeneratedColumn<String>(
    'base_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    baseType,
    createdAt,
    updatedAt,
    revision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_account_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncedCustomAccountTypeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('base_type')) {
      context.handle(
        _baseTypeMeta,
        baseType.isAcceptableOrUnknown(data['base_type']!, _baseTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_baseTypeMeta);
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
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncedCustomAccountTypeRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncedCustomAccountTypeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      baseType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  $SyncedCustomAccountTypesTable createAlias(String alias) {
    return $SyncedCustomAccountTypesTable(attachedDatabase, alias);
  }
}

class SyncedCustomAccountTypeRow extends DataClass
    implements Insertable<SyncedCustomAccountTypeRow> {
  final String id;
  final String name;
  final String baseType;
  final String createdAt;
  final String updatedAt;
  final int revision;
  const SyncedCustomAccountTypeRow({
    required this.id,
    required this.name,
    required this.baseType,
    required this.createdAt,
    required this.updatedAt,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['base_type'] = Variable<String>(baseType);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['revision'] = Variable<int>(revision);
    return map;
  }

  SyncedCustomAccountTypesCompanion toCompanion(bool nullToAbsent) {
    return SyncedCustomAccountTypesCompanion(
      id: Value(id),
      name: Value(name),
      baseType: Value(baseType),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      revision: Value(revision),
    );
  }

  factory SyncedCustomAccountTypeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncedCustomAccountTypeRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      baseType: serializer.fromJson<String>(json['baseType']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'baseType': serializer.toJson<String>(baseType),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'revision': serializer.toJson<int>(revision),
    };
  }

  SyncedCustomAccountTypeRow copyWith({
    String? id,
    String? name,
    String? baseType,
    String? createdAt,
    String? updatedAt,
    int? revision,
  }) => SyncedCustomAccountTypeRow(
    id: id ?? this.id,
    name: name ?? this.name,
    baseType: baseType ?? this.baseType,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    revision: revision ?? this.revision,
  );
  SyncedCustomAccountTypeRow copyWithCompanion(
    SyncedCustomAccountTypesCompanion data,
  ) {
    return SyncedCustomAccountTypeRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      baseType: data.baseType.present ? data.baseType.value : this.baseType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncedCustomAccountTypeRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseType: $baseType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, baseType, createdAt, updatedAt, revision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncedCustomAccountTypeRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.baseType == this.baseType &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.revision == this.revision);
}

class SyncedCustomAccountTypesCompanion
    extends UpdateCompanion<SyncedCustomAccountTypeRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> baseType;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> revision;
  final Value<int> rowid;
  const SyncedCustomAccountTypesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.baseType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncedCustomAccountTypesCompanion.insert({
    required String id,
    required String name,
    required String baseType,
    required String createdAt,
    required String updatedAt,
    required int revision,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       baseType = Value(baseType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       revision = Value(revision);
  static Insertable<SyncedCustomAccountTypeRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? baseType,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? revision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (baseType != null) 'base_type': baseType,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncedCustomAccountTypesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? baseType,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return SyncedCustomAccountTypesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      baseType: baseType ?? this.baseType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (baseType.present) {
      map['base_type'] = Variable<String>(baseType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncedCustomAccountTypesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseType: $baseType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncedAccountsTable extends SyncedAccounts
    with TableInfo<$SyncedAccountsTable, SyncedAccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncedAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
  );
  static const VerificationMeta _customTypeIdMeta = const VerificationMeta(
    'customTypeId',
  );
  @override
  late final GeneratedColumn<String> customTypeId = GeneratedColumn<String>(
    'custom_type_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isBudgetAccountMeta = const VerificationMeta(
    'isBudgetAccount',
  );
  @override
  late final GeneratedColumn<bool> isBudgetAccount = GeneratedColumn<bool>(
    'is_budget_account',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_budget_account" IN (0, 1))',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    openingBalanceMinor,
    currencyCode,
    isArchived,
    customTypeId,
    isBudgetAccount,
    createdAt,
    updatedAt,
    revision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncedAccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
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
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    } else if (isInserting) {
      context.missing(_isArchivedMeta);
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
    } else if (isInserting) {
      context.missing(_isBudgetAccountMeta);
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
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncedAccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncedAccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      openingBalanceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_balance_minor'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      customTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_type_id'],
      ),
      isBudgetAccount: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_budget_account'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  $SyncedAccountsTable createAlias(String alias) {
    return $SyncedAccountsTable(attachedDatabase, alias);
  }
}

class SyncedAccountRow extends DataClass
    implements Insertable<SyncedAccountRow> {
  final String id;
  final String name;
  final String type;
  final int openingBalanceMinor;
  final String currencyCode;
  final bool isArchived;
  final String? customTypeId;
  final bool isBudgetAccount;
  final String createdAt;
  final String updatedAt;
  final int revision;
  const SyncedAccountRow({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalanceMinor,
    required this.currencyCode,
    required this.isArchived,
    this.customTypeId,
    required this.isBudgetAccount,
    required this.createdAt,
    required this.updatedAt,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['opening_balance_minor'] = Variable<int>(openingBalanceMinor);
    map['currency_code'] = Variable<String>(currencyCode);
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || customTypeId != null) {
      map['custom_type_id'] = Variable<String>(customTypeId);
    }
    map['is_budget_account'] = Variable<bool>(isBudgetAccount);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['revision'] = Variable<int>(revision);
    return map;
  }

  SyncedAccountsCompanion toCompanion(bool nullToAbsent) {
    return SyncedAccountsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      openingBalanceMinor: Value(openingBalanceMinor),
      currencyCode: Value(currencyCode),
      isArchived: Value(isArchived),
      customTypeId: customTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(customTypeId),
      isBudgetAccount: Value(isBudgetAccount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      revision: Value(revision),
    );
  }

  factory SyncedAccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncedAccountRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      openingBalanceMinor: serializer.fromJson<int>(
        json['openingBalanceMinor'],
      ),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      customTypeId: serializer.fromJson<String?>(json['customTypeId']),
      isBudgetAccount: serializer.fromJson<bool>(json['isBudgetAccount']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'openingBalanceMinor': serializer.toJson<int>(openingBalanceMinor),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'isArchived': serializer.toJson<bool>(isArchived),
      'customTypeId': serializer.toJson<String?>(customTypeId),
      'isBudgetAccount': serializer.toJson<bool>(isBudgetAccount),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'revision': serializer.toJson<int>(revision),
    };
  }

  SyncedAccountRow copyWith({
    String? id,
    String? name,
    String? type,
    int? openingBalanceMinor,
    String? currencyCode,
    bool? isArchived,
    Value<String?> customTypeId = const Value.absent(),
    bool? isBudgetAccount,
    String? createdAt,
    String? updatedAt,
    int? revision,
  }) => SyncedAccountRow(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
    currencyCode: currencyCode ?? this.currencyCode,
    isArchived: isArchived ?? this.isArchived,
    customTypeId: customTypeId.present ? customTypeId.value : this.customTypeId,
    isBudgetAccount: isBudgetAccount ?? this.isBudgetAccount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    revision: revision ?? this.revision,
  );
  SyncedAccountRow copyWithCompanion(SyncedAccountsCompanion data) {
    return SyncedAccountRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      openingBalanceMinor: data.openingBalanceMinor.present
          ? data.openingBalanceMinor.value
          : this.openingBalanceMinor,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      customTypeId: data.customTypeId.present
          ? data.customTypeId.value
          : this.customTypeId,
      isBudgetAccount: data.isBudgetAccount.present
          ? data.isBudgetAccount.value
          : this.isBudgetAccount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncedAccountRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('openingBalanceMinor: $openingBalanceMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('isArchived: $isArchived, ')
          ..write('customTypeId: $customTypeId, ')
          ..write('isBudgetAccount: $isBudgetAccount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision')
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
    isArchived,
    customTypeId,
    isBudgetAccount,
    createdAt,
    updatedAt,
    revision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncedAccountRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.openingBalanceMinor == this.openingBalanceMinor &&
          other.currencyCode == this.currencyCode &&
          other.isArchived == this.isArchived &&
          other.customTypeId == this.customTypeId &&
          other.isBudgetAccount == this.isBudgetAccount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.revision == this.revision);
}

class SyncedAccountsCompanion extends UpdateCompanion<SyncedAccountRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<int> openingBalanceMinor;
  final Value<String> currencyCode;
  final Value<bool> isArchived;
  final Value<String?> customTypeId;
  final Value<bool> isBudgetAccount;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> revision;
  final Value<int> rowid;
  const SyncedAccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.openingBalanceMinor = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.customTypeId = const Value.absent(),
    this.isBudgetAccount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncedAccountsCompanion.insert({
    required String id,
    required String name,
    required String type,
    required int openingBalanceMinor,
    required String currencyCode,
    required bool isArchived,
    this.customTypeId = const Value.absent(),
    required bool isBudgetAccount,
    required String createdAt,
    required String updatedAt,
    required int revision,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       openingBalanceMinor = Value(openingBalanceMinor),
       currencyCode = Value(currencyCode),
       isArchived = Value(isArchived),
       isBudgetAccount = Value(isBudgetAccount),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       revision = Value(revision);
  static Insertable<SyncedAccountRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? openingBalanceMinor,
    Expression<String>? currencyCode,
    Expression<bool>? isArchived,
    Expression<String>? customTypeId,
    Expression<bool>? isBudgetAccount,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? revision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (openingBalanceMinor != null)
        'opening_balance_minor': openingBalanceMinor,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (isArchived != null) 'is_archived': isArchived,
      if (customTypeId != null) 'custom_type_id': customTypeId,
      if (isBudgetAccount != null) 'is_budget_account': isBudgetAccount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncedAccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? type,
    Value<int>? openingBalanceMinor,
    Value<String>? currencyCode,
    Value<bool>? isArchived,
    Value<String?>? customTypeId,
    Value<bool>? isBudgetAccount,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return SyncedAccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      isArchived: isArchived ?? this.isArchived,
      customTypeId: customTypeId ?? this.customTypeId,
      isBudgetAccount: isBudgetAccount ?? this.isBudgetAccount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (openingBalanceMinor.present) {
      map['opening_balance_minor'] = Variable<int>(openingBalanceMinor.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (customTypeId.present) {
      map['custom_type_id'] = Variable<String>(customTypeId.value);
    }
    if (isBudgetAccount.present) {
      map['is_budget_account'] = Variable<bool>(isBudgetAccount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncedAccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('openingBalanceMinor: $openingBalanceMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('isArchived: $isArchived, ')
          ..write('customTypeId: $customTypeId, ')
          ..write('isBudgetAccount: $isBudgetAccount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncedCategoriesTable extends SyncedCategories
    with TableInfo<$SyncedCategoriesTable, SyncedCategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncedCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
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
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_plan_archived" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isPlanDeletedMeta = const VerificationMeta(
    'isPlanDeleted',
  );
  @override
  late final GeneratedColumn<bool> isPlanDeleted = GeneratedColumn<bool>(
    'is_plan_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_plan_deleted" IN (0, 1))',
    ),
  );
  static const VerificationMeta _planGroupMeta = const VerificationMeta(
    'planGroup',
  );
  @override
  late final GeneratedColumn<String> planGroup = GeneratedColumn<String>(
    'plan_group',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _linkedAccountIdMeta = const VerificationMeta(
    'linkedAccountId',
  );
  @override
  late final GeneratedColumn<String> linkedAccountId = GeneratedColumn<String>(
    'linked_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    createdAt,
    updatedAt,
    revision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncedCategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    } else if (isInserting) {
      context.missing(_isArchivedMeta);
    }
    if (data.containsKey('is_plan_archived')) {
      context.handle(
        _isPlanArchivedMeta,
        isPlanArchived.isAcceptableOrUnknown(
          data['is_plan_archived']!,
          _isPlanArchivedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isPlanArchivedMeta);
    }
    if (data.containsKey('is_plan_deleted')) {
      context.handle(
        _isPlanDeletedMeta,
        isPlanDeleted.isAcceptableOrUnknown(
          data['is_plan_deleted']!,
          _isPlanDeletedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isPlanDeletedMeta);
    }
    if (data.containsKey('plan_group')) {
      context.handle(
        _planGroupMeta,
        planGroup.isAcceptableOrUnknown(data['plan_group']!, _planGroupMeta),
      );
    } else if (isInserting) {
      context.missing(_planGroupMeta);
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
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncedCategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncedCategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
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
      planGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_group'],
      )!,
      linkedAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_account_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  $SyncedCategoriesTable createAlias(String alias) {
    return $SyncedCategoriesTable(attachedDatabase, alias);
  }
}

class SyncedCategoryRow extends DataClass
    implements Insertable<SyncedCategoryRow> {
  final String id;
  final String name;
  final String kind;
  final bool isArchived;
  final bool isPlanArchived;
  final bool isPlanDeleted;
  final String planGroup;
  final String? linkedAccountId;
  final String createdAt;
  final String updatedAt;
  final int revision;
  const SyncedCategoryRow({
    required this.id,
    required this.name,
    required this.kind,
    required this.isArchived,
    required this.isPlanArchived,
    required this.isPlanDeleted,
    required this.planGroup,
    this.linkedAccountId,
    required this.createdAt,
    required this.updatedAt,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['is_archived'] = Variable<bool>(isArchived);
    map['is_plan_archived'] = Variable<bool>(isPlanArchived);
    map['is_plan_deleted'] = Variable<bool>(isPlanDeleted);
    map['plan_group'] = Variable<String>(planGroup);
    if (!nullToAbsent || linkedAccountId != null) {
      map['linked_account_id'] = Variable<String>(linkedAccountId);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['revision'] = Variable<int>(revision);
    return map;
  }

  SyncedCategoriesCompanion toCompanion(bool nullToAbsent) {
    return SyncedCategoriesCompanion(
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
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      revision: Value(revision),
    );
  }

  factory SyncedCategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncedCategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      isPlanArchived: serializer.fromJson<bool>(json['isPlanArchived']),
      isPlanDeleted: serializer.fromJson<bool>(json['isPlanDeleted']),
      planGroup: serializer.fromJson<String>(json['planGroup']),
      linkedAccountId: serializer.fromJson<String?>(json['linkedAccountId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'isArchived': serializer.toJson<bool>(isArchived),
      'isPlanArchived': serializer.toJson<bool>(isPlanArchived),
      'isPlanDeleted': serializer.toJson<bool>(isPlanDeleted),
      'planGroup': serializer.toJson<String>(planGroup),
      'linkedAccountId': serializer.toJson<String?>(linkedAccountId),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'revision': serializer.toJson<int>(revision),
    };
  }

  SyncedCategoryRow copyWith({
    String? id,
    String? name,
    String? kind,
    bool? isArchived,
    bool? isPlanArchived,
    bool? isPlanDeleted,
    String? planGroup,
    Value<String?> linkedAccountId = const Value.absent(),
    String? createdAt,
    String? updatedAt,
    int? revision,
  }) => SyncedCategoryRow(
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
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    revision: revision ?? this.revision,
  );
  SyncedCategoryRow copyWithCompanion(SyncedCategoriesCompanion data) {
    return SyncedCategoryRow(
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
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncedCategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('isArchived: $isArchived, ')
          ..write('isPlanArchived: $isPlanArchived, ')
          ..write('isPlanDeleted: $isPlanDeleted, ')
          ..write('planGroup: $planGroup, ')
          ..write('linkedAccountId: $linkedAccountId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision')
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
    createdAt,
    updatedAt,
    revision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncedCategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.isArchived == this.isArchived &&
          other.isPlanArchived == this.isPlanArchived &&
          other.isPlanDeleted == this.isPlanDeleted &&
          other.planGroup == this.planGroup &&
          other.linkedAccountId == this.linkedAccountId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.revision == this.revision);
}

class SyncedCategoriesCompanion extends UpdateCompanion<SyncedCategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<bool> isArchived;
  final Value<bool> isPlanArchived;
  final Value<bool> isPlanDeleted;
  final Value<String> planGroup;
  final Value<String?> linkedAccountId;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> revision;
  final Value<int> rowid;
  const SyncedCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isPlanArchived = const Value.absent(),
    this.isPlanDeleted = const Value.absent(),
    this.planGroup = const Value.absent(),
    this.linkedAccountId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncedCategoriesCompanion.insert({
    required String id,
    required String name,
    required String kind,
    required bool isArchived,
    required bool isPlanArchived,
    required bool isPlanDeleted,
    required String planGroup,
    this.linkedAccountId = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    required int revision,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       kind = Value(kind),
       isArchived = Value(isArchived),
       isPlanArchived = Value(isPlanArchived),
       isPlanDeleted = Value(isPlanDeleted),
       planGroup = Value(planGroup),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       revision = Value(revision);
  static Insertable<SyncedCategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<bool>? isArchived,
    Expression<bool>? isPlanArchived,
    Expression<bool>? isPlanDeleted,
    Expression<String>? planGroup,
    Expression<String>? linkedAccountId,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? revision,
    Expression<int>? rowid,
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
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncedCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? kind,
    Value<bool>? isArchived,
    Value<bool>? isPlanArchived,
    Value<bool>? isPlanDeleted,
    Value<String>? planGroup,
    Value<String?>? linkedAccountId,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return SyncedCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      isArchived: isArchived ?? this.isArchived,
      isPlanArchived: isPlanArchived ?? this.isPlanArchived,
      isPlanDeleted: isPlanDeleted ?? this.isPlanDeleted,
      planGroup: planGroup ?? this.planGroup,
      linkedAccountId: linkedAccountId ?? this.linkedAccountId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
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
      map['plan_group'] = Variable<String>(planGroup.value);
    }
    if (linkedAccountId.present) {
      map['linked_account_id'] = Variable<String>(linkedAccountId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncedCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('isArchived: $isArchived, ')
          ..write('isPlanArchived: $isPlanArchived, ')
          ..write('isPlanDeleted: $isPlanDeleted, ')
          ..write('planGroup: $planGroup, ')
          ..write('linkedAccountId: $linkedAccountId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncedTransactionsTable extends SyncedTransactions
    with TableInfo<$SyncedTransactionsTable, SyncedTransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncedTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payeeMeta = const VerificationMeta('payee');
  @override
  late final GeneratedColumn<String> payee = GeneratedColumn<String>(
    'payee',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceAccountIdMeta = const VerificationMeta(
    'sourceAccountId',
  );
  @override
  late final GeneratedColumn<String> sourceAccountId = GeneratedColumn<String>(
    'source_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _destinationAccountIdMeta =
      const VerificationMeta('destinationAccountId');
  @override
  late final GeneratedColumn<String> destinationAccountId =
      GeneratedColumn<String>(
        'destination_account_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    revision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncedTransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
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
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('payee')) {
      context.handle(
        _payeeMeta,
        payee.isAcceptableOrUnknown(data['payee']!, _payeeMeta),
      );
    } else if (isInserting) {
      context.missing(_payeeMeta);
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
    } else if (isInserting) {
      context.missing(_noteMeta);
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
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncedTransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncedTransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      payee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payee'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      sourceAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_account_id'],
      ),
      destinationAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_account_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  $SyncedTransactionsTable createAlias(String alias) {
    return $SyncedTransactionsTable(attachedDatabase, alias);
  }
}

class SyncedTransactionRow extends DataClass
    implements Insertable<SyncedTransactionRow> {
  final String id;
  final String type;
  final int amountMinor;
  final String currencyCode;

  /// `YYYY-MM-DD`; see `parseSyncedDate` for year 0000.
  final String date;
  final String payee;
  final String? categoryId;
  final String? sourceAccountId;
  final String? destinationAccountId;
  final String note;
  final String createdAt;
  final String updatedAt;
  final int revision;
  const SyncedTransactionRow({
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
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency_code'] = Variable<String>(currencyCode);
    map['date'] = Variable<String>(date);
    map['payee'] = Variable<String>(payee);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || sourceAccountId != null) {
      map['source_account_id'] = Variable<String>(sourceAccountId);
    }
    if (!nullToAbsent || destinationAccountId != null) {
      map['destination_account_id'] = Variable<String>(destinationAccountId);
    }
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['revision'] = Variable<int>(revision);
    return map;
  }

  SyncedTransactionsCompanion toCompanion(bool nullToAbsent) {
    return SyncedTransactionsCompanion(
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
      revision: Value(revision),
    );
  }

  factory SyncedTransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncedTransactionRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      date: serializer.fromJson<String>(json['date']),
      payee: serializer.fromJson<String>(json['payee']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      sourceAccountId: serializer.fromJson<String?>(json['sourceAccountId']),
      destinationAccountId: serializer.fromJson<String?>(
        json['destinationAccountId'],
      ),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'date': serializer.toJson<String>(date),
      'payee': serializer.toJson<String>(payee),
      'categoryId': serializer.toJson<String?>(categoryId),
      'sourceAccountId': serializer.toJson<String?>(sourceAccountId),
      'destinationAccountId': serializer.toJson<String?>(destinationAccountId),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'revision': serializer.toJson<int>(revision),
    };
  }

  SyncedTransactionRow copyWith({
    String? id,
    String? type,
    int? amountMinor,
    String? currencyCode,
    String? date,
    String? payee,
    Value<String?> categoryId = const Value.absent(),
    Value<String?> sourceAccountId = const Value.absent(),
    Value<String?> destinationAccountId = const Value.absent(),
    String? note,
    String? createdAt,
    String? updatedAt,
    int? revision,
  }) => SyncedTransactionRow(
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
    revision: revision ?? this.revision,
  );
  SyncedTransactionRow copyWithCompanion(SyncedTransactionsCompanion data) {
    return SyncedTransactionRow(
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
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncedTransactionRow(')
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
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision')
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
    revision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncedTransactionRow &&
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
          other.updatedAt == this.updatedAt &&
          other.revision == this.revision);
}

class SyncedTransactionsCompanion
    extends UpdateCompanion<SyncedTransactionRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<int> amountMinor;
  final Value<String> currencyCode;
  final Value<String> date;
  final Value<String> payee;
  final Value<String?> categoryId;
  final Value<String?> sourceAccountId;
  final Value<String?> destinationAccountId;
  final Value<String> note;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> revision;
  final Value<int> rowid;
  const SyncedTransactionsCompanion({
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
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncedTransactionsCompanion.insert({
    required String id,
    required String type,
    required int amountMinor,
    required String currencyCode,
    required String date,
    required String payee,
    this.categoryId = const Value.absent(),
    this.sourceAccountId = const Value.absent(),
    this.destinationAccountId = const Value.absent(),
    required String note,
    required String createdAt,
    required String updatedAt,
    required int revision,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       amountMinor = Value(amountMinor),
       currencyCode = Value(currencyCode),
       date = Value(date),
       payee = Value(payee),
       note = Value(note),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       revision = Value(revision);
  static Insertable<SyncedTransactionRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<int>? amountMinor,
    Expression<String>? currencyCode,
    Expression<String>? date,
    Expression<String>? payee,
    Expression<String>? categoryId,
    Expression<String>? sourceAccountId,
    Expression<String>? destinationAccountId,
    Expression<String>? note,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? revision,
    Expression<int>? rowid,
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
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncedTransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<int>? amountMinor,
    Value<String>? currencyCode,
    Value<String>? date,
    Value<String>? payee,
    Value<String?>? categoryId,
    Value<String?>? sourceAccountId,
    Value<String?>? destinationAccountId,
    Value<String>? note,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return SyncedTransactionsCompanion(
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
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (payee.present) {
      map['payee'] = Variable<String>(payee.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (sourceAccountId.present) {
      map['source_account_id'] = Variable<String>(sourceAccountId.value);
    }
    if (destinationAccountId.present) {
      map['destination_account_id'] = Variable<String>(
        destinationAccountId.value,
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncedTransactionsCompanion(')
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
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncedMonthlyPlansTable extends SyncedMonthlyPlans
    with TableInfo<$SyncedMonthlyPlansTable, SyncedMonthlyPlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncedMonthlyPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<String> month = GeneratedColumn<String>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    revision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'monthly_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncedMonthlyPlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
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
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncedMonthlyPlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncedMonthlyPlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
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
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  $SyncedMonthlyPlansTable createAlias(String alias) {
    return $SyncedMonthlyPlansTable(attachedDatabase, alias);
  }
}

class SyncedMonthlyPlanRow extends DataClass
    implements Insertable<SyncedMonthlyPlanRow> {
  final String id;

  /// `YYYY-MM`.
  final String month;
  final String categoryId;
  final int? targetAmountMinor;
  final int assignedAmountMinor;
  final String currencyCode;
  final String createdAt;
  final String updatedAt;
  final int revision;
  const SyncedMonthlyPlanRow({
    required this.id,
    required this.month,
    required this.categoryId,
    this.targetAmountMinor,
    required this.assignedAmountMinor,
    required this.currencyCode,
    required this.createdAt,
    required this.updatedAt,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['month'] = Variable<String>(month);
    map['category_id'] = Variable<String>(categoryId);
    if (!nullToAbsent || targetAmountMinor != null) {
      map['target_amount_minor'] = Variable<int>(targetAmountMinor);
    }
    map['assigned_amount_minor'] = Variable<int>(assignedAmountMinor);
    map['currency_code'] = Variable<String>(currencyCode);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['revision'] = Variable<int>(revision);
    return map;
  }

  SyncedMonthlyPlansCompanion toCompanion(bool nullToAbsent) {
    return SyncedMonthlyPlansCompanion(
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
      revision: Value(revision),
    );
  }

  factory SyncedMonthlyPlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncedMonthlyPlanRow(
      id: serializer.fromJson<String>(json['id']),
      month: serializer.fromJson<String>(json['month']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      targetAmountMinor: serializer.fromJson<int?>(json['targetAmountMinor']),
      assignedAmountMinor: serializer.fromJson<int>(
        json['assignedAmountMinor'],
      ),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'month': serializer.toJson<String>(month),
      'categoryId': serializer.toJson<String>(categoryId),
      'targetAmountMinor': serializer.toJson<int?>(targetAmountMinor),
      'assignedAmountMinor': serializer.toJson<int>(assignedAmountMinor),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'revision': serializer.toJson<int>(revision),
    };
  }

  SyncedMonthlyPlanRow copyWith({
    String? id,
    String? month,
    String? categoryId,
    Value<int?> targetAmountMinor = const Value.absent(),
    int? assignedAmountMinor,
    String? currencyCode,
    String? createdAt,
    String? updatedAt,
    int? revision,
  }) => SyncedMonthlyPlanRow(
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
    revision: revision ?? this.revision,
  );
  SyncedMonthlyPlanRow copyWithCompanion(SyncedMonthlyPlansCompanion data) {
    return SyncedMonthlyPlanRow(
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
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncedMonthlyPlanRow(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('categoryId: $categoryId, ')
          ..write('targetAmountMinor: $targetAmountMinor, ')
          ..write('assignedAmountMinor: $assignedAmountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision')
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
    revision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncedMonthlyPlanRow &&
          other.id == this.id &&
          other.month == this.month &&
          other.categoryId == this.categoryId &&
          other.targetAmountMinor == this.targetAmountMinor &&
          other.assignedAmountMinor == this.assignedAmountMinor &&
          other.currencyCode == this.currencyCode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.revision == this.revision);
}

class SyncedMonthlyPlansCompanion
    extends UpdateCompanion<SyncedMonthlyPlanRow> {
  final Value<String> id;
  final Value<String> month;
  final Value<String> categoryId;
  final Value<int?> targetAmountMinor;
  final Value<int> assignedAmountMinor;
  final Value<String> currencyCode;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> revision;
  final Value<int> rowid;
  const SyncedMonthlyPlansCompanion({
    this.id = const Value.absent(),
    this.month = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.targetAmountMinor = const Value.absent(),
    this.assignedAmountMinor = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncedMonthlyPlansCompanion.insert({
    required String id,
    required String month,
    required String categoryId,
    this.targetAmountMinor = const Value.absent(),
    required int assignedAmountMinor,
    required String currencyCode,
    required String createdAt,
    required String updatedAt,
    required int revision,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       month = Value(month),
       categoryId = Value(categoryId),
       assignedAmountMinor = Value(assignedAmountMinor),
       currencyCode = Value(currencyCode),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       revision = Value(revision);
  static Insertable<SyncedMonthlyPlanRow> custom({
    Expression<String>? id,
    Expression<String>? month,
    Expression<String>? categoryId,
    Expression<int>? targetAmountMinor,
    Expression<int>? assignedAmountMinor,
    Expression<String>? currencyCode,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? revision,
    Expression<int>? rowid,
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
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncedMonthlyPlansCompanion copyWith({
    Value<String>? id,
    Value<String>? month,
    Value<String>? categoryId,
    Value<int?>? targetAmountMinor,
    Value<int>? assignedAmountMinor,
    Value<String>? currencyCode,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return SyncedMonthlyPlansCompanion(
      id: id ?? this.id,
      month: month ?? this.month,
      categoryId: categoryId ?? this.categoryId,
      targetAmountMinor: targetAmountMinor ?? this.targetAmountMinor,
      assignedAmountMinor: assignedAmountMinor ?? this.assignedAmountMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (month.present) {
      map['month'] = Variable<String>(month.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
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
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncedMonthlyPlansCompanion(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('categoryId: $categoryId, ')
          ..write('targetAmountMinor: $targetAmountMinor, ')
          ..write('assignedAmountMinor: $assignedAmountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncRejectionsTable extends SyncRejections
    with TableInfo<$SyncRejectionsTable, SyncRejectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncRejectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _causedByMeta = const VerificationMeta(
    'causedBy',
  );
  @override
  late final GeneratedColumn<String> causedBy = GeneratedColumn<String>(
    'caused_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _operationsMeta = const VerificationMeta(
    'operations',
  );
  @override
  late final GeneratedColumn<String> operations = GeneratedColumn<String>(
    'operations',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdIdsMeta = const VerificationMeta(
    'createdIds',
  );
  @override
  late final GeneratedColumn<String> createdIds = GeneratedColumn<String>(
    'created_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelsMeta = const VerificationMeta('labels');
  @override
  late final GeneratedColumn<String> labels = GeneratedColumn<String>(
    'labels',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rejectedAtMeta = const VerificationMeta(
    'rejectedAt',
  );
  @override
  late final GeneratedColumn<String> rejectedAt = GeneratedColumn<String>(
    'rejected_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    batchId,
    kind,
    code,
    detail,
    causedBy,
    operations,
    createdIds,
    labels,
    rejectedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_rejections';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncRejectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    }
    if (data.containsKey('caused_by')) {
      context.handle(
        _causedByMeta,
        causedBy.isAcceptableOrUnknown(data['caused_by']!, _causedByMeta),
      );
    }
    if (data.containsKey('operations')) {
      context.handle(
        _operationsMeta,
        operations.isAcceptableOrUnknown(data['operations']!, _operationsMeta),
      );
    } else if (isInserting) {
      context.missing(_operationsMeta);
    }
    if (data.containsKey('created_ids')) {
      context.handle(
        _createdIdsMeta,
        createdIds.isAcceptableOrUnknown(data['created_ids']!, _createdIdsMeta),
      );
    } else if (isInserting) {
      context.missing(_createdIdsMeta);
    }
    if (data.containsKey('labels')) {
      context.handle(
        _labelsMeta,
        labels.isAcceptableOrUnknown(data['labels']!, _labelsMeta),
      );
    } else if (isInserting) {
      context.missing(_labelsMeta);
    }
    if (data.containsKey('rejected_at')) {
      context.handle(
        _rejectedAtMeta,
        rejectedAt.isAcceptableOrUnknown(data['rejected_at']!, _rejectedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_rejectedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {batchId};
  @override
  SyncRejectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncRejectionRow(
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      ),
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      ),
      causedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caused_by'],
      ),
      operations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operations'],
      )!,
      createdIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_ids'],
      )!,
      labels: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}labels'],
      )!,
      rejectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rejected_at'],
      )!,
    );
  }

  @override
  $SyncRejectionsTable createAlias(String alias) {
    return $SyncRejectionsTable(attachedDatabase, alias);
  }
}

class SyncRejectionRow extends DataClass
    implements Insertable<SyncRejectionRow> {
  /// The refused batch's UUID. One entry per batch, so a retry after a crash
  /// cannot record it twice.
  final String batchId;

  /// `rejected`, or `dependency_rejected` for a batch that was never sent
  /// because it relied on a refused one.
  final String kind;

  /// The server's message code; null for `dependency_rejected`.
  final String? code;

  /// The server's JSON detail, when it sent one.
  final String? detail;

  /// For `dependency_rejected`: the batch it relied on.
  final String? causedBy;

  /// The batch envelope exactly as queued: what the user tried to do.
  final String operations;

  /// JSON list of the IDs the batch would have created.
  final String createdIds;

  /// JSON object of record ID → name (or payee) as the device showed them
  /// when the change was refused, so it can still be described after the
  /// records return to the server's state.
  final String labels;

  /// UTC, ISO 8601.
  final String rejectedAt;
  const SyncRejectionRow({
    required this.batchId,
    required this.kind,
    this.code,
    this.detail,
    this.causedBy,
    required this.operations,
    required this.createdIds,
    required this.labels,
    required this.rejectedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['batch_id'] = Variable<String>(batchId);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    if (!nullToAbsent || detail != null) {
      map['detail'] = Variable<String>(detail);
    }
    if (!nullToAbsent || causedBy != null) {
      map['caused_by'] = Variable<String>(causedBy);
    }
    map['operations'] = Variable<String>(operations);
    map['created_ids'] = Variable<String>(createdIds);
    map['labels'] = Variable<String>(labels);
    map['rejected_at'] = Variable<String>(rejectedAt);
    return map;
  }

  SyncRejectionsCompanion toCompanion(bool nullToAbsent) {
    return SyncRejectionsCompanion(
      batchId: Value(batchId),
      kind: Value(kind),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      detail: detail == null && nullToAbsent
          ? const Value.absent()
          : Value(detail),
      causedBy: causedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(causedBy),
      operations: Value(operations),
      createdIds: Value(createdIds),
      labels: Value(labels),
      rejectedAt: Value(rejectedAt),
    );
  }

  factory SyncRejectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncRejectionRow(
      batchId: serializer.fromJson<String>(json['batchId']),
      kind: serializer.fromJson<String>(json['kind']),
      code: serializer.fromJson<String?>(json['code']),
      detail: serializer.fromJson<String?>(json['detail']),
      causedBy: serializer.fromJson<String?>(json['causedBy']),
      operations: serializer.fromJson<String>(json['operations']),
      createdIds: serializer.fromJson<String>(json['createdIds']),
      labels: serializer.fromJson<String>(json['labels']),
      rejectedAt: serializer.fromJson<String>(json['rejectedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'batchId': serializer.toJson<String>(batchId),
      'kind': serializer.toJson<String>(kind),
      'code': serializer.toJson<String?>(code),
      'detail': serializer.toJson<String?>(detail),
      'causedBy': serializer.toJson<String?>(causedBy),
      'operations': serializer.toJson<String>(operations),
      'createdIds': serializer.toJson<String>(createdIds),
      'labels': serializer.toJson<String>(labels),
      'rejectedAt': serializer.toJson<String>(rejectedAt),
    };
  }

  SyncRejectionRow copyWith({
    String? batchId,
    String? kind,
    Value<String?> code = const Value.absent(),
    Value<String?> detail = const Value.absent(),
    Value<String?> causedBy = const Value.absent(),
    String? operations,
    String? createdIds,
    String? labels,
    String? rejectedAt,
  }) => SyncRejectionRow(
    batchId: batchId ?? this.batchId,
    kind: kind ?? this.kind,
    code: code.present ? code.value : this.code,
    detail: detail.present ? detail.value : this.detail,
    causedBy: causedBy.present ? causedBy.value : this.causedBy,
    operations: operations ?? this.operations,
    createdIds: createdIds ?? this.createdIds,
    labels: labels ?? this.labels,
    rejectedAt: rejectedAt ?? this.rejectedAt,
  );
  SyncRejectionRow copyWithCompanion(SyncRejectionsCompanion data) {
    return SyncRejectionRow(
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      kind: data.kind.present ? data.kind.value : this.kind,
      code: data.code.present ? data.code.value : this.code,
      detail: data.detail.present ? data.detail.value : this.detail,
      causedBy: data.causedBy.present ? data.causedBy.value : this.causedBy,
      operations: data.operations.present
          ? data.operations.value
          : this.operations,
      createdIds: data.createdIds.present
          ? data.createdIds.value
          : this.createdIds,
      labels: data.labels.present ? data.labels.value : this.labels,
      rejectedAt: data.rejectedAt.present
          ? data.rejectedAt.value
          : this.rejectedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncRejectionRow(')
          ..write('batchId: $batchId, ')
          ..write('kind: $kind, ')
          ..write('code: $code, ')
          ..write('detail: $detail, ')
          ..write('causedBy: $causedBy, ')
          ..write('operations: $operations, ')
          ..write('createdIds: $createdIds, ')
          ..write('labels: $labels, ')
          ..write('rejectedAt: $rejectedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    batchId,
    kind,
    code,
    detail,
    causedBy,
    operations,
    createdIds,
    labels,
    rejectedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncRejectionRow &&
          other.batchId == this.batchId &&
          other.kind == this.kind &&
          other.code == this.code &&
          other.detail == this.detail &&
          other.causedBy == this.causedBy &&
          other.operations == this.operations &&
          other.createdIds == this.createdIds &&
          other.labels == this.labels &&
          other.rejectedAt == this.rejectedAt);
}

class SyncRejectionsCompanion extends UpdateCompanion<SyncRejectionRow> {
  final Value<String> batchId;
  final Value<String> kind;
  final Value<String?> code;
  final Value<String?> detail;
  final Value<String?> causedBy;
  final Value<String> operations;
  final Value<String> createdIds;
  final Value<String> labels;
  final Value<String> rejectedAt;
  final Value<int> rowid;
  const SyncRejectionsCompanion({
    this.batchId = const Value.absent(),
    this.kind = const Value.absent(),
    this.code = const Value.absent(),
    this.detail = const Value.absent(),
    this.causedBy = const Value.absent(),
    this.operations = const Value.absent(),
    this.createdIds = const Value.absent(),
    this.labels = const Value.absent(),
    this.rejectedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncRejectionsCompanion.insert({
    required String batchId,
    required String kind,
    this.code = const Value.absent(),
    this.detail = const Value.absent(),
    this.causedBy = const Value.absent(),
    required String operations,
    required String createdIds,
    required String labels,
    required String rejectedAt,
    this.rowid = const Value.absent(),
  }) : batchId = Value(batchId),
       kind = Value(kind),
       operations = Value(operations),
       createdIds = Value(createdIds),
       labels = Value(labels),
       rejectedAt = Value(rejectedAt);
  static Insertable<SyncRejectionRow> custom({
    Expression<String>? batchId,
    Expression<String>? kind,
    Expression<String>? code,
    Expression<String>? detail,
    Expression<String>? causedBy,
    Expression<String>? operations,
    Expression<String>? createdIds,
    Expression<String>? labels,
    Expression<String>? rejectedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (batchId != null) 'batch_id': batchId,
      if (kind != null) 'kind': kind,
      if (code != null) 'code': code,
      if (detail != null) 'detail': detail,
      if (causedBy != null) 'caused_by': causedBy,
      if (operations != null) 'operations': operations,
      if (createdIds != null) 'created_ids': createdIds,
      if (labels != null) 'labels': labels,
      if (rejectedAt != null) 'rejected_at': rejectedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncRejectionsCompanion copyWith({
    Value<String>? batchId,
    Value<String>? kind,
    Value<String?>? code,
    Value<String?>? detail,
    Value<String?>? causedBy,
    Value<String>? operations,
    Value<String>? createdIds,
    Value<String>? labels,
    Value<String>? rejectedAt,
    Value<int>? rowid,
  }) {
    return SyncRejectionsCompanion(
      batchId: batchId ?? this.batchId,
      kind: kind ?? this.kind,
      code: code ?? this.code,
      detail: detail ?? this.detail,
      causedBy: causedBy ?? this.causedBy,
      operations: operations ?? this.operations,
      createdIds: createdIds ?? this.createdIds,
      labels: labels ?? this.labels,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (causedBy.present) {
      map['caused_by'] = Variable<String>(causedBy.value);
    }
    if (operations.present) {
      map['operations'] = Variable<String>(operations.value);
    }
    if (createdIds.present) {
      map['created_ids'] = Variable<String>(createdIds.value);
    }
    if (labels.present) {
      map['labels'] = Variable<String>(labels.value);
    }
    if (rejectedAt.present) {
      map['rejected_at'] = Variable<String>(rejectedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncRejectionsCompanion(')
          ..write('batchId: $batchId, ')
          ..write('kind: $kind, ')
          ..write('code: $code, ')
          ..write('detail: $detail, ')
          ..write('causedBy: $causedBy, ')
          ..write('operations: $operations, ')
          ..write('createdIds: $createdIds, ')
          ..write('labels: $labels, ')
          ..write('rejectedAt: $rejectedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SyncedDatabase extends GeneratedDatabase {
  _$SyncedDatabase(QueryExecutor e) : super(e);
  $SyncedDatabaseManager get managers => $SyncedDatabaseManager(this);
  late final $SyncedCustomAccountTypesTable syncedCustomAccountTypes =
      $SyncedCustomAccountTypesTable(this);
  late final $SyncedAccountsTable syncedAccounts = $SyncedAccountsTable(this);
  late final $SyncedCategoriesTable syncedCategories = $SyncedCategoriesTable(
    this,
  );
  late final $SyncedTransactionsTable syncedTransactions =
      $SyncedTransactionsTable(this);
  late final $SyncedMonthlyPlansTable syncedMonthlyPlans =
      $SyncedMonthlyPlansTable(this);
  late final $SyncRejectionsTable syncRejections = $SyncRejectionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    syncedCustomAccountTypes,
    syncedAccounts,
    syncedCategories,
    syncedTransactions,
    syncedMonthlyPlans,
    syncRejections,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$SyncedCustomAccountTypesTableCreateCompanionBuilder =
    SyncedCustomAccountTypesCompanion Function({
      required String id,
      required String name,
      required String baseType,
      required String createdAt,
      required String updatedAt,
      required int revision,
      Value<int> rowid,
    });
typedef $$SyncedCustomAccountTypesTableUpdateCompanionBuilder =
    SyncedCustomAccountTypesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> baseType,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> revision,
      Value<int> rowid,
    });

class $$SyncedCustomAccountTypesTableFilterComposer
    extends Composer<_$SyncedDatabase, $SyncedCustomAccountTypesTable> {
  $$SyncedCustomAccountTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseType => $composableBuilder(
    column: $table.baseType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncedCustomAccountTypesTableOrderingComposer
    extends Composer<_$SyncedDatabase, $SyncedCustomAccountTypesTable> {
  $$SyncedCustomAccountTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
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

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncedCustomAccountTypesTableAnnotationComposer
    extends Composer<_$SyncedDatabase, $SyncedCustomAccountTypesTable> {
  $$SyncedCustomAccountTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get baseType =>
      $composableBuilder(column: $table.baseType, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);
}

class $$SyncedCustomAccountTypesTableTableManager
    extends
        RootTableManager<
          _$SyncedDatabase,
          $SyncedCustomAccountTypesTable,
          SyncedCustomAccountTypeRow,
          $$SyncedCustomAccountTypesTableFilterComposer,
          $$SyncedCustomAccountTypesTableOrderingComposer,
          $$SyncedCustomAccountTypesTableAnnotationComposer,
          $$SyncedCustomAccountTypesTableCreateCompanionBuilder,
          $$SyncedCustomAccountTypesTableUpdateCompanionBuilder,
          (
            SyncedCustomAccountTypeRow,
            BaseReferences<
              _$SyncedDatabase,
              $SyncedCustomAccountTypesTable,
              SyncedCustomAccountTypeRow
            >,
          ),
          SyncedCustomAccountTypeRow,
          PrefetchHooks Function()
        > {
  $$SyncedCustomAccountTypesTableTableManager(
    _$SyncedDatabase db,
    $SyncedCustomAccountTypesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncedCustomAccountTypesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SyncedCustomAccountTypesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SyncedCustomAccountTypesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> baseType = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncedCustomAccountTypesCompanion(
                id: id,
                name: name,
                baseType: baseType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String baseType,
                required String createdAt,
                required String updatedAt,
                required int revision,
                Value<int> rowid = const Value.absent(),
              }) => SyncedCustomAccountTypesCompanion.insert(
                id: id,
                name: name,
                baseType: baseType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $SyncedCustomAccountTypesTable,
                    SyncedCustomAccountTypeRow
                  >(table),
                  BaseReferences<
                    _$SyncedDatabase,
                    $SyncedCustomAccountTypesTable,
                    SyncedCustomAccountTypeRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncedCustomAccountTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncedDatabase,
      $SyncedCustomAccountTypesTable,
      SyncedCustomAccountTypeRow,
      $$SyncedCustomAccountTypesTableFilterComposer,
      $$SyncedCustomAccountTypesTableOrderingComposer,
      $$SyncedCustomAccountTypesTableAnnotationComposer,
      $$SyncedCustomAccountTypesTableCreateCompanionBuilder,
      $$SyncedCustomAccountTypesTableUpdateCompanionBuilder,
      (
        SyncedCustomAccountTypeRow,
        BaseReferences<
          _$SyncedDatabase,
          $SyncedCustomAccountTypesTable,
          SyncedCustomAccountTypeRow
        >,
      ),
      SyncedCustomAccountTypeRow,
      PrefetchHooks Function()
    >;
typedef $$SyncedAccountsTableCreateCompanionBuilder =
    SyncedAccountsCompanion Function({
      required String id,
      required String name,
      required String type,
      required int openingBalanceMinor,
      required String currencyCode,
      required bool isArchived,
      Value<String?> customTypeId,
      required bool isBudgetAccount,
      required String createdAt,
      required String updatedAt,
      required int revision,
      Value<int> rowid,
    });
typedef $$SyncedAccountsTableUpdateCompanionBuilder =
    SyncedAccountsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> type,
      Value<int> openingBalanceMinor,
      Value<String> currencyCode,
      Value<bool> isArchived,
      Value<String?> customTypeId,
      Value<bool> isBudgetAccount,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> revision,
      Value<int> rowid,
    });

class $$SyncedAccountsTableFilterComposer
    extends Composer<_$SyncedDatabase, $SyncedAccountsTable> {
  $$SyncedAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customTypeId => $composableBuilder(
    column: $table.customTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBudgetAccount => $composableBuilder(
    column: $table.isBudgetAccount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncedAccountsTableOrderingComposer
    extends Composer<_$SyncedDatabase, $SyncedAccountsTable> {
  $$SyncedAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
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

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customTypeId => $composableBuilder(
    column: $table.customTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBudgetAccount => $composableBuilder(
    column: $table.isBudgetAccount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncedAccountsTableAnnotationComposer
    extends Composer<_$SyncedDatabase, $SyncedAccountsTable> {
  $$SyncedAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customTypeId => $composableBuilder(
    column: $table.customTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBudgetAccount => $composableBuilder(
    column: $table.isBudgetAccount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);
}

class $$SyncedAccountsTableTableManager
    extends
        RootTableManager<
          _$SyncedDatabase,
          $SyncedAccountsTable,
          SyncedAccountRow,
          $$SyncedAccountsTableFilterComposer,
          $$SyncedAccountsTableOrderingComposer,
          $$SyncedAccountsTableAnnotationComposer,
          $$SyncedAccountsTableCreateCompanionBuilder,
          $$SyncedAccountsTableUpdateCompanionBuilder,
          (
            SyncedAccountRow,
            BaseReferences<
              _$SyncedDatabase,
              $SyncedAccountsTable,
              SyncedAccountRow
            >,
          ),
          SyncedAccountRow,
          PrefetchHooks Function()
        > {
  $$SyncedAccountsTableTableManager(
    _$SyncedDatabase db,
    $SyncedAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncedAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncedAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncedAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> openingBalanceMinor = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String?> customTypeId = const Value.absent(),
                Value<bool> isBudgetAccount = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncedAccountsCompanion(
                id: id,
                name: name,
                type: type,
                openingBalanceMinor: openingBalanceMinor,
                currencyCode: currencyCode,
                isArchived: isArchived,
                customTypeId: customTypeId,
                isBudgetAccount: isBudgetAccount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String type,
                required int openingBalanceMinor,
                required String currencyCode,
                required bool isArchived,
                Value<String?> customTypeId = const Value.absent(),
                required bool isBudgetAccount,
                required String createdAt,
                required String updatedAt,
                required int revision,
                Value<int> rowid = const Value.absent(),
              }) => SyncedAccountsCompanion.insert(
                id: id,
                name: name,
                type: type,
                openingBalanceMinor: openingBalanceMinor,
                currencyCode: currencyCode,
                isArchived: isArchived,
                customTypeId: customTypeId,
                isBudgetAccount: isBudgetAccount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncedAccountsTable, SyncedAccountRow>(table),
                  BaseReferences<
                    _$SyncedDatabase,
                    $SyncedAccountsTable,
                    SyncedAccountRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncedAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncedDatabase,
      $SyncedAccountsTable,
      SyncedAccountRow,
      $$SyncedAccountsTableFilterComposer,
      $$SyncedAccountsTableOrderingComposer,
      $$SyncedAccountsTableAnnotationComposer,
      $$SyncedAccountsTableCreateCompanionBuilder,
      $$SyncedAccountsTableUpdateCompanionBuilder,
      (
        SyncedAccountRow,
        BaseReferences<
          _$SyncedDatabase,
          $SyncedAccountsTable,
          SyncedAccountRow
        >,
      ),
      SyncedAccountRow,
      PrefetchHooks Function()
    >;
typedef $$SyncedCategoriesTableCreateCompanionBuilder =
    SyncedCategoriesCompanion Function({
      required String id,
      required String name,
      required String kind,
      required bool isArchived,
      required bool isPlanArchived,
      required bool isPlanDeleted,
      required String planGroup,
      Value<String?> linkedAccountId,
      required String createdAt,
      required String updatedAt,
      required int revision,
      Value<int> rowid,
    });
typedef $$SyncedCategoriesTableUpdateCompanionBuilder =
    SyncedCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> kind,
      Value<bool> isArchived,
      Value<bool> isPlanArchived,
      Value<bool> isPlanDeleted,
      Value<String> planGroup,
      Value<String?> linkedAccountId,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> revision,
      Value<int> rowid,
    });

class $$SyncedCategoriesTableFilterComposer
    extends Composer<_$SyncedDatabase, $SyncedCategoriesTable> {
  $$SyncedCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
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

  ColumnFilters<String> get planGroup => $composableBuilder(
    column: $table.planGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedAccountId => $composableBuilder(
    column: $table.linkedAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncedCategoriesTableOrderingComposer
    extends Composer<_$SyncedDatabase, $SyncedCategoriesTable> {
  $$SyncedCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
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

  ColumnOrderings<String> get linkedAccountId => $composableBuilder(
    column: $table.linkedAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncedCategoriesTableAnnotationComposer
    extends Composer<_$SyncedDatabase, $SyncedCategoriesTable> {
  $$SyncedCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
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

  GeneratedColumn<String> get planGroup =>
      $composableBuilder(column: $table.planGroup, builder: (column) => column);

  GeneratedColumn<String> get linkedAccountId => $composableBuilder(
    column: $table.linkedAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);
}

class $$SyncedCategoriesTableTableManager
    extends
        RootTableManager<
          _$SyncedDatabase,
          $SyncedCategoriesTable,
          SyncedCategoryRow,
          $$SyncedCategoriesTableFilterComposer,
          $$SyncedCategoriesTableOrderingComposer,
          $$SyncedCategoriesTableAnnotationComposer,
          $$SyncedCategoriesTableCreateCompanionBuilder,
          $$SyncedCategoriesTableUpdateCompanionBuilder,
          (
            SyncedCategoryRow,
            BaseReferences<
              _$SyncedDatabase,
              $SyncedCategoriesTable,
              SyncedCategoryRow
            >,
          ),
          SyncedCategoryRow,
          PrefetchHooks Function()
        > {
  $$SyncedCategoriesTableTableManager(
    _$SyncedDatabase db,
    $SyncedCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncedCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncedCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncedCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isPlanArchived = const Value.absent(),
                Value<bool> isPlanDeleted = const Value.absent(),
                Value<String> planGroup = const Value.absent(),
                Value<String?> linkedAccountId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncedCategoriesCompanion(
                id: id,
                name: name,
                kind: kind,
                isArchived: isArchived,
                isPlanArchived: isPlanArchived,
                isPlanDeleted: isPlanDeleted,
                planGroup: planGroup,
                linkedAccountId: linkedAccountId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String kind,
                required bool isArchived,
                required bool isPlanArchived,
                required bool isPlanDeleted,
                required String planGroup,
                Value<String?> linkedAccountId = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                required int revision,
                Value<int> rowid = const Value.absent(),
              }) => SyncedCategoriesCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                isArchived: isArchived,
                isPlanArchived: isPlanArchived,
                isPlanDeleted: isPlanDeleted,
                planGroup: planGroup,
                linkedAccountId: linkedAccountId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncedCategoriesTable, SyncedCategoryRow>(table),
                  BaseReferences<
                    _$SyncedDatabase,
                    $SyncedCategoriesTable,
                    SyncedCategoryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncedCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncedDatabase,
      $SyncedCategoriesTable,
      SyncedCategoryRow,
      $$SyncedCategoriesTableFilterComposer,
      $$SyncedCategoriesTableOrderingComposer,
      $$SyncedCategoriesTableAnnotationComposer,
      $$SyncedCategoriesTableCreateCompanionBuilder,
      $$SyncedCategoriesTableUpdateCompanionBuilder,
      (
        SyncedCategoryRow,
        BaseReferences<
          _$SyncedDatabase,
          $SyncedCategoriesTable,
          SyncedCategoryRow
        >,
      ),
      SyncedCategoryRow,
      PrefetchHooks Function()
    >;
typedef $$SyncedTransactionsTableCreateCompanionBuilder =
    SyncedTransactionsCompanion Function({
      required String id,
      required String type,
      required int amountMinor,
      required String currencyCode,
      required String date,
      required String payee,
      Value<String?> categoryId,
      Value<String?> sourceAccountId,
      Value<String?> destinationAccountId,
      required String note,
      required String createdAt,
      required String updatedAt,
      required int revision,
      Value<int> rowid,
    });
typedef $$SyncedTransactionsTableUpdateCompanionBuilder =
    SyncedTransactionsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<int> amountMinor,
      Value<String> currencyCode,
      Value<String> date,
      Value<String> payee,
      Value<String?> categoryId,
      Value<String?> sourceAccountId,
      Value<String?> destinationAccountId,
      Value<String> note,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> revision,
      Value<int> rowid,
    });

class $$SyncedTransactionsTableFilterComposer
    extends Composer<_$SyncedDatabase, $SyncedTransactionsTable> {
  $$SyncedTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payee => $composableBuilder(
    column: $table.payee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceAccountId => $composableBuilder(
    column: $table.sourceAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationAccountId => $composableBuilder(
    column: $table.destinationAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncedTransactionsTableOrderingComposer
    extends Composer<_$SyncedDatabase, $SyncedTransactionsTable> {
  $$SyncedTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
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

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceAccountId => $composableBuilder(
    column: $table.sourceAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationAccountId => $composableBuilder(
    column: $table.destinationAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncedTransactionsTableAnnotationComposer
    extends Composer<_$SyncedDatabase, $SyncedTransactionsTable> {
  $$SyncedTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get payee =>
      $composableBuilder(column: $table.payee, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceAccountId => $composableBuilder(
    column: $table.sourceAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationAccountId => $composableBuilder(
    column: $table.destinationAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);
}

class $$SyncedTransactionsTableTableManager
    extends
        RootTableManager<
          _$SyncedDatabase,
          $SyncedTransactionsTable,
          SyncedTransactionRow,
          $$SyncedTransactionsTableFilterComposer,
          $$SyncedTransactionsTableOrderingComposer,
          $$SyncedTransactionsTableAnnotationComposer,
          $$SyncedTransactionsTableCreateCompanionBuilder,
          $$SyncedTransactionsTableUpdateCompanionBuilder,
          (
            SyncedTransactionRow,
            BaseReferences<
              _$SyncedDatabase,
              $SyncedTransactionsTable,
              SyncedTransactionRow
            >,
          ),
          SyncedTransactionRow,
          PrefetchHooks Function()
        > {
  $$SyncedTransactionsTableTableManager(
    _$SyncedDatabase db,
    $SyncedTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncedTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncedTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncedTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> payee = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> sourceAccountId = const Value.absent(),
                Value<String?> destinationAccountId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncedTransactionsCompanion(
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
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required int amountMinor,
                required String currencyCode,
                required String date,
                required String payee,
                Value<String?> categoryId = const Value.absent(),
                Value<String?> sourceAccountId = const Value.absent(),
                Value<String?> destinationAccountId = const Value.absent(),
                required String note,
                required String createdAt,
                required String updatedAt,
                required int revision,
                Value<int> rowid = const Value.absent(),
              }) => SyncedTransactionsCompanion.insert(
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
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncedTransactionsTable, SyncedTransactionRow>(
                    table,
                  ),
                  BaseReferences<
                    _$SyncedDatabase,
                    $SyncedTransactionsTable,
                    SyncedTransactionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncedTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncedDatabase,
      $SyncedTransactionsTable,
      SyncedTransactionRow,
      $$SyncedTransactionsTableFilterComposer,
      $$SyncedTransactionsTableOrderingComposer,
      $$SyncedTransactionsTableAnnotationComposer,
      $$SyncedTransactionsTableCreateCompanionBuilder,
      $$SyncedTransactionsTableUpdateCompanionBuilder,
      (
        SyncedTransactionRow,
        BaseReferences<
          _$SyncedDatabase,
          $SyncedTransactionsTable,
          SyncedTransactionRow
        >,
      ),
      SyncedTransactionRow,
      PrefetchHooks Function()
    >;
typedef $$SyncedMonthlyPlansTableCreateCompanionBuilder =
    SyncedMonthlyPlansCompanion Function({
      required String id,
      required String month,
      required String categoryId,
      Value<int?> targetAmountMinor,
      required int assignedAmountMinor,
      required String currencyCode,
      required String createdAt,
      required String updatedAt,
      required int revision,
      Value<int> rowid,
    });
typedef $$SyncedMonthlyPlansTableUpdateCompanionBuilder =
    SyncedMonthlyPlansCompanion Function({
      Value<String> id,
      Value<String> month,
      Value<String> categoryId,
      Value<int?> targetAmountMinor,
      Value<int> assignedAmountMinor,
      Value<String> currencyCode,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> revision,
      Value<int> rowid,
    });

class $$SyncedMonthlyPlansTableFilterComposer
    extends Composer<_$SyncedDatabase, $SyncedMonthlyPlansTable> {
  $$SyncedMonthlyPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
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

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncedMonthlyPlansTableOrderingComposer
    extends Composer<_$SyncedDatabase, $SyncedMonthlyPlansTable> {
  $$SyncedMonthlyPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
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

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncedMonthlyPlansTableAnnotationComposer
    extends Composer<_$SyncedDatabase, $SyncedMonthlyPlansTable> {
  $$SyncedMonthlyPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

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

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);
}

class $$SyncedMonthlyPlansTableTableManager
    extends
        RootTableManager<
          _$SyncedDatabase,
          $SyncedMonthlyPlansTable,
          SyncedMonthlyPlanRow,
          $$SyncedMonthlyPlansTableFilterComposer,
          $$SyncedMonthlyPlansTableOrderingComposer,
          $$SyncedMonthlyPlansTableAnnotationComposer,
          $$SyncedMonthlyPlansTableCreateCompanionBuilder,
          $$SyncedMonthlyPlansTableUpdateCompanionBuilder,
          (
            SyncedMonthlyPlanRow,
            BaseReferences<
              _$SyncedDatabase,
              $SyncedMonthlyPlansTable,
              SyncedMonthlyPlanRow
            >,
          ),
          SyncedMonthlyPlanRow,
          PrefetchHooks Function()
        > {
  $$SyncedMonthlyPlansTableTableManager(
    _$SyncedDatabase db,
    $SyncedMonthlyPlansTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncedMonthlyPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncedMonthlyPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncedMonthlyPlansTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> month = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int?> targetAmountMinor = const Value.absent(),
                Value<int> assignedAmountMinor = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncedMonthlyPlansCompanion(
                id: id,
                month: month,
                categoryId: categoryId,
                targetAmountMinor: targetAmountMinor,
                assignedAmountMinor: assignedAmountMinor,
                currencyCode: currencyCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String month,
                required String categoryId,
                Value<int?> targetAmountMinor = const Value.absent(),
                required int assignedAmountMinor,
                required String currencyCode,
                required String createdAt,
                required String updatedAt,
                required int revision,
                Value<int> rowid = const Value.absent(),
              }) => SyncedMonthlyPlansCompanion.insert(
                id: id,
                month: month,
                categoryId: categoryId,
                targetAmountMinor: targetAmountMinor,
                assignedAmountMinor: assignedAmountMinor,
                currencyCode: currencyCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncedMonthlyPlansTable, SyncedMonthlyPlanRow>(
                    table,
                  ),
                  BaseReferences<
                    _$SyncedDatabase,
                    $SyncedMonthlyPlansTable,
                    SyncedMonthlyPlanRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncedMonthlyPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncedDatabase,
      $SyncedMonthlyPlansTable,
      SyncedMonthlyPlanRow,
      $$SyncedMonthlyPlansTableFilterComposer,
      $$SyncedMonthlyPlansTableOrderingComposer,
      $$SyncedMonthlyPlansTableAnnotationComposer,
      $$SyncedMonthlyPlansTableCreateCompanionBuilder,
      $$SyncedMonthlyPlansTableUpdateCompanionBuilder,
      (
        SyncedMonthlyPlanRow,
        BaseReferences<
          _$SyncedDatabase,
          $SyncedMonthlyPlansTable,
          SyncedMonthlyPlanRow
        >,
      ),
      SyncedMonthlyPlanRow,
      PrefetchHooks Function()
    >;
typedef $$SyncRejectionsTableCreateCompanionBuilder =
    SyncRejectionsCompanion Function({
      required String batchId,
      required String kind,
      Value<String?> code,
      Value<String?> detail,
      Value<String?> causedBy,
      required String operations,
      required String createdIds,
      required String labels,
      required String rejectedAt,
      Value<int> rowid,
    });
typedef $$SyncRejectionsTableUpdateCompanionBuilder =
    SyncRejectionsCompanion Function({
      Value<String> batchId,
      Value<String> kind,
      Value<String?> code,
      Value<String?> detail,
      Value<String?> causedBy,
      Value<String> operations,
      Value<String> createdIds,
      Value<String> labels,
      Value<String> rejectedAt,
      Value<int> rowid,
    });

class $$SyncRejectionsTableFilterComposer
    extends Composer<_$SyncedDatabase, $SyncRejectionsTable> {
  $$SyncRejectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get causedBy => $composableBuilder(
    column: $table.causedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operations => $composableBuilder(
    column: $table.operations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdIds => $composableBuilder(
    column: $table.createdIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labels => $composableBuilder(
    column: $table.labels,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rejectedAt => $composableBuilder(
    column: $table.rejectedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncRejectionsTableOrderingComposer
    extends Composer<_$SyncedDatabase, $SyncRejectionsTable> {
  $$SyncRejectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get causedBy => $composableBuilder(
    column: $table.causedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operations => $composableBuilder(
    column: $table.operations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdIds => $composableBuilder(
    column: $table.createdIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labels => $composableBuilder(
    column: $table.labels,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rejectedAt => $composableBuilder(
    column: $table.rejectedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncRejectionsTableAnnotationComposer
    extends Composer<_$SyncedDatabase, $SyncRejectionsTable> {
  $$SyncRejectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);

  GeneratedColumn<String> get causedBy =>
      $composableBuilder(column: $table.causedBy, builder: (column) => column);

  GeneratedColumn<String> get operations => $composableBuilder(
    column: $table.operations,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdIds => $composableBuilder(
    column: $table.createdIds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get labels =>
      $composableBuilder(column: $table.labels, builder: (column) => column);

  GeneratedColumn<String> get rejectedAt => $composableBuilder(
    column: $table.rejectedAt,
    builder: (column) => column,
  );
}

class $$SyncRejectionsTableTableManager
    extends
        RootTableManager<
          _$SyncedDatabase,
          $SyncRejectionsTable,
          SyncRejectionRow,
          $$SyncRejectionsTableFilterComposer,
          $$SyncRejectionsTableOrderingComposer,
          $$SyncRejectionsTableAnnotationComposer,
          $$SyncRejectionsTableCreateCompanionBuilder,
          $$SyncRejectionsTableUpdateCompanionBuilder,
          (
            SyncRejectionRow,
            BaseReferences<
              _$SyncedDatabase,
              $SyncRejectionsTable,
              SyncRejectionRow
            >,
          ),
          SyncRejectionRow,
          PrefetchHooks Function()
        > {
  $$SyncRejectionsTableTableManager(
    _$SyncedDatabase db,
    $SyncRejectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncRejectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncRejectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncRejectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> batchId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<String?> detail = const Value.absent(),
                Value<String?> causedBy = const Value.absent(),
                Value<String> operations = const Value.absent(),
                Value<String> createdIds = const Value.absent(),
                Value<String> labels = const Value.absent(),
                Value<String> rejectedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncRejectionsCompanion(
                batchId: batchId,
                kind: kind,
                code: code,
                detail: detail,
                causedBy: causedBy,
                operations: operations,
                createdIds: createdIds,
                labels: labels,
                rejectedAt: rejectedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String batchId,
                required String kind,
                Value<String?> code = const Value.absent(),
                Value<String?> detail = const Value.absent(),
                Value<String?> causedBy = const Value.absent(),
                required String operations,
                required String createdIds,
                required String labels,
                required String rejectedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncRejectionsCompanion.insert(
                batchId: batchId,
                kind: kind,
                code: code,
                detail: detail,
                causedBy: causedBy,
                operations: operations,
                createdIds: createdIds,
                labels: labels,
                rejectedAt: rejectedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncRejectionsTable, SyncRejectionRow>(table),
                  BaseReferences<
                    _$SyncedDatabase,
                    $SyncRejectionsTable,
                    SyncRejectionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncRejectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncedDatabase,
      $SyncRejectionsTable,
      SyncRejectionRow,
      $$SyncRejectionsTableFilterComposer,
      $$SyncRejectionsTableOrderingComposer,
      $$SyncRejectionsTableAnnotationComposer,
      $$SyncRejectionsTableCreateCompanionBuilder,
      $$SyncRejectionsTableUpdateCompanionBuilder,
      (
        SyncRejectionRow,
        BaseReferences<
          _$SyncedDatabase,
          $SyncRejectionsTable,
          SyncRejectionRow
        >,
      ),
      SyncRejectionRow,
      PrefetchHooks Function()
    >;

class $SyncedDatabaseManager {
  final _$SyncedDatabase _db;
  $SyncedDatabaseManager(this._db);
  $$SyncedCustomAccountTypesTableTableManager get syncedCustomAccountTypes =>
      $$SyncedCustomAccountTypesTableTableManager(
        _db,
        _db.syncedCustomAccountTypes,
      );
  $$SyncedAccountsTableTableManager get syncedAccounts =>
      $$SyncedAccountsTableTableManager(_db, _db.syncedAccounts);
  $$SyncedCategoriesTableTableManager get syncedCategories =>
      $$SyncedCategoriesTableTableManager(_db, _db.syncedCategories);
  $$SyncedTransactionsTableTableManager get syncedTransactions =>
      $$SyncedTransactionsTableTableManager(_db, _db.syncedTransactions);
  $$SyncedMonthlyPlansTableTableManager get syncedMonthlyPlans =>
      $$SyncedMonthlyPlansTableTableManager(_db, _db.syncedMonthlyPlans);
  $$SyncRejectionsTableTableManager get syncRejections =>
      $$SyncRejectionsTableTableManager(_db, _db.syncRejections);
}
