# WELLAURA

> **Your AI-powered fitness & wellness companion.**  
> **Train well. Live well.**

WELLAURA is a full-stack fitness and wellness application designed to help people train with more structure, understand their progress, and build healthier routines.

The product combines workout planning and execution with an exercise library, progress tracking, recovery and breathwork experiences, personalized onboarding, and an in-app coaching experience. The current repository is an active development/MVP codebase rather than a finished production SaaS.

---

## ✨ What WELLAURA Includes

### Training
- Personalized training plans and plan-day organization
- Guided workout sessions
- Freestyle workouts
- Set/repetition/weight tracking
- Workout timer
- Scheduled workout dates
- Exercise history

### Exercise Library
- Searchable exercise library
- Muscle/body-part filtering
- Exercise details and instructions
- Equipment, movement pattern, difficulty, and exercise type metadata
- Exercise alternatives, progressions, and regressions
- Favorites
- Exercise images, video URLs, and animation URLs where available

### Progress
- Workout session history
- Per-exercise history
- Progress metrics
- Body-weight tracking
- Progress visualization

### Wellness & Recovery
- Post-workout recovery experience
- Guided breathwork
- Recovery reminders
- Mindful training/recovery concepts

### Coaching & Form
- In-app coach experience
- Form Vault / biomechanics-oriented screens
- 3D replay interface
- Coach-oriented workout feedback UI

> **Current-state note:** Some coaching, biomechanics, and recovery experiences currently use mock/static data and UI flows. They are structured to be connected to real services as the product evolves.

### Account & Profile
- JWT authentication
- Persistent application authentication state
- User profile and onboarding data
- Locale and country fields
- Training goals, experience level, availability, and profile information

### Social / Gym Bro
- Tinder-style workout-partner discovery: swipe left (pass) or right (like) through nearby candidate profiles
- Matching: a mutual like creates a match, surfaced in a dedicated "Gym Bro" bottom-nav tab
- A per-match chat thread (messages icon on the discovery screen) for matched training partners
- A short training-focused profile (bio, training goals, experience level, availability, location) that's separate from the main account profile, editable from its own settings screen
- Built on top of the existing `Profile` model plus three dedicated models (`Swipe`, `Match`, `GymBroMessage`) — see the "Gym Bro" section further down for the full picture

### Subscription Foundation
The backend contains a subscription model and billing abstraction that can be extended with a payment provider such as Stripe. Payment processing/webhooks are **not yet a complete production billing integration**.

---

# 🧭 Getting to Know WELLAURA (a guided tour)

This section is the mental model an engineer (or an AI assistant) needs before
touching this codebase — the shape of each piece, not just its file path,
built up by actually reading the code rather than guessing from folder names.

WELLAURA ("welora" in the UI) is a single Flutter codebase talking to one
Django REST API — no separate microservices. It's a solo training coach
(plan generation, a library-backed exercise browser, workout logging,
progress tracking) plus a social layer (Gym Bro matching) and a lightweight
mindfulness layer (breathwork, recovery), all sharing one `Profile` model.

The bottom-nav shell (`frontend/lib/features/home/presentation/home_page.dart`)
carries five tabs, each a `ShellRoute` child so the nav bar persists across
navigation:

- **Home** (`/`) — the daily dashboard: weekly-rhythm cards, a category grid
  that deep-links into the exercise library, an editable weekly schedule, and
  the AI-generated plan's *today* session with a "Start workout" CTA.
- **Workouts** (`/explorer`) — the exercise library: search, muscle-group
  filters, favorites, and entry points to My Plans, Form Vault, and the AI
  Coach.
- **Gym Bro** (`/gym-bro`) — the Tinder-style training-partner discovery feed
  (see the dedicated section below).
- **Progress** (`/progress`) — history and analytics: streaks, lift volume,
  personal records, body-weight trend, rhythm/muscle-load charts, and the raw
  session/set history.
- **Profile** (`/you`) — account settings, onboarding data, and the
  subscription state.

Two things trip people up the first time:

1. **There are two unrelated "Plan" concepts.** The real backend `Plan` /
   `PlanDay` / `PlanDayExercise` models are full CRUD, multiple named plans
   per user, with a weekly schedule (`frontend/lib/features/plans/`, reachable
   from the calendar icon on the Workouts tab). Separately, the Home tab's
   dashboard runs on an AI-coach `WorkoutPlan` JSON contract
   (`frontend/lib/features/plan/domain/plan_contract.dart`) that's bridged
   from the user's first real `Plan` by `PlanNotifier.refreshFromApi()`. They
   look similar but are not interchangeable.
