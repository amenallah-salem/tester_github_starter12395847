import 'package:flutter/foundation.dart';
import 'package:gym_app/features/exercise_library/domain/exercise.dart'
    as domain;
import 'package:gym_app/services/api_client.dart';

/// Reads the exercise library from the backend API, falling back to a
/// bundled starter list when the network is unavailable.
class ExerciseRepository {
  Stream<List<domain.Exercise>> watchAll({
    String? search,
    String? bodyPart,
  }) {
    final params = <String, String>{
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (bodyPart != null && bodyPart.isNotEmpty) 'body_part': bodyPart,
    };
    // Fetch the library from the backend API once and expose as a single-event stream.
    // On failure (network error, API down, CORS, etc.) fall back to the bundled
    // starter list so the screen still shows something usable.
    return Stream.fromFuture(
      ApiClient.I
          .fetchLibraryExercises(params: params)
          .then(
            (list) => list.map((m) => _fromApi(m)).toList(growable: false),
          )
          .catchError((Object error, StackTrace stackTrace) {
        debugPrint('Unable to load exercise library from API: $error');
        return _webExercises;
      }),
    );
  }

  Future<domain.Exercise?> getById(String id) async {
    List<Map<String, dynamic>> list;
    try {
      list = await ApiClient.I.fetchLibraryExercises();
    } catch (error, stackTrace) {
      debugPrint('Unable to load exercise library from API: $error');
      for (final exercise in _webExercises) {
        if (exercise.id == id) return exercise;
      }
      return null;
    }
    for (final m in list) {
      if (m['id']?.toString() == id) {
        return _fromApi(m);
      }
    }
    // Not found in the live library (e.g. legacy bundled id) — check the
    // fallback list too before giving up.
    for (final exercise in _webExercises) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }

  static final _webExercises = [
    domain.Exercise.legacy(
      id: '1',
      name: 'Barbell Squat',
      muscleGroup: 'Quads',
      equipment: 'Barbell',
      description: 'Compound lower-body movement for strength and control.',
      muscleGroups: ['Quads', 'Glutes', 'Core'],
      howTo: [
        'Rest the bar on your upper back.',
        'Descend with control.',
        'Drive through the mid-foot to stand.'
      ],
      coachTip: 'Keep your knees tracking over your toes.',
    ),
    domain.Exercise.legacy(
      id: '2',
      name: 'Goblet Squat',
      muscleGroup: 'Quads',
      equipment: 'Dumbbell',
      description: 'A friendly lower-body strength movement.',
      muscleGroups: ['Quads', 'Glutes', 'Core'],
      howTo: [
        'Hold a dumbbell at your chest.',
        'Sit back with your chest tall.',
        'Drive through your heels.'
      ],
      coachTip: 'Move slowly and keep your ribs stacked over your hips.',
    ),
    domain.Exercise.legacy(
      id: '3',
      name: 'Push-Up',
      muscleGroup: 'Chest',
      equipment: 'Bodyweight',
      description: 'Classic upper-body pressing movement.',
      muscleGroups: ['Chest', 'Shoulders', 'Triceps'],
      howTo: [
        'Place hands under your shoulders.',
        'Lower your chest as one unit.',
        'Press back up.'
      ],
      coachTip: 'Keep a straight line from your head to your heels.',
    ),
    domain.Exercise.legacy(
      id: '4',
      name: 'Dumbbell Row',
      muscleGroup: 'Back',
      equipment: 'Dumbbell',
      description: 'Build upper-back strength with a controlled pull.',
      muscleGroups: ['Back', 'Biceps'],
      howTo: [
        'Hinge with a flat back.',
        'Pull the dumbbell toward your hip.',
        'Lower slowly.'
      ],
      coachTip: 'Lead with your elbow and squeeze your shoulder blade.',
    ),
    domain.Exercise.legacy(
      id: '5',
      name: 'Bench Press',
      muscleGroup: 'Chest',
      equipment: 'Barbell',
      description: 'Compound pressing movement for the chest and triceps.',
      muscleGroups: ['Chest', 'Shoulders', 'Triceps'],
      howTo: [
        'Plant your feet and grip the bar.',
        'Lower it to your chest.',
        'Press to the start.'
      ],
      coachTip: 'Keep your wrists stacked over your elbows.',
    ),
    domain.Exercise.legacy(
      id: '6',
      name: 'Plank',
      muscleGroup: 'Core',
      equipment: 'Bodyweight',
      description: 'Isometric core stabilization for everyday movement.',
      muscleGroups: ['Core'],
      howTo: [
        'Brace your abs and glutes.',
        'Keep your body in a straight line.',
        'Breathe steadily.'
      ],
      coachTip: 'Think long and strong rather than squeezing for time.',
    ),
    domain.Exercise.legacy(
      id: '7',
      name: 'Lat Pulldown',
      muscleGroup: 'Back',
      equipment: 'Cable Machine',
      description: 'Vertical pulling exercise for the lats and upper back.',
      muscleGroups: ['Back', 'Biceps'],
      howTo: [
        'Secure your thighs under the pads.',
        'Pull the bar toward your upper chest.',
        'Return it slowly without shrugging.'
      ],
      coachTip: 'Keep the bar in front of your body and lead with your elbows.',
    ),
    domain.Exercise.legacy(
      id: '8',
      name: 'Seated Cable Row',
      muscleGroup: 'Back',
      equipment: 'Cable Machine',
      description: 'Controlled horizontal pull for the middle back.',
      muscleGroups: ['Back', 'Biceps'],
      howTo: [
        'Sit tall with knees softly bent.',
        'Pull the handle toward your ribs.',
        'Extend your arms without rounding your back.'
      ],
      coachTip: 'Avoid rocking; let your back do the work.',
    ),
    domain.Exercise.legacy(
      id: '9',
      name: 'Dumbbell Shoulder Press',
      muscleGroup: 'Shoulders',
      equipment: 'Dumbbell',
      description: 'Overhead press that builds shoulder strength.',
      muscleGroups: ['Shoulders', 'Triceps'],
      howTo: [
        'Start with weights at shoulder height.',
        'Press overhead with wrists stacked.',
        'Lower smoothly to the start.'
      ],
      coachTip: 'Use a load that lets you keep your ribs down.',
    ),
    domain.Exercise.legacy(
      id: '10',
      name: 'Dumbbell Lateral Raise',
      muscleGroup: 'Shoulders',
      equipment: 'Dumbbell',
      description: 'Isolation movement for the side deltoids.',
      muscleGroups: ['Shoulders'],
      howTo: [
        'Stand tall with light weights at your sides.',
        'Raise your arms to shoulder height.',
        'Lower without swinging.'
      ],
      coachTip: 'Keep the movement quiet and controlled.',
    ),
    domain.Exercise.legacy(
      id: '11',
      name: 'Biceps Curl',
      muscleGroup: 'Biceps',
      equipment: 'Dumbbell',
      description: 'Simple elbow-flexion exercise for the biceps.',
      muscleGroups: ['Biceps'],
      howTo: [
        'Stand with elbows close to your sides.',
        'Curl the weights without moving your shoulders.',
        'Lower fully under control.'
      ],
      coachTip: 'Choose a weight that does not require body swing.',
    ),
    domain.Exercise.legacy(
      id: '12',
      name: 'Cable Triceps Pressdown',
      muscleGroup: 'Triceps',
      equipment: 'Cable Machine',
      description: 'Cable exercise focused on elbow extension.',
      muscleGroups: ['Triceps'],
      howTo: [
        'Set the elbows beside your ribs.',
        'Press the handle down until arms are nearly straight.',
        'Return slowly to the start.'
      ],
      coachTip: 'Keep your upper arms still throughout each rep.',
    ),
    domain.Exercise.legacy(
      id: '13',
      name: 'Romanian Deadlift',
      muscleGroup: 'Hamstrings',
      equipment: 'Barbell',
      description: 'Hip hinge that trains the hamstrings and glutes.',
      muscleGroups: ['Hamstrings', 'Glutes', 'Back'],
      howTo: [
        'Hold the bar close with knees softly bent.',
        'Push your hips back while keeping a neutral spine.',
        'Drive your hips forward to stand.'
      ],
      coachTip:
          'Stop when your hamstrings are taut, not when your back rounds.',
    ),
    domain.Exercise.legacy(
      id: '14',
      name: 'Reverse Lunge',
      muscleGroup: 'Glutes',
      equipment: 'Bodyweight',
      description: 'Single-leg movement for strength and balance.',
      muscleGroups: ['Glutes', 'Quads'],
      howTo: [
        'Stand tall with feet hip-width apart.',
        'Step one foot back and lower comfortably.',
        'Push through the front foot to return.'
      ],
      coachTip: 'Use a stable support until your balance feels reliable.',
    ),
    domain.Exercise.legacy(
      id: '15',
      name: 'Calf Raise',
      muscleGroup: 'Calves',
      equipment: 'Bodyweight',
      description: 'Raises the heels to strengthen the lower legs.',
      muscleGroups: ['Calves'],
      howTo: [
        'Stand near a stable support.',
        'Lift your heels slowly.',
        'Pause and lower with control.'
      ],
      coachTip: 'Avoid bouncing and use a comfortable range of motion.',
    ),
    domain.Exercise.legacy(
      id: '16',
      name: 'Dead Bug',
      muscleGroup: 'Core',
      equipment: 'Bodyweight',
      description: 'Core-control exercise using opposite arm and leg movement.',
      muscleGroups: ['Core'],
      howTo: [
        'Lie on your back with arms up and knees bent.',
        'Extend the opposite arm and leg slowly.',
        'Return and alternate sides.'
      ],
      coachTip: 'Keep your lower back gently connected to the floor.',
    ),
    domain.Exercise.legacy(
      id: '17',
      name: 'Treadmill Walk',
      muscleGroup: 'Cardio',
      equipment: 'Treadmill',
      description:
          'Adjustable, low-impact cardio for building aerobic capacity.',
      muscleGroups: ['Cardio', 'Legs'],
      howTo: [
        'Start at an easy pace.',
        'Increase speed until breathing is elevated but conversational.',
        'Slow down gradually before stopping.'
      ],
      coachTip: 'Stay upright and avoid leaning heavily on the rails.',
    ),
    domain.Exercise.legacy(
      id: '18',
      name: 'Stationary Cycling',
      muscleGroup: 'Cardio',
      equipment: 'Exercise Bike',
      description: 'Low-impact cardio with adjustable resistance.',
      muscleGroups: ['Cardio', 'Quads', 'Glutes'],
      howTo: [
        'Set the seat so your knee stays slightly bent.',
        'Pedal smoothly at easy resistance.',
        'Build time or resistance gradually.'
      ],
      coachTip: 'Keep your knees tracking in line with your feet.',
    ),
  ];

