# Flutter Architecture — AI Gym Assistant

Applies to the `app/` Flutter application of the AI Gym Assistant monorepo
(`tester_github_starter12395847`). This document is the single source of truth
for frontend project structure, state management, dependency injection,
service/repository layering, model strategy, build flavors, and offline
behavior. It satisfies the Flutter requirements of project instruction
[SIW-6 §2, §4, §22] and the plan §4 **Flutter principles**.

---

## 1. Goals and non-goals

### Goals

- Clean separation of UI, state, networking, models, authentication,
  configuration, local storage, and business logic — **no mixed-responsibility
  "god" widgets or god services**.
- The app is built against a documented API contract (`docs/api-contract-v1.yaml`,
  task T-07). Flutter never invents endpoints.
- Environment configuration (API base URL) is changeable **without modifying
  application source code** (SIW-6 §4): flavors + `--dart-define`.
- A central API client with an auth interceptor and single-flight token refresh.
- A predictable local-persistence and offline-cache strategy.
- A layout every feature task (T-10, T-15, T-16, T-19, T-23, T-25, T-28, T-29,
  T-32) can implement directly against.

### Non-goals (now)

- Server-driven UI / remote themes.
- Multi-tenant branding.
- AI coaching, payments, notifications, wearables — these are allocated one
  explicit future hook each (see §10) and not built now.

---

## 2. Folder layout (maps to plan §4 `app/lib/**`)

Plan §4 and SIW-6 §22 both prescribe the same core folders:
`core/`, `config/`, `models/`, `services/`, `repositories/`, `state/`,
`features/`, `widgets/`, `routing/`. The layout below is the canonical mapping.

```
app/
├── lib/
│   ├── main.dart                    # entrypoint: load AppConfig → runApp(ProviderScope(...))
│   ├── app.dart                     # root widget: MaterialApp.router + theme
│   │
│   ├── core/                        # framework-agnostic, feature-independent
│   │   ├── theme/                   #   design tokens, colors, typography, ThemeData builders
│   │   ├── errors/                  #   AppFailure hierarchy + error→message mapping
│   │   ├── utils/                   #   formatters, validators, math, extensions
│   │   └── constants/               #   non-secret constants (routes? no — see routing/)
│   │
│   ├── config/                      # environment + flavors (see §7)
│   │   ├── app_config.dart          #   resolved AppConfig (apiBaseUrl, env, flags)
│   │   ├── environments/
│   │   │   ├── development.dart     #   dev defaults (REQUIRES API_BASE_URL)
│   │   │   ├── staging.dart         #   staging defaults (https URL)
│   │   │   └── production.dart      #   production defaults (https URL)
│   │   └── build_environment.dart   #   enum development/staging/production + parsing
│   │
│   ├── routing/                     # navigation, centralized (one router)
│   │   ├── app_router.dart          #   go_router config, redirect logic, guards
│   │   └── route_paths.dart         #   route name/path constants
│   │
│   ├── widgets/                     # cross-feature reusable UI
│   │   ├── loading_indicator.dart
│   │   ├── empty_state.dart
│   │   ├── error_state.dart
│   │   ├── app_button.dart
│   │   └── ...                      #   small, composable, token-driven
│   │
│   ├── models/                      # DTOs derived from T-07 OpenAPI contract
│   │   ├── generated/               #   openapi-generator output (committed)
│   │   ├── enums/                   #   hand-written where generator output is weak
│   │   └── mappers/                 #   DTO → domain / domain → DTO
│   │
│   ├── services/                    # infrastructure, no UI, no feature rules
│   │   ├── api/
│   │   │   ├── api_client.dart      #   central Dio client + configuration
│   │   │   ├── auth_interceptor.dart#   attaches Authorization header
│   │   │   ├── token_refresh_interceptor.dart  # 401 → single-flight refresh → retry
│   │   │   └── error_transformer.dart
│   │   ├── auth/
│   │   │   └── auth_service.dart    #   register/login/logout/refresh orchestration
│   │   ├── storage/
│   │   │   ├── token_storage.dart   #   flutter_secure_storage (refresh/access tokens)
│   │   │   └── cache_storage.dart   #   hive/shared_preferences cache (see §9)
│   │   └── connectivity/
│   │       └── connectivity_service.dart
│   │
│   ├── repositories/                # data access; decide cache vs network (§5.4, §9)
│   │   ├── auth_repository.dart
│   │   ├── profile_repository.dart
│   │   ├── exercise_repository.dart
│   │   ├── plan_repository.dart
│   │   ├── workout_repository.dart
│   │   └── progress_repository.dart
│   │
│   ├── state/                       # app-wide, provider-of-choice in §6
│   │   ├── app_providers.dart       #   shared providers (auth state, session, settings)
│   │   └── notifiers/
│   │       └── auth_controller.dart #   example: AuthController extends AsyncNotifier
│   │
│   └── features/                    # one folder per product slice; OWN UI + state
│       ├── auth/
│       │   ├── screens/             #   login_screen.dart, register_screen.dart
│       │   ├── widgets/             #   feature-local widgets
│       │   └── controllers/         #   feature state/providers (Riverpod notifiers)
│       ├── onboarding/
│       ├── exercises/
│       ├── equipment/
│       ├── plans/
│       ├── workout/                 #   today's workout + set logging
│       ├── progress/
│       ├── history/                 #   history + calendar
│       ├── dashboard/
│       └── settings/
│
├── test/                            # unit + widget tests
│   ├── unit/                        #   repositories, services, notifiers, mappers, models
│   ├── widget/                      #   feature widget tests
│   └── mocks/                       #   fakes/fixtures used across tests
│
├── integration_test/                # at least one E2E flow (auth → onboarding → plan)
│
├── android/                         # flavor configs (see §7.2)
│   └── app/build.gradle.kts         #   productFlavors + flavorDimensions
│
└── ios/                             # flavor configs (see §7.3)
    ├── Runner.xcodeproj             #   3 schemes: development, staging, production
    └── Runner/                      #   Info.plist driven by build configurations
```

