# Gym Planner Application Guide

## What the application is

Gym Planner is a fitness application with a Flutter frontend and a Django REST
backend.

The frontend supports:

- Account creation and sign-in
- JWT authentication
- Onboarding for goals, experience, equipment, and training preferences
- Workout plans and exercise lists
- A workout runner with work and rest timers
- Workout history and progress tracking
- Exercise library, recovery, and biomechanics screens
- Profile settings and subscription state

The backend provides:

- PostgreSQL persistence
- User profiles
- Training plans
- Exercises
- Workout sessions
- Progress metrics
- Subscription records
- JWT authentication and ownership checks

## Important directories

```text
frontend/lib/                         Flutter application code
frontend/lib/core/router/             GoRouter navigation
frontend/lib/core/state/              Riverpod application/auth state
frontend/lib/services/                Django API client
frontend/lib/features/auth/           Sign-in and registration
frontend/lib/features/onboarding/     Onboarding flow
frontend/lib/features/plan/           Plan state and Today screen
frontend/lib/features/plan_runner/    Workout execution and timers
frontend/lib/features/progress/       History and progress UI
frontend/lib/features/you/            Profile and settings

backend/gym_api/models.py             Django data models
backend/gym_api/serializers.py        API validation and response shapes
backend/gym_api/views.py              REST API viewsets
backend/gym_api/urls.py               API routes
backend/gym_project/settings.py       Django configuration
```

## Run with Docker

From the repository root, start the database and backend:

```bash
docker compose up --build -d
docker compose ps
docker compose logs -f backend
```

The backend is available at:

- API: <http://localhost:8000/api/>
- Admin: <http://localhost:8000/admin/>
- PostgreSQL: `localhost:5432`

Run backend tests:

```bash
docker compose exec backend python manage.py test gym_api
```

Start the Flutter web frontend:

```bash
docker compose -f docker-compose.frontend.yml up --build -d
docker compose -f docker-compose.frontend.yml ps
```

Open <http://localhost:8080>.

Stop the services:

```bash
docker compose down
docker compose -f docker-compose.frontend.yml down
```

## Run Flutter directly

Requires Flutter 3.24 or later:

```bash
cd frontend
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze --no-fatal-infos
flutter test
flutter run -d chrome
```

For Android:

```bash
flutter devices
flutter run -d <device-id>
```

## How Claude Code should edit the repository

Start Claude Code from the repository root:

```bash
cd /path/to/directory-code-understanding
claude
```

Useful task examples:

```text
Inspect the Flutter authentication and onboarding flow. Fix navigation without
removing JWT ownership checks, then run flutter analyze and flutter test.
```

```text
Add a workout-history endpoint to Django, connect it to the Flutter Progress
page, add focused backend tests, and validate the Docker stack.
```

```text
Improve the onboarding UI while preserving its existing route behavior. Run
the relevant Flutter tests afterward.
```

Recommended project instructions:

```text
This is a Flutter frontend and Django REST backend.
The frontend runs at http://localhost:8080 and the API at http://localhost:8000.
Use Docker for backend validation.
Make focused changes, preserve authentication and ownership checks, and run
targeted tests after editing.
```

Avoid editing the same files concurrently with another coding assistant.
