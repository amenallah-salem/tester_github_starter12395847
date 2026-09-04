import 'package:flutter/material.dart';
import 'package:gym_app/core/theme/app_theme.dart';

/// Muscle-group filter bar aligned to Stitch welora_exercise_library_filter.
/// Reusable component for Exercise Explorer (chest, back, shoulders, arms, legs, core).
class MuscleFilterBar extends StatelessWidget {
  const MuscleFilterBar({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final String? selected;
  final ValueChanged<String?> onSelect;

  final List<String> groups = const [
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Legs',
    'Core',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 8),
          ...groups.map(
            (g) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: g,
                selected: selected == g,
                onTap: () => onSelect(selected == g ? null : g),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : AppTheme.ink,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
