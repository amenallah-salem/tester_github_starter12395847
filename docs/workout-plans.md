# Seeded Workout Plan Templates

This document explains the three workout-plan templates seeded by
`python manage.py seed_workouts`, the research behind their structure, and how
to verify them.

## Research basis

The programming principles below (frequency, sets, rep ranges, training to
near-failure, compound-before-isolation ordering) are based on:

- ACSM's 2026 resistance-training position stand (first update in 17 years,
  synthesizing 137 systematic reviews): training all major muscle groups at
  least twice a week matters more than any specific split; hypertrophy
  benefits from roughly 10+ sets per muscle group per week; training within
  ~0-3 reps of failure produces equivalent hypertrophy/strength regardless of
  the exact rep range used, provided effort and volume are controlled.
  - https://acsm.org/resistance-training-guidelines-update-2026/
  - https://acsm.org/science-spotlight-acsm-releases-new-position-stand-on-resistance-training/
  - https://pubmed.ncbi.nlm.nih.gov/41843416/
- Comparative analyses of Push/Pull/Legs, Upper/Lower, and Full-Body splits:
  each split "wins" at the frequency it's built for (full-body at 3 days/week,
  upper/lower at 4, PPL at 6), and PPL/Upper-Lower both hit each muscle group
  twice a week when run at their intended frequency, which is the frequency
  band linked to the best hypertrophy outcomes.
  - https://styrki.com/blog/ppl-vs-upper-lower-vs-full-body
  - https://www.hevyapp.com/pplul-split/
  - https://universalperformancecoaching.com/2025/06/03/the-best-training-splits-for-muscle-growth-in-2025-a-practical-evidence-informed-guide/

These sources agree on the practical takeaways used below: hit each muscle
group at least twice a week, order compound lifts before isolation work, keep
rep ranges roughly 6-10 for heavy compounds and 10-15+ for isolation, and
prefer a split that matches how many days the user actually trains.

## Plans

All three plans are owned by a seed-only demo account (`wellaura_demo`, an
unusable-password account) created by the seed script, so they never touch a
real user's data. Each plan is represented using the app's existing
`Plan` -> `PlanDay` -> `PlanDayExercise` -> `Exercise` structure (the same one
the "week" editor in the app already uses) — a **rest day is simply the
absence of a `PlanDay` for that weekday**, which is how the existing
architecture already expresses rest without any new field or flag.

Every exercise referenced is an existing row in the exercise library
(`is_library=True`); no plan duplicates exercise data, images, or videos — the
plans only reference exercises by ID, so media lives in exactly one place
(`gym_api.Exercise.video_url` / `animation_url`).

Per-exercise sets/reps guidance comes from the exercise library's own
`target_sets` / `target_reps` fields (the only place the current schema
stores that data — `PlanDayExercise` has no per-assignment override), tuned
per exercise: ~3-4x6-10 for heavy compounds, ~3x8-12 for secondary compounds,
~2-3x10-15+ for isolation work. **The current schema has no rest-time field**
on `Exercise` or `PlanDayExercise`, so rest intervals are not seeded — this is
a known gap, not an oversight (see "Assumptions" below).

### 1. Push Pull Legs

3-way split, run twice across the week (6 training days, one rest day) so each
muscle group is trained roughly every 3-4 days:

| Weekday | Session | Focus |
|---|---|---|
| Mon | Push | Chest, front/lateral delts, triceps |
| Tue | Pull | Lats, upper back, traps, rear delts, biceps |
| Wed | Legs | Quads, hamstrings, glutes, calves |
| Thu | Rest | — |
| Fri | Push | (repeat) |
| Sat | Pull | (repeat) |
| Sun | Legs | (repeat) |

Each session is 6 exercises, compounds first:

- **Push**: Barbell Bench Press, Incline Dumbbell Press, Barbell Overhead
  Press, Dumbbell Lateral Raise, Triceps Pushdown, Lying Triceps Extension
- **Pull**: Pull-up, Bent Over Barbell Row, Seated Cable Row, Dumbbell Rear
  Delt Fly, Barbell Curl, Dumbbell Hammer Curl
- **Legs**: Barbell Back Squat, Romanian Deadlift, Walking Lunge, Leg
  Extension, Lying Leg Curl, Standing Calf Raise

