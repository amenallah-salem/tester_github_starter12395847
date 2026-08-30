# Backend Architecture — AI Gym Assistant

> **Task:** T-05 (SIW-11) · **Owner:** Backend Lead · **Applies to:** T-09, T-12, T-13, T-14, T-17, T-18, T-20, T-21, T-22, T-24, T-26, T-27, T-31
> Companion docs: [data-model.md](data-model.md) · [decisions.md](decisions.md)

---

## 1. Stack summary

| Concern        | Choice                                                        | Why |
| -------------- | ------------------------------------------------------------- | --- |
| Language       | Python 3.12+                                                  | Django/DRF ecosystem maturity |
| Web framework  | Django 5.x                                                    | Admin, ORM, migrations, security defaults |
| API framework  | Django REST Framework 3.15+                                   | Pluggable auth/permissions, ViewSets, serializers |
| Database       | PostgreSQL 16 (see [decisions.md](decisions.md) ADR-0001)      | Relational integrity, JSONB, full-text, managed parity dev/prod |
| Auth           | `djangorestframework-simplejwt` (see ADR-0002)                | JWT access/refresh with blacklist |
| API versioning | URL path `/api/v1/` (see ADR-0003)                            | Stable contract for Flutter, OpenAPI-per-version |
| OpenAPI        | `drf-spectacular`                                             | Generated schema + Swagger UI, single source of truth |
| Settings/env   | `django-environ`, tiered settings (dev/staging/prod)          | 12-factor; no secrets/URLs in code |
| Search         | Postgres full-text (`SearchVector`/`GinIndex`) + `pg_trgm`    | Server-side, no extra engine for MVP |
| Caching        | Django cache framework (Redis in prod, locmem in dev)         | Tokens/CORS-free reads, dashboard aggregates |
| Testing        | `pytest` + `pytest-django`, factories                          | Fast, isolated, CI-friendly |
| Deployment     | Docker + `gunicorn` + Docker Compose                          | §24; dev/prod parity |

---

## 2. Repository layout (monorepo, per plan §4)

Planned layout implemented by T-04/T-09 (this doc defines the backend portion):

```
/
  backend/
    config/                  # Django project root (NOT "project" ambiguity)
      settings/              # base.py, development.py, staging.py, production.py
      urls.py                # mounts /api/v1/, /admin/, schema, health
      wsgi.py  asgi.py
    apps/
      accounts/              # custom User, auth, password flows, Subscription
      profiles/              # UserProfile, Goal, TrainingPreference
      content/               # Exercise, MuscleGroup, Equipment, media, alternatives
      training/              # TrainingPlan, PlanDay, Workout, WorkoutExercise, WorkoutSet
      sessions/              # WorkoutSession, SessionExercise, SessionSet, WorkoutNote
      progress/              # BodyMeasurement, PersonalRecord, ProgressMetric
      notifications/         # Notification, NotificationPreference
      admin/                 # admin registrations for every content model
      analytics/             # AnalyticsEvent (ingestion stub)
      common/                # enums, mixins, permissions, pagination, exceptions (app-like package)
    tests/                   # pytest suite (unit/API/auth/permission/logic)
    seed_data/               # JSON/YAML seeds + management commands (T-12/T-22)
    Dockerfile  entrypoint.sh  healthcheck.py
  docker-compose.yml         # web + db + (redis optional)
  docs/                      # THIS suite + architecture/development/api/database docs
  .github/workflows/         # ci.yml, release.yml (T-11/T-34/T-35/T-36)
```

---

## 3. Django app split → feature phase mapping (1:1)

Each app owns one bounded concern and maps to at least one backend phase. The mapping is **1:1** with plan §6 so the
CEO and leads can reason about task↔code ownership without ambiguity.

| # | App            | Owns (entities from [data-model.md](data-model.md))     | Feature phases        | Primary tasks |
| - | -------------- | ------------------------------------------------------- | --------------------- | ------------- |
| 1 | `accounts`     | User, RefreshToken(blacklist), Subscription             | Auth & onboarding     | T-09, T-13    |
| 2 | `profiles`     | UserProfile, Goal, TrainingPreference (+ M2M throughs)  | Onboarding & goals    | T-14          |
| 3 | `content`      | Exercise, MuscleGroup, Equipment, ExerciseMedia, ExerciseAlternative | Exercise system | T-12, T-17, T-18, T-20 |
| 4 | `training`     | TrainingPlan, TrainingPlanDay, Workout, WorkoutExercise, WorkoutSet | Training plans | T-12, T-21, T-22 |
| 5 | `sessions`     | WorkoutSession, WorkoutSessionExercise, WorkoutSessionSet, WorkoutNote | Workout engine | T-24, T-26 |
| 6 | `progress`     | BodyMeasurement, PersonalRecord, ProgressMetric         | History & progress    | T-27          |
| 7 | `notifications`| Notification, NotificationPreference                   | Notifications (§18, phase-backlog) | T-24 (stub) |
| 8 | `admin`        | admin registrations for ALL content + user models       | Content management    | T-18          |
| 9 | `analytics`    | AnalyticsEvent                                          | Analytics (backlog)   | — (stub ready) |

