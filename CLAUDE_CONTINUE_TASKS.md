Claude Code prompt: Continue Welora product implementation

Repository and branch
- GitHub: amenallah-salem/tester_github_starter12395847
- Working branch: feat/welora-exercise-workout-progress
- Local workspace root (for reference): /home/amen/Desktop/tester_github_starter12395847.worktrees/directory-code-understanding

Summary / context
You are continuing development of Welora (Flutter frontend + Django REST backend). Prior work completed and pushed includes:
- Exercise explorer, exercise catalog expansion
- Workout session creation and progress metric logging
- Progress UI with logged sets and deletion
- Progress analytics summary (volume, estimated 1RM, PR count)
- Offline session fallback and basic retry
- Exercise history & session detail views

Primary objective for this task
Implement the remaining product/UX features from the Stitch design system and production-hardening items listed below, and validate them with local tests and a web release build. Work incrementally and produce high-quality, tested commits. The user requests one combined commit later, but prefer multiple small commits if a task is large — ask the user only if split is necessary.

High-priority tasks (in order)
1. Form Vault favorites and persistence
   - Add UI for marking/unmarking favorites in Form Vault and Exercise Detail
   - Persist favorites to backend (new API) or locally (Drift) with sync
   - Expose a "Favorites" filter in Form Vault and Explorer
2. Kaori coaching chat (MVP)
   - Lightweight chat widget with persisted messages (local DB + backend endpoint placeholder)
   - UI for starting a Kaori-guided plan/feedback
3. Workout resume/history detail
   - Allow resuming an unfinished workout session (persist runner state locally)
   - Add richer session detail (duration, volume, per-exercise breakdown) using existing WorkoutSession serializers
4. Offline metric persistence and robust retry/sync UX
   - Ensure metrics created offline are queued in Drift and retried until confirmed
   - Add UI status for queued/syncing/failed items and retry button
5. Progress analytics improvements
   - Add trending charts and personal-record markers per exercise
   - Add an exercise-specific history page (already scaffolded) fully wired and visually matched to design
6. Machine calibration and workout setup flow
   - Implement the calibration UI (placeholder logic allowed) and store calibration entries per-device in profile
7. Accessibility, empty states, and error messages
   - Replace generic error strings with field-level errors and clear user-friendly copy
   - Ensure contrast, readable fonts, and screen-reader labels on key screens
8. Biomechanics placeholder improvements
   - Replace existing static replay with improved placeholder that explains capture limitation and provides a CTA for "Record movement" (device permission handling is out of scope)
9. Wearables & device connection placeholder
   - Provide UI for pairing and storing device metadata; stub backend endpoints

Files & locations to inspect (high-value)
- frontend/lib/features/progress/presentation/progress_page.dart
- frontend/lib/features/progress/presentation/exercise_history_page.dart
- frontend/lib/features/progress/presentation/session_detail_page.dart
- frontend/lib/features/plan_runner/presentation/plan_runner_page.dart
- frontend/lib/features/exercise_library/presentation/exercise_detail_page.dart
- frontend/lib/features/biomechanics/presentation/form_vault_page.dart
- frontend/lib/services/api_client.dart
- frontend/lib/features/exercise_library/data/exercise_repository.dart
- backend/gym_api/views.py
- backend/gym_api/serializers.py

Local validation commands (run from repo root)
- Backend tests (SQLite test mode):
  cd backend && DJANGO_TESTING=1 python manage.py test gym_api
- Frontend analyze & tests:
  cd frontend && flutter pub get
  cd frontend && dart run build_runner build --delete-conflicting-outputs
  cd frontend && flutter analyze --no-fatal-infos
  cd frontend && flutter test
- Web release build (for browser validation):
  cd frontend && flutter build web --release
  cd frontend/build/web && python3 -m http.server 8096
  Open http://127.0.0.1:8096 in browser

CI notes (important)
- CI runs the same analyze/test steps and fails if analyzer reports issues. Keep analyzer output clean of errors/warnings that CI treats as fatal.
- If CI fails because of Node deprecation warnings (actions), that's infra — prefer to fix code-level problems first.

Commit and PR policy
- Follow the repository's existing commit style: short subject + optional body (conventional-ish e.g. feat:, fix:, chore:, refactor:).
- Do not commit secrets or generated build artifacts (frontend/build/, .dart_tool/).
- Run tests and analyzer locally before pushing.
- Push to the same branch feat/welora-exercise-workout-progress and add a clear commit message describing the implemented tasks.

Acceptance criteria for each task (examples)
- Form Vault favorites: UI works, favorites persist across app restarts, accessible filter present, backend or local persistence tests added
- Kaori MVP: Chat UI persists messages; conversation stored in local DB; ability to export conversation to backend endpoint (stub OK)
- Offline queue: Create offline metric while offline, reopen app, metric is shown queued and later syncs to backend when online (simulate with local API)
- Analyzer: flutter analyze should not produce fatal issues; frontend tests pass
- Backend tests: all gym_api tests pass

Deliverables to produce and evidence
- Code changes committed and pushed to branch
- Tests updated/added for backend and frontend where applicable
- A release web build to validate major UI flows
- Short runbook in the commit/PR description summarizing what was done and how to validate manually

Constraints and caveats
- Do not add new large dependencies unless needed; prefer using existing Drift/local DB and HTTP client
- For heavyweight work (full biomechanics pipeline, wearables), create placeholders + clear TODOs and wire UI flows to those placeholders
- If unable to complete a task fully, implement a safe, test-covered placeholder and document next steps in the PR

Communication style and outputs
- After each completed feature, commit with a focused message and push. Add a short summary comment.
- If a CI failure is encountered, gather the failing job logs and fix only code-level issues.
- Report progress to the user in short, actionable updates.

Checklist for Claude Code to follow interactively
1. Pull the branch and inspect changed files.
2. Implement Task A (Form Vault favorites) and local tests.
3. Run backend and frontend tests locally. Fix any problems.
4. Build web release and validate visually.
5. Commit and push with a single combined commit if the user requests; otherwise make small commits per feature and push.
6. Record a link to the pushed commit in the PR description.

-- End of prompt --


Notes: send this entire prompt to Claude Code. Adjust any environment paths as needed for your execution environment.