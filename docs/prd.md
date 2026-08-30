# Product Requirements Document — AI Gym Assistant / Personal Training App

**Project:** AI Gym Assistant / Personal Training Application
**Product:** Internal codename **AIGym** (final name TBD in branding pass)
**Document owner:** Product Manager (siwar_corp)
**Status:** Draft v0.1 — approved for build baseline on acceptance of this PRD
**Source authority:** [SIW-6 — PROJECT MASTER INSTRUCTION — AI GYM ASSISTANT](/SIW/issues/SIW-6) sections §1–§39
**Related research:** T-01 Competitive research & feature inventory ([SIW-7](/SIW/issues/SIW-7)), T-02 Personas / UX / IA ([SIW-8](/SIW/issues/SIW-8))
**Repository:** `tester_github_starter12395847`

---

## 1. Document Purpose

This is the **single authoritative Product Requirements Document** for the AI Gym
Assistant product. It consolidates the product definition from the master
instruction ([SIW-6](/SIW/issues/SIW-6)) and becomes the **acceptance basis for all
phases** of the program:

- Every capability section of the master spec (§5–§20) is expressed as testable
  functional requirements.
- Non-functional requirements (§4, §24–§31) are expressed as measurable NFRs.
- Every requirement is traceable to a master-spec section and to a build-phase
  task family (T-13..T-36) (§11).
- Every feature area carries acceptance criteria and a Definition of Done (DoD)
  usable as an acceptance gate (§9, §10).

Changes to this document are controlled. After it is reviewed and approved, any
scope change must be made as a new revision and re-approved before build work
relies on it.

---

## 2. Product Overview

### 2.1 Product statement

AIGym is a production-quality **AI Gym Assistant / Personal Training** application
that lets a user:

1. Create an account and define a fitness profile and objectives.
2. Complete a guided onboarding flow.
3. Select a training plan.
4. Discover and inspect exercises and machines/equipment.
5. Follow workouts, record sets/reps/weight, and complete sessions.
6. Track progress, history, body metrics, and consistency over time.

The product is built as a **real product**, not a prototype. It must be usable on
physical devices (phones) against a backend running on a developer laptop over the
local network, and later against staging/production backends.

### 2.2 Target platforms

- Android (primary), via Flutter.
- iOS (primary), via Flutter.
- Web where practical, via Flutter.
- Backend: Django + Django REST Framework, containerized with Docker.

### 2.3 Core user journeys (high level)

1. **Register & onboard** — account creation → guided onboarding → profile.
2. **Plan selection** — choose objective (e.g. lose weight, build muscle) → choose a
   data-driven training plan.
3. **Day-to-day training** — open today's workout → follow exercises → record sets →
   finish → review results.
4. **Progress** — view history, charts, personal records, body metrics, consistency.

### 2.4 Guiding principles

- **No hardcoding:** training plans and exercise data must come from the backend,
  never be baked into the Flutter client.
- **Configurable environment:** the API base URL must be switchable between
  development / staging / production **without source-code changes** (§4).
- **Synchronized contract:** the Flutter team builds against a documented API
  contract; backend and frontend must not invent incompatible interfaces (§21).
- **Evidence-backed delivery:** every feature ships with tests, documentation, and
  evidence (§32).
- **Extensibility:** the architecture must allow later additions (AI coaching,
  subscriptions, wearables, notifications, analytics, personalization) without
  rework (§3).

---

## 3. Goals & Success Metrics

### 3.1 Product goals (must hold for MVP)

- G1 — A new user can go from "installed app" to "first completed workout" in
  under 15 minutes on a supported device.
- G2 — All core training data (plans, exercises, history, progress) round-trips
  through the documented REST API; no core data lives only on-device.
- G3 — The app runs against dev / staging / prod via flavor configuration with no
  code edits.
- G4 — A developer can bring the backend up with documented container commands and
  a physical device can talk to it over the local network.

### 3.2 Success metrics (instrumented after MVP)

- M1 — Onboarding completion rate ≥ 80% (started → completed).
- M2 — % of signed-up users who complete ≥ 3 workouts in their first 14 days.
- M3 — Workout completion rate (opened → completed) ≥ 90%.
- M4 — Weekly retention: ≥ 40% of active users train in a given week.
- M5 — API error rate < 1% on core endpoints; p95 API latency < 400 ms (LAN).

Metrics are aspirational for MVP and are used by later personalization/analytics
phases; MVP ships the telemetry plumbing where cheap, not the analytics product.

---

## 4. Personas

> **Status:** Incorporated. The authoritative personas, UX flows, and information
> architecture are delivered by T-02 ([SIW-8](/SIW/issues/SIW-8)) in
> `docs/personas.md`, `docs/ux-flows.md`, and `docs/information-architecture.md`.
> This section summarizes the five personas for scope/priority purposes; the full
> persona cards (snapshots, friction points, design implications) live in those
> files and are the binding UX reference.

The T-02 research defines **five personas**, each mapped to the training-objective
categories of [SIW-6 §6](/SIW/issues/SIW-6):

