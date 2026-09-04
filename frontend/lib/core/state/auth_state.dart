import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/services/api_client.dart';

/// Stores the JWT access token after sign-in / register.
final accessTokenProvider = StateProvider<String?>((ref) => null);

/// Stores the refresh token so an expired access token can be renewed.
final refreshTokenProvider = StateProvider<String?>((ref) => null);

/// Display username of the signed-in user.
final currentUsernameProvider = StateProvider<String?>((ref) => null);

final authBootstrapProvider = FutureProvider<void>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final access = prefs.getString('access_token');
  final refresh = prefs.getString('refresh_token');
  final username = prefs.getString('username');
  if (access != null && access.isNotEmpty) {
    ref.read(accessTokenProvider.notifier).state = access;
    ApiClient.I.accessToken = access;
  }
  if (refresh != null) {
    ref.read(refreshTokenProvider.notifier).state = refresh;
  }
  if (username != null) {
    ref.read(currentUsernameProvider.notifier).state = username;
  }
});

Future<void> persistAuth({
  required String access,
  required String? refresh,
  required String username,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('access_token', access);
  if (refresh != null) await prefs.setString('refresh_token', refresh);
  await prefs.setString('username', username);
}

Future<void> clearPersistedAuth() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('access_token');
  await prefs.remove('refresh_token');
  await prefs.remove('username');
}
