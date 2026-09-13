# Gym Planner Feature Research

_Research cycle date: 2026-09-13. Mode: D (Gap Audit) + B (Deep Competitive Research), filtered to only the highest-value candidates. Read-only — no application code was modified in producing this document._

## Implementation Status (updated 2026-09-13)

TASK-001, TASK-002, TASK-004, TASK-005, and TASK-006 below have been **implemented and validated** (64/64 backend tests pass, `flutter analyze` clean). TASK-003 (subscription billing) remains **not started** — it needs a business decision on payment provider (Stripe webhook vs. platform IAP) before implementation. See each task's entry in the Implementation Backlog for what shipped; a future research cycle should not re-recommend these five as gaps, and should treat TASK-003 as the one still-open "Now" item.

| Task | Status | Notes |
|---|---|---|
| TASK-001 Exercise substitution | ✅ Done | `GET /exercises/lookup/<uuid>/` + runner "Replace exercise" sheet |
| TASK-002 AI/Premium copy remediation | ✅ Done | `PreviewBadge` widget applied to Coach/Form Vault/3D Replay; dishonest Premium copy rewritten |
| TASK-003 Subscription billing | ⏸ Deferred | Needs a payment-provider decision first (out of scope for this pass) |
| TASK-004 RPE logging | ✅ Done | `ProgressMetric.rpe` (1–10), optional runner slider, `average_rpe` in summary |
| TASK-005 Session deep-linking | ✅ Done | `/session/:id` fetches via API when no in-memory session is available |
| TASK-006 Progress photos | ✅ Done | Private `ProgressPhoto` model/endpoint + Progress tab photo timeline |

## Executive Summary

Gym Planner (the training module of WELLAURA) has a genuinely solid **tracking core**: JWT auth, real CRUD workout plans with a weekly schedule, a rich exercise-library data model, a full workout runner with rest timers/set logging/offline queueing/PR detection, and a progress dashboard with volume, estimated‑1RM, streaks and body-weight trend. This core is comparable to Strong/Hevy's tracking layer and is backed by real backend tests (`backend/gym_api/tests.py`).

The biggest risk to the product right now is **not a missing feature — it's a credibility gap**. Several prominently marketed screens are non-functional mockups wired to fake data: the "AI-generated" plan on Home is a deterministic template behind a fake 1.6s spinner (`frontend/lib/features/plan/state/plan_notifier.dart`), the "Kaori" AI Coach chat is canned static bubbles with a "launching soon" snackbar (`frontend/lib/features/coach/presentation/coach_page.dart`), and Form Vault / 3D Replay are explicitly commented as mock data with "NOT REAL MEASUREMENTS" (`frontend/lib/features/biomechanics/data/biomechanics_mock.dart`). Meanwhile, the best-tested, most fully-built feature in the entire repo is "Gym Bro" — a Tinder-style workout-partner matching and chat system — which is a differentiator worth leaning into, not a distraction.

Competitor research (Hevy, Strong, Fitbod, JEFIT, Boostcamp, OpenGym, plus WHOOP/Garmin for recovery) shows the fitness-tracker category has converged on a small set of table-stakes mechanics Gym Planner is missing or weak on: **RPE/RIR logging**, **exercise substitution as an in-workout action** (not just a data field), **progress photos**, and **real payment/entitlement gating** for the subscription that already exists as a UI shell. Social feed/leaderboard style features (Hevy) are already substantially covered here by Gym Bro's different (partner-matching) angle, so we do not recommend duplicating a generic public feed.

**Top recommendation:** close the "fake feature" credibility gap first (either build the real thing behind it or remove/relabel the marketing), then add RPE/RIR + exercise substitution (cheap, high-value, table-stakes), then wire real subscription billing before spending further engineering time on AI/CV features that currently have no backend at all.

---

## Current Product Assessment

```text
Area                     Status
--------------------------------------------------------------
Authentication           Complete (JWT, register/login/logout, tested)
Onboarding               Complete (UI flow), feeds a fake plan generator
Workout Plans (CRUD)     Complete, tested
"AI" Plan Generation     Stubbed — deterministic template, no real AI
Exercise Library         Complete (search/filter/favorites/detail), tested
Exercise Substitution    Complete — in-workout "Replace exercise" action (done 2026-09-13)
Workout Runner           Complete (timers, logging, offline queue, PR detection)
RPE Tracking             Complete — optional per-set RPE + average in summary (done 2026-09-13)
Progress Tracking        Complete (volume, e1RM, streaks, PRs, body weight, avg RPE)
Progress Photos/Measure. Photos complete (done 2026-09-13); body circumference still missing
Recovery/Meditation      Complete (backend just shipped today), tested
Breathwork               Partial — UI only, not confirmed persisted
Profile/Settings         Partial — notifications/wearables explicitly stripped as non-functional
Feedback ("help us improve") Complete (write-only by design), just shipped
Subscription/Paywall     Stubbed — no payment gateway, waitlist only, nothing gated (TASK-003, still open)
Social ("Gym Bro")       Complete — best-tested feature in the repo
AI Coach ("Kaori")       Stubbed/Mock, now honestly labeled "Preview" (done 2026-09-13) — still no backend
Biomechanics/Form Vault  Stubbed/Mock, now honestly labeled "Preview" (done 2026-09-13) — still no CV pipeline
Notifications            Missing (removed as non-functional stub)
Nutrition                Missing (not in product scope currently)
Wearables                Missing
Offline/Local Persistence Complete (Drift cache + SharedPreferences outbox)
```

