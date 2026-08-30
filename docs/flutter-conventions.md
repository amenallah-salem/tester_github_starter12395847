# Flutter Naming & Conventions Guide — AI Gym Assistant

Companion to [`docs/flutter-architecture.md`](flutter-architecture.md). These
rules apply to all code under `app/`. They are borrowable, minimal, and enforced
by `flutter_lints` + CI in later tasks.

---

## 1. File & folder naming

| Kind | Rule | Example |
|---|---|---|
| Directories | **`snake_case`**, one concept per level | `features/workout/screens` |
| Dart source files | **`snake_case.dart`** | `auth_repository.dart` |
| Test files | `_test.dart` suffix, mirrors source path | `test/unit/services/api/auth_interceptor_test.dart` |
| Android Gradle flavors | **`lowerCamelCase`** | `development`, `staging`, `production` |
| iOS schemes/configs | lowerCamelCase, same names | `development` |

- One widget/class per file (name must match content).
- Screen files end in `_screen.dart`, feature-local widgets in `_widget.dart` or
  plain feature-noun names.
- **Never** pluralize folder names (`screens`, not `screen`) inconsistently —
  pick one per feature and keep it.

---

## 2. Dart identifiers

| Kind | Convention | Example |
|---|---|---|
| Classes / enums / mixins | `UpperCamelCase` | `WorkoutSessionDto` |
| Constants | `lowerCamelCase` **or** `SCREAMING_SNAKE_CASE` for literals | `defaultPageSize`, `kAppName` |
| Variables / functions | `lowerCamelCase` | `fetchNext()` |
| Private members | prefix `_` | `_isRefreshing` |
| Type params | single uppercase or `PascalCase` with `T` | `Repository<T>` |
| Booleans | predicate-style (`has`, `is`, `can`, `should`) | `hasSession`, `isOffline` |

**Model/state suffixes** (fixed vocabulary):

| Suffix | Meaning | Example |
|---|---|---|
| `Dto` | generated wire model (1:1 contract) | `ExerciseDto` |
| `Failure` | error result | `UnauthorizedFailure` |
| `Repository` | data-access layer | `PlanRepository` |
| `Service` | infrastructure operation | `AuthService` |
| `Controller` / `Notifier` | Riverpod state holder | `WorkoutController` |
| `Result` | typed outcome wrapper | `Result<T>` |
| `Manager` | **not used** — prefer Repository/Service |

---

## 3. Rivers / state naming

- Feature provider: `featureXProvider` → `featureXControllerProvider`.
- Notifier class: `XController extends AsyncNotifier<Y>`.
- Provider file per feature: `features/<name>/controllers/<name>_controller.dart`
  exporting one or few providers — a single provider per use site is the goal.
- Do not expose repositories to UI; expose **Provider / StateNotifier families**.

---

## 4. Architecture & dependency rules (project-internal)

- Screens never import `services/`, storage, or Dio — only providers.
- Repositories never return `http.Response`/`DioException` raw — always
  `Result<T>` (from `core/errors`) with typed failures.
- Features never import other features' screens or controllers. Shared logic
  lives in `core/`, `services/`, `repositories/`, or `widgets/`.
- `core/` imports nothing from `features/`, `state/`, `services/`,
  `repositories/`.
- No `BuildContext` coupling outside widgets.

---

## 5. Widget conventions

- `const` constructors wherever the widget tree allows it (enable
  `prefer_const_constructors` in `analysis_options.yaml`).
- Widgets are always: `const Foo({super.key, required ...})`.
- Prefer composition over deep nesting; extract any subtree with
  `MediaQuery`/`LayoutBuilder`/logic into its own widget/function.
- Widget **keys**: use value/object keys in tests (`ValueKey`) instead of
  fragile text lookups.
- No business logic in widgets — only present state that already came from a
  provider.

---

## 6. State management conventions

- All mutable app state flows through Riverpod `Notifier`/`AsyncNotifier`.
- **No `StatefulWidget`** solely to hold business state (local form controllers
  + focus nodes are fine).