2. **`Exercise` plays two roles with one table.** `is_library=True` /
   `user=None` rows are the shared, admin-authored catalog (rich metadata:
   muscles, equipment, instructions, alternatives/progressions/regressions).
   The same model, with `is_library=False` and a `user`/`plan` set, doubles as
   a per-plan-day assignment row.

Everything a workout produces flows through `WorkoutSession` (start/finish
timestamps, optional `Plan` link) grouping `ProgressMetric` rows (one row per
logged set — reps, weight, duration, which exercise); the Progress tab reads
that same data back out. The AI Coach ("Kaori") is a chat-style assistant
that is currently UI/mock-data driven, not backed by a real inference
pipeline yet — same for the biomechanics/3D-replay screens.

Once that picture is in place, the fastest way to extend the backend safely
is with fully-populated, realistic test accounts rather than hand-crafting
data through the API or the admin one field at a time — see the "Test
Environment Initialization" section further down.

---

# 🏗️ Architecture

WELLAURA is split into a Flutter frontend and a Django REST backend backed by PostgreSQL.

```text
                         ┌──────────────────────────┐
                         │      WELLAURA App        │
                         │     Flutter / Dart       │
                         │                          │
                         │  Auth · Plans · Workout  │
                         │  Exercises · Progress    │
                         │  Coach · Recovery       │
                         └────────────┬─────────────┘
                                      │ HTTP / JSON
                                      │ JWT
                                      ▼
                         ┌──────────────────────────┐
                         │       Django API         │
                         │ Django 5 + DRF           │
                         │ SimpleJWT                │
                         │                          │
                         │ Profiles · Plans         │
                         │ Exercises · Sessions     │
                         │ Metrics · Billing        │
                         └────────────┬─────────────┘
                                      │
                                      │ PostgreSQL
                                      ▼
                         ┌──────────────────────────┐
                         │       PostgreSQL 16       │
                         │      persistent data      │
                         └──────────────────────────┘
```

### Frontend

- Flutter 3.24.x
- Dart 3.5+
- Riverpod
- GoRouter
- Drift / SQLite for local persistence
- HTTP client for API communication
- Shared Preferences for local state/queues
- Wakelock support for workout sessions

### Backend

- Python 3.13
- Django 5.1
- Django REST Framework
- SimpleJWT
- drf-spectacular
- PostgreSQL 16
- Gunicorn
- Pillow
## Fill data in the DB , by training exercices 
`scripts/seed-dev-data.sh`
### Infrastructure

- Docker
- Docker Compose
- Nginx for the production Flutter web build
- GitHub Actions
- Android release automation

---

# 📁 Project Structure

```text
.
├── backend/
│   ├── gym_api/
│   │   ├── migrations/
│   │   ├── management/
│   │   ├── fixtures/
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   └── billing.py
│   ├── gym_project/
│   │   ├── settings.py
│   │   ├── urls.py
│   │   ├── asgi.py
│   │   └── wsgi.py
│   ├── Dockerfile
│   ├── requirements.txt
│   └── manage.py
│
├── frontend/
│   ├── lib/
│   │   ├── core/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── biomechanics/
│   │   │   ├── coach/
│   │   │   ├── exercise_library/
│   │   │   ├── gym_bro/
│   │   │   ├── home/
│   │   │   ├── onboarding/
│   │   │   ├── plan/
│   │   │   ├── plan_runner/
│   │   │   ├── progress/
│   │   │   └── recovery/
│   │   ├── services/
│   │   └── main.dart
│   ├── assets/
│   ├── android/
│   ├── ios/
│   ├── web/
│   ├── pubspec.yaml
│   └── Dockerfile
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── android-release.yml
│
├── .claude/
│   └── skills/
│
├── asserts/
├── docker-compose.backend.dev.yml
├── docker-compose.backend.prod.yml
├── docker-compose.frontend.dev.yml
├── docker-compose.frontend.prod.yml
├── docker.dev.sh
├── docker.prod.sh
├── RUN.md
└── README.md
```

---

# 🚀 Quick Start

## Prerequisites

For the Docker workflow, install:

- Docker Engine
- Docker Compose v2
- Git

Verify:

```bash
docker --version
docker compose version
git --version
```