---

## Competitor Research Summary

| Source | Confidence | Key takeaway |
|---|---|---|
| Hevy (2026 reviews) | High | Auto-fills previous performance for progressive overload; Trainer (Pro) does adaptive weight adjustment + exercise substitution; full social feed, friends, gym leaderboards |
| Strong | High | Zero social features by design; users praise raw logging speed; known gaps: no calorie estimate, no recovery map |
| Fitbod | Medium | No permanent free tier (trial→paid only); users complain about illogical AI-generated exercise selection and difficulty progressively overloading *custom* (non-AI) workouts |
| JEFIT | Medium | Large exercise DB (1,400+) with animated demos; community-shared routines; ads on free tier |
| Boostcamp | High | Free tier includes RPE **and** RIR logging per set, rest timer, plate calculator, supersets/dropsets, e1RM, 11,000+ programs — sets the current bar for "table stakes" set-logging fields |
| OpenGym (self-hosted OSS variant) | Medium | Privacy-first, no-account, guided workouts, weight trend chart with goal line — validates that Gym Planner's own offline/local-first approach (Drift + outbox) is a reasonable product direction, not a compromise |
| WHOOP / Garmin / Oura (recovery) | High | Recovery scoring is built from HRV/sleep and is genuinely hardware-dependent (wearable sensors) — confirms a from-scratch software-only "readiness score" would be low-credibility without sensor data, unlike simple meditation-minutes streak tracking which Gym Planner already does well |
| General user sentiment (Reddit-adjacent) | Medium | Recurring complaint is *feature bloat/slowness*, not "app doesn't do enough" — reinforces this document's bias toward a small number of high-value additions over a long list |

---

## Top Opportunities

### #1 Exercise Substitution as an In-Workout Action

**Category:** CORE WORKOUT / EXERCISE LIBRARY

**Current Status:** Partial. `Exercise` model already has `alternatives`, `progression_exercises`, `regression_exercises` M2M fields and admin tooling to curate them (`backend/gym_api/models.py:129-258`, `admin.py:94-171`), and `ExerciseSerializer.alternatives_detail` exposes them. But there is no confirmed user-facing "swap this exercise" action inside the plan runner or plan editor — the data is curated and served but not actionable.

**Why:** This is the single most common "table stakes" gap identified: Hevy gates it behind Trainer/Pro, Strong lacks it, and Fitbod's algorithmic substitution frustrates users. Gym Planner already has the hard part (curated alternatives data + admin curation workflow) built and unused. Wiring the UI is comparatively cheap.

**Evidence:** Hevy Trainer "exercise replacements" (Pro-only); Fitbod user complaints about inflexible/illogical substitutions; general expectation across JEFIT/Boostcamp that swapping an exercise (e.g., no cable machine at this gym) is a normal mid-workout action.

**Competitors:** Hevy, Fitbod, JEFIT, Boostcamp

**User Value:** 4/5 — solves the real "equipment isn't available" / "this hurts my joints" problem mid-workout.
**Business Value:** 3/5 — retention/consistency driver, not a conversion feature by itself.
**Competitive Importance:** 4/5 — approaching table stakes for a serious tracker.
**Strategic Fit:** 5/5 — reuses existing data model and admin curation exactly as designed.
**Complexity:** 2/5 — data already modeled; work is UI + one filtering endpoint.

**Priority: P0**

**Recommendation: YES — build.** This is the cheapest high-value gap in the entire audit because the schema and admin curation already exist; only the surface action is missing.

---

### #2 RPE / RIR Logging on Sets

**Category:** CORE WORKOUT / PROGRAMMING

**Current Status:** Missing. `ProgressMetric` (models.py:320-341) captures `reps`, `weight_kg`, `duration_seconds` — no perceived-exertion field anywhere in the model, serializer, or runner UI.

**Why:** Boostcamp ships RPE **and** RIR per set on its free tier and stores it to build fatigue trend/e1RM confidence. It is now a baseline expectation for anyone doing structured hypertrophy/strength programming, and Gym Planner already computes an estimated 1RM (`views.py:502-505`) that would become meaningfully more accurate with an RPE input.

**Evidence:** Boostcamp feature comparison (RPE/RIR on free tier); general strength-training programming literature treats RPE/RIR as standard autoregulation input.

**Competitors:** Boostcamp, most serious lifting-log apps

