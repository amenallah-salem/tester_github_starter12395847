# Welora / Gym Planner — Project Guide for Claude

This file is read automatically by Claude Code at the start of a session in
this repo. It explains what the project is, how it's built, and the
conventions to follow when making changes. It does not describe how to run
Docker (see `RUN.md` / `README.md` for that) — it's about how the code fits
together so changes are made consistently.

For *why* the product is built this way — the vision, which features are
real vs. mockups, and product constraints — see `docs/app-idea.md`. Read
both before planning non-trivial work.

## What this project is

A fitness app called **Welora / Gym Planner**, with two independently
deployable parts that talk over a REST API:

- **`backend/`** — Django 5 + Django REST Framework, PostgreSQL. Serves JWT
  auth and a CRUD API for plans, exercises, workout sessions, progress, and
  billing.
- **`frontend/`** — Flutter app (Android/iOS/web/desktop) with a **local-first**
  architecture: a Drift/SQLite database on-device, synced opportunistically
  with the Django API. State is managed with Riverpod, navigation with
  go_router.

Treat these as two codebases that share a data contract (the DRF
serializers ↔ the Dart models / `ApiClient`), not one monolith.

## Backend (`backend/gym_api`)

Stack: Django 5, DRF, `rest_framework_simplejwt`, PostgreSQL 16.

**Core models** (`gym_api/models.py`), all UUID-keyed except join tables:
- `Profile` — 1:1 with Django `User`. Also carries "Gym Bro" social-matching
  fields (`bio`, `training_goals`, `experience_level`, `availability`,
  `location`) and onboarding/locale state.
- `Subscription` — 1:1 billing state per user (`backend/gym_api/billing.py`
  has the stub logic).
- `Plan` → `PlanDay` (weekday 0–6) → `PlanDayExercise` (ordered) → `Exercise`.
  Weekly plan structure, not just a flat list.
- `Exercise` — can belong to a `Plan`+`User` (personal) or be
  `is_library=True` with `user=None` (global library entry, managed via
  Django Admin). Has rich metadata: body part, movement pattern, muscles,
  alternatives/progressions/regressions (self-referential M2M).
- `WorkoutSession` → `ProgressMetric` (per-set logged reps/weight/duration).
- `BodyWeightEntry`, `FavoriteExercise` — simple per-user records.

**Views** (`gym_api/views.py`): one `ModelViewSet` per resource, registered on
a `DefaultRouter` in `gym_api/urls.py`. The consistent pattern:
- `get_queryset()` is always scoped to `self.request.user` — there is no
  endpoint that returns another user's data by default.
- `perform_create()` sets `user=self.request.user` server-side; it is never
  taken from the request body.
- Custom actions use `@action(detail=False/True, methods=[...])`, e.g.
  `ProfileViewSet.me` for `GET /profiles/me/`.
- Auth: JWT via `/auth/token/` and `/auth/token/refresh/`; almost everything
  else requires `IsAuthenticated`. `/health/` and `/auth/register/` are the
  only unauthenticated endpoints.

**Conventions to follow:**
- New user-owned data → new model with a `user = ForeignKey(User, ...)`,
  UUID primary key, `db_table` set explicitly in `Meta`, and a matching
  `ModelViewSet` that filters `get_queryset()` by `request.user`.
- Any model change needs a migration (`python manage.py makemigrations`) —
  don't hand-edit files in `gym_api/migrations/`.
- Add tests in `gym_api/tests.py` (uses plain `TestCase`/`APITestCase`,
  no fixtures/factories library — tests build their own `User`/model
  instances inline).
- Keep serializers in `gym_api/serializers.py` in sync with any model field
  changes — the Flutter side has no fallback if a field silently disappears.

## Frontend (`frontend/lib`)

Stack: Flutter, `flutter_riverpod` (state), `go_router` (nav), `drift` +
`sqlite3_flutter_libs` (local DB), `http` (API calls), `shared_preferences`
(small local flags/tokens).

**Structure — feature-first:**
```
lib/
  core/
    database/       Drift schema + DAOs (local-only source of truth)
    di/              Riverpod providers wiring DB → DAOs → repositories
    router/          go_router config + auth/onboarding redirect logic
    state/           cross-cutting Riverpod state (auth, onboarding)
    theme/           app theming
  features/<name>/
    domain/          plain Dart models / business rules for the feature
    data/             repositories, sample/seed data
    presentation/    widgets & pages
    state/            feature-scoped Riverpod notifiers/providers
  services/
    api_client.dart  the only place that talks HTTP to the Django backend
```
Current features: `auth`, `biomechanics`, `coach`, `exercise_library`,
`gym_bro`, `home`, `onboarding`, `plan`, `plan_runner`, `progress`,
`recovery`, `you`.

**Key architectural point:** the app is **local-first**. Drift (SQLite) is
the primary data store on-device (see `core/database/app_database.dart` and
`core/database/daos/`); the Django API is used for auth, sync, and features
that need a server (e.g. profile/onboarding state, Gym Bro matching,
billing). When adding a feature, decide up front whether it's local-only
(Drift) or server-backed (`ApiClient`) — don't assume every feature needs
both.

**`services/api_client.dart`** is a singleton (`ApiClient.I`) that:
- Picks its base URL by platform (`10.0.2.2:8000` for Android emulator,
  `127.0.0.1:8000` for iOS/desktop, `/api` for web, or `API_BASE_URL` env
  override).
- Auto-refreshes the JWT access token on a 401 and retries once.
- Throws a typed `ApiException` on non-2xx responses — callers should
  catch that, not raw `http` exceptions.
- Every new backend endpoint that the app needs gets one corresponding
  method here, following the existing method shapes (see `fetchProfile`,
  `updateProfile`, etc.).

**Routing:** all routes are registered in one place,
`core/router/app_router.dart`, gated by `authBootstrapProvider` /
`onboardingBootstrapProvider` (redirect logic lives in
`core/router/redirect.dart`). New pages get added here, not via ad hoc
`Navigator.push`.

**State:** Riverpod providers are declared close to what they own —
DB/DAO providers in `core/di/injection.dart`, auth/onboarding in
`core/state/`, everything else feature-local in `features/<name>/state/`.

## Working across the boundary

When a change touches both sides (e.g. a new field on `Profile`):
1. Backend: model field → migration → serializer → (if needed) view logic.
2. Frontend: add/extend the method in `services/api_client.dart` →
   surface it in the relevant `domain` model → wire into `state`/`presentation`.
Keep both sides' shape of the data identical (field names, nullability) —
there's no codegen/schema-sharing between Django and Dart here, so mismatches
fail silently as missing keys, not compile errors.

## Running things

See `README.md` for full Docker instructions. Quick reference:
```bash
docker compose -f docker-compose.backend.dev.yml up --build   # db + Django API on :8000
docker compose -f docker-compose.frontend.dev.yml up --build  # Flutter web on :8080
```
Backend tests: `docker compose exec backend python manage.py test gym_api`