| # | Persona | Primary objective(s) | Experience | Core value |
|---|---------|----------------------|------------|------------|
| 1 | Dana "Determined" | Lose weight, improve fitness & endurance | Beginner | Short guided workouts, no guesswork, gentle consistency loop |
| 2 | Ben "Builder" | Build muscle, body composition | Intermediate | Progressive overload, previous-session memory, rest timing |
| 3 | Sam "Strength" | Gain strength | Intermediate–Advanced | PR tracking, strict progression, barbell alternatives |
| 4 | Fatima "Fit For Life" | General health, improve endurance | Beginner–Intermediate | Home/outdoor plans, duration-based sets, streaks |
| 5 | Maya "Maintain" | Maintain, general health | Intermediate | 15-minute scans, low data entry, flexible rescheduling |

Personas drive MVP prioritization:

- **Dana and Fatima** define the must-have guided flows: onboarding
  ([§6](/SIW/issues/SIW-6)), today-first dashboard
  ([§15](/SIW/issues/SIW-6)), machine/exercise clarity
  ([§9](/SIW/issues/SIW-6)), and equipment-aware substitution
  ([§16](/SIW/issues/SIW-6)).
- **Ben** drives set-tracking depth ([§11](/SIW/issues/SIW-6)): previous-session
  memory, ~2 taps per set, rest timer, warm-up/working/drop sets.
- **Sam** drives PR tracking, strict progression rules, and barbell-pattern
  substitution ([§12](/SIW/issues/SIW-6), [§16](/SIW/issues/SIW-6)).
- **Maya** drives batch completion, reschedule-without-guilt, and glanceable
  calendar/history ([§13](/SIW/issues/SIW-6), [§14](/SIW/issues/SIW-6),
  [§17](/SIW/issues/SIW-6)).

Every objective category of [SIW-6 §6](/SIW/issues/SIW-6) is covered by at least one
persona; the onboarding flow records one `Goal` per user and drives plan
recommendations from it.

---

## 5. Competitive Context

> **Status:** Incorporated. Competitive research and feature inventory are delivered
> by T-01 ([SIW-7](/SIW/issues/SIW-7)) in `docs/competitive-research.md` and
> `docs/feature-inventory.md`. Cited here are only the strategic takeaways that shape
> product decisions; no competitor branding or copyrighted content is reproduced.

### 5.1 Market landscape (2026)

The gym-app market splits into four archetypes:

1. **Minimalist loggers** — logging speed is the sole product; progressive-overload
   data is the value.
2. **Freemium social/gamified loggers** — generous free tiers, streaks/XP, social
   accountability; compete on retention mechanics.
3. **Adaptive/"AI" generators** — program generation in advance, algorithmic
   progression; compete on "open app → workout appears".
4. **Coaching platforms** — human/algorithmic coaching and accountability.

### 5.2 Takeaways that shape the PRD

- **Logging speed is the #1 differentiator.** Every set entry must be fast, with
  pre-filled last-session weight/reps, a numeric keypad, and a rest timer. The PRD
  requires ~2 taps per set (see FR-WO-06, AC-7).
- **Free tiers are the battleground; analytics are paywalled-but-expected.**
  MVP ships generous core tracking; premium analytics (advanced charts, e1RM,
  heatmaps) are future scope.
- **Plans/exercise content must be backend-driven.** No hardcoded plans or exercise
  data in the Flutter client — matches SIW-6 §7/§8 mandates.
- **"AI"/adaptive generation is future differentiation**, not MVP (per
  SIW-6 §2 extensibility requirement).
- **Retention mechanics matter**: streaks, consistency, completion feedback, and
  habit loops (targets the 90-day churn problem) — reflected in FR-PR/FR-CA/FR-DA.

The MVP feature scope (§6) is derived from the master instruction's §1, §10–§17
combined with the T-01 feature inventory: onboarding, exercise discovery, workout
experience, progress tracking, plans, dashboard, and retention mechanics — without
copying any competitor's branding, proprietary content, or copyrighted assets.

---

## 6. Feature Scope

### 6.1 MVP scope (in) — must-ship for release

