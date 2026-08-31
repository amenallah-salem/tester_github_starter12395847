# API — Versioned REST Contract v1

> Task T-07 (SIW-13). The machine-readable source of truth is
> [`api-contract-v1.yaml`](api-contract-v1.yaml) (OpenAPI 3.0.3). This page is
> the human-readable reference that the Flutter client (T-06) and every feature
> phase (T-13..T-29, T-31..T-33) build against.
>
> Git history: the contract freezes at the start of Phase 1 and only evolves via
> a versioned v2 contract, never by silent field changes to v1.

## 1. Conventions

| Convention | Rule |
| --- | --- |
| Base path | `https://<host>/api/v1` (URL-path versioning, ADR-0003) |
| Auth | Bearer JWT. `Authorization: Bearer <access>` on every protected endpoint. Access token default TTL 30 min, refresh 30 days, rotated on every refresh (`ROTATE_REFRESH_TOKENS=True`). |
| Content type | `application/json` for both requests and responses |
| IDs | `int64`, backend-assigned bigints (T-05 §2). No UUIDs. |
| Timestamps | ISO-8601 UTC `date-time` (`YYYY-MM-DDTHH:MM:SSZ`); dates are `YYYY-MM-DD` |
| Pagination | `?page=` (1-based) and `?page_size=` (default 20, max 100). Every list returns the `Pagination` envelope: `{ count, next, previous, results }` |
| Errors | Uniform envelope `{ detail, code, field_errors }` (§7 below) |
| Enum codes | camel-lowercase snake codes (`lose_weight`, `beginner`, `in_app`, …). Must match T-05 §5 and the Flutter DTOs exactly. |

### Traceability

Every endpoint below maps to the data model in [`data-model.md`](data-model.md)
(T-05) and the Flutter model layer (T-06). Feature tasks consume them as follows:

- **T-13 auth** → §2 Auth
- **T-14 profile/goals** → §4 Profile, §5 Goals
- **T-15/T-16 onboarding** → §3 Onboarding
- **T-17 exercise DB** → §6 Content (exercises, muscles, equipment, media, alternatives)
- **T-18/T-19/T-20** content/search/media pipeline (consumed via §6 read endpoints)
- **T-21 plans** → §8 Plans
- **T-23 plan selection** → `PUT /users/me/current-plan/`
- **T-24/T-25 workout execution** → §9 Sessions, §10 Sets, §11 Previous performance
- **T-26 substitution** → `POST .../substitute/` + §6 alternatives
- **T-27 measurements/PRs/metrics** → §12 Progress
- **T-28 history/calendar** → §13 History, §14 Calendar
- **T-29 dashboard** → §15 Dashboard
- **T-31/T-32/T-33 notifications & subscription** → §16 Notifications, §17 Subscription

## 2. Auth (`/auth/…`)

| Method | Path | Description |
| --- | --- | --- |
| POST | `/auth/register/` | Create account, returns tokens + user (auto-login). Public. |
| POST | `/auth/login/` | Email + password → tokens + user. Public. |
| POST | `/auth/refresh/` | Refresh token → new access + rotated refresh. Public. |
| POST | `/auth/logout/` | Blacklist the refresh token. |
| POST | `/auth/forgot-password/` | Email a reset link. Always `202` (no enumeration). Public. |
| POST | `/auth/reset-password/` | Set new password with the signed token from the email. Public. |
| POST | `/auth/change-password/` | Change password given the current password (authenticated). |

### 2.1 Register

```http
POST /api/v1/auth/register/
Content-Type: application/json

{
  "first_name": "Sara",
  "last_name": "Ben Ali",
  "email": "sara.benali@example.com",
  "password": "Str0ng!Pass",
  "password_confirm": "Str0ng!Pass",
  "accept_terms": true
}
```

`201 Created`:

```json
{
  "access": "<jwt>",
  "refresh": "<jwt>",
  "user": {
    "id": 12,
    "email": "sara.benali@example.com",
    "first_name": "Sara",
    "last_name": "Ben Ali",
    "is_active": true,
    "is_onboarded": false,
    "date_joined": "2026-08-30T09:12:44Z"
  }
}
```

### 2.2 Login / refresh / logout

Login is identical to register minus `accept_terms` (response: `200` with the same
`TokenWithUserResponse`). Refresh is a simple rotation:

