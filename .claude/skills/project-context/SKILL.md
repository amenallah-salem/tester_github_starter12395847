# WELLAURA Project Context Skill

Use this skill whenever you need to understand the repository before coding.

## Goal
Build a compact mental model without scanning the whole repository.

## App Concept
WELLAURA ("welora" in the UI) is a mobile-first fitness/well-being app: a
solo training coach (plan generation, a library-backed exercise browser,
workout logging, progress tracking) plus a social layer ("Gym Bro" matching)
and a lightweight mindfulness layer (breathwork, recovery). It's a single
Flutter codebase (`frontend/`) talking to one Django REST API (`backend/`),
no separate services. Below is the shape of each piece, not just its file
path — enough to hold a real conversation about how the app works.

**The five bottom-nav tabs** (`frontend/lib/features/home/presentation/home_page.dart`),
each a `ShellRoute` child so the nav bar persists:
- **Home** (`/`, `PlanPage`) — the daily dashboard: greeting, weekly-rhythm
  bento cards, a category grid (Strength/Mobility/Cardio/Recovery, all of
  which just deep-link into the Explorer filtered by that category), an
  editable weekly schedule ("Your week" — pick a weekday, assign exercises,
  "Start this day"), and the AI-generated plan's *today* session with a
  "Start workout" CTA. Also carries the entry point into the AI Coach chat.
- **Workouts** (`/explorer`, `ExerciseExplorerPage`) — the exercise library:
  search + muscle-group filter chips, a card per exercise (image thumbnail,
  difficulty/type badges, favorite star), tapping pushes the exercise detail
  page. Also has entry points to My Plans, Form Vault, and the AI Coach.
- **Progress** (`/progress`, `ProgressPage`) — history and analytics: streak,
  lift volume, personal records, week/month toggle, body-weight log with a
  hand-drawn trend line, per-exercise lift-progress cards, a rhythm bar chart,
  a muscle-load chart, a recovery indicator, and the raw session/set history
  (tap a logged set to see its exercise history, tap a session for detail).
- **Profile** (`/you`, `YouPage`) — account/profile settings.
- (No literal "Train" tab — Train/AI-Coach is reached *from* Home and
  Workouts, not from the bottom nav; see the gotcha below if this ever
  regresses.)

**Two overlapping "plan" systems** — see the gotcha below for the full
explanation; in short, the Home dashboard runs on an AI-generated
`WorkoutPlan` contract, while `/plans` is the real backend-CRUD `Plan` model
with a weekly schedule, and `PlanNotifier` bridges the two.

**Exercise library** — `Exercise` (`backend/gym_api/models.py`) is a rich,
mostly admin-authored reference record: name/aliases, body part, primary +
secondary muscles, equipment, movement pattern, exercise type, difficulty,
instructions split into setup/execution/breathing, common mistakes, an
optional demo image/animation/video, and self-referential
alternatives/progressions/regressions (easier/harder variants — the exercise
detail page renders these as tappable chips that push a new detail route,
so browsing the library is partly a graph walk). The same `Exercise` model
doubles as a per-plan-day assignment row (`is_library=False`, tied to a
`user`/`plan`) versus a shared catalog entry (`is_library=True`, `user=None`)
— one table, two roles, disambiguated by `is_library`.

**Running a workout** — `WorkoutSession` (start/finish timestamps, optional
link to a `Plan`) groups `ProgressMetric` rows (one row per logged set: reps,
weight, duration, which exercise). `frontend/lib/features/plan_runner/` is
the live workout screen (set-by-set logging, rest timers, freestyle mode for
an unplanned session); finishing feeds `WorkoutSessions`/`ProgressMetric`
providers that the Progress tab reads back.

**AI Coach ("Kaori")** — `frontend/lib/features/coach/` (route `/coach`,
outside the shell so it gets its own back button) is a chat-style assistant:
post-workout check-ins, conversational Q&A, and inline "form analysis" cards
with a percentage score and a "Review biomechanical replay" action that opens
`frontend/lib/features/biomechanics/` (`FormVaultPage` — saved form-check
history; `replay_3d_page.dart` — a mocked 3D rep replay). This is currently
UI/mock-data driven (`biomechanics/data/biomechanics_mock.dart`), not backed
by a real pose-estimation pipeline yet.

**Gym Bro** (`frontend/lib/features/gym_bro/`, backend `Swipe`/`Match`/
`GymBroMessage` models) — a Tinder-style workout-partner matching layer on
top of `Profile` (goals/experience/availability/location): discover
candidates, swipe like/pass, chat once matched. Fully separate from the
training/progress domain; only shares the `Profile` model.

**Recovery & mindfulness** (`frontend/lib/features/recovery/`) — a
post-workout "session complete" recovery screen (RPE/recovery mock metrics)
and a standalone breathwork timer (`/breathwork`). Currently client-only, no
dedicated backend model — this is the app's nod to "well-being" beyond pure
strength training.

