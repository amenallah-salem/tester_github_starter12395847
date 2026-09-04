import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/plan.dart';
import '../models/progress_metric.dart';

class ApiClient {
  static final ApiClient I = ApiClient();

  final String baseUrl;
  String? accessToken;
  String? refreshToken;

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl();

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers({bool json = false}) => {
        if (json) 'Content-Type': 'application/json',
        if (accessToken != null)
          'Authorization': ['Bearer', accessToken!].join(' '),
      };

  static String _defaultBaseUrl() {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) {
      return configured.replaceFirst(RegExp(r'/$'), '');
    }
    if (kIsWeb) return '/api';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api';
      case TargetPlatform.iOS:
      default:
        return 'http://127.0.0.1:8000/api';
    }
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    required String method,
    required String path,
  }) async {
    final uri = _uri(path);
    try {
      var response = await request();
      if (response.statusCode == 401 && refreshToken != null) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) response = await request();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException.fromResponse(
          method: method,
          uri: uri,
          response: response,
        );
      }
      return response;
    } on ApiException {
      rethrow;
    } on http.ClientException catch (error) {
      throw ApiException(
        message:
            'Unable to reach the API at $uri. Check that Django is running and that this device can reach the backend.',
        method: method,
        uri: uri,
        cause: error.message,
      );
    }
  }

  Future<bool> _refreshAccessToken() async {
    final token = refreshToken;
    if (token == null) return false;
    final response = await http.post(
      _uri('/auth/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': token}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) return false;
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic> || data['access'] is! String) {
      return false;
    }
    accessToken = data['access'] as String;
    return true;
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await _send(
      () => http.post(
        _uri('/auth/token/'),
        headers: _headers(json: true),
        body: jsonEncode({'username': username, 'password': password}),
      ),
      method: 'POST',
      path: '/auth/token/',
    );
    return _jsonObject(response, 'login');
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
  }) async {
    final response = await _send(
      () => http.post(
        _uri('/auth/register/'),
        headers: _headers(json: true),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName ?? '',
        }),
      ),
      method: 'POST',
      path: '/auth/register/',
    );
    return _jsonObject(response, 'registration');
  }

  Future<List<Plan>> fetchPlans() async {
    final data = _jsonObject(
      await _send(
        () => http.get(_uri('/plans/'), headers: _headers()),
        method: 'GET',
        path: '/plans/',
      ),
      'plans',
    );
    final list = (data['results'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>().map(Plan.fromJson).toList();
  }

  Future<List<ProgressMetric>> fetchProgress() async {
    final data = _jsonObject(
      await _send(
        () => http.get(_uri('/metrics/'), headers: _headers()),
        method: 'GET',
        path: '/metrics/',
      ),
      'metrics',
    );
    final list = (data['results'] as List?) ?? const [];
    return list
        .cast<Map<String, dynamic>>()
        .map(ProgressMetric.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> fetchProgressSummary() async {
    final response = await _send(
      () => http.get(_uri('/metrics/summary/'), headers: _headers()),
      method: 'GET',
      path: '/metrics/summary/',
    );
    return _jsonObject(response, 'progress summary');
  }

  Future<Map<String, dynamic>> createWorkout({required String notes}) async {
    final response = await _send(
      () => http.post(
        _uri('/sessions/'),
        headers: _headers(json: true),
        body: jsonEncode({'name': 'Workout', 'notes': notes}),
      ),
      method: 'POST',
      path: '/sessions/',
    );
    return _jsonObject(response, 'workout creation');
  }

  Future<void> logWorkoutMetric({
    required String sessionId,
    required String exerciseName,
    required int setNumber,
    required int reps,
    double? weightKg,
  }) async {
    await _send(
      () => http.post(
        _uri('/sessions/$sessionId/log-metric/'),
        headers: _headers(json: true),
        body: jsonEncode({
          'exercise_name': exerciseName,
          'set_number': setNumber,
          'reps': reps,
          'weight_kg': weightKg,
        }),
      ),
      method: 'POST',
      path: '/sessions/$sessionId/log-metric/',
    );
  }

  Future<void> deleteProgressMetric(String metricId) async {
    await _send(
      () => http.delete(
        _uri('/metrics/$metricId/'),
        headers: _headers(),
      ),
      method: 'DELETE',
      path: '/metrics/$metricId/',
    );
  }

  Future<List<Map<String, dynamic>>> fetchSessions() async {
    final response = await _send(
      () => http.get(_uri('/sessions/'), headers: _headers()),
      method: 'GET',
      path: '/sessions/',
    );
    final data = jsonDecode(response.body);
    final list = data is Map ? data['results'] as List? : data as List?;
    return (list ?? const []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> fetchCurrentPlan() async {
    final plansData = _jsonObject(
      await _send(
        () => http.get(_uri('/plans/'), headers: _headers()),
        method: 'GET',
        path: '/plans/',
      ),
      'plans',
    );
    final plans = (plansData['results'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    if (plans.isEmpty) return null;
    final plan = plans.first;
    final exerciseResponse = await _send(
      () =>
          http.get(_uri('/exercises/?plan=${plan['id']}'), headers: _headers()),
      method: 'GET',
      path: '/exercises/?plan=${plan['id']}',
    );
    final exerciseData = jsonDecode(exerciseResponse.body);
    final exercises = exerciseData is Map
        ? exerciseData['results'] as List? ?? const []
        : exerciseData as List? ?? const [];
    return {...plan, 'exercises': exercises};
  }

  Future<Map<String, dynamic>> fetchSubscription() async {
    final response = await _send(
      () => http.get(_uri('/billing/subscription/'), headers: _headers()),
      method: 'GET',
      path: '/billing/subscription/',
    );
    return _jsonObject(response, 'subscription');
  }

  Future<Map<String, dynamic>> upgradeSubscription() async {
    final response = await _send(
      () => http.patch(
        _uri('/billing/subscription/'),
        headers: _headers(json: true),
        body: jsonEncode({'plan_name': 'premium'}),
      ),
      method: 'PATCH',
      path: '/billing/subscription/',
    );
    return _jsonObject(response, 'subscription upgrade');
  }

  Map<String, dynamic> _jsonObject(http.Response response, String operation) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      throw const FormatException('Expected a JSON object.');
    } on FormatException catch (error) {
      throw ApiException(
        message: 'The API returned invalid JSON for $operation.',
        method: 'response',
        uri: response.request?.url ?? _uri('/'),
        cause: error.message,
      );
    }
  }
}

class ApiException implements Exception {
  ApiException({
    required this.message,
    required this.method,
    required this.uri,
    this.statusCode,
    this.fieldErrors = const {},
    this.cause,
  });

  final String message;
  final String method;
  final Uri uri;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;
  final String? cause;

  factory ApiException.fromResponse({
    required String method,
    required Uri uri,
    required http.Response response,
  }) {
    final details = _readErrorDetails(response.body);
    return ApiException(
      message: details.message,
      method: method,
      uri: uri,
      statusCode: response.statusCode,
      fieldErrors: details.fieldErrors,
    );
  }

  @override
  String toString() => message;
}

class _ErrorDetails {
  const _ErrorDetails(this.message, this.fieldErrors);

  final String message;
  final Map<String, List<String>> fieldErrors;
}

_ErrorDetails _readErrorDetails(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final fields = <String, List<String>>{};
      final messages = <String>[];
      decoded.forEach((key, value) {
        final values = value is List ? value : [value];
        final text = values.map((item) => item.toString()).toList();
        fields[key] = text;
        messages.add('$key: ${text.join(', ')}');
      });
      if (messages.isNotEmpty) {
        return _ErrorDetails(messages.join('\n'), fields);
      }
    }
    if (decoded is List && decoded.isNotEmpty) {
      return _ErrorDetails(decoded.join('\n'), const {});
    }
    if (decoded is String && decoded.isNotEmpty) {
      return _ErrorDetails(decoded, const {});
    }
  } on FormatException {
    // Preserve a proxy/server body when it is not JSON.
  }
  final text = body.trim();
  return _ErrorDetails(
    text.isEmpty ? 'The API returned an empty error response.' : text,
    const {},
  );
}
