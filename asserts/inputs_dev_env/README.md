# Dev/test environment: JSON-driven seed data

## Where it lives

```
asserts/inputs_dev_env/json_file.json
```

This single file is the **source of truth** for every test user, exercise,
workout plan, plan assignment and workout history record in the
development environment. Nothing is hard-coded in Python or Bash:

```
asserts/inputs_dev_env/json_file.json
                ↓
scripts/init_test_environment.sh
                ↓
backend/gym_api/management/commands/init_test_environment.py
                ↓
database
```

To change what test data exists, edit the JSON file and re-run the script —
you never need to touch the shell script or the Django command.

## Running it

```bash
./scripts/init_test_environment.sh
```

This requires the dev backend to already be running (`./docker.dev.sh up`).
It calls `python manage.py init_test_environment` inside the `backend`
container.

Useful flags (passed straight through to the management command):

```bash
# Validate the JSON without writing anything to the database
./scripts/init_test_environment.sh --check-only

# Use a different JSON file (e.g. a scratch copy while editing)
./scripts/init_test_environment.sh --file /path/to/other.json
```

The command is **idempotent**: re-running it updates/reuses existing rows
(matched by the stable ids described below) instead of duplicating them.
It's also **fail-safe**: the entire file is validated *before* anything is
written, and the whole import runs in one database transaction — if
anything unexpected happens partway through, nothing is left half-written.

## JSON structure

Top level:

```json
{
  "users": [],
  "exercises": [],
  "plans": [],
  "user_plans": [],
  "workout_history": []
}
```

### `users`

Each user carries a stable string `id` used to reference them elsewhere in
the file (this is **not** the database primary key — the command resolves
it to a real `User`/`Profile` row by `username`).

```json
{
  "id": "alex_strength",
  "username": "alex_strength",
  "email": "alex.strength@example.com",
  "password": "Test12345!",
  "first_name": "Alex",
  "last_name": "Martin",
  "is_staff": false,
  "is_superuser": false,
  "profile": {
    "display_name": "Alex Martin",
    "bio": "Powerlifting-focused lifter chasing a 200kg deadlift.",
    "training_goals": ["strength", "hypertrophy"],
    "experience_level": "intermediate",
    "availability": "Weekday mornings, Sat afternoons",
    "location": "Lyon, FR",
    "onboarding_completed": true,
    "avatar": "27hzn4y....jpeg"
  },
  "favorite_exercises": ["barbell_bench_press", "deadlift"],
  "body_weight_log": [
    { "weight_kg": 82.4, "logged_at": "2026-08-11T07:00:00Z" }
  ]
}
```

- `training_goals` must use `Profile.GOAL_CHOICES` values (`strength`,
  `cardio`, `general_fitness`, `hypertrophy`, `weight_loss`, `flexibility`).