Rules:

- **No cross-app model imports for schema** — a model lives in exactly one app; other apps reference it through the
  defining app (e.g. `sessions.WorkoutSession.user` → `settings.AUTH_USER_MODEL`).
- New domain = new app; never grow an app past one concern.
- `common/` is a library package, not an app — no models.

---

## 4. DRF conventions

### 4.1 ViewSets & routers

- Every resource uses `ModelViewSet` unless it is read-only (`ReadOnlyModelViewSet`) or action-only (APIView/ViewSet).
- Router: one `DefaultRouter` per app namespace, aggregated in `config/urls.py` under `/api/v1/`.
- Custom endpoints as `@action(detail=False | detail=True)` on the relevant ViewSet (e.g.
  `POST /api/v1/workout-sessions/{id}/complete/`, `GET .../previous/`).
- Write endpoints that mutate >1 resource live in the **sessions** app and call services; secondary app never writes
  another app's tables directly.

### 4.2 Serializers

- One serializer per (resource, view-context): `{Entity}Serializer` (read/nested), `{Entity}WriteSerializer`
  (create/update), padded through `Meta.fields`. Read vs write split keeps payloads tight and validation explicit.
- Validation lives in serializer `validate_*` + model `CheckConstraint`s (DB is the final authority). Never validate
  only on the client.
- Nested writes for M2M through-tables use explicit ListSerializer/`create` overrides; no bulk-update hacks.
- Output DTOs match the OpenAPI contract exactly; Flutter models are generated from the schema by the frontend team.

### 4.3 Permissions

- Default permission policy: `IsAuthenticated` for all `/api/v1/` endpoints **except** `POST /auth/register`,
  password reset, and public content reads.
- Content endpoints (exercises, equipment, muscles, plans, workouts) are **read for any authenticated user**,
  write-only for staff (`DjangoModelPermissions` / `IsAdminUser`) — §19 administration.
- Per-object ownership enforced via `get_queryset()` filtered by `request.user` (tenant-by-request-column) —
  a user can never observe another user's sessions/measurements/PRs/metrics/notifications.
- Custom permission classes in `common/permissions.py`: `IsOwnerOrReadOnly`, `IsStaffOrReadOnly`.

### 4.4 Pagination, filtering, ordering, throttling

- Pagination: DRF `PageNumberPagination`, `page_size=20`, `max_page_size=100`.
- Filtering: `django-filter` `FilterSet` per list endpoint (muscle, equipment, difficulty, pattern, objective,
  status, date ranges). Search via `filters.SearchFilter`/`SearchVector` for exercise text.
- Ordering: `OrderingFilter` with whitelisted fields only.
- Throttle: anonymous `100/hour`, authenticated `1000/hour` (ScopedRateThrottle on auth/log endpoints).

### 4.5 Errors & responses

- `APIException` subclasses in `common/exceptions.py`; enforced envelope
  `{"detail": ..., "code": ..., "field_errors": {...}}` for 4xx.
- Unhandled errors → 500 JSON with `request_id` (X-Request-ID) for traceability.
- Validation errors surface DRF default structure (field-keyed).

### 4.6 Performance conventions

- `select_related` for every FK on detail/list serializers; `prefetch_related` for M2M sets (muscles, equipment, media).
- N+1 guard: list serializers never trigger query-per-row; enforced in code review via `django-debug-toolbar` (dev)
  and a query-count test assertion.
- Cache dashboard aggregate reads (ProgressMetric) keyed by user id; invalidate on session completion.

---

## 5. Authentication & authorization (simplejwt)

### 5.1 Token flow

1. `POST /api/v1/auth/register/` → creates `User` (+ blank `UserProfile`), returns `access`+`refresh` (auto-login).
2. `POST /api/v1/auth/login/` → returns JWT pair.
3. Client stores tokens in secure storage (`flutter_secure_storage`); all API calls send
   `Authorization: Bearer <access>`.