  Future<void> seedDefaults() async {
    // No-op: library is now sourced from the backend API. Keep signature for compatibility.
    // Optionally, warm the local cache by fetching once.
    try {
      await ApiClient.I.fetchLibraryExercises();
    } catch (_) {
      // ignore network errors during app startup
    }
  }
}

/// Convert API exercise JSON to domain model, keeping every backend field.
domain.Exercise _fromApi(Map<String, dynamic> m) {
  List<String> strings(String key) =>
      (m[key] as List?)?.cast<String>() ?? const [];

  List<domain.ExerciseSummary> summaries(String key) {
    final raw = (m[key] as List?) ?? const [];
    return raw
        .cast<Map<String, dynamic>>()
        .map(
          (e) => domain.ExerciseSummary(
            id: e['id'].toString(),
            name: (e['name'] ?? '') as String,
            bodyPart: (e['body_part'] ?? '') as String,
            difficulty: (e['difficulty'] ?? '') as String,
          ),
        )
        .toList();
  }

  final targetWeight = m['target_weight_kg'];

  return domain.Exercise(
    id: m['id']?.toString(),
    name: (m['name'] ?? '') as String,
    description: (m['description'] ?? '') as String,
    aliases: strings('aliases'),
    bodyPart: (m['body_part'] ?? '') as String,
    primaryMuscles: strings('primary_muscles'),
    secondaryMuscles: strings('secondary_muscles'),
    equipment: strings('equipment'),
    movementPattern: (m['movement_pattern'] ?? '') as String,
    exerciseType: (m['exercise_type'] ?? '') as String,
    difficulty: (m['difficulty'] ?? '') as String,
    isTimed: (m['is_timed'] as bool?) ?? false,
    instructions: (m['instructions'] ?? '') as String,
    setup: (m['setup'] ?? '') as String,
    execution: (m['execution'] ?? '') as String,
    breathing: (m['breathing'] ?? '') as String,
    commonMistakes: strings('common_mistakes'),
    alternatives: summaries('alternatives_detail'),
    progressions: summaries('progression_exercises_detail'),
    regressions: summaries('regression_exercises_detail'),
    videoUrl: (m['video_url'] ?? '') as String,
    animationUrl: (m['animation_url'] ?? '') as String,
    imageUrl: (m['image'] ?? '') as String,
    targetSets: (m['target_sets'] as num?)?.toInt(),
    targetReps: (m['target_reps'] as num?)?.toInt(),
    targetWeightKg: targetWeight == null
        ? null
        : (targetWeight is num
            ? targetWeight.toDouble()
            : double.tryParse(targetWeight.toString())),
  );
}
