# API v1 — Readable Reference

> **Task:** T-07 (SIW-13) · **Owner:** Backend Lead
> Canonical contract: [`api-contract-v1.yaml`](api-contract-v1.yaml) (OpenAPI 3.0.3).
> This document is the human-readable companion to that machine-readable contract and the
> data model in [`data-model.md`](data-model.md). The Flutter DTOs (T-06) and the backend
> implementation must derive their shape from those two sources — this guide never overrides them.

## 1. Overview

All endpoints are versioned under **`/api/v1`** and return **JSON**. The API is
**OpenAPI-first**: the contract is the single synchronization point between the Django REST
Framework backend and the Flutter client.

- **Auth:** Bearer JWT (`Authorization: Bearer <access>`). Access tokens last ~30 min; refresh
  tokens ~30 days and are rotated on each refresh (`djangorestframework-simplejwt`).
- **Pagination:** every list endpoint is paginated (`page`, `page_size`, default 20, max 100)
  and returns a `{ count, next, previous, results }` envelope.
- **Errors:** every 4xx/5xx returns the uniform `{"detail", "code", "field_errors"}` envelope.
- **Enums:** string codes mirror the T-05 canonical enums exactly — the client must use these
  exact strings, never invent new ones.

### Base URLs

| Env | Base URL |
| --- | --- |
| Development | `http://192.168.1.100:8000/api/v1` |
| Staging | `https://staging-api.example.com/api/v1` |
| Production | `https://api.example.com/api/v1` |

### Token & error envelope shapes

```jsonc
// 200 POST /auth/login
{ "access": "<jwt>", "refresh": "<jwt>", "user": { "id": 1, "email": "...", "first_name": "...", "last_name": "...", "is_onboarded": false } }

// 4xx/5xx error — always this shape
{ "detail": "Human-readable summary", "code": "invalid_credentials", "field_errors": { "email": ["Enter a valid email."] } }
```

## 2. Endpoint Reference

### 2.1 Auth (`/auth/`)

| Method | Path | Body → Success | Purpose |
| --- | --- | --- | --- |
| POST | `/auth/register/` | `RegisterRequest` → `201 TokenWithUserResponse` | Create account (auto-login) |
| POST | `/auth/login/` | `LoginRequest` → `200 TokenWithUserResponse` | Log in |
| POST | `/auth/logout/` | `RefreshTokenRequest` → `204` | Blacklist refresh token |
| POST | `/auth/refresh/` | `RefreshTokenRequest` → `200 TokenResponse` | Refresh + rotate tokens |
| POST | `/auth/forgot-password/` | `ForgotPasswordRequest` → `202` | Send reset email (no enumeration) |
| POST | `/auth/reset-password/` | `ResetPasswordRequest` → `204` | Set new password with token |
| POST | `/auth/change-password/` | `ChangePasswordRequest` → `204` | Change password while logged in |

### 2.2 Profile & goals (`/profile/`, `/goals/`)

| Method | Path | Body → Success | Purpose |
| --- | --- | --- | --- |
| GET | `/profile/` | — → `200 ProfileBundle` | User + profile + active goal + preferences |
| PATCH | `/profile/` | `UserProfileWrite` → `200 UserProfile` | Partial profile update |
| GET | `/goals/` | — → `200 PaginatedGoals` | List goals |
| POST | `/goals/` | `GoalWrite` → `201 Goal` | Create a goal |
| GET | `/goals/{id}/` | — → `200 Goal` | Goal detail |
| PATCH | `/goals/{id}/` | `GoalWrite` → `200 Goal` | Update goal |
| DELETE | `/goals/{id}/` | — → `204` | Delete goal |

### 2.3 Onboarding (`/onboarding/`)

