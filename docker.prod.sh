#!/bin/bash
# Production launcher: gunicorn backend + optimized web build
set -euo pipefail
echo "=== Production Mode ==="
docker compose -f docker-compose.yml up --build -d backend frontend || docker compose up --build -d backend frontend
echo "Prod running: frontend http://localhost:8080 | backend http://localhost:8000 (proxy via nginx)"
