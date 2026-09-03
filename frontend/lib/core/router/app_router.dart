import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/features/home/presentation/home_page.dart';
import 'package:gym_app/features/onboarding/presentation/onboarding_page.dart';
import 'package:gym_app/features/plan/presentation/plan_page.dart';
import 'package:gym_app/features/plan_runner/presentation/plan_runner_page.dart';
import 'package:gym_app/features/exercise_library/presentation/exercise_detail_page.dart';
import 'package:gym_app/features/progress/presentation/progress_page.dart';
import 'package:gym_app/features/you/presentation/you_page.dart';
import 'package:gym_app/core/state/app_state.dart';

/// App navigation.
///
/// - Pre-plan: full-screen [OnboardingPage] (no chrome).
/// - Post-plan: bottom tab bar with 3 tabs (Today / Progress / You).
/// - Plan Runner is a **modal, full-screen overlay** outside the shell, so it
///   hides the tab bar (TES-6 §2). Exercise Detail is pushed from the Runner
///   or a plan card.
final appRouterProvider = Provider<GoRouter>((ref) {
  final onboardingDone = ref.watch(onboardingDoneProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            HomePage(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const PlanPage(),
          ),
          GoRoute(
            path: '/progress',
            builder: (context, state) => const ProgressPage(),
          ),
          GoRoute(
            path: '/you',
            builder: (context, state) => const YouPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/run',
        builder: (context, state) => const PlanRunnerPage(),
      ),
      GoRoute(
        path: '/exercise/:id',
        builder: (context, state) => ExerciseDetailPage(
          exerciseId: state.pathParameters['id']!,
        ),
      ),
    ],
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (!onboardingDone) {
        return loc.startsWith('/onboarding') ? null : '/onboarding';
      }
      if (loc.startsWith('/onboarding')) return '/';
      return null;
    },
  );
});