- Use `AsyncValue.guard`/`ref.watch` to derive `loading/error/data` instead of
  hand-rolled flags.
- Do not hold mutable state in `static`/`global` variables; use providers.

---

## 7. Models & serialization

- DTOs only from `docs/api-contract-v1.yaml` via generator (committed under
  `lib/models/generated/`).
- Keep `fromJson`/`toJson` wire shapes **identical** to the contract
  (snake_case). Never "fix" a field name client-side and drift from the wire.
- Domain-only helpers live as mapped types in `models/mappers/`.
- Prefer `sealed`/`freezed`-style exhaustive handling for state unions; add
  `json_serializable` only when hand-writing an enumerated type is cleaner.

---

## 8. Error handling

- Throw typed `AppFailure` subtypes; catch at the boundary (notifier/screen) and
  convert to user messages via `AppFailure.mapToUserMessage`.
- Never `.catchError`/`try/catch` and swallow; always log or wrap.
- Network errors must not bubble raw `DioException` texts to users.

---

## 9. Async & futures

- Prefer `AsyncValue` and `AsyncNotifier` over raw `FutureBuilder` unless local
  and trivial.
- `async/await` everywhere; `then/catchError` only for pipelines that far.
- Tag long-lived futures with named parameters for debuggability; prefer the
  `unawaited()` helper for fire-and-forget rehydration.

---

## 10. Styling & design tokens

- Colors, spacing, radii, typography ONLY from `core/theme/` tokens.
- No hardcoded hex colors/margins in widgets (lint `NoHardcodedColors`,
  `NoHardcodedSpacing` where available) — let the theme be the single point.
- Use `Theme.of(context)` and the media-query-responsive helper in
  `core/utils/`.

---

## 11. Imports

Order (`dart format` + `directives_ordering`):

1. `dart:` (stdlib)
2. `package:` (flutter + third-party)
3. relative (`../`)

Rules:

- **Package imports** inside `lib/`; relative imports only across same feature.
- Never import from a sibling feature folder (`features/a` → `features/b` ✗).
- Wildcard imports only for generated model barrels (`generated/models.dart`).

---

## 12. Tests

- Mirror the source tree under `test/`.
- Unit: repositories/services/notifiers/mappers/models — with `test/mocks/`
  fakes (no brittle network mocks; override providers).
- Widget: golden tests for shared `widgets/`; smoke tests for screens.
- Each feature task lands with unit + widget test coverage for:
  loading, empty, error, and success paths (the four `AsyncValue` states).
- **Always override providers** in `ProviderScope` per test; never rely on a
  real backend or real network.

---

## 13. Git & PR conventions (frontend part)

- Feature work branches: `feat/<feature>`; docs branches: `docs/<topic>`;
  flavor/tooling branches: `chore/flavors-<env>`.
- Commit messages: conventional style with a scope, e.g.
  `feat(workout): log set with previous-performance prefill`, `docs(flavors):
  document API_BASE_URL resolution`.
- PR body includes: what changed, how it maps to the feature task, test
  evidence, and a screenshot for UI work.
- Re-run `dart format`, `flutter analyze`, and `flutter test` before opening a PR.

---

## 14. Optional quick reference (cheat sheet)

```
Folders       → snake_case
Files         → snake_case.dart, screens end _screen, tests end _test
Classes       → UpperCamelCase (+Dto/+Repository/+Service/+Controller/+Notifier)
Methods/vars  → lowerCamelCase; booleans is/has/can/should
Private       → _underscore
Constants     → lowerCamelCase or SCREAMING_SNAKE for literals
State         → Riverpod only; screens just watch providers
Errors        → typed AppFailure → mapToUserMessage at boundary
Style tokens  → core/theme only, never inline colors/spacing
Wire shapes   → generated DTOs, 1:1 with OpenAPI contract
Imports       → dart: → package: → relative; no cross-feature imports
Tests         → ProviderScope overrides; cover loading/empty/error/success
```