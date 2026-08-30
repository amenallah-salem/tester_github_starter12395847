# User Personas — AI Gym Assistant

**Status:** Baseline (v1) — approved by Product Manager (SIW-8 / T-02).
**Scope:** Personas drive onboarding, plan selection, workout UX, progress, and dashboard
prioritization for v1 of the AI Gym Assistant (Flutter client + Django API).
**Alignment:** Each persona maps to the training objective categories in the SIW-6 spec
[§6](/SIW/issues/SIW-6): Lose weight, Build muscle, Gain strength, Improve fitness &
endurance, Body composition, General health, Maintain.

---

## Terminology reminder

This document uses the data-model vocabulary frozen in [SIW-6 §20](/SIW/issues/SIW-6):
`TrainingPlan`, `TrainingPlanDay`, `Workout`, `WorkoutExercise`, `WorkoutSet`,
`WorkoutSession`, `Exercise`, `ExerciseAlternative`, `Goal`, `TrainingPreference`,
`PersonalRecord`, `ProgressMetric`, `BodyMeasurement`. Frontend and backend teams must
use the same names.

---

## Persona summary matrix

| # | Persona | Primary objective(s) | Experience | Primary device | Core value |
|---|---------|----------------------|------------|----------------|------------|
| 1 | Dana "Determined" | Lose weight, Improve fitness & endurance | Beginner | Android phone | Short guided workouts, no guesswork, gentle consistency loop |
| 2 | Ben "Builder" | Build muscle, Body composition | Intermediate | Phone (Android + iOS) | Progressive overload, previous-session memory, rest timing |
| 3 | Sam "Strength" | Gain strength | Intermediate–Advanced | Phone / tablet | PR tracking, strict progression, barbell alternatives |
| 4 | Fatima "Fit For Life" | General health, Improve endurance | Beginner–Intermediate | Phone / home tablet | Home & outdoor plans, duration-based sets, streaks |
| 5 | Maya "Maintain" | Maintain, General health | Intermediate | Phone / web | 15-minute scans, low data entry, flexible rescheduling |

---

## 1. Dana "Determined"

> "I know I need to move more, but I don't want to think about it. Tell me what to do,
> how long, and whether I'm actually getting better."

- **Snapshot:** Dana, 31, marketing manager. Two jobs' worth of schedule, joins a budget
  gym near her office in January and usually fades by March — not from lack of motivation
  but from not knowing what to do next.
- **Goals:** Lose weight in a healthy, measurable way; build a habit she can keep twice a
  week; feel confident in the gym without a human coach.
- **Experience level:** Beginner. Has never followed a structured program.
- **Training frequency / style:** 2–3 days/week, 30–45 min sessions, full-body or
  weight-loss plans. Prefers machine work because it is self-explanatory.
- **Devices:** Android phone (primary), sometimes the web dashboard on her work laptop.
  Often has one hand free and a towel in the other.
- **Friction points:**
  - Overwhelmed by long lists of exercises; wants *today's workout* front and center.
  - Uncomfortable asking for help; needs clear instructions, images, and machine setup
    steps ([§9](/SIW/issues/SIW-6)).
  - Fears she "isn't doing it right" — needs completion feedback and simple progress
    proof ([§12](/SIW/issues/SIW-6), [§15](/SIW/issues/SIW-6)).
  - Time anxiety: a 30-minute workout must end after 30 minutes.
- **Features that matter most:** Onboarding wizards ([§6](/SIW/issues/SIW-6)), guided
  daily workout ([§10](/SIW/issues/SIW-6)), substitution when a machine is taken
  ([§16](/SIW/issues/SIW-6)), dashboard that leads with "today" ([§15](/SIW/issues/SIW-6)),
  progress charts that never feel judgmental ([§12](/SIW/issues/SIW-6)).
- **Design implications:**
  - One-tap start on the dashboard; the workout page is readable at a glance while
    standing at a machine.
  - Beginner-friendly tone without medical claims ([§6](/SIW/issues/SIW-6) limitation
    rules).
  - Celebrate completion ("Checked in — 2 week streak") more than raw numbers.

## 2. Ben "Builder"

> "I run a push/pull/legs split. I need to know what I lifted last time so I can add a
> rep or 2.5 kg and actually grow."

- **Snapshot:** Ben, 24, software engineer, gym member 4–5 days/week on a hypertrophy
  focus. Lifter for ~2 years; confident with barbells, dumbbells, and machines.
