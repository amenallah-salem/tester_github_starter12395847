import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/plan.dart';
import '../models/progress_metric.dart';

class ApiClient {
  static final ApiClient I = ApiClient();

  final String baseUrl;
  String? accessToken;
  ApiClient({this.baseUrl = '/api'});

  Uri _uri(String path) => Uri.parse(baseUrl + path);
  Map<String, String> _headers({bool json = false}) => {
    if (json) 'Content-Type': 'application/json',
    if (accessToken != null) 'Authorization': 'Bearer $accessToken',
  };

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final r = await http.post(
      _uri('/auth/token/'),
      headers: _headers(json: true),
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (r.statusCode != 200) throw Exception('login: ${r.statusCode}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<List<Plan>> fetchPlans() async {
    final r = await http.get(_uri('/plans/'), headers: _headers());
    if (r.statusCode != 200) throw Exception('plans: ${r.statusCode}');
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final list = (data['results'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>().map(Plan.fromJson).toList();
  }

  Future<List<ProgressMetric>> fetchProgress() async {
    final r = await http.get(_uri('/metrics/'), headers: _headers());
    if (r.statusCode != 200) throw Exception('metrics: ${r.statusCode}');
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final list = (data['results'] as List?) ?? const [];
    return list
        .cast<Map<String, dynamic>>()
        .map(ProgressMetric.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
  }) async {
    final r = await http.post(
      _uri('/auth/register/'),
      headers: _headers(json: true),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'first_name': firstName ?? '',
      }),
    );
    if (r.statusCode != 201) throw Exception('register: ${r.statusCode}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<void> createWorkout({required String notes}) async {
    final r = await http.post(
      _uri('/sessions/'),
      headers: _headers(json: true),
      body: jsonEncode({'name': 'Workout', 'notes': notes}),
    );
    if (r.statusCode != 201) throw Exception('workout: ${r.statusCode}');
  }

  Future<List<Map<String, dynamic>>> fetchSessions() async {
    final r = await http.get(_uri('/sessions/'), headers: _headers());
    if (r.statusCode != 200) throw Exception('sessions: ${r.statusCode}');
    final data = jsonDecode(r.body);
    final list = data is Map ? data['results'] as List? : data as List?;
    return (list ?? const []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> fetchCurrentPlan() async {
    final plansResponse = await http.get(_uri('/plans/'), headers: _headers());
    if (plansResponse.statusCode != 200) {
      throw Exception('plans: ${plansResponse.statusCode}');
    }
    final plansData = jsonDecode(plansResponse.body) as Map<String, dynamic>;
    final plans = (plansData['results'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    if (plans.isEmpty) return null;
    final plan = plans.first;
    final exerciseResponse = await http.get(
      _uri('/exercises/?plan=${plan['id']}'),
      headers: _headers(),
    );
    if (exerciseResponse.statusCode != 200) {
      throw Exception('exercises: ${exerciseResponse.statusCode}');
    }
    final exerciseData = jsonDecode(exerciseResponse.body);
    final exercises = exerciseData is Map
        ? exerciseData['results'] as List? ?? const []
        : exerciseData as List? ?? const [];
    return {...plan, 'exercises': exercises};
  }

  Future<Map<String, dynamic>> fetchSubscription() async {
    final r = await http.get(
      _uri('/billing/subscription/'),
      headers: _headers(),
    );
    if (r.statusCode != 200) throw Exception('subscription: ${r.statusCode}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> upgradeSubscription() async {
    final r = await http.patch(
      _uri('/billing/subscription/'),
      headers: _headers(json: true),
      body: jsonEncode({'plan_name': 'premium'}),
    );
    if (r.statusCode != 200) throw Exception('upgrade: ${r.statusCode}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}
