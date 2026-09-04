import 'package:flutter/material.dart';
import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/core/widgets/common.dart';
import 'package:go_router/go_router.dart';

/// Post-workout mindful recovery screen (Stitch: welora_workout_complete_mindful_recovery).
/// Uses mock recovery metrics; ready for real session data.
class RecoveryPage extends StatelessWidget {
  const RecoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return mobileWrap(
      Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Session complete.',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Let's recover properly before the next.",
                  style: TextStyle(color: AppTheme.mut, fontSize: 15),
                ),
                const SizedBox(height: 24),

                // RPE / Recovery cards
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(label: 'RPE', value: '7'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricTile(label: 'Sets', value: '4'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(label: 'Duration', value: '32 min'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricTile(label: 'Volume', value: '2,400 kg'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Breathwork card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppTheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mindful breathwork',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Slow inhale — 4s · Hold — 4s · Exhale — 6s',
                          style: TextStyle(color: AppTheme.mut, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => context.push('/breathwork'),
                          icon: const Icon(Icons.self_improvement, size: 18),
                          label: const Text('Start breathwork'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Hydration reminder
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  child: const Text(
                    '💧 Hydration reminder — 500ml within the next 30 minutes.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Return to sanctuary'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppTheme.mut, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