4. `POST /api/v1/auth/refresh/` → new access token (and rotated refresh).
5. `POST /api/v1/auth/logout/` → blacklists the refresh token (`token_blacklist` app).
6. `POST /api/v1/auth/change-password/` (authenticated), `POST /api/v1/auth/forgot-password/`,
   `POST /api/v1/auth/reset-password/` (signed token) — out-of-band tokens, no stored reset rows.

### 5.2 simplejwt configuration (settings baseline)

- `ACCESS_TOKEN_LIFETIME = 30 min`, `REFRESH_TOKEN_LIFETIME = 30 days`, `ROTATE_REFRESH_TOKENS = True`,
  `BLACKLIST_AFTER_ROTATION = True`, `TOKEN_USER_CLASS = apps.accounts.User`.
- Claims: `user_id` + custom `email`, `role` (staff), `sub`.
- `DEFAULT_AUTHENTICATION_CLASSES = ['rest_framework_simplejwt.authentication.JWTAuthentication']`.
- Password validators: Django defaults + min-length 8 + not-email + not-common.

### 5.3 Authorization model

- `User.is_active` gates login (disqualified accounts rejected at token issue).
- DRF permission classes + object-scoped querysets (4.3). No custom security mechanism — DRF pluggable auth over
  simplejwt only (SIW-6 §3 mandate).

---

## 6. API versioning & namespace

- **Path versioning** `/api/v1/` (ADR-0003). Root URLconf:

```
/api/v1/            → DRF DefaultRouter (all app routers aggregated)
/api/v1/auth/       → accounts.auth views
/api/v1/schema/     → drf-spectacular OpenAPI schema (JSON + Swagger UI + Redoc)
/api/admin/         → Django admin
/healthz/           → kubernetes/docker healthcheck (no auth)
```

- New versions mount `/api/v2/` alongside; old versions kept until the Flutter minimum-app version drops them.
- Contract source of truth: `docs/api.md` (T-07) generated from the same drf-spectacular schema.

---

## 7. Settings & environment layout

### 7.1 Tiered settings

`config/settings/`:

- `base.py` — everything shared; reads `os.environ` via `django-environ`; **no secrets, no URLs**.
- `development.py` — `DEBUG=True`, SQLite-free (Postgres via compose), CORS local-network + `http://localhost`,
  `ALLOWED_HOSTS` from `DJANGO_ALLOWED_HOSTS` (or `*` in dev only).
- `staging.py` — `DEBUG=False`, restricted hosts/CORS, seeded content, `SENTRY_DSN` optional.
- `production.py` — `DEBUG=False`, strict `ALLOWED_HOSTS`, `SECURE_*` (SSL redirect, HSTS), Redis cache + sessions,
  CSRF/SecurityMiddleware harden.

Selection: package entry `config.settings.${DJANGO_ENV}` — `DJANGO_ENV=development|staging|production`.
Docker sets `DJANGO_SETTINGS_MODULE=config.settings.development` by default.

### 7.2 Environment variables (`.env`, no defaults for secrets)

| Variable                  | Required | Notes                                  |
| ------------------------- | -------- | -------------------------------------- |
| `DJANGO_ENV`              | yes      | tier selector                         |
| `DJANGO_SECRET_KEY`       | yes      | rotated per environment; never in git  |
| `DATABASE_URL`            | yes      | `postgres://user:pass@host:5432/db`    |
| `DEBUG`                   | dev only | must be false otherwise                |
| `DJANGO_ALLOWED_HOSTS`    | yes      | comma-separated                        |
| `CORS_ALLOWED_ORIGINS`    | staging+ | comma-separated                        |
| `DJANGO_SUPERUSER_EMAIL/PASSWORD` | dev | bootstrap admin               |
| `REDIS_URL`               | prod     | cache/sessions/blacklist               |
| `SENTRY_DSN`              | optional | error telemetry                        |
| `MEDIA_BASE_URL`          | prod     | CDN prefix for ExerciseMedia urls     |
| `API_BASE_URL_PUBLIC`     | prod     | OpenAPI server URL override            |

`.env` is git-ignored; `.env.example` ships with placeholders and documentation. Flutter side mirrors these tiers
via flavors (plan §9) — no coupling of values, only of contract.

### 7.3 CORS

- Dev: `http://localhost:*`, `http://<host-lan-ip>:*` (physical-phone testing, §25).
- Prod: explicit origin allowlist. Credentials off (Bearer tokens, not cookies).

---

## 8. Migrations policy

1. **One migration per logical change**, named by content
   (`0042_add_session_set_exercise_index.py`) — never `auto_*` leftovers.