```http
POST /api/v1/auth/refresh/
Content-Type: application/json

{ "refresh": "<refresh-jwt>" }
```

```json
{ "access": "<new-access-jwt>", "refresh": "<new-refresh-jwt>" }
```

Logout blacklists the refresh token (idempotent; `204 No Content`):

```http
POST /api/v1/auth/logout/
Authorization: Bearer <access>
Content-Type: application/json

{ "refresh": "<refresh-jwt>" }
```

### 2.3 Password recovery

```http
POST /api/v1/auth/forgot-password/
{ "email": "sara.benali@example.com" }          → 202 (always)
```

```http
POST /api/v1/auth/reset-password/
{ "token": "<signed-token-from-email>", "new_password": "NewStr0ng!Pass", "new_password_confirm": "NewStr0ng!Pass" }   → 204
```

```http
POST /api/v1/auth/change-password/
Authorization: Bearer <access>
{ "current_password": "OldPass", "new_password": "NewStr0ng!Pass", "new_password_confirm": "NewStr0ng!Pass" }   → 204
```

## 3. Onboarding (`/onboarding/`)

Completed once after registration; drives the recommended plan.

| Method | Path | Description |
| --- | --- | --- |
| GET | `/onboarding/` | `{ completed, profile, ... }` progress snapshot |
| PUT | `/onboarding/` | Submit all onboarding answers; creates active goal + preferences; returns recommended plan |

```http
PUT /api/v1/onboarding/
Authorization: Bearer <access>
Content-Type: application/json

{
  "date_of_birth": "1994-04-12",
  "gender": "female",
  "height_cm": 167.0,
  "current_weight_kg": 62.0,
  "primary_objective": "lose_weight",
  "fitness_level": "beginner",
  "training_experience": "less_than_1y",
  "days_per_week": 3,
  "session_duration_minutes": 45,
  "preferred_time_of_day": "morning",
  "preferred_location": "gym",
  "available_equipment": [3, 5, 9],
  "preferred_exercises": [11, 42],
  "avoided_exercises": [27]
}
```

`200` → `OnboardingResult`:

```json
{
  "onboarding_completed": true,
  "profile": { "id": 8, "user": { "id": 12, ... }, "onboarding_completed_at": "2026-08-30T09:20:01Z", ... },
  "active_goal": { "id": 1, "type": "lose_weight", "status": "active", "start_date": "2026-08-30", ... },
  "recommended_plan": { "id": 3, "name": "Beginner Full Body 3x", "objective": "lose_weight", "days_per_week": 3, ... }
}
```

## 4. Profile (`/profile/…`)

| Method | Path | Description |
| --- | --- | --- |
| GET | `/profile/` | `ProfileBundle`: user + profile + active_goal + preferences |
| PATCH | `/profile/` | Partial update of `UserProfile` fields (e.g. `fitness_level`, `preferred_location`). `PATCH` semantics: only provided fields change. |
| GET | `/profile/preferences/` | Training preferences (equipment range, preferred/avoided exercises) |
| PUT | `/profile/preferences/` | Upsert preferences |

```http
PATCH /api/v1/profile/
Authorization: Bearer <access>
{ "fitness_level": "intermediate", "preferred_location": "home" }   → 200 ProfileBundle
```

## 5. Goals (`/goals/…`)

| Method | Path | Description |
| --- | --- | --- |
| GET | `/goals/` | Paginated goals, optional `?status=active` filter |
| POST | `/goals/` | Create a goal. **Only one active goal per user** (DB-enforced). |
| GET | `/goals/{id}/` | Goal detail (`selected_plan` populated after plan assignment) |
| PATCH | `/goals/{id}/` | Update a goal |
| DELETE | `/goals/{id}/` | Delete a goal (`204`) |

```http
POST /api/v1/goals/
{ "type": "gain_strength", "target_value": 100, "target_unit": "kg", "target_date": "2026-12-31", "status": "active" }
→ 201 Goal
```

## 6. Content — read-only catalog (`/exercises/`, `/muscles/`, `/equipment/`)

