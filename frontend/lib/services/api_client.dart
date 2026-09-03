import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  ApiClient({this.baseUrl = 'http://localhost:8000'});

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<List<Map<String, dynamic>>> fetchPlans() async {
    final r = await http.get(_uri('/api/plans/'));
    if (r.statusCode != 200) throw Exception('plans: ${r.statusCode}');
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final list = (data['results'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>();
  }
}
