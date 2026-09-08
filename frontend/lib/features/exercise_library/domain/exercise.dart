/// A compact reference to another exercise (used for alternatives,
/// progressions and regressions) — enough to render a tappable chip without
/// a second network round-trip.
class ExerciseSummary {
  const ExerciseSummary({
    required this.id,
    required this.name,
    this.bodyPart = '',
    this.difficulty = '',
  });

  final String id;
  final String name;
  final String bodyPart;
  final String difficulty;
}

/// Domain model for an exercise in the library.
/// Kept independent of the persistence layer so features stay testable.
class Exercise {
  const Exercise({
    this.id,
    required this.name,
    this.description = '',
    this.aliases = const [],
    this.bodyPart = '',
    this.primaryMuscles = const [],
    this.secondaryMuscles = const [],
    this.equipment = const [],
    this.movementPattern = '',
    this.exerciseType = '',
    this.difficulty = '',
    this.isTimed = false,
    this.instructions = '',
    this.setup = '',
    this.execution = '',
    this.breathing = '',
    this.commonMistakes = const [],
    this.alternatives = const [],
    this.progressions = const [],
    this.regressions = const [],
    this.videoUrl = '',
    this.animationUrl = '',
    this.imageUrl = '',
    this.targetSets,
    this.targetReps,
    this.targetWeightKg,
  });

  /// Backend UUID (null for the legacy hardcoded/offline fallback data).
  final String? id;
  final String name;
  final String description;
  final List<String> aliases;
  final String bodyPart;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> equipment;
  final String movementPattern;
  final String exerciseType;
  final String difficulty;
  final bool isTimed;
  final String instructions;
  final String setup;
  final String execution;
  final String breathing;
  final List<String> commonMistakes;
  final List<ExerciseSummary> alternatives;
  final List<ExerciseSummary> progressions;
  final List<ExerciseSummary> regressions;
  final String videoUrl;
  final String animationUrl;
  final String imageUrl;
  final int? targetSets;
  final int? targetReps;
  final double? targetWeightKg;

  /// All muscles trained (drives the chips on the exercise detail screen).
  List<String> get muscleGroups => [...primaryMuscles, ...secondaryMuscles];

  /// Convenience accessor kept for call sites that only need one label
  /// (list-tile subtitles, etc).
  String get muscleGroup =>
      bodyPart.isNotEmpty ? bodyPart : (primaryMuscles.isNotEmpty ? primaryMuscles.first : 'Unknown');

  /// Numbered how-to steps derived from instructions, used only when the
  /// structured setup/execution/breathing fields are all empty.
  List<String> get howTo {
    final steps = <String>[];
    if (setup.isNotEmpty) steps.addAll(_splitSentences(setup));
    if (execution.isNotEmpty) steps.addAll(_splitSentences(execution));
    if (steps.isEmpty && instructions.isNotEmpty) {
      steps.addAll(_splitSentences(instructions));
    }
    return steps;
  }

  /// Friendly coach tip surfaced on the detail screen (first common mistake,
  /// phrased as something to avoid).
  String get coachTip => commonMistakes.isNotEmpty ? commonMistakes.first : '';

  /// Builds an [Exercise] from the old flat single-value shape used by the
  /// bundled offline fallback data and the local Drift cache.
  factory Exercise.legacy({
    String? id,
    required String name,
    required String muscleGroup,
    String equipment = 'bodyweight',
    String description = '',
    List<String> muscleGroups = const [],
    List<String> howTo = const [],
    String coachTip = '',
  }) {
    return Exercise(
      id: id,
      name: name,
      description: description,
      bodyPart: muscleGroup,
      primaryMuscles: muscleGroups,
      equipment: [equipment],
      setup: howTo.isNotEmpty ? howTo.first : '',
      execution: howTo.length > 1 ? howTo.sublist(1).join('. ') : '',
      commonMistakes: coachTip.isNotEmpty ? [coachTip] : const [],
    );
  }
}

List<String> _splitSentences(String text) {
  return text
      .split(RegExp(r'[\.\?\n]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
