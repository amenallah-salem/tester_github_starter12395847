import 'package:drift/drift.dart';

import 'package:gym_app/core/database/app_database.dart';

part 'exercise_dao.g.dart';

@DriftAccessor(tables: [Exercises])
class ExerciseDao extends DatabaseAccessor<AppDatabase>
    with _$ExerciseDaoMixin {
  ExerciseDao(super.db);

  Stream<List<Exercise>> watchAll() =>
      (select(exercises)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  Future<List<Exercise>> getAll() => select(exercises).get();

  Future<Exercise?> getByName(String name) =>
      (select(exercises)..where((t) => t.name.equals(name))).getSingleOrNull();

  Future<int> insertOne(ExercisesCompanion row) => into(exercises).insert(row);

  Future<void> insertMany(List<ExercisesCompanion> rows) =>
      batch((b) => b.insertAll(exercises, rows));
}

extension ExerciseDaoSeed on ExerciseDao {
  Future<void> seedIfEmpty(List<ExercisesCompanion> seed) async {
    final existing = await getAll();
    if (existing.isEmpty) {
      await insertMany(seed);
    }
  }
}
