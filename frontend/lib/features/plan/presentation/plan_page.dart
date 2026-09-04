import 'package:flutter/material.dart';
import 'package:gym_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/state/app_state.dart';
import 'package:gym_app/core/strings/coaching.dart';
import 'package:gym_app/core/widgets/common.dart';
import 'package:gym_app/features/home/presentation/home_page.dart';
import 'package:gym_app/features/plan/state/plan_notifier.dart';

/// Welora dashboard (Today tab). Enhanced per Stitch.
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

    return mobileWrap(Scaffold(
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
      padding: const EdgeInsets.all(16),
      children: [
        // Greeting
        Text(
          strings.greeting(name),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          'Movement is self-care.',
          style: TextStyle(
            color: AppTheme.mut,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        // Bento grid
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _WeeklyRhythmCard(daysDone: 0),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _SessionProgressCard(
                label: session.dayLabel,
                mins: plan.profile.sessionMinutes,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Session card + starter buttons preserved from original
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.profile.goal.name,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                for (final e in session.exercises) ...[
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, '/exercise'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${e.name} · ${e.sets} × ${e.reps}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
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
          onPressed: () {},
          icon: const Icon(Icons.play_arrow),
          label: Text(strings.startWorkout),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  await ref.read(planNotifierProvider.notifier).regeneratePlan();
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
          const Text('This week', style: TextStyle(fontSize: 11, color: AppTheme.mut, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) => Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: i == 2 ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.outlineVariant),
              ),
              child: i == 2 ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            )),
          ),
        ],
      ),
    );
  }
}

class _SessionProgressCard extends StatelessWidget {
  const _SessionProgressCard({required this.label, required this.mins});
  final String label; final int mins;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.outlineVariant)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$mins min', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.mut, fontSize: 13)),
      ],
    ),
  );
}

class _PlanSkeleton extends StatelessWidget {
  const _PlanSkeleton();
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: const [LoadingShimmer(height: 28), SizedBox(height: 12), LoadingShimmer(height: 200), SizedBox(height: 12), LoadingShimmer(height: 56)]);
}

String _weekday(int d) => const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d-1];
String _month(int m) => const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];