### Dependency direction (must not be violated)

```
UI (screens/widgets)
   → state (notifiers/providers)
   → repositories
   → services (api, auth, storage, connectivity)
   → models (DTOs) / core
```

- **Screens never touch** `Dio`/api clients, storage, or repositories directly.
  They only `ref.watch`/`ref.listen` providers and call methods on notifiers.
- **Repositories never touch** widgets or provider state. They expose the
  `Result` type from `core/errors`.
- **Services never render anything.**

---

## 3. State management: Riverpod

### Choice

**`flutter_riverpod` (Riverpod 2 / `AsyncNotifier`, plus `riverpod_annotation` +
Riverpod Generator for provider codegen).**

### Rationale (vs alternatives)

| Option | Verdict | Why |
|---|---|---|
| **Riverpod (chosen)** | ✅ | Compile-safe providers (no `context.watch<T>()` string lookups), no reliance on widget-tree build-time wiring, first-class async state (`AsyncValue`), trivial test overrides (`ProviderContainer`), built-in DI (see §4), scales to feature-notifier pattern. |
| Provider | ❌ | Superseded by Riverpod (same author); widget-tree dependent, weaker testability. |
| Bloc | ⚠️ | Preferable for very large teams that want strict event-driven flow; much more boilerplate for our feature-notifier granularity. |
| `setState` only | ❌ | Fine inside a screen, not app-wide; does not separate state from UI. |

Riverpod keeps state **outside the widget tree**, which is exactly what the
project instruction means by "state ... appropriately separated".

### Rules

- **Feature state lives in the feature folder** (`features/<x>/controllers/`),
  exposed via a feature-scoped provider.
- **App-wide state lives in `state/`** (auth session, active plan id, settings).
- A feature's notifier may call exactly the repositories it needs; it must not
  reach into another feature's controllers.