- **Goals:** Build muscle, shift body composition (lean bulk/cut cycles). Progressive
  overload is his explicit philosophy.
- **Experience level:** Intermediate.
- **Training frequency / style:** 4–5 days/week; PPL and upper/lower splits; 60–75 min.
- **Devices:** Phone (Android and iOS both in his household), used in one hand between
  sets; sometimes casts to his phone screen only.
- **Friction points:**
  - Loses track of *what he did last time* — enters weights that drift down.
  - Rest timing: forgets to rest long enough or starts next set too early.
  - Wants to log working sets only; warm-up sets are noise he wants to skip quickly.
  - Feels substitution must respect the movement pattern, not just the muscle
    ([§16](/SIW/issues/SIW-6)).
- **Features that matter most:** Previous-session memory on the set screen
  ([§11](/SIW/issues/SIW-6)), rest timer, set-type support (warm-up / working / drop)
  ([§11](/SIW/issues/SIW-6)), personal records ([§12](/SIW/issues/SIW-6)), flexible
  customization without breaking plan logic ([§17](/SIW/issues/SIW-6)).
- **Design implications:**
  - The set screen shows *last week's* weight immediately beside the input.
  - Keep interaction to ~2 taps per set: tap "done" or adjust one field; everything else
    auto-suggests.
  - Loading-state and empty-state polish matters: he lives in the session screen.

## 3. Sam "Strength"

> "Heavy bar work. I don't need cardio. I need to know my true max progression and never
> stall because a rack was taken."

- **Snapshot:** Sam, 35, intermediate-to-advanced lifter (5/3/1 and linear progression
  history), training for strength; occasionally trains with a barbell club and at home.
- **Goals:** Gain strength; beat personal records on squat, bench, deadlift; follow
  strict progression rules.
- **Experience level:** Intermediate–Advanced.
- **Training frequency / style:** 3–4 days/week; strength-oriented TrainingPlans with
  prescribed sets/reps and set-by-set logic.
