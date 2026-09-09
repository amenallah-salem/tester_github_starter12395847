#!/usr/bin/env bash
set -euo pipefail

# Initialize the development/test environment from a single JSON source of
# truth: asserts/inputs_dev_env/json_file.json. Safe to run repeatedly
# (idempotent) against the running dev backend.
#
# This script and the Django management command it calls contain NO test
# data themselves — everything created (users, exercises, plans, plan
# assignments, workout history) comes from that JSON file. To change what
# gets seeded, edit the JSON and re-run this script; see
# asserts/inputs_dev_env/README.md for the full schema.
#
# Usage:
#   ./scripts/init_test_environment.sh [--check-only] [--file PATH]

cd "$(dirname "$0")/.."

COMPOSE=(docker compose --env-file .env.dev -f docker-compose.backend.dev.yml)

echo "=== Initializing test environment from asserts/inputs_dev_env/json_file.json ==="
"${COMPOSE[@]}" exec -T backend python manage.py init_test_environment "$@"

echo "=== Done ==="
