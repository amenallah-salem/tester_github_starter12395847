# Gym Planner API

Django REST Framework backend for the Gym Planner application.

## Stack
- Python 3.13
- Django 5.x
- Django REST Framework
- PostgreSQL 16
- JWT auth (rest_framework_simplejwt)

## Models
- `Profile` – extends `auth.User`
- `Plan` – training plan
- `Exercise` – exercise definition
- `WorkoutSession` – a concrete workout
- `ProgressMetric` – per-set progress log

## Quick start (Docker)

```bash
cd backend
cp .env.example .env
docker-compose -f docker-compose.local.yml up --build
```

The API will be available at `http://localhost:8000/api/`.
Django admin: `http://localhost:8000/admin/`.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/token/` | Obtain JWT (username/password) |
| POST | `/api/auth/token/refresh/` | Refresh JWT |
| GET/POST | `/api/profiles/me/` | Current user profile |
| GET/POST | `/api/plans/` | List / create plans |
| GET/POST | `/api/exercises/` | List / create exercises |
| GET/POST | `/api/sessions/` | List / create workout sessions |
| GET/POST | `/api/metrics/` | List / create progress metrics |

All endpoints except `/api/auth/token/*` require a Bearer token.

## Local dev (no Docker)

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
# configure env vars (DB_HOST=localhost, ...)
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

## Tests

```bash
python manage.py test gym_api
```