| Area | MVP ships |
|---|---|
| Accounts | Register (name/email/password/confirm/terms), login, logout, session persistence, token refresh, forgot/reset/change password |
| Profile | Name, DOB, gender, height, weight, fitness level, experience, frequency, available equipment, preferred location |
| Onboarding | Guided: profile basics → main objective → preferences (days, duration, time, gym/home/outdoor, equipment, exercises to avoid) → experience → limitations |
| Exercises | Browse, search, filter (muscle/equipment/difficulty/type), detail (instructions, image, muscle info, equipment, guidance), machine/equipment info for machine exercises |
| Plans | Data-driven plan list + detail (name, description, objective, difficulty, duration, schedule, exercises/sets/reps/rest), plan selection |
| Workout | Today's workout, exercise sequence, instructions, prescribed sets/reps, record sets (weight/reps/rest), previous performance, complete workout, results review |
| Set tracking | Weight, reps, sets, completed, warm-up/working/drop sets, rest periods, notes |
| Progress | Body weight, measurements, completed workouts, frequency, exercise performance, PRs, volume, consistency, basic charts |
| History | Completed workout list + detail (date, duration, exercises, sets, reps, weights, volume, notes) |
| Calendar | Planned/completed/missed/upcoming workouts, consistency visible |
| Dashboard | Today's workout, next workout, goal, weekly progress, recent activity, metrics, streak, quick access to library |
| Substitution | Replace exercise with compatible alternative (muscle, movement, equipment, difficulty, user equipment) |
| Customization | Replace exercises, adjust weight, add sets, modify reps, notes, skip exercise, reschedule workouts (within plan logic) |
| Admin | Django admin for users, exercises, images, equipment, muscles, plans, workouts, goals, content, config |
| API | Versioned `/api/v1/` covering the above, OpenAPI docs |
| Environments | Dev/staging/prod API base URL via flavors, no code edits |
| Auth back-end | DRF-based authentication (token or JWT) + permissions |

### 6.2 Future scope (deferred, architecture must support)

- AI coaching / personalized recommendations (assistant features).
- Subscriptions / payments / plan tiers.
- Wearable integrations and heart-rate/sensor data.
- Notifications (reminders, missed workout, milestone, consistency) — backend and
  frontend are *designed* so notifications can be added (§18) but notification
  **delivery** is future.
- Advanced analytics and personalization.
- Social / community features.
- Video workout content and richer media.
- Advanced programming (periodization, deloads, auto-regulation) beyond MVP.

### 6.3 Explicitly out of scope

See §8 for the full out-of-scope list.

---

## 7. Functional Requirements

Requirement IDs are stable and used in the traceability matrix (§11). Each FR links
to the master-spec section it operationalizes (§5–§20).

### 7.1 User account system (SIW-6 §5; FR-AU)

| ID | Requirement |
|---|---|
| FR-AU-01 | Provide account registration with name, email, password, password confirmation, and required terms acceptance. Server-side validation; duplicate-email rejection. |
| FR-AU-02 | Provide login with email + password; return a credential that keeps the user authenticated across application restarts and allows refresh. |
| FR-AU-03 | Provide logout that invalidates the client credential server-side (where supported) and clears local auth state. |
| FR-AU-04 | Provide password reset via email (forgot password) and change-password while authenticated. |
| FR-AU-05 | Provide profile management: name, profile picture, DOB/age, gender, height, weight, fitness level, training experience, training frequency, available equipment, preferred training location; only collect data the product uses. |
| FR-AU-06 | Enforce authorization: users can read/write only their own profile, goals, sessions, history (admin excepted). |
| FR-AU-07 | Preserve authentication state across app restarts; refresh/rotate tokens where required. |

### 7.2 Onboarding (SIW-6 §6; FR-OB)

| ID | Requirement |
|---|---|
| FR-OB-01 | After registration, guide the user through onboarding steps: basic profile (age, height, weight, experience). |
| FR-OB-02 | Capture main objective: lose weight / build muscle / gain strength / improve fitness / improve endurance / improve body composition / general health / maintain fitness. |
| FR-OB-03 | Capture training preferences: days per week, preferred workout duration, preferred time (where useful), gym/home/outdoor, available equipment, preferred exercises, exercises to avoid. |
| FR-OB-04 | Capture experience level: beginner / intermediate / advanced. |
| FR-OB-05 | Allow identifying exercises/movements the user cannot perform (limitations) without making medical claims. |
| FR-OB-06 | Persist onboarding answers to the backend and use them to personalize plans and exercise suggestions. |

### 7.3 Training plans (SIW-6 §7; FR-TP)

| ID | Requirement |
|---|---|
| FR-TP-01 | Support plans describing: name, description, objective, difficulty, duration, number of training days, workout schedule, exercises, sets, repetitions, duration, rest periods, progression rules, notes. |
| FR-TP-02 | Provide library plans to start: Full Body, Upper/Lower, Push/Pull/Legs, Strength, Hypertrophy, Weight Loss, Beginner, Home Training. |
| FR-TP-03 | Plans are data-driven from the backend; **no plan is hardcoded in Flutter**. |
| FR-TP-04 | Plan selection by user; selected plan drives the user's scheduled workouts. |

### 7.4 Exercise database (SIW-6 §8; FR-EX)

| ID | Requirement |
|---|---|
| FR-EX-01 | Each exercise supports: name, description, muscle groups, primary muscle, secondary muscles, equipment, difficulty, movement type, instructions, reps/sets/rest guidance, safety notes, video/media where available, image, alternatives. |
| FR-EX-02 | Users can browse exercises and open a detail view. |
| FR-EX-03 | Search exercises by name/keyword. |
| FR-EX-04 | Filter by muscle, equipment, difficulty, and training type. |
| FR-EX-05 | Detail view shows instructions, image/media, how to perform, and required equipment/machine. |
| FR-EX-06 | Exercise content is backend-managed so admins can change it without a Flutter release. |

