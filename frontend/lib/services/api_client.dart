import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/plan.dart';
import '../models/progress_metric.dart';

class ApiClient {
  static final ApiClient I = ApiClient();

  final String baseUrl;
  ApiClient({this.baseUrl = 'http://localhost:8000'});

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<List<Plan>> fetchPlans() async {
    final r = await http.get(_uri('/api/plans/'));
    if (r.statusCode != 200) throw Exception('plans: ${r.statusCode}');
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final list = (data['results'] as List?) ?? const [];
    return list
        .cast<Map<String, dynamic>>()
        .map(Plan.fromJson)
        .toList();
  }

  Future<List<ProgressMetric>> fetchProgress() async {
    final r = await http.get(_uri('/api/metrics/'));
    if (r.statusCode != 200) throw Exception('metrics: ${r.statusCode}');
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final list = (data['results'] as List?) ?? const [];
    return list
        .cast<Map<String, dynamic>>()
        .map(ProgressMetric.fromJson)
        .toList();
  }

  Future<void> createWorkout({required String notes}) async {
    final r = await http.post(
      _uri('/api/sessions/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': 'Workout', 'notes': notes}),
    );
    if (r.statusCode != 201) throw Exception('workout: ${r.statusCode}');
  }
}
