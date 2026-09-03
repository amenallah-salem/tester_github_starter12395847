import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gym_app/core/database/app_database.dart';
import 'package:gym_app/core/database/daos/exercise_dao.dart';
import 'package:gym_app/core/database/daos/plan_dao.dart';
import 'package:gym_app/features/exercise_library/domain/exercise.dart' as domain;
import 'package:gym_app/features/exercise_library/data/exercise_repository.dart';

/// Top-level providers for local-only, on-device dependencies.
/// No network, no accounts: everything resolves to the Drift database.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final exerciseDaoProvider = Provider<ExerciseDao>((ref) {
  return ExerciseDao(ref.watch(databaseProvider));
});

final planDaoProvider = Provider<PlanDao>((ref) {
  return PlanDao(ref.watch(databaseProvider));
});

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository(ref.watch(exerciseDaoProvider));
});

/// Seed default exercise library on first launch.
final seedProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(exerciseRepositoryProvider);
  await repo.seedDefaults();
});

final exerciseListProvider = StreamProvider<List<domain.Exercise>>((ref) {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.watchAll();
});
