/// Training plan data contract — consumed from the AI Coach Engineer (TES-13).
///
/// This is the single source of truth for the JSON shape the AI coach returns
/// and the app renders. Field names mirror `ai_coach/docs/plan_contract.schema.json`
/// (JSON Schema 2020-12); the machine-readable schema is bundled as
/// `assets/plan_contract.schema.json` and a plan is validated against it before
/// it is rendered (see `plan_validator.dart`).
///
/// Serialization is hand-written (no codegen) so the model is drop-in ready and
/// stays in lock-step with the contract.
library;

import 'package:gym_app/features/plan/domain/plan_enums.dart';

export 'plan_enums.dart';

/// Onboarding inputs echoed back in [WorkoutPlan.profile].
class OnboardingProfile {
  const OnboardingProfile({
    required this.goal,
    required this.experience,
    required this.daysPerWeek,
    required this.sessionMinutes,
    required this.equipment,
    required this.focusAreas,
    this.limitations = const [],
    this.notes,
  });

  final Goal goal;
  final Experience experience;
  final int daysPerWeek;
  final int sessionMinutes;
  final List<Equipment> equipment;
  final List<FocusArea> focusAreas;
  final List<String> limitations;
  final String? notes;

  factory OnboardingProfile.fromJson(Map<String, dynamic> json) {
    final goal = enumFromString(Goal.values, json['goal']);
    final experience = enumFromString(Experience.values, json['experience']);
    final equipment = (json['equipment'] as List)
        .map((e) => enumFromString(Equipment.values, e))
        .toList();
    final focusAreas = (json['focusAreas'] as List)
        .map((e) => enumFromString(FocusArea.values, e))
        .toList();
    return OnboardingProfile(
      goal: goal,
      experience: experience,
      daysPerWeek: json['daysPerWeek'] as int,
      sessionMinutes: json['sessionMinutes'] as int,
      equipment: equipment,
      focusAreas: focusAreas,
      limitations: (json['limitations'] as List? ?? [])
          .map((e) => e as String)
          .toList(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'goal': enumName(goal),
        'experience': enumName(experience),
        'daysPerWeek': daysPerWeek,
        'sessionMinutes': sessionMinutes,
        'equipment': equipment.map(enumName).toList(),
        'focusAreas': focusAreas.map(enumName).toList(),
        'limitations': limitations,
        'notes': notes,
      };
}

/// The full structured workout plan returned by the AI coach.
class WorkoutPlan {
  const WorkoutPlan({
    required this.schemaVersion,
    required this.planId,
    required this.generatedAt,
    required this.model,
    required this.profile,
    required this.summary,
    required this.weeklySplit,
    required this.days,
    required this.progression,
    required this.safetyNotes,
    required this.disclaimer,
  });

  final String schemaVersion;
  final String planId;
  final DateTime generatedAt;
  final String model;
  final OnboardingProfile profile;
  final String summary;
  final WeeklySplit weeklySplit;
  final List<PlanDay> days;
  final String progression;
  final List<String> safetyNotes;
  final String disclaimer;

  /// The session the app surfaces on the Today tab (first day of the split).
  PlanDay get todaySession => days.first;

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    final days = (json['days'] as List)
        .map((d) => PlanDay.fromJson(d as Map<String, dynamic>))
        .toList();
    return WorkoutPlan(
      schemaVersion: json['schemaVersion'] as String,
      planId: json['planId'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      model: json['model'] as String,
      profile:
          OnboardingProfile.fromJson(json['profile'] as Map<String, dynamic>),
      summary: json['summary'] as String,
      weeklySplit: enumFromString(WeeklySplit.values, json['weeklySplit']),
      days: days,
      progression: json['progression'] as String,
      safetyNotes: (json['safetyNotes'] as List)
          .map((e) => e as String)
          .toList(),
      disclaimer: json['disclaimer'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'planId': planId,
        'generatedAt': generatedAt.toIso8601String(),
        'model': model,
        'profile': profile.toJson(),
        'summary': summary,
        'weeklySplit': enumName(weeklySplit),
        'days': days.map((d) => d.toJson()).toList(),
        'progression': progression,
        'safetyNotes': safetyNotes,
        'disclaimer': disclaimer,
      };
}

class PlanDay {
  const PlanDay({
    required this.dayIndex,
    required this.dayLabel,
    required this.focus,
    this.warmup,
    this.cooldown,
    required this.blocks,
    required this.estimatedMinutes,
  });

  final int dayIndex;
  final String dayLabel;
  final String focus;
  final String? warmup;
  final String? cooldown;
  final List<PlanBlock> blocks;
  final int estimatedMinutes;

  /// Flattened list of every exercise across the day's blocks — used by the
  /// Today view, Plan Runner, and Exercise Detail screens.
  List<PlanExercise> get exercises =>
      blocks.expand((b) => b.exercises).toList();

  factory PlanDay.fromJson(Map<String, dynamic> json) => PlanDay(
        dayIndex: json['dayIndex'] as int,
        dayLabel: json['dayLabel'] as String,
        focus: json['focus'] as String,
        warmup: json['warmup'] as String?,
        cooldown: json['cooldown'] as String?,
        blocks: (json['blocks'] as List)
            .map((b) => PlanBlock.fromJson(b as Map<String, dynamic>))
            .toList(),
        estimatedMinutes: json['estimatedMinutes'] as int,
      );

  Map<String, dynamic> toJson() => {
        'dayIndex': dayIndex,
        'dayLabel': dayLabel,
        'focus': focus,
        'warmup': warmup,
        'cooldown': cooldown,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'estimatedMinutes': estimatedMinutes,
      };
}

class PlanBlock {
  const PlanBlock({
    required this.blockType,
    this.rounds,
    required this.exercises,
  });

  final BlockType blockType;
  final int? rounds;
  final List<PlanExercise> exercises;

  factory PlanBlock.fromJson(Map<String, dynamic> json) => PlanBlock(
        blockType: enumFromString(BlockType.values, json['blockType']),
        rounds: json['rounds'] as int?,
        exercises: (json['exercises'] as List)
            .map((e) => PlanExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'blockType': enumName(blockType),
        'rounds': rounds,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
}

class PlanExercise {
  const PlanExercise({
    required this.exerciseId,
    required this.name,
    required this.equipment,
    required this.muscleGroups,
    required this.sets,
    required this.reps,
    this.weight,
    required this.restSec,
    this.tempo,
    this.notes,
    this.substitutes = const [],
  });

  /// Stable lowercase snake_case slug → exercise library.
  final String exerciseId;
  final String name;
  final Equipment equipment;
  final List<FocusArea> muscleGroups;
  final int sets;

  /// e.g. "8-10", "12", "to failure".
  final String reps;
  final String? weight;
  final int restSec;
  final String? tempo;
  final String? notes;
  final List<String> substitutes;

  factory PlanExercise.fromJson(Map<String, dynamic> json) => PlanExercise(
        exerciseId: json['exerciseId'] as String,
        name: json['name'] as String,
        equipment: enumFromString(Equipment.values, json['equipment']),
        muscleGroups: (json['muscleGroups'] as List)
            .map((e) => enumFromString(FocusArea.values, e))
            .toList(),
        sets: json['sets'] as int,
        reps: json['reps'] as String,
        weight: json['weight'] as String?,
        restSec: json['restSec'] as int,
        tempo: json['tempo'] as String?,
        notes: json['notes'] as String?,
        substitutes: (json['substitutes'] as List? ?? [])
            .map((e) => e as String)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'name': name,
        'equipment': enumName(equipment),
        'muscleGroups': muscleGroups.map(enumName).toList(),
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'restSec': restSec,
        'tempo': tempo,
        'notes': notes,
        'substitutes': substitutes,
      };
}

/// Structured response for conversational chat turns (reference for later
/// OpenRouter wiring; not rendered in M1 UI).
class CoachReply {
  const CoachReply({
    required this.reply,
    required this.planUpdated,
    this.plan,
    this.suggestedActions = const [],
  });

  final String reply;
  final bool planUpdated;
  final WorkoutPlan? plan;
  final List<String> suggestedActions;

  factory CoachReply.fromJson(Map<String, dynamic> json) => CoachReply(
        reply: json['reply'] as String,
        planUpdated: json['planUpdated'] as bool? ?? false,
        plan: json['plan'] == null
            ? null
            : WorkoutPlan.fromJson(json['plan'] as Map<String, dynamic>),
        suggestedActions: (json['suggestedActions'] as List? ?? [])
            .map((e) => e as String)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'reply': reply,
        'planUpdated': planUpdated,
        'plan': plan?.toJson(),
        'suggestedActions': suggestedActions,
      };
}

T enumFromString<T extends Enum>(List<T> values, dynamic value, [T? fallback]) {
  for (final v in values) {
    if (enumName(v) == value) return v;
  }

  if (fallback != null) return fallback;
  throw ArgumentError('Unknown enum value: $value');
}

String enumName(Enum value) => value.toString().split('.').last;
