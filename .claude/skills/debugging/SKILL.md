# WELLAURA Debugging Skill

Use when something fails.

## Rules
- reproduce before editing when practical
- preserve the exact error
- isolate one layer at a time
- make one focused fix
- re-run the failing check
- run regression tests

## Docker Debugging
```bash
docker compose ps
docker compose logs --tail=150 backend
docker compose logs --tail=150 db
docker compose config
```
Use the actual compose files in this repository.

## Django Debugging
Check traceback, URL route, permission class, serializer validation, ORM query, migration state, and database connectivity. Do not mask exceptions with broad catches without a justified boundary.

## Flutter Debugging
Check route, provider state, repository request, response parsing, local cache, lifecycle/startup, and widget state. Avoid changing multiple state layers at once.

## Network/Device
Remember that `localhost` inside an emulator/container/device may not refer to the development host. Inspect the existing configurable API base URL mechanism before changing it.
