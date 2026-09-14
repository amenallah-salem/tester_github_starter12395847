import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gym_app/features/plan/data/sample_plan.dart';
import 'package:gym_app/features/plan/domain/plan_contract.dart';
import 'package:gym_app/features/plan/domain/plan_validator.dart';
import 'package:gym_app/core/database/app_database.dart';
import 'package:gym_app/core/di/injection.dart';
import 'package:gym_app/services/api_client.dart';

/// Holds the current AI-generated training plan. Mirrors the async nature of
/// plan generation so the UI can render generating / empty / failed states
/// exactly as the design spec (TES-6 §4) requires.
///
/// State machine:
/// - `AsyncLoading`            → "We're crafting your plan…" / shimmer
/// - `AsyncError`             → "Something tripped up… Retry?"
/// - `AsyncData(null)`        → no plan yet (empty)
/// - `AsyncData(plan)`        → plan rendered on Today
///
/// On launch it re-hydrates the last cached, contract-valid plan from Drift;
/// new plans are validated against the contract before they are cached or
/// rendered.
class PlanNotifier extends Notifier<AsyncValue<WorkoutPlan?>> {
  @override
  AsyncValue<WorkoutPlan?> build() {
    if (kIsWeb) return AsyncData(samplePlan);
    _init();
    return const AsyncLoading();
  }

  void _init() {
    Future<void>(() async {
      final dao = ref.read(planDaoProvider);
      final cached = await dao.getLatest();
      if (cached == null) {
        state = const AsyncData(null);
        return;
      }
      try {
        state = AsyncData(validatePlanJson(cached.json));
      } catch (_) {
        // Stale/corrupt cache — fall back to empty so the user can regenerate.
        state = const AsyncData(null);
      }
    });
  }

  Future<void> _cacheAndEmit(WorkoutPlan plan) async {
    // Guard: never render a plan that fails the contract.
    final raw = jsonEncode(plan.toJson());
    final validated = validatePlanJson(raw);
    state = AsyncData(validated);
    final dao = ref.read(planDaoProvider);
    unawaited(
      dao
          .upsert(
        CachedPlansCompanion.insert(
          planId: validated.planId,
          schemaVersion: validated.schemaVersion,
          json: raw,
          updatedAt: DateTime.now(),
        ),
      )
          .catchError((error, stackTrace) {
        debugPrint('Unable to cache generated plan: $error');
      }),
    );
  }

  /// First-run generation triggered from onboarding. When the wizard's
  /// answers are passed in, the sample template is personalized to them
  /// (goal, experience, day count, equipment) instead of always returning
  /// the same static plan regardless of what the user picked. Called with
  /// no arguments (e.g. the "Generate a plan" CTA on an empty Today view)
  /// it still falls back to the generic sample.
  Future<void> generatePlan({
    Goal? goal,
    Experience? experience,
    int? daysPerWeek,
    List<Equipment>? equipment,
    List<FocusArea>? focusAreas,
  }) async {
    state = const AsyncLoading();
    await Future.delayed(const Duration(milliseconds: 1600));
    final hasAnswers = goal != null ||
        experience != null ||
        daysPerWeek != null ||
        equipment != null ||
        focusAreas != null;
    final plan = hasAnswers
        ? _personalizedPlan(
            goal: goal ?? samplePlan.profile.goal,
            experience: experience ?? samplePlan.profile.experience,
            daysPerWeek: daysPerWeek ?? samplePlan.profile.daysPerWeek,
            equipment: (equipment == null || equipment.isEmpty)
                ? samplePlan.profile.equipment
                : equipment,
            focusAreas: (focusAreas == null || focusAreas.isEmpty)
                ? samplePlan.profile.focusAreas
                : focusAreas,
          )
        : samplePlan;
    try {
      await _cacheAndEmit(plan);
    } catch (error) {
      state = AsyncData(plan);
      debugPrint('Unable to persist generated plan: $error');
    }
  }

  /// Adapts the sample day template to the onboarding answers: swaps
  /// equipment-only exercises for their bodyweight substitute when the user
  /// picked bodyweight-only training, and repeats the (adapted) day across
  /// the chosen days-per-week so the profile/summary the user sees actually
  /// reflects what they picked. The exercise *content* is still drawn from
  /// one starter template — real per-day exercise selection by goal is a
  /// bigger, non-48h build (see launch plan P2: real AI plan generation).
  WorkoutPlan _personalizedPlan({
    required Goal goal,
    required Experience experience,
    required int daysPerWeek,
    required List<Equipment> equipment,
    required List<FocusArea> focusAreas,
  }) {
    final bodyweightOnly =
        equipment.length == 1 && equipment.single == Equipment.bodyweight;
    final template = samplePlan.days.first;

    PlanExercise adapt(PlanExercise exercise) {
      if (!bodyweightOnly ||
          exercise.equipment == Equipment.bodyweight ||
          exercise.substitutes.isEmpty) {
        return exercise;
      }
      final substituteId = exercise.substitutes.first;
      return PlanExercise(
        exerciseId: substituteId,
        name: substituteId
            .split('_')
            .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' '),
        equipment: Equipment.bodyweight,
        muscleGroups: exercise.muscleGroups,
        sets: exercise.sets,
        reps: exercise.reps,
        weight: 'bodyweight',
        isTimed: exercise.isTimed,
        restSec: exercise.restSec,
        tempo: exercise.tempo,
        notes: exercise.notes,
      );
    }

