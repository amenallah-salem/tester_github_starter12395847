/// Loop-free navigation policy for the app router.
///
/// Every rule targets a location that is *stable* for the same auth state,
/// so no combination of flags can produce a redirect cycle like the old
/// `/sign-in` <=> `/` loop (GoException: redirect loop detected).
///
/// Decision table:
/// - signed out                    -> `/sign-in` is the only reachable page
/// - signed in, on `/sign-in`      -> go to `/` (or `/onboarding` if pending)
/// - signed in, onboarding pending -> `/onboarding` is the only reachable page
/// - signed in, onboarding done    -> everything is reachable
String? resolveRedirect({
  required String location,
  required bool signedIn,
  required bool onboardingDone,
}) {
  final onSignIn = location == '/sign-in';
  final onOnboarding = location == '/onboarding';

  // Signed out: only the sign-in page is reachable, and it never redirects.
  if (!signedIn) return onSignIn ? null : '/sign-in';

  // Signed in: never stay on (or bounce back to) the sign-in page.
  if (onSignIn) return onboardingDone ? '/' : '/onboarding';

  // Signed in but onboarding unfinished: onboarding is the only page.
  if (!onboardingDone) return onOnboarding ? null : '/onboarding';

  return null;
}
