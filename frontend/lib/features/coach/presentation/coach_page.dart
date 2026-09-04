import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/theme/app_theme.dart';

class CoachPage extends StatelessWidget {
  const CoachPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryContainer,
              child: Icon(Icons.spa_outlined, color: AppTheme.primary),
            ),
            SizedBox(width: 10),
            Text('Kaori'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Form Vault',
            onPressed: () => context.push('/vault'),
            icon: const Icon(Icons.insights_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Card(
            color: AppTheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryContainer,
                    child: Icon(Icons.graphic_eq,
                        size: 30, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Post-workout check-in',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        const Text(
                          'Your steady tempo today was a strong foundation.',
                          style: TextStyle(color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.play_circle_fill,
                        color: AppTheme.primary, size: 34),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _CoachBubble(
            text:
                'Welcome back. How did your lower-body session feel today?',
            coach: true,
          ),
          const SizedBox(height: 12),
          const _CoachBubble(
            text:
                'Felt very stable. Keeping my feet forward made a big difference.',
            coach: false,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.show_chart, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Form analysis · Rep 6–8',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: const Text('96% optimal'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: CustomPaint(painter: _WavePainter()),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your hip hinge and bar path stayed consistent. '
                    'Keep this grounded pace next week.',
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/replay/latest'),
                    icon: const Icon(Icons.replay),
                    label: const Text('Review biomechanical replay'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            decoration: InputDecoration(
              hintText: 'Message Kaori',
              prefixIcon: const Icon(Icons.add_circle_outline),
              suffixIcon: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.send),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachBubble extends StatelessWidget {
  const _CoachBubble({required this.text, required this.coach});

  final String text;
  final bool coach;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: coach ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: coach ? AppTheme.surface : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Text(text),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(12, size.height * .66);
    for (var x = 12.0; x < size.width - 12; x += 4) {
      final y = size.height * .5 +
          (size.height * .22) * math.sin(x / size.width * math.pi * 2);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
