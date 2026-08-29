# Auth Strategy

Applies to: **SIW-6 §3 (backend auth), §5 (user account system), SIW-7 (T-07 API contract v1), SIW-8 (T-06 Flutter architecture)**

Status: **Approved baseline** — implementation tasks (T-09/T-13, T-10/T-15) must build to this spec.

## 1. Decision summary

- **Mechanism:** stateless JWT **access** + **refresh** token pair issued by Django REST Framework via
  `djangorestframework-simplejwt` (chosen in the backend decision record, `docs/adr/0001-...`).
- **Transport:** `Authorization: Bearer <access>` header for every authenticated API call.
  No cookies. No tokens in URLs, bodies, or logs.
- **Lifetimes:** access `15 min`, refresh `30 days` (both configurable via Django settings).
- **Refresh behaviour:** **rotating refresh tokens** — every `/auth/refresh` returns a fresh
  access token **and** a new refresh token; the used refresh token is blacklisted.
- **Session persistence:** refresh token stored securely on-device
  (`flutter_secure_storage`) so the user stays logged in across app restarts.
- **Single-flight refresh:** the Flutter API client performs at most **one** refresh at a time;
  concurrent `401` responses share that single refresh and replay their original requests once.

## 2. Token lifecycle

```
┌────────────┐   POST /api/v1/auth/register | login   ┌──────────────┐
│            │ ──────────────────────────────────────▶ │  Auth API    │
│   Flutter  │                                        │  (Django)     │
│    app     │ ◀────────────────────────────── 200    └──────┬───────┘
└────────────┘      { access, refresh, user }                │
                                                             ▼
                                              ┌──────────────────────┐
                                              │ /auth/refresh (POST)  │
                                              │ rotate + blacklist old│
                                              └──────────────────────┘
```

### 2.1 Registration (`POST /api/v1/auth/register`)

1. Client validates: name, email, password, confirm-password match, terms accepted.
2. Client submits `{ name, email, password }`.
3. Backend:
   - normalizes + validates email (unique, format) and password strength
     (Django `AUTH_PASSWORD_VALIDATORS`);
   - hashes password (Django default hasher; Argon2 recommended in production);
   - creates inactive-until-verified account if email verification is enabled, otherwise active;
   - creates the `User` + empty `Profile` stub (profile completion happens in onboarding).
4. Response `201` returns `{ access, refresh, user }` (auto-login after registration) so the
   client can skip a separate login round-trip. If email verification is on, returns
   `{ message }` and the client shows a "check your email" screen.

### 2.2 Login (`POST /api/v1/auth/login`)

- Request `{ email, password }`.
- On success → `{ access, refresh, user, expires_in }`.
- On failure → `401` with a generic `"invalid_credentials"` error (do not reveal whether the
  email exists). Apply rate limiting per IP/email (see §5).
- Store both tokens in secure storage, then open the authenticated home.

### 2.3 Session restore on app start (persistence across restarts)

1. App boots → read stored refresh token from secure storage.
2. If present, immediately attempt `POST /auth/refresh`:
   - **success** → fresh access token cached in memory, user session restored;
   - **`401`/network failure** → clear stored tokens, route to login.
3. If no stored token → route to login.
4. Never block the splash screen on network longer than a short timeout; fall back to login if
   the refresh cannot be confirmed.

### 2.4 API calls with refresh-on-401 (single-flight discipline)

The central `ApiClient` implements **one outstanding refresh** at a time:

1. Every request attaches `Authorization: Bearer <access-token>` if a token exists.
2. On a `401` response:
   - if the failing call is itself `/auth/refresh` or `/auth/login` → **do not** re-refresh
     (prevents loops); propagate the error;
   - otherwise, enqueue the request on a shared in-flight refresh future — if a refresh is
     already running, wait on it instead of starting a second one;
   - start the refresh (see 2.3), then **replay the original request exactly once** with the new
     access token;
   - if the replayed request still returns `401` → force logout locally and navigate to login.
3. Force logout: revoke the stored refresh token via `POST /auth/logout`, clear secure storage,
   clear in-memory state, navigate to the auth flow.

### 2.5 Logout (`POST /api/v1/auth/logout`)

- Request includes the refresh token (or its `jti`) to revoke.
- Backend blacklists the refresh token (and, for full logout, rotates/blacklists all outstanding
  refresh tokens for the user).
- Client clears secure storage and in-memory tokens **regardless** of the network response
  (local logout must always succeed).

### 2.6 Password management

| Flow                    | Endpoint                | Notes                                                            |
| ----------------------- | ----------------------- | ---------------------------------------------------------------- |
| Forgot password         | `POST /auth/forgot-password` | send reset token/email link; generic response (no account enum)  |
| Reset password          | `POST /auth/reset-password`  | sets new password, revokes all refresh tokens for the user       |
| Change password         | `POST /auth/change-password` | requires current password; revokes all refresh tokens except current session |

