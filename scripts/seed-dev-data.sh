#!/usr/bin/env bash
set -euo pipefail

# Seed the dev database with a starter exercise library and example workout
# plans. Safe to run repeatedly (idempotent) against the running dev backend.
# Usage: ./scripts/seed-dev-data.sh

cd "$(dirname "$0")/.."

COMPOSE=(docker compose --env-file .env.dev -f docker-compose.backend.dev.yml)

echo "=== Seeding exercise library ==="
"${COMPOSE[@]}" exec -T backend python manage.py seed_exercises

echo "=== Seeding workout plans ==="
"${COMPOSE[@]}" exec -T backend python manage.py seed_workouts

echo "=== Done ==="