**User Value:** 3/5 — meaningful for intermediate/advanced lifters, less critical for beginners.
**Business Value:** 2/5 — mostly a retention/credibility feature for the serious-lifter segment.
**Competitive Importance:** 4/5 — increasingly expected.
**Strategic Fit:** 4/5 — plugs directly into the existing `ProgressMetric` + `summary` (e1RM, volume) pipeline.
**Complexity:** 2/5 — one nullable field + one migration + one UI control in the runner.

**Priority: P1**

**Recommendation: YES — build**, after #1, since it's a similarly small backend change with real programming value.

---

### #3 Resolve the "Fake Feature" Credibility Gap (AI Plan Generation, Kaori Coach, Form Vault/3D Replay)

**Category:** UX / RETENTION / PRODUCT INTEGRITY

**Current Status:** All three are explicitly mock/stubbed in code comments:
- `plan_notifier.dart:117-121` — plan "generation" is a deterministic template behind a fake delay, comment literally says "see launch plan P2: real AI plan generation."
- `coach_page.dart:11-16` — live chat shows a "launching soon — this is a preview" snackbar; all visible chat is hardcoded.
- `biomechanics_mock.dart` header — "Mock data layer... NOT REAL MEASUREMENTS. Architecture is ready to swap in real CV data."
- `you_page.dart:165` — "unlock AI coaching & Form Vault with Premium" copy exists, but no code anywhere gates access by subscription status.

**Why:** This is not a "missing feature," it's an integrity risk: the app currently presents fabricated AI/CV output as if it were real personalization to users, including inside a monetization pitch ("unlock with Premium") for a capability that doesn't exist yet. If a user discovers the "AI plan" is a static template, or pays for Premium expecting a working coach/Form Vault, that is a trust and potentially a consumer-protection problem, not just a UX rough edge.

**Evidence:** Direct code inspection (see file:line references above), confirmed first-party, not competitor-derived.

**Competitors:** N/A (internal finding)

**User Value:** 5/5 (as a *risk avoided*, not a feature added) — directly affects trust in every other feature.
**Business Value:** 4/5 — protects premium conversion integrity and avoids review-bombing/refund risk once users notice.
**Competitive Importance:** N/A
**Strategic Fit:** 5/5 — must be resolved before any of these three areas is marketed further.
**Complexity:** Varies — the *remediation* (relabeling honestly, or gating premium copy) is Low complexity; *building the real feature* is Very High (real LLM plan generation, real chat backend, real computer-vision form analysis).

**Priority: P0** for the honesty/labeling remediation. Building the real underlying AI/CV features is **NOT recommended in this cycle** (see "Do Not Build Yet").

