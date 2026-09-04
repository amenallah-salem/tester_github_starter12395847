import 'package:flutter/material.dart';
import 'package:gym_app/core/theme/app_theme.dart';

/// Rhythm bar chart (Stitch: weekly_progress_rhythm_analytics)
/// Renders 7 vertical bars for M–S with intensity gradient.
class RhythmBarChart extends StatelessWidget {
  const RhythmBarChart(
      {super.key, this.values = const [0.4, 0.7, 0.0, 0.6, 0.0, 0.9, 0.3]});

  final List<double> values; // 0..1 per day, Mon..Sun

  @override
  Widget build(BuildContext context) {
    final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final v = values[i.clamp(0, values.length - 1)];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 80 * v,
                    decoration: BoxDecoration(
                      color: v == 0
                          ? AppTheme.outlineVariant
                          : v > 0.5
                              ? AppTheme.primary
                              : AppTheme.primary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: i == DateTime.now().weekday - 1
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: i == DateTime.now().weekday - 1
                          ? AppTheme.primary
                          : AppTheme.mut,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Muscle-load distribution card (Stitch: muscle-load distribution)
class MuscleLoadChart extends StatelessWidget {
  const MuscleLoadChart({super.key});

  static const _muscles = [
    ['Chest', 0.78],
    ['Back', 0.55],
    ['Legs', 0.92],
    ['Shoulders', 0.41],
    ['Core', 0.33],
    ['Arms', 0.22],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _muscles.map((m) {
        final v = m[1] as double;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  m[0] as String,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: v,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: v > 0.7
                              ? const Color(0xFFE8C547)
                              : AppTheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(v * 100).round()}%',
                style: const TextStyle(fontSize: 11, color: AppTheme.mut),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Recovery/HRV indicator (Stitch: recovery)
class RecoveryIndicator extends StatelessWidget {
  const RecoveryIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF446651).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.spa_outlined,
                color: Color(0xFF446651), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Recovery',
                    style: TextStyle(fontSize: 13, color: AppTheme.mut)),
                SizedBox(height: 2),
                Text('Ready for full session',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF446651).withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '72',
              style: TextStyle(
                color: Color(0xFF446651),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