**Auth & onboarding** — JWT access/refresh via `rest_framework_simplejwt`.
Refresh tokens live in the OS keychain on mobile (`flutter_secure_storage`)
and in `SharedPreferences`/localStorage on web (no secure-storage equivalent
there). A `Profile.onboarding_completed` flag (plus a local
`SharedPreferences` mirror) gates a first-run wizard (goal, experience,
equipment, schedule) that produces the initial AI `WorkoutPlan`; the router's
top-level `redirect` is the single place that decides sign-in vs onboarding
vs main-app routing based on `authStatusProvider` + `onboardingDoneProvider`.

**Billing** — a `Subscription` model/endpoint exists (`plan_name`, `status`,
period dates). No dedicated `features/billing/` module — it's surfaced
directly inline in `features/you/presentation/you_page.dart` (the Profile
tab fetches and can upgrade the subscription from there), not its own route.

## Procedure
1. Start at repository root.
2. Inspect only top-level files/directories relevant to the request.
3. Read `CLAUDE.md` first.
4. For backend work inspect `backend/README.md`, Django settings/URLs, models, serializers, views, tests, and relevant migrations.
5. For Flutter work inspect `frontend/pubspec.yaml`, routing, providers/state, repositories/API client, models, and the affected feature.
6. For infrastructure inspect Dockerfiles, compose files, shell scripts, and CI workflows.
7. Search for the feature name/symbol before opening unrelated files.
8. Record important findings mentally and avoid rereading unchanged files.

## Do Not
- scan `build/`, caches, `.git/`, dependency/vendor directories, or generated artifacts
- read every file just to "understand the project"
- infer architecture from filenames when source code can confirm it
- create duplicate abstractions when an existing one can be reused

## Output
Before a non-trivial implementation, be able to answer:
- where the feature lives
- how data flows
- which files must change
- which tests validate it
- how to run the affected part

## Known Domain Gotchas
Concrete traps discovered during real feature work — check these before re-deriving them from scratch.

- **Two unrelated "Plan" concepts exist.** (1) The real backend `Plan`/`PlanDay`/`PlanDayExercise` Django models — full CRUD, multiple named plans per user, weekly schedule via `/plans/{id}/week/`, surfaced in the frontend at `frontend/lib/features/plans/` (list + detail, reachable from the calendar icon on the Workouts tab). (2) The AI-coach `WorkoutPlan` contract (`frontend/lib/features/plan/domain/plan_contract.dart`), a separate JSON schema used only by the Home tab dashboard (`features/plan/presentation/plan_page.dart`, `plan_notifier.dart`). `PlanNotifier.refreshFromApi()` bridges the two by mapping the user's first real `Plan`'s week into the AI-shaped contract. When a task mentions "plans," confirm which one before touching code — they look similar but are not interchangeable.
- **DRF pagination silently truncates catalog endpoints.** `backend/gym_project/settings.py` sets a global `PAGE_SIZE = 10`. Any ViewSet meant to return a full bounded reference dataset (e.g. the exercise library) needs `pagination_class = None` explicitly, or clients only ever see the first page with no obvious error. Check this first when something reports "not all items are showing."
- **Self-referential M2M fields serialize as bare PK lists by default.** DRF's `ModelSerializer` renders M2M relations (e.g. `Exercise.alternatives`/`progression_exercises`/`regression_exercises`) as UUID lists, not nested objects. To show names/details, add a read-only `SerializerMethodField` or nested serializer (see `ExerciseMinimalSerializer` in `serializers.py`) alongside the writable PK field — don't replace the PK field, it's still needed for writes.
- **`frontend/lib/models/` and `frontend/lib/pages/`** (top-level, outside `features/`) have historically held unrouted, superseded duplicates of feature-folder code. Before reusing something found there, grep whether `app_router.dart` actually imports it — it may be dead code left over from an earlier iteration.
- **Exercise identity is the backend UUID, not the name.** Navigate/look up exercises by `id`; an earlier version of the app routed by URL-encoded name, which broke on rename/casing and made cross-linking (alternatives, plan schedules) unreliable.
- **A real headless browser is available for self-verification.** `google-chrome` is on PATH and `playwright` (Python) is installed, but the default Playwright Chromium download is missing — launch with `p.chromium.launch(executable_path="/usr/bin/google-chrome", args=["--no-sandbox"])` instead of a bare `launch()`. This app renders via CanvasKit, so there are no real DOM `<input>`/button elements to select — drive it with `page.mouse.click(x, y)` on coordinates read off a screenshot, plus `page.keyboard.type(...)`, and verify by screenshotting rather than `page.inner_text`. `page.url` can read stale on this app's hash-based GoRouter navigation immediately after a click; trust a screenshot over a `page.url` check taken right after navigating. Full login on web requires clicking through `/onboarding` for any account with `onboarding_completed=False` (the "I'll do this later" button skips it) — check/patch `Profile.onboarding_completed` via `manage.py shell` first if testing an existing seeded account.

