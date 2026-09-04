// Mock data layer for biomechanical features (Form Vault, 3D Replay).
// NOT REAL MEASUREMENTS. Architecture is ready to swap in real CV data.
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormVaultEntry {
  final String id;
  final String exerciseName;
  final String date;
  final int score; // 0–100, mock
  final String thumbnail;
  final int durationSec;
  const FormVaultEntry({
    required this.id,
    required this.exerciseName,
    required this.date,
    required this.score,
    required this.thumbnail,
    required this.durationSec,
  });
}

class JointAngle {
  final String joint;
  final double angle;
  final double target;
  const JointAngle(this.joint, this.angle, this.target);
}

class ReplayFrame {
  final int frameNumber;
  final List<JointAngle> joints;
  const ReplayFrame(this.frameNumber, this.joints);
}

class Replay {
  final String id;
  final String exerciseName;
  final List<ReplayFrame> frames;
  const Replay({required this.id, required this.exerciseName, required this.frames});
}

const _mockVault = [
  FormVaultEntry(
    id: 'v1',
    exerciseName: 'Back Squat',
    date: '2026-09-02',
    score: 92,
    thumbnail: '',
    durationSec: 12,
  ),
  FormVaultEntry(
    id: 'v2',
    exerciseName: 'Romanian Deadlift',
    date: '2026-08-30',
    score: 87,
    thumbnail: '',
    durationSec: 15,
  ),
  FormVaultEntry(
    id: 'v3',
    exerciseName: 'Bench Press',
    date: '2026-08-28',
    score: 78,
    thumbnail: '',
    durationSec: 8,
  ),
];

final formVaultProvider = Provider<List<FormVaultEntry>>((_) => _mockVault);

final replayProvider = Provider<Replay>((_) => Replay(
      id: 'r1',
      exerciseName: 'Back Squat',
      frames: List.generate(10, (i) {
        final t = i / 9;
        return ReplayFrame(i, [
          JointAngle('knee', 90 + 30 * (1 - t), 120),
          JointAngle('hip', 100 + 25 * (1 - t), 125),
          JointAngle('ankle', 70 + 5 * t, 75),
        ]);
      }),
    ));
