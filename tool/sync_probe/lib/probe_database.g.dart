// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'probe_database.dart';

// ignore_for_file: type=lint
class $ProbeParentsTable extends ProbeParents
    with TableInfo<$ProbeParentsTable, ProbeParent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProbeParentsTable(this.attachedDatabase, [this._alias]);
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
  List<GeneratedColumn> get $columns => [id, name, revision];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'probe_parents';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProbeParent> instance, {
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
  ProbeParent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProbeParent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  $ProbeParentsTable createAlias(String alias) {
    return $ProbeParentsTable(attachedDatabase, alias);
  }
}

class ProbeParent extends DataClass implements Insertable<ProbeParent> {
  final String id;
  final String name;
  final int revision;
  const ProbeParent({
    required this.id,
    required this.name,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['revision'] = Variable<int>(revision);
    return map;
  }

  ProbeParentsCompanion toCompanion(bool nullToAbsent) {
    return ProbeParentsCompanion(
      id: Value(id),
      name: Value(name),
      revision: Value(revision),
    );
  }

  factory ProbeParent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProbeParent(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'revision': serializer.toJson<int>(revision),
    };
  }

  ProbeParent copyWith({String? id, String? name, int? revision}) =>
      ProbeParent(
        id: id ?? this.id,
        name: name ?? this.name,
        revision: revision ?? this.revision,
      );
  ProbeParent copyWithCompanion(ProbeParentsCompanion data) {
    return ProbeParent(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProbeParent(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, revision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProbeParent &&
          other.id == this.id &&
          other.name == this.name &&
          other.revision == this.revision);
}

class ProbeParentsCompanion extends UpdateCompanion<ProbeParent> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> revision;
  final Value<int> rowid;
  const ProbeParentsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.revision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProbeParentsCompanion.insert({
    required String id,
    required String name,
    required int revision,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       revision = Value(revision);
  static Insertable<ProbeParent> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? revision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (revision != null) 'revision': revision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProbeParentsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? revision,
    Value<int>? rowid,
  }) {
    return ProbeParentsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
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
    return (StringBuffer('ProbeParentsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('revision: $revision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProbeEntriesTable extends ProbeEntries
    with TableInfo<$ProbeEntriesTable, ProbeEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProbeEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
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
  @override
  List<GeneratedColumn> get $columns => [id, parentId, amountMinor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'probe_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProbeEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_parentIdMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProbeEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProbeEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
    );
  }

  @override
  $ProbeEntriesTable createAlias(String alias) {
    return $ProbeEntriesTable(attachedDatabase, alias);
  }
}

class ProbeEntry extends DataClass implements Insertable<ProbeEntry> {
  final String id;
  final String parentId;
  final int amountMinor;
  const ProbeEntry({
    required this.id,
    required this.parentId,
    required this.amountMinor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['parent_id'] = Variable<String>(parentId);
    map['amount_minor'] = Variable<int>(amountMinor);
    return map;
  }

  ProbeEntriesCompanion toCompanion(bool nullToAbsent) {
    return ProbeEntriesCompanion(
      id: Value(id),
      parentId: Value(parentId),
      amountMinor: Value(amountMinor),
    );
  }

  factory ProbeEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProbeEntry(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String>(json['parentId']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String>(parentId),
      'amountMinor': serializer.toJson<int>(amountMinor),
    };
  }

  ProbeEntry copyWith({String? id, String? parentId, int? amountMinor}) =>
      ProbeEntry(
        id: id ?? this.id,
        parentId: parentId ?? this.parentId,
        amountMinor: amountMinor ?? this.amountMinor,
      );
  ProbeEntry copyWithCompanion(ProbeEntriesCompanion data) {
    return ProbeEntry(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProbeEntry(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('amountMinor: $amountMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, parentId, amountMinor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProbeEntry &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.amountMinor == this.amountMinor);
}

class ProbeEntriesCompanion extends UpdateCompanion<ProbeEntry> {
  final Value<String> id;
  final Value<String> parentId;
  final Value<int> amountMinor;
  final Value<int> rowid;
  const ProbeEntriesCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProbeEntriesCompanion.insert({
    required String id,
    required String parentId,
    required int amountMinor,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       parentId = Value(parentId),
       amountMinor = Value(amountMinor);
  static Insertable<ProbeEntry> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<int>? amountMinor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProbeEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? parentId,
    Value<int>? amountMinor,
    Value<int>? rowid,
  }) {
    return ProbeEntriesCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      amountMinor: amountMinor ?? this.amountMinor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProbeEntriesCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ProbeDatabase extends GeneratedDatabase {
  _$ProbeDatabase(QueryExecutor e) : super(e);
  $ProbeDatabaseManager get managers => $ProbeDatabaseManager(this);
  late final $ProbeParentsTable probeParents = $ProbeParentsTable(this);
  late final $ProbeEntriesTable probeEntries = $ProbeEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    probeParents,
    probeEntries,
  ];
}

typedef $$ProbeParentsTableCreateCompanionBuilder =
    ProbeParentsCompanion Function({
      required String id,
      required String name,
      required int revision,
      Value<int> rowid,
    });
typedef $$ProbeParentsTableUpdateCompanionBuilder =
    ProbeParentsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> revision,
      Value<int> rowid,
    });

class $$ProbeParentsTableFilterComposer
    extends Composer<_$ProbeDatabase, $ProbeParentsTable> {
  $$ProbeParentsTableFilterComposer({
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

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProbeParentsTableOrderingComposer
    extends Composer<_$ProbeDatabase, $ProbeParentsTable> {
  $$ProbeParentsTableOrderingComposer({
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

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProbeParentsTableAnnotationComposer
    extends Composer<_$ProbeDatabase, $ProbeParentsTable> {
  $$ProbeParentsTableAnnotationComposer({
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

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);
}

class $$ProbeParentsTableTableManager
    extends
        RootTableManager<
          _$ProbeDatabase,
          $ProbeParentsTable,
          ProbeParent,
          $$ProbeParentsTableFilterComposer,
          $$ProbeParentsTableOrderingComposer,
          $$ProbeParentsTableAnnotationComposer,
          $$ProbeParentsTableCreateCompanionBuilder,
          $$ProbeParentsTableUpdateCompanionBuilder,
          (
            ProbeParent,
            BaseReferences<_$ProbeDatabase, $ProbeParentsTable, ProbeParent>,
          ),
          ProbeParent,
          PrefetchHooks Function()
        > {
  $$ProbeParentsTableTableManager(_$ProbeDatabase db, $ProbeParentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProbeParentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProbeParentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProbeParentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProbeParentsCompanion(
                id: id,
                name: name,
                revision: revision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int revision,
                Value<int> rowid = const Value.absent(),
              }) => ProbeParentsCompanion.insert(
                id: id,
                name: name,
                revision: revision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProbeParentsTable, ProbeParent>(table),
                  BaseReferences<
                    _$ProbeDatabase,
                    $ProbeParentsTable,
                    ProbeParent
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProbeParentsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProbeDatabase,
      $ProbeParentsTable,
      ProbeParent,
      $$ProbeParentsTableFilterComposer,
      $$ProbeParentsTableOrderingComposer,
      $$ProbeParentsTableAnnotationComposer,
      $$ProbeParentsTableCreateCompanionBuilder,
      $$ProbeParentsTableUpdateCompanionBuilder,
      (
        ProbeParent,
        BaseReferences<_$ProbeDatabase, $ProbeParentsTable, ProbeParent>,
      ),
      ProbeParent,
      PrefetchHooks Function()
    >;
typedef $$ProbeEntriesTableCreateCompanionBuilder =
    ProbeEntriesCompanion Function({
      required String id,
      required String parentId,
      required int amountMinor,
      Value<int> rowid,
    });
typedef $$ProbeEntriesTableUpdateCompanionBuilder =
    ProbeEntriesCompanion Function({
      Value<String> id,
      Value<String> parentId,
      Value<int> amountMinor,
      Value<int> rowid,
    });

class $$ProbeEntriesTableFilterComposer
    extends Composer<_$ProbeDatabase, $ProbeEntriesTable> {
  $$ProbeEntriesTableFilterComposer({
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

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProbeEntriesTableOrderingComposer
    extends Composer<_$ProbeDatabase, $ProbeEntriesTable> {
  $$ProbeEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProbeEntriesTableAnnotationComposer
    extends Composer<_$ProbeDatabase, $ProbeEntriesTable> {
  $$ProbeEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );
}

class $$ProbeEntriesTableTableManager
    extends
        RootTableManager<
          _$ProbeDatabase,
          $ProbeEntriesTable,
          ProbeEntry,
          $$ProbeEntriesTableFilterComposer,
          $$ProbeEntriesTableOrderingComposer,
          $$ProbeEntriesTableAnnotationComposer,
          $$ProbeEntriesTableCreateCompanionBuilder,
          $$ProbeEntriesTableUpdateCompanionBuilder,
          (
            ProbeEntry,
            BaseReferences<_$ProbeDatabase, $ProbeEntriesTable, ProbeEntry>,
          ),
          ProbeEntry,
          PrefetchHooks Function()
        > {
  $$ProbeEntriesTableTableManager(_$ProbeDatabase db, $ProbeEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProbeEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProbeEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProbeEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> parentId = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProbeEntriesCompanion(
                id: id,
                parentId: parentId,
                amountMinor: amountMinor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String parentId,
                required int amountMinor,
                Value<int> rowid = const Value.absent(),
              }) => ProbeEntriesCompanion.insert(
                id: id,
                parentId: parentId,
                amountMinor: amountMinor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProbeEntriesTable, ProbeEntry>(table),
                  BaseReferences<
                    _$ProbeDatabase,
                    $ProbeEntriesTable,
                    ProbeEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProbeEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProbeDatabase,
      $ProbeEntriesTable,
      ProbeEntry,
      $$ProbeEntriesTableFilterComposer,
      $$ProbeEntriesTableOrderingComposer,
      $$ProbeEntriesTableAnnotationComposer,
      $$ProbeEntriesTableCreateCompanionBuilder,
      $$ProbeEntriesTableUpdateCompanionBuilder,
      (
        ProbeEntry,
        BaseReferences<_$ProbeDatabase, $ProbeEntriesTable, ProbeEntry>,
      ),
      ProbeEntry,
      PrefetchHooks Function()
    >;

class $ProbeDatabaseManager {
  final _$ProbeDatabase _db;
  $ProbeDatabaseManager(this._db);
  $$ProbeParentsTableTableManager get probeParents =>
      $$ProbeParentsTableTableManager(_db, _db.probeParents);
  $$ProbeEntriesTableTableManager get probeEntries =>
      $$ProbeEntriesTableTableManager(_db, _db.probeEntries);
}
