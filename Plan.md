# Agent Brief: Gym App — Tier 1 + Tier 2 Implementation

## Context

You're working on a Django (DRF) + Flutter (Riverpod, go_router) gym
training-log app. This is a **rewrite** of an earlier prototype — some
backend models and Flutter scaffolding already exist and are good
starting points. You are not building from a blank repo.

**Already done — do not redo:**
- JWT auth (`djangorestframework-simplejwt`) — login/register/refresh work.
- Django models: `Profile`, `Plan`, `Exercise`, `WorkoutSession`,
  `ProgressMetric` — read `backend/gym_api/models.py` before changing
  anything. Reuse and extend these; don't replace them wholesale.
- Flutter scaffolding exists for: exercise library, plan pages, a workout
  runner page with a timer widget, progress/history pages. Read the
  existing files under `frontend/lib/features/` before writing new ones —
  extend what's there, don't duplicate it.

**Explicitly out of scope — do not build, do not suggest, do not leave
stubs for:** AI coach/chat features, billing/subscriptions, 3D
biomechanics/pose replay, breathwork/recovery content, social features.
If you find existing code for these, leave it alone unless asked —
don't extend it.

**Inspiration, not copying:** Some feature *ideas* below are inspired by
an existing open-source app (openGym), described here in plain language.
You have not seen and must not reference or copy that app's source code,
UI text, or asset names. Implement the underlying idea as original code
that fits this codebase's existing patterns and naming. Everything you
write is this project's own property.

---

## Ground rules for this work

1. **One numbered item at a time.** Finish, test, and report back before
   moving to the next. Do not implement multiple items in one pass.
2. **Read before writing.** For each item, first read the relevant
   existing model/file and summarize what's there and what you plan to
   change, before writing code.
3. **Every backend change ships with:** a migration, at least one test
   per new endpoint (happy path + one failure case), and an update to
   the DRF serializer/viewset pattern already used in this project.
4. **Every Flutter change**: reuse the existing Riverpod provider pattern
   and folder structure (`features/<name>/{data,domain,presentation,state}`).
   Don't introduce a second state-management approach.
5. **No offline/local database work.** This app is API-only for now —
   don't add or extend any local SQLite/Drift persistence.
6. **Commit after each numbered item**, with a message naming the item
   (e.g. `feat: weekly plan per weekday (Tier 1.2)`).
7. If an item seems to require something out of scope (see above), stop
   and ask rather than expanding scope on your own.

---

## Tier 1 — Core loop (do these in order)

### 1.1 Exercise library: search + filter
- Add search-by-name and filter-by-`body_part` query params to the
  existing exercise list endpoint.
- Flutter: wire the existing exercise library screen's search/filter UI
  to these query params (replace any mock data).
- No exercise images/animations — text only for now.

### 1.2 Weekly plan: a routine per weekday
- Add a new model tying a `Plan` to a specific weekday (0–6) with an
  ordered list of exercises for that day. Design the schema yourself,
  fitting the existing `Plan`/`Exercise` relationship style.
- Endpoint(s) to read/write a full week's assignment.
- Flutter: on the home screen, show a 7-day strip; tapping a day shows/edits
  that day's exercise list.
- Seed one example plan (not four templates) so there's something to see.

### 1.3 Guided workout session
- Endpoint: given an exercise, return the most recent logged set for the
  current user (for pre-filling weight/reps).
- Session flow: starting "today's workout" resolves to the weekday's
  assigned plan from 1.2.
- Flutter: wire the existing workout-runner screen and timer widget to
  real API data — replace any mock/sample data. Rest timer between sets.

### 1.4 Set logging
- Confirm the existing `ProgressMetric` model supports: reps, weight,
  set number, per exercise, per session. Extend only if something's
  actually missing for this use case.
- Flutter: the set-logging rows in the workout runner should POST to the
  real endpoint per set, not batch at the end.

### 1.5 Reschedule a day
- Add a way to start a session for a day other than today, without
  altering the weekly plan template from 1.2. Design the
  field/relationship (e.g. a scheduled date separate from the plan's
  weekday) yourself.
- Flutter: a simple "move to another day" action from the day view.

### 1.6 Body-weight tracking
- New model: user, weight, logged-at timestamp. This is new — it doesn't
  exist yet in the current models.
- Endpoint: log + list body-weight entries for the current user.
- Flutter: use the existing progress/chart screen, point it at real data
  instead of mock data. Simple line chart, no goal-line logic yet.

### 1.7 Basic stats
- One aggregation endpoint: total volume (sum of weight×reps) over time,
  workout count per week. No heatmap, no muscle-group breakdown yet.
- Flutter: wire the existing progress/history screens to this endpoint.

**Checkpoint after Tier 1:** a user can register, build a weekly plan,
start today's guided workout, log sets with pre-filled weights from last
time, reschedule a session to another day, log body weight, and see a
basic volume chart. Confirm this full loop works manually before Tier 2.

---

## Tier 2 — Do only after Tier 1 checkpoint passes

### 2.1 PR detection
- When a set is logged, compare it against the user's best-ever for that
  exercise (by weight, or by weight×reps — pick one consistent rule and
  document it in a code comment). Flag if it's a new best.
- Flutter: show a simple "new PR" indicator when logging that set.

### 2.2 Favorite exercises
- Add a favorite flag/relation between user and exercise.
- Flutter: favorites sort first in the exercise picker/library.

### 2.3 Freestyle sessions
- Allow starting a workout with no assigned plan for that day; exercises
  are picked ad hoc during the session.
- Each freestyle-picked exercise pre-fills from the user's last log for
  it (reuse the endpoint from 1.3).

### 2.4 Screen-stays-awake during a workout
- Add a wakelock package to the Flutter project; enable it only while a
  workout session is actively running, release it when the session ends.

### 2.5 Timed exercises
- Add a way to mark an exercise as logged-by-duration instead of
  reps (e.g. planks, holds).
- Flutter: the set-logging row shows a duration input/timer instead of a
  reps input for these exercises.

**Checkpoint after Tier 2:** report back with what was built, what
deviated from this brief and why, and a short list of anything you think
needs cleanup before Tier 3 (which is not part of this brief).

---

## Before you start

Read `backend/gym_api/models.py`, `backend/gym_api/serializers.py`,
`backend/gym_api/views.py`, and the Flutter files under
`frontend/lib/features/{exercise_library,plan,plan_runner,progress}/`.
Summarize the current state of each in a few sentences before starting
1.1, so we both know what you're building on top of.

