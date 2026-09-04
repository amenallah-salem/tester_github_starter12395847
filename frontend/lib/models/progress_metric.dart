class ProgressMetric {
  final String id;
  final String? exerciseName;
  final String date;
  final int reps;
  final double? weightKg;
  final int? durationSeconds;

  ProgressMetric({
    required this.id,
    this.exerciseName,
    required this.date,
    required this.reps,
    this.weightKg,
    this.durationSeconds,
  });

  factory ProgressMetric.fromJson(Map<String, dynamic> json) => ProgressMetric(
        id: json['id'].toString(),
        exerciseName: json['exercise_name'] as String?,
        date: json['logged_at'] as String? ?? '',
        reps: (json['reps'] as num?)?.toInt() ?? 0,
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        durationSeconds: json['duration_seconds'] as int?,
      );
}