You do **not** need Python, PostgreSQL, or Flutter installed on the host to use the Docker development stack.

---

# 🐳 Development with Docker

The recommended development entry point is:

```bash
./docker.dev.sh up
```

If the script is not executable:

```bash
chmod +x docker.dev.sh docker.prod.sh
```

The development script:

1. Validates the Docker Compose configuration
2. Builds the backend and frontend images
3. Starts PostgreSQL
4. Waits for PostgreSQL health
5. Starts Django
6. Waits for the backend health endpoint
7. Starts the frontend

### Build only

```bash
./docker.dev.sh build
```

### Development services

| Service | URL |
|---|---|
| WELLAURA web app | http://127.0.0.1:8080 |
| Django API | http://127.0.0.1:8000 |
| Django admin | http://127.0.0.1:8000/admin/ |
| PostgreSQL | 127.0.0.1:5432 |

The exact host ports can be changed through the environment configuration.

---

# 🖥️ Run the Services Manually

If you prefer to control each Compose stack yourself:

### Backend + PostgreSQL

```bash
docker compose --env-file .env.dev \
  -f docker-compose.backend.dev.yml \
  up --build
```

### Frontend

In another terminal:

```bash
docker compose --env-file .env.dev \
  -f docker-compose.frontend.dev.yml \
  up --build
```

---

# ⚙️ Environment Configuration

Environment templates are provided for development and production:

```text
.env.dev
.env.prod
```

The frontend uses:

```text
API_BASE_URL
```

to determine which backend API it should communicate with.

Typical backend variables include:

```text
DJANGO_DEBUG
DJANGO_SECRET_KEY
DJANGO_ALLOWED_HOSTS

POSTGRES_DB
POSTGRES_USER
POSTGRES_PASSWORD
POSTGRES_PORT

API_BASE_URL
```

## Security

**Never commit real production credentials or API secrets to Git.**

Use environment variables or your deployment platform's secret manager for production secrets.

If an environment file already exists locally, verify that it contains no credentials before publishing the repository.

---

# 🗄️ Database & Django

The development and production Compose stacks automatically run Django migrations when the backend starts.

To run migrations manually:

```bash
docker compose \
  --env-file .env.dev \
  -f docker-compose.backend.dev.yml \
  exec backend python manage.py migrate
```

Create migrations after model changes:

```bash
docker compose \
  --env-file .env.dev \
  -f docker-compose.backend.dev.yml \
  exec backend python manage.py makemigrations
```

Create a Django admin user:

```bash
docker compose \
  --env-file .env.dev \
  -f docker-compose.backend.dev.yml \
  exec backend python manage.py createsuperuser
```

Open:

```text
http://127.0.0.1:8000/admin/
```

---

# 🧪 Test Environment Initialization

Once the dev stack is up (`./docker.dev.sh up` prints a reminder of this at
the end), populate it with fully-featured test accounts — users, profiles,
avatars, exercises, workout plans, plan assignments, and workout
history/sets/reps/weights — with a single command:

```bash
./scripts/init_test_environment.sh
```

All of that data comes from one JSON file, `asserts/inputs_dev_env/json_file.json`
— it is the single source of truth for the dev/test environment, not the
script or the Django command that reads it:

```text
asserts/inputs_dev_env/json_file.json
                ↓
scripts/init_test_environment.sh
                ↓
backend/gym_api/management/commands/init_test_environment.py
                ↓
database
```

To add or change a test user, exercise, plan, or workout history entry, edit
that JSON file and re-run the script — the command is idempotent (safe to
re-run; it updates/reuses existing rows by stable id rather than duplicating
them) and validates the entire file up front, refusing to write anything to
the database if it finds a problem (missing fields, bad references, invalid
dates, duplicate ids, etc.).

Validate without writing to the database:

```bash
./scripts/init_test_environment.sh --check-only
```

Full schema documentation, including how to add each kind of record, lives
in [`asserts/inputs_dev_env/README.md`](asserts/inputs_dev_env/README.md).

---

# 🔐 Authentication

The API uses JWT authentication through `djangorestframework-simplejwt`.

### Obtain access token

```http
POST /api/auth/token/
```

### Refresh access token

```http
POST /api/auth/token/refresh/
```

Authenticated requests use:

```http
Authorization: Bearer <access_token>
```

The Flutter client handles API authentication and maintains local authentication state.

---

# 🔌 API Overview

The backend exposes REST endpoints for the main application domains.

| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/api/auth/token/` | Obtain JWT |
| POST | `/api/auth/token/refresh/` | Refresh JWT |
| GET / PATCH | `/api/profiles/me/` | Current user profile |
| PATCH | `/api/profiles/<id>/` | Update profile |
| GET / POST | `/api/plans/` | Training plans |
| GET / POST | `/api/exercises/` | Exercises |
| GET / POST | `/api/sessions/` | Workout sessions |
| PATCH | `/api/sessions/<id>/` | Update workout session |
| POST | `/api/sessions/<id>/log-metric/` | Log workout metric |
| GET / POST | `/api/metrics/` | Progress metrics |
| GET | `/api/metrics/last-for-exercise/` | Latest exercise metric |
| GET | `/api/library/exercises/` | Global exercise library |
| GET | `/api/favorites/` | Favorite exercises |
| GET / POST | `/api/billing/subscription/` | Subscription state |

Authenticated endpoints require a valid JWT unless explicitly stated otherwise.

---

# 📱 Flutter Application

The Flutter application is organized by feature rather than by screen type.

Important areas include:

```text
features/auth
features/onboarding
features/home
features/plan
features/plan_runner
features/exercise_library
features/progress
features/coach
features/recovery
features/biomechanics
features/gym_bro
```

This structure keeps product functionality isolated and makes it easier to evolve individual domains independently.

---

# 🏋️ Gym Bro

Gym Bro is WELLAURA's social layer: a Tinder-style way to find a training
partner, layered on top of the same `Profile` model the rest of the app
uses (no separate account system).

**Data model** (`backend/gym_api/models.py`):

- `Profile` carries the Gym Bro–specific fields: `bio`, `training_goals`
  (a JSON list, e.g. `["strength", "cardio"]`), `experience_level`
  (`beginner` / `intermediate` / `advanced`), `availability` (free text),
  and `location` (city/area text only — precise geolocation is intentionally
  never collected or stored).
- `Swipe` — a like/pass recorded by one user against another's profile.
- `Match` — created automatically once two users have both liked each
  other; stored as an ordered pair so a mutual like can never create two
  rows for the same pair. It also doubles as the chat thread.
- `GymBroMessage` — a persisted chat message tied to a `Match`.

**API** (`backend/gym_api/views.py`, `urls.py`):

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/api/profiles/discover/` | Candidate profiles to swipe on (excludes already-swiped users) |
| POST | `/api/swipes/` | Record a like/pass; auto-creates a `Match` on mutual like |
| GET | `/api/gym-bro/matches/` | List the current user's matches |
| GET / POST | `/api/gym-bro/matches/<id>/messages/` | Read/send messages in a match's chat thread |

**Frontend** (`frontend/lib/features/gym_bro/`):

- `gym_bro_settings_page.dart` — edit your own Gym Bro profile (bio, goal
  chips, experience, availability).
- `gym_bro_discover_page.dart` — the swipe deck (also embedded as the
  `Gym Bro` bottom-nav tab; see `isTab` on `GymBroDiscoverPage`).
- `gym_bro_matches_page.dart` — your matches list ("Your matches"; empty
  state until you get a mutual like).
- `gym_bro_chat_page.dart` — the per-match chat screen.

The bottom-nav tab's app bar carries a messages icon on the left (opens your
matches/chat) and a settings icon on the right (opens your Gym Bro profile
editor), so discovery, messaging, and profile editing are all one tap away
from the tab itself.

---

# 💾 Offline & Local Persistence

The frontend includes local persistence using:

- Drift
- SQLite
- Shared Preferences

Workout information can be queued locally when network communication fails and synchronized when connectivity is restored.

This architecture is intended to make workout logging more resilient to temporary network problems.

---

# 🧪 Testing

### Backend

Run Django tests inside the backend container:

```bash
docker compose \
  --env-file .env.dev \
  -f docker-compose.backend.dev.yml \
  exec backend python manage.py test gym_api
```

### Flutter

From the `frontend` directory:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

The CI workflow runs Flutter dependency installation, Drift code generation, static analysis, and Flutter tests.

---

# 🔄 CI/CD

GitHub Actions currently provides:

### Pull Request CI

`.github/workflows/ci.yml`

Runs:

- Flutter dependency installation
- Drift code generation
- Flutter analysis
- Flutter tests

### Android Release

`.github/workflows/android-release.yml`

On pushes to `main`, the workflow can:

