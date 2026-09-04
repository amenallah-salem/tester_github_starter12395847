import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/features/progress/state/workout_sessions.dart';
import 'package:gym_app/models/progress_metric.dart';

class ExerciseHistoryPage extends ConsumerWidget {
  const ExerciseHistoryPage({required this.exerciseName, super.key});

  final String exerciseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(progressMetricsProvider);
    final metrics = metricsAsync.value
            ?.where((m) =>
                m.exerciseName?.toLowerCase() == exerciseName.toLowerCase())
            .toList() ??
        const <ProgressMetric>[];
    final weighted = metrics.where((m) => m.weightKg != null).toList();
    final best = weighted.isEmpty
        ? null
        : weighted.map((m) => m.weightKg!).reduce((a, b) => a > b ? a : b);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(exerciseName),
      ),
      body: metricsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('History unavailable. ${error.toString()}'),
        ),
        data: (_) => metrics.isEmpty
            ? const Center(child: Text('No sets logged for this movement yet.'))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _Stat(
                              label: 'Best load',
                              value: best == null
                                  ? 'Bodyweight'
                                  : '${best.toStringAsFixed(1)} kg',
                            ),
                          ),
                          Expanded(
                            child: _Stat(
                              label: 'Sets',
                              value: '${metrics.length}',
                            ),
                          ),
                          Expanded(
                            child: _Stat(
                              label: 'Trend',
                              value: _trend(weighted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Logged history',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...metrics.map(
                    (metric) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.fitness_center,
                            color: AppTheme.primary),
                        title: Text(
                          '${metric.weightKg?.toStringAsFixed(1) ?? 'Bodyweight'} '
                          'kg · ${metric.reps} reps',
                        ),
                        subtitle:
                            Text('Set ${metric.setNumber} · ${metric.date}'),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  static String _trend(List<ProgressMetric> metrics) {
    if (metrics.length < 2) return 'New';
    final first = metrics.first.weightKg ?? 0;
    final last = metrics.last.weightKg ?? 0;
    if (last > first) return 'Up';
    if (last < first) return 'Down';
    return 'Steady';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: AppTheme.mut, fontSize: 12)),
        ],
      );
}
