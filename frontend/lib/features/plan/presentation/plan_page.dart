import 'package:flutter/material.dart';
import 'package:gym_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/state/app_state.dart';
import 'package:gym_app/core/strings/coaching.dart';
import 'package:gym_app/core/widgets/common.dart';
import 'package:gym_app/features/plan/state/plan_notifier.dart';

/// Welora dashboard (Today tab). Enhanced per Stitch.
class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planState = ref.watch(planNotifierProvider);
    final strings = ref.watch(coachingStringsProvider);
    final name = ref.watch(profileNameProvider);

    return mobileWrap(Scaffold(
      appBar: AppBar(
        title: const Text(
          'welora',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
            color: AppTheme.primary,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primary,
              child: Text(
                name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: planState.when(
        loading: () => const _PlanSkeleton(),
        error: (_, __) => EmptyState(
          message: strings.planFailed,
          icon: Icons.error_outline,
          ctaLabel: strings.retry,
          onCta: () => ref.read(planNotifierProvider.notifier).generatePlan(),
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
          return _DashboardBody(
            name: name,
            plan: plan,
            session: session,
            strings: strings,
            ref: ref,
          );
        },
      ),
    ));
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.name,
    required this.plan,
    required this.session,
    required this.strings,
    required this.ref,
  });

  final String name;
  final dynamic plan;
  final dynamic session;
  final CoachingStrings strings;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.screenGutter,
        8,
        AppTheme.screenGutter,
        24,
      ),
      children: [
        // Greeting
        Text(
          strings.greeting(name),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Movement is self-care.',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -1.5,
                color: AppTheme.ink,
              ),
        ),
        const SizedBox(height: 16),
        // Bento grid
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _WeeklyRhythmCard(daysDone: 3),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _SessionProgressCard(
                label: '3/5 sessions',
                mins: plan.profile.sessionMinutes,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _CategoryGrid(),
        const SizedBox(height: 16),
        // Session card + starter buttons preserved from original
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.profile.goal.name,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                for (final e in session.exercises) ...[
                  InkWell(
                    onTap: () => context.go('/exercise/${e.exerciseId}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${e.name} · ${e.sets} × ${e.reps}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppTheme.mut),
                        ],
                      ),
                    ),
                  ),
                  if (e != session.exercises.last) const Divider(height: 1),
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
                onPressed: () {},
                child: Text(strings.doItLater),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _WeeklyRhythmCard extends StatelessWidget {
  const _WeeklyRhythmCard({required this.daysDone});
  final int daysDone;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This week',
              style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.mut,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
                7,
                (i) => Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: i == 2 ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.outlineVariant),
                      ),
                      child: i == 2
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    )),
          ),
        ],
      ),
    );
  }
}

class _SessionProgressCard extends StatelessWidget {
  const _SessionProgressCard({required this.label, required this.mins});
  final String label;
  final int mins;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.outlineVariant)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$mins min',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: AppTheme.mut, fontSize: 13)),
          ],
        ),
      );
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context) {
    const categories = [
      ('Strength', 'Build & tone', Icons.fitness_center, Color(0xFFE5F5E9)),
      ('Mobility', 'Move better', Icons.self_improvement, Color(0xFFF1ECFA)),
      ('Cardio', 'Elevate energy', Icons.favorite_border, Color(0xFFFFF0EA)),
      ('Recovery', 'Rest & restore', Icons.nightlight_outlined, Color(0xFFE8F5F5)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: () => context.go('/explorer'),
          child: Ink(
            decoration: BoxDecoration(
              color: category.$4,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white.withOpacity(0.65),
                  child: Icon(category.$3, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.$1,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(category.$2,
                          style: const TextStyle(
                              color: AppTheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlanSkeleton  extends StatelessWidget {
  const _PlanSkeleton();
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(16), children: const [
        LoadingShimmer(height: 28),
        SizedBox(height: 12),
        LoadingShimmer(height: 200),
        SizedBox(height: 12),
        LoadingShimmer(height: 56)
      ]);
}
