import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gym_app/core/strings/coaching.dart';
import 'package:gym_app/core/state/app_state.dart';
import 'package:gym_app/core/theme/app_theme.dart';

/// Friendly coach bubble. Tone comes from [CoachingStrings] — never hardcoded.
class CoachLine extends StatelessWidget {
  const CoachLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2742),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C3C66)),
      ),
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline, color: cs.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFCFE0FF), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single-select chip used across onboarding and filters.
class SelectionChip extends StatelessWidget {
  const SelectionChip({
    required this.label,
    this.selected = false,
    this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
            if (selected)
              const Icon(Icons.check_circle, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}

/// Muscle-group pills shown on the exercise detail screen.
class MuscleChips extends StatelessWidget {
  const MuscleChips(this.groups, {super.key});

  final List<String> groups;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: groups
          .map(
            (g) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppTheme.outlineVariant),
              ),
              child: Text(
                g,
                style: const TextStyle(fontSize: 12, color: AppTheme.mut),
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Designed empty state: a human sentence paired with one clear action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.ctaLabel,
    this.onCta,
    super.key,
  });

  final String message;
  final IconData icon;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppTheme.mut),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.mut, fontSize: 15),
            ),
            if (ctaLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onCta,
                child: Text(ctaLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mobile-width responsive wrapper for web (max 420px centered).
Widget mobileWrap(Widget child) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: child,
      ),
    );

/// Skeleton placeholder used while history/plan data loads (TES-6 §4).
class LoadingShimmer extends StatefulWidget {
  const LoadingShimmer({this.height = 64, super.key});

  final double height;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final Animation<double> _opacity =
      Tween<double>(begin: 0.4, end: 1).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        height: widget.height,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Global inline offline banner. Always present in the shell; only visible
/// when connectivity reports none (TES-6 §4 "No network").
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(isOfflineProvider);
    if (!offline) return const SizedBox.shrink();
    final strings = ref.watch(coachingStringsProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppTheme.error.withOpacity(0.18),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: AppTheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              strings.offline,
              style: const TextStyle(color: AppTheme.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
