#!/usr/bin/env bash
set -euo pipefail

# Build-only dev script: builds backend and frontend development images
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
"
echo "Building development images: backend + frontend"

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or not on PATH" >&2
  exit 2
fi

BACKEND_FILE="$ROOT_DIR/docker-compose.backend.dev.yml"
FRONTEND_FILE="$ROOT_DIR/docker-compose.frontend.dev.yml"

if [ ! -f "$BACKEND_FILE" ]; then
  echo "Error: backend compose file not found: $BACKEND_FILE" >&2
  exit 3
fi
if [ ! -f "$FRONTEND_FILE" ]; then
  echo "Error: frontend compose file not found: $FRONTEND_FILE" >&2
  exit 4
fi

echo "Using files:"
echo "  $BACKEND_FILE"
echo "  $FRONTEND_FILE"

docker compose -f "$BACKEND_FILE" -f "$FRONTEND_FILE" build --parallel --pull

echo "Dev images built successfully."

# Start DB and backend and wait for readiness before starting frontend
echo "Bringing up db and backend..."
docker compose -f "$BACKEND_FILE" -f "$FRONTEND_FILE" up -d db backend

# get container id for the db service in this compose project
DB_CID=$(docker compose -f "$BACKEND_FILE" -f "$FRONTEND_FILE" ps -q db)
if [ -z "$DB_CID" ]; then
  echo "Warning: could not determine db container id, skipping health wait" >&2
else
  echo "Waiting for Postgres to be healthy (container: $DB_CID)"
  # Wait for the health status to become healthy (timeout after 120s)
  SECONDS_WAITED=0
  TIMEOUT=120
  INTERVAL=2
  while true; do
    status=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$DB_CID") || status=none
    if [ "$status" = "healthy" ]; then
      echo "Postgres is healthy"
      break
    fi
    if [ "$SECONDS_WAITED" -ge "$TIMEOUT" ]; then
      echo "Timed out waiting for Postgres health (status=$status). Continuing..." >&2
      break
    fi
    sleep $INTERVAL
    SECONDS_WAITED=$((SECONDS_WAITED + INTERVAL))
  done
fi

# Wait for backend to accept connections on localhost:8000 (timeout 60s)
echo "Waiting for backend HTTP on http://localhost:8000/"
BACKEND_TIMEOUT=60
BACKEND_WAITED=0
BACKEND_INTERVAL=2
while true; do
  if curl -sfI http://localhost:8000/ >/dev/null 2>&1; then
    echo "Backend is responding on http://localhost:8000/"
    break
  fi
  if [ "$BACKEND_WAITED" -ge "$BACKEND_TIMEOUT" ]; then
    echo "Timed out waiting for backend HTTP. Continuing to start frontend..." >&2
    break
  fi
  sleep $BACKEND_INTERVAL
  BACKEND_WAITED=$((BACKEND_WAITED + BACKEND_INTERVAL))
done

# Start frontend after backend is ready
echo "Starting frontend..."
docker compose -f "$BACKEND_FILE" -f "$FRONTEND_FILE" up -d frontend

echo "Dev stack is up (db, backend, frontend)."