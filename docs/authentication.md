# Authentication Persistence

This documents the JWT authentication architecture (Django + DRF SimpleJWT,
one Flutter codebase for web/iOS/Android) and the fix for the bug where
refreshing the web app sent a signed-in user back to Sign In.

## Root cause

The app already restored a persisted JWT on startup (`authBootstrapProvider`
in `frontend/lib/core/state/auth_state.dart` reads `access_token` /
`refresh_token` from storage and refreshes if needed) — the persistence
mechanism itself was not missing. The bug was in the router:

`app_router.dart` built the `GoRouter` with `initialLocation: '/sign-in'`.
go_router only honors `initialLocation` when the platform's *actual* current
location is `/` (see `GoRouter._effectiveInitialLocation`); otherwise it uses
the real browser path. Since Home is mounted at `/` in this app, refreshing
the browser while on Home reported a platform location of `/`, so go_router
started on `/sign-in` regardless of auth state — while `authBootstrapProvider`
was still resolving asynchronously, `redirect()` intentionally did nothing
(to avoid guessing "not loaded yet" = "logged out"), so the Sign In page was
the actual first frame rendered, every time. This matches the anti-pattern of
starting the UI in an unauthenticated-looking state before checking whether a
session already exists.

## Fix

- **`frontend/lib/app.dart`**: added an explicit `AUTHENTICATION_CHECKING`
  render state. While `authBootstrapProvider`/`onboardingBootstrapProvider`
  are loading, the app shows a bare loading screen (`_BootstrapApp`) instead
  of mounting the router at all — so no route (Sign In included) is ever the
  visible "default" during restoration.
- **`frontend/lib/core/router/app_router.dart`**: removed the hardcoded
  `initialLocation`. go_router now always starts from the real platform
  location (current browser URL on web, deep link on mobile), so a refresh on
  any page — not just Home — stays on that page once auth is confirmed.
- **`frontend/lib/core/state/auth_state.dart`**: added `AuthStatus`
  (`checking` / `authenticated` / `unauthenticated`) as an explicit tri-state
  provider instead of inferring auth from "is the token loaded yet".
- **`frontend/lib/core/state/app_state.dart`**: `onboardingBootstrapProvider`
  now awaits `authBootstrapProvider.future` before reading
  `accessTokenProvider` — previously the two bootstrap futures ran
  concurrently and the onboarding check frequently read the access token
  before it was restored, silently skipping the server-side onboarding sync.

## Session lifetime and refresh

Unchanged architecture (JWT bearer tokens, `rest_framework_simplejwt`), tuned
lifetimes:

- Access token: 60 minutes (`SIMPLE_JWT['ACCESS_TOKEN_LIFETIME']`).
- Refresh token: 30 days (`SIMPLE_JWT['REFRESH_TOKEN_LIFETIME']`), rotated on
  every use (`ROTATE_REFRESH_TOKENS`) and blacklisted after rotation
  (`BLACKLIST_AFTER_ROTATION`), backed by the newly-enabled
  `rest_framework_simplejwt.token_blacklist` app.

`ApiClient._send` already retried a 401 once via `/auth/token/refresh/`
before this change; that's untouched. What's new is `ApiClient.onSessionExpired`
— invoked when a 401 survives that refresh attempt (refresh token missing,
expired, or blacklisted). It's wired once in `authBootstrapProvider` to clear
in-memory tokens and persisted storage, which is what lets `redirect()`
correctly send the user to Sign In only when the session is genuinely
unrecoverable (section 10 of the request), rather than on every transient
error.

## Logout

`POST /api/auth/logout/` (`gym_api.views.LogoutView`) blacklists the supplied
refresh token server-side — the JWT equivalent of Django's session `logout()`
clearing session data, since a stateless access token itself can't be
revoked. The client-side `logout(ref)` helper in `auth_state.dart` is the one
place that performs a full sign-out: calls that endpoint (best-effort),
clears `accessTokenProvider`/`refreshTokenProvider`/`currentUsernameProvider`,
and clears persisted storage. `you_page.dart`'s "Sign out" button now calls
this instead of duplicating the clearing logic inline.

## Storage

- **Access token, username**: `shared_preferences` (unchanged) — short-lived,
  low sensitivity.
- **Refresh token**: `flutter_secure_storage` (iOS Keychain / Android
  Keystore) on mobile; `shared_preferences` on web, since Flutter Web has no
  OS-level secure storage backend (the web implementation of
  `flutter_secure_storage` is itself just `localStorage`, so there's no
  security gained by adding the extra dependency there).
- No password is ever persisted anywhere on the client.
- Cookies/CSRF/CORS are not part of this architecture: the web build is
  served by nginx (`frontend/nginx.conf`), which proxies `/api/` to the
  Django backend same-origin, so there are no cross-origin cookies to
  configure — this was verified, not changed.

## Verification performed

- Backend: `python manage.py test gym_api` — 46/46 pass, including 7 new
  `AuthenticationTests` covering login, wrong password, authenticated
  request, refresh, logout-blacklists-refresh, logout-requires-auth, and
  invalid-token rejection.
- Live API check against the running dev stack: register → login →
  authenticated `/api/profiles/me/` (200) → refresh (200) → logout (205) →
  reusing the blacklisted refresh token now returns 401
  `{"detail":"Token is blacklisted"}`.
- Regression check: `/api/library/exercises/` and
  `/api/library/exercises/?body_part=Chest` still return 200 (exercise
  library filter contract untouched).
- `flutter analyze` — no new issues introduced (only pre-existing lints
  elsewhere in the codebase).
- `flutter build web --release` — builds successfully with
  `flutter_secure_storage` added.
