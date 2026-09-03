import 'package:gym_app/features/plan/domain/plan_contract.dart';

/// Milestone 1 sample plan, shaped exactly to the AI Coach contract
/// (`WorkoutPlan` / `docs/plan_contract.schema.json`). In a later milestone this
/// is replaced by a plan returned over the local data layer; the scaffold
/// renders a representative, contract-valid "Full Body A" so every screen
/// (Today, Plan Runner, Exercise Detail) is exercisable end-to-end.
final WorkoutPlan samplePlan = WorkoutPlan(
  schemaVersion: '1.0',
  planId: '11111111-1111-1111-1111-111111111111',
  generatedAt: DateTime.utc(2026, 1, 1, 9, 0),
  model: 'openai/gpt-4o-mini',
  profile: const OnboardingProfile(
    goal: Goal.strength,
    experience: Experience.beginner,
    daysPerWeek: 3,
    sessionMinutes: 35,
    equipment: [Equipment.bodyweight, Equipment.dumbbell],
    focusAreas: [FocusArea.fullBody],
  ),
  summary: 'Full Body A — build baseline strength and consistency.',
  weeklySplit: WeeklySplit.fullBody,
  days: const [
    PlanDay(
      dayIndex: 1,
      dayLabel: 'Day A',
      focus: 'Full Body',
      warmup: '2 min easy cardio + shoulder rolls.',
      cooldown: '1 min deep breathing.',
      blocks: [
        PlanBlock(
          blockType: BlockType.straight,
          exercises: [
            PlanExercise(
              exerciseId: 'goblet_squat',
              name: 'Goblet Squat',
              equipment: Equipment.dumbbell,
              muscleGroups: [FocusArea.legs, FocusArea.core],
              sets: 3,
              reps: '10',
              weight: 'moderate',
              restSec: 60,
              tempo: '2-0-1-0',
              notes: 'Keep chest up, drive through heels.',
              substitutes: ['bodyweight_squat'],
            ),
            PlanExercise(
              exerciseId: 'push_up',
              name: 'Push-Up',
              equipment: Equipment.bodyweight,
              muscleGroups: [FocusArea.chest, FocusArea.shoulders, FocusArea.arms],
              sets: 3,
              reps: '12',
              weight: 'bodyweight',
              restSec: 45,
              notes: 'Lower with control.',
              substitutes: ['knee_push_up'],
            ),
            PlanExercise(
              exerciseId: 'dumbbell_row',
              name: 'Dumbbell Row',
              equipment: Equipment.dumbbell,
              muscleGroups: [FocusArea.back, FocusArea.arms],
              sets: 3,
              reps: '10',
              weight: 'moderate',
              restSec: 60,
              notes: 'Squeeze shoulder blade at the top.',
              substitutes: ['inverted_row'],
            ),
          ],
        ),
      ],
      estimatedMinutes: 35,
    ),
  ],
  progression: 'Add 1–2 reps or a little load when you hit the top of the range.',
  safetyNotes: const [
    'Stop any movement that causes sharp pain.',
    'Brace your core on every lift.',
  ],
  disclaimer: 'Generated for guidance only — not medical advice. Consult a pro.',
);
