import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gym_app/features/meditation/domain/meditation_session.dart';
import 'package:gym_app/services/api_client.dart';

final meditationSessionsProvider =
    FutureProvider<List<MeditationSession>>((ref) async {
  if (ApiClient.I.accessToken == null) return const [];
  final raw = await ApiClient.I.fetchMeditationSessions();
  return raw.map(MeditationSession.fromJson).toList();
});

final meditationSummaryProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  if (ApiClient.I.accessToken == null) return const {};
  return ApiClient.I.fetchMeditationSummary();
});

/// Logs a completed session and refreshes the summary/list so the
/// Meditation page reflects it immediately.
Future<void> logMeditationSession(
  WidgetRef ref, {
  required String category,
  required int durationMinutes,
}) async {
  await ApiClient.I.logMeditationSession(
    category: category,
    durationMinutes: durationMinutes,
  );
  ref.invalidate(meditationSessionsProvider);
  ref.invalidate(meditationSummaryProvider);
}
