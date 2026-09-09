#!/usr/bin/env bash
set -euo pipefail

# docker.dev.sh — helper to build and start dev stack (db + backend + frontend)
#
# Usage:
#   ./docker.dev.sh build              # build images only
#   ./docker.dev.sh up [--no-strict]   # build + bring up services; strict by default
#
# Environment variables:
#   BACKEND_TIMEOUT  seconds to wait for the backend to become ready (default 120)
#   BACKEND_HOST     host to probe the backend on (default 127.0.0.1)
#   BACKEND_PORT     port to probe the backend on (default 8000)
#   BACKEND_PATH     HTTP path used as the readiness probe (default /api/health/)
#   DB_TIMEOUT       seconds to wait for Postgres to become healthy (default 120)
#   BACKEND_MAX_RESTARTS  restarts allowed before failing fast (default 3)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CMD="${1:-up}"
BACKEND_TIMEOUT="${BACKEND_TIMEOUT:-120}"
BACKEND_HOST="${BACKEND_HOST:-127.0.0.1}"
BACKEND_PORT="${BACKEND_PORT:-8000}"
# NOTE: "/api/" is the DRF router root, which requires authentication
# (DEFAULT_PERMISSION_CLASSES = IsAuthenticated) and returns 401 even when
# Django and the database are perfectly healthy. Use the dedicated,
# unauthenticated readiness endpoint instead.
BACKEND_PATH="${BACKEND_PATH:-/api/health/}"
DB_TIMEOUT="${DB_TIMEOUT:-120}"
# Fail fast if the backend keeps crash-looping instead of waiting out the
# full timeout: a container stuck restarting can leave Docker's network
# endpoint for that container in a half-attached state, which surfaces as
# "could not translate host name db to address" even though db is healthy.
BACKEND_MAX_RESTARTS="${BACKEND_MAX_RESTARTS:-3}"

STRICT=1
if [ "${2:-}" = "--no-strict" ]; then
  STRICT=0
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or not on PATH" >&2
  exit 2
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Error: Docker Compose is not available." >&2
  exit 2
fi

BACKEND_FILE="$ROOT_DIR/docker-compose.backend.dev.yml"
FRONTEND_FILE="$ROOT_DIR/docker-compose.frontend.dev.yml"
ENV_FILE="$ROOT_DIR/.env.dev"

if [ ! -f "$BACKEND_FILE" ]; then
  echo "Error: backend compose file not found: $BACKEND_FILE" >&2
  exit 3
fi
if [ ! -f "$FRONTEND_FILE" ]; then
  echo "Error: frontend compose file not found: $FRONTEND_FILE" >&2
  exit 4
fi

# NOTE: Docker Compose only auto-loads a file literally named ".env" in the
# project directory for ${VAR} substitution *inside the compose YAML itself*.
# The service-level "env_file: .env.dev" only injects variables into the
# *container's* runtime environment. Passing --env-file here makes any
# overrides in .env.dev (e.g. a custom POSTGRES_PASSWORD) apply consistently
# to both the compose-time substitution and the container environment.
COMPOSE=(docker compose)
if [ -f "$ENV_FILE" ]; then
  COMPOSE+=(--env-file "$ENV_FILE")
fi
COMPOSE+=(-f "$BACKEND_FILE" -f "$FRONTEND_FILE")

echo "Using files:"
echo "  $BACKEND_FILE"
echo "  $FRONTEND_FILE"
echo

echo "Validating Docker Compose configuration..."
"${COMPOSE[@]}" config >/dev/null
echo "Compose configuration is valid."
echo

if [ "$CMD" = "build" ]; then
  echo "Building development images: backend + frontend"
  "${COMPOSE[@]}" build --parallel --pull
  echo "Dev images built successfully."
  exit 0
fi

if [ "$CMD" != "up" ]; then
  echo "ERROR: Unknown command: $CMD" >&2
  echo "Usage: ./docker.dev.sh [build|up] [--no-strict]" >&2
  exit 1
fi

# ------------------------------------------------------------------
# Build images
# ------------------------------------------------------------------
echo "Building development images: backend + frontend"
"${COMPOSE[@]}" build --parallel --pull
echo "Dev images built successfully."
echo

# ------------------------------------------------------------------
# Start PostgreSQL and wait for it to become healthy
# ------------------------------------------------------------------
echo "Starting PostgreSQL..."
"${COMPOSE[@]}" up -d db

DB_CID="$("${COMPOSE[@]}" ps -q db)"
if [ -z "$DB_CID" ]; then
  echo "ERROR: Could not determine PostgreSQL container id." >&2
  exit 5
fi