- `experience_level` must be `beginner`, `intermediate` or `advanced`.
- `avatar` is a **filename only** (no image data, no path) — it must exist
  in `asserts/avatars/`. The initializer copies that file into the
  `Profile.avatar` field (backed by Django's normal media storage) the
  first time it sees it, and leaves it alone on later runs.
- `favorite_exercises` and `body_weight_log` are optional.

### `exercises`

The shared exercise library (`Exercise.is_library = True`). Each has a
stable `id` referenced from `plans`, `workout_history`, and
`favorite_exercises`.

```json
{
  "id": "barbell_bench_press",
  "name": "Barbell Bench Press",
  "body_part": "Chest",
  "primary_muscles": ["Chest"],
  "secondary_muscles": ["Triceps", "Shoulders"],
  "equipment": ["Barbell", "Bench"],
  "movement_pattern": "Horizontal Push",
  "exercise_type": "Compound",
  "difficulty": "Intermediate",
  "is_timed": false,
  "target_sets": 4,
  "target_reps": 8,
  "instructions": "Lie on a flat bench, lower the bar to mid-chest, then press up to lockout.",
  "is_library": true
}
```

`body_part`, `movement_pattern`, `exercise_type` and `difficulty` must match
the choices on the `Exercise` model (see `backend/gym_api/models.py`).

### `plans`

Plan **templates** — a name/description plus a weekly schedule of exercise
ids. A template on its own doesn't create anything in the database; it only
takes effect once referenced from `user_plans` (see below), because in this
app a `Plan` row is always owned by one user.

```json
{
  "id": "push_pull_legs",
  "name": "Push Pull Legs",
  "description": "Classic 3-way body-part split run across the working week.",
  "is_active": true,
  "days": [
    { "weekday": 0, "exercises": ["barbell_bench_press", "barbell_overhead_press"] },
    { "weekday": 2, "exercises": ["pull_up", "bent_over_barbell_row"] }
  ]
}
```

`weekday` is `0` = Monday … `6` = Sunday (matches `PlanDay.weekday`).

### `user_plans`

Assigns a plan template to a user — i.e. "this user follows this plan".
Because `Plan.user` is a single owner in the data model (not a
many-to-many "followers" list), assigning the same `plan_id` to multiple
users gives each of them their **own** `Plan` row with the same name/
description/schedule, rather than one shared row. That's why a
`workout_history` entry that references a `plan_id` must have a matching
`user_plans` entry for that same user — otherwise there's no plan for that
user to point the session at.

```json
{ "user_id": "alex_strength", "plan_id": "push_pull_legs" }
```

### `workout_history`

A completed (or partially logged) workout session, with sets/reps/weight
and, for cardio/timed exercises, `duration_seconds`.

```json
{
  "user_id": "alex_strength",
  "plan_id": "push_pull_legs",
  "name": "Push Day",
  "scheduled_for": "2026-09-01",
  "started_at": "2026-09-01T07:00:00Z",
  "finished_at": "2026-09-01T08:05:00Z",
  "notes": "Felt strong on bench today.",
  "exercises": [
    {
      "exercise_id": "barbell_bench_press",
      "sets": [
        { "set_number": 1, "reps": 8, "weight_kg": 70 },
        { "set_number": 2, "reps": 8, "weight_kg": 75 }
      ]
    }
  ]
}
```

For cardio/activity-only sets, set `reps: 0`, `weight_kg: null`, and use
`duration_seconds` instead (see the `treadmill_running` / `jump_rope`
entries in the shipped `json_file.json` for examples).

`plan_id` is optional — omit it for a freestyle/unplanned session.

A session is identified, for idempotency purposes, by
`(user_id, name, scheduled_for)` — re-running the initializer with the same
triple updates that session (and fully replaces its sets) instead of
creating a duplicate. Two entries with the same triple in the same file are
rejected as a duplicate identifier.

## Validation

Running the initializer always validates the **entire** file before writing
anything. It reports every problem it finds (not just the first one) and
exits without touching the database if any are found. Checks include:

- missing required fields (`id`, `username`, `name`, …)
- duplicate ids (`users[].id`, `exercises[].id`, `plans[].id`, duplicate
  `user_plans`/`workout_history` entries)
- unknown references (`favorite_exercises`, plan-day exercises,
  `user_plans.user_id`/`plan_id`, `workout_history.user_id`/`plan_id`/
  `exercise_id`), including a `workout_history` entry pointing at a
  `plan_id` the user isn't assigned in `user_plans`
- invalid enum values (body part, movement pattern, exercise type,
  difficulty, experience level, training goals)
- invalid dates/datetimes (`scheduled_for`, `started_at`, `finished_at`,
  `logged_at`), including `finished_at` earlier than `started_at`
- invalid types/values (negative reps/weight/duration, non-boolean flags,
  weekday outside 0-6, etc.)

Use `--check-only` to run just the validation step, e.g. while editing the
JSON:

```bash
./scripts/init_test_environment.sh --check-only
```

## How to extend it

All of these are edits to `asserts/inputs_dev_env/json_file.json` only,
followed by `./scripts/init_test_environment.sh`.

**Add a test user** — append an object to `users` with a new `id`/
`username`. Add a `profile` block if you want bio/goals/avatar populated.

**Add an exercise** — append an object to `exercises` with a new `id`.
Reference that `id` from any plan's `days[].exercises` or from
`workout_history[].exercises[].exercise_id`.

**Add a workout plan** — append a template to `plans` with a new `id` and
its weekly `days`. On its own this does nothing until…

**Assign a plan to a user** — add `{ "user_id": ..., "plan_id": ... }` to
`user_plans`. The same `plan_id` can be assigned to several users.

**Add workout history** — append an entry to `workout_history` with the
`user_id`, optional `plan_id` (must be assigned to that user via
`user_plans`), a session `name`, dates, and the `exercises`/`sets` performed.

**Assign an avatar** — set `profile.avatar` to a filename that exists in
`asserts/avatars/`.

After editing, re-run:

```bash
./scripts/init_test_environment.sh
```

## Notes for maintainers

- The Django command lives at
  `backend/gym_api/management/commands/init_test_environment.py`. It
  contains only import/validation *logic* — no test data.
- `docker-compose.backend.dev.yml` mounts the repo's `asserts/` directory
  read-only into the backend container at `/asserts` so the command can
  read both the JSON file and the avatar images.
- `Profile.avatar` is a normal Django `ImageField` (`upload_to='avatars/'`);
  the command copies the referenced file from `asserts/avatars/` into
  Django's media storage the first time it's assigned.
- This initializer is separate from the older, hard-coded
  `seed_exercises`/`seed_workouts` management commands
  (`scripts/seed-dev-data.sh`), which seed the shared exercise library and
  demo plans for the `wellaura_demo` account. Both can coexist; this one is
  for fully-populated, reproducible test *accounts*.
