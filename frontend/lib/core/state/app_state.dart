import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// True once the user has finished onboarding and a plan exists.
final onboardingDoneProvider = StateProvider<bool>((ref) => false);

final onboardingBootstrapProvider = FutureProvider<void>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  ref.read(onboardingDoneProvider.notifier).state =
      prefs.getBool('onboarding_done') ?? false;
});

Future<void> persistOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_done', true);
}

Future<void> clearPersistedOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('onboarding_done');
}

/// Display name used in greetings. Milestone 1 is local-only (no accounts),
/// so this defaults to the prototype's "Sam" and is editable in the You tab.
final profileNameProvider = StateProvider<String>((ref) => 'Sam');

/// Live connectivity, used to show the global offline banner (TES-6 §4).
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged;
});

/// User-controlled theme mode (light / dark). Defaults to system.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

/// Convenience: true when the device has no network connection.
final isOfflineProvider = Provider<bool>((ref) {
  final result = ref.watch(connectivityProvider);
  return result.when(
    data: (r) => r.contains(ConnectivityResult.none),
    loading: () => false,
    error: (_, __) => false,
  );
});
