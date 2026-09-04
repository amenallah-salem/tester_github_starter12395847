import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_app/features/progress/domain/workout_session.dart';
import 'package:gym_app/services/api_client.dart';
import 'package:gym_app/models/progress_metric.dart';

/// Holds completed sessions for the Progress tab.
class WorkoutSessions extends Notifier<List<WorkoutSession>> {
  @override
  List<WorkoutSession> build() {
    _loadLocal();
    return const [];
  }

  void add(WorkoutSession session) {
    state = [session, ...state];
    _saveLocal();
  }

  void clear() {
    state = const [];
    _saveLocal();
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('workout_sessions');
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List;
      state = decoded
          .whereType<Map>()
          .map((item) =>
              WorkoutSession.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      await prefs.remove('workout_sessions');
    }
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'workout_sessions',
      jsonEncode(state.take(100).map((session) => session.toJson()).toList()),
    );
  }

  Future<void> loadRemote() async {
    if (ApiClient.I.accessToken == null) return;
    await ApiClient.I.flushOfflineQueue();
    final remote = await ApiClient.I.fetchSessions();
    state = remote.map((item) {
      final names =
          (item['exercise_names'] as List? ?? const []).cast<String>();
      return WorkoutSession(
        id: item['id']?.toString(),
        date: DateTime.parse(item['started_at'] as String),
        name: item['name'] as String? ?? 'Workout',
        exerciseCount: names.length,
        setCount: (item['metric_count'] as num?)?.toInt() ?? 0,
        minutes:
            (((item['duration_seconds'] as num?)?.toInt() ?? 0) / 60).round(),
        exerciseNames: names,
        durationSeconds: (item['duration_seconds'] as num?)?.toInt(),
        volumeKg: (item['total_volume_kg'] as num?)?.toDouble() ?? 0,
        finishedAt: DateTime.tryParse(item['finished_at'] as String? ?? ''),
      );
    }).toList();
    await _saveLocal();
  }
}

final workoutSessionsProvider =
    NotifierProvider<WorkoutSessions, List<WorkoutSession>>(
  WorkoutSessions.new,
);

final progressMetricsProvider =
    FutureProvider<List<ProgressMetric>>((ref) async {
  if (ApiClient.I.accessToken == null) return const [];
  return ApiClient.I.fetchProgress();
});

final progressSummaryProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  if (ApiClient.I.accessToken == null) return const {};
  return ApiClient.I.fetchProgressSummary();
});
