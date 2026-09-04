class Plan {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final int exerciseCount;

  Plan({
    required this.id,
    required this.name,
    this.description = '',
    this.isActive = false,
    this.exerciseCount = 0,
  });

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
        id: j['id'].toString(),
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        isActive: j['is_active'] as bool? ?? false,
        exerciseCount: j['exercise_count'] as int? ?? 0,
      );
}