| Method | Path | Body → Success | Purpose |
| --- | --- | --- | --- |
| GET | `/onboarding/` | — → `200 OnboardingState` | Check onboarding progress |
| PUT | `/onboarding/` | `OnboardingSubmit` → `200 OnboardingResult` | Submit all answers; sets profile, active goal, preferences + returns recommended plan |

### 2.4 Content (read-only for non-admin)

| Method | Path | Query | Success | Purpose |
| --- | --- | --- | --- | --- |
| GET | `/exercises/` | `search`, `muscle`, `equipment`, `difficulty`, `movement_type`, `pattern` | `200 PaginatedExercises` | Search/filter exercise DB |
| GET | `/exercises/{id}/` | — | `200 Exercise` | Full detail incl. media, muscles, equipment |
| GET | `/exercises/{id}/alternatives/` | — | `200 AlternativeList` | Ranked substitute candidates |
| GET | `/muscles/` | — | `200 MuscleGroupList` | All muscle groups |
| GET | `/equipment/` | — | `200 EquipmentList` | All equipment |

### 2.5 Plans (`/plans/`) & calendar (`/calendar/`)

| Method | Path | Query/Body → Success | Purpose |
| --- | --- | --- | --- |
| GET | `/plans/` | `objective`, `difficulty` | `200 PaginatedPlans` | List active plans (data-driven) |
| GET | `/plans/{id}/` | — | `200 Plan` | Plan + days + workouts + prescribed sets |
| GET | `/users/me/current-plan/` | — | `200 Plan` | Current active plan |
| PUT | `/users/me/current-plan/` | `AssignPlanRequest` → `200 Plan` | Select the current plan |
| POST | `/plans/{plan_id}/days/{day_id}/schedule/` | `ScheduleSessionRequest` → `201 Session` | Create a planned session for a plan day |
| GET | `/calendar/` | `start_date`, `end_date` | `200 Calendar` | Month window of planned/completed/missed |

### 2.6 Workout sessions (`/workout-sessions/`)

| Method | Path | Body → Success | Purpose |
| --- | --- | --- | --- |
| GET | `/workout-sessions/` | `status`, `start_date`, `end_date` | `200 PaginatedSessions` | List sessions |
| GET | `/workout-sessions/{id}/` | — | `200 Session` | Session + exercises + sets + prev performance |
| POST | `/workout-sessions/{id}/start/` | `StartSessionActionRequest` → `200 Session` | Start a session |
| POST | `/workout-sessions/{id}/complete/` | `CompleteSessionRequest` → `200 Session` | Complete; recalc volume/PR/metrics |

### 2.7 Set logging (`/workout-sessions/{id}/exercises/{seId}/sets/`)

| Method | Path | Body → Success | Purpose |
| --- | --- | --- | --- |
| GET | `.../sets/` | — | `200 SessionSetList` | List performed sets |
| POST | `.../sets/` | `SessionSetCreate` → `201 SessionSet` | Log a performed set |
| PATCH | `.../sets/{setId}/` | `SessionSetUpdate` → `200 SessionSet` | Correct a set |
| DELETE | `.../sets/{setId}/` | — | `204` | Delete a set |
| GET | `.../previous/` | — | `200 PreviousPerformance` | Last workout's sets + best + est 1RM |
| POST | `.../skip/` | — | `200 SessionExercise` | Skip this exercise |
| POST | `.../substitute/` | `SubstituteRequest` → `200 SessionExercise` | Swap in an alternative (traced) |

### 2.8 History, dashboard, progress

| Method | Path | Query → Success | Purpose |
| --- | --- | --- | --- |
| GET | `/history/workouts/` | paged | `200 PaginatedSessions` | Completed workout history |
| GET | `/dashboard/` | — | `200 Dashboard` | Today/next workout, weekly progress, streak |
| GET | `/measurements/` | `measurement_type`, `start_date`, `end_date` | `200 PaginatedMeasurements` | Body-measurement trends |
| POST | `/measurements/` | `BodyMeasurementWrite` → `201` | Add a measurement point |
| DELETE | `/measurements/{id}/` | — | `204` | Delete a measurement |
| GET | `/personal-records/` | `exercise`, `metric` | `200 PersonalRecordList` | Personal records |
| GET | `/progress-metrics/` | `metric_type`, `start_date`, `end_date` | `200 ProgressMetricList` | Materialized chart metrics |

