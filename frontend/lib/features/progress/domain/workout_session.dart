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

  /// Builds a [WorkoutSession] from the backend's single-object
  /// `WorkoutSessionSerializer` shape (`GET /sessions/{id}/`), which nests
  /// full `metrics` rather than the summarized `exercise_names`/`metric_count`
  /// the list endpoint returns — used when a deep link or page refresh has
  /// no in-memory session to fall back on (see app_router `/session/:id`).
  factory WorkoutSession.fromDetailJson(Map<String, dynamic> json) {
    final metrics = (json['metrics'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final exerciseNames = metrics
        .map((m) => m['exercise_name'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    return WorkoutSession(
      id: json['id']?.toString(),
      date: DateTime.parse(json['started_at'] as String).toLocal(),
      name: json['name'] as String? ?? 'Workout',
      finishedAt: json['finished_at'] == null
          ? null
          : DateTime.tryParse(json['finished_at'] as String)?.toLocal(),
      exerciseCount: exerciseNames.length,
      setCount: metrics.length,
      minutes: (((json['duration_seconds'] as num?)?.toInt() ?? 0) / 60).round(),
      exerciseNames: exerciseNames,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      volumeKg: (json['total_volume_kg'] as num?)?.toDouble() ?? 0,
    );
  }
}
