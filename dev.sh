#!/bin/bash
# Dev launcher: backend (runserver reload) + frontend (hot reload or build)
set -euo pipefail

echo "=== Dev Mode: Backend (runserver auto-reload) + Frontend ==="
echo "Backend: edit files in ./backend -> reloads automatically"
echo "Frontend: edit files in ./frontend -> rebuild required (dev server available)"

echo "Starting backend..."
docker compose -f docker-compose.frontend.yml up -d backend || docker compose up -d backend

echo "Building & starting frontend (production static)..."
docker compose -f docker-compose.frontend.yml up --build -d frontend || docker compose up --build -d frontend

echo "=== Services ==="
echo "Frontend (website): http://localhost:8080"
echo "Backend (API):     http://localhost:8000 (internal proxy via nginx at /api/)"
echo "Backend direct test (no rebuild): docker compose exec backend python manage.py migrate"
echo "Dev mode on: edit backend files, save -> Django reloads instantly."
echo "For faster frontend edits, use: docker compose -f docker-compose.frontend.dev.yml up --build -d"
