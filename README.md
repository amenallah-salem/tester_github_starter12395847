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

### Subscription Foundation
The backend contains a subscription model and billing abstraction that can be extended with a payment provider such as Stripe. Payment processing/webhooks are **not yet a complete production billing integration**.

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
- Social/community experiences

Some of these concepts are represented in the current UI, while others remain roadmap items.

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
