# Decision Record — AI Gym Assistant Backend

> **Task:** T-05 (SIW-11) · **Owner:** Backend Lead
> Status: **Accepted** · Companion docs: [data-model.md](data-model.md) · [backend-architecture.md](backend-architecture.md)

Three architecture decisions the backend team commits to and must not silently reverse (reversal requires a new ADR
coordinated with the CTO before any implementation).

---

## ADR-0001 — Use PostgreSQL as the production database

**Status:** Accepted · **Context:** SIW-6 §3 mandates "a relational database appropriate for production" and prefers
PostgreSQL; §20 demands a proper relational data model.

**Decision:** PostgreSQL 16 for all environments (dev, staging, prod). SQLite/Django defaults are never used past the
first scaffold smoke test.

**Why**
1. **Relational integrity is core to the product.** Training plans, workout/session/set hierarchies, M2M muscle/
   equipment matrices, PR and metric rows all demand enforced FKs, unique constraints, and check constraints — the
   model in [data-model.md](data-model.md) is designed around them.
2. **Concurrency + data safety.** ACID transactions matter for session completion (commit session + perform set +
   PR replace in one transaction); MySQL's weaker constraints and SQLite's single-writer modeling are non-starters.
3. **JSONB for structured-but-flexible data** — `AnalyticsEvent.properties`, notification payloads — without giving
   up relational tables for the core.
4. **Server-side search** (§8 search/filter): full-text `to_tsvector`/`GIN` + `pg_trgm` trigram typo-tolerant
   search on exercise names runs in the DB; no extra search engine (Elasticsearch → off-MVP complexity).
5. **Extensions & roadmap fit** — JSONB → JSONPath, later PostGIS (geo-based gym features), partitioning for
   analytics scale, all first-class.
6. **Ecosystem parity.** Django/DRF target Postgres first-class (including `topic/contrib.postgres`); Docker dev
   container matches prod, killing the classic "works on sqlite, breaks in prod" class of bugs.
7. **Managed-service maturity** — RDS/Cloud SQL/Crunchy etc. reduce ops burden when deployment lands.

**Consequences:** All migrations must use Postgres features (JSONB, GIN/trigram extensions); CI runs tests against a
Postgres test database, never in-memory SQLite.

---

## ADR-0002 — Use `djangorestframework-simplejwt` for authentication

**Status:** Accepted · **Context:** SIW-6 §3 "Authentication and authorization must be implemented properly. DRF
supports pluggable authentication and permissions and should be used as the foundation rather than inventing an
insecure custom mechanism."

**Decision:** JWT access/refresh via `djangorestframework-simplejwt`, mounted as DRF's `DEFAULT_AUTHENTICATION_CLASSES`;

**Why**
1. **DRF-native, battle-tested, maintained** — the de-facto standard for JWT in DRF; no hand-rolled crypto.
2. **Stateless access tokens** fit a mobile client hitting an API cluster; no per-request DB session lookup on reads.
3. **Refresh rotation + blacklist** (`ROTATE_REFRESH_TOKENS`, `token_blacklist`) delivers "refresh where required"
   (SIW-6 §5) with server-side revocation on logout — closing the classic stateless-JWT no-logout hole.
4. **Custom claims** can carry `email`/`role`/`sub` without extra lookups on hot endpoints.
5. **Clean escape hatch** — auth is a pluggable DRF class; swapping to `django-allauth`/OAuth2 later (future
   "social login") is a config change, not a rewrite, because permissions and viewsets are auth-agnostic.

**Considered & rejected:** session+cookie auth (stateless API-first mobile client, CORS-heavy, §7.3 cookies off);
DRF token auth (single token, no refresh/rotation/expiry flow); building custom JWT (forbidden by §3).

**Consequences:** Access token 30 min, refresh 30 days, rotate + blacklist on refresh (see
[backend-architecture.md](backend-architecture.md) §5). Flutter persists tokens securely and auto-refreshes on 401.

---

## ADR-0003 — Version the API by URL path (`/api/v1/`)

**Status:** Accepted · **Context:** SIW-6 §21 requires a versioned API ("Example: `/api/v1/`") consumed by Flutter;
§22 mandates the frontend develop against the documented contract.

**Decision:** Path-based versioning — all endpoints mounted under `/api/v1/`, schema under
`/api/v1/schema/`, future versions as `/api/v2/` alongside.

**Why**
1. **Explicit and client-visible.** The version is in the URL the Flutter team configures per flavor
   (`API_BASE_URL=.../api/v1`, SIW-6 §4). No header magic that a developer has to remember to set.
2. **Cache/CDN friendly.** Different versions are distinct URLs → proxies and caches never mix payload shapes.
3. **Backwards-compatible shipping.** Old `/api/v1/` keeps serving installed app versions while `/api/v2/` evolves —
   mobile apps can't be force-upgraded instantly; this is the de-facto standard split for mobile API teams.
4. **One OpenAPI view per version** via `drf-spectacular` `SCHEMA_PATH_PREFIX` — contract diffing between versions is
   trivial, so the Flutter team and QA always test against a pinned version.
5. **Spec-mandated.** SIW-6 §21 gives `/api/v1/` as the example; no reason to diverge.

**Considered & rejected:** header/`Accept`-based versioning (opaque to clients, breaks CDN/caching, harder to debug);
no versioning (guaranteed contract drift the moment the first breaking change lands, which §21 explicitly exists to
avoid).

**Consequences:** Every future breaking change rides `/api/v2/`; the CEO/CTO gates when old versions are deprecated.
`docs/api.md` (T-07) documents only the pinned version the Flutter app targets.

---

*These ADRs are binding for T-09..T-31 implementation. Challenge them only through the CTO.*