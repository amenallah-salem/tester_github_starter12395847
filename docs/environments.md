# Environment Strategy

Applies to: **SIW-6 §4 (configurable API URL), §24/§25 (Docker + local network dev), SIW-8 (T-06 Flutter architecture)**

Goal: the API base URL **must be configurable without editing application source code**, and
`localhost`/`127.0.0.1` must **never** be the permanent/hardcoded API address (on a physical
phone `localhost` is the phone itself, not the developer laptop).

## 1. Environment matrix (SIW-6 §4)

| Environment | API base URL                         | Who uses it                     | Auth                          |
| ----------- | ------------------------------------ | ------------------------------- | ----------------------------- |
| Development | `http://<laptop-lan-ip>:8000/api/v1` | Dev laptop + **physical phone**, same Wi-Fi | HTTP on LAN (dev only) |
| Staging     | `https://staging-api.example.com/api/v1` | QA / preview, TestFlight builds | HTTPS |
| Production  | `https://api.example.com/api/v1`     | End users                       | HTTPS |

- `<laptop-lan-ip>` is the developer's laptop LAN address (e.g. `192.168.1.100`), resolved once
  per run, **not** committed as the permanent value.
- Staging/production values are placeholders until dns/domains are provisioned (owner: DevOps
  Lead in the deployment tasks); the config mechanism below accepts any URL and does not need
  source changes to point at the real domains.

**Rules (from SIW-6 §4):**

1. API URL is supplied at **build/run time**, never hardcoded in source.
2. `flutter run --flavor development` uses development defaults, overridable per run with
   `--dart-define=API_BASE_URL=...`.
3. No `localhost` / `127.0.0.1` default in committed source. If source ever needs a dev fallback
   it fails loudly ("API_BASE_URL not provided") rather than silently pointing at the phone.
4. The same mechanism serves Android, iOS, and Web.

## 2. Mechanism

### 2.1 Flutter: `--dart-define` + flavors

- **Primary override:** `--dart-define=API_BASE_URL=<url>` — wins over every flavor default.
- **Flavor defaults** (`development` / `staging` / `production`) provide conventional values so a
  plain `flutter run --flavor development` works on a dev machine without extra flags.
- Resolution (highest precedence first):

  1. `String.fromEnvironment('API_BASE_URL')` set on the command line;
  2. flavor run-config default (a development LAN placeholder, or the staging/prod domains);
  3. no fallback to `localhost` — throw at startup if nothing resolved.

- Implementation outline (`lib/config/app_config.dart`, owned by T-06):

  ```dart
  const _fallback = String.fromEnvironment('API_BASE_URL');
  class AppConfig {
    static Uri get apiBaseUrl {
      final raw = const String.fromEnvironment('API_BASE_URL');
      if (raw.isEmpty) throw StateError('API_BASE_URL is required (use --dart-define=API_BASE_URL=...)');
      return Uri.parse(raw);
    }
  }
  ```

- Flavor wiring (Android + iOS): standard Flutter flavors with `--flavor`; per-flavor
  `--dart-define` defaults injected by helper scripts (`tool/flutter_run_dev.sh`) that resolve the
  laptop LAN IP automatically for development.

### 2.2 Backend: `DJANGO_ENV` + settings split + env vars

- Settings module selected by `DJANGO_ENV`:
  - `development` → `config.settings.development`
  - `staging` → `config.settings.staging`
  - `production` → `config.settings.production`
- Values read from environment variables (via `django-environ` / `.env` file), **never**
  committed. `.env` files rotate per environment; `.env.example` documents keys.
- Docker compose picks the same `DJANGO_ENV` so containers mirror the matrix.

### 2.3 Backend environment variables

