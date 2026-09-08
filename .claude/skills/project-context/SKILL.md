# WELLAURA Project Context Skill

Use this skill whenever you need to understand the repository before coding.

## Goal
Build a compact mental model without scanning the whole repository.

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

