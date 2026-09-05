import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/features/progress/domain/workout_session.dart';

class SessionDetailPage extends StatelessWidget {
  const SessionDetailPage({required this.session, super.key});
  final WorkoutSession session;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/progress'),
          ),
          title: const Text('Workout details'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(session.name,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(_date(session.date),
                style: const TextStyle(color: AppTheme.mut)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                        child: _Stat('Duration', '${session.minutes} min')),
                    Expanded(child: _Stat('Sets', '${session.setCount}')),
                    Expanded(
                        child: _Stat('Volume',
                            '${session.volumeKg.toStringAsFixed(0)} kg')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Exercises',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...session.exerciseNames.map(
              (name) => Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline,
                      color: AppTheme.primary),
                  title: Text(name),
                ),
              ),
            ),
          ],
        ),
      );

  static String _date(DateTime date) =>
      '${date.day}/${date.month}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(color: AppTheme.mut, fontSize: 12)),
        ],
      );
}
