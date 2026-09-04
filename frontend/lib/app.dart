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
    ref.watch(authBootstrapProvider);
    ref.watch(onboardingBootstrapProvider);
    ref.watch(seedProvider); // seed local exercise library on first launch
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
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
