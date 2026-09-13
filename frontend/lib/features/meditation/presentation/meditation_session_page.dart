import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/features/meditation/domain/meditation_session.dart';
import 'package:gym_app/features/meditation/state/meditation_state.dart';

/// Runs a single timed meditation session for [category]/[durationMinutes].
/// Logs the session to the backend once the countdown completes; closing
/// early does not log a partial session.
class MeditationSessionRunnerPage extends ConsumerStatefulWidget {
  const MeditationSessionRunnerPage({
    required this.category,
    required this.durationMinutes,
    super.key,
  });

  final MeditationCategory category;
  final int durationMinutes;

  @override
  ConsumerState<MeditationSessionRunnerPage> createState() =>
      _MeditationSessionRunnerPageState();
}

class _MeditationSessionRunnerPageState
    extends ConsumerState<MeditationSessionRunnerPage> {
  Timer? _timer;
  late final int _totalSeconds = widget.durationMinutes * 60;
  late int _secondsLeft = _totalSeconds;
  bool _running = false;
  bool _logging = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _toggle();
  }

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
      if (_secondsLeft <= 1) {
        _timer?.cancel();
        setState(() {
          _secondsLeft = 0;
          _running = false;
          _completed = true;
        });
        _logCompletion();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _logCompletion() async {
    setState(() => _logging = true);
    try {
      await logMeditationSession(
        ref,
        category: widget.category.key,
        durationMinutes: widget.durationMinutes,
      );
    } catch (_) {
      // Session still "completed" from the user's perspective even if the
      // log call failed (e.g. offline) — don't block the finish screen.
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_secondsLeft / _totalSeconds);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.label),
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/meditation'),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          children: [
            const Spacer(),
            Text(
              _completed ? 'Session complete' : widget.category.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
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
                      Icon(widget.category.icon,
                          size: 36, color: AppTheme.primary),
                      const SizedBox(height: 8),
                      Text(
                        '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
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
                onPressed: _completed
                    ? (_logging
                        ? null
                        : () => context.canPop()
                            ? context.pop()
                            : context.go('/meditation'))
                    : _toggle,
                icon: Icon(_completed
                    ? Icons.check
                    : (_running ? Icons.pause : Icons.play_arrow)),
                label: Text(_completed
                    ? 'Done'
                    : (_running ? 'Pause' : 'Resume')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