| Method | Path | Description |
| --- | --- | --- |
| GET | `/exercises/` | Paginated exercise cards; filters `?muscle=`, `?equipment=`, `?difficulty=`, `?search=` |
| GET | `/exercises/{id}/` | Full exercise: instructions, muscles (role), equipment, media (image/video), alternatives |
| GET | `/exercises/{id}/alternatives/` | Curated substitution list (rationale + priority) |
| GET | `/muscles/` | Muscle groups (region hierarchy); `?region=` filter |
| GET | `/equipment/` | Equipment catalog (category); `?category=` filter |

Media is returned **embedded** on exercise detail as `media: [{ id, media_type, url, alt_text, is_primary, sort_order }]`.
There is no standalone media endpoint in v1 — URLs are CDN-backed and render directly in Flutter.

### 6.1 Substitution contract

```json
GET /api/v1/exercises/42/alternatives/
{
  "results": [
    { "exercise": { "id": 58, "name": "Dumbbell Bench Press", "slug": "dumbbell-bench-press", ... },
      "rationale": "same_muscle", "priority": 1 },
    { "exercise": { "id": 63, "name": "Machine Chest Press", "slug": "machine-chest-press", ... },
      "rationale": "same_pattern", "priority": 2 }
  ]
}
```

The Flutter workout screen calls this at plan-build and during a live session it uses
`POST /workout-sessions/{id}/exercises/{sessionExerciseId}/substitute/` (§11).

## 7. Errors

Every 4xx/5xx uses the same envelope:

```json
{
  "detail": "Human-readable summary",
  "code": "machine_code",
  "field_errors": { "email": ["This field is required."] }
}
```

| HTTP | Meaning | Typical `code` |
| --- | --- | --- |
| 400 | Validation / malformed body | `validation_error` |
| 401 | Missing or invalid credentials | `not_authenticated` / `token_expired` |
| 403 | Authenticated but not allowed / not subscribed | `permission_denied` |
| 404 | Resource not found | `not_found` |
| 409 | Conflict (duplicate email, second active goal, slot taken) | `conflict` |
| 202/204 | Accepted / No content (common for actions) | — |

`field_errors` is omitted when there is no field-level problem. `detail` is always present.

---

## 8. Plans (`/plans/…`)

| Method | Path | Description |
| --- | --- | --- |
| GET | `/plans/` | Paginated catalog; filters `?objective=`, `?difficulty=`, `?days_per_week=` |
| GET | `/plans/{id}/` | Full plan: days → workouts → exercises → prescribed sets (`PlanDay`/`Workout`/`WorkoutExercise`/`PrescribedSet`) |
| GET | `/users/me/current-plan/` | The user's assigned plan (drives calendar/dashboard) |
| PUT | `/users/me/current-plan/` | Assign the current plan to the active goal (`AssignPlanRequest { plan_id }`) |
| POST | `/plans/{plan_id}/days/{day_id}/schedule/` | Create a planned session for a plan day on a date (default today; one open slot per date) |

```http
PUT /api/v1/users/me/current-plan/
Authorization: Bearer <access>
{ "plan_id": 3 }   → 200 Plan
```

A full plan nests its structure:

```json
{
  "id": 3, "name": "Beginner Full Body 3x", "objective": "lose_weight",
  "duration_weeks": 8, "days_per_week": 3,
  "days": [
    {
      "id": 10, "day_number": 1, "is_rest_day": false,
      "workout": {
        "id": 44, "name": "Full Body A", "estimated_duration_minutes": 45,
        "exercises": [
          {
            "id": 110, "order": 1,
            "exercise": { "id": 11, "name": "Barbell Squat", "slug": "barbell-squat", "difficulty": "beginner", "movement_type": "compound" },
            "prescribed_sets": [ { "id": 501, "set_number": 1, "set_type": "working", "target_reps": 10, "target_rpe": null, "rest_seconds": 90 } ],
            "rest_after_seconds": 90, "notes": "Sit depth to parallel"
          }
        ]
      }
    }
  ]
}
```

## 9. Workout sessions (`/workout-sessions/…`)

| Method | Path | Description |
| --- | --- | --- |
| GET | `/workout-sessions/` | Paginated sessions; `?status=`, `?start_date=`, `?end_date=` |
| GET | `/workout-sessions/{id}/` | Session detail (exercises + performed sets + previous performance) |
| POST | `/workout-sessions/{id}/start/` | Move a planned session to `in_progress` (idempotent; returns or creates the open in-progress session for the workout/day) |
| POST | `/workout-sessions/{id}/complete/` | Mark completed; backend computes volume, PRs, metrics, streak |