### 7.5 Exercise machine / equipment information (SIW-6 §9; FR-MM)

| ID | Requirement |
|---|---|
| FR-MM-01 | For machine-based exercises provide: machine name, machine image, exercise image where appropriate, setup instructions, how to use the machine, movement instructions, common mistakes, target muscles, adjustment instructions. |
| FR-MM-02 | Media is appropriately licensed or created in-house; no copying of others' copyrighted assets. |

### 7.6 Workout experience (SIW-6 §10; FR-WO)

| ID | Requirement |
|---|---|
| FR-WO-01 | User can open today's planned workout and see the exercise list in order. |
| FR-WO-02 | Per exercise: view instructions and image/media, see prescribed sets/repetitions. |
| FR-WO-03 | Start an exercise, record performed set(s): weight, reps, duration where applicable. |
| FR-WO-04 | Rest between sets (rest timer); progress to the next exercise. |
| FR-WO-05 | Complete the workout and review the results. |
| FR-WO-06 | The workout UI minimizes unnecessary interaction during training (large targets, minimal taps). |

### 7.7 Set tracking (SIW-6 §11; FR-ST)

| ID | Requirement |
|---|---|
| FR-ST-01 | Track weight, repetitions, sets, and completed status. |
| FR-ST-02 | Support warm-up sets, working sets, drop sets, rest periods, and notes where appropriate. |
| FR-ST-03 | System remembers previous performance for an exercise and displays it (e.g. last workout `60kg × 10/9/8`) in the next session to drive consistency. |

### 7.8 Progress tracking (SIW-6 §12; FR-PR)

| ID | Requirement |
|---|---|
| FR-PR-01 | Track body weight, measurements, workout frequency, completed workouts, exercise performance, weights lifted, reps, personal records, training volume, consistency, progress over time. |
| FR-PR-02 | Provide charts/visualizations so users can see whether they are progressing. |

### 7.9 Workout history (SIW-6 §13; FR-HI)

| ID | Requirement |
|---|---|
| FR-HI-01 | List previous completed workouts. |
| FR-HI-02 | Per-workout detail: date, duration, exercises, sets, reps, weights, volume where applicable, notes, completion status. |
| FR-HI-03 | Users can open a historical workout and inspect performance. |

### 7.10 Calendar / training schedule (SIW-6 §14; FR-CA)

| ID | Requirement |
|---|---|
| FR-CA-01 | Provide a calendar/schedule showing planned, completed, missed, and upcoming workouts. |
| FR-CA-02 | Make consistency visible (e.g. adherence marking). |

### 7.11 Dashboard / home (SIW-6 §15; FR-DA)

| ID | Requirement |
|---|---|
| FR-DA-01 | Home dashboard shows: today's workout, next workout, current goal, weekly progress, recent activity, progress metrics, streak/consistency where appropriate, quick access to exercise library and training plan. |
| FR-DA-02 | Dashboard prioritizes actionable information over statistics. |

### 7.12 Exercise substitution (SIW-6 §16; FR-SU)

| ID | Requirement |
|---|---|
| FR-SU-01 | Allow the user to replace an exercise with an alternative (e.g. Barbell Squat → Leg Press → Hack Squat). |
| FR-SU-02 | Alternatives are chosen based on muscle group, movement pattern, equipment, difficulty, and the user's available equipment. |
| FR-SU-03 | The replacement must stay compatible with the workout (target muscles/goal preserved). |

### 7.13 Training customization (SIW-6 §17; FR-CU)

| ID | Requirement |
|---|---|
| FR-CU-01 | Users can: replace exercises, adjust weights, record additional sets, modify repetitions where allowed, add notes, skip exercises, reschedule workouts. |
| FR-CU-02 | Do not allow arbitrary modifications that break the training-plan logic. |

### 7.14 Notifications — design readiness (SIW-6 §18; FR-NT)

| ID | Requirement |
|---|---|
| FR-NT-01 | Backend and frontend are designed so notifications can be added later: notification data model/API surface and client scheduling hooks. |
| FR-NT-02 | Potential future notifications: workout reminder, missed workout, upcoming workout, progress milestone, plan completion, consistency reminder. |
| FR-NT-03 | First implementation focuses on essential functionality; no full notification subsystem in MVP. |

### 7.15 Admin / content management (SIW-6 §19; FR-AD)

| ID | Requirement |
|---|---|
| FR-AD-01 | Django admin interface for: users, exercises, exercise images, equipment, muscles, training plans, workouts, exercises within workouts, goals, content, application configuration. |
| FR-AD-02 | Admins can update exercise and training content without a Flutter code change. |

### 7.16 Data model (SIW-6 §20; FR-DM)

