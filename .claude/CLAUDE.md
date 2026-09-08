# WELLAURA — Claude Code Operating Instructions

## Mission
WELLAURA is a fitness and well-being application that helps users train efficiently while supporting recovery, goals, mindfulness/breathwork, lifestyle habits, and coaching experiences.

The repository currently contains a Flutter frontend, Django REST backend, PostgreSQL, Docker-based development/production stacks, local persistence/offline capabilities, exercise data, and GitHub Actions.

## Repository Map
- `frontend/` — Flutter application.
- `backend/` — Django REST API and database-facing business logic.
- `backend/gym_api/` — primary Django application.
- `.claude/skills/` — reusable engineering instructions.
- `.github/workflows/` — CI and Android release workflows.
- `docker-compose.backend.dev.yml` — development DB + backend.
- `docker-compose.frontend.dev.yml` — development frontend.
- `docker-compose.backend.prod.yml` — production DB + backend.
- `docker-compose.frontend.prod.yml` — production frontend.
- `docker.dev.sh` — preferred development stack launcher.
- `docker.prod.sh` — preferred production stack launcher.
- `asserts/` — project visual/reference assets.

## Stack
- Flutter / Dart
- Riverpod
- GoRouter
- Drift / SQLite for local persistence
- Django
- Django REST Framework
- PostgreSQL
- Docker / Docker Compose
- GitHub Actions

## Golden Rules
1. Preserve working functionality.
2. Prefer the smallest correct change.
3. Reuse established project patterns before introducing new ones.
4. Do not rewrite architecture without evidence.
5. Do not add dependencies unless they solve a real requirement.
6. Never commit secrets or expose `.env` values.
7. Never reset/delete the database merely to fix an application bug.
8. Never modify migration history just to hide a migration problem.
9. Keep frontend/backend contracts explicit and compatible.
10. Test meaningful changes before declaring them complete.
11. Do not touch unrelated files.
12. Do not claim a feature is implemented unless it is actually wired and validated.

## Investigation Before Implementation
For any non-trivial task:
1. Read the relevant skill(s).
2. Inspect repository structure only as needed.
3. Locate the current implementation.
4. Trace the affected flow end-to-end.
5. Identify the root cause or exact change boundary.
6. State a concise plan before making broad changes.
7. Implement incrementally.
8. Validate the actual behavior.

Do not start by scanning the entire repository. Use targeted searches and follow references outward.

## Project Startup
Preferred development command from the repository root:

```bash
./docker.dev.sh up
```

Build only:

```bash
./docker.dev.sh build
```

Development services:
- Frontend: `http://127.0.0.1:8080`
- Backend: `http://127.0.0.1:8000`
- Health endpoint: `http://127.0.0.1:8000/api/health/`
- PostgreSQL: `127.0.0.1:${POSTGRES_PORT:-5432}`

The development script uses `.env.dev` when present and combines:
- `docker-compose.backend.dev.yml`
- `docker-compose.frontend.dev.yml`

Do not invent a `docker-compose.yml` file. Use the actual compose files/scripts in this repository.

### Backend-only development
```bash
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml up --build
```

### Frontend-only development container
```bash
docker compose -f docker-compose.frontend.dev.yml up --build
```

### Production-like stack
Use only when explicitly needed:

```bash
./docker.prod.sh up
```

Never use production startup to debug a normal development issue unless the task specifically concerns production behavior.

## Backend Commands
Inside the backend container:

```bash
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml exec backend python manage.py test gym_api
```

Useful commands:
```bash
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml exec backend python manage.py migrate

docker compose --env-file .env.dev -f docker-compose.backend.dev.yml exec backend python manage.py makemigrations

docker compose --env-file .env.dev -f docker-compose.backend.dev.yml exec backend python manage.py createsuperuser

docker compose --env-file .env.dev -f docker-compose.backend.dev.yml logs -f backend
```

Before inventing a command, inspect the Dockerfile, compose files, and backend README.

## Flutter Commands
If Flutter is installed on the host, run from `frontend/`:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

If Flutter is not installed, use the repository's Docker/frontend setup where appropriate. Do not assume a host Flutter installation exists.

## Validation Standard
A task is complete only when appropriate checks pass:
- targeted tests
- backend tests for backend changes
- `flutter analyze` / targeted Flutter tests for frontend changes when available
- Docker Compose configuration validation for infrastructure changes
- application startup/health check when startup/infrastructure changed
- git diff review

If a check cannot be run, report exactly why. Never pretend it passed.

## Git Discipline
- Keep commits focused.
- Do not mix refactors with feature fixes unless required.
- Never commit `.env`, credentials, API keys, tokens, or private keys.
- Inspect `git diff` before committing.
- Do not force-push or rewrite history unless explicitly requested.
- Use the repository's existing branch/workflow conventions.

## Cost Efficiency
Optimize for useful work per token/tool call:
- search narrowly before reading large files
- read only relevant ranges/files
- do not repeatedly inspect unchanged files
- avoid generated/build/cache/vendor directories
- reuse knowledge established during the current task
- run the smallest relevant test set first
- expand validation only when necessary
- do not make speculative edits

## Definition of Done
Before saying "done":
- root cause/requirement is understood
- implementation is complete
- relevant validation was executed
- failures were resolved or clearly reported
- no unrelated changes were introduced
- security/secrets were checked
- documentation was updated if behavior/commands changed
