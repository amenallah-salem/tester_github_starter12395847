import 'dart:convert';
import 'package:http/http.dart' as http;

class Plan {
  final int id;
  final String name;
  final String level;
  final String description;
  final int weeks;
  Plan({required this.id, required this.name, required this.level, required this.description, required this.weeks});
  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
        id: j['id'] as int,
        name: j['name'] as String,
        level: j['level'] as String? ?? '',
        description: j['description'] as String? ?? '',
        weeks: j['weeks'] as int? ?? 0,
      );
}

class ProgressMetric {
  final int id;
  final String date;
  final double? weightKg;
  final double? bodyFatPct;
  final String notes;
  ProgressMetric({required this.id, required this.date, this.weightKg, this.bodyFatPct, required this.notes});
  factory ProgressMetric.fromJson(Map<String, dynamic> j) => ProgressMetric(
        id: j['id'] as int,
        date: j['date'] as String? ?? '',
        weightKg: (j['weight_kg'] as num?)?.toDouble(),
        bodyFatPct: (j['body_fat_pct'] as num?)?.toDouble(),
        notes: j['notes'] as String? ?? '',
      );
}

class ApiClient {
  ApiClient._();
  static final ApiClient I = ApiClient._();

  // Override at build time: --dart-define=API_BASE=http://host:8000
  static const String _base = String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:8000');

  Uri _u(String path) => Uri.parse('$_base$path');

  Future<List<Plan>> fetchPlans() async {
    final r = await http.get(_u('/api/plans/'));
    if (r.statusCode != 200) throw Exception('plans: ${r.statusCode}');
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final list = (data['results'] as List?) ?? const [];
    return list.map((e) => Plan.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ProgressMetric>> fetchProgress() async {
    final r = await http.get(_u('/api/progress/'));
    if (r.statusCode != 200) throw Exception('progress: ${r.statusCode}');
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final list = (data['results'] as List?) ?? const [];
    return list.map((e) => ProgressMetric.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createWorkout({String notes = ''}) async {
    final r = await http.post(
      _u('/api/workouts/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'notes': notes}),
    );
    if (r.statusCode >= 300) throw Exception('workout: ${r.statusCode} ${r.body}');
  }
}