| ID | Requirement |
|---|---|
| FR-DM-01 | Relational data model covering at minimum the entities listed in §20 of the master spec (User, UserProfile, Goal, TrainingPreference, Equipment, MuscleGroup, Exercise, ExerciseMedia, ExerciseAlternative, TrainingPlan, TrainingPlanDay, Workout, WorkoutExercise, WorkoutSet, WorkoutSession, WorkoutSessionExercise, ProgressMetric, BodyMeasurement, PersonalRecord, WorkoutNote, Notification). |
| FR-DM-02 | Avoid unnecessary models; use appropriate relationships, indexes, constraints, and validation. |
| FR-DM-03 | Determine the final model in the backend-design task (Phase 1), driven by these requirements. |

### 7.17 API (SIW-6 §21; FR-API)

| ID | Requirement |
|---|---|
| FR-API-01 | Versioned API under `/api/v1/`. |
| FR-API-02 | Endpoints cover: authentication, user profile, onboarding, goals, exercises, equipment, training plans, workouts, workout sessions, sets, progress, history, dashboard, notifications, administration. |
| FR-API-03 | API documented via OpenAPI/Swagger or equivalent; Flutter team develops against the documented contract. |

### 7.18 Flutter architecture (SIW-6 §22; FR-FL)

| ID | Requirement |
|---|---|
| FR-FL-01 | Flutter codebase cleanly separates UI, state management, networking, models, authentication, configuration, local storage, business logic. |
| FR-FL-02 | Provides centralized API client, centralized auth handling, environment configuration, error handling, loading states, empty states, offline-aware behavior where useful, reusable components, responsive layouts. |
| FR-FL-03 | Not one large mixed-responsibility codebase. |

---

## 8. Out-of-Scope (MVP)

The following are explicitly **out of scope** for MVP; they must not be treated as
MVP bugs and must not block release:

1. AI coaching / generative assistant features (architecture-ready only).
2. Subscriptions, payments, and paid plan tiers.
3. Wearable / fitness-tracker / heart-rate integrations.
4. Delivery of push/local notifications (design-readiness only — see FR-NT).
5. Social/community/feed features, friend challenges.
6. Advanced analytics product, reporting for coaches.
7. Video workout programming (all-video workouts) and premium media libraries.
8. Advanced periodization / auto-regulation / deload algorithms.
9. Multi-language (i18n) and accessibility-at-scale beyond Flutter defaults.
10. White-labeling / multi-tenant B2B configuration.
11. Web-first marketing site and full web parity (web is "where practical").
12. In-app purchasing; App Store/Play billing integrations.
13. Medical, nutrition, or meal-planning features; injury rehabilitation programs
    (the app must not make medical claims — see §7.2 FR-OB-05).
14. Equipment booking, gym-location search, or gym directory.

**Change control:** any item pulled into MVP requires a PRD revision + approval
before build tasks depend on it.

---

## 9. Acceptance Criteria per Feature Area

Acceptance criteria (AC) are the testable gates per feature area. A feature area
passes when **all** its ACs pass on the target environment (dev flavor) with backend
tests, Flutter tests, and, where noted, an end-to-end flow.

