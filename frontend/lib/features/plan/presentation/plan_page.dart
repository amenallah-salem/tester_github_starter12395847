import 'package:flutter/material.dart';
import 'package:gym_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/state/app_state.dart';
import 'package:gym_app/core/strings/coaching.dart';
import 'package:gym_app/core/widgets/common.dart';
import 'package:gym_app/features/plan/state/plan_notifier.dart';

/// AI-generated plan view (Today tab). Renders generating / no-plan / failed /
/// ready states per TES-6 §3.2 and §4.
class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planState = ref.watch(planNotifierProvider);
    final strings = ref.watch(coachingStringsProvider);
    final name = ref.watch(profileNameProvider);

    final today = DateTime.now();
    final dateLabel =
        '${_weekday(today.weekday)} · ${_month(today.month)} ${today.day}';

    return Scaffold(
      appBar: AppBar(
        title: Text(dateLabel),
        automaticallyImplyLeading: false,
      ),
      body: planState.when(
        loading: () => const _PlanSkeleton(),
        error: (_, __) => EmptyState(
          message: strings.planFailed,
          icon: Icons.error_outline,
          ctaLabel: strings.retry,
          onCta: () =>
              ref.read(planNotifierProvider.notifier).generatePlan(),
        ),
        data: (plan) {
          if (plan == null) {
            return EmptyState(
              message: strings.noPlan,
              icon: Icons.auto_awesome_outlined,
              ctaLabel: strings.retry,
              onCta: () =>
                  ref.read(planNotifierProvider.notifier).generatePlan(),
            );
          }
          final session = plan.todaySession;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  strings.greeting(name),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.planFocus(session.dayLabel, plan.profile.sessionMinutes),
                style: const TextStyle(color: AppTheme.mut, fontSize: 15),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.summary,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                          '${plan.profile.goal.name} · ${plan.weeklySplit.name}',
                          style: const TextStyle(color: AppTheme.mut)),
                      const SizedBox(height: 12),
                      for (final e in session.exercises) ...[
                        InkWell(
                          onTap: () => context.push(
                            '/exercise/${Uri.encodeComponent(e.name)}',
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                       Text(e.name,
                                           style: const TextStyle(
                                               fontWeight: FontWeight.w600)),
                                       const SizedBox(height: 2),
                                       Text(
                                         '${e.sets} × ${e.reps} · rest ${e.restSec}s',
                                         style: const TextStyle(
                                             color: AppTheme.mut, fontSize: 13),
                                       ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: AppTheme.mut),
                              ],
                            ),
                          ),
                        ),
                        if (e != session.exercises.last)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/run'),
                icon: const Icon(Icons.play_arrow),
                label: Text(strings.startWorkout),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await ref
                            .read(planNotifierProvider.notifier)
                            .regeneratePlan();
                      },
                      child: Text(strings.regenerate),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(
                              content: Text(strings.doItLaterConfirm))),
                      child: Text(strings.doItLater),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlanSkeleton extends StatelessWidget {
  const _PlanSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        LoadingShimmer(height: 28),
        SizedBox(height: 12),
        LoadingShimmer(height: 200),
        SizedBox(height: 12),
        LoadingShimmer(height: 56),
      ],
    );
  }
}

String _weekday(int d) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1];
String _month(int m) => const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][m - 1];
