# Gym Planner — Ready to Go / Ready to Monetize

Status: production-scaffold with CI (GitHub Actions), mobile builds (Android APK + iOS archive), auth + billing stub.

## Earn money with this
- Subscriptions: `frontend/lib/services/api_client.dart` → `/billing/subscription`; backend stub at `backend/gym_api/billing.py`
- Lock features behind `checkSubscription()`; upgrade with `upgradeSubscription('premium')`
- Add Stripe webhook endpoint to `backend/`; put fee logic in `SubscriptionViewSet`

---

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Project Structure](#project-structure)
5. [Running the Backend with Docker](#running-the-backend-with-docker)
6. [Running the Frontend with Docker](#running-the-frontend-with-docker)
7. [Running the Full Stack (Backend + Frontend)](#running-the-full-stack-backend--frontend)
8. [Environment Variables](#environment-variables)
9. [Database & Migrations](#database--migrations)
10. [API Endpoints](#api-endpoints)
11. [Useful Docker Commands](#useful-docker-commands)
12. [Troubleshooting](#troubleshooting)
13. [Deploy](#deploy)
14. [Verification (this session)](#verification-this-session)

---

## Overview

Gym Planner is a full-stack fitness application composed of:
- **Backend** — Django 5 + Django REST Framework + PostgreSQL 16, served via Gunicorn on port `8000`
- **Frontend** — Flutter 3.24 web build, served via Nginx on port `8080` (container port `80`)
- **Database** — PostgreSQL 16 (Alpine) running in a Docker container, persistent volume `pg_data`

Everything is containerized and orchestrated through Docker Compose. No host-level Python or Flutter installation is required to run the app.

---

## Architecture

```
┌────────────────────────┐      HTTP      ┌────────────────────────┐
│  Frontend (Flutter Web)│ ─────────────► │  Backend (Django/DRF)  │
│  Nginx :8080 → :80     │   /api/*       │  Gunicorn :8000        │
└────────────────────────┘                └──────────┬─────────────┘
                                                     │ SQL
                                                     ▼
                                          ┌────────────────────────┐
                                          │  PostgreSQL 16         │
                                          │  :5432 (volume: pg_data)│
                                          └────────────────────────┘
```

The frontend and backend communicate over HTTP. The Flutter app's `api_client.dart` targets the backend at `http://localhost:8000/api/` by default.

---

## Prerequisites

You only need:
- **Docker Engine** ≥ 20.10
- **Docker Compose** v2 (the modern `docker compose` CLI — `docker compose` works; the older `docker-compose` v1 syntax in the files is also accepted by Docker)

Verify your setup:
```bash
docker --version
docker compose version
```

No Python, Flutter, Node, or PostgreSQL installations are required on the host.

---

## Project Structure

```
.
├── backend/                       # Django + DRF service
│   ├── Dockerfile                 # python:3.13-slim, gunicorn
│   ├── docker-compose.local.yml   # standalone backend stack
│   ├── requirements.txt
│   ├── manage.py
│   ├── gym_api/                   # app: models, views, serializers, fixtures
│   └── gym_project/               # settings, urls, wsgi
├── frontend/                      # Flutter web app
│   ├── Dockerfile                 # multi-stage: flutter build → nginx
│   ├── pubspec.yaml
│   ├── lib/                       # Dart source
│   └── web/                       # web entrypoint
├── docker-compose.yml             # backend stack (db + backend)
├── docker-compose.frontend.yml    # frontend-only stack
├── .github/workflows/             # CI (flutter analyze, test, build)
└── README.md
```

Two compose files exist on purpose:
- `docker-compose.yml` → `db` + `backend` (production-shape stack with healthchecks)
- `docker-compose.frontend.yml` → `frontend` only (run after the backend is up)

---

## Running the Backend with Docker

The backend stack spins up **PostgreSQL** and the **Django/Gunicorn** service.

### 1. From the project root, start the stack

```bash
cd /home/amen/Desktop/tester_github_starter12395847
docker compose up --build
```

What happens:
1. `db` (Postgres 16 Alpine) starts; the healthcheck (`pg_isready -U aigym -d aigym`) waits until it accepts connections.
2. `backend` waits for `db` to be healthy, then:
   - runs `python manage.py migrate`
   - loads seed data from `gym_api/fixtures/seed.json` (failure is tolerated)
   - starts Gunicorn on `0.0.0.0:8000`

### 2. Verify

- API root: <http://localhost:8000/api/>
- Django admin: <http://localhost:8000/admin/>
- Postgres: `localhost:5432` (user `aigym`, password `aigym`, db `aigym`)

### 3. Create a superuser (optional)

Open a second terminal:
```bash
docker compose exec backend python manage.py createsuperuser
```

### 4. Run backend tests

```bash
docker compose exec backend python manage.py test gym_api
```

### 5. Stop the stack

```bash
docker compose down            # stop containers, keep pg_data volume
docker compose down -v         # stop containers AND delete the pg_data volume
```

---

## Running the Frontend with Docker

The frontend uses a **multi-stage build**:
- **Builder stage** (`ubuntu:24.04`) — installs Flutter 3.24, runs `flutter pub get`, then `flutter build web --release`
- **Runtime stage** (`nginx:alpine`) — copies the built `/build/web` to Nginx's html root and serves on port `80`

### 1. Start the frontend

The frontend compose file is a **standalone service** — it does NOT include the backend or database. Make sure the backend is already running (see above), then:

```bash
cd /home/amen/Desktop/tester_github_starter12395847
docker compose -f docker-compose.frontend.yml up --build
```

What happens:
1. The builder image compiles the Flutter app for web in release mode (this takes several minutes the first time).
2. The Nginx image starts and serves the compiled assets.
3. The app is available at <http://localhost:8080>.

### 2. Verify

Open <http://localhost:8080> in your browser. The Flutter web app should load.

### 3. Stop the frontend

```bash
docker compose -f docker-compose.frontend.yml down
```

### 4. Rebuild from scratch (no cache)

If you change `pubspec.yaml` or need a clean build:
```bash
docker compose -f docker-compose.frontend.yml build --no-cache
docker compose -f docker-compose.frontend.yml up
```

---

## Running the Full Stack (Backend + Frontend)

You need **two terminals** because the two compose files are separate. This is intentional — the frontend compose only contains the frontend service, so the backend stack owns Postgres + Django and the frontend stack owns Nginx + Flutter.

### Terminal 1 — Backend (DB + API)
```bash
cd /home/amen/Desktop/tester_github_starter12395847
docker compose up --build
```
Wait until you see Gunicorn boot and the migrate step complete.

### Terminal 2 — Frontend
```bash
cd /home/amen/Desktop/tester_github_starter12395847
docker compose -f docker-compose.frontend.yml up --build
```

### Access
- **App (web UI)**: <http://localhost:8080>
- **API**: <http://localhost:8000/api/>
- **Admin**: <http://localhost:8000/admin/>
- **Postgres**: `localhost:5432`

### Tear down everything
```bash
docker compose down -v                                  # backend + db volume
docker compose -f docker-compose.frontend.yml down       # frontend
```

---

## Environment Variables

### Backend
Defined inline in `docker-compose.yml`. Override at runtime with shell env or an `.env` file at the project root.

| Variable | Default | Purpose |
|----------|---------|---------|
| `DJANGO_SECRET_KEY` | `change-me-in-prod` | **Set this in production** |
| `DJANGO_DEBUG` | `1` | Set to `0` in production |
| `DB_ENGINE` | `postgres` | Set to `sqlite` to bypass Postgres (local-only) |
| `POSTGRES_DB` | `aigym` | Database name |
| `POSTGRES_USER` | `aigym` | DB user |
| `POSTGRES_PASSWORD` | `aigym` | DB password |
| `POSTGRES_HOST` | `db` | Service name in compose network |
| `POSTGRES_PORT` | `5432` | DB port |

Override example:
```bash
DJANGO_SECRET_KEY=$(openssl rand -hex 32) DJANGO_DEBUG=0 docker compose up --build
```

---

## Database & Migrations

Migrations run automatically on `docker compose up` via the `command` block in the backend service. To run migrations manually:

```bash
docker compose exec backend python manage.py migrate
```

To create new migrations after model changes:
```bash
docker compose exec backend python manage.py makemigrations
```

Seed data is loaded from `backend/gym_api/fixtures/seed.json` automatically (errors are ignored so the stack still boots if the fixture is missing).

---

## API Endpoints

Base URL: `http://localhost:8000/api/`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/auth/token/` | none | Obtain JWT (`username` + `password`) |
| POST | `/auth/token/refresh/` | none | Refresh JWT |
| GET / POST | `/profiles/me/` | Bearer | Current user profile |
| GET / POST | `/plans/` | Bearer | List / create training plans |
| GET / POST | `/exercises/` | Bearer | List / create exercises |
| GET / POST | `/sessions/` | Bearer | List / create workout sessions |
| GET / POST | `/metrics/` | Bearer | List / create progress metrics |

All endpoints except `/auth/token/*` require `Authorization: Bearer <access_token>`.

---

## Useful Docker Commands

```bash
# Logs (follow)
docker compose logs -f backend
docker compose logs -f db

# Shell into backend
docker compose exec backend sh

# Django management
docker compose exec backend python manage.py createsuperuser
docker compose exec backend python manage.py shell
docker compose exec backend python manage.py test gym_api

# Postgres shell
docker compose exec db psql -U aigym -d aigym

# Frontend logs
docker compose -f docker-compose.frontend.yml logs -f frontend

# List running containers
docker compose ps

# Full reset (delete data)
docker compose down -v
```

---

## Troubleshooting

**Port 8000 or 8080 already in use**
Stop the conflicting process or change the host port mapping in the compose file (e.g. `"9000:8000"`).

**`db` is unhealthy / backend exits immediately**
Check Postgres logs: `docker compose logs db`. Most often a stale volume — run `docker compose down -v` to clear it.

**Frontend build fails on first run**
The Flutter SDK is cloned inside the image, so the first build downloads ~700 MB and takes 5–10 minutes. Watch the builder stage: `docker compose -f docker-compose.frontend.yml logs -f frontend`.

**API calls from the browser fail with CORS / network errors**
Make sure the backend is running on `:8000` and the Flutter `api_client.dart` base URL points to `http://localhost:8000/api/`. If you change ports, update both sides.

**Changes to `pubspec.yaml` not picked up**
Rebuild without cache:
```bash
docker compose -f docker-compose.frontend.yml build --no-cache
```

**Permission errors on Linux with bind-mounted volumes**
The `docker-compose.yml` bind-mounts `./backend:/app`. If you hit permission issues, remove that line and rebuild — the image is self-contained.

---

## Deploy
- Docker: `docker compose up --build` (port 80 / 8080 mapped)
- Mobile releases: CI publishes prerelease on every `push` to `main` + tag `v*`
- Signing: see `frontend/signing-reference.md` + `key.properties.example`

---

## Verification (this session)
- CI rebuilt from `amenallah-salem/gym_app_starter_2548596354` reference (flutter-actions/setup-flutter@v4, upload-artifact@v4, prerelease)
- Push confirmed (`f6f921a` → `main`, 0 unpushed)
- Ad-hoc scripts run and cleaned (`hermes-*` temp, exit 0)
- Honest limits: no SDK/macOS/keystore in this env; no actual `flutter build` executed; release artifacts unsigned; billing is stub only

Branch: `main` (merged T-09 + T-17 + CI + improvements).
