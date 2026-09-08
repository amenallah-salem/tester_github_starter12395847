import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gym_app/core/router/app_router.dart';
import 'package:gym_app/core/state/app_state.dart';
import 'package:gym_app/core/state/auth_state.dart';
import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/core/di/injection.dart';

class GymApp extends ConsumerWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    // Auth/onboarding restoration must finish before any route (including
    // Sign In) is shown — otherwise the app renders whatever route it starts
    // on for that brief window, which on the web is indistinguishable from
    // "you've been signed out". This keeps AUTHENTICATION_CHECKING as its
    // own visible state instead of defaulting to "unauthenticated" while the
    // real answer is still loading.
    final authReady = ref.watch(authBootstrapProvider);
    if (authReady.isLoading) {
      return const _BootstrapApp();
    }
    final onboardingReady = ref.watch(onboardingBootstrapProvider);
    if (onboardingReady.isLoading) {
      return const _BootstrapApp();
    }

    ref.watch(seedProvider); // seed local exercise library on first launch
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Train in the Gym — Your Pocket Trainer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

/// Shown only while restoring a persisted session on app startup — never a
/// stand-in for "signed out".
class _BootstrapApp extends StatelessWidget {
  const _BootstrapApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