- **Devices:** Phone; tablet at home for exercise/machine info in the garage gym.
- **Friction points:**
  - Progression rules must be enforced by the plan (e.g., "add 2.5 kg when all working
    sets hit target reps"), not left to memory ([§17](/SIW/issues/SIW-6)).
  - Barbell alternatives matter: if the platform is taken he needs a same-pattern
    substitution immediately ([§16](/SIW/issues/SIW-6)).
  - Wants long-term charts of estimated 1RM / top sets, not just volume
    ([§12](/SIW/issues/SIW-6)).
- **Features that matter most:** PR tracking and PersonalRecord record-keeping
  ([§12](/SIW/issues/SIW-6)), substitution by movement pattern and equipment
  ([§16](/SIW/issues/SIW-6)), exercise machine/setup depth for barbell movements
  ([§9](/SIW/issues/SIW-6)), history deep-dive per lift ([§13](/SIW/issues/SIW-6)).
- **Design implications:**
  - Big readable numbers, charts over time, PR badge inline when a set beats a record.
  - Minimal ceremony: no celebratory modals mid-session; show it after, in history.

## 4. Fatima "Fit For Life"

> "I work out at home and in the park. I don't have a bench, and I don't want to buy one.
> Give me a plan that fits my apartment and my asthma."

- **Snapshot:** Fatima, 28, teacher; trains in a small apartment or the local park,
  sometimes with a kettlebell and a pair of dumbbells, sometimes bodyweight only.
- **Goals:** General health, improve endurance/fitness; stay consistent near a busy
  family schedule. Avoid movements that aggravate her knee and asthma triggers.
- **Experience level:** Beginner–Intermediate (has done yoga and walking; gym machines
  are foreign).
- **Training frequency / style:** 3–4 days/week, 20–40 min, home/outdoor; duration-based
  and bodyweight/light-equipment exercises.
- **Devices:** Android phone primary; tablet mounted against the wall for instruction
  videos at home.
- **Friction points:**
  - Equipment filters are non-negotiable: a plan that requires a leg press she does not
    have will fail inside a week ([§6](/SIW/issues/SIW-6) preferences, [§8](/SIW/issues/SIW-6)).
  - Needs to exclude specific movements (knees, asthma) — limitations must be respected
    in generated plans and substitutions ([§6](/SIW/issues/SIW-6), [§16](/SIW/issues/SIW-6)).
  - Duration-based sets (rowing, bodyweight circuits) must be trackable as time, not
    weight×reps ([§11](/SIW/issues/SIW-6)).
  - Consistency is motivation: streaks and "same time next week" nudges
    ([§14](/SIW/issues/SIW-6), [§15](/SIW/issues/SIW-6)).
- **Design implications:**
  - Duration-based set entry; warm-up descriptors simplified.
  - Substitution must reason across equipment availability, not just muscle group.
  - Offline-ish tolerance for spotty home Wi-Fi.

## 5. Maya "Maintain"

> "I've trained for years and I like it, but life is loud. I need the app to get out of
> the way when I'm busy and be there when I'm committed."

- **Snapshot:** Maya, 41, product ops manager, parent of two; trained for 8+ years, has a
  clear sense of what works, alternates gym and home weeks.
- **Goals:** Maintain fitness and physique while juggling a family and travel; keep a
  truthful history without spending five minutes logging it; reschedule without guilt.
- **Experience level:** Intermediate.
- **Training frequency / style:** 2–4 days/week, variable; sometimes 45 min gym, sometimes
  20 min hotel-room session.
- **Devices:** Phone primarily; occasional web dashboards for reviewing trends.
- **Friction points:**
  - Data entry is a tax: she wants bulk "done" completion and skip-once behaviors
    ([§17](/SIW/issues/SIW-6)).
  - Rescheduling a planned Workout must not corrupt the TrainingPlan logic
    ([§17](/SIW/issues/SIW-6)), and the calendar should make missed/upcoming/done visible
    at a glance ([§14](/SIW/issues/SIW-6)).
  - Dashboard should prioritize *what changed* over a wall of stats
    ([§15](/SIW/issues/SIW-6)).
- **Features that matter most:** Calendar/schedule ([§14](/SIW/issues/SIW-6)), fast
  completion and skip ([§17](/SIW/issues/SIW-6)), dashboard Scan ([§15](/SIW/issues/SIW-6)),
  history filters ([§13](/SIW/issues/SIW-6)), account/profile settings
  ([§5](/SIW/issues/SIW-6)).
- **Design implications:**
  - A "Scan" mode that shows glanceable state in <5 seconds.
  - Batch actions (complete set of exercises, mark whole day done).
  - Reschedule interactions that persist the original plan.

---

## Persona → objective coverage check

Every SIW-6 [§6](/SIW/issues/SIW-6) objective is covered by at least one persona:

| Objective category | Persona(s) |
|--------------------|------------|
| Lose weight | Dana |
| Build muscle | Ben |
| Gain strength | Sam |
| Improve fitness & endurance | Fatima (+Dana) |
| Body composition | Ben |
| General health | Fatima, Maya |
| Maintain | Maya |

**Coverage note:** a single user may select any objective during onboarding; personas are
segment archetypes, not a restriction. The onboarding flow records one `Goal` per user
and drives plan recommendations from it ([§6](/SIW/issues/SIW-6), [§7](/SIW/issues/SIW-6)).

---

## Personas → feature priorities

| Feature area (SIW-6 §) | Prioritized **for** |
|------------------------|---------------------|
| Onboarding (§6) | Dana, Fatima |
| Training Plans (§7) | All (Sam: strict logic; Fatima: home equipment) |
| Exercise library + machine info (§8/§9) | Dana (setup clarity), Sam (barbell depth) |
| Workout experience (§10) | Dana (guided), Ben (speed) |
| Set tracking (§11) | Ben, Sam; Fatima needs duration-based sets |
| Progress (§12) | Sam (PRs), Dana (gentle proof), Ben (overload) |
| History + calendar (§13/§14) | Maya, Sam |
| Dashboard (§15) | Dana ("today"), Maya ("scan") |
| Substitution (§16) | Sam, Fatima, Dana (machine taken) |
| Customization (§17) | Maya (skip/reschedule), Ben (extra sets) |

---

## Non-goals for v1 personas

- No extreme-athlete / competition-coach persona in MVP (future: AI coaching
  personalization per SIW-6 §2 architecture note).
- No children under 16; terms required at registration ([§5](/SIW/issues/SIW-6)).
- No medical-condition management; the app never diagnoses or prescribes
  ([§6](/SIW/issues/SIW-6) limitation).