### 2.9 Notifications & subscription

| Method | Path | Success | Purpose |
| --- | --- | --- | --- |
| GET | `/notifications/` | `200 PaginatedNotifications` | List notifications |
| POST | `/notifications/read-all/` | `204` | Mark all read |
| POST | `/notifications/{id}/read/` | `204` | Mark one read |
| GET | `/subscription/plans/` | `200 SubscriptionPlanList` | Available plans |
| GET | `/subscription/` | `200 Subscription` | Current subscription |

## 3. Using the API from Flutter

The client only needs to know the base URL, the token header, and the request/response shapes (which
it generates from the OpenAPI contract). Below are minimal, idiomatic examples using `dio` (the
project's HTTP client).

### 3.1 Client setup + auth interceptor

```dart
import 'package:dio/dio.dart';

Dio dio([String base = 'https://staging-api.example.com/api/v1']) => Dio(
      BaseOptions(
        baseUrl: base,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

// Attach the access token to every request.
void withAuth(Dio d, String access) =>
    d.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      o.headers['Authorization'] = 'Bearer $access';
      h.next(o);
    }));
```

### 3.2 Register / login / refresh

```dart
final d = dio();
final res = await d.post('/auth/register/', data: {
  'first_name': 'Sami',
  'last_name': 'Ben',
  'email': 'sami@example.com',
  'password': 'S3curePass!x',
  'password_confirm': 'S3curePass!x',
  'accept_terms': true,
});
// res.data => { 'access': ..., 'refresh': ..., 'user': { id, email, ... } }
```

On `401` from a protected call, refresh once and retry:

```dart
Future<void> protectedCall() async {
  try {
    await d.get('/dashboard/');
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      final r = await d.post('/auth/refresh/', data: {
        'refresh': storedRefreshToken,
      });
      await saveTokens(r.data['access'], r.data['refresh']); // rotated!
      await protectedCall();
    } else {
      rethrow;
    }
  }
}
```

### 3.3 Handling the uniform error envelope

```dart
String readError(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['detail'] != null) {
    final fieldErrors = data['field_errors'];
    if (fieldErrors is Map && fieldErrors.isNotEmpty) {
      return (fieldErrors.values.first as List).first as String;
    }
    return data['detail'] as String;
  }
  return 'Unexpected error';
}
```

### 3.4 Pagination helper

```dart
Future<List<T>> fetchPage<T>(Future<Response<dynamic>> Function(int page) call,
    T Function(Map<String, dynamic>) fromJson) async {
  final results = <T>[];
  var page = 1;
  Response<dynamic> res;
  do {
    res = await call(page);
    final body = res.data as Map<String, dynamic>;
    results.addAll((body['results'] as List).map((e) => fromJson(e as Map<String, dynamic>)));
    page++;
  } while (body['next'] != null);
  return results;
}
```

## 4. Data Flow Examples

These walks show the request/response sequence the client drives for each key phase. They
reference the endpoint table above and the exact schema shapes in the contract.

### 4.1 Auth flow (first run)

```txt
1. POST /auth/register/            -> 201 { access, refresh, user{ is_onboarded:false } }
2. GET  /onboarding/               -> 200 { completed: false, profile: {…} }
   # is_onboarded=false => route to the onboarding wizard
   # (if is_onboarded=true, route straight to /dashboard)
3. On every protected call: Authorization: Bearer <access>
4. If 401: POST /auth/refresh/ { refresh } -> new access+refresh (rotated), retry once.
5. Logout: POST /auth/logout/ { refresh } -> 204 (token blacklisted).
```

### 4.2 Onboarding → plan selection

```txt
1. GET  /exercises/  (filter by equipment/muscle)  -> pick exercises for preference lists
2. GET  /muscles/ , GET /equipment/               -> fill option pickers (data-driven)
3. PUT  /onboarding/  body = OnboardingSubmit     -> 200 OnboardingResult
        { onboarding_completed:true, profile:{...}, active_goal:{...},
          recommended_plan:{ id, name, days: [...], ... } }
4. GET  /plans/  (objective=active_goal.type)     -> choose a plan
5. PUT  /users/me/current-plan/ { plan_id }       -> 200 Plan (now the current plan)
6. GET  /dashboard/                               -> today_workout / next_workout populated
```

### 4.3 Workout execution with set logging

```txt
1. GET  /dashboard/                       -> today_workout.workout_id & plan_day_id
2. GET  /workout-sessions/ ?status=planned -> find today's planned session (or schedule one)
   # If none: POST /plans/{plan_id}/days/{day_id}/schedule/ { scheduled_for: today } -> 201 Session
3. POST /workout-sessions/{id}/start/     -> 200 Session { status:'in_progress', exercises:[...] }
4. For each session exercise:
   a. GET  .../exercises/{seId}/previous/ -> show last time's sets + est 1RM (pre-fill targets)
   b. For each performed set:
      POST .../exercises/{seId}/sets/     { set_type:'working', weight_kg, reps, rpe, is_completed }
      # corrective edit optional: PATCH .../sets/{setId}/
   c. If equipment missing: POST .../exercises/{seId}/substitute/ { alternative_exercise_id } (or skip/)
5. POST /workout-sessions/{id}/complete/  { note? } -> 200 Session { status:'completed',
   duration_seconds }; backend recomputes PRs, volume, metrics, streak.
```

### 4.4 Previous-performance driven set logging

```txt
1. GET  .../exercises/{seId}/previous/
   { has_previous:true, last_session_date, last_sets:[{set_number,weight_kg,reps,...}],
     best_weight_kg, estimated_1rm }
2. UI pre-fills suggested weight/reps from last_sets + trial-set logic.
3. As the user logs sets via POST .../sets/, responses return the stored SessionSet.
4. On complete, PRs and metrics update server-side; GET /personal-records/ reflects new records.
```

### 4.5 Progress tracking

```txt
1. POST /measurements/  { measurement_type:'weight', value:82.5, unit:'kg' } -> 201
2. GET  /measurements/ ?measurement_type=weight&start_date=...&end_date=... -> trend series
3. GET  /progress-metrics/ ?metric_type=weekly_volume -> materialized chart data
4. GET  /personal-records/ ?metric=max_weight          -> PR badges
5. GET  /dashboard/                                    -> streak + weekly progress summary
```

## 5. Schema-to-Flutter Derivation Rules

- Generate Dart model classes (equatable/freezed) directly from the OpenAPI `components/schemas`
  (e.g. `Session`, `SessionSet`, `PreviousPerformance`, `Dashboard`). Do **not** hand-write a second
  shape that can drift.
- Enum fields map to Dart enums whose `name` is the exact string code above
  (e.g. `SessionStatus.completed` serializes to `'completed'`).
- Timestamps are ISO-8601 UTC (`format: date-time`); dates (`format: date`) are `yyyy-MM-dd`.
- `nullable: true` fields map to nullable Dart fields. Lists inside paginated envelopes come from
  `results`.
- Any question about a field name, type, or allowed value is answered by the OpenAPI contract and
  the T-05 data model — escalate to the Backend Lead if the two ever disagree rather than guessing.

## 6. Keeping this guide in sync

This document is a convenience reference, not the source of truth. Whenever the OpenAPI contract
changes, update the endpoint table and the Flutter examples in the same commit so the docs never
drift from the machine-readable contract.
