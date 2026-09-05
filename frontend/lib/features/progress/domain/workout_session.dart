/// A training session recorded locally or returned by the API.
class WorkoutSession {
  const WorkoutSession({
    required this.date,
    required this.name,
    required this.exerciseCount,
    required this.setCount,
    required this.minutes,
    this.exerciseNames = const [],
    this.durationSeconds,
    this.volumeKg = 0,
    this.id,
    this.finishedAt,
  });

  final DateTime date;
  final String name;
  final int exerciseCount;
  final int setCount;
  final int minutes;

  /// Names of exercises performed, used for personal-best lines.
  final List<String> exerciseNames;
  final int? durationSeconds;
  final double volumeKg;
  final String? id;
  final DateTime? finishedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'name': name,
        'exerciseCount': exerciseCount,
        'setCount': setCount,
        'minutes': minutes,
        'exerciseNames': exerciseNames,
        'durationSeconds': durationSeconds,
        'volumeKg': volumeKg,
        'finishedAt': finishedAt?.toIso8601String(),
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    var date = DateTime.tryParse(json['date'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    // Ensure we work in the device's local timezone for date comparisons and 'today'.
    date = date.toLocal();
    final finishedAtRaw = json['finishedAt'] as String?;
    final finishedAt = finishedAtRaw != null && finishedAtRaw.isNotEmpty
        ? DateTime.tryParse(finishedAtRaw)?.toLocal()
        : null;
    return WorkoutSession(
      id: json['id'] as String?,
      date: date,
      name: json['name'] as String? ?? 'Workout',
      finishedAt: finishedAt,
      exerciseCount: (json['exerciseCount'] as num?)?.toInt() ?? 0,
      setCount: (json['setCount'] as num?)?.toInt() ?? 0,
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      exerciseNames:
          (json['exerciseNames'] as List? ?? const []).cast<String>(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      volumeKg: (json['volumeKg'] as num?)?.toDouble() ?? 0,
    );
  }
}
