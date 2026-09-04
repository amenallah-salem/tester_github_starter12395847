// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _muscleGroupMeta =
      const VerificationMeta('muscleGroup');
  @override
  late final GeneratedColumn<String> muscleGroup = GeneratedColumn<String>(
      'muscle_group', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _equipmentMeta =
      const VerificationMeta('equipment');
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
      'equipment', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('bodyweight'));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _muscleGroupsMeta =
      const VerificationMeta('muscleGroups');
  @override
  late final GeneratedColumn<String> muscleGroups = GeneratedColumn<String>(
      'muscle_groups', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _howToMeta = const VerificationMeta('howTo');
  @override
  late final GeneratedColumn<String> howTo = GeneratedColumn<String>(
      'how_to', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _coachTipMeta =
      const VerificationMeta('coachTip');
  @override
  late final GeneratedColumn<String> coachTip = GeneratedColumn<String>(
      'coach_tip', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        muscleGroup,
        equipment,
        description,
        muscleGroups,
        howTo,
        coachTip
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(Insertable<Exercise> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('muscle_group')) {
      context.handle(
          _muscleGroupMeta,
          muscleGroup.isAcceptableOrUnknown(
              data['muscle_group']!, _muscleGroupMeta));
    } else if (isInserting) {
      context.missing(_muscleGroupMeta);
    }
    if (data.containsKey('equipment')) {
      context.handle(_equipmentMeta,
          equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('muscle_groups')) {
      context.handle(
          _muscleGroupsMeta,
          muscleGroups.isAcceptableOrUnknown(
              data['muscle_groups']!, _muscleGroupsMeta));
    }
    if (data.containsKey('how_to')) {
      context.handle(
          _howToMeta, howTo.isAcceptableOrUnknown(data['how_to']!, _howToMeta));
    }
    if (data.containsKey('coach_tip')) {
      context.handle(_coachTipMeta,
          coachTip.isAcceptableOrUnknown(data['coach_tip']!, _coachTipMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      muscleGroup: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}muscle_group'])!,
      equipment: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}equipment'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      muscleGroups: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}muscle_groups'])!,
      howTo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}how_to'])!,
      coachTip: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}coach_tip'])!,
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final int id;
  final String name;

  /// Primary muscle group (used for quick grouping in lists).
  final String muscleGroup;
  final String equipment;
  final String description;

  /// Comma-joined list of all trained muscles (chips on detail screen).
  final String muscleGroups;

  /// Newline-joined how-to steps (numbered on the detail screen).
  final String howTo;

  /// Coach tip for the exercise. Tone lives in the coaching-voice doc.
  final String coachTip;
  const Exercise(
      {required this.id,
      required this.name,
      required this.muscleGroup,
      required this.equipment,
      required this.description,
      required this.muscleGroups,
      required this.howTo,
      required this.coachTip});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['muscle_group'] = Variable<String>(muscleGroup);
    map['equipment'] = Variable<String>(equipment);
    map['description'] = Variable<String>(description);
    map['muscle_groups'] = Variable<String>(muscleGroups);
    map['how_to'] = Variable<String>(howTo);
    map['coach_tip'] = Variable<String>(coachTip);
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      name: Value(name),
      muscleGroup: Value(muscleGroup),
      equipment: Value(equipment),
      description: Value(description),
      muscleGroups: Value(muscleGroups),
      howTo: Value(howTo),
      coachTip: Value(coachTip),
    );
  }

  factory Exercise.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      muscleGroup: serializer.fromJson<String>(json['muscleGroup']),
      equipment: serializer.fromJson<String>(json['equipment']),
      description: serializer.fromJson<String>(json['description']),
      muscleGroups: serializer.fromJson<String>(json['muscleGroups']),
      howTo: serializer.fromJson<String>(json['howTo']),
      coachTip: serializer.fromJson<String>(json['coachTip']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'muscleGroup': serializer.toJson<String>(muscleGroup),
      'equipment': serializer.toJson<String>(equipment),
      'description': serializer.toJson<String>(description),
      'muscleGroups': serializer.toJson<String>(muscleGroups),
      'howTo': serializer.toJson<String>(howTo),
      'coachTip': serializer.toJson<String>(coachTip),
    };
  }

  Exercise copyWith(
          {int? id,
          String? name,
          String? muscleGroup,
          String? equipment,
          String? description,
          String? muscleGroups,
          String? howTo,
          String? coachTip}) =>
      Exercise(
        id: id ?? this.id,
        name: name ?? this.name,
        muscleGroup: muscleGroup ?? this.muscleGroup,
        equipment: equipment ?? this.equipment,
        description: description ?? this.description,
        muscleGroups: muscleGroups ?? this.muscleGroups,
        howTo: howTo ?? this.howTo,
        coachTip: coachTip ?? this.coachTip,
      );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      muscleGroup:
          data.muscleGroup.present ? data.muscleGroup.value : this.muscleGroup,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      description:
          data.description.present ? data.description.value : this.description,
      muscleGroups: data.muscleGroups.present
          ? data.muscleGroups.value
          : this.muscleGroups,
      howTo: data.howTo.present ? data.howTo.value : this.howTo,
      coachTip: data.coachTip.present ? data.coachTip.value : this.coachTip,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('muscleGroup: $muscleGroup, ')
          ..write('equipment: $equipment, ')
          ..write('description: $description, ')
          ..write('muscleGroups: $muscleGroups, ')
          ..write('howTo: $howTo, ')
          ..write('coachTip: $coachTip')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, muscleGroup, equipment, description,
      muscleGroups, howTo, coachTip);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.muscleGroup == this.muscleGroup &&
          other.equipment == this.equipment &&
          other.description == this.description &&
          other.muscleGroups == this.muscleGroups &&
          other.howTo == this.howTo &&
          other.coachTip == this.coachTip);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> muscleGroup;
  final Value<String> equipment;
  final Value<String> description;
  final Value<String> muscleGroups;
  final Value<String> howTo;
  final Value<String> coachTip;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.muscleGroup = const Value.absent(),
    this.equipment = const Value.absent(),
    this.description = const Value.absent(),
    this.muscleGroups = const Value.absent(),
    this.howTo = const Value.absent(),
    this.coachTip = const Value.absent(),
  });
  ExercisesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String muscleGroup,
    this.equipment = const Value.absent(),
    this.description = const Value.absent(),
    this.muscleGroups = const Value.absent(),
    this.howTo = const Value.absent(),
    this.coachTip = const Value.absent(),
  })  : name = Value(name),
        muscleGroup = Value(muscleGroup);
  static Insertable<Exercise> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? muscleGroup,
    Expression<String>? equipment,
    Expression<String>? description,
    Expression<String>? muscleGroups,
    Expression<String>? howTo,
    Expression<String>? coachTip,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (muscleGroup != null) 'muscle_group': muscleGroup,
      if (equipment != null) 'equipment': equipment,
      if (description != null) 'description': description,
      if (muscleGroups != null) 'muscle_groups': muscleGroups,
      if (howTo != null) 'how_to': howTo,
      if (coachTip != null) 'coach_tip': coachTip,
    });
  }

  ExercisesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? muscleGroup,
      Value<String>? equipment,
      Value<String>? description,
      Value<String>? muscleGroups,
      Value<String>? howTo,
      Value<String>? coachTip}) {
    return ExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      description: description ?? this.description,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      howTo: howTo ?? this.howTo,
      coachTip: coachTip ?? this.coachTip,
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
    if (muscleGroup.present) {
      map['muscle_group'] = Variable<String>(muscleGroup.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (muscleGroups.present) {
      map['muscle_groups'] = Variable<String>(muscleGroups.value);
    }
    if (howTo.present) {
      map['how_to'] = Variable<String>(howTo.value);
    }
    if (coachTip.present) {
      map['coach_tip'] = Variable<String>(coachTip.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('muscleGroup: $muscleGroup, ')
          ..write('equipment: $equipment, ')
          ..write('description: $description, ')
          ..write('muscleGroups: $muscleGroups, ')
          ..write('howTo: $howTo, ')
          ..write('coachTip: $coachTip')
          ..write(')'))
        .toString();
  }
}

class $CachedPlansTable extends CachedPlans
    with TableInfo<$CachedPlansTable, CachedPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
      'plan_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _schemaVersionMeta =
      const VerificationMeta('schemaVersion');
  @override
  late final GeneratedColumn<String> schemaVersion = GeneratedColumn<String>(
      'schema_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
      'json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [planId, schemaVersion, json, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_plans';
  @override
  VerificationContext validateIntegrity(Insertable<CachedPlan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('plan_id')) {
      context.handle(_planIdMeta,
          planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta));
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
          _schemaVersionMeta,
          schemaVersion.isAcceptableOrUnknown(
              data['schema_version']!, _schemaVersionMeta));
    } else if (isInserting) {
      context.missing(_schemaVersionMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
          _jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {planId};
  @override
  CachedPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPlan(
      planId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_id'])!,
      schemaVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}schema_version'])!,
      json: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CachedPlansTable createAlias(String alias) {
    return $CachedPlansTable(attachedDatabase, alias);
  }
}

class CachedPlan extends DataClass implements Insertable<CachedPlan> {
  final String planId;
  final String schemaVersion;
  final String json;
  final DateTime updatedAt;
  const CachedPlan(
      {required this.planId,
      required this.schemaVersion,
      required this.json,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['plan_id'] = Variable<String>(planId);
    map['schema_version'] = Variable<String>(schemaVersion);
    map['json'] = Variable<String>(json);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedPlansCompanion toCompanion(bool nullToAbsent) {
    return CachedPlansCompanion(
      planId: Value(planId),
      schemaVersion: Value(schemaVersion),
      json: Value(json),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedPlan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPlan(
      planId: serializer.fromJson<String>(json['planId']),
      schemaVersion: serializer.fromJson<String>(json['schemaVersion']),
      json: serializer.fromJson<String>(json['json']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'planId': serializer.toJson<String>(planId),
      'schemaVersion': serializer.toJson<String>(schemaVersion),
      'json': serializer.toJson<String>(json),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedPlan copyWith(
          {String? planId,
          String? schemaVersion,
          String? json,
          DateTime? updatedAt}) =>
      CachedPlan(
        planId: planId ?? this.planId,
        schemaVersion: schemaVersion ?? this.schemaVersion,
        json: json ?? this.json,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CachedPlan copyWithCompanion(CachedPlansCompanion data) {
    return CachedPlan(
      planId: data.planId.present ? data.planId.value : this.planId,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      json: data.json.present ? data.json.value : this.json,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPlan(')
          ..write('planId: $planId, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('json: $json, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(planId, schemaVersion, json, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPlan &&
          other.planId == this.planId &&
          other.schemaVersion == this.schemaVersion &&
          other.json == this.json &&
          other.updatedAt == this.updatedAt);
}

class CachedPlansCompanion extends UpdateCompanion<CachedPlan> {
  final Value<String> planId;
  final Value<String> schemaVersion;
  final Value<String> json;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedPlansCompanion({
    this.planId = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.json = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPlansCompanion.insert({
    required String planId,
    required String schemaVersion,
    required String json,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : planId = Value(planId),
        schemaVersion = Value(schemaVersion),
        json = Value(json),
        updatedAt = Value(updatedAt);
  static Insertable<CachedPlan> custom({
    Expression<String>? planId,
    Expression<String>? schemaVersion,
    Expression<String>? json,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (planId != null) 'plan_id': planId,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (json != null) 'json': json,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPlansCompanion copyWith(
      {Value<String>? planId,
      Value<String>? schemaVersion,
      Value<String>? json,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CachedPlansCompanion(
      planId: planId ?? this.planId,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      json: json ?? this.json,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<String>(schemaVersion.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPlansCompanion(')
          ..write('planId: $planId, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('json: $json, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $CachedPlansTable cachedPlans = $CachedPlansTable(this);
  late final PlanDao planDao = PlanDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [exercises, cachedPlans];
}

typedef $$ExercisesTableCreateCompanionBuilder = ExercisesCompanion Function({
  Value<int> id,
  required String name,
  required String muscleGroup,
  Value<String> equipment,
  Value<String> description,
  Value<String> muscleGroups,
  Value<String> howTo,
  Value<String> coachTip,
});
typedef $$ExercisesTableUpdateCompanionBuilder = ExercisesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> muscleGroup,
  Value<String> equipment,
  Value<String> description,
  Value<String> muscleGroups,
  Value<String> howTo,
  Value<String> coachTip,
});

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get muscleGroup => $composableBuilder(
      column: $table.muscleGroup, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get equipment => $composableBuilder(
      column: $table.equipment, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get muscleGroups => $composableBuilder(
      column: $table.muscleGroups, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get howTo => $composableBuilder(
      column: $table.howTo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coachTip => $composableBuilder(
      column: $table.coachTip, builder: (column) => ColumnFilters(column));
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get muscleGroup => $composableBuilder(
      column: $table.muscleGroup, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get equipment => $composableBuilder(
      column: $table.equipment, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get muscleGroups => $composableBuilder(
      column: $table.muscleGroups,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get howTo => $composableBuilder(
      column: $table.howTo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coachTip => $composableBuilder(
      column: $table.coachTip, builder: (column) => ColumnOrderings(column));
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
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

  GeneratedColumn<String> get muscleGroup => $composableBuilder(
      column: $table.muscleGroup, builder: (column) => column);

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get muscleGroups => $composableBuilder(
      column: $table.muscleGroups, builder: (column) => column);

  GeneratedColumn<String> get howTo =>
      $composableBuilder(column: $table.howTo, builder: (column) => column);

  GeneratedColumn<String> get coachTip =>
      $composableBuilder(column: $table.coachTip, builder: (column) => column);
}

class $$ExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExercisesTable,
    Exercise,
    $$ExercisesTableFilterComposer,
    $$ExercisesTableOrderingComposer,
    $$ExercisesTableAnnotationComposer,
    $$ExercisesTableCreateCompanionBuilder,
    $$ExercisesTableUpdateCompanionBuilder,
    (Exercise, BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>),
    Exercise,
    PrefetchHooks Function()> {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> muscleGroup = const Value.absent(),
            Value<String> equipment = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> muscleGroups = const Value.absent(),
            Value<String> howTo = const Value.absent(),
            Value<String> coachTip = const Value.absent(),
          }) =>
              ExercisesCompanion(
            id: id,
            name: name,
            muscleGroup: muscleGroup,
            equipment: equipment,
            description: description,
            muscleGroups: muscleGroups,
            howTo: howTo,
            coachTip: coachTip,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String muscleGroup,
            Value<String> equipment = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> muscleGroups = const Value.absent(),
            Value<String> howTo = const Value.absent(),
            Value<String> coachTip = const Value.absent(),
          }) =>
              ExercisesCompanion.insert(
            id: id,
            name: name,
            muscleGroup: muscleGroup,
            equipment: equipment,
            description: description,
            muscleGroups: muscleGroups,
            howTo: howTo,
            coachTip: coachTip,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ExercisesTable, Exercise>(table),
                    BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExercisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExercisesTable,
    Exercise,
    $$ExercisesTableFilterComposer,
    $$ExercisesTableOrderingComposer,
    $$ExercisesTableAnnotationComposer,
    $$ExercisesTableCreateCompanionBuilder,
    $$ExercisesTableUpdateCompanionBuilder,
    (Exercise, BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>),
    Exercise,
    PrefetchHooks Function()>;
typedef $$CachedPlansTableCreateCompanionBuilder = CachedPlansCompanion
    Function({
  required String planId,
  required String schemaVersion,
  required String json,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CachedPlansTableUpdateCompanionBuilder = CachedPlansCompanion
    Function({
  Value<String> planId,
  Value<String> schemaVersion,
  Value<String> json,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$CachedPlansTableFilterComposer
    extends Composer<_$AppDatabase, $CachedPlansTable> {
  $$CachedPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get schemaVersion => $composableBuilder(
      column: $table.schemaVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedPlansTable> {
  $$CachedPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get schemaVersion => $composableBuilder(
      column: $table.schemaVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedPlansTable> {
  $$CachedPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get schemaVersion => $composableBuilder(
      column: $table.schemaVersion, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedPlansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedPlansTable,
    CachedPlan,
    $$CachedPlansTableFilterComposer,
    $$CachedPlansTableOrderingComposer,
    $$CachedPlansTableAnnotationComposer,
    $$CachedPlansTableCreateCompanionBuilder,
    $$CachedPlansTableUpdateCompanionBuilder,
    (CachedPlan, BaseReferences<_$AppDatabase, $CachedPlansTable, CachedPlan>),
    CachedPlan,
    PrefetchHooks Function()> {
  $$CachedPlansTableTableManager(_$AppDatabase db, $CachedPlansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> planId = const Value.absent(),
            Value<String> schemaVersion = const Value.absent(),
            Value<String> json = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedPlansCompanion(
            planId: planId,
            schemaVersion: schemaVersion,
            json: json,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String planId,
            required String schemaVersion,
            required String json,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedPlansCompanion.insert(
            planId: planId,
            schemaVersion: schemaVersion,
            json: json,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$CachedPlansTable, CachedPlan>(table),
                    BaseReferences<_$AppDatabase, $CachedPlansTable,
                        CachedPlan>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedPlansTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedPlansTable,
    CachedPlan,
    $$CachedPlansTableFilterComposer,
    $$CachedPlansTableOrderingComposer,
    $$CachedPlansTableAnnotationComposer,
    $$CachedPlansTableCreateCompanionBuilder,
    $$CachedPlansTableUpdateCompanionBuilder,
    (CachedPlan, BaseReferences<_$AppDatabase, $CachedPlansTable, CachedPlan>),
    CachedPlan,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$CachedPlansTableTableManager get cachedPlans =>
      $$CachedPlansTableTableManager(_db, _db.cachedPlans);
}
