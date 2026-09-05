#!/usr/bin/env bash
set -euo pipefail

# Build-only prod script: builds backend and frontend production images
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Building production images: backend + frontend"

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or not on PATH" >&2
  exit 2
fi

BACKEND_FILE="$ROOT_DIR/docker-compose.backend.prod.yml"
FRONTEND_FILE="$ROOT_DIR/docker-compose.frontend.prod.yml"

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

echo "Note: Ensure required env vars (POSTGRES_*, etc.) are set or provided via .env.prod before running the built containers."

docker compose -f "$BACKEND_FILE" -f "$FRONTEND_FILE" build --parallel --pull

echo "Prod images built successfully."