- All loading/empty/error rendering flows from `AsyncValue` + the shared widget
  components in `widgets/` (see §8).

---

## 4. Dependency injection (DI)

### Approach

Riverpod **is** the DI container:

- **Composition root** = `ProviderScope(overrides: [...])` created in `main.dart`
  after `AppConfig` resolves.
- **Services** (api client, storage, connectivity) are exposed as plain
  providers (`Provider`), constructed once, replaced in tests via overrides.
- **Repositories** consume services/other repositories through `ref`.
- **Notifiers** consume repositories through `ref` and expose UI state.

### Resolution order for API configuration

`AppConfig` resolves in this order (see §7.4):

1. `--dart-define` values passed at build/run time (highest priority).
2. Flavor default from the environment config matching the active flavor.
3. Guard/assert (fails fast on `localhost`/`127.0.0.1` unless the explicit
   `ALLOW_LOCAL_API` escape hatch is set).

### Test DI

```dart
ProviderScope(
  overrides: [
    apiClientProvider.overrideWithValue(ApiClient(customDio)),
    authRepositoryProvider.overrideWith(fakeAuthRepository),
  ],
  child: MyApp(),
)
```

### Construction rules

- No `get_it` service-locator for new code. If a future plugin forces it, keep it
  confined to `core/` + one provider, never spread across the app.
- Never `global` singletons holding mutable state; only immutable singletons via
  providers.

---

## 5. Service / repository layering

### 5.1 API client (central)

One `Dio` instance in `services/api/api_client.dart`, configured by `AppConfig`:

- `baseUrl` = resolved `AppConfig.apiBaseUrl` (never localhost/127.0.0.1 — §7.4).
- `connectTimeout`/`receiveTimeout` per environment.
- Standard JSON content-type.
- Error transformer normalizes `DioException` → `AppFailure` hierarchy
  (`NetworkFailure`, `ServerFailure`, `UnauthorizedFailure`, `ValidationFailure`,
  `OfflineFailure`).

### 5.2 Auth interceptor

`auth_interceptor.dart`:

- On `onRequest`: if a session exists, set `Authorization: Bearer <accessToken>`.
- On `onError` with status 401 (and endpoint != refresh):
  1. Acquire the **single-flight refresh lock** (a shared `Completer<TokenPair>`).
  2. Call `/api/v1/auth/refresh` with the stored refresh token.
  3. On success: swap tokens in secure storage, re-run the failed request once
     with the new token.
  4. On refresh failure: clear session, emit `AuthSessionExpired`, redirect to
     the auth flow.
- Concurrent 401s **wait on the same in-flight refresh** (no refresh storms).

See T-08 (`auth strategy + environment strategy + CI/CD architecture`) for the
matching backend JWT contract (access/refresh rotation via
`djangorestframework-simplejwt`).

### 5.3 Authentication service

`AuthService` orchestrates register / login / logout / refresh / forgot / reset /
change-password against the contract endpoints and persists the session through
`TokenStorage`.

### 5.4 Repositories

Each repository owns **one domain slice** and presents the data-access API the
feature notifiers actually call. It decides the source:

| Policy        | Used for                                        | Behavior |
|---|---|---|
| `cacheFirst`  | catalogs: exercises, equipment, muscles, plans  | serve cache immediately; refresh in background; update cache + notify |
| `networkFirst`| user-owned data: profile, progress, history     | network; on failure serve last-known-good with `source: cache` |
| `remoteOnly`  | mutations: register, login, set logging         | always network; failures surfaced |

Repositories expose typed `Result<T>` (from `core/errors`) or `AsyncValue`
via notifiers — never raw Dio objects.

---

## 6. Model strategy (DTOs matching the T-07 OpenAPI contract)

- **Source of truth:** `docs/api-contract-v1.yaml` (`docs/api.md` readable form),
  produced by T-07 and consumed here.