All three rotate/blacklist existing refresh tokens so old sessions die when the password changes.

### 2.7 Current user (`GET /api/v1/auth/me` / `/api/v1/users/me`)

- Returns the authenticated user's public profile. Requires a valid access token.

> Endpoint names/statuses are the **contract surface**; the exact request/response schemas are
> owned by T-07 (`docs/api-contract-v1.yaml`). This document defines policy and lifecycle, not
> wire shapes.

## 3. Token design (backend)

### 3.1 Access token claims

```json
{
  "token_type": "access",
  "exp": 1699000000,
  "iat": 1698999100,
  "jti": "uuid",
  "user_id": "<uuid>"
}
```

- `user_id` (UUID PK), `exp` (15 min), `jti` (unique id used for revocation/audit).
- Avoid embedding PII or roles in claims; load permission-relevant state from DB per request.

### 3.2 Refresh token claims

```json
{
  "token_type": "refresh",
  "exp": 1699000000 + 30d,
  "iat": ...,
  "jti": "uuid",
  "user_id": "<uuid>",
  "session_id": "<uuid>"
}
```

- Long `exp` (30 days), carries a `session_id` so a user's sibling sessions can be revoked
  independently (e.g. "log out all other devices").

### 3.3 Rotation & blacklist (simplejwt settings)

```python
SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=15),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=30),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
    "UPDATE_LAST_LOGIN": True,
    "AUTH_HEADER_TYPES": ("Bearer",),
    "AUTH_TOKEN_CLASSES": ("rest_framework_simplejwt.tokens.AccessToken",),
}
```

- `ROTATE_REFRESH_TOKENS = True` + `BLACKLIST_AFTER_ROTATION = True`:
  each refresh mints a new refresh token and blacklists the used one, limiting refresh token
  replay window to one use.
- Enable `rest_framework_simplejwt.token_blacklist` app in `INSTALLED_APPS` and run its migration.
- Server-side revocations (logout, password change) delete or blacklist the stored refresh `jti`.

### 3.4 Client storage (Flutter)

- **`flutter_secure_storage`** — Android Keystore-backed + iOS Keychain. Never plaintext
  `SharedPreferences`/`NSUserDefaults`.
- Keys: `auth.access_token`, `auth.refresh_token`, `auth.user_id` (or a single encrypted
  session bag).
- The in-memory copy held by the state layer is short-lived and cleared on logout/refresh failure.

## 4. Authentication & permission enforcement (DRF)

- Global default authentication: `rest_framework_simplejwt.authentication.JWTAuthentication`.
- Permission classes: `IsAuthenticated` on all `/api/v1/**` views unless explicitly public
  (register, login, refresh, forgot/reset password, public exercise/media listing, health).
- User lookup derived from `request.user` (set from the token), never from client-supplied IDs.
- Sensitive writes re-verify ownership (e.g. an exercise log must belong to the authenticated
  user).
- Django admin keeps its own session auth (unaffected by API tokens).

## 5. Security notes

| Concern                  | Control                                                                      |
| ------------------------ | ---------------------------------------------------------------------------- |
| Token theft              | Short access TTL (15 min), rotating refresh, per-device `session_id`          |
| Refresh replay           | One-time use refresh via rotation + blacklist                                 |
| Stored XSS / leakage     | Tokens only in secure storage / memory; never log or persist tokens           |
| Transport                | HTTPS on staging+prod. Dev LAN uses `http://<lan-ip>` only — flagged in docs   |
| CSRF                     | N/A for Bearer-header auth; CSRF still enforced for Django admin/session      |
| Brute force              | Rate limit `/auth/login`, `/auth/register`, reset endpoints (per IP + email)  |
| Account enumeration      | Generic responses for invalid credentials / nonexistent email                 |
| Password storage         | Django hashers (PBKDF2 default; Argon2 in prod), never plaintext              |
| Password strength        | `AUTH_PASSWORD_VALIDATORS` (length, not-common, not-email)                    |
| Session revocation       | Logout + password change revoke refresh tokens                                |
| Logs                      | Redact Authorization headers anywhere (Django/nginx request logging)          |
| Dependency supply chain  | `pip-audit` in CI; keep DRF + simplejwt patched (Dependabot)                  |
| Secrets                   | Django `SECRET_KEY` per environment via env vars, never in repo                |

Non-goals for MVP: MFA, SSO/OIDC, hardware keys, subscription-gated auth. These are future
additions layered on the same JWT foundation.

## 6. Open items / future work

- Email verification decision (skip for MVP; SMS/email OTP later).
- Automated auth tests (account registration matrix, refresh rotation, replay, logout
  revocation, permission checks) → owned by T-09/T-13 backend implementation tasks.
- E2E auth smoke test `register → login → refresh → logout` → QA.