1. Install Java 17
2. Install the configured Flutter version
3. Generate Drift code
4. Analyze the Flutter project
5. Run tests
6. Configure Android release signing from GitHub Secrets
7. Build the APK
8. Build the Android App Bundle
9. Create a semantic release tag
10. Create/update a GitHub Release
11. Upload the Android artifacts

### Required Android Secrets

For signed Android releases, configure the appropriate GitHub Actions secrets:

```text
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

If signing credentials are not supplied, the workflow's signing step does not create the release keystore.

---

# 🏭 Production Docker Stack

The production stack uses separate Compose files for the backend and frontend.

Start it with:

```bash
./docker.prod.sh up
```

Build only:

```bash
./docker.prod.sh build
```

The production backend uses Gunicorn, while the Flutter web application is built into an Nginx image.

> Before deploying publicly, configure real production secrets, HTTPS/reverse proxy infrastructure, allowed hosts, database security, backups, monitoring, and a production-grade PostgreSQL setup.

---

# 🧹 Useful Docker Commands

### View services

```bash
docker compose ps
```

### Backend logs

```bash
docker compose \
  --env-file .env.dev \
  -f docker-compose.backend.dev.yml \
  logs -f backend
```

### Database logs

```bash
docker compose \
  --env-file .env.dev \
  -f docker-compose.backend.dev.yml \
  logs -f db
```

### Open a backend shell

```bash
docker compose \
  --env-file .env.dev \
  -f docker-compose.backend.dev.yml \
  exec backend sh
```

### Stop development services

```bash
docker compose \
  --env-file .env.dev \
  -f docker-compose.backend.dev.yml \
  -f docker-compose.frontend.dev.yml \
  down
```

### Stop and delete the database volume

```bash
docker compose \
  --env-file .env.dev \
  -f docker-compose.backend.dev.yml \
  -f docker-compose.frontend.dev.yml \
  down -v
```

> `down -v` deletes the local PostgreSQL volume and therefore destroys the local database data.

---

# 🩺 Troubleshooting

## Port already in use

If port `8000`, `8080`, or `5432` is occupied:

```bash
ss -ltnp | grep -E ':8000|:8080|:5432'
```

Then stop the conflicting process/container or change the corresponding host port.

## Backend does not become ready

Check:

```bash
docker compose \
  --env-file .env.dev \
  -f docker-compose.backend.dev.yml \
  logs --tail=200 backend
```

Then check PostgreSQL:

```bash
docker compose \
  --env-file .env.dev \
  -f docker-compose.backend.dev.yml \
  logs --tail=200 db
```

The development startup script uses:

```text
/api/health/
```

as its backend readiness endpoint.

## Frontend cannot reach the API

Check `API_BASE_URL`.

For a browser running on the same machine, a typical development value is:

```text
http://127.0.0.1:8000/api/
```

If the application is accessed from another device on your local network, `localhost` points to that device itself. Use the development machine's LAN IP instead and make sure Django's allowed hosts/CORS configuration permits the connection.

## Flutter generated files

If Drift-generated files become inconsistent:

```bash
cd frontend
dart run build_runner build --delete-conflicting-outputs
```

---

# 🛣️ Product Direction

WELLAURA is being developed toward a broader wellness platform where training is only one part of the experience.

Potential product evolution includes:

- AI-powered personalized training
- Adaptive workout programming
- Intelligent progress analysis
- Deeper biomechanics and form analysis
- Recovery recommendations
- Meditation and breathwork programs
- Lifestyle and habit recommendations
- Music/workout integrations
- Smarter reminders and scheduling
- Premium subscription features
- Deeper social/community experiences beyond the current Gym Bro matching (e.g. group challenges, activity feeds)

Some of these concepts are represented in the current UI, while others remain roadmap items. Gym Bro matching itself is already implemented — see the dedicated section above.

---

# 🤝 Development Philosophy

The project is intended to evolve as a modular product rather than a collection of isolated screens.

Key principles:

- **Feature-oriented architecture**
- **API-first backend**
- **Offline-aware workout experience**
- **Reusable domain models**
- **Automated validation through CI**
- **Containerized development**
- **Production-minded configuration**
- **Privacy-conscious user data handling**

---

# 📄 License

No open-source license has been declared yet.

If this repository will be publicly distributed, add a `LICENSE` file and update this section with the selected license.

---

## WELLAURA

**Train well. Live well.**
