# Planning — T-09: Gym App Architecture (Django + Flutter)

**Status:** Draft  
**Branch:** `plan/t-09-gym-planning`  
**Task ref:** T-09 (continuation from T-01..T-08)  
**Created by:** Hermes agent (single-agent with delegation cap)  
**Stack:** Python Django (backend) + Flutter (frontend, multi-platform)

---

## 1. Product (from T-03 PRD — AI Gym Assistant / Personal Training)
- User creates fitness profile / objectives
- Guided onboarding flow
- Training-plan selection
- Exercise / equipment discovery
- Workout session tracking (sets/reps/weight)
- Progress / history / body metrics / consistency

---

## 2. Stack Decisions (your direction)

| Layer | Choice | Justification |
|---|---|---|
| **Backend** | Python Django 5.x + Django REST Framework + PostgreSQL | Maturity, ORM, auth, DRF for REST APIs; aligns with T-05/T-08 docs |
| **Frontend** | Flutter (Dart) 3.x | Single codebase for Web / iOS / Android (your spec); FVM for versions |
| **Web host** | Django + Whitenoise / Gunicorn + Nginx (or Render/Railway) | T-08 CI/CD references deployment |
| **Mobile** | Flutter build to App Store / Play Store / Web deploy | Flutter `flutter build web/appstore/ios` |
| **Auth** | Django REST auth (JWT via `djangorestframework-simplejwt`) + Flutter `http` client | T-08 auth strategy |
| **Database** | PostgreSQL 15+ (dev: SQLite optional) | T-05 backend / decision records |

---

## 3. Architecture (high-level)

```
┌─────────────────────────────────────────────┐
│         Flutter Client (Web / iOS / Android) │
│  Pages: Onboarding → Plan → Workout → Stats  │
│  State: Provider / Riverpod (recommended)    │
└──────────────┬──────────────────────────────┘
               │ REST / HTTPS
               ▼
┌─────────────────────────────────────────────┐
│  Django REST API  (DRF)                      │
│  Endpoints (T-07 API contract v1):          │
│  • POST /auth/login /register               │
│  • GET /plans /exercises /workouts          │
│  • POST /workouts /sessions /progress       │
│  • GET /stats /metrics                      │
└──────────────┬──────────────────────────────┘
               │ SQL / ORM
               ▼
┌─────────────────────────────────────────────┐
│  PostgreSQL  (users, plans, workouts,        │
│  exercises, metrics, progress)              │
└─────────────────────────────────────────────┘
```

---

## 4. Milestones / Build Order (T-13..T-36 mapping from PRD)

| Phase | Task | Deliverable | Status (this PR) |
|---|---|---|---|
| 0 — Planning | **T-09 (this)** | Plan doc, stack locks | ❌ Draft |
| 1 — Scaffold | T-04 + T-05 | Monorepo (`backend/`, `frontend/`), DB schema | ✅ Branched (T-04) |
| 2 — Auth/Env | T-08 | JWT, env vars, CI workflow, `.env` templates | ✅ Branched (T-08) |
| 3 — API Contract | T-07 | OpenAPI spec, DRF endpoints, fixtures | ✅ Branched (T-07) |
| 4 — PRD / UX | T-03 + T-02 | PRD approved, personas, wireframes | ✅ Branched |
| 5 — Feature Inventory | T-01 | Competitive analysis, feature list | ✅ Branched (T-01) |
| 6 — Scaffold Backend | T-13..T-16 | Django project, models, admin, serializers | ⏳ Next |
| 7 — Scaffold Flutter | T-17..T-20 | Flutter project, pages, navigation, theming | ⏳ Next |
| 8 — Integration | T-21..T-24 | API client (`dio` or `http`), auth flow, data sync | ⏳ Next |
| 9 — Workout / Stats | T-25..T-28 | Session tracking, progress charts, metrics | ⏳ Next |
| 10 — CI / Deploy | T-29..T-36 | Tests, lint, deploy to web + mobile stores | ⏳ Next |

---

## 5. Essential Notes (per your request)

- **Django backend:** Python, DRF, PostgreSQL, JWT auth (from T-08 auth docs).
- **Flutter frontend:** Dart, multi-platform (Web / iOS / Android). Use `flutter build` targets accordingly.
- **Planning framework:** This is single-agent (Hermes) with delegation cap of 1 level; sub-agents can be used for parallel backend / frontend work if needed, but coordination is manual via this doc.
- **Repo state:** Main is at `7c5502a` (Hello World). Feature branches (T-01..T-08) contain planning docs but are unmerged to `main`. This branch (`plan/t-09-gym-planning`) extends the series.

---

## 6. Next Actions (implementation start)

1. Merge / reconcile T-04 (monorepo scaffold) + T-08 (env/CI) to establish `backend/` + `frontend/` directories.
2. Lock Flutter version (`flutter_version`) and Django `requirements.txt`.
3. Create Django project + initial models (`UserProfile`, `Plan`, `Exercise`, `WorkoutSession`, `ProgressMetric`).
4. Create Flutter skeleton (`lib/pages/`, `lib/services/api/`) with `http` or `dio` client
5. Open follow-up PRs per phase (T-13, T-17, T-21, etc.).