    final adaptedBlocks = template.blocks
        .map((block) => PlanBlock(
              blockType: block.blockType,
              rounds: block.rounds,
              exercises: block.exercises.map(adapt).toList(),
            ))
        .toList();

    final focusLabel = focusAreas.isEmpty
        ? template.focus
        : focusAreas.map(enumLabel).join(' + ');

    final days = List.generate(daysPerWeek, (i) {
      return PlanDay(
        dayIndex: i + 1,
        dayLabel: 'Day ${String.fromCharCode(65 + i)}',
        focus: focusLabel,
        warmup: template.warmup,
        cooldown: template.cooldown,
        blocks: adaptedBlocks,
        estimatedMinutes: template.estimatedMinutes,
      );
    });

    return WorkoutPlan(
      schemaVersion: samplePlan.schemaVersion,
      planId: 'onboarding-${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now().toUtc(),
      model: samplePlan.model,
      profile: OnboardingProfile(
        goal: goal,
        experience: experience,
        daysPerWeek: daysPerWeek,
        sessionMinutes: template.estimatedMinutes,
        equipment: equipment,
        focusAreas: focusAreas,
      ),
      summary:
          '${enumLabel(goal)} · $daysPerWeek day${daysPerWeek == 1 ? '' : 's'} a week, $focusLabel focus.',
      weeklySplit: samplePlan.weeklySplit,
      days: days,
      progression: samplePlan.progression,
      safetyNotes: samplePlan.safetyNotes,
      disclaimer: samplePlan.disclaimer,
    );
  }

  /// "Regenerate plan" from the Today view.
  Future<void> regeneratePlan() async {
    state = const AsyncLoading();
    await Future.delayed(const Duration(milliseconds: 1200));
    await _cacheAndEmit(samplePlan);
  }

  /// Hydrates the contract used by the UI from the authenticated Django plan.
  Future<void> refreshFromApi() async {
    if (ApiClient.I.accessToken == null) return;
    try {
      final remote = await ApiClient.I.fetchCurrentPlan();
      if (remote == null) return;
      final week = remote['week'] as Map<String, dynamic>?;
      final todayIndex = DateTime.now().weekday - 1;
      final days = (week?['days'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      final today = days.cast<Map<String, dynamic>?>().firstWhere(
            (day) => day?['weekday'] == todayIndex,
            orElse: () => null,
          );
      final assignments = (today?['assignments'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      final exercises = assignments
          .map(
            (assignment) => <String, dynamic>{
              'id': assignment['exercise'],
              'name': assignment['exercise_name'],
              'target_sets': 3,
              'target_reps': 10,
            },
          )
          .toList();
      if (exercises.isEmpty) return;
      final dayExercises = exercises
          .map(
            (e) => PlanExercise(
              exerciseId: e['id'].toString(),
              name: e['name'] as String,
              equipment: Equipment.bodyweight,
              muscleGroups: const [FocusArea.fullBody],
              sets: (e['target_sets'] as num?)?.toInt() ?? 3,
              reps: '${(e['target_reps'] as num?)?.toInt() ?? 10}',
              weight: e['target_weight_kg']?.toString(),
              restSec: 60,
              notes: e['description'] as String?,
            ),
          )
          .toList();
      final plan = WorkoutPlan(
        schemaVersion: '1.0',
        planId: remote['id'].toString(),
        generatedAt: DateTime.now().toUtc(),
        model: 'django',
        profile: const OnboardingProfile(
          goal: Goal.general,
          experience: Experience.beginner,
          daysPerWeek: 3,
          sessionMinutes: 35,
          equipment: [Equipment.bodyweight],
          focusAreas: [FocusArea.fullBody],
        ),
        summary: remote['description'] as String? ?? remote['name'] as String,
        weeklySplit: WeeklySplit.fullBody,
        days: [
          PlanDay(
            dayIndex: 1,
            dayLabel: remote['name'] as String,
            focus: 'Full Body',
            blocks: [
              PlanBlock(blockType: BlockType.straight, exercises: dayExercises),
            ],
            estimatedMinutes: 35,
          ),
        ],
        progression: 'Progress gradually while maintaining good form.',
        safetyNotes: const ['Stop if you feel sharp pain.'],
        disclaimer: 'Training guidance is not medical advice.',
      );
      await _cacheAndEmit(plan);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

final planNotifierProvider =
    NotifierProvider<PlanNotifier, AsyncValue<WorkoutPlan?>>(PlanNotifier.new);
