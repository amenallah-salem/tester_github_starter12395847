# WELLAURA Run & Environment Skill

Use whenever you need to start, stop, inspect, or validate the application.

## Preferred Development Startup
From repository root:
```bash
./docker.dev.sh up
```

Build only:
```bash
./docker.dev.sh build
```

The script validates Compose, starts PostgreSQL, waits for health, starts Django, probes `/api/health/`, then starts the frontend.

Expected development endpoints:
- frontend: `http://127.0.0.1:8080`
- backend: `http://127.0.0.1:8000`
- health: `http://127.0.0.1:8000/api/health/`
- PostgreSQL: `127.0.0.1:${POSTGRES_PORT:-5432}`

## Inspect Running Stack
```bash
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml -f docker-compose.frontend.dev.yml ps
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml -f docker-compose.frontend.dev.yml logs --tail=100 backend
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml -f docker-compose.frontend.dev.yml logs --tail=100 db
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml -f docker-compose.frontend.dev.yml logs --tail=100 frontend
```

## Stop
```bash
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml -f docker-compose.frontend.dev.yml down
```
Do not add `-v` unless deleting the development database volume is intentional.

## Reset Development Database
Only when explicitly required:
```bash
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml down -v
```
Warn before destructive resets.

## Production
Only when explicitly requested:
```bash
./docker.prod.sh up
```
Do not debug normal development problems by silently switching to production.

## Health Check
```bash
curl -i http://127.0.0.1:8000/api/health/
```

## Environment
Do not print secrets. Do not copy `.env` contents into chat. Use `.env.example` as the safe reference for required variables.
