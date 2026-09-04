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
    // Brief loading shimmer before cached/empty fallback (TES-6 §4).
    Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  List<WorkoutSession> _visible(List<WorkoutSession> all) {
    if (_range == 'month') return all;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return all.where((s) => s.date.isAfter(weekAgo)).toList();
  }

  int get _streak {
    // Consecutive days with a session ending today. M1: at most 1.
    return ref.read(workoutSessionsProvider).isEmpty ? 0 : 1;
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(coachingStringsProvider);
    final sessions = ref.watch(workoutSessionsProvider);
    final visible = _visible(sessions);

    return mobileWrap(Scaffold(
      appBar: AppBar(title: const Text('Progress')),
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
                  padding: const EdgeInsets.all(16),
                  children: [
                    _SummaryCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _streak == 0
                                ? strings.zeroStreak
                                : strings.streak(_streak),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
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
                    const Text('Weekly rhythm',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: RhythmBarChart(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Muscle load',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: MuscleLoadChart(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Recovery',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const RecoveryIndicator(),
                    const SizedBox(height: 12),
                    const Text('Personal bests',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    for (final name in _personalBests(visible))
                      _SummaryCard(
                        child: Text(strings.personalBest(name, 'first session!')),
                      ),
                    const SizedBox(height: 12),
                    const Text('Sessions',
                        style: TextStyle(fontWeight: FontWeight.w700)),
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
                          onTap: () => _showSession(context, s),
                        ),
                      ),
                  ],
                ),
    ));
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

  int _totalWorkouts(List<WorkoutSession> list) => list.length;
  int _totalSets(List<WorkoutSession> list) =>
      list.fold(0, (s, e) => s + e.setCount);
  int _totalMinutes(List<WorkoutSession>? list) =>
      (list ?? const []).fold(0, (s, e) => s + e.minutes);
  List<String> _personalBests(List<WorkoutSession> list) =>
      list.expand((s) => s.exerciseNames).toSet().toList();

  static String _fmtDate(DateTime d) =>
      '${_wd(d.weekday)} ${d.day}/${d.month}';
  static String _wd(int d) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1];
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      );
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