import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/core/widgets/common.dart';
import 'package:gym_app/features/meditation/domain/meditation_session.dart';
import 'package:gym_app/features/meditation/state/meditation_state.dart';

/// The Meditation section, reached from a Home dashboard card. Lets a user
/// start a timed guided session per category; completed sessions are logged
/// to the backend (`MeditationSessionViewSet`) and roll up into the streak/
/// total-minutes summary shown at the top.
class MeditationPage extends ConsumerWidget {
  const MeditationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(meditationSummaryProvider);

    return mobileWrap(Scaffold(
      appBar: AppBar(
        title: const Text('Meditation'),
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.screenGutter,
          8,
          AppTheme.screenGutter,
          28,
        ),
        children: [
          summary.when(
            loading: () => const _SummaryCardSkeleton(),
            error: (_, __) => const SizedBox.shrink(),
            data: (data) => _SummaryCard(
              streakDays: (data['streak_days'] as num?)?.toInt() ?? 0,
              totalMinutes: (data['total_minutes'] as num?)?.toInt() ?? 0,
              sessionCount: (data['session_count'] as num?)?.toInt() ?? 0,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Choose a practice',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          for (final category in meditationCategories) ...[
            _CategoryTile(
              category: category,
              onTap: () => _openCategory(context, category),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    ));
  }

  void _openCategory(BuildContext context, MeditationCategory category) {
    if (category.key == 'breathing') {
      context.push('/breathwork');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (sheetContext) => _DurationPickerSheet(category: category),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.streakDays,
    required this.totalMinutes,
    required this.sessionCount,
  });

  final int streakDays;
  final int totalMinutes;
  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: [
          _SummaryStat(
            icon: Icons.local_fire_department_outlined,
            value: '$streakDays',
            label: streakDays == 1 ? 'day streak' : 'day streak',
          ),
          _SummaryStat(
            icon: Icons.self_improvement,
            value: '$totalMinutes',
            label: 'minutes',
          ),
          _SummaryStat(
            icon: Icons.check_circle_outline,
            value: '$sessionCount',
            label: sessionCount == 1 ? 'session' : 'sessions',
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(height: 6),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SummaryCardSkeleton extends StatelessWidget {
  const _SummaryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final MeditationCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: category.color,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white.withOpacity(0.65),
              child: Icon(category.icon, color: AppTheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(category.description,
                      style: const TextStyle(
                          color: AppTheme.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _DurationPickerSheet extends StatelessWidget {
  const _DurationPickerSheet({required this.category});

  final MeditationCategory category;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.label,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(category.description,
                style: const TextStyle(color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final minutes in meditationDurationOptionsMinutes)
                  ChoiceChip(
                    label: Text('$minutes min'),
                    selected: false,
                    onSelected: (_) {
                      Navigator.of(context).pop();
                      context.push(
                        '/meditation/session',
                        extra: {
                          'category': category,
                          'durationMinutes': minutes,
                        },
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
