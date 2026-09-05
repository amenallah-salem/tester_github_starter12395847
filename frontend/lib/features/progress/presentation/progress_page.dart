import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gym_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/strings/coaching.dart';
import 'package:gym_app/core/widgets/common.dart';
import 'package:gym_app/features/progress/presentation/progress_charts.dart';
import 'package:gym_app/features/progress/domain/workout_session.dart';
import 'package:gym_app/features/progress/state/workout_sessions.dart';
import 'package:gym_app/models/progress_metric.dart';
import 'package:gym_app/services/api_client.dart';

/// History & progress (Progress tab). Renders first-run empty, loading
/// shimmer, and the populated stats view (TES-6 §3.5 and §4).
class ProgressPage extends ConsumerStatefulWidget {
  const ProgressPage({super.key});

  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage> {
  bool _loading = true;
  String _range = 'week'; // 'week' | 'month'

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(workoutSessionsProvider.notifier).loadRemote());
    // Brief loading shimmer before cached/empty fallback (TES-6 §4).
    Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  List<WorkoutSession> _visible(List<WorkoutSession> all) {
    if (_range == 'month') return all;
    // Compare by date (local) rather than exact DateTime to avoid timezone edge cases.
    final now = DateTime.now().toLocal();
    final weekAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
    return all.where((s) {
      final sessionDay = DateTime(s.date.year, s.date.month, s.date.day);
      return sessionDay.isAfter(weekAgo) || sessionDay.isAtSameMomentAs(weekAgo);
    }).toList();
  }