**Recommendation:**
- **YES — remediate immediately:** stop referencing "Premium unlocks AI coaching & Form Vault" in copy until a real capability exists behind it, since nothing currently gates on subscription status; either soft-launch these as clearly-labeled "Preview" / "Coming soon" experiences (partially already true for Kaori's live chat) applied consistently to Form Vault and the AI plan, or hide the entry points until real functionality lands.
- **MAYBE — investigate further** before committing engineering time to real LLM-backed plan generation or real CV-based form analysis; these are Very High complexity, require external AI/CV vendor integration, and should go through a separate scoping cycle once the tracking core (Now/Next below) is solid.

---

### #4 Real Subscription Billing & Feature Gating

**Category:** MONETIZATION

**Current Status:** Stubbed. `Subscription` model has Stripe-shaped fields (`provider_customer_id`, `provider_subscription_id`) but no webhook handler was found; `SubscriptionSerializer` makes plan/status read-only by design; the only real backend action is `join_waitlist` (views.py:635-641); the frontend "Upgrade" button opens an external Stripe Payment Link in a browser rather than using in-app purchase; no code anywhere actually checks subscription status to gate access to any screen.

**Why:** There is currently no way for WELLAURA to collect recurring revenue in-app, and no feature is actually paywalled — meaning the "Premium" framing in the UI is aspirational. This blocks monetization entirely and is a prerequisite for any of the "Premium" claims already visible in the You tab to become true.

**Evidence:** Direct code inspection (models.py:76-108, serializers.py:384-406, views.py:635-641, you_page.dart:130-208).

**Competitors:** Hevy ($23.99/yr, real free tier + paid unlock), Fitbod ($95.99/yr, trial-to-paid only) — both show that a working billing pipeline, not just a payment link, is standard.

**User Value:** 2/5 — mostly indirect (funds continued development); not a user-facing pain point per se.
**Business Value:** 5/5 — this is the only path to recurring revenue; currently completely blocked.
**Competitive Importance:** 5/5 — every competitor referenced has a working billing pipeline.
**Strategic Fit:** 5/5 — foundational for the business, not optional polish.
**Complexity:** 4/5 — requires App Store/Play Store IAP or Stripe webhook + entitlement sync, receipt validation, and at least one real gated feature to gate.

**Priority: P0**

**Recommendation: YES — build**, but scope it as its own task chain (webhook/IAP integration → entitlement model → gate exactly one real feature) rather than bundling with the AI/CV remediation above.

---

### #5 Progress Photos

**Category:** PROGRESS

**Current Status:** Missing. `BodyWeightEntry` covers weight only; no photo model, no body-measurement (waist/chest/arm) fields anywhere in `models.py`.

**Why:** Progress photos are a low-complexity, high-perceived-value addition that pairs naturally with the existing body-weight trend chart already built in `progress_page.dart`, and is a well-established retention mechanic (visible physical change reinforces continued app use) without requiring AI/CV analysis — just storage and a timeline view.

**Evidence:** Common feature across JEFIT/Strong-style logs; general fitness-app category expectation once body-weight tracking already exists.

**Competitors:** JEFIT, Strong-adjacent trackers, most physique-focused apps

**User Value:** 3/5 — meaningful for users tracking body composition change, not universal.
**Business Value:** 2/5 — modest retention lever.
**Competitive Importance:** 3/5 — common but not universal.
**Strategic Fit:** 4/5 — extends the existing `BodyWeightEntry`/progress screen pattern directly.
**Complexity:** 3/5 — needs image storage (already have a precedent: `Feedback.attachment` and `Exercise.image` use Django `ImageField`), a new model, and a simple timeline/compare UI.

**Priority: P2**

**Recommendation: YES — build**, but only after P0/P1 items above; this is a "Next," not a "Now."

---

## Feature Comparison Matrix

| Feature | OpenGym | Competitors | Gym Planner | Gap | Priority |
|---|---|---|---|---|---|
| Weekly plan scheduling | Yes | Yes (all) | Yes, tested | None | — |
| Exercise search/filter/favorites | Yes | Yes (all) | Yes, tested | None | — |
| Rest timer + set logging | Yes | Yes (all) | Yes, incl. offline queue | None | — |
| Previous-performance prefill | Partial | Yes (Hevy) | Yes | None | — |
| PR detection | No | Yes (most) | Yes, server-side | None | — |
| Estimated 1RM | No | Yes (Boostcamp) | Yes | None | — |
| Exercise substitution (in-workout action) | No | Yes (Hevy Trainer/Pro, Fitbod) | Data model only, no UI action | **Gap** | P0 |
| RPE/RIR logging | No | Yes (Boostcamp) | No | **Gap** | P1 |
| Body-weight trend | Yes | Yes | Yes | None | — |
| Progress photos | No | Yes (JEFIT-adjacent) | No | **Gap** | P2 |
| Body measurements (circumference) | No | Some | No | Gap (low priority — see below) | P3 |
| Meditation/mindfulness logging | No | Rare | Yes, tested, has streak | Differentiator | — |
| Social feed / leaderboard | No | Yes (Hevy) | No public feed; has partner-matching ("Gym Bro") instead | Different angle, not a gap | — |
| Real subscription billing | N/A (self-hosted, free) | Yes (Hevy, Fitbod) | No (waitlist + external payment link only) | **Gap** | P0 |
| AI adaptive plan generation | No | Yes (Hevy Trainer, Fitbod) | Fake/template, marketed as if real | **Credibility gap** | P0 (remediate) |
| AI chat coach | No | No (not common) | Fake/static, marked "coming soon" | Consistent labeling needed | P0 (remediate) |
| Recovery readiness score (HRV-based) | No | Yes (WHOOP/Garmin, hardware-dependent) | No | Not recommended without sensor data — see Do Not Build Yet | — |
| Nutrition tracking | No | Some (MyFitnessPal-adjacent) | No | Out of current scope | — |
| Wearable integration | No | Yes (Garmin/WHOOP) | No, explicitly removed as non-functional | Deferred, not urgent | — |

---

## UX Opportunities

These are existing features with real backend/frontend wiring where the *experience*, not the underlying capability, needs work:

1. **Session-detail deep-linking.** `session_detail_page.dart` receives the `WorkoutSession` object via in-memory router `extra` and falls back to a "missing session" page if not present (`app_router.dart:42-59`) — meaning a saved link or app restart can't reliably reopen a past session. Fix: fetch by ID from the backend when `extra` is absent, since the `WorkoutSession`/`ProgressMetric` data already exists server-side.
2. **"Coming soon" settings rows left visible.** Push-notification and sensor/wearable toggles were deliberately removed from `you_page.dart` per an explicit comment (they "silently did nothing"), which is the right call — but confirm no other screen still references them, and keep this pattern (remove rather than leave a dead toggle) as the house style going forward.
3. **Premium marketing copy references non-existent gating.** "Unlock AI coaching & Form Vault with Premium" (you_page.dart:165) should either be removed or clearly marked as a future capability until #3 and #4 above are resolved.

---

## Differentiation Opportunities

Rather than copying competitors feature-for-feature, two areas of the existing codebase are already ahead of typical competitors and worth investing in further rather than diluting focus with copycat features:

1. **"Gym Bro" partner matching is a genuine differentiator.** It's the most fully built, best-tested feature in the repo (`GymBroTests`, tests.py:515-626) and represents an accountability/social angle none of the researched competitors (Hevy's public feed/leaderboard model is different — broadcast, not matchmaking) offer in this form. Rather than adding a generic public social feed to "catch up" to Hevy, doubling down on making Gym Bro discovery/matching better (e.g., smarter compatibility signals from shared `training_goals`/`experience_level`/`availability` already on `Profile`) is a stronger strategic bet than chasing feed parity.
2. **Meditation + workout integration is ahead of most lifting-focused competitors.** Very few strength-tracking apps (Hevy, Strong, Fitbod, JEFIT, Boostcamp) bundle a tested meditation/mindfulness log with its own streak logic. Building a lightweight cross-feature signal — e.g., surfacing meditation streak alongside workout streak on the Home dashboard — would reinforce this as a "well-being," not just "lifting," app without requiring new backend work (`MeditationSessionViewSet.summary` already computes streak).

