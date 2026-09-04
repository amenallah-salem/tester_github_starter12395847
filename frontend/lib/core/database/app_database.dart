import 'package:drift/drift.dart';

import 'package:gym_app/core/database/daos/plan_dao.dart';
import 'database_connection.dart'
  if (dart.library.io) 'database_connection_native.dart'
  if (dart.library.html) 'database_connection_web.dart';

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
  AppDatabase() : super(openConnection());

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