### 2. Full Body

Three sessions (Mon/Wed/Fri), four rest days. Each session covers every major
movement pattern (squat, hinge, horizontal push, vertical push, horizontal
pull, vertical pull, plus one arms and one core exercise), with a different
exercise selection per session so the same patterns are trained through
different angles/equipment rather than repeating the same lifts three times:

- **Full Body A** (Mon): Barbell Back Squat, Romanian Deadlift, Barbell Bench
  Press, Barbell Overhead Press, Bent Over Barbell Row, Lat Pulldown, Barbell
  Curl, Front Plank
- **Full Body B** (Wed): Leg Press, Barbell Hip Thrust, Incline Dumbbell
  Press, Arnold Press, Seated Cable Row, Pull-up, Triceps Pushdown, Cable
  Crunch
- **Full Body C** (Fri): Walking Lunge, Glute Bridge, Push-up, Barbell
  Overhead Press, Bent Over Barbell Row, Lat Pulldown, Dumbbell Hammer Curl,
  Hanging Leg Raise

### 3. Upper Lower

Four sessions (Mon/Tue, Thu/Fri), weekend + Wednesday rest, so upper body and
lower body are each trained twice a week:

| Weekday | Session |
|---|---|
| Mon | Upper A |
| Tue | Lower A |
| Wed | Rest |
| Thu | Upper B |
| Fri | Lower B |
| Sat/Sun | Rest |

- **Upper A**: Barbell Bench Press, Lat Pulldown, Seated Cable Row, Barbell
  Overhead Press, Barbell Curl, Triceps Pushdown
- **Lower A**: Barbell Back Squat, Romanian Deadlift, Walking Lunge, Lying Leg
  Curl, Standing Calf Raise
- **Upper B** (different angles/equipment from A): Incline Dumbbell Press,
  Pull-up, Bent Over Barbell Row, Dumbbell Lateral Raise, Dumbbell Hammer
  Curl, Lying Triceps Extension
- **Lower B**: Leg Press, Romanian Deadlift, Walking Lunge, Leg Extension,
  Lying Leg Curl, Seated Calf Raise

## Running the seed script

```bash
./scripts/seed-dev-data.sh
```

or individually, inside the backend container:

```bash
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml exec backend python manage.py seed_exercises
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml exec backend python manage.py seed_workouts
```

`seed_workouts` requires the exercise library to already be seeded (it looks
up exercises by name and skips a plan with a warning if any referenced
exercise is missing). It is safe to run repeatedly:

- Plans/days/exercise-assignments are matched with `get_or_create` /
  `update_or_create` keyed on `(user, name)` for plans and `(plan, weekday)`
  for days, so re-running never creates duplicate rows.
- The two prior, less-precisely-named seed plans this script used to create
  (`Push / Pull / Legs`, `Upper / Lower Split`) are removed for the demo user
  only and replaced by `Push Pull Legs` / `Upper Lower` above.

## Verifying the result

```bash
# Exercise library still works (unchanged contract)
curl http://127.0.0.1:8000/api/library/exercises/
curl "http://127.0.0.1:8000/api/library/exercises/?body_part=Chest"

# Plans (requires an authenticated user's JWT)
curl -H "Authorization: Bearer <token>" http://127.0.0.1:8000/api/plans/
curl -H "Authorization: Bearer <token>" http://127.0.0.1:8000/api/plans/<plan_id>/week/
```

Run the backend test suite:

```bash
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml exec backend python manage.py test gym_api
```

## Assumptions

- Plans need an owning user (`Plan.user` is required, not nullable), so all
  seeded plans belong to a dedicated `wellaura_demo` account rather than a
  real user — matching the "do not touch real user data" rule.
- `PlanDayExercise` has no per-assignment sets/reps/rest fields, so those live
  on the shared `Exercise.target_sets` / `target_reps`. This means sets/reps
  guidance is per-exercise, not per-plan; two plans using the same exercise
  share the same guidance. This is an existing architecture limitation, not
  something introduced by this change.
- There is no rest-time (seconds between sets) field anywhere in the schema,
  so rest intervals are not part of the seeded data.
