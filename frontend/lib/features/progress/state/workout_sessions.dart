import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gym_app/features/progress/domain/workout_session.dart';
import 'package:gym_app/services/api_client.dart';
import 'package:gym_app/models/progress_metric.dart';

/// Holds completed sessions for the Progress tab.
class WorkoutSessions extends Notifier<List<WorkoutSession>> {
  @override
  List<WorkoutSession> build() => const [];

  void add(WorkoutSession session) {
    state = [session, ...state];
  }

  void clear() => state = const [];

  Future<void> loadRemote() async {
    if (ApiClient.I.accessToken == null) return;
    final remote = await ApiClient.I.fetchSessions();
    state = remote.map((item) {
      final names =
          (item['exercise_names'] as List? ?? const []).cast<String>();
      return WorkoutSession(
        date: DateTime.parse(item['started_at'] as String),
        name: item['name'] as String? ?? 'Workout',
        exerciseCount: names.length,
        setCount: (item['metric_count'] as num?)?.toInt() ?? 0,
        minutes: 0,
        exerciseNames: names,
      );
    }).toList();
  }
}

final workoutSessionsProvider =
    NotifierProvider<WorkoutSessions, List<WorkoutSession>>(
  WorkoutSessions.new,
);

final progressMetricsProvider = FutureProvider<List<ProgressMetric>>((ref) async {
  if (ApiClient.I.accessToken == null) return const [];
  return ApiClient.I.fetchProgress();
});
