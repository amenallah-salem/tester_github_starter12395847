# UX Flows — AI Gym Assistant

**Status:** Baseline (v1) — approved by Product Manager (SIW-8 / T-02).
**Audience:** Frontend Lead / Flutter engineers (SIW-6 §22 architecture), UI/UX Lead,
QA. These flows are the implementation contract for primary user journeys. Every flow
references its SIW-6 § section; step lists are sequential and branch points are
explicit, so the frontend can build them as-is.

**Terminology (frozen, = SIW-6 §20 data model):**

| Term | Meaning in flows |
|------|------------------|
| `User` | Registered account |
| `UserProfile` | Demographic + fitness profile (height, weight, level, etc.) |
| `Goal` | The user's training objective (e.g. *Build muscle*) |
| `TrainingPreference` | Days/week, duration, location, equipment, exclusions |
| `TrainingPlan` | The program a user follows (e.g. *Push/Pull/Legs*) |
| `TrainingPlanDay` | One scheduled day inside a plan |
| `Workout` | A planned workout instance (from a `TrainingPlanDay`, or ad-hoc) |
| `WorkoutExercise` | An exercise slot inside a `Workout` (prescribed sets/reps/rest, `ExerciseAlternative` links) |
| `WorkoutSet` | One performed set record: weight, reps, duration, type, completed |
| `WorkoutSession` | One logged session of a `Workout` (started/completed), owns the set records |
| `Exercise` | Library exercise (muscle groups, equipment, instructions, media) |
| `ExerciseAlternative` | Swap relationship used by substitution (§16) |
| `PersonalRecord` | Best recorded performance for an exercise/metric |
| `ProgressMetric` / `BodyMeasurement` | Time-series progress data (§12) |

**Global conventions used by all flows**

- **Auth session:** all flows assume an authenticated `User` unless stated.
- **Loading / empty / error states are first-class:** every list/detail screen defines a
  loading spinner, a content-empty message, and a retry action. No ambiguous "blank page".
- **Optimistic updates:** set recording and quick actions update the UI immediately and
  reconcile with the API; failure shows a non-blocking toast + in-session retry row.
- **Offline tolerance:** mid-workout writes buffer locally (queue) and sync when the
  API is reachable; a banner shows "Syncing…" ([§10](/SIW/issues/SIW-6) low friction).
- **Tap targets ≥ 44 px on mobile; mid-workout controls are ≥ 80 px** for sweaty thumbs.

---

## Flow 0 — First launch / authentication (context) — [§5](/SIW/issues/SIW-6)

Preconditions: app installed, already onboarded (i.e., returning `User`).

1. App opens → sessions check (`User` token present and valid?).
2. Token valid → go to **Dashboard scan (Flow 9)**.
3. Token absent/expired and refresh fails → show **Login** screen.
4. Login branches → *authenticate* (email + password → back to Flow 9) or *forgot
   password* (email → reset link → set new password → back to Login) or *create account*
   (→ Register → Terms checkbox → → **Onboarding (Flow 1)**).
5. Error paths: invalid credentials → inline field error; network down → retry banner.
6. Post-login, if profile is incomplete (`Goal` and `TrainingPreference` missing) →
   redirect to **Onboarding continuation (Flow 1)**.

Exit criteria: user lands on Dashboard with a complete profile.

---

## Flow 1 — Onboarding — [§6](/SIW/issues/SIW-6)

Preconditions: `User` just registered (or never finished onboarding). Linear wizard,
6 steps, progress indicator on top, **Back always available**, **Skip allowed on
non-required steps** (explicitly labeled "I'll do this later").

1. **Welcome** — value pitch + "Let's set you up". CTA: *Start*.
2. **Basic profile** — age / DOB, height, weight, training experience (beginner /
   intermediate / advanced). Writes `UserProfile`.
3. **Main objective** — single-select from the §6 categories:
   Lose weight, Build muscle, Gain strength, Improve fitness, Improve endurance,
   Improve body composition, General health, Maintain fitness. Writes `Goal`
   (single primary; secondary optional).
4. **Training preferences** — days per week, preferred session duration, preferred
   time of day (optional), training location (gym / home / outdoor), available
   equipment (multi-select from `Equipment` list). Writes `TrainingPreference`.
5. **Preferences / limitations** — preferred exercise types; exercises to avoid
   (searchable selection) + free-tap "cannot do" movements. Writes exclusions onto
   `TrainingPreference` / limitation notes. *No medical claims* ([§6]).