echo "Waiting for PostgreSQL to become healthy (container: $DB_CID)..."
DB_WAITED=0
DB_INTERVAL=2
while true; do
  DB_STATUS="$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$DB_CID" 2>/dev/null || echo none)"

  if [ "$DB_STATUS" = "healthy" ]; then
    echo "PostgreSQL is healthy."
    break
  fi

  if [ "$DB_STATUS" = "unhealthy" ]; then
    echo
    echo "ERROR: PostgreSQL became unhealthy." >&2
    echo
    "${COMPOSE[@]}" logs --tail=100 db >&2
    exit 6
  fi

  if [ "$DB_WAITED" -ge "$DB_TIMEOUT" ]; then
    echo
    echo "ERROR: Timed out waiting for PostgreSQL after ${DB_TIMEOUT}s (status=$DB_STATUS)." >&2
    echo
    "${COMPOSE[@]}" logs --tail=100 db >&2
    exit 7
  fi

  sleep "$DB_INTERVAL"
  DB_WAITED=$((DB_WAITED + DB_INTERVAL))
done
echo

# ------------------------------------------------------------------
# Start the Django backend and wait for it to become ready
# ------------------------------------------------------------------
echo "Starting Django backend..."
"${COMPOSE[@]}" up -d backend

echo
echo "Waiting for Django backend..."
echo "URL: http://${BACKEND_HOST}:${BACKEND_PORT}${BACKEND_PATH}"
echo

BACKEND_CID="$("${COMPOSE[@]}" ps -q backend || true)"
BACKEND_WAITED=0
BACKEND_INTERVAL=2

while true; do
  if [ -n "$BACKEND_CID" ]; then
    BACKEND_STATE="$(docker inspect --format='{{.State.Status}}' "$BACKEND_CID" 2>/dev/null || echo missing)"
    BACKEND_RESTARTS="$(docker inspect --format='{{.RestartCount}}' "$BACKEND_CID" 2>/dev/null || echo 0)"

    if [ "$BACKEND_STATE" = "exited" ] || [ "$BACKEND_STATE" = "dead" ] || [ "$BACKEND_STATE" = "missing" ]; then
      echo
      echo "ERROR: Django backend stopped unexpectedly (state=$BACKEND_STATE)." >&2
      echo
      "${COMPOSE[@]}" logs --tail=150 backend >&2
      exit 8
    fi

    if [ "$BACKEND_RESTARTS" -ge "$BACKEND_MAX_RESTARTS" ]; then
      echo
      echo "ERROR: Django backend is crash-looping (restarted ${BACKEND_RESTARTS} times)." >&2
      echo "        Failing fast instead of waiting out the full timeout." >&2
      echo
      "${COMPOSE[@]}" logs --tail=150 backend >&2
      exit 8
    fi
  fi

  if curl --fail --silent --show-error --max-time 5 \
      "http://${BACKEND_HOST}:${BACKEND_PORT}${BACKEND_PATH}" >/dev/null 2>&1; then
    echo "Django backend is responding."
    break
  fi

  if [ -n "$BACKEND_CID" ]; then
    if docker exec "$BACKEND_CID" sh -c "command -v curl >/dev/null 2>&1 && curl --fail --silent --max-time 5 http://127.0.0.1:8000${BACKEND_PATH}" >/dev/null 2>&1; then
      echo "Django backend is responding inside the container."
      break
    fi
  fi

  if [ "$BACKEND_WAITED" -ge "$BACKEND_TIMEOUT" ]; then
    echo
    echo "ERROR: Timed out waiting for Django backend after ${BACKEND_TIMEOUT}s." >&2
    echo
    echo "Backend container status:"
    "${COMPOSE[@]}" ps backend
    echo
    echo "Last backend logs:"
    "${COMPOSE[@]}" logs --tail=150 backend >&2

    if [ "$STRICT" -eq 1 ]; then
      exit 9
    else
      echo
      echo "WARNING: Continuing because --no-strict was specified."
      break
    fi
  fi

  sleep "$BACKEND_INTERVAL"
  BACKEND_WAITED=$((BACKEND_WAITED + BACKEND_INTERVAL))
done
echo

# ------------------------------------------------------------------
# Start the frontend
# ------------------------------------------------------------------
echo "Starting frontend..."
"${COMPOSE[@]}" up -d frontend

echo
echo "PostgreSQL is healthy."
echo "Django backend is responding."
echo "Development stack is running."
echo
echo "Frontend: http://127.0.0.1:8080"
echo "Backend:  http://${BACKEND_HOST}:${BACKEND_PORT}"
echo "Postgres: 127.0.0.1:${POSTGRES_PORT:-5432}"
echo
echo "To populate fully-featured test accounts (users, exercises, plans, workout history), run:"
echo "  ./scripts/init_test_environment.sh"
echo

"${COMPOSE[@]}" ps