| Area | ID | Acceptance criteria |
|---|---|---|
| Accounts & auth | AC-1 | Register with name/email/password/confirm/terms → account exists server-side; invalid email, short password, mismatched confirm, duplicate email each rejected with a clear error. Login respects credentials, wrong password rejected. Logout clears session. Auth survives app restart (refresh token flow). Forgot/reset/change password work end-to-end. |
| Profile | AC-2 | User can view/edit name, DOB/age, gender, height, weight, fitness level, experience, frequency, equipment, location; persisted to backend; only own profile editable by non-admin. |
| Onboarding | AC-3 | Complete onboarding in order: basics → objective (8 options) → preferences → experience → limitations; all answers persisted and reflected in recommended plans/experience. Skippable/back navigation does not corrupt data. No medical claims displayed. |
| Training plans | AC-4 | Plan library loads from backend (not hardcoded); plan detail shows all fields of FR-TP-01; at least the 8 starter plans exist in seed data; selecting a plan creates the user's schedule. |
| Exercise database | AC-5 | Browse/search/filter (muscle, equipment, difficulty, type) return correct, paginated results; detail shows instructions, image, muscles, equipment, guidance; content editable via admin without Flutter change. |
| Machine/equipment info | AC-6 | Machine exercises show name, image, setup, usage, movement, common mistakes, target muscles, adjustments; media is licensed/attributed appropriately. |
| Workout experience | AC-7 | Open today's workout → ordered exercise list → detail w/ instructions + prescribed sets → start/record sets → rest timer → complete → results review. Minimizes taps (e.g. ≥ most actions ≤ 2 taps). Works with flutter run on a physical device against LAN backend. |
| Set tracking | AC-8 | Weight, reps, sets, completed, warm-up/working/drop, rest, notes persisted; previous performance shown for the exercise from last session. |
| Progress | AC-9 | Body weight, measurements, frequency, completed count, exercise performance, PRs, volume, consistency computed from stored session data; at least one chart updates after a completed workout. |
| History | AC-10 | Completed workouts listed with date/duration/sets/reps/weights/volume/notes; detail matches recorded values. |
| Calendar | AC-11 | Planned/completed/missed/upcoming days render correctly; completing a workout marks the day completed; missed/past uncompleted days marked missed. |
| Dashboard | AC-12 | Shows today's workout, next workout, goal, weekly progress, recent activity, metrics, streak, quick links; actionable information prioritized. |
| Substitution | AC-13 | Substitute button offered where FR-SU-01; alternative respects muscle/movement/equipment/difficulty/user equipment; substitution persists in the workout. |
| Customization | AC-14 | Replace exercise, adjust weight, add set, modify reps, add note, skip, reschedule all work; edits that would break plan logic are blocked with explanation. |
| Notifications (readiness) | AC-15 | Notification model/API surface exists and is documented; no delivery required. |
| Admin | AC-16 | Django admin manages the entities of FR-AD-01; exercising admin content change (e.g. edit an exercise description or image) reflects in the app without a Flutter release. |
| API | AC-17 | `/api/v1/` endpoints per FR-API-02 exist, are versioned, documented via OpenAPI, and return consistent schemas; the Flutter client consumes only documented endpoints. |
| Environments/config | AC-18 | A single build supports dev / staging / prod API base URLs chosen by flavor at build/run time; `flutter run --flavor development` targets the dev URL; no `localhost`/`127.0.0.1` hardcoded as a permanent address. |
| Security | AC-19 | Auth tokens stored securely; password hashing server-side; TLS required on staging/prod; no secrets in the repository; permissions enforced per FR-AU-06; DRF permission/authentication used (not a custom insecure mechanism). |
| Performance | AC-20 | Core list/detail endpoints p95 ≤ 400 ms on LAN (dev) for reference datasets; app cold start acceptable on mid-range devices; scrolling lists (exercise library) jank-free on a mid-range device. |
| Testing | AC-21 | Backend unit/API/auth/permission/validation/plan & workout-logic tests pass; Flutter unit/widget tests + the §26 end-to-end flow (create account → onboard → select goal → select plan → workout → sets → complete → history → progress) pass. |
| Docker & local dev | AC-22 | `docker compose up` starts Django + (dev) DB with migrations + health check; documented dev loop (laptop IP → phone → register → auth → API requests) works (SIW-6 §24–§25). |
| CI/CD | AC-23 | GitHub Actions runs lint/static analysis → backend tests → Flutter tests → build validation on every PR; a successful pipeline produces artifacts (SIW-6 §27). |
| Android build | AC-24 | CI generates an Android release APK (AAB preferred) available from the run and/or release. |
| iOS build | AC-25 | iOS build/archive pipeline exists; TestFlight distribution supported where signing is available; dev/staging/prod clearly distinguished; secrets only in CI secrets (SIW-6 §29). |
| Docs | AC-26 | README + docs per §31 structure present; developer can start the backend and run the app following docs alone; PRD linked from README; docs kept in sync (doc-maintenance). |

---

## 10. Definition of Done (DoD) per Feature

A feature is **done** only when **all** of the following hold (SIW-6 §36):

| # | DoD gate |
|---|---|
| D-1 | Implementation is finished and matches the FR for that feature. |
| D-2 | Backend/API works and is tested (unit + API tests for the feature). |
| D-3 | Flutter integration works against the API contract. |
| D-4 | Feature's ACs (see §9) pass with recorded evidence. |
| D-5 | Tests for the feature pass in CI. |
| D-6 | Documentation for the feature/screens/API is updated. |
| D-7 | Evidence is captured (screenshots, API/test results) and attached to the task/PR (§32). |
| D-8 | Code is committed and a PR is opened for the feature. |
| D-9 | CI passes on the PR. |
| D-10 | No critical or high-severity issues remain open on the feature. |

**Release-level DoD (applies once at RC, SIW-6 §36/§12):** Android build succeeds,
iOS build succeeds where signing infra exists, E2E test passes, documentation is
complete, release artifacts exist, known issues are documented, and the release is
reproducible.

---

## 11. Requirement Traceability

Each requirement maps to its master-spec section and to the build-phase task family
that implements/validates it. Task families T-13..T-36 are created from Phase 1
onward per §34 task-creation rules; the mapping below is the contract those tasks
must cover. *Task-family assignments are owned by the CEO/PM and may be split into
individual tasks when the build tasks are created; any split must retain this
traceability.*

Legend — task families by phase (24 families, T-13..T-36):

