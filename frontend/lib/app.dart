import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gym_app/core/router/app_router.dart';
import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/core/di/injection.dart';

class GymApp extends ConsumerWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(seedProvider); // seed local exercise library on first launch
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'tes2 — Train in the Gym',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
