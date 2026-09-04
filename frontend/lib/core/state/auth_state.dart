import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stores the JWT access token after sign-in / register.
final accessTokenProvider = StateProvider<String?>((ref) => null);

/// Stores the refresh token so an expired access token can be renewed.
final refreshTokenProvider = StateProvider<String?>((ref) => null);

/// Display username of the signed-in user.
final currentUsernameProvider = StateProvider<String?>((ref) => null);