| Family | Phase | Theme |
|---|---|---|
| T-13 | 1 Architecture | Repository structure + monorepo scaffold |
| T-14 | 1 Architecture | Backend & Flutter architecture + DB design + API contract + env/auth/CI strategy |
| T-15 | 2 Infrastructure | Django project + Docker + DB + environment config |
| T-16 | 2 Infrastructure | Flutter project + dev/staging/prod configuration |
| T-17 | 3 Auth & Onboarding | Backend auth + profile + onboarding APIs |
| T-18 | 3 Auth & Onboarding | Flutter auth + onboarding UX |
| T-19 | 4 Exercise System | Exercise/muscle/equipment/media/alternative backend + admin |
| T-20 | 4 Exercise System | Flutter exercise discovery (search/filter/detail) |
| T-21 | 5 Training Plans | Plan backend (models/API/seed data) |
| T-22 | 5 Training Plans | Flutter plan selection + scheduling |
| T-23 | 6 Workout Engine | Workout API + session/set persistence |
| T-24 | 6 Workout Engine | Flutter workout UI + set tracking + rest timer |
| T-25 | 7 History & Progress | History + progress/stats/prs backend |
| T-26 | 7 History & Progress | Flutter history + progress charts + dashboard |
| T-27 | 8 UX / Polish | Visual design, states, responsiveness, accessibility |
| T-28 | 8 UX / Polish | Performance + error/empty/loading polish + device QA |
| T-29 | 9 Testing | Backend test expansion + plan/workout logic tests |
| T-30 | 9 Testing | Flutter widget/integration tests + E2E flow |
| T-31 | 10 CI/CD | GitHub Actions pipeline + security checks |
| T-32 | 10 CI/CD | Android build (APK/AAB) + iOS build/TestFlight |
| T-33 | 11 Documentation | README + all docs/ deliverables |
| T-34 | 11 Documentation | Release artifacts + reproducible release process |
| T-35 | 12 Release Candidate | Production-readiness review + acceptance pass |
| T-36 | 12 Release Candidate | Final acceptance + evidence consolidation |

### Traceability matrix

| Req ID | Requirement (short) | Master-spec § | Task family |
|---|---|---|---|
| FR-AU-01 | Registration | §5 | T-17 (BE), T-18 (FE) |
| FR-AU-02 | Login + persistent auth | §5 | T-17 (BE), T-18 (FE) |
| FR-AU-03 | Logout | §5 | T-17 (BE), T-18 (FE) |
| FR-AU-04 | Forgot/reset/change password | §5 | T-17 (BE), T-18 (FE) |
| FR-AU-05 | Profile management | §5 | T-17 (BE), T-18 (FE) |
| FR-AU-06 | Authorization (own data) | §5 | T-17 (BE), T-18 (FE) |
| FR-AU-07 | Auth persistence + refresh | §5 | T-17 (BE), T-18 (FE) |
| FR-OB-01..06 | Onboarding flow + persistence + personalization | §6 | T-17 (BE), T-18 (FE) |
| FR-TP-01..04 | Data-driven training plans + selection | §7 | T-21 (BE), T-22 (FE) |
| FR-EX-01..06 | Exercise database, search, filter, detail, admin-managed | §8 | T-19 (BE), T-20 (FE) |
| FR-MM-01..02 | Machine/equipment info + licensed media | §9 | T-19 (BE), T-20 (FE) |
| FR-WO-01..06 | Workout experience | §10 | T-23 (BE), T-24 (FE) |
| FR-ST-01..03 | Set tracking + previous performance | §11 | T-23 (BE), T-24 (FE) |
| FR-PR-01..02 | Progress tracking + charts | §12 | T-25 (BE), T-26 (FE) |
| FR-HI-01..03 | Workout history | §13 | T-25 (BE), T-26 (FE) |
| FR-CA-01..02 | Calendar/schedule | §14 | T-26 (FE) |
| FR-DA-01..02 | Dashboard | §15 | T-26 (FE) |
| FR-SU-01..03 | Exercise substitution | §16 | T-19 (BE), T-24 (FE) |
| FR-CU-01..02 | Training customization | §17 | T-23 (BE), T-24 (FE) |
| FR-NT-01..03 | Notifications design-readiness | §18 | T-14 (arch), T-19 (BE) |
| FR-AD-01..02 | Admin/content management | §19 | T-19 (BE) |
| FR-DM-01..03 | Data model | §20 | T-13/T-14 (design), T-19 (BE) |
| FR-API-01..03 | Versioned, documented API | §21 | T-14 (contract), T-17/T-19/T-21/T-23/T-25 (BE) |
| FR-FL-01..03 | Flutter architecture | §22 | T-13/T-14 (arch), T-16 (scaffold) |
| NFR-ENV | Configurable API base URL via flavors | §4 | T-16 (FE config) |
| NFR-PERF | Performance budgets | §12/§23 | T-27/T-28 |
| NFR-SEC | Security (DRF auth, TLS, no secrets) | §3/§5/§21 | T-14, T-17, T-31 |
| NFR-DB | PostgreSQL default | §3 | T-14, T-15 |
| NFR-DOCKER | Docker backend + documented dev loop | §24/§25 | T-15 |
| NFR-TEST | Backend/Flutter/E2E testing | §26 | T-29, T-30 |
| NFR-CI | CI/CD pipeline | §27 | T-31 |
| NFR-BUILD | Android APK/AAB + iOS build/TestFlight | §28/§29 | T-32 |
| NFR-REL | Versioned reproducible releases | §30 | T-34 |
| NFR-DOCS | Comprehensive docs + PRD link from README | §31 | T-33 |
| NFR-DOD | Definition-of-Done gates enforced | §36 | T-35, T-36 |

