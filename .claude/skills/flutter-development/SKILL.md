# WELLAURA Flutter Development Skill

Use for Flutter/Dart work.

## Existing Stack
- Flutter
- Riverpod
- GoRouter
- Drift/SQLite
- HTTP client
- SharedPreferences
- connectivity_plus

Verify actual usage before adding another state-management, routing, persistence, or networking library.

## Architecture
Prefer the existing flow:
UI -> state/provider -> repository/data layer -> API/local persistence.

Do not put substantial networking/database logic directly into widgets.

## UI Rules
For each screen consider loading, success, empty, error, offline, and authentication states where applicable. Reuse existing theme, components, navigation, and spacing conventions.

## Routing
Inspect the current GoRouter configuration before adding routes. Do not create duplicate navigation paths.

## Persistence
Inspect existing Drift tables/DAOs and SharedPreferences usage before adding storage. Maintain compatibility with existing data.

## API
Never hard-code production URLs. Preserve the configurable API base URL strategy.

## Validation
Prefer:
```bash
cd frontend
flutter pub get
flutter analyze
flutter test
```
Run targeted tests first, then broader tests when warranted.
