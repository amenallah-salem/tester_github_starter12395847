# WELLAURA Agent Runbook

## Start
```bash
./docker.dev.sh up
```

## Verify
```bash
curl -i http://127.0.0.1:8000/api/health/
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml -f docker-compose.frontend.dev.yml ps
```

## Logs
```bash
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml -f docker-compose.frontend.dev.yml logs --tail=150 backend
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml -f docker-compose.frontend.dev.yml logs --tail=150 db
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml -f docker-compose.frontend.dev.yml logs --tail=150 frontend
```

## Backend Tests
```bash
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml exec backend python manage.py test gym_api
```

## Flutter Tests
```bash
cd frontend
flutter analyze
flutter test
```

## Stop
```bash
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml -f docker-compose.frontend.dev.yml down
```

Do not use `down -v` unless the task explicitly requires destroying the development database volume.
