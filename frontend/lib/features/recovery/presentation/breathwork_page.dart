import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/theme/app_theme.dart';

class BreathworkPage extends StatefulWidget {
  const BreathworkPage({super.key});

  @override
  State<BreathworkPage> createState() => _BreathworkPageState();
}

class _BreathworkPageState extends State<BreathworkPage> {
  Timer? _timer;
  int _seconds = 60;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_seconds <= 1) {
        _timer?.cancel();
        setState(() {
          _seconds = 0;
          _running = false;
        });
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_seconds / 60);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mindful recovery'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          children: [
            const Spacer(),
            Text(
              _seconds == 0 ? 'Complete' : 'Breathe with your movement',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Inhale for 4 seconds · hold for 4 · exhale for 6',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: AppTheme.surfaceContainer,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.spa_outlined,
                        size: 36,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _toggle,
                icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                label: Text(_running ? 'Pause' : 'Begin'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
