/// Summary of a backend `Plan` record, as returned by `PlanListSerializer`.
class PlanSummary {
  PlanSummary({
    required this.id,
    required this.name,
    this.description = '',
    this.isActive = false,
    this.exerciseCount = 0,
  });

  final String id;
  final String name;
  final String description;
  final bool isActive;
  final int exerciseCount;

  factory PlanSummary.fromJson(Map<String, dynamic> j) => PlanSummary(
        id: j['id'].toString(),
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        isActive: j['is_active'] as bool? ?? false,
        exerciseCount: j['exercise_count'] as int? ?? 0,
      );
}