Session status flow: `planned → in_progress → completed` (or `skipped`, or `paused` ↔ resume via `start/`).

## 10. Sets — set logging

| Method | Path | Description |
| --- | --- | --- |
| POST | `/workout-sessions/{id}/exercises/{sessionExerciseId}/sets/` | Record one performed set |
| GET | `/workout-sessions/{id}/exercises/{sessionExerciseId}/sets/` | List sets for the exercise |
| PATCH | `/workout-sessions/{id}/exercises/{sessionExerciseId}/sets/{setId}/` | Correct weight/reps/completion |
| DELETE | `/workout-sessions/{id}/exercises/{sessionExerciseId}/sets/{setId}/` | Remove a mis-logged set (`204`) |

```http
POST /api/v1/workout-sessions/201/exercises/310/sets/
Authorization: Bearer <access>
Content-Type: application/json

{
  "set_type": "working",
  "weight_kg": 40.0,
  "reps": 12,
  "rpe": 7,
  "is_completed": true,
  "note": "Felt easy — add weight next week"
}
```

`201` → `SessionSet` (backend assigns `set_number` 1-based, unique per exercise):

```json
{
  "id": 4021, "set_number": 1, "set_type": "working",
  "weight_kg": 40.0, "reps": 12, "rpe": 7, "is_completed": true,
  "note": "Felt easy — add weight next week",
  "created_at": "2026-08-30T10:05:12Z", "updated_at": "2026-08-30T10:05:12Z"
}
```

`weight_kg` null means bodyweight/unloaded; `reps` null means timed sets (`duration_seconds`).

## 11. Previous performance, skip, substitute

| Path | Description |
| --- | --- |
| `GET /workout-sessions/{id}/exercises/{sessionExerciseId}/previous/` | Compact history used pre-set |
| `POST /workout-sessions/{id}/exercises/{sessionExerciseId}/skip/` | Mark exercise `skipped` (mid-session simplification) |
| `POST /workout-sessions/{id}/exercises/{sessionExerciseId}/substitute/` | Swap the exercise for an alternative for this session |

```json
GET /api/v1/workout-sessions/201/exercises/310/previous/
{
  "has_previous": true,
  "last_session_date": "2026-08-23T10:02:00Z",
  "last_sets": [
    { "set_number": 1, "set_type": "working", "weight_kg": 37.5, "reps": 12 },
    { "set_number": 2, "set_type": "working", "weight_kg": 37.5, "reps": 11 }
  ],
  "best_weight_kg": 37.5,
  "estimated_1rm": 52.6
}
```

```http
POST /api/v1/workout-sessions/201/exercises/310/substitute/
{ "alternative_exercise_id": 58 }   → 200 SessionExercise (substituted_from = original)
```

Substitution is constraint-aware (T-26): the server validates the alternative against the user's
training preferences, equipment availability, and the original exercise's role/pattern.

## 12. Progress, measurements, PRs, metrics

| Method | Path | Description |
| --- | --- | --- |
| GET | `/measurements/` | Paginated body measurements; `?measurement_type=` |
| POST | `/measurements/` | Add a measurement (`weight`, `waist`, `body_fat_percentage`, …) |
| DELETE | `/measurements/{id}/` | Remove a mis-entered measurement (`204`) |
| GET | `/personal-records/` | PRs: `{ exercise, metric: max_weight|max_reps|estimated_1rm|best_time|max_volume, value, achieved_at }` |
| GET | `/progress-metrics/` | `?metric_type=` + `?period=` (week/period); `weekly_volume`, `consistency_percent`, `streak_days`, … |

```http
POST /api/v1/measurements/
{ "measurement_type": "weight", "value": 61.8, "unit": "kg", "measured_at": "2026-08-30T07:30:00Z" }   → 201
```

## 13. History & 14. Calendar

| Path | Description |
| --- | --- |
| `GET /history/workouts/` | Completed sessions for history screens (paginated; `?start_date=`/`?end_date=`) |
| `GET /calendar/?start=YYYY-MM-DD&end=YYYY-MM-DD` | Day grid: `entries: [{ date, status: planned|completed|missed|rest_day|upcoming, session_id?, workout? }]` |
| `PUT /plans/{plan_id}/days/{day_id}/schedule/` (see §8) | Populates the calendar with planned sessions |