| Variable                     | development default                          | staging / production                       |
| ---------------------------- | -------------------------------------------- | ------------------------------------------ |
| `DJANGO_ENV`                 | `development`                                | `staging` / `production`                   |
| `DJANGO_SECRET_KEY`          | dev-only value (gitignored)                  | strong secret from CI/secret store         |
| `DJANGO_DEBUG`               | `true`                                       | `false`                                    |
| `DJANGO_ALLOWED_HOSTS`       | `localhost,127.0.0.1,<laptop-lan-ip>,*` (dev) | `staging-api.example.com` / `api.example.com` |
| `DJANGO_CORS_ALLOWED_ORIGINS` | dev UI origins (`http://localhost:*`, LAN IP) | public app/web origins                     |
| `DATABASE_URL`               | `postgres://gym:gym@localhost:5432/gym_dev`  | managed Postgres DSN                        |
| `ACCESS_TOKEN_LIFETIME_MIN`  | `15`                                         | `15`                                       |
| `REFRESH_TOKEN_LIFETIME_DAYS`| `30`                                         | `30`                                       |
| `EMAIL_*` (SMTP)             | console backend                              | real SMTP / provider                       |
| `SENTRY_DSN` (optional)      | unset                                        | project DSN                                |

### 2.4 Django settings enforcement (`base.py` shared, per-env overrides)

```python
# config/settings/base.py
DEBUG = False
ALLOWED_HOSTS = split_env("DJANGO_ALLOWED_HOSTS", [])
CSRF_TRUSTED_ORIGINS = split_env("DJANGO_CSRF_TRUSTED_ORIGINS", [])

# production.py enforces
DEBUG = False
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = 31536000
```

### 2.5 Hosts (ALLOWED_HOSTS) & CORS per environment

| Env | `ALLOWED_HOSTS`                    | `CORS` notes                                                                  |
| --- | ---------------------------------- | ----------------------------------------------------------------------------- |
| dev | `localhost`, `127.0.0.1`, laptop LAN IP, container hostname | User's-permissive: any `http://localhost:*` and the laptop LAN origin. Mobile apps send **no** `Origin` — CORS only matters for Flutter Web / admin |
| staging | `staging-api.example.com` (+ CI preview hostnames)  | `https://staging.example.com` app origin / `https://staging-app.example.com`   |
| prod | `api.example.com`                  | `https://app.example.com` etc., explicit allowlist only                        |

- `django-cors-headers`: `CORS_ALLOWED_ORIGINS` per env; never `CORS_ALLOW_ALL_ORIGINS` outside
  raw local development. Mobile (native) requests carry no `Origin` header and are unaffected.
- `CSRF_TRUSTED_ORIGINS` matches `CORS_ALLOWED_ORIGINS` for cookie-bearing admin/session flows.

## 3. Docker & local-network development (SIW-6 §25)

```
Developer Laptop  ──Wi‑Fi/LAN──▶  Physical phone
   Django :8000 ◀────────────────── Flutter app (API_BASE_URL=http://<lan-ip>:8000/api/v1)
```

1. **Find the laptop IP:** `ip addr` / `ipconfig getifaddr en0` → note the LAN address.
2. **Run the backend:** `docker compose up` (Django listens on `0.0.0.0:8000` in dev).
3. **Expose port 8000:** dev `docker compose` publishes `8000:8000`; verify
   `curl http://<lan-ip>:8000/api/v1/health/` from the phone's browser.
4. **Same network:** phone on the same Wi-Fi; firewall allows the port.
5. **Configure the API URL:** `flutter run --flavor development --dart-define=API_BASE_URL=http://<lan-ip>:8000/api/v1`
   (or the helper script that fills the LAN IP automatically).
6. **Launch & verify** login/register/health calls from `app/`.

> `localhost` works only for emulators (which loop back to the host). Physical devices must use
> the LAN IP. Emulators may use `http://10.0.2.2:8000/api/v1` (Android emulator host alias) —
> still via `--dart-define`, never hardcoded.

## 4. What NOT to do

- ❌ Commit `http://localhost:8000` or `http://127.0.0.1:8000` as the app default.
- ❌ Bake the API URL into compiled source (no `const` default).
- ❌ Weave environment-specific settings into one monolithic settings file.
- ❌ Use `.env` at Flutter **runtime** — Dart has no runtime env; build-time `--dart-define`
  is the mechanism (Flutter standard practice).

## 5. Landing points for follow-up tasks

- Backend env wiring + settings split → **T-09** (Django project/infra, DevOps).
- Flutter config/flavors implementation → **T-10/T-15** (Frontend).
- Staging/prod domains, secrets, Docker compose env separation → **T-11 / T-34** (DevOps).
- The `docs/adr/*` records capture the "why" (see decision record `0002-environment-mechanism`).