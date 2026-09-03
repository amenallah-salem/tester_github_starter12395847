import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:gym_app/core/database/daos/plan_dao.dart';

part 'app_database.g.dart';

/// Local-only on-device persistence for the gym trainer app.
/// Schema is versioned; Milestone 1 ships exercises + training plan tables.
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  /// Primary muscle group (used for quick grouping in lists).
  TextColumn get muscleGroup => text()();

  TextColumn get equipment =>
      text().withDefault(const Constant('bodyweight'))();

  TextColumn get description => text().withDefault(const Constant(''))();

  /// Comma-joined list of all trained muscles (chips on detail screen).
  TextColumn get muscleGroups =>
      text().withDefault(const Constant(''))();

  /// Newline-joined how-to steps (numbered on the detail screen).
  TextColumn get howTo => text().withDefault(const Constant(''))();

  /// Coach tip for the exercise. Tone lives in the coaching-voice doc.
  TextColumn get coachTip => text().withDefault(const Constant(''))();
}

/// Cached AI-generated plan, persisted as the contract JSON blob keyed by
/// `planId` (per the plan-contract "persist the JSON blob directly" guidance).
/// The app re-hydrates the UI from [WorkoutPlan] parsed out of [json].
class CachedPlans extends Table {
  @override
  Set<Column> get primaryKey => {planId};

  TextColumn get planId => text()();

  TextColumn get schemaVersion => text()();

  TextColumn get json => text()();

  DateTimeColumn get updatedAt => dateTime()();
}

@DriftDatabase(
  tables: [Exercises, CachedPlans],
  daos: [PlanDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(cachedPlans);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gym_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
