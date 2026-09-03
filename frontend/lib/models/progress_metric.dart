class ProgressMetric {
  final int id;
  final String date;
  final int reps;
  final double? weightKg;
  final int? durationSeconds;

  ProgressMetric({
    required this.id,
    required this.date,
    required this.reps,
    this.weightKg,
    this.durationSeconds,
  });

  factory ProgressMetric.fromJson(Map<String, dynamic> json) => ProgressMetric(
        id: json['id'] as int,
        date: json['logged_at'] as String? ?? '',
        reps: json['reps'] as int,
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        durationSeconds: json['duration_seconds'] as int?,
      );
}