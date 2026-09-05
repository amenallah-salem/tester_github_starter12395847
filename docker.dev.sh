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