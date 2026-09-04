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

final exerciseByNameProvider =
    FutureProvider.family<Exercise?, String>((ref, name) {
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

    return mobileWrap(Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
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
            padding: const EdgeInsets.all(20),
            children: [
              MuscleChips(muscles),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('How-to',
                          style: TextStyle(color: AppTheme.mut)),
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
                        const Text('Today',
                            style: TextStyle(color: AppTheme.mut)),
                        const SizedBox(height: 4),
                        Text(
                          '${prescription.sets} × ${prescription.reps} · rest ${prescription.restSec}s',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.logSet)),
                ),
                child: Text(strings.logSet),
              ),
            ],
          );
        },
      ),
    ));
  }
}
