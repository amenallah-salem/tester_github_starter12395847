import 'package:drift/drift.dart';

import 'package:gym_app/core/database/app_database.dart';
import 'package:gym_app/core/database/daos/exercise_dao.dart';
import 'package:gym_app/features/exercise_library/domain/exercise.dart' as domain;

/// Reads/writes the exercise library against the local Drift database.
/// Milestone 1 seeds a small starter library on first launch.
class ExerciseRepository {
  ExerciseRepository(this._dao);

  final ExerciseDao _dao;

  Stream<List<domain.Exercise>> watchAll() {
    return _dao.watchAll().map(
          (rows) => rows.map((r) => _toDomain(r)).toList(),
        );
  }

  Future<domain.Exercise?> getByName(String name) async {
    final row = await _dao.getByName(name);
    return row == null ? null : _toDomain(row);
  }

  Future<void> seedDefaults() async {
    await _dao.seedIfEmpty(_defaultExercises());
  }
}

domain.Exercise _toDomain(Exercise r) {
  return domain.Exercise(
    id: r.id,
    name: r.name,
    muscleGroup: r.muscleGroup,
    equipment: r.equipment,
    description: r.description,
    muscleGroups: _split(r.muscleGroups),
    howTo: _split(r.howTo),
    coachTip: r.coachTip,
  );
}

List<String> _split(String value) =>
    value.isEmpty ? const [] : value.split(',').map((s) => s.trim()).toList();

List<ExercisesCompanion> _defaultExercises() {
  const seeds = [
    _Seed(
      name: 'Goblet Squat',
      muscleGroup: 'Quads',
      equipment: 'Dumbbell',
      description: 'Fundamental lower-body strength move.',
      muscleGroups: ['Quads', 'Glutes', 'Core'],
      howTo: [
        'Hold a dumbbell vertically at your chest.',
        'Sit back with chest up, weight in heels.',
        'Drive through heels to stand tall.',
      ],
      coachTip: 'Keep your core tight and move with control — quality over speed.',
    ),
    _Seed(
      name: 'Push-Up',
      muscleGroup: 'Chest',
      equipment: 'Bodyweight',
      description: 'Classic upper-body pressing move.',
      muscleGroups: ['Chest', 'Shoulders', 'Triceps'],
      howTo: [
        'Place hands under shoulders, body in a line.',
        'Lower your chest toward the floor.',
        'Press back up, keeping a rigid plank.',
      ],
      coachTip: 'Breathe out as you push up. Lower with control.',
    ),
    _Seed(
      name: 'Dumbbell Row',
      muscleGroup: 'Back',
      equipment: 'Dumbbell',
      description: 'Pulling move for the upper back.',
      muscleGroups: ['Back', 'Biceps'],
      howTo: [
        'Hinge at the hips, flat back, one hand braced.',
        'Pull the dumbbell to your hip.',
        'Lower slowly, then switch sides.',
      ],
      coachTip: 'Squeeze your shoulder blade at the top of each rep.',
    ),
    _Seed(
      name: 'Barbell Squat',
      muscleGroup: 'Legs',
      equipment: 'Barbell',
      description: 'Compound lower-body movement.',
      muscleGroups: ['Quads', 'Glutes', 'Core'],
      howTo: [
        'Rest the bar on your upper back.',
        'Break at hips and knees to descend.',
        'Stand back up, driving through the mid-foot.',
      ],
      coachTip: 'Keep your chest up and your knees tracking your toes.',
    ),
    _Seed(
      name: 'Bench Press',
      muscleGroup: 'Chest',
      equipment: 'Barbell',
      description: 'Compound pressing movement.',
      muscleGroups: ['Chest', 'Shoulders', 'Triceps'],
      howTo: [
        'Plant your feet, arch slightly, grip the bar.',
        'Lower the bar to your chest.',
        'Press powerfully back to the start.',
      ],
      coachTip: 'Keep your wrists stacked over your elbows.',
    ),
    _Seed(
      name: 'Plank',
      muscleGroup: 'Core',
      equipment: 'Bodyweight',
      description: 'Isometric core stabilization.',
      muscleGroups: ['Core'],
      howTo: [
        'Forearms on the floor, body in a straight line.',
        'Brace your abs and glutes.',
        'Hold steady, breathing evenly.',
      ],
      coachTip: 'Don’t let your hips sag — think long and straight.',
    ),
  ];
  return seeds
      .map(
            (s) => ExercisesCompanion.insert(
              name: s.name,
              muscleGroup: s.muscleGroup,
              equipment: Value(s.equipment),
          description: Value(s.description),
          muscleGroups: Value(s.muscleGroups.join(',')),
          howTo: Value(s.howTo.join(',')),
          coachTip: Value(s.coachTip),
        ),
      )
      .toList();
}

class _Seed {
  const _Seed({
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.description,
    required this.muscleGroups,
    required this.howTo,
    required this.coachTip,
  });

  final String name;
  final String muscleGroup;
  final String equipment;
  final String description;
  final List<String> muscleGroups;
  final List<String> howTo;
  final String coachTip;
}