6. **Review & start** — summary card of profile/goal/preferences → *Looks good* →
   API persists the full profile → transition to **Plan selection (Flow 2)**.

Branch points:

- Any step skipped → the corresponding defaults are assumed (profile estimated from
  age/height/weight; equipment = "full gym"; location = gym).
- Plan selection later stays consistent with the saved `Goal` and `TrainingPreference`.

Exit criteria: profile complete in backend; user sees plan onboarding screen.

---

## Flow 2 — Plan selection — [§7](/SIW/issues/SIW-6)

Preconditions: onboarding complete (Flow 1) OR user tapping "Plans/Change plan" from the
plan tab.

1. Open Plan tab (or first-run landing) → fetch `TrainingPlan` list filtered by the
   user's `Goal`, `TrainingPreference.location`, and available `Equipment` (server-side
   ranking first, e.g. *Home Training* for Fatima).
2. Render plan cards: name, description, objective badge, difficulty, duration,
   days/week, sample schedule, equipment needed. Sort: recommended → shorter duration.
3. User opens **Plan detail**: full day-by-day preview (`TrainingPlanDay` list with
   `WorkoutExercise` counts), progression-rules summary, notes.
4. Tap **Start plan** → confirmation sheet: "This replaces your current plan" (if one
   exists) → confirm.
5. API creates/points the user's weekly schedule at the plan → success → **Dashboard
   (Flow 9)** with today's `Workout` surfaced.
