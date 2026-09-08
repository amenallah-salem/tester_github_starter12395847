# WELLAURA Testing & Validation Skill

A task is not done because code compiles. It is done when intended behavior is validated.

## Test Pyramid
1. targeted test for changed behavior
2. affected component/module tests
3. integration/end-to-end checks when boundaries changed
4. full suite only when justified

## Backend
```bash
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml exec backend python manage.py test gym_api
```

## Flutter
```bash
cd frontend
flutter analyze
flutter test
```

## Docker
```bash
docker compose --env-file .env.dev -f docker-compose.backend.dev.yml -f docker-compose.frontend.dev.yml config
```

## Behavioral Validation
For bugs, reproduce the original failure before and after the fix when practical. For API changes validate status code and response contract. For persistence changes verify data survives the relevant lifecycle. For authentication changes test login, restart/session restoration, logout, and unauthorized access as applicable.

## Completion Report
Report what changed, checks run, results, and anything not run with the reason.
