import 'package:flutter/material.dart';
import 'package:gym_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gym_app/core/strings/coaching.dart';
import 'package:gym_app/core/widgets/common.dart';
import 'package:gym_app/core/di/injection.dart';
import 'package:gym_app/features/exercise_library/domain/exercise.dart';
import 'package:gym_app/features/plan/data/sample_plan.dart';
import 'package:gym_app/features/plan/state/plan_notifier.dart';

final exerciseByIdProvider = FutureProvider.family<Exercise?, String>((
  ref,
  id,
) {
  return ref.watch(exerciseRepositoryProvider).getById(id);
});

/// Exercise detail, pushed from the Explorer, a plan card, or another
/// exercise's alternatives/progressions/regressions (TES-6 §3.4).
class ExerciseDetailPage extends ConsumerWidget {
  const ExerciseDetailPage({required this.exerciseId, super.key});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(coachingStringsProvider);
    final exercise = ref.watch(exerciseByIdProvider(exerciseId));

    final plan = ref.watch(planNotifierProvider).value ?? samplePlan;

    return mobileWrap(
      Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/explorer'),
          ),
          title: Text(exercise.value?.name ?? 'Exercise'),
        ),
        body: exercise.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Exercise not found.')),
          data: (ex) {
            if (ex == null) {
              return const Center(child: Text('Exercise not found.'));
            }
            final prescription = plan.todaySession.exercises
                .where((e) => e.name.toLowerCase() == ex.name.toLowerCase())
                .firstOrNull;
            return _ExerciseDetailBody(
              exercise: ex,
              prescription: prescription,
              strings: strings,
            );
          },
        ),
      ),
    );
  }
}

class _ExerciseDetailBody extends StatelessWidget {
  const _ExerciseDetailBody({
    required this.exercise,
    required this.prescription,
    required this.strings,
  });

  final Exercise exercise;
  final dynamic prescription;
  final CoachingStrings strings;

  @override
  Widget build(BuildContext context) {
    final ex = exercise;
    final muscles = ex.muscleGroups.isNotEmpty ? ex.muscleGroups : [ex.muscleGroup];
    final mediaUrl = ex.animationUrl.isNotEmpty ? ex.animationUrl : ex.imageUrl;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _MediaHeader(mediaUrl: mediaUrl, videoUrl: ex.videoUrl),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                ex.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              tooltip: 'Save exercise',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exercise saved to Form Vault'),
                ),
              ),
              icon: const Icon(Icons.bookmark_border),
            ),
          ],
        ),
        if (ex.aliases.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Also known as: ${ex.aliases.join(', ')}',
              style: const TextStyle(
                color: AppTheme.mut,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ),
        if (ex.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            ex.description,
            style: const TextStyle(color: AppTheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (ex.difficulty.isNotEmpty) _Badge(ex.difficulty, Icons.speed),
            if (ex.exerciseType.isNotEmpty) _Badge(ex.exerciseType, Icons.category_outlined),
            if (ex.movementPattern.isNotEmpty)
              _Badge(ex.movementPattern, Icons.swap_calls),
            if (ex.isTimed) _Badge('Timed', Icons.timer_outlined),
          ],
        ),
        const SizedBox(height: 12),
        MuscleChips(muscles),
        if (ex.equipment.isNotEmpty) ...[
          const SizedBox(height: 8),
          MuscleChips(ex.equipment),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Metric(
                  label: 'Sets × Reps',
                  value: ex.targetSets != null && ex.targetReps != null
                      ? '${ex.targetSets} × ${ex.targetReps}'
                      : '—',
                ),
                _Metric(
                  label: 'Equipment',
                  value: ex.equipment.isNotEmpty
                      ? ex.equipment.join(', ')
                      : 'Bodyweight',
                ),
                _Metric(
                  label: 'Focus',
                  value: ex.bodyPart.isNotEmpty ? ex.bodyPart : 'Full body',
                ),
              ],
            ),
          ),
        ),
        ..._textSection(context, 'Setup', ex.setup),
        ..._textSection(context, 'Execution', ex.execution),
        ..._textSection(context, 'Breathing', ex.breathing),
        if (ex.setup.isEmpty && ex.execution.isEmpty && ex.breathing.isEmpty)
          ..._howToSection(context, ex.howTo),
        if (ex.commonMistakes.isNotEmpty) ..._bulletSection(
          context,
          'Common mistakes',
          ex.commonMistakes,
          icon: Icons.warning_amber_outlined,
        ),
        ..._relationSection(context, 'Alternatives', ex.alternatives),
        ..._relationSection(context, 'Easier (regressions)', ex.regressions),
        ..._relationSection(context, 'Harder (progressions)', ex.progressions),
        if (prescription != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Today', style: TextStyle(color: AppTheme.mut)),
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
  }

  List<Widget> _textSection(BuildContext context, String label, String text) {
    if (text.isEmpty) return const [];
    return [
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.mut)),
              const SizedBox(height: 8),
              Text(text),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _howToSection(BuildContext context, List<String> howTo) {
    return [
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How-to', style: TextStyle(color: AppTheme.mut)),
              const SizedBox(height: 8),
              if (howTo.isEmpty)
                const Text('No steps recorded yet.')
              else
                for (var i = 0; i < howTo.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${i + 1}. ${howTo[i]}'),
                  ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _bulletSection(
    BuildContext context,
    String label,
    List<String> items, {
    required IconData icon,
  }) {
    return [
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.mut)),
              const SizedBox(height: 8),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 16, color: AppTheme.mut),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _relationSection(
    BuildContext context,
    String label,
    List<ExerciseSummary> items,
  ) {
    if (items.isEmpty) return const [];
    return [
      const SizedBox(height: 12),
      Text(label, style: const TextStyle(color: AppTheme.mut, fontSize: 13)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map(
              (summary) => ActionChip(
                label: Text(summary.name),
                avatar: const Icon(Icons.fitness_center, size: 16),
                onPressed: () => context.push('/exercise/${summary.id}'),
              ),
            )
            .toList(),
      ),
    ];
  }
}

class _MediaHeader extends StatelessWidget {
  const _MediaHeader({required this.mediaUrl, required this.videoUrl});

  final String mediaUrl;
  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Container(
            height: 180,
            width: double.infinity,
            color: AppTheme.surfaceContainerLow,
            child: mediaUrl.isEmpty
                ? const Center(
                    child: Icon(
                      Icons.directions_run,
                      size: 72,
                      color: AppTheme.primary,
                    ),
                  )
                : Image.network(
                    mediaUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.directions_run,
                        size: 72,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
          ),
        ),
        if (videoUrl.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(videoUrl),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Watch video'),
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.icon);

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