6. No plan matches filters → empty state with data-driven hints ("Try allowing home
   equipment" → clears filter) — never a dead end.
7. Error path: plan list load failure → retry; plan start failure → rollback note and
   stay on detail.

Exit criteria: user has an active `TrainingPlan` and a scheduled `Workout` for today.

---

## Flow 3 — Daily workout execution (low-interaction during training) — [§10](/SIW/issues/SIW-6), [§11](/SIW/issues/SIW-6)

**Principle (from [§10](/SIW/issues/SIW-6)** "minimize unnecessary interaction"** and
[§11](/SIW/issues/SIW-6)):** during a session the UI leads with one primary action per
screen. Logging a set is **1–2 taps**; eyes stay on the phone for < 3 seconds per set.
No typing required for normal sets.

Preconditions: today's `Workout` exists (from `TrainingPlanDay`); user tapped
**Start today's workout** on the dashboard.

### 3a. Session start

1. Tap **Start workout** (dashboard or plan tab) → API creates `WorkoutSession`
   (`status = started`, timestamped).
2. Session screen opens in the **App-locked, always-on** state (screen stays on).
3. On-screen header: session progress (e.g. "3 / 8 exercises"), elapsed time, plan name.

### 3b. Exercise list → current exercise

1. Session shows the ordered `WorkoutExercise` list for this session.
2. Current exercise is highlighted and auto-focuses when the previous one completes.
3. Each row shows: exercise name, target muscle(s), required equipment, planned
   `WorkoutSet` schema (e.g. *4 × 8–12*), and **previous performance** from the last
   session: "Last: 60 kg × 10/9/8" ([§11](/SIW/issues/SIW-6)).

### 3c. Set screen (primary interaction)

1. Tap exercise row → **Set screen** (or swipe right). One `WorkoutExercise` at a time.
2. Show `Exercise` media: image/video thumb + tap-to-expand instructions
   ([§8](/SIW/issues/SIW-6), [§9](/SIW/issues/SIW-6) machine setup).
3. Per set, the UI pre-fills: weight = last session's working weight; reps = prescribed
   count; type = working (unless warm-up/drop requested). One confirm tap logs it:
   `WorkoutSet {weight, reps, duration?, type, completed=true}`.
4. Tap-to-adjust zones (no keyboard): +/- weight (stepper 2.5 kg default Adult-plate
   step for barbell, 1 kg for dumbbell), reps stepper, duration picker (for
   duration-based sets).
5. Tap **✓ Done** → set saved (optimistic) → inline "Last/Now" comparison + optional
   **PersonalRecord badge** if it beat the PR ([§12](/SIW/issues/SIW-6)).
6. **Rest timer** auto-starts after `✓ Done` (rest prescribed by
   `WorkoutExercise.rest`): full-screen countdown with tap to start next set
   immediately. Skip always available: "Next set".
7. After the prescribed set count → **Finish exercise** → return to 3b list, next
   exercise highlighted. (Adding extra sets is allowed via
   [§17](/SIW/issues/SIW-6) customization: "+ Add set".)

Branch points:

- **Substitution** (equipment taken / pain) → **Flow 5** inline, returns to this set
  screen with the new `WorkoutExercise`.
- **Skip exercise** → mark skipped (recorded, not counted complete) → next exercise.
- **End session early** → confirm sheet ("Save completed sets? Yes / Discard") →
  closes session with partial sets recorded.

### 3d. Workout completion — [§10](/SIW/issues/SIW-6)

1. Last exercise finished → **Finish workout** CTA becomes the single primary action.
2. Tap → API finalizes `WorkoutSession` (`status = completed`, end timestamp,
   aggregates volume/duration) → **Summary screen**.
3. Summary shows: duration, exercises completed, sets, total volume, notes →
   **Done → Dashboard (Flow 9)**.
4. History/calendar updates immediately ([§13](/SIW/issues/SIW-6), [§14](/SIW/issues/SIW-6)).

**Mid-workout minimal-tap rules (implement as is):**

- Primary logging action is exactly **1 tap** (confirm pre-filled set) or **2 taps**
  (adjust one parameter then confirm).
- No keyboard for weight/reps in v1; steppers only. (Keyboard optional behind a
  "precision" toggle in settings [§17](/SIW/issues/SIW-6).)
- Back navigation mid-session never discards data silently.
- No notifications, no chat, no marketing surfaces during an active session.
- Session must survive app backgrounding (state restored on resume).

Exit criteria: `WorkoutSession` persisted with all recorded `WorkoutSet`s; user reaches
summary; history + dashboard reflect the completed session.

---

## Flow 4 — Exercise browse / search / filter / detail — [§8](/SIW/issues/SIW-6), [§9](/SIW/issues/SIW-6)

Preconditions: user in the Exercises tab.

1. **Browse:** exercise list (lazy-loading) grouped by muscle group with chips:
   `MuscleGroup`, `Equipment`, difficulty, movement type.
2. **Search:** full-text search on exercise name/description/instructions; debounced
   server query; results keep filter context.
3. **Filter:** multi-select chips — muscle (primary), equipment, difficulty, training
   type. Active count is visible; **Clear all** restores list.
4. **Detail:** open an `Exercise` → screen shows name, images/video thumb, description,
   primary + secondary muscles, equipment, difficulty, instructions (step-by-step),
   sets/reps/rest guidance, safety notes, alternatives preview, and any machine info
   ([§9](/SIW/issues/SIW-6)).
5. **Machine detail** (where applicable): setup steps, "how to use" movement guide,
   common mistakes, adjustments ([§9](/SIW/issues/SIW-6)).
6. Empty state: no filter matches → "No exercises found" + suggestion to relax filters.
7. Error state: query fails → retry row, results restored from cache where available.

Exit criteria: user can reach any exercise detail in ≤ 3 taps from the tab root.

---

## Flow 5 — Exercise substitution — [§16](/SIW/issues/SIW-6)

Preconditions: user is inside a session (Flow 3c) or viewing a `WorkoutExercise`
(or uses the "alternatives" link on exercise detail).

1. Trigger: tap **Swap/替代** (or "alternatives") on the `WorkoutExercise`.
2. API returns candidate `ExerciseAlternative`s ranked by: same muscle group → same
   movement pattern → available `Equipment` → difficulty similarity → user exclusions
   removed.
3. Candidate list with reason chip per item (e.g. "same movement pattern, home
   equipment ✓") + a preview of media.
4. Select candidate → confirm sheet shows what changes: exercise slot replaced, set
   schema carried over (sets/reps/rest), original exercise still recorded as
   substituted in the session log.
5. Confirm → `WorkoutExercise` now points at the new `Exercise`; continue Flow 3c.
6. No compatible candidate → clear "No compatible alternative with your equipment"
   empty state; suggest opening equipment filter; or skip the exercise.

Exit criteria: substituted exercise is logged under the new `Exercise`, session
continues without loss of set state.

---

## Flow 6 — History review — [§13](/SIW/issues/SIW-6), [§14](/SIW/issues/SIW-6)

Preconditions: at least one completed `WorkoutSession`.

1. **Calendar tab** → monthly grid: planned (dot), completed (filled), missed (dim),
   upcoming (outline) days ([§14](/SIW/issues/SIW-6)).
2. Tap a day → drill into that day's sessions. Month swipe + "Today" anchor button.
3. **Session detail:** date, duration, exercises, each `WorkoutSet` (weight, reps,
   volume), notes, completion status ([§13](/SIW/issues/SIW-6)).
4. **Your workout history** list view (alternate tab node): reverse-chronological
   compact rows → opens same session detail.
5. Filter chips: by plan, by exercise, by date range.
6. Actions from a session: *Repeat workout* (creates an ad-hoc `Workout` from that
   session's composition), *View in calendar*.
7. Empty state: "Finish your first workout to see history here" → links to dashboard.

Exit criteria: any past session reachable and inspectable in ≤ 4 taps.

---

## Flow 7 — Progress review — [§12](/SIW/issues/SIW-6)

Preconditions: at least one prior session or measurement; user in Progress tab.

1. **Progress tab** → metric cards: body weight trend (from `BodyMeasurement`), workout
   frequency, completed workouts, best weights / volume, **PersonalRecord** list.
2. Chart picker: time range (1M / 3M / 6M / all) and metric selector; renders line/bar
   charts from `ProgressMetric` series.
3. Tap a `PersonalRecord` row → the drill-in shows the historical session it was set in
   (links to Flow 6).
4. Body measurements: optional manual log (weight weekly prompt via settings).
5. Empty state: "Add a few workout sessions to unlock progress charts."
6. Error state: chart load failure → retry, cache last view.

Exit criteria: user can see trend + PRs for any tracked metric in ≤ 3 taps.

---

## Flow 8 — Settings / account — [§5](/SIW/issues/SIW-6), [§17](/SIW/issues/SIW-6)

1. Profile & preferences: edit `UserProfile` (name, DOB, height, weight, level),
   `Goal`, `TrainingPreference` (days, duration, location, equipment, exclusions).
2. Change password → verify current → new + confirm (§5).
3. Units: metric/imperial toggle (storage/unit preference).
4. Notifications preferences (blank on/off scaffold for §18 reminders).
5. Data: offline queue status, sync now, "delete my data" request, sign out.
6. Post-edit effects: changing `Goal`/equipment recomputes plan recommendations
   (Flow 2 banner when applicable) — does **not** silently replace the active plan.

Exit criteria: every §5 account function reachable here; edits persist and propagate
to flows that depend on preferences.

---

## Flow 9 — Dashboard scan — [§15](/SIW/issues/SIW-6)

Preconditions: logged in, plan active (or onboarding incomplete → simplified dashboard).

1. Dashboard loads and immediately leads with a **Today card**: today's `Workout`
   (name, # of exercises, est. duration) + single primary CTA **Start workout**
   (or "Rest day" state, or "Tomorrow: <plan day>").
2. Secondary row: weekly progress (sessions done this week / target), current `Goal`
   badge, streak/consistency where available ([§12](/SIW/issues/SIW-6)).
3. Recent activity: last `WorkoutSession` summary card → tap into Flow 6.
4. Quick access: exercise library shortcut, plan shortcut ([§8](/SIW/issues/SIW-6),
   [§7](/SIW/issues/SIW-6)).
5. Glance rule: ~5 seconds to read; prioritize *actionable* information over stats
   ([§15](/SIW/issues/SIW-6)).
6. No workout today → positive empty card ("Rest / reschedule") not a blank screen.
7. Fresh updates only when the app foregrounds (no live polling churn).

Exit criteria: dashboard always shows one obvious next action + context in <5 s.

---

## Cross-flow acceptance checklist (for Frontend Lead & QA)

- [ ] Every screen reachable in ≤ 3 taps from its tab root (Flow 4/6/7/9).
- [ ] All states specified (loading, empty, error, offline-sync) implemented per screen.
- [ ] Terminology matches the frozen table above and the DAOS data model in T-05.
- [ ] No flow leaves the user in an ambiguous state — every step has an outcome or a
      labeled branch.
- [ ] Mid-session flow meets minimal-tap rules (Flow 3).
- [ ] Substitution never silently drops the original exercise record (Flow 5).
- [ ] Rescheduling/skipping never corrupts the source `TrainingPlan` (Flow 8, §17).
- [ ] End-to-end test defined by SIW-6 §26: register → onboard → plan → workout → sets
      → complete → history → progress.

## Flow dependency map

```
Flow 0 Auth ──► Flow 1 Onboarding ──► Flow 2 Plan selection ──► Flow 9 Dashboard
                                                │
                                                ▼
                                        Flow 3 Workout execution ◄──► Flow 5 Substitution
                                                │
                              ┌─────────────────┼──────────────────┐
                              ▼                 ▼                  ▼
                       Flow 4 Exercises    Flow 6 History      Flow 7 Progress
                              │                 │                  │
                              └─────────────────┴──────────────────┘
                                        (all feed Flow 8 Settings)
```