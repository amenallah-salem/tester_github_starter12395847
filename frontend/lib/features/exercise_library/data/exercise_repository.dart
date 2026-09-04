import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'package:gym_app/core/database/app_database.dart';
import 'package:gym_app/core/database/daos/exercise_dao.dart';
import 'package:gym_app/features/exercise_library/domain/exercise.dart' as domain;

/// Reads/writes the exercise library against the local Drift database.
/// Milestone 1 seeds a small starter library on first launch.
class ExerciseRepository {
  ExerciseRepository(this._dao);

  final ExerciseDao _dao;

  Stream<List<domain.Exercise>> watchAll() {
    if (kIsWeb) return Stream.value(_webExercises);
    return _dao.watchAll().map(
          (rows) => rows.map((r) => _toDomain(r)).toList(),
        );
  }

  Future<domain.Exercise?> getByName(String name) async {
    if (kIsWeb) {
      for (final exercise in _webExercises) {
        if (exercise.name == name) return exercise;
      }
      return null;
    }
    final row = await _dao.getByName(name);
    return row == null ? null : _toDomain(row);
  }

  static const _webExercises = [
    domain.Exercise(
      id: 1,
      name: 'Barbell Squat',
      muscleGroup: 'Quads',
      equipment: 'Barbell',
      description: 'Compound lower-body movement for strength and control.',
      muscleGroups: ['Quads', 'Glutes', 'Core'],
      howTo: ['Rest the bar on your upper back.', 'Descend with control.', 'Drive through the mid-foot to stand.'],
      coachTip: 'Keep your knees tracking over your toes.',
    ),
    domain.Exercise(
      id: 2,
      name: 'Goblet Squat',
      muscleGroup: 'Quads',
      equipment: 'Dumbbell',
      description: 'A friendly lower-body strength movement.',
      muscleGroups: ['Quads', 'Glutes', 'Core'],
      howTo: ['Hold a dumbbell at your chest.', 'Sit back with your chest tall.', 'Drive through your heels.'],
      coachTip: 'Move slowly and keep your ribs stacked over your hips.',
    ),
    domain.Exercise(
      id: 3,
      name: 'Push-Up',
      muscleGroup: 'Chest',
      equipment: 'Bodyweight',
      description: 'Classic upper-body pressing movement.',
      muscleGroups: ['Chest', 'Shoulders', 'Triceps'],
      howTo: ['Place hands under your shoulders.', 'Lower your chest as one unit.', 'Press back up.'],
      coachTip: 'Keep a straight line from your head to your heels.',
    ),
    domain.Exercise(
      id: 4,
      name: 'Dumbbell Row',
      muscleGroup: 'Back',
      equipment: 'Dumbbell',
      description: 'Build upper-back strength with a controlled pull.',
      muscleGroups: ['Back', 'Biceps'],
      howTo: ['Hinge with a flat back.', 'Pull the dumbbell toward your hip.', 'Lower slowly.'],
      coachTip: 'Lead with your elbow and squeeze your shoulder blade.',
    ),
    domain.Exercise(
      id: 5,
      name: 'Bench Press',
      muscleGroup: 'Chest',
      equipment: 'Barbell',
      description: 'Compound pressing movement for the chest and triceps.',
      muscleGroups: ['Chest', 'Shoulders', 'Triceps'],
      howTo: ['Plant your feet and grip the bar.', 'Lower it to your chest.', 'Press to the start.'],
      coachTip: 'Keep your wrists stacked over your elbows.',
    ),
    domain.Exercise(
      id: 6,
      name: 'Plank',
      muscleGroup: 'Core',
      equipment: 'Bodyweight',
      description: 'Isometric core stabilization for everyday movement.',
      muscleGroups: ['Core'],
      howTo: ['Brace your abs and glutes.', 'Keep your body in a straight line.', 'Breathe steadily.'],
      coachTip: 'Think long and strong rather than squeezing for time.',
    ),
    domain.Exercise(
      id: 7,
      name: 'Lat Pulldown',
      muscleGroup: 'Back',
      equipment: 'Cable Machine',
      description: 'Vertical pulling exercise for the lats and upper back.',
      muscleGroups: ['Back', 'Biceps'],
      howTo: ['Secure your thighs under the pads.', 'Pull the bar toward your upper chest.', 'Return it slowly without shrugging.'],
      coachTip: 'Keep the bar in front of your body and lead with your elbows.',
    ),
    domain.Exercise(
      id: 8,
      name: 'Seated Cable Row',
      muscleGroup: 'Back',
      equipment: 'Cable Machine',
      description: 'Controlled horizontal pull for the middle back.',
      muscleGroups: ['Back', 'Biceps'],
      howTo: ['Sit tall with knees softly bent.', 'Pull the handle toward your ribs.', 'Extend your arms without rounding your back.'],
      coachTip: 'Avoid rocking; let your back do the work.',
    ),
    domain.Exercise(
      id: 9,
      name: 'Dumbbell Shoulder Press',
      muscleGroup: 'Shoulders',
      equipment: 'Dumbbell',
      description: 'Overhead press that builds shoulder strength.',
      muscleGroups: ['Shoulders', 'Triceps'],
      howTo: ['Start with weights at shoulder height.', 'Press overhead with wrists stacked.', 'Lower smoothly to the start.'],
      coachTip: 'Use a load that lets you keep your ribs down.',
    ),
    domain.Exercise(
      id: 10,
      name: 'Dumbbell Lateral Raise',
      muscleGroup: 'Shoulders',
      equipment: 'Dumbbell',
      description: 'Isolation movement for the side deltoids.',
      muscleGroups: ['Shoulders'],
      howTo: ['Stand tall with light weights at your sides.', 'Raise your arms to shoulder height.', 'Lower without swinging.'],
      coachTip: 'Keep the movement quiet and controlled.',
    ),
    domain.Exercise(
      id: 11,
      name: 'Biceps Curl',
      muscleGroup: 'Biceps',
      equipment: 'Dumbbell',
      description: 'Simple elbow-flexion exercise for the biceps.',
      muscleGroups: ['Biceps'],
      howTo: ['Stand with elbows close to your sides.', 'Curl the weights without moving your shoulders.', 'Lower fully under control.'],
      coachTip: 'Choose a weight that does not require body swing.',
    ),
    domain.Exercise(
      id: 12,
      name: 'Cable Triceps Pressdown',
      muscleGroup: 'Triceps',
      equipment: 'Cable Machine',
      description: 'Cable exercise focused on elbow extension.',
      muscleGroups: ['Triceps'],
      howTo: ['Set the elbows beside your ribs.', 'Press the handle down until arms are nearly straight.', 'Return slowly to the start.'],
      coachTip: 'Keep your upper arms still throughout each rep.',
    ),
    domain.Exercise(
      id: 13,
      name: 'Romanian Deadlift',
      muscleGroup: 'Hamstrings',
      equipment: 'Barbell',
      description: 'Hip hinge that trains the hamstrings and glutes.',
      muscleGroups: ['Hamstrings', 'Glutes', 'Back'],
      howTo: ['Hold the bar close with knees softly bent.', 'Push your hips back while keeping a neutral spine.', 'Drive your hips forward to stand.'],
      coachTip: 'Stop when your hamstrings are taut, not when your back rounds.',
    ),
    domain.Exercise(
      id: 14,
      name: 'Reverse Lunge',
      muscleGroup: 'Glutes',
      equipment: 'Bodyweight',
      description: 'Single-leg movement for strength and balance.',
      muscleGroups: ['Glutes', 'Quads'],
      howTo: ['Stand tall with feet hip-width apart.', 'Step one foot back and lower comfortably.', 'Push through the front foot to return.'],
      coachTip: 'Use a stable support until your balance feels reliable.',
    ),
    domain.Exercise(
      id: 15,
      name: 'Calf Raise',
      muscleGroup: 'Calves',
      equipment: 'Bodyweight',
      description: 'Raises the heels to strengthen the lower legs.',
      muscleGroups: ['Calves'],
      howTo: ['Stand near a stable support.', 'Lift your heels slowly.', 'Pause and lower with control.'],
      coachTip: 'Avoid bouncing and use a comfortable range of motion.',
    ),
    domain.Exercise(
      id: 16,
      name: 'Dead Bug',
      muscleGroup: 'Core',
      equipment: 'Bodyweight',
      description: 'Core-control exercise using opposite arm and leg movement.',
      muscleGroups: ['Core'],
      howTo: ['Lie on your back with arms up and knees bent.', 'Extend the opposite arm and leg slowly.', 'Return and alternate sides.'],
      coachTip: 'Keep your lower back gently connected to the floor.',
    ),
    domain.Exercise(
      id: 17,
      name: 'Treadmill Walk',
      muscleGroup: 'Cardio',
      equipment: 'Treadmill',
      description: 'Adjustable, low-impact cardio for building aerobic capacity.',
      muscleGroups: ['Cardio', 'Legs'],
      howTo: ['Start at an easy pace.', 'Increase speed until breathing is elevated but conversational.', 'Slow down gradually before stopping.'],
      coachTip: 'Stay upright and avoid leaning heavily on the rails.',
    ),
    domain.Exercise(
      id: 18,
      name: 'Stationary Cycling',
      muscleGroup: 'Cardio',
      equipment: 'Exercise Bike',
      description: 'Low-impact cardio with adjustable resistance.',
      muscleGroups: ['Cardio', 'Quads', 'Glutes'],
      howTo: ['Set the seat so your knee stays slightly bent.', 'Pedal smoothly at easy resistance.', 'Build time or resistance gradually.'],
      coachTip: 'Keep your knees tracking in line with your feet.',
    ),
  ];

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
