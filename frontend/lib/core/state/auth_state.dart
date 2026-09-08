import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/services/api_client.dart';

/// Stores the JWT access token after sign-in / register.
final accessTokenProvider = StateProvider<String?>((ref) => null);

/// Stores the refresh token so an expired access token can be renewed.
final refreshTokenProvider = StateProvider<String?>((ref) => null);

/// Display username of the signed-in user.
final currentUsernameProvider = StateProvider<String?>((ref) => null);

/// The three states the app's auth bootstrap can be in. Kept as an explicit
/// type (rather than inferring "not authenticated" from "not loaded yet")
/// so the router/UI never has to guess which case it's in.
enum AuthStatus { checking, authenticated, unauthenticated }

final authStatusProvider = Provider<AuthStatus>((ref) {
  final bootstrap = ref.watch(authBootstrapProvider);
  if (bootstrap.isLoading) return AuthStatus.checking;
  final access = ref.watch(accessTokenProvider);
  return access != null && access.isNotEmpty
      ? AuthStatus.authenticated
      : AuthStatus.unauthenticated;
});

/// Refresh tokens are long-lived (30 days) bearer credentials, so on
/// iOS/Android they're kept in the OS keychain/keystore rather than plain
/// SharedPreferences. Flutter Web has no equivalent secure store (secure
/// storage there just wraps localStorage), so web keeps using
/// SharedPreferences, matching this app's existing web storage model.
const _secureStorage = FlutterSecureStorage();
const _refreshTokenKey = 'refresh_token';

Future<String?> _readRefreshToken(SharedPreferences prefs) {
  if (kIsWeb) return Future.value(prefs.getString(_refreshTokenKey));
  return _secureStorage.read(key: _refreshTokenKey);
}

Future<void> _writeRefreshToken(SharedPreferences prefs, String? value) async {
  if (kIsWeb) {
    if (value == null) {
      await prefs.remove(_refreshTokenKey);
    } else {
      await prefs.setString(_refreshTokenKey, value);
    }
    return;
  }
  if (value == null) {
    await _secureStorage.delete(key: _refreshTokenKey);
  } else {
    await _secureStorage.write(key: _refreshTokenKey, value: value);
  }
}

final authBootstrapProvider = FutureProvider<void>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  var access = prefs.getString('access_token');
  final refresh = await _readRefreshToken(prefs);
  final username = prefs.getString('username');

  // If we have no access token but a refresh token, try to refresh it now so the app
  // can restore authenticated state on startup.
  if ((access == null || access.isEmpty) && refresh != null && refresh.isNotEmpty) {
    ApiClient.I.refreshToken = refresh;
    try {
      final refreshed = await ApiClient.I.refreshAccessToken();
      if (refreshed) {
        access = ApiClient.I.accessToken;
        // persist refreshed access so subsequent startups have it
        if (access != null) await prefs.setString('access_token', access);
      }
    } catch (_) {
      // Network unreachable or backend down: fall through and treat this as
      // "could not restore" rather than crashing the bootstrap future (an
      // unhandled error here would otherwise leave accessTokenProvider unset
      // while authStatusProvider reports "unauthenticated" for the wrong
      // reason). The user simply stays signed out until connectivity returns.
    }
  }

  if (access != null && access.isNotEmpty) {
    ref.read(accessTokenProvider.notifier).state = access;
    ApiClient.I.accessToken = access;
  }
  if (refresh != null && refresh.isNotEmpty) {
    ref.read(refreshTokenProvider.notifier).state = refresh;
    ApiClient.I.refreshToken = refresh;
  }
  if (username != null) {
    ref.read(currentUsernameProvider.notifier).state = username;
  }

  // Any 401 that survives a refresh attempt elsewhere in the app means the
  // session is unrecoverable (refresh token expired/blacklisted/revoked) —
  // clear it centrally so the router's redirect sends the user to sign-in
  // instead of leaving stale, unusable credentials in place.
  ApiClient.I.onSessionExpired = () async {
    ref.read(accessTokenProvider.notifier).state = null;
    ref.read(refreshTokenProvider.notifier).state = null;
    ApiClient.I.accessToken = null;
    ApiClient.I.refreshToken = null;
    await clearPersistedAuth();
  };
});

Future<void> persistAuth({
  required String access,
  required String? refresh,
  required String username,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('access_token', access);
  if (refresh != null) await _writeRefreshToken(prefs, refresh);
  await prefs.setString('username', username);
}

Future<void> clearPersistedAuth() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('access_token');
  await _writeRefreshToken(prefs, null);
  await prefs.remove('username');
}

/// Single place that performs a full sign-out: invalidates the refresh token
/// on the backend (best-effort — if that call fails the user is still signed
/// out locally), clears in-memory auth state, and clears persisted
/// credentials. Use this instead of clearing providers ad hoc so logout
/// behaves the same everywhere it's triggered from.
Future<void> logout(WidgetRef ref) async {
  final refresh = ref.read(refreshTokenProvider);
  try {
    await ApiClient.I.logout(refresh);
  } catch (_) {
    // Best-effort: even if the backend is unreachable, still clear locally.
  }
  ref.read(accessTokenProvider.notifier).state = null;
  ref.read(refreshTokenProvider.notifier).state = null;
  ref.read(currentUsernameProvider.notifier).state = null;
  ApiClient.I.accessToken = null;
  ApiClient.I.refreshToken = null;
  await clearPersistedAuth();
}
