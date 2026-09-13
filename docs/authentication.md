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

## Social sign-in: Continue with Google / Continue with Apple

Adds one-tap social auth on top of the existing JWT session — a successful
Google/Apple exchange returns the exact same `{'user', 'access', 'refresh'}`
shape as `/api/auth/register/`/`/api/auth/token/`, so everything above
(storage, refresh, logout, onboarding redirect) applies unchanged.

### Backend

- **`SocialAccount`** model (`gym_api/models.py`) links `(provider,
  provider_user_id)` — the provider's durable subject id, not email — to a
  Django `User`. `provider_user_id` is what's trusted long-term; email is
  only captured at link time (Apple private-relay emails, or an email
  changed later, must not break the link).
- **`POST /api/auth/google/`** (`GoogleAuthView`) and **`POST
  /api/auth/apple/`** (`AppleAuthView`) accept `id_token` /
  `identity_token` respectively. The credential is verified **server-side**
  before anything is trusted:
  - Google: `google.oauth2.id_token.verify_oauth2_token`, then the `aud`
    claim is checked against `settings.GOOGLE_OAUTH_CLIENT_IDS` (a
    comma-separated env var — Google issues a distinct client id per
    platform, so all of Web/Android/iOS must be listed).
  - Apple: `PyJWKClient('https://appleid.apple.com/auth/keys')` +
    `jwt.decode(..., algorithms=['RS256'], audience=settings.APPLE_BUNDLE_ID,
    issuer='https://appleid.apple.com')`.
  - Client-supplied name/email fields are never used to decide identity —
    only the verified claims are.
- **`find_or_create_social_user`** (`gym_api/views.py`) resolution order:
  1. An existing `SocialAccount` for `(provider, subject)` → that user
     (returning social user, 200).
  2. No match, but the provider asserts a **verified** email matching an
     existing `User.email` → auto-link a new `SocialAccount` to that user
     and sign them in (200). No password confirmation — the provider has
     already proven ownership of the email. An **unverified** email match
     is rejected (400) rather than silently linked or duplicated.
  3. No match at all → create a new `User` (unusable password via
     `create_user(..., password=None)`), provision it exactly like email
     signup (`_provision_new_user`: `Profile.objects.get_or_create` +
     starter "Starter Week" plan), link the `SocialAccount`, sign in (201).
- `_provision_new_user` is shared with `RegisterView` (extracted from its
  previous inline block) and is idempotent — a returning social user being
  linked never gets a second starter plan.
- New env vars: `GOOGLE_OAUTH_CLIENT_IDS`, `APPLE_BUNDLE_ID` (see
  `.env.dev.example`). New dependencies: `google-auth`, `PyJWT[crypto]`,
  `requests`.

### Frontend

- `frontend/lib/services/social_auth_service.dart` wraps `google_sign_in` /
  `sign_in_with_apple`, returning a plugin-agnostic `SocialAuthResult` (raw
  token + Apple's one-time name fields) so `sign_in_page.dart` and
  `ApiClient` never touch plugin types.
- `ApiClient.loginWithGoogle` / `loginWithApple` POST to the endpoints above
  and return the same shape `login()`/`register()` already produce.
- `sign_in_page.dart` adds "Continue with Google" (all platforms) and
  "Continue with Apple" (gated to `defaultTargetPlatform ==
  TargetPlatform.iOS` — **not** `dart:io Platform`, which throws on web) next
  to the existing email/password form. All three paths (email, Google, Apple)
  now funnel through one shared `_onAuthSuccess` handler.
- **Apple Sign In is iOS-only in this implementation.** Android/Web would
  additionally require a paid Apple Developer **Services ID** (not an App
  ID), a registered redirect URI, and Apple's web JS SDK — none of that is
  wired up here.

### Manual platform configuration (not automatable from code)

- **Google Cloud Console**: create OAuth 2.0 client IDs for Web, Android
  (needs the debug/release keystore SHA-1:
  `keytool -list -v -keystore ~/.android/debug.keystore`), and iOS (bundle id
  `com.tes2.gymApp`). Put all of them, comma-separated, into
  `GOOGLE_OAUTH_CLIENT_IDS`.
- **Android**: configure `google_sign_in`'s Android setup (current plugin
  docs) so `applicationId com.tes2.gym_app` matches the registered client.
- **iOS**: add the reversed-client-id URL scheme to `Info.plist`; in Xcode,
  enable the "Sign in with Apple" capability for the `com.tes2.gymApp`
  target and register Sign in with Apple for that App ID in the Apple
  Developer portal. Set `APPLE_BUNDLE_ID=com.tes2.gymApp`.
- **Web**: register authorized JavaScript origins for the Web OAuth client
  and pass that client id as `webClientId` to
  `SocialAuthService.signInWithGoogle`.

### Verification performed

- Backend: `python manage.py test gym_api` — 72/72 pass, including 10 new
  `SocialAuthTests` (new-user creation, returning-user login, auto-link to a
  pre-existing verified-email user, rejection of an unverified-email match,
  invalid-token rejection — Google and Apple) plus all pre-existing
  `AuthenticationTests`/registration tests unchanged (regression check on the
  `_provision_new_user` extraction).
- `makemigrations`/`migrate` applied cleanly against the dev Postgres
  database (`gym_api/migrations/0023_socialaccount.py`).
- `flutter pub get` resolved `google_sign_in`/`sign_in_with_apple` with no
  conflicts; `flutter analyze` — no new issues introduced (only pre-existing
  lints elsewhere in the codebase).
- Not verified (requires accounts this environment doesn't have): a real
  OAuth handshake against live Google/Apple consent screens, which needs the
  manual console setup above completed first.
