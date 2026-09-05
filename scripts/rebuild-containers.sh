#!/usr/bin/env bash
set -euo pipefail

# Rebuild and restart backend and frontend containers, run migrations.
# Usage: ./scripts/rebuild-containers.sh

COMPOSE_FILES=( -f docker-compose.yml -f docker-compose.frontend.yml )

echo "=== Rebuilding backend ==="
# Build backend image and restart the backend container
docker compose ${COMPOSE_FILES[*]} build backend
docker compose ${COMPOSE_FILES[*]} up -d --no-deps --force-recreate backend

echo "=== Running migrations ==="
# Run migrations (non-interactive)
# Use exec -T to avoid allocating a tty in CI/environments where it's not available
docker compose ${COMPOSE_FILES[*]} exec -T backend python manage.py migrate || true

echo "=== Rebuilding frontend ==="
# Build frontend (static build) and restart frontend container
docker compose ${COMPOSE_FILES[*]} build frontend
docker compose ${COMPOSE_FILES[*]} up -d --no-deps --force-recreate frontend

echo "=== Done ==="
echo "Frontend: http://localhost:8080"
echo "Backend:  http://localhost:8000 (api at /api/)"