  int get _streak {
    final dates = ref
        .read(workoutSessionsProvider)
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet();
    var day = DateTime.now().toLocal();
    day = DateTime(day.year, day.month, day.day);
    var count = 0;
    while (dates.contains(day)) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(coachingStringsProvider);
    final sessions = ref.watch(workoutSessionsProvider);
    final metrics = ref.watch(progressMetricsProvider).value ?? const [];
    final summary = ref.watch(progressSummaryProvider).value ?? const {};
    final visible = _visible(sessions);

    return mobileWrap(
      Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WELORA MINDFUL',
                style: TextStyle(fontSize: 10, letterSpacing: 1),
              ),
              Text('Progress'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryContainer,
                child: Icon(Icons.person_outline, color: AppTheme.primary),
              ),
            ),
          ],
        ),
        body: _loading
            ? const _ProgressSkeleton()
            : sessions.isEmpty
                ? EmptyState(
                    message: strings.progressEmpty,
                    icon: Icons.show_chart_outlined,
                    ctaLabel: strings.startTodaysPlan,
                    onCta: () => context.go('/'),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Your rhythm & progress',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Chip(
                            avatar: const Icon(Icons.eco_outlined, size: 16),
                            label: Text('${visible.length}/4 consistent'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SummaryCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _streak == 0
                                  ? strings.zeroStreak
                                  : strings.streak(_streak),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'This ${_range == 'week' ? 'week' : 'month'}: '
                              '${_totalWorkouts(visible)} workouts · '
                              '${_totalMinutes(visible)} min · '
                              '${_totalSets(visible)} sets',
                              style: const TextStyle(color: AppTheme.mut),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _InsightCard(
                              icon: Icons.timer_outlined,
                              value: _formatKg(summary['total_volume_kg']),
                              label: 'Lift volume',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InsightCard(
                              icon: Icons.emoji_events_outlined,
                              value: '${summary['personal_records'] ?? 0}',
                              label: 'Personal records',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'week', label: Text('Week')),
                          ButtonSegment(value: 'month', label: Text('Month')),
                        ],
                        selected: {_range},
                        onSelectionChanged: (s) =>
                            setState(() => _range = s.first),
                      ),
                      const SizedBox(height: 12),
                      if (metrics.isNotEmpty) ...[
                        const Text(
                          'Lift progress',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        _LiftProgressCard(metrics: metrics),
                        const SizedBox(height: 12),
                        const Text(
                          'Logged sets',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        for (final metric in metrics)
                          Card(
                            child: ListTile(
                              title: Text(metric.exerciseName ?? 'Exercise'),
                              onTap: metric.exerciseName == null
                                  ? null
                                  : () => context.push(
                                        '/exercise-history/${Uri.encodeComponent(metric.exerciseName!)}',
                                      ),
                              subtitle: Text(
                                '${metric.weightKg == null ? 'Bodyweight' : '${metric.weightKg} kg'} · '
                                '${metric.reps} reps · ${_metricDate(metric.date)}',
                              ),
                              trailing: IconButton(
                                tooltip: 'Delete logged set',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteMetric(metric),
                              ),
                            ),
                          ),
                      ],
                      const Text(
                        'Weekly rhythm',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: RhythmBarChart(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Muscle load',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: MuscleLoadChart(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Recovery',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      const RecoveryIndicator(),
                      const SizedBox(height: 12),
                      const Text(
                        'Personal bests',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      for (final name in _personalBests(visible))
                        _SummaryCard(
                          child: Text(
                              strings.personalBest(name, 'first session!')),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'Sessions',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      for (final s in visible)
                        Card(
                          child: ListTile(
                            title: Text(s.name),
                            subtitle: Text(
                              '${_fmtDate(s.date)} · ${s.setCount} sets · '
                              '${s.minutes} min',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/session/${s.id ?? ''}',
                                extra: s),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  void _showSession(BuildContext context, WorkoutSession s) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s.name),
        content: Text(
          '${_fmtDate(s.date)}\n'
          '${s.exerciseCount} exercises · ${s.setCount} sets · ${s.minutes} min\n'
          'Exercises: ${s.exerciseNames.join(', ')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMetric(ProgressMetric metric) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete logged set?'),
        content:
            const Text('This set will be removed from your progress history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ApiClient.I.deleteProgressMetric(metric.id);
    if (mounted) ref.invalidate(progressMetricsProvider);
  }

  int _totalWorkouts(List<WorkoutSession> list) => list.length;
  int _totalSets(List<WorkoutSession> list) =>
      list.fold(0, (s, e) => s + e.setCount);
  int _totalMinutes(List<WorkoutSession>? list) =>
      (list ?? const []).fold(0, (s, e) => s + e.minutes);
  List<String> _personalBests(List<WorkoutSession> list) =>
      list.expand((s) => s.exerciseNames).toSet().toList();

  static String _fmtDate(DateTime d) => '${_wd(d.weekday)} ${d.day}/${d.month}';
  static String _wd(int d) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1];
  static String _metricDate(String value) {
    final date = DateTime.tryParse(value);
    return date == null ? 'recently' : _fmtDate(date.toLocal());
  }

  static String _formatKg(dynamic value) {
    final kg = (value as num?)?.toDouble() ?? 0;
    final formatted = kg.truncateToDouble() == kg
        ? kg.toStringAsFixed(0)
        : kg.toStringAsFixed(1);
    return '$formatted kg';
  }
}

class _LiftProgressCard extends StatelessWidget {
  const _LiftProgressCard({required this.metrics});
  final List<ProgressMetric> metrics;
  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<ProgressMetric>>{};
    for (final metric in metrics) {
      grouped
          .putIfAbsent(metric.exerciseName ?? 'Exercise', () => [])
          .add(metric);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final entry in grouped.entries.take(4))
              _LiftRow(name: entry.key, metrics: entry.value),
          ],
        ),
      ),
    );
  }
}

class _LiftRow extends StatelessWidget {
  const _LiftRow({required this.name, required this.metrics});
  final String name;
  final List<ProgressMetric> metrics;
  @override
  Widget build(BuildContext context) {
    final weighted =
        metrics.where((metric) => metric.weightKg != null).toList();
    final latest = weighted.isEmpty ? null : weighted.last.weightKg!;
    final previous =
        weighted.length < 2 ? null : weighted[weighted.length - 2].weightKg;
    final delta = latest != null && previous != null ? latest - previous : null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(latest == null
          ? 'Bodyweight · ${metrics.last.reps} reps'
          : '${latest.toStringAsFixed(1)} kg · ${metrics.last.reps} reps'),
      trailing: delta == null
          ? const Icon(Icons.trending_flat, color: AppTheme.mut)
          : Text('${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg',
              style: TextStyle(
                  color: delta >= 0 ? AppTheme.primary : AppTheme.secondary,
                  fontWeight: FontWeight.w700)),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      );
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryContainer,
              child: Icon(icon, size: 17, color: AppTheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: const TextStyle(color: AppTheme.mut, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSkeleton extends StatelessWidget {
  const _ProgressSkeleton();
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          LoadingShimmer(height: 72),
          SizedBox(height: 12),
          LoadingShimmer(height: 48),
          SizedBox(height: 12),
          LoadingShimmer(height: 56),
          SizedBox(height: 12),
          LoadingShimmer(height: 56),
        ],
      );
}
