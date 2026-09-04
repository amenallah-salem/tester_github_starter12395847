import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/features/biomechanics/data/biomechanics_mock.dart';

/// 3D biomechanical replay UI — Stitch: welora_interactive_biomechanical_3d_replay.
/// Mock data only. Architecture ready for real CV/pose data.
class ReplayPage3D extends ConsumerStatefulWidget {
  const ReplayPage3D({super.key});

  @override
  ConsumerState<ReplayPage3D> createState() => _ReplayPage3DState();
}

class _ReplayPage3DState extends ConsumerState<ReplayPage3D> {
  int _frame = 0;
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    final replay = ref.watch(replayProvider);
    final current = replay.frames[_frame.clamp(0, replay.frames.length - 1)];

    return Scaffold(
      appBar: AppBar(
        title: Text('Replay · ${replay.exerciseName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_ccw),
            onPressed: () {},
            tooltip: 'Rotate 3D view',
          ),
        ],
      ),
      body: Column(
        children: [
          // 3D viewport placeholder
          Expanded(
            child: Container(
              color: const Color(0xFF141E18),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.accessibility_new,
                          size: 120,
                          color: Color(0xFFE8C547),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '3D replay · frame ${_frame + 1} / ${replay.frames.length}',
                          style: const TextStyle(
                            color: Color(0xFFE8C547),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Mock visualization · connect pose CV for real render',
                          style: TextStyle(
                            color: Color(0xFF727972),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Frame scrubber overlay
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      children: [
                        Slider(
                          value: _frame.toDouble(),
                          min: 0,
                          max: (replay.frames.length - 1).toDouble(),
                          divisions: replay.frames.length - 1,
                          onChanged: (v) =>
                              setState(() => _frame = v.round()),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                _playing
                                    ? Icons.pause_circle
                                    : Icons.play_circle,
                                color: const Color(0xFFE8C547),
                                size: 36,
                              ),
                              onPressed: () =>
                                  setState(() => _playing = !_playing),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Joint angle readout
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Joint angles',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...current.joints.map((j) {
                  final diff = (j.angle - j.target).abs();
                  final ok = diff < 5;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            j.joint,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (j.angle / 180).clamp(0.0, 1.0),
                            backgroundColor: AppTheme.surfaceContainer,
                            valueColor: AlwaysStoppedAnimation(
                              ok ? const Color(0xFF446651) : const Color(0xFFE8C547),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${j.angle.toStringAsFixed(0)}° (target ${j.target.toStringAsFixed(0)}°)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.mut,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
