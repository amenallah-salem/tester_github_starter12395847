import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gym_app/core/state/auth_state.dart';
import 'package:gym_app/services/api_client.dart';
import 'package:gym_app/features/plan/state/plan_notifier.dart';
import 'package:gym_app/features/progress/state/workout_sessions.dart';

/// Applies a successful auth response (email/password, Google, Apple, or
/// phone — they all return the same `{'user','access','refresh'}` shape) to
/// app state: tokens, providers, and persisted storage. Callers still handle
/// their own navigation (`context.go('/')`) afterward, since navigation
/// isn't this function's concern and varies by caller (e.g. a page pushed
/// on top of sign-in vs. sign-in itself).
Future<void> applyAuthResult(
  WidgetRef ref,
  Map<String, dynamic> result, {
  required String fallbackUsername,
}) async {
  ref.read(accessTokenProvider.notifier).state = result['access'] as String;
  ApiClient.I.accessToken = result['access'] as String;
  if (result['refresh'] case final String refresh) {
    ref.read(refreshTokenProvider.notifier).state = refresh;
    ApiClient.I.refreshToken = refresh;
  }
  await ref.read(planNotifierProvider.notifier).refreshFromApi();
  await ref.read(workoutSessionsProvider.notifier).loadRemote();
  final user = result['user'];
  ref.read(currentUsernameProvider.notifier).state =
      user is Map ? user['username'] as String : fallbackUsername;
  await persistAuth(
    access: result['access'] as String,
    refresh: result['refresh'] as String?,
    username: ref.read(currentUsernameProvider) ?? fallbackUsername,
  );
}
