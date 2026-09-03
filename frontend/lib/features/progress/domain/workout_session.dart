/// A completed training session, recorded by the Plan Runner.
/// Milestone 1 keeps these in memory (persistence lands in a later issue);
/// they drive the Progress tab's streak, volume, and personal bests.
class WorkoutSession {
  const WorkoutSession({
    required this.date,
    required this.name,
    required this.exerciseCount,
    required this.setCount,
    required this.minutes,
    this.exerciseNames = const [],
  });

  final DateTime date;
  final String name;
  final int exerciseCount;
  final int setCount;
  final int minutes;

  /// Names of exercises performed, used for personal-best lines.
  final List<String> exerciseNames;
}