2. **Every model change ships a migration in the same PR**; CI fails on `makemigrations --check` drift.
3. **Custom User is migrated in T-09 as the very first migration** (`AUTH_USER_MODEL` set before any FK reference).
4. **Migrations are forward-only and immutable once merged** (rebase/never edit). Corrections = new migration.
5. Data migrations are idempotent and used only for content/backfill; seed catalogs run via management commands
   (`seed_exercises`, `seed_plans`, T-12/T-22) using `update_or_create(slug=...)` — they are **data, not migrations**.
6. Long-running tables (AnalyticsEvent) at scale: partition via a dedicated migration; documented but out of MVP scope.
7. `django.contrib.postgres` only (JSONB, TrigramExtension via `TrigramExtension` migration).

---

## 9. Admin / content management (app `admin`, §19)

- Every model from apps accounts/profiles/content/training/sessions/progress/notifications/analytics is registered.
- `list_display`, `list_filter`, `search_fields` tuned per model; workouts/exercises inline-editable
  (WorkoutExercise inline in Workout, WorkoutSet inline in WorkoutExercise, ExerciseMedia inline in Exercise).
- Content changes are **runtime-only** — editing exercises/plans never requires a Flutter release (§19).
- Admin ops require `is_staff`; read-only users provisioned separately for analysts.

---

## 10. OpenAPI / schema

- `drf-spectacular` settings: `SERVERS` from `API_BASE_URL_PUBLIC`, `ENUM_NAME_OVERRIDES` without prefixes,
  `SCHEMA_PATH_PREFIX = r'/api/v[0-9]+'` so `/api/v1/` paths are clean.
- CI validates the schema compiles (`spectacular --validate`); a drift PR cannot pass with a broken contract.
- `docs/api.md` (T-07) is the contract the Flutter team builds against — generated once from this schema, never
  hand-maintained twice.

---

## 11. Testing strategy (T-31 baseline, sized for T-09..T-27)

- `pytest` + `pytest-django` + `model_bakery` factories; `pytest.ini` DB = Postgres test schema (fresh per run).
- Required suites per task (SIW-6 §26):
  - `unit/` — model constraints, enum behavior, service math (volume, 1RM, streak, substitution ranking).
  - `api/` — endpoint contracts per ViewSet (happy path + field validation).
  - `auth_api/` — register/login/refresh/logout/blacklist/password flows.
  - `permission/` — ownership isolation (user A cannot read user B), staff-only writes.
  - `logic/` — session completion, PR replace, previous-performance query, plan-day generation, substitution filter.
- Query-count guards on list endpoints (assert < N queries) to lock the N+1 conventions.
- CI runs `pytest` + `makemigrations --check` + `spectacular --validate` (T-11 pipeline hook).

---

## 12. Docker / deployment (§24, T-09)

- `backend/Dockerfile`: `python:3.12-slim`, non-root user, `pip install -r requirements`, collectstatic, gunicorn CMD.
- `docker-compose.yml`: `web` (8000) + `db` (Postgres 16, named volume, healthcheck) + optional `redis` (prod profile).
- `entrypoint.sh`: wait-for-db → `migrate` → optional `seed_*` (dev) → `runserver` (dev) / `gunicorn config.wsgi` (prod).
- Healthcheck `GET /healthz/` → 200 + DB `SELECT 1`; used by compose `healthcheck` and k8s probes.
- Docs: `docs/backend.md` + `docs/deployment.md` (T-37) walk a new developer clone→up→register→workout.

---

## 13. Phase-handoff readiness

This architecture doc, plus [data-model.md](data-model.md), is the direct input to:

- **T-09** scaffold + Docker + first migration (custom User) + `/healthz/`
- **T-12** seed tooling (exercises/muscles/equipment → content app; plans/workouts → training app)
- **T-13** auth API on `accounts` (register/login/refresh/logout/password)
- **T-17** exercise CRUD + search/filter on `content`
- **T-21** plan/workout API on `training`
- **T-24** session/set recording on `sessions` (start/complete/log sets/previous)
- **T-27** measurements/PR/metrics API on `progress`
- **T-31** full test suite per §11

Any deviation from this model/contract must be coordinated with the CTO and reflected in `docs/api.md` (T-07)
**before** the Flutter team codes against a conflicting interface.

---

*References: SIW-6 §3/§4/§20/§21/§24–§27 · Plan §4 (architecture) & §6 (phases) ·
[data-model.md](data-model.md) · [decisions.md](decisions.md).*