> **Note on requirements baseline:** FR/NFR IDs above are the stable baseline.
> When build tasks are created (T-13..T-36), each task's description must cite the
> requirement IDs it implements so acceptance can be verified back to this PRD.

---

## 12. Non-Functional Requirements

Measurement and enforcement detail for the NFRs referenced in §11.

### NFR-ENV — Configurable API base URL (SIW-6 §4) — **priority: blocker**

- **NFR-ENV-01** The API base URL must be configurable without modifying application
  source code.
- **NFR-ENV-02** At least three flavors/configs: **development** (e.g.
  `http://192.168.1.XXX:8000/api`), **staging** (e.g. `https://staging-api.example.com/api`),
  **production** (e.g. `https://api.example.com/api`).
- **NFR-ENV-03** Configuration changeable through the app's build/run configuration
  (Flutter flavors / `--dart-define` / environment mechanism), not by editing Dart
  source.
- **NFR-ENV-04** `localhost`/`127.0.0.1` must **never** be the permanent/hardcoded API
  address; docs must warn that on a physical phone `localhost` is the phone itself.
- **NFR-ENV-05** `flutter run --flavor development` (or documented equivalent) must
  run the app against the development API.

### NFR-PERF — Performance

- Core list/detail API p95 ≤ 400 ms on LAN (dev reference dataset).
- Exercise library scroll must be smooth on a mid-range device (no jank).
- Pagination on list endpoints (exercises, history) to bound payload size.

### NFR-SEC — Security

- Passwords hashed server-side with a strong algorithm (e.g. PBKDF2/argon in DRF
  defaults); never stored in plaintext.
- DRF pluggable authentication + permissions are the foundation (FR-AU-06); no
  custom insecure auth.
- Staging/prod require HTTPS; insecure transport rejected.
- No secrets in the repository; API keys/signing credentials only in CI secrets
  (SIW-6 §28–29).
- Token storage on device uses secure storage.

### NFR-DB — Database

- PostgreSQL is the default relational database; another DB only with a documented
  justification (SIW-6 §3).

### NFR-DOCKER — Containerized backend

- Dockerfile + docker-compose (dev DB container), migration process, startup
  process, health check, documented startup command (SIW-6 §24).

### NFR-LAN — Local-network development

- Django listens on an interface reachable from the local network; documented
  steps: find laptop IP → start Docker → expose port 8000 → same network → configure
  dev API URL → launch app → verify connectivity → test auth/API (SIW-6 §25).

### NFR-TEST — Mandatory testing (SIW-6 §26)

- Backend: unit, API, auth, permissions, database, validation, workout-logic,
  plan-logic tests.
- Flutter: unit, widget, and integration tests where appropriate, covering the
  §26 list (registration, login, onboarding, plan selection, exercise browsing,
  exercise details, workout execution, set recording, completion, history,
  progress, logout).
- At least one complete E2E flow (create account → onboarding → goal → plan →
  workout → sets → complete → history → progress).

### NFR-CI — CI/CD (SIW-6 §27)

- GitHub Actions on every PR: checkout → install deps → lint/static analysis →
  backend tests → Flutter tests → build validation → security checks → build
  artifacts.

### NFR-BUILD — Mobile builds (SIW-6 §28–29)

- CI produces an Android release **APK** (AAB preferred).
- iOS archive/build pipeline with TestFlight where signing is available;
  dev/staging/prod distinguished; credentials only in CI secrets.

### NFR-REL — Releases (SIW-6 §30)

- Versioned releases with changelog, Android artifact, iOS build info, backend
  version, DB migration info, doc changes, test status; reproducible.

### NFR-DOCS — Documentation (SIW-6 §31)

- README + `docs/` per §31 structure; PRD linked from README; docs review keeps
  them in sync.

---

## 13. Risks & Open Items

| # | Risk / open item | Impact | Mitigation |
|---|---|---|---|
| R-1 | T-01 research may shift MVP feature detail | Low–Med | §6.1 MVP frozen on PRD approval; research only refines non-functional detail of §5/§4 personas-context sections |
| R-2 | iOS signing infra unavailable in CI | Med | iOS build pipeline designed; distribution gated on availability (NFR-BUILD, AC-25) |
| R-3 | Physical-device dev requires LAN specifics | Med | Documented dev runbook (NFR-LAN); flavor config isolates environment |
| R-4 | Copyrighted media risk in exercise images | High | Only licensed/created media (FR-MM-02); review gate in T-19 |
| R-5 | Contract drift between backend & Flutter | High | OpenAPI contract frozen in T-14; Flutter builds against contract (FR-API-03) |

---

## 14. Sign-off / Change History

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-08-29 | PM (siwar_corp) | Initial consolidated PRD from master instruction §1–§39; serves as PRD draft awaiting T-01/T-02 research incorporation |

Approval: pending PRD review/approval before Phase-1 build tasks are created.