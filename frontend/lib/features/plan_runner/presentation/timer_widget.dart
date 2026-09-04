import 'package:flutter/material.dart';

import 'package:gym_app/core/theme/app_theme.dart';

/// Big, legible countdown dial used in the Plan Runner. Shows the remaining
/// seconds for the current work/rest phase and an arc expressing progress
/// through that phase.
class CountdownDial extends StatelessWidget {
  const CountdownDial({
    required this.remaining,
    required this.total,
    required this.label,
    super.key,
  });

  final int remaining;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final fraction = total <= 0 ? 0.0 : remaining / total;
    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: fraction,
                  strokeWidth: 12,
                  backgroundColor: AppTheme.surfaceContainer,
                  color: AppTheme.secondary,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _fmt(remaining),
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: const TextStyle(color: AppTheme.mut)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