---

## Recommended Roadmap

### Now
- ~~TASK-001 Exercise substitution in-workout action (#1)~~ — done 2026-09-13
- ~~TASK-002 Fix/relabel AI plan generation and Premium marketing copy honesty issues (#3, remediation only)~~ — done 2026-09-13
- TASK-003 Begin real subscription billing integration scoping (#4) — **still open**, needs a payment-provider decision

### Next
- ~~TASK-004 RPE/RIR logging on sets (#2)~~ — done 2026-09-13
- ~~TASK-005 Session-detail deep-linking fix (UX)~~ — done 2026-09-13
- ~~TASK-006 Progress photos (#5)~~ — done 2026-09-13

### Later
- Body measurement tracking (waist/chest/arm circumference) — real but lower-value than photos; revisit once photos ship and there's user demand signal.
- Cross-feature Home dashboard signal combining workout + meditation streaks (differentiation opportunity #2).
- Gym Bro compatibility-signal improvements (differentiation opportunity #1).

### Do Not Build Yet
- **Real LLM-backed adaptive plan generation.** Very High complexity, requires external AI vendor integration and safety/quality evaluation; should not be started until the credibility remediation (#3) and core P0/P1 items ship. Revisit as its own scoped research cycle.
- **Real computer-vision Form Vault / 3D Replay.** Very High complexity, requires a camera/pose-estimation pipeline with no current backend; same reasoning as above — do not build until there's a clear resourcing plan for a CV pipeline specifically.
- **HRV/sensor-based recovery readiness score.** Rejected for now: WHOOP/Garmin/Oura readiness scores are built on dedicated wearable sensor hardware (HRV, overnight sleep staging); a software-only "readiness score" without sensor input would not be credible and risks the same trust problem flagged in #3. The existing meditation/streak-based recovery signal is honest and sufficient for now.
- **Nutrition tracking.** Explicitly out of current product scope per the skill's own guidance ("evaluate whether it fits Gym Planner's strategy" — no evidence in the codebase or product framing that nutrition is part of the near-term vision); would also be a large net-new feature area (food database, macro tracking) disproportionate to current focus.
- **Generic public social feed / leaderboard (Hevy-style).** Gym Bro already covers the social/accountability angle with a different, more differentiated mechanic; a second, overlapping social surface would fragment attention rather than add value (see Differentiation Opportunities).
- **Wearable integration.** Deferred — was explicitly and correctly stripped from the UI as a non-functional stub; re-introduce only alongside a concrete wearable-data use case (e.g., once/if a real recovery feature is scoped), not speculatively.

---

## Implementation Backlog

### TASK-001 ✅ Done
**Title:** Exercise substitution during workout execution
**Category:** CORE WORKOUT
**Priority:** P0
**Goal:** Allow users to replace an exercise mid-workout (or during plan editing) with a curated compatible alternative, using the `alternatives`/`progression_exercises`/`regression_exercises` relationships that already exist on `Exercise`.
**User Story:** As a gym user mid-workout, I want to swap an exercise for a suitable alternative (e.g., equipment unavailable, discomfort) so that I can keep training without abandoning the session.
**Problem:** The data model and admin curation for alternatives already exist (`backend/gym_api/models.py:129-258`, `admin.py:94-171`, `serializers.py` `alternatives_detail`) but there is no user-facing action to invoke a swap.
**Prerequisites:** Existing `Exercise` model relationships, existing `LibraryExerciseViewSet`, existing plan runner (`plan_runner_page.dart`).
**Frontend:**
- Add a "Replace exercise" action to `plan_runner_page.dart` (accessible from the active exercise view) and, if in scope, to plan editing.
- Build a replacement-selection sheet/screen showing `alternatives_detail` (and optionally progression/regression) with target muscles and equipment shown per candidate.
- Preserve the current set's configuration (target reps/weight/rest) onto the replacement where compatible; carry over `PlanDayExercise` ordering.
- Update `ExerciseRepository`/Drift cache usage as needed so the swap works with the offline-first read path.
**Backend:**
- Confirm `ExerciseSerializer.alternatives_detail` returns enough fields (muscles, equipment, difficulty) for the selection UI; extend if not.
- If runtime filtering by available equipment is desired, add a query param to `LibraryExerciseViewSet` or a dedicated `substitutes` action on `ExerciseViewSet`/`LibraryExerciseViewSet` (reuse existing `equipment`/`body_part` filter pattern from views.py:348-392) rather than inventing a new endpoint pattern.
- No new models required; this is UI + serializer/endpoint extension only.
**Database:** None (existing M2M fields already support this).
**UX:** Empty state when no alternatives are curated for an exercise; clear indication of why a swap is suggested (equipment/target-muscle match).
**Acceptance Criteria:**
- User can open a "Replace exercise" flow from an active workout in the runner.
- Only curated alternatives (or, if implemented, equipment-filtered library matches) are shown — not arbitrary unrelated exercises.
- Completed sets logged before the swap remain unchanged in `ProgressMetric`/`WorkoutSession`.
- The replacement is reflected for the remainder of that session and, where applicable, persists back to the `PlanDayExercise`/`Exercise` assignment.
- Users cannot substitute into another user's private exercise (must respect existing ownership/library rules already enforced by `ExerciseViewSet`).
- Empty state renders correctly when an exercise has no curated alternatives.
**Testing:**
- Backend: API test that substitution/browse endpoint only returns library or user-owned exercises (mirror the existing `test_favorites_are_user_scoped_and_reject_foreign_exercises` pattern in tests.py).
- Backend: authorization test — unauthenticated/foreign-user requests rejected.
- Flutter: widget test for the replacement sheet rendering alternatives and empty state.
- Flutter: runner state test confirming a swap mid-session doesn't corrupt already-logged sets.
- End-to-end manual: log in → start workout → replace an exercise → finish set → finish workout → verify session detail shows correct exercise → reopen app → verify persistence.
**Regression Checks:** Existing plan runner flows (start/finish workout, rest timer, PR detection, offline queue) must continue to pass unchanged; run `test gym_api` targeted at `PlanViewSet`/`ExerciseViewSet`/`ProgressMetricViewSet` tests plus `flutter analyze` on touched files.
**Dependencies:** None — all prerequisite data/model work already exists.
**Estimated Complexity:** Medium

---

### TASK-002 ✅ Done
**Title:** Remediate AI/Premium marketing copy honesty gaps
**Category:** UX / RETENTION
**Priority:** P0
**Goal:** Remove or clearly relabel marketing claims that reference non-functional capabilities (AI plan generation as real AI, "unlock AI coaching & Form Vault with Premium") until those capabilities exist and are actually gated.
**User Story:** As a gym user, I want the app's claims about AI/Premium features to reflect what the app actually does, so I'm not misled about what I'm paying for or using.
**Problem:** `plan_notifier.dart` fakes AI generation behind a timed delay; `coach_page.dart` shows static chat; `biomechanics_mock.dart` is explicitly fake data; `you_page.dart:165` markets Premium as unlocking capabilities that no code anywhere gates on subscription status.
**Prerequisites:** None — this is a copy/labeling and (optionally) UI-visibility change, not new functionality.
**Frontend:**
- Update copy in `you_page.dart` to remove or clearly caveat ("Preview", "Coming soon") claims about AI coaching/Form Vault being a Premium unlock.
- Apply the same "Preview"/"Coming soon" labeling already used for Kaori's live chat consistently to the Home "AI-generated" plan screen and to Form Vault/3D Replay entry points.
- Optionally rename the Home generation copy from "AI-generated plan" to something accurate (e.g., "Personalized starter plan") if the underlying logic will remain template-based for now.
**Backend:** None required for the labeling fix itself.
**Database:** None.
**UX:** Ensure labeling is consistent across all three surfaces (plan generation, coach, biomechanics) rather than fixed piecemeal.
**Acceptance Criteria:**
- No screen claims a capability is AI-generated, Premium-gated, or CV-analyzed unless that is actually true in code.
- Copy changes reviewed against actual gating logic (grep for `subscription`/`isPremium` checks) to confirm no remaining mismatches.
**Testing:**
- Manual copy review pass across `you_page.dart`, `coach_page.dart`, `plan_page.dart`/`plan_notifier.dart`, `form_vault_page.dart`, `replay_3d_page.dart`.
- Flutter widget/golden test updates if any copy strings are asserted in existing tests.
**Regression Checks:** Confirm no other screen or test depends on the old copy strings; run `flutter analyze` and any widget tests touching these pages.
**Dependencies:** None.
**Estimated Complexity:** Low

---

### TASK-003 ⏸ Deferred (needs payment-provider decision)
**Title:** Real subscription billing integration (foundation)
**Category:** MONETIZATION
**Priority:** P0
**Goal:** Replace the external Stripe Payment Link + waitlist-only flow with a real billing integration (Stripe webhook-driven entitlement sync, or platform IAP) so `Subscription.status`/`plan_name` reflect real payment state, and gate at least one real feature on it.
**User Story:** As a business owner, I want subscription status to reflect real payments so Premium claims are accurate and recurring revenue is possible.
**Problem:** `Subscription` model has Stripe-shaped fields but no webhook handler; `SubscriptionSerializer` is read-only by design; frontend only supports `join_waitlist` and an external browser-based payment link; nothing in the codebase checks subscription status to gate feature access.
**Prerequisites:** Decide IAP vs. Stripe-webhook approach (business/product decision, not purely technical) before implementation — flag this as a scoping question for the user/product owner rather than assuming.
**Frontend:**
- Replace/extend the "Upgrade" flow in `you_page.dart` per the chosen approach (in-app purchase sheet, or keep external checkout but poll/refresh subscription status on return).
- Add at least one real UI gate (e.g., a feature currently marketed as Premium) that checks `subscriptionProvider` status before granting access.
**Backend:**
- Add a Stripe webhook endpoint (or platform receipt-validation endpoint) that updates `Subscription.status`/`provider_subscription_id`/`provider_customer_id` on real payment events.
- Extend `SubscriptionSerializer`/`ProfileViewSet`-adjacent logic to expose accurate real-time status.
- Add server-side permission checks gating whichever feature is chosen for the first real paywall.
**Database:** Likely no new models — `Subscription` fields already anticipate this; may need a `webhook_event_id` audit field to guard against duplicate webhook delivery.
**UX:** Handle payment failure/pending states gracefully (`past_due`, `unpaid` already modeled).
**Acceptance Criteria:**
- A real payment (or platform sandbox purchase) updates `Subscription.status` without manual admin intervention.
- At least one feature is verifiably inaccessible to a `free`/`waitlisted` user and accessible to an `active` subscriber.
- Webhook/receipt endpoint rejects unauthenticated or malformed events without crashing.
- No secrets (Stripe keys) committed to the repo; configuration via existing `.env` pattern.
**Testing:**
- Backend: webhook signature validation test, duplicate-event idempotency test, status-transition tests (mirroring existing `test_join_waitlist_records_intent_without_granting_premium` pattern).
- Backend: permission test confirming the gated feature is denied/allowed correctly by status.
- Manual: sandbox/test-mode payment end-to-end.
**Regression Checks:** Existing `test_current_subscription_is_private_and_read_only` and `test_join_waitlist_...` tests must still pass (or be deliberately and explicitly updated if the read-only contract changes); confirm the waitlist path still works for users who haven't paid.
**Dependencies:** Product decision on IAP vs. Stripe webhook approach; TASK-002 remediation should land first or alongside so Premium copy matches the newly-real gating.
**Estimated Complexity:** High

---

### TASK-004 ✅ Done
**Title:** RPE/RIR logging on logged sets
**Category:** PROGRAMMING / PROGRESS
**Priority:** P1
**Goal:** Let users optionally record RPE (1-10) or RIR (reps in reserve) per logged set, and surface it in progress/history views.
**User Story:** As a gym user doing structured programming, I want to log how hard a set felt so I can track fatigue trends and get a more accurate estimated 1RM.
**Problem:** `ProgressMetric` has no exertion field; the runner UI has no input for it.
**Prerequisites:** TASK-001 not required as a dependency, but should be sequenced after it to avoid two runner-UI changes landing in parallel and causing merge conflicts in `plan_runner_page.dart`.
**Frontend:**
- Add an optional RPE (or RIR — pick one consistent unit; do not offer both simultaneously to avoid confusing input, per Boostcamp's model of storing both but from a single consistent capture UI) input control to the set-logging step in `plan_runner_page.dart`.
- Surface average RPE/RIR trend in `progress_page.dart` alongside existing volume/e1RM cards.
**Backend:**
- Add nullable `rpe` (or `rir`) field to `ProgressMetric` + migration.
- Extend `ProgressMetricSerializer` and the `summary` action to include average exertion and optionally factor it into the existing estimated-1RM calculation.
**Database:** One new nullable column + migration (`backend/gym_api/migrations/`).
**UX:** Field must be clearly optional — do not block set completion if omitted, to avoid the "too much stuff" complaint pattern identified in user research.
**Acceptance Criteria:**
- User can log a set without RPE/RIR (fully optional) and with it.
- Submitted RPE/RIR values are validated to a sane range (e.g., RPE 1-10) and rejected outside it, mirroring the existing body-weight validation pattern (`test_body_weight_can_be_logged_and_listed_*`).
- `summary` endpoint returns average exertion for the requested scope without errors when some sets have no value logged.
- Existing progress charts continue to render correctly for historical sets with no RPE/RIR value.
**Testing:**
- Backend: model/migration test, validation test (reject out-of-range values), summary-endpoint test with mixed logged/unlogged exertion data.
- Flutter: widget test for the optional input control; ensure omitting it doesn't block set completion.
**Regression Checks:** Re-run `ProgressMetricViewSet` test suite in full; confirm existing e1RM/volume/PR calculations are unaffected for sets without exertion data.
**Dependencies:** None blocking; sequence after TASK-001 to avoid runner-file merge conflicts.
**Estimated Complexity:** Low

---

### TASK-005 ✅ Done
**Title:** Fix session-detail deep-linking
**Category:** UX
**Priority:** P1
**Goal:** Allow `/session/:id` to load a `WorkoutSession` from the backend when it isn't available via in-memory router `extra`, so links, deep links, and app restarts work.
**User Story:** As a gym user, I want to reopen a past workout session (e.g., from a notification, share link, or after restarting the app) and see its details, not a "missing session" placeholder.
**Problem:** `session_detail_page.dart` currently depends on the `WorkoutSession` being passed via router `extra`; if absent, `app_router.dart:42-59` falls back to a `_MissingSessionPage`, even though the session data exists server-side.
**Prerequisites:** None — `WorkoutSession`/`ProgressMetric` retrieval endpoints already exist.
**Frontend:**
- Update `app_router.dart`'s `/session/:id` route (and `session_detail_page.dart`) to fetch the session via `ApiClient` when `extra` is null, using the existing `WorkoutSessionViewSet` retrieve endpoint.
- Add a loading state while fetching and an error state distinct from "missing" for network failures vs. a genuinely nonexistent/foreign session.
**Backend:** Likely none — confirm `WorkoutSessionViewSet` supports authorized single-object retrieval by ID (it should, given standard `ModelViewSet` CRUD); add an authorization test if one doesn't already exist confirming a user can't fetch another user's session by guessing an ID.
**Database:** None.
**UX:** Distinguish "loading," "not found/not yours," and "network error" states clearly.
**Acceptance Criteria:**
- Navigating directly to `/session/:id` (e.g., via browser refresh on Flutter Web, or a fresh deep link) loads the correct session detail without requiring in-memory `extra`.
- A session ID belonging to another user returns an authorization error, not the session's data.
- A genuinely nonexistent session ID shows a clear "not found" state, not a generic crash.
**Testing:**
- Backend: authorization test for cross-user session retrieval (mirror the existing `MatchViewSet` non-participant 403 pattern from `GymBroTests`).
- Flutter: widget test confirming the page fetches by ID when `extra` is null.
- Manual: refresh the browser tab on a session-detail URL (Flutter Web) and confirm it still renders.
**Regression Checks:** Confirm the existing in-memory `extra` fast-path (from the progress page) still works unchanged; run full `progress`/`plan_runner` related Flutter tests.
**Dependencies:** None.
**Estimated Complexity:** Low

---

### TASK-006 ✅ Done
**Title:** Progress photos
**Category:** PROGRESS
**Priority:** P2
**Goal:** Let users attach a dated photo to their progress log, viewable as a timeline alongside the existing body-weight trend chart.
**User Story:** As a gym user tracking physique change, I want to log progress photos over time so I can visually compare changes alongside my weight trend.
**Problem:** No photo/measurement model exists beyond `BodyWeightEntry` (weight only).
**Prerequisites:** None blocking, but should follow the P0/P1 items above.
**Frontend:**
- Add a "Log photo" action near the existing body-weight entry flow in `progress_page.dart`.
- Build a simple photo timeline/compare view (reuse the existing custom-painter chart area's layout conventions where sensible).
**Backend:**
- Add a `ProgressPhoto` model (user, image `ImageField` — reuse the existing `Feedback.attachment`/`Exercise.image` pattern — logged_at) + migration.
- Add a `ProgressPhotoViewSet` (list/create/delete, user-scoped, mirroring `BodyWeightEntryViewSet`'s permission pattern).
**Database:** New model + migration; new media storage path (reuse existing media configuration used by `Exercise.image`/`Feedback.attachment`).
**UX:** Clear empty state; explicit user consent/privacy framing given these are sensitive personal images (no sharing/social exposure by default — this must remain private to the user, unlike Gym Bro's profile data).
**Acceptance Criteria:**
- User can upload a dated photo and see it in a private timeline.
- Photos are never exposed to other users (including Gym Bro matches) — verify no serializer path leaks another user's `ProgressPhoto`.
- Deleting a photo removes it from storage and the timeline.
- Unauthorized users cannot list/retrieve another user's photos.
**Testing:**
- Backend: CRUD test, user-scoping test (mirror `test_favorites_are_user_scoped_and_reject_foreign_exercises`), unauthenticated-rejection test.
- Flutter: widget test for upload flow and empty state.
- Manual: upload → verify appears in timeline → restart app → verify persistence → delete → verify removal.
**Regression Checks:** Confirm existing body-weight logging flow and progress charts are unaffected; run full `progress` test suite.
**Dependencies:** None.
**Estimated Complexity:** Medium

---

## Notes on Scope Discipline

Per the skill's core principle, several plausible competitor features were deliberately **not** turned into tasks this cycle:
- Nutrition tracking, wearable integration, HRV-based recovery scoring, a generic public social feed, and building the real AI plan generator / CV form analysis are all listed under "Do Not Build Yet" above with explicit reasoning — not omitted by oversight.
- Body measurements (waist/chest/arm) were downgraded to "Later" rather than bundled with progress photos, since photos alone address most of the same underlying user need with lower complexity, and adding both at once risks the "feature bloat" complaint pattern surfaced in user research.
