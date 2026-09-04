import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/features/home/presentation/home_page.dart';
import 'package:gym_app/features/onboarding/presentation/onboarding_page.dart';
import 'package:gym_app/features/plan/presentation/plan_page.dart';
import 'package:gym_app/features/plan_runner/presentation/plan_runner_page.dart';
import 'package:gym_app/features/exercise_library/presentation/exercise_detail_page.dart';
import 'package:gym_app/features/exercise_library/presentation/muscle_filter_bar.dart';
import 'package:gym_app/features/progress/presentation/progress_page.dart';
import 'package:gym_app/features/you/presentation/you_page.dart';
import 'package:gym_app/features/auth/presentation/sign_in_page.dart';
import 'package:gym_app/features/recovery/presentation/recovery_page.dart';
import 'package:gym_app/features/plan_runner/presentation/workout_setup_page.dart';
import 'package:gym_app/features/biomechanics/presentation/form_vault_page.dart';
import 'package:gym_app/features/biomechanics/presentation/replay_3d_page.dart';
import 'package:gym_app/core/state/app_state.dart';
import 'package:gym_app/core/state/auth_state.dart';

/// App navigation — Welora routes.
final appRouterProvider = Provider<GoRouter>((ref) {
  final accessToken = ref.watch(accessTokenProvider);
  return GoRouter(
    initialLocation: '/sign-in',
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInPage(),
      ),
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
      // Welora new routes
      GoRoute(
        path: '/explorer',
        builder: (context, state) => const ExerciseExplorerPage(),
      ),
      GoRoute(
        path: '/vault',
        builder: (context, state) => const FormVaultPage(),
      ),
      GoRoute(
        path: '/replay/:id',
        builder: (context, state) => const ReplayPage3D(),
      ),
      GoRoute(
        path: '/recovery',
        builder: (context, state) => const RecoveryPage(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const WorkoutSetupPage(),
      ),
    ],
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final done = ref.read(onboardingDoneProvider);
      if (accessToken == null && loc != '/sign-in') return '/sign-in';
      if (accessToken != null && loc == '/sign-in')
        return done ? '/' : '/onboarding';
      // After onboarding completes, stay inside app for all non-auth routes.
      if (loc == '/sign-in' && done) return '/';
      if (!done &&
          !loc.startsWith('/sign-in') &&
          !loc.startsWith('/onboarding')) {
        return '/onboarding';
      }
      return null;
    },
  );
});

// Exercise Explorer page with muscle-group filter (Stitch: welora_exercise_library_filter)
class ExerciseExplorerPage extends ConsumerStatefulWidget {
  const ExerciseExplorerPage({super.key});
  @override
  ConsumerState<ExerciseExplorerPage> createState() =>
      _ExerciseExplorerPageState();
}

class _ExerciseExplorerPageState extends ConsumerState<ExerciseExplorerPage> {
  String? _selectedMuscle;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Explorer')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: MuscleFilterBar(
              selected: _selectedMuscle,
              onSelect: (v) => setState(() => _selectedMuscle = v),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                ListTile(
                    title: Text('Goblet Squat'),
                    subtitle: Text('Quads · Dumbbell')),
                ListTile(
                    title: Text('Push-Up'),
                    subtitle: Text('Chest · Bodyweight')),
                ListTile(
                    title: Text('Barbell Squat'),
                    subtitle: Text('Legs · Barbell')),
                ListTile(
                    title: Text('Bench Press'),
                    subtitle: Text('Chest · Barbell')),
                ListTile(
                    title: Text('Dumbbell Row'),
                    subtitle: Text('Back · Dumbbell')),
                ListTile(
                    title: Text('Plank'), subtitle: Text('Core · Bodyweight')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
