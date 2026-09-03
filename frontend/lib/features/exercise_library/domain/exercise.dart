/// Domain model for an exercise in the library.
/// Kept independent of the persistence layer so features stay testable.
class Exercise {
  const Exercise({
    this.id,
    required this.name,
    required this.muscleGroup,
    this.equipment = 'bodyweight',
    this.description = '',
    this.muscleGroups = const [],
    this.howTo = const [],
    this.coachTip = '',
  });

  final int? id;
  final String name;
  final String muscleGroup;
  final String equipment;
  final String description;

  /// All muscles trained (drives the chips on the exercise detail screen).
  final List<String> muscleGroups;

  /// Numbered how-to steps shown on the exercise detail screen.
  final List<String> howTo;

  /// Friendly coach tip surfaced on the detail screen. Sourced from the
  /// coaching-voice document (TES-6) — never hardcoded ad hoc.
  final String coachTip;

  Exercise copyWith({
    int? id,
    String? name,
    String? muscleGroup,
    String? equipment,
    String? description,
    List<String>? muscleGroups,
    List<String>? howTo,
    String? coachTip,
  }) {
    return Exercise(
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
}