- **Generation:** `lib/models/generated/` is produced from the contract via
  `openapi-generator` (Dart/Dio flavor) and **committed**. Regenerate when the
  contract changes (CI job in later tasks; documented in `CONTRIBUTING.md`).
- **Immutability:** DTOs are immutable, use `fromJson`/`toJson` matching the
  contract's snake_case fields.
- **Naming:** DTO classes mirror contract schema names (`ExerciseDto`,
  `WorkoutSessionDto`). Field accessors map snake_case JSON to Dart
  camelCase via generator config.
- **Domain vs DTO:** where a feature needs behavior (e.g. computed volume,
  `GlobalKey`-free formatting) the feature keeps a thin domain wrapper in
  `models/mappers/` (e.g. `WorkoutSession → WorkoutSummary`). Do **not**
  duplicate entire DTOs by hand.
- **Enums:** contract enums first mirror generator output; hand-tune in
  `models/enums/` only where the generator output is unusable, keeping the
  wire values identical.

Prefer **1:1 DTO↔contract**; any deviation (extra client-only field) must be a
mapped domain type, never a silent change to the serialized shape.

---

## 7. Flavors and configuration

Three flavors: **`development`** · **`staging`** · **`production`**.

> Rule (SIW-6 §4): the API base URL is configured at build/run time and must
> **never** default to `localhost` / `127.0.0.1` as a permanent address.
> `localhost` on a physical phone is the *phone*, not the laptop.

### 7.1 Where values come from

```
--dart-define (build/run time)   ←  highest priority
        ↓
featured environment default     ←  config/environments/<flavor>.dart
        ↓
AppConfig assert                 ←  rejects localhost/127.0.0.1 unless ALLOW_LOCAL_API
```

### 7.2 Android flavor setup

`android/app/build.gradle.kts`:

```kotlin
flavorDimensions += "env"
productFlavors {
    create("development") { dimension = "env"; applicationIdSuffix = ".dev" }
    create("staging")    { dimension = "env"; applicationIdSuffix = ".staging" }
    create("production") { dimension = "env" }
}
```

`--dart-define` values are passed through by the Flutter tooling automatically
(no extra wiring required in Gradle).

### 7.3 iOS flavor setup

- Xcode: three **schemes** (`development`, `staging`, `production`) mapped to
  three build **configurations**; the scheme `Runner` uses is chosen by
  `--flavor`.
- Per-configuration values (Product Bundle Identifier, display name) set in
  `Configuration` build settings so `Info.plist` stays environment-agnostic.
- `--dart-define` works identically on iOS.

### 7.4 Resolved configuration & guard

`config/app_config.dart`:

```dart
factory AppConfig.resolve({
  required BuildEnvironment environment,
  required String? apiBaseUrlFromDartDefine, // const String.fromEnvironment
}) {
  final base = apiBaseUrlFromDartDefine?.isNotEmpty ?? false
      ? apiBaseUrlFromDartDefine!
      : environment.defaultBaseUrl;
  // Assert placement: after merge, before use.
  assert(!AppConfig.isLoopbackOnly(base), 'API_BASE_URL must not be localhost/127.0.0.1');
  return AppConfig(environment: environment, apiBaseUrl: base);
}
```

`ALLOW_LOCAL_API=true` (a `--dart-define`) is the **only** way to bypass the
guard (used solely for SwiftUI/emulator prototyping or CI-on-localhost); it is
never a default and never shipped in staging/production.

### 7.5 Run/build commands (documented for the team)

Development (physical device on the same Wi-Fi — use your laptop's LAN IP,
**never** `localhost`):

```bash
flutter run --flavor development \
  --dart-define=API_BASE_URL=http://192.168.1.42:8000/api/v1
```

Staging / production (real HTTPS endpoints; defaults live in
`config/environments/`, overridable per CI/CD task):

```bash
flutter run --flavor staging
flutter run --flavor production

flutter build apk --flavor production
flutter build appbundle --flavor production
flutter build ios --flavor production --no-codesign
```

Run Android emulator against host backend with explicit LAN IP only
(`adb reverse` is optional and does not change the rule above).