## 15. Dashboard (`/dashboard/`)

One call for the home screen:

```http
GET /api/v1/dashboard/
Authorization: Bearer <access>
```

```json
{
  "today_workout": { "id": 44, "name": "Full Body A", "slug": "full-body-a", "estimated_duration_minutes": 45 },
  "next_workout": { "id": 51, "name": "Full Body B", "slug": "full-body-b", "estimated_duration_minutes": 40 },
  "active_goal": { "id": 1, "type": "lose_weight", "status": "active", "start_date": "2026-08-30" },
  "weekly_progress": { "completed": 2, "planned": 3, "total_volume_kg": 2540.5, "workouts": [ ... ] },
  "recent_activity": [ { "type": "workout_completed", "title": "Full Body A", "occurred_at": "2026-08-28T10:12:00Z", "entity_id": 201 } ],
  "metrics": [ { "id": 1, "metric_type": "streak_days", "value": 4, "period_start": "2026-08-27", "period_end": "2026-08-30", "computed_at": "2026-08-30T10:15:00Z" } ],
  "streak_days": 4
}
```

## 16. Notifications (`/notifications/…`)

| Method | Path | Description |
| --- | --- | --- |
| GET | `/notifications/` | Paginated in-app notifications; `?unread_only=true` |
| POST | `/notifications/read-all/` | Mark all read (`204`) |
| POST | `/notifications/{id}/read/` | Mark one read (`204`) |

Types: `workout_reminder`, `missed_workout`, `plan_completed`, `progress_milestone`, `consistency`, `system`, `subscription`.

## 17. Subscription (`/subscription/…`)

| Method | Path | Description |
| --- | --- | --- |
| GET | `/subscription/plans/` | Available plans: `free` / `plus` / `pro` |
| GET | `/subscription/` | Current subscription + plan + status (`trialing`/`active`/`past_due`/`cancelled`/`expired`) |

```json
GET /api/v1/subscription/
{
  "id": 22, "status": "active",
  "plan": { "code": "plus", "name": "Plus", "price_monthly": 9.99, "features": [ ... ] },
  "current_period_end": "2026-09-29T09:00:00Z",
  "cancel_at_period_end": false
}
```

---

## Data-flow walkthroughs

### A. First run: auth → onboarding → plan

```text
POST /auth/register/ ──────────────► 201 { access, refresh, user (is_onboarded: false) }
GET  /onboarding/  ────────────────► 200 { completed: false }
PUT  /onboarding/  (answers) ──────► 200 OnboardingResult { recommended_plan }
GET  /plans/ ?objective=…          ► paginated catalog
PUT  /users/me/current-plan/ {plan_id} ► 200 Plan (assigned to active goal)
GET  /calendar/?start=…&end=… ────► entries include planned sessions
```

### B. Workout execution with set logging

```text
GET  /workout-sessions/ ?status=planned   ► pick today's planned session
POST /workout-sessions/{id}/start/        ► 200 Session status=in_progress
     (GET /workout-sessions/{id}/ returns exercises + previous_performance per exercise)
POST …/exercises/{sid}/sets/              ► 201 SessionSet (set_number auto)
POST …/exercises/{sid}/sets/              ► 201 (set 2)
PATCH …/sets/{setId}/                     ► correct a rep count
POST …/exercises/{sid}/previous/ OR  /substitute/  ► overrides / swaps unavailable exercise
POST /workout-sessions/{id}/complete/     ► 200 Session status=completed (volume, PRs, metrics computed server-side)
```

### C. Previous-performance driven progression (double progression)

`GET .../previous/` returns last sessions' sets + `best_weight_kg` + `estimated_1rm`. The Flutter screen
seeds the working sets from `last_sets` (same weight, n+1 target reps), and the backend's PR/metric
recomputation on `complete/` records a PR when weight or reps exceed history.

### D. Progress tracking

```text
POST /measurements/  (daily/weekly weight entry)      ► 201 BodyMeasurement
GET  /measurements/?measurement_type=weight           ► paginated series for charts
GET  /progress-metrics/?metric_type=weekly_volume     ► series for volume charts
GET  /personal-records/                               ► PR list per exercise
GET  /dashboard/                                      ► home: today's workout, streak, weekly progress
```