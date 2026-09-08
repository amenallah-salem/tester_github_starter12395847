# WELLAURA Investigation & Root-Cause Analysis Skill

Use this skill before changing code for bugs, regressions, unclear behavior, or unfamiliar features.

## Core Rule
Investigate first. Edit second.

Never make a speculative multi-file fix merely because an error message looks familiar.

## Investigation Loop
1. Reproduce the issue if possible.
2. Capture the exact error/behavior, including status codes and logs.
3. Classify the layer: Flutter UI, state, local DB, API client, Django view/serializer/model, PostgreSQL, Docker, CI, or external integration.
4. Search for the exact error, endpoint, class, widget, model, route, or configuration key.
5. Trace the data/control flow one layer backward and forward.
6. Identify the smallest root cause.
7. Check whether the behavior is intentional elsewhere.
8. Propose the smallest safe fix.
9. Implement.
10. Reproduce the original failure again.
11. Run regression tests.
12. Review the diff for unrelated changes.

## Evidence Hierarchy
Prefer:
1. reproducible test/failure
2. runtime logs
3. actual source/configuration
4. existing tests
5. documentation/comments
6. assumptions

If evidence conflicts with comments or README text, trust the actual executable behavior and update documentation when appropriate.

## Debugging Commands
Use targeted commands such as:
```bash
docker compose ps
docker compose logs --tail=150 backend
docker compose logs --tail=150 db
docker compose config
curl -i http://127.0.0.1:8000/api/health/
git status --short
git diff --stat
git diff
```
Use the exact compose files/env file from the repository. Do not blindly use generic `docker compose` if it selects the wrong project.

## Common Failure Patterns
### Authentication/session
Trace: Flutter startup -> stored credentials/session -> auth provider -> API client -> backend authentication -> user endpoint.

### Onboarding persistence
Trace: onboarding UI -> submit -> API -> Profile model -> response -> app state -> subsequent startup fetch.

### API bug
Trace: route -> permission/auth -> view -> serializer -> model/query -> database.

### Docker startup
Trace: compose interpolation -> env -> dependency health -> container logs -> application process -> readiness endpoint.

### Flutter UI bug
Trace: route -> screen -> provider/state -> repository -> local/API data -> widget rendering.

## Stop Conditions
Stop and ask for clarification only when a decision materially affects architecture/data/security and cannot be resolved from the repository. Otherwise choose the safest repository-consistent behavior and document the assumption.