---

## 8. Loading / empty / error / responsive conventions

- **Loading:** `widgets/loading_indicator.dart` (spinner + optional label).
- **Empty:** `widgets/empty_state.dart` (icon, title, action).
- **Error:** `widgets/error_state.dart` (message from `AppFailure.mapToUserMessage`,
  retry callback).
- Screens render **exclusively** from `AsyncValue.when(loading:empty:error:data:)`
  composed with these components — no bespoke per-feature loading/error UIs.
- **Responsive:** mobile-first; large-screen pass (web/tablet) uses
  `LayoutBuilder`/`WidgetsBindingObserver` and a shared `Breakpoint` helper in
  `core/`. No fixed-width content assumptions in shared widgets.

---

## 9. Local persistence & offline-cache strategy

| Concern                     | Technology            | Where                        |
|-----------------------------|-----------------------|------------------------------|
| Access/refresh tokens       | `flutter_secure_storage` | `TokenStorage`            |
| Session/auth flags, small settings | `shared_preferences` | `CacheStorage`        |
| Cached catalogs (exercises, plans, equipment) | **Hive** (typed boxes, TTL + schema version) | `CacheStorage` |
| Pending offline operations  | Hive `pending_ops` queue (write-behind)     | repositories      |

### Offline flow

1. `ConnectivityService` publishes online/offline state (provider).
2. Repository `cacheFirst` reads from cache, returns immediately, then refreshes
   when online; `networkFirst` retries, then serves last-known-good flagged
   `source: cache`.
3. Workout set logging while offline enqueues a `PendingOp` (type + payload +
   attemptedAt) that replays on reconnect; idempotency keys assigned by the
   backend contract keep retries safe.
4. Cache invalidation: on successful write, invalidate the affected queries;
   versioned boxes increment on schema change (force re-fetch).

Offline scope for MVP: browsing exercises/plans and viewing last-known data.
Real-time sync of logged sets is the T-17/T-26 scope; this strategy makes it
additive, not a rewrite.

---

## 10. Future hooks (architecture-ready, not built now)

- **AI coaching / personalization:** feature folder `features/ai/`, driven by
  backend endpoints; no local logic.
- **Subscriptions / payments:** feature folder `features/subscription/` +
  `PaymentService` behind the same repository pattern.
- **Notifications:** `NotificationService` + provider stub reserved in
  `services/`; iOS/android permission wiring documented when task lands.
- **Wearables:** `WearableService` seam in `services/`; storage/state unchanged.

---

## 11. Implementation checklist for downstream tasks

Each of T-10, T-15, T-16, T-19, T-23, T-25, T-28, T-29, T-32 must:

1. Add its feature under `lib/features/<name>/` (`screens`, `widgets`, `controllers`).
2. Add one repository in `repositories/` (or extend an owner repository) using
   the source-policy table in §5.4.
3. Add models only as generated DTOs mapped from `docs/api-contract-v1.yaml`
   (regenerate `lib/models/generated/`).
4. Register routes in `routing/app_router.dart` (paths in `route_paths.dart`).
5. Render loading/empty/error via `widgets/` components.
6. Compose app-wide state (if any) in `state/`, feature state in the feature.
7. Cover the feature with `test/unit` + `test/widget` tests and the shared
   mocks in `test/mocks/`.

The **naming and coding conventions** for all of the above are in
[`docs/flutter-conventions.md`](flutter-conventions.md).

---

## References

- Project master instruction: [SIW-6](/SIW/issues/SIW-6) §2 (technology), §4
  (dev env / API URL), §22 (Flutter architecture).
- Project plan §4 "Flutter principles": flavors + `--dart-define`, central API
  client + interceptor + once-token refresh, local persistence, reusable
  components, response-layout — this document implements each.
- API contract (source of truth for models): T-07 → `docs/api-contract-v1.yaml`,
  `docs/api.md`.
- Auth/environment/CI-CD architecture: T-08.