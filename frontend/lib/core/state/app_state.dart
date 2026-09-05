import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' show PlatformDispatcher;
import 'package:gym_app/services/api_client.dart';
import 'package:gym_app/core/state/auth_state.dart';

/// True once the user has finished onboarding and a plan exists.
final onboardingDoneProvider = StateProvider<bool>((ref) => false);

final onboardingBootstrapProvider = FutureProvider<void>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  // Default from local pref
  var locallyDone = prefs.getBool('onboarding_done') ?? false;

  // If authenticated, prefer server-side canonical value and sync to prefs.
  final access = ref.read(accessTokenProvider);
  if (access != null && access.isNotEmpty) {
    try {
      final profile = await ApiClient.I.fetchProfile();
      final serverDone = profile['onboarding_completed'] == true;
      locallyDone = serverDone;
      await prefs.setBool('onboarding_done', serverDone);
      // also persist locale/country locally if present
      final locale = profile['locale'] as String?;
      final country = profile['country'] as String?;
      if (locale != null && locale.isNotEmpty) await prefs.setString('locale', locale);
      if (country != null && country.isNotEmpty) await prefs.setString('country', country);

      // If server lacks locale/country, try to detect device locale and update the profile
      if ((locale == null || locale.isEmpty) && ApiClient.I.accessToken != null) {
        try {
          final deviceLocale = PlatformDispatcher.instance.locale;
          final detected = deviceLocale.toLanguageTag();
          final detectedCountry = deviceLocale.countryCode ?? '';
          var id = profile['id']?.toString();
          if (id == null) {
            id = profile['id']?.toString();
          }
          if (id != null) {
            await ApiClient.I.updateProfile(id, {'locale': detected, 'country': detectedCountry});
            await prefs.setString('locale', detected);
            if (detectedCountry.isNotEmpty) await prefs.setString('country', detectedCountry);
          }
        } catch (_) {
          // ignore detection/update failure
        }
      }
    } catch (_) {
      // ignore – fallback to local pref if fetch fails
    }
  }

  ref.read(onboardingDoneProvider.notifier).state = locallyDone;
});

Future<void> persistOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_done', true);

  // If authenticated, update server-side profile as well.
  final profileId = prefs.getString('profile_id');
  try {
    if (ApiClient.I.accessToken != null) {
      // If we don't know the profile id, fetch it first
      var id = profileId;
      if (id == null) {
        final profile = await ApiClient.I.fetchProfile();
        id = profile['id']?.toString();
        if (id != null) await prefs.setString('profile_id', id);
      }
      if (id != null) {
        await ApiClient.I.updateProfile(id, {'onboarding_completed': true});
      }
    }
  } catch (_) {
    // ignore errors – we already persisted locally
  }
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
