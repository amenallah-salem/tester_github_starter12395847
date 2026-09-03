import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gym_app/features/progress/domain/workout_session.dart';

/// Holds completed sessions for the Progress tab.
class WorkoutSessions extends Notifier<List<WorkoutSession>> {
  @override
  List<WorkoutSession> build() => const [];

  void add(WorkoutSession session) {
    state = [session, ...state];
  }

  void clear() => state = const [];
}

final workoutSessionsProvider =
    NotifierProvider<WorkoutSessions, List<WorkoutSession>>(
  WorkoutSessions.new,
);
