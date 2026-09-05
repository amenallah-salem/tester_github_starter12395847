import 'package:flutter/material.dart';
import 'package:gym_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/strings/coaching.dart';
import 'package:gym_app/core/widgets/common.dart';
import 'package:gym_app/core/di/injection.dart';
import 'package:gym_app/features/exercise_library/domain/exercise.dart';
import 'package:gym_app/features/plan/data/sample_plan.dart';
import 'package:gym_app/features/plan/state/plan_notifier.dart';

final exerciseByNameProvider = FutureProvider.family<Exercise?, String>((
  ref,
  name,
) {
  return ref.watch(exerciseRepositoryProvider).getByName(name);
});

/// Exercise detail, pushed from the Runner or a plan card (TES-6 §3.4).
class ExerciseDetailPage extends ConsumerWidget {
  const ExerciseDetailPage({required this.exerciseId, super.key});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = Uri.decodeComponent(exerciseId);
    final strings = ref.watch(coachingStringsProvider);
    final exercise = ref.watch(exerciseByNameProvider(name));

    final plan = ref.watch(planNotifierProvider).value ?? samplePlan;
    final prescription = plan.todaySession.exercises
        .where((e) => e.name.toLowerCase() == name.toLowerCase())
        .firstOrNull;

    return mobileWrap(
      Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/explorer'),
          ),
          title: Text(name),
        ),
        body: exercise.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Exercise not found.')),
          data: (ex) {
            final muscles = ex?.muscleGroups ?? [ex?.muscleGroup ?? 'General'];
            final howTo = ex?.howTo ?? const <String>[];
            final tip = ex?.coachTip ?? '';
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.directions_run,
                      size: 72,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Save exercise',
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(
                            const SnackBar(
                              content: Text('Exercise saved to Form Vault'),
                            ),
                          ),
                      icon: const Icon(Icons.bookmark_border),
                    ),
                  ],
                ),
                if (ex?.description.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    ex!.description,
                    style: const TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 12),
                MuscleChips(muscles),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.cardPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Metric(label: 'Tempo', value: '3-1-2'),
                        _Metric(
                          label: 'Equipment',
                          value: ex?.equipment ?? 'Bodyweight',
                        ),
                        _Metric(
                          label: 'Focus',
                          value: ex?.muscleGroup ?? 'Full body',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How-to',
                          style: TextStyle(color: AppTheme.mut),
                        ),
                        const SizedBox(height: 8),
                        if (howTo.isEmpty)
                          const Text('No steps recorded yet.')
                        else
                          for (var i = 0; i < howTo.length; i++) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text('${i + 1}. ${howTo[i]}'),
                            ),
                          ],
                      ],
                    ),
                  ),
                ),
                if (tip.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  CoachLine('${strings.coachTipLabel}: $tip'),
                ],
                if (prescription != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today',
                            style: TextStyle(color: AppTheme.mut),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${prescription.sets} × ${prescription.reps} · rest ${prescription.restSec}s',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(strings.logSet))),
                  child: Text(strings.logSet),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.mut, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
