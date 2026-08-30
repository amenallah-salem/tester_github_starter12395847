# Feature Inventory — AI Gym Assistant / Personal Training SaaS

**Deliverable for [SIW-7](/#SIW-7) · feeds SIW-6 (Project Master Instruction, §5–§20).**

- **Author:** Product Analyst (siwar_corp)
- **Date:** 2026-08-29
- **Purpose:** Full feature inventory matrix for the Product Manager (T-03) to convert into the product requirements baseline. Maps 1:1 to every SIW-6 capability section (5–20) and records whether benchmarked competitors have each feature, then assigns **MVP / Future** priority with rationale.
- **Method:** Cross-referenced against [competitive-research.md](competitive-research.md) (2026 public listings/reviews).

**Legend**

- ✅ Present today · ◐ Partial / tier-limited / gated · ❌ Absent · — Not publicly verified in this research (flag for T-03 to validate)
- Priority: **MVP** = must ship for a credible v1 of the AI Gym Assistant; **Future** = post-MVP differentiator, can wait.

Benchmarks: **St** = Strong · **He** = Hevy · **Fb** = Fitbod · **RC** = RepCount · **JF** = JEFIT · **Sv** = Strive · **IS** = IronStreak · **Ca** = Caliber.

---

## §5 — User Account System (SIW-6 §5)

| # | Feature | St | He | Fb | RC | JF | Sv | IS | Ca | Priority | Rationale |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 5.1 | Registration (name, email, password, confirm, terms) | ✅ | ✅ | ✅ | ◐ | ✅ | ◐ | ❌ | ✅ | **MVP** | Required by spec; enables progress sync and coaching personalization. |
| 5.2 | Login / logout | ✅ | ✅ | ✅ | ◐ | ✅ | ◐ | ❌ | ✅ | **MVP** | Core auth loop. |
| 5.3 | Persistent auth across restarts + refresh | ✅ | ✅ | ✅ | — | ✅ | — | n/a | ✅ | **MVP** | Retain session; refresh tokens (DRF). |
| 5.4 | Forgot / reset / change password | ✅ | ✅ | ✅ | — | ✅ | — | n/a | ✅ | **MVP** | Standard security + support surface. |
| 5.5 | Profile: name, picture, DOB, gender | ✅ | ✅ | ✅ | ◐ | ✅ | ◐ | ❌ | ✅ | **MVP** | Basis for personalization. |
| 5.6 | Body stats: height / weight | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ | ✅ | **MVP** | Drives volume/PR baselines. |
| 5.7 | Fitness level + training experience | ◐ | ◐ | ✅ | ◐ | ◐ | ◐ | ❌ | ✅ | **MVP** | Fitbod/Caliber show value in onboarding. |
| 5.8 | Training frequency + schedule preference | ◐ | ◐ | ✅ | ◐ | ◐ | ◐ | ◐ | ✅ | **MVP** | Feed into plan/week generation. |
| 5.9 | Available equipment profile | ◐ | ◐ | ✅ | ◐ | ◐ | ◐ | ◐ | ✅ | **MVP** | Fitbod/Caliber prove eq-aware programming. |
| 5.10 | Preferred training location (gym/home/outdoor) | ❌ | ❌ | ✅ | ❌ | ◐ | ❌ | ❌ | ◐ | **Future** | Nice personalization input; not core to MVP logging. |
| **Section note** | No-account apps (Strive, IronStreak) prove local-first UX works; we ship full accounts per spec, but keep logging usable offline. | | | | | | | | | |

---

## §6 — Onboarding (SIW-6 §6)

| # | Feature | St | He | Fb | RC | JF | Sv | IS | Ca | Priority | Rationale |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 6.1 | Guided post-registration onboarding flow | ◐ | ◐ | ✅ | ❌ | ◐ | ❌ | ❌ | ✅ | **MVP** | Fitbod/Caliber benchmark; lowers activation barrier. |
| 6.2 | Basic profile questions (age/height/weight/experience) | ◐ | ◐ | ✅ | ◐ | ◐ | ◐ | ◐ | ✅ | **MVP** | Required by spec; short, useful only. |
| 6.3 | Main objective selection (lose/weight, build muscle, strength, endurance, body comp, general health, maintain) | ◐ | ◐ | ✅ | ◐ | ◐ | ❌ | ❌ | ✅ | **MVP** | Drives plan recommendation. |
| 6.4 | Training preferences (days/week, duration, time, location, equipment, preferred exercises) | ◐ | ◐ | ✅ | ◐ | ◐ | ◐ | ❌ | ✅ | **MVP** | Personalization seed (spec explicit). |
| 6.5 | Experience level (beginner/intermediate/advanced) | ◐ | ◐ | ✅ | ◐ | ◐ | ❌ | ❌ | ✅ | **MVP** | Plan difficulty selection. |
| 6.6 | Limitations: exercises/movements to avoid | ❌ | ❌ | ◐ | ❌ | ❌ | ❌ | ❌ | ◐ | **MVP** | **White-space gap G1** (Fitbod's most-requested missing feature). Protects users; sharpens substitution. |
| 6.7 | No medical claims; safe scope | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Legal/safety guardrail — must be in copy + disclaimers. |
| 6.8 | Onboarding data stored backend side & used for personalization | ✅ | ✅ | ✅ | ◐ | ✅ | ◐ | ❌ | ✅ | **MVP** | Per spec §6; powers plans, dashboard, substitution. |

---

## §7 — Training Plans (SIW-6 §7)

| # | Feature | St | He | Fb | RC | JF | Sv | IS | Ca | Priority | Rationale |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 7.1 | Plan entity: name, description, objective, difficulty | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ | ✅ | ✅ | **MVP** | Core plan model. |
| 7.2 | Plan duration + number of training days | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ | ✅ | ✅ | **MVP** | Week/day generation dependency. |
| 7.3 | Workout schedule (days) with exercises | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ | ✅ | ✅ | **MVP** | Drives calendar (§14). |
| 7.4 | Per-exercise: sets, reps, rest, duration | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Core workout prescription. |
| 7.5 | Progression rules (auto-load advances) | ◐ | ✅ | ✅ | ◐ | ✅ | ◐ | ◐ | ✅ | **MVP** | Progressive overload is the product's engine. |
| 7.6 | Plan notes / coaching cues | ✅ | ✅ | ✅ | ◐ | ✅ | ◐ | ◐ | ✅ | **Future** | Adds coaching value; not blocking MVP. |
| 7.7 | Starter templates: Full Body, Upper/Lower, PPL, Strength, Hypertrophy, Weight Loss, Beginner, Home | ✅ | ✅ | ◐ | ✅ | ✅ | ◐ | ◐ | ✅ | **MVP** | Data-driven seed plans (spec §7 + §38 "no hardcode"). |
| 7.8 | Plans stored backend-side (data-driven, not hardcoded) | ✅ | ✅ | ✅ | ✅ | ✅ | — | ◐ | ✅ | **MVP** | Spec §38 mandate; enables admin (§19). |
| 7.9 | Automatic/adaptive plan generation | ❌ | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ | **Future** | Fitbod/Hevy-Trainer/JEFIT-v17 lane; differentiating but post-MVP. |

---

## §8 — Exercise Database (SIW-6 §8)

| # | Feature | St | He | Fb | RC | JF | Sv | IS | Ca | Priority | Rationale |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 8.1 | Exercise: name, description, instructions | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Baseline for any library. |
| 8.2 | Muscle groups: primary + secondary | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Search/filter + muscle heat map. |
| 8.3 | Equipment field per exercise | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Equipment-aware filtering (§9). |
| 8.4 | Difficulty + movement type | ◐ | ✅ | ✅ | ◐ | ✅ | ◐ | ◐ | ✅ | **MVP** | Core filters (spec §8). |
| 8.5 | Sets / reps / rest guidance per exercise | ◐ | ✅ | ✅ | ◐ | ✅ | ◐ | ◐ | ✅ | **MVP** | Prescription defaults. |
| 8.6 | Safety notes where appropriate | ◐ | ◐ | ◐ | ◐ | ◐ | ◐ | ◐ | ✅ | **Future** | Safety value; content effort high. |
| 8.7 | Video / media per exercise | ✅ | ✅ | ✅ | ◐ | ✅ | ◐ | ◐ | ✅ | **MVP** | JEFIT/Fitbod set expectation; video guidance (licence-compliant). |
| 8.8 | Image per exercise | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Cheap, expected. |
| 8.9 | Alternative/replacement exercises | ◐ | ◐ | ✅ | ◐ | ✅ | ◐ | ❌ | ✅ | **MVP** | Substitution (§16) depends on this. |
| 8.10 | Browse + search | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Table stakes. |
| 8.11 | Filter by muscle / equipment / difficulty / type | ◐ | ✅ | ✅ | ◐ | ✅ | ✅ | ◐ | ✅ | **MVP** | Spec §8 filters. |
| 8.12 | Exercise detail view (full info) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Expected UX. |
| 8.13 | Custom/user-defined exercises | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **Future** | Nice customization lane; low-demand at launch. |
| 8.14 | Library scale (target) | — | large | 1k+ | moderate | 1.4k+ | moderate | 91 | 600+ | **MVP** | Ship ~150–250 well-licensed exercises, admin-extensible. |

---

## §9 — Equipment / Machine Information (SIW-6 §9)

| # | Feature | St | He | Fb | RC | JF | Sv | IS | Ca | Priority | Rationale |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 9.1 | Equipment/machine catalogue (name, category) | ◐ | ✅ | ✅ | ◐ | ✅ | ✅ | ◐ | ✅ | **MVP** | Basis for filtering + exercise binding. |
| 9.2 | Machine image / exercise image | ◐ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Visual identification. |
| 9.3 | Setup instructions / how to use the machine | ❌ | ◐ | ◐ | ❌ | ◐ | ◐ | ❌ | ◐ | **Future** | **White-space gap G6** — thin industry-wide; differentiating content. |
| 9.4 | Movement instructions per machine | ◐ | ✅ | ✅ | ◐ | ✅ | ◐ | ◐ | ✅ | **MVP** | Exercise instructions cover this daily-use case. |
| 9.5 | Common mistakes guidance | ❌ | ◐ | ◐ | ❌ | ◐ | ◐ | ❌ | ◐ | **Future** | Content-heavy; strong coaching value post-MVP. |
| 9.6 | Adjustment instructions (seat/levers) | ❌ | ❌ | ◐ | ❌ | ◐ | ❌ | ❌ | ◐ | **Future** | Deep equipment education = white space. |
| 9.7 | Equipment-aware workout/plan filtering | ◐ | ◐ | ✅ | ◐ | ◐ | ◐ | ◐ | ✅ | **MVP** | Fitbod/Caliber prove it; matches profile (§5). |
| 9.8 | Properly licensed or original media | — | — | — | — | — | — | — | — | **MVP** | Spec §9 + §23: no copied assets; produce/create ours. |

---

## §10 — Workout Experience (SIW-6 §10)

| # | Feature | St | He | Fb | RC | JF | Sv | IS | Ca | Priority | Rationale |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 10.1 | Open today's workout from plan | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ | ✅ | ✅ | **MVP** | Core daily loop. |
| 10.2 | See planned exercises for session | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Pre-session overview. |
| 10.3 | Open exercise + view instructions/media | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | In-flow guidance. |
| 10.4 | See prescribed sets/reps/rest | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Prescription display. |
| 10.5 | Start exercise; record performed set (weight/rep) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | The logging core. |
| 10.6 | Record duration where applicable | ◐ | ◐ | ◐ | ◐ | ◐ | ◐ | ◐ | ◐ | **Future** | Cardio/time-based sets; post-MVP. |
| 10.7 | Rest timer between sets | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ | **MVP** | Strong showed timer-notifications matter. |
| 10.8 | Move to next exercise / supersets | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ | **MVP** | Workflow continuity. |
| 10.9 | Complete workout + review results | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Closure + triggers history/progress. |
| 10.10 | Minimize interaction during training (speed UX) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ | **MVP** | #1 category lesson (RepCount articulation). |

---

## §11 — Set Tracking (SIW-6 §11)

| # | Feature | St | He | Fb | RC | JF | Sv | IS | Ca | Priority | Rationale |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 11.1 | Track weight / reps / sets / completed status | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Non-negotiable core. |
| 11.2 | Warm-up sets | ✅ | ✅ | ✅ | ◐ | ✅ | ✅ | ◐ | ✅ | **MVP** | Standard in gym practice. |
| 11.3 | Working sets | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Implicit core. |
| 11.4 | Drop sets / myo-reps / advanced set types | ◐ | ◐ | ✅ | ✅ | ◐ | ✅ | ◐ | ◐ | **Future** | Differentiation lane; logging complexity low but spec-optional. |
| 11.5 | Rest time recording per set | ◐ | ◐ | ◐ | ◐ | ◐ | ✅ | ◐ | ◐ | **Future** | Analytics nicety. |
| 11.6 | Per-set notes | ✅ | ✅ | ◐ | ✅ | ◐ | ✅ | ◐ | ◐ | **MVP** | Cheap, high subjective value. |
| 11.7 | Previous performance shown (pre-fill next set) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ | ✅ | **MVP** | Progressive overload crux (spec §11 example). |
| 11.8 | RPE / RIR logging | ✅ | ◐ | ◐ | ◐ | ◐ | ✅ | ❌ | ◐ | **Future** | Serious-lifter Pro feature (Strive/Strong). |

---

## §12 — Progress Tracking (SIW-6 §12)

| # | Feature | St | He | Fb | RC | JF | Sv | IS | Ca | Priority | Rationale |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 12.1 | Body weight tracking | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ | ✅ | **MVP** | Simple + motivating. |
| 12.2 | Body measurements (waist/chest/etc.) | ✅ | ✅ | ◐ | ✅ | ✅ | ✅ | ❌ | ✅ | **Future** | Content/UX cost; post-MVP. |
| 12.3 | Workout frequency + completed count | ◐ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Consistency visibility. |
| 12.4 | Exercise performance: weights & reps over time | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Core charts. |
| 12.5 | Personal records (incl. per rep range, e1RM) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | RepCount's per-rep-range PRs are the bar. |
| 12.6 | Training volume trends | ✅ | ✅ | ✅ | ◐ | ✅ | ✅ | ◐ | ✅ | **MVP** | Standard metric. |
| 12.7 | Consistency / streak metrics | ◐ | ◐ | ❌ | ◐ | ◐ | ✅ | ✅ | ◐ | **MVP** | IronStreak/Strive prove retention value; cheap. |
| 12.8 | Charts/visualizations (progress over time) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Users must "see" progression (spec §12). |
| 12.9 | Composite score (e.g., Strength Score/Balance) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | **Future** | **Gap G2/G4** — Caliber's differentiating legibility; post-MVP. |
| 12.10 | Muscle heat map / group load balance | ✅ | ◐ | ◐ | ❌ | ◐ | ◐ | ❌ | ✅ | **Future** | Nice visualization; not MVP-blocking. |

---

## §13 — Workout History (SIW-6 §13)

| # | Feature | St | He | Fb | RC | JF | Sv | IS | Ca | Priority | Rationale |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 13.1 | List of previous workouts (date, duration, status) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Spec §13 core. |
| 13.2 | Open a workout: exercises, sets, reps, weights, volume | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Full replay. |
| 13.3 | Per-workout notes | ✅ | ✅ | ◐ | ✅ | ◐ | ✅ | ◐ | ◐ | **MVP** | Low cost; supports coaching. |
| 13.4 | Completion status (completed/partial/skipped) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ | ✅ | **MVP** | Feeds calendar + reminders. |
| 13.5 | History export (CSV/JSON) | ✅ | ✅ | ✅ | ◐ | ✅ | ✅ | ◐ | ◐ | **Future** | Data ownership; post-MVP. |
| 13.6 | Unfettered history on free tier | ◐ | ◐ | ❌ | ✅ | ◐ | ✅ | ◐ | ✅ | **MVP** | Strive/RepCount/Caliber show this wins trust (G4). |

---

## §14 — Calendar / Training Schedule (SIW-6 §14)

| # | Feature | St | He | Fb | RC | JF | Sv | IS | Ca | Priority | Rationale |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 14.1 | Calendar view of training schedule | ✅ | ◐ | ◐ | ◐ | ◐ | ◐ | ◐ | ◐ | **MVP** | Simple month/week view. |
| 14.2 | Show planned workouts | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ | ✅ | ✅ | **MVP** | Plan day assignment. |
| 14.3 | Show completed workouts | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Check-off. |
| 14.4 | Show missed workouts / recovery | ◐ | ◐ | ◐ | ❌ | ◐ | ◐ | ◐ | ◐ | **MVP** | **Gap G7** — consistency visibility per spec §14. |
| 14.5 | Show upcoming workouts | ✅ | ✅ | ✅ | ◐ | ✅ | ◐ | ◐ | ✅ | **MVP** | Previews + reminders. |
| 14.6 | Reschedule/recovery on missed day | ❌ | ◐ | ❌ | ❌ | ◐ | ❌ | ❌ | ◐ | **Future** | **Gap G7** retention differentiator. |

---

## §15 — Dashboard / Home (SIW-6 §15)

| # | Feature | St | He | Fb | RC | JF | Sv | IS | Ca | Priority | Rationale |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 15.1 | Today's workout entry point | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Action first. |
| 15.2 | Next workout preview | ✅ | ✅ | ✅ | ◐ | ✅ | ◐ | ◐ | ✅ | **MVP** | Spec §15. |
| 15.3 | Current goal display | ◐ | ◐ | ✅ | ◐ | ◐ | ◐ | ◐ | ✅ | **MVP** | Motivation + goal adherence. |
| 15.4 | Weekly progress summary | ◐ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Quick status. |
| 15.5 | Recent activity / history snippet | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Continuity. |
| 15.6 | Progress metric highlights (PRs, volume, streak) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Motivational hooks. |
| 15.7 | Streak / consistency indicator | ❌ | ◐ | ❌ | ◐ | ◐ | ✅ | ✅ | ◐ | **MVP** | IronStreak benchmark; cheap + effective. |
| 15.8 | Quick access: exercise library, plan | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Navigation affordance. |
| 15.9 | Actionable-first (not stats-only) | ◐ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Spec §15 explicit. |
| 15.10 | Personalizable dashboard modules | 🟡 | ◐ | ◐ | ◐ | ◐ | ✅ | ◐ | ◐ | **Future** | Strive premium lane. |

---

## §16 — Exercise Substitution (SIW-6 §16)

| # | Feature | St | He | Fb | RC | JF | Sv | IS | Ca | Priority | Rationale |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 16.1 | Replace an exercise with an alternative | ◐ | ◐ | ✅ | ◐ | ✅ | ◐ | ❌ | ✅ | **MVP** | Spec §16; Fitbod/Caliber benchmark. |
| 16.2 | Alternatives based on muscle group | ◐ | ◐ | ✅ | ◐ | ✅ | ◐ | ❌ | ✅ | **MVP** | Core matching rule. |
| 16.3 | Alternatives based on movement pattern | ❌ | ❌ | ✅ | ❌ | ◐ | ❌ | ❌ | ✅ | **Future** | Sophisticated matching; post-MVP. |
| 16.4 | Alternatives based on equipment + user's equipment | ◐ | ◐ | ✅ | ◐ | ◐ | ◐ | ❌ | ✅ | **MVP** | Equipment-aware swap (G1 pairing with 6.6). |
| 16.5 | Alternatives based on difficulty | ❌ | ❌ | ✅ | ❌ | ◐ | ❌ | ❌ | ◐ | **MVP** | Beginner-safe swaps. |
| 16.6 | Replacement keeps workout compatible (sets/reps/rest carry) | ◐ | ◐ | ✅ | ◐ | ✅ | ◐ | ❌ | ✅ | **MVP** | Avoids plan corruption. |
| 16.7 | Respect limitation list (don't suggest avoided movements) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ◐ | **MVP** | **Gap G1** — differentiator combining §6.6. |

---

## §17 — Training Customization (SIW-6 §17)

| # | Feature | St | He | Fb | RC | JF | Sv | IS | Ca | Priority | Rationale |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 17.1 | Replace exercises in a workout | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ | ✅ | **MVP** | User agency daily. |
| 17.2 | Adjust weights (deviate from prescription) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Autonomy without breaking logic. |
| 17.3 | Add/remove sets | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Practical in-gym edits. |
| 17.4 | Modify reps where allowed | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **MVP** | Guardrailed progression. |
| 17.5 | Add notes per exercise/workout | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ | ✅ | **MVP** | Coaching + memory. |
| 17.6 | Skip exercises (mark skipped) | ◐ | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ | ✅ | **MVP** | Daily reality; feeds substitution suggestion. |
| 17.7 | Reschedule workouts | ✅ | ◐ | ◐ | ◐ | ✅ | ◐ | ❌ | ◐ | **Future** | Tied to §14.6 calendar flexibility. |
| 17.8 | Guardrails block edits that corrupt plan logic | — | — | — | — | — | — | — | — | **MVP** | Spec §17 explicit; our design constraint. |
| 17.9 | Custom exercises / themes / UI customization | ✅ | ◐ | ◐ | ✅ | ◐ | ✅ | ✅ | ◐ | **Future** | Custom exercises medium; themes polish. |

---

## §18 — Notifications (SIW-6 §18)

| # | Feature | St | He | Fb | RC | JF | Sv | IS | Ca | Priority | Rationale |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 18.1 | Workout reminder | ✅ | ✅ | ✅ | ◐ | ✅ | ✅ | ✅ | ◐ | **MVP** | Spec §18; core retention loop. |
| 18.2 | Missed-workout nudge | ◐ | ◐ | ◐ | ❌ | ◐ | ◐ | ✅ | ◐ | **MVP** | Consistency layer (G7). |
| 18.3 | Upcoming-workout preview | ✅ | ✅ | ◐ | ◐ | ✅ | ◐ | ◐ | ◐ | **Future** | Soft value; post-MVP. |
| 18.4 | Progress milestone / PR alert | ◐ | ◐ | ◐ | ◐ | ◐ | ◐ | ✅ | ◐ | **Future** | Motivational; post-MVP. |
| 18.5 | Plan completion celebration | ◐ | ◐ | ◐ | ◐ | ◐ | ◐ | ◐ | ◐ | **Future** | Gamification lane. |
| 18.6 | Consistency reminder | ◐ | ◐ | ◐ | ◐ | ◐ | ◐ | ✅ | ◐ | **MVP** | IronStreak/Strive benchmark. |
| 18.7 | Backend + frontend architecture ready for notifications | — | — | — | — | — | — | — | — | **MVP** | Spec §18: design for it, ship essentials first. |
| 18.8 | Workout-finish reminder ("did you save your workout?") | ◐ | ◐ | ◐ | ◐ | ◐ | ✅ | ◐ | ◐ | **Future** | Strive standout; post-MVP. |

---

## §19 — Admin / Content Management (SIW-6 §19)

| # | Feature | St | He | Fb | RC | JF | Sv | IS | Ca | Priority | Rationale |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 19.1 | Django admin: manage users | — | — | — | — | — | — | — | — | **MVP** | DRF/Django admin baseline. |
| 19.2 | Manage exercises + media + muscles | — | — | — | — | — | — | — | — | **MVP** | Spec §19 core; no-code content ops. |
| 19.3 | Manage equipment catalogue | — | — | — | — | — | — | — | — | **MVP** | Content ops. |
| 19.4 | Manage training plans + workouts + exercises-in-workouts | — | — | — | — | — | — | — | — | **MVP** | Plans data-driven must be admin-editable. |
| 19.5 | Manage goals & application configuration | — | — | — | — | — | — | — | — | **Future** | Config UI post-MVP; seeds manageable. |
| 19.6 | Content updates without Flutter changes | — | — | — | — | — | — | — | — | **MVP** | Spec §19 mandate; plan/exercise content from backend. |
| 19.7 | Coach/PT management lane (trainers manage clients) | — (Coach: He) | — (Coach: JF) | — | — | — | — | — | — | **Future** | Hevy Coach/JEFIT Coach/Caliber Premium; B2B lane for later. |

*(Admin rows: competitor apps keep admin internal — not user-facing — so ratings are not applicable; priority set from SIW-6 §19 requirements.)*

---

## §20 — Data Model (SIW-6 §20)

| # | Entity | Must support (for) | Priority |
|---|---|---|---|
| 20.1 | User / UserProfile | Auth, profile §5 | **MVP** |
| 20.2 | Goal | Objectives §6/§15 | **MVP** |
| 20.3 | TrainingPreference | Onboarding §6 → plans | **MVP** |
| 20.4 | Equipment + EquipmentCatalogue | Filtering §8/§9, profile §5 | **MVP** |
| 20.5 | MuscleGroup | Exercise tagging §8, heat maps §12 | **MVP** |
| 20.6 | Exercise | Library §8 | **MVP** |
| 20.7 | ExerciseMedia | Images/video §8/§9 | **MVP** |
| 20.8 | ExerciseAlternative | Substitution §16 | **MVP** |
| 20.9 | TrainingPlan / TrainingPlanDay | Plans §7 | **MVP** |
| 20.10 | Workout / WorkoutExercise | Prescription §7/§10 | **MVP** |
| 20.11 | WorkoutSet / WorkoutSession / WorkoutSessionExercise | Logging §10/§11 | **MVP** |
| 20.12 | ProgressMetric / PersonalRecord / BodyMeasurement | Progress §12, history §13 | **MVP** |
| 20.13 | WorkoutNote | Notes §11/§17 | **MVP** |
| 20.14 | Notification (scheduled/read state) | §18 backend readiness | **MVP** |
| 20.15 | Limitation / AvoidedMovement | §6.6 white-space (G1) | **MVP** |
| 20.16 | RIR/RPE + SetType (warmup/drop/myo) | Advanced sets §11.8 | **Future** |
| 20.17 | Coach/Client relation | PT lane §19.7, monetization | **Future** |
| 20.18 | Wearable/HealthConnect sync record | Recover-aware programming (G3) | **Future** |

---

## 21 — MVP vs Future recommendations (with rationale)

### MVP scope — a complete, credible personal-training loop

The MVP is a **closed loop**: register → onboard → get a plan → do workouts → log sets → see progress → stay consistent. Everything else waits.

| Priority | Feature cluster | Why (evidence) |
|---|---|---|
| **MVP** | Fast set logging with pre-fill of last performance + rest timer | The #1 category lesson; RepCount/Strong/Hevy all optimise this above all. Spec §10/§11. |
| **MVP** | Accounts (§5), Onboarding with objective + experience + equipment + limitations (§6) | Spec mandate; limitations (§6.6) is the white-space differentiator (Fitbod gap). |
| **MVP** | Data-driven training plans + starter templates (Full Body, U/L, PPL, Strength, Hypertrophy, Weight Loss, Beginner, Home) (§7) | Spec §7/§38; JEFIT/Boostcamp prove template libraries drive beginners. |
| **MVP** | Exercise DB (150–250 licensed) with muscles, equipment, difficulty, instructions, media, search/filter (§8) | Table stakes in every benchmark. Scale later; admin-extensible now. |
| **MVP** | Equipment catalogue + equipment-aware filtering (not machine deep-edu) (§9) | Fitbod/Caliber prove equipment profiling; full machine setup content is post-MVP (G6). |
| **MVP** | Workout execution: prescribed sets/reps/rest, record sets, complete, review (§10/§11) | Non-negotiable core loop. |
| **MVP** | Set basics: weight/reps/sets, warm-up, notes, completed status (§11) | Core logging. Advanced set types deferred. |
| **MVP** | Progress: body weight, exercise charts, e1RM/per-rep-range PRs, volume, streak, sessions (§12) | Progress visibility is the retention engine; IronStreak streak = cheap win. |
| **MVP** | Workout history with full replay (§13) | Spec §13; inspectability builds trust. |
| **MVP** | Calendar: planned/completed/missed/upcoming (§14) | Spec §14; missed-day visibility is our (G7) hook. |
| **MVP** | Dashboard, action-first: today/next workout, goal, weekly progress, streak, quick links (§15) | Spec §15 explicit; all benchmarks converge here. |
| **MVP** | Exercise substitution by muscle/equipment/difficulty + limitation-aware (G1) (§16) | Spec §16 + Fitbod's most-requested missing feature → our moat. |
| **MVP** | Customization within guardrails: swap exercises, adjust weights, add/skip sets, notes (§17) | Daily autonomy; spec guardrails. |
| **MVP** | Notifications: workout reminder, missed-workout, consistency (§18) | Spec §18 "essential first"; retention. |
| **MVP** | Django admin for exercises/muscles/equipment/plans/workouts (§19) | Spec §19; non-code content ops. |
| **MVP** | Relational data model (§20) + versioned API (§21) | Backend foundation; spec-wide. |

### Future scope — differentiators, paid tiers, and growth lanes

| Priority | Feature cluster | Why deferred |
|---|---|---|
| **Future** | Advanced set types: drop/myo-reps, RPE/RIR (Pro) | Spec-tolerated; Strive/RepCount gate these to Premium — natural paid tier vs1.1. |
| **Future** | Adaptive plan generation (algorithmic overload, double-progression) | Fitbod/Hevy-Trainer/JEFIT-v17 lane; strong but second release — logistics/quality risk first. |
| **Future** | Machine/equipment deep-education (setup, adjustments, common mistakes) (G6) | High content cost; clear white space but post-MVP. |
| **Future** | Composite progress score (Strength-Score-style legibility) | Caliber's differentiator; needs analytics maturity. |
| **Future** | Body measurements + muscle heat maps | Nice visual analytics; not core. |
| **Future** | Export (CSV/JSON), custom themes, custom exercises | Trust/ownership + personalization; post-MVP polish lane. |
| **Future** | Conversational / coach-lite AI ("explain why", mid-workout adaptation) | Emerging lane (PRPath/SensAI); do not hardcode now — keep API/prompt seam. |
| **Future** | Wellness sync (Health Connect/wearables) + recovery-aware programming (G3) | Ecosystem dependency; post-MVP. |
| **Future** | PT/coach management lane (Hevy Coach / JEFIT Coach / Caliber Premium analogue) | Separate B2B monetization; not MVP. |
| **Future** | Nutrition/tracking integrations | Out of scope per SIW-6; competitors diverge here. |

### Cross-cutting product principles (derived from research)

1. **Logging speed is a feature** — measure taps-to-log; pre-fill last session; numeric keypad; one-screen workout.
2. **Free tier must be genuinely useful** (unlimited logging) — the adoption engine of Hevy/RepCount/Strive/Caliber; monetize depth, not access (G4).
3. **No hardcoding** (plans/exercises) — backend-driven content so admin/content teams never touch Flutter (spec §38, §19).
4. **Privacy posture** — accounts per spec, but offline-capable logging + transparent data policy + export (G5).
5. **Medical-safety guardrails** — no medical claims; limitation-awareness in substitutions (§6.6, §7).
6. **Evidence of progress** (spec §32): charts + PR + streak are the product's proof-of-work.

---

## Appendix — How to read "has it" ratings

Ratings were compiled from the sources listed in [competitive-research.md](competitive-research.md). Cells marked `—` were not conclusively verified in public material and should be validated by the Product Manager (T-03) or the Product Analyst in-app where a specific yes/no materially changes a roadmap decision. Ratings reflect products as publicly described in August 2026 and will drift.