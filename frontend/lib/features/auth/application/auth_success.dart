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
  final access = result['access'] as String;
  final refresh = result['refresh'] as String?;
  // Only the plain ApiClient fields are set here — not the Riverpod
  // providers below, which the router watches to decide whether to
  // navigate away from sign-in. Setting those before this function is done
  // would let that navigation dispose the calling widget (and this
  // WidgetRef) mid-flight, silently aborting everything after it —
  // including persistAuth — with no visible error.
  ApiClient.I.accessToken = access;
  ApiClient.I.refreshToken = refresh;

  await ref.read(planNotifierProvider.notifier).refreshFromApi();
  await ref.read(workoutSessionsProvider.notifier).loadRemote();
  final user = result['user'];
  final username = user is Map ? user['username'] as String : fallbackUsername;
  await persistAuth(access: access, refresh: refresh, username: username);

  ref.read(accessTokenProvider.notifier).state = access;
  if (refresh != null) ref.read(refreshTokenProvider.notifier).state = refresh;
  ref.read(currentUsernameProvider.notifier).state = username;
}
