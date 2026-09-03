import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gym_app/features/plan/data/sample_plan.dart';
import 'package:gym_app/features/plan/domain/plan_contract.dart';
import 'package:gym_app/features/plan/domain/plan_validator.dart';
import 'package:gym_app/core/database/app_database.dart';
import 'package:gym_app/core/di/injection.dart';

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
    final dao = ref.read(planDaoProvider);
    await dao.upsert(
      CachedPlansCompanion.insert(
        planId: validated.planId,
        schemaVersion: validated.schemaVersion,
        json: raw,
        updatedAt: DateTime.now(),
      ),
    );
    state = AsyncData(validated);
  }

  /// First-run generation triggered from onboarding.
  Future<void> generatePlan() async {
    state = const AsyncLoading();
    await Future.delayed(const Duration(milliseconds: 1600));
    await _cacheAndEmit(samplePlan);
  }

  /// "Regenerate plan" from the Today view.
  Future<void> regeneratePlan() async {
    state = const AsyncLoading();
    await Future.delayed(const Duration(milliseconds: 1200));
    await _cacheAndEmit(samplePlan);
  }
}

final planNotifierProvider =
    NotifierProvider<PlanNotifier, AsyncValue<WorkoutPlan?>>(
  PlanNotifier.new,
);
