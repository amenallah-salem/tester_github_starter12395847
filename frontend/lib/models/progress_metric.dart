/// DRF serializes `DecimalField`s (e.g. `weight_kg`) as JSON strings
/// (e.g. `"85.00"`) rather than numbers, so a plain `as num?` cast throws.
double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

class ProgressMetric {
  final String id;
  final String? exerciseName;
  final String date;
  final int setNumber;
  final int reps;
  final double? weightKg;
  final int? durationSeconds;

  ProgressMetric({
    required this.id,
    this.exerciseName,
    required this.date,
    this.setNumber = 1,
    required this.reps,
    this.weightKg,
    this.durationSeconds,
  });

  factory ProgressMetric.fromJson(Map<String, dynamic> json) => ProgressMetric(
        id: json['id'].toString(),
        exerciseName: json['exercise_name'] as String?,
        date: json['logged_at'] as String? ?? '',
        setNumber: (json['set_number'] as num?)?.toInt() ?? 1,
        reps: (json['reps'] as num?)?.toInt() ?? 0,
        weightKg: _toDouble(json['weight_kg']),
        durationSeconds: json['duration_seconds'] as int?,
      );
}
