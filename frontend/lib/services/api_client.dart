import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/plan.dart';
import '../models/progress_metric.dart';

class ApiClient {
  static final ApiClient I = ApiClient();

  final String baseUrl;
  ApiClient({this.baseUrl = '/api'});

  Uri _uri(String path) => Uri.parse(baseUrl + path);

  Future<List<Plan>> fetchPlans() async {
    final r = await http.get(_uri('/plans/'));
    if (r.statusCode != 200) throw Exception('plans: ${r.statusCode}');
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final list = (data['results'] as List?) ?? const [];
    return list
        .cast<Map<String, dynamic>>()
        .map(Plan.fromJson)
        .toList();
  }

  Future<List<ProgressMetric>> fetchProgress() async {
    final r = await http.get(_uri('/metrics/'));
    if (r.statusCode != 200) throw Exception('metrics: ${r.statusCode}');
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final list = (data['results'] as List?) ?? const [];
    return list
        .cast<Map<String, dynamic>>()
        .map(ProgressMetric.fromJson)
        .toList();
  }

  Future<Map<String,dynamic>> register({required String username, required String email, required String password, String? firstName}) async {
    final r = await http.post(_uri('/auth/register/'), headers: {'Content-Type':'application/json'}, body: jsonEncode({'username':username,'email':email,'password':password,'first_name':firstName??''}));
    if (r.statusCode!=201) throw Exception('register: ${r.statusCode}');
    return jsonDecode(r.body) as Map<String,dynamic>;
  }

  Future<void> createWorkout({required String notes}) async {
    final r = await http.post(
      _uri('/sessions/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': 'Workout', 'notes': notes}),
    );
    if (r.statusCode != 201) throw Exception('workout: ${r.statusCode}');
  }
}
