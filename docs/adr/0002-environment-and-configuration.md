# ADR 0002 — Environment/configuration mechanism for the API base URL

- **Status:** Accepted
- **Date:** 2026-08-29
- **Owner:** CTO (with Frontend Lead, Backend Lead, DevOps Lead)
- **Relates to:** SIW-6 §4, §24, §25; `docs/environments.md`

## Context

SIW-6 §4 mandates the API base URL be configurable **without source changes**, support
development (`http://<laptop-lan-ip>:8000/api/v1`), staging, and production, and never hardcode
`localhost`/`127.0.0.1` (a physical phone's `localhost` is itself). Both a Flutter app and a
Django backend must mirror the same dev/staging/prod worlds.

## Decision

### Flutter

1. **Primary mechanism: `--dart-define=API_BASE_URL=<url>`.** Build-time compile constant, the
   standard Flutter way to inject environment at build/run time. Highest precedence, no source
   edit.
2. **Flavor defaults:** `development` / `staging` / `production` flavors (Android + iOS) carry
   conventional default values so bare `flutter run --flavor development` works.
3. **No localhost fallback.** `String.fromEnvironment('API_BASE_URL')` empty → hard startup
   error, so a wrong/missing config fails loudly instead of silently hitting the phone itself.
4. Rejected: runtime dotenv in Dart (no runtime env; contradicts build-time model), hardcoded
   constants in source, Kotlin/Swift-side `BuildConfig` only (loses D-dart uniformity across
   platforms), and Firebase Remote Config for something as load-bearing as the API root.

### Backend

5. **Settings split per environment** selected by `DJANGO_ENV`, values from environment
   variables/`.env` via `django-environ`. `ALLOWED_HOSTS`, `CORS`, `DEBUG`, and `SECRET_KEY`
   derive per environment (see `docs/environments.md`).
6. Rejected: one monolithic settings file with `if DEBUG` branches (unreviewable), and baking
   secrets into repo config.

## Consequences

- **Positive:** matches Flutter/Django ecosystem norms; peer-reviewed by Frontend/Backend leads;
  a physical phone + laptop workflow is one command; CI builds per-environment using the same
  switches.
- **Negative:** build-time injection means env can't change without rebuilding an already-installed
  app (acceptable — standard for mobile); dev LAN IP must be supplied per run (helper script
  resolves it).
- **Rollback:** a flavor/config change is a tiny PR; nothing in the data layer depends on it.