# Information Architecture — AI Gym Assistant

**Status:** Baseline (v1) — approved by Product Manager (SIW-8 / T-02).
**Audience:** Frontend Lead / Flutter engineers, UI/UX Lead, backend API team.
**Purpose:** the navigation model, screen inventory, and state rules that map every SIW-6
feature to a concrete screen. Flutter routes should be 1:1 with the routes column below
(SIW-6 §22 `routing/`). Terminology matches [ux-flows.md](./ux-flows.md) and the SIW-6 §20
data model.

---

## 1. Navigation model

### 1.1 Mobile (primary) — persistent shell

Bottom navigation with **4 tabs** + 1 overflown entry. Structure:

```
Shell
├── Tab 1  Home / Dashboard          (route: /home)
├── Tab 2  Plans / Schedule          (routes: /plans, /calendar)
├── Tab 3  Exercises                 (routes: /exercises, /exercise/:id)
└── Tab 4  Progress                  (routes: /progress)
Plus: Profile/More → /more  (5th entry or top-right avatar from any tab)
```

- The **More** hub holds: History, Settings, Account, Help/About (and future
  Notifications).
- Historically, History is a "meat navigation" entry; in v1 it is reachable from
  `/more`, from `/calendar`, and from Progress (session drill-down), satisfying
  Flow 6/7 within 3 taps.

### 1.2 Pre-auth & onboarding — no shell

```
/auth/login
/auth/register
/onboarding/step/1..6
/plans/onboarding (first plan pick is part of onboarding, Flow 2)
```

### 1.3 Top-level flows that span tabs

- Workout session (`/session/:sessionId`) is a **full-screen modal layer** above all
  tabs; tabs are hidden while a session is active so nothing else can distract
  mid-workout (Flow 3).
- Exercise detail is pushed from both the Exercises tab and the session set screen
  (instructions/media popover).

---

## 2. Route table (implement 1:1)

| Route | Screen | Purpose | Linked SIW-6 § | Enters from | Exits to |
|-------|--------|---------|----------------|-------------|----------|
| `/home` | Dashboard | Today card, weekly progress, recent activity, quick access | §15 | app start (auth), anywhere | session, plans, exercises, progress |
| `/plans` | Plan list / my plan | Browse + manage `TrainingPlan` | §7 | tab, onboarding | plan detail |
| `/plan/:id` | Plan detail | Days, schedule, progression rules, Start/Change | §7 | plans, dashboard | confirm start → `/home` |
| `/calendar` | Calendar | Month grid; planned/completed/missed/upcoming | §14 | Plans tab switch | day detail |
| `/day/:date` | Day detail | Sessions on a date | §13/§14 | calendar | session detail |
| `/exercises` | Exercise list + search/filter | Browse `Exercise` catalog | §8 | tab, dashboard shortcut | exercise detail |
| `/exercise/:id` | Exercise detail | Full info + machine detail | §8/§9 | exercises, session | substitution, session |
| `/progress` | Progress overview | Metrics, charts, PR list | §12 | tab | metric detail / PR drill-in |
| `/pr/:id` | PR detail | Record context, links to session | §12/§13 | progress | session detail |
| `/more` | More hub | History, settings, account, help | §13/§5 | avatar/menu | sub-screens |
| `/history` | History list | Reverse-chron sessions + filters | §13 | more, calendar | session detail |
| `/session/:id/review` | Session detail (past) | Sets, notes, repeat | §13 | history/calendar/PR | repeat workout |
| `/session/:sessionId` | Active session | Flow 3 exercise/set/rest UI | §10/§11 | home/calendar | summary `/summary/:sessionId` |
| `/session/:id/summary` | Session summary | Completion results | §10 | session | home |
| `/more/settings` | Settings | Profile/prefs/units/notifications scaffold | §5/§17 | more | — |
| `/more/account` | Account & security | Password, data, sign out | §5 | more | — |
| `/auth/login` | Login | Existing user auth | §5 | launch/expired | home |
| `/auth/register` | Register | New account + terms | §5 | login | onboarding |
| `/onboarding/step/:n` | Onboarding wizard | Flow 1 (§6) | §6 | register/resume | plan selection |

---

## 3. Screen inventory → feature map (mvs: MVP includes)

| Feature area (SIW-6 §) | Serving screen(s) | MVP? |
|------------------------|-------------------|------|
| Account/registration/login (§5) | login, register, more/account, more/settings | ✔ |
| Onboarding (§6) | onboarding/step/1–6 | ✔ |
| Training plans (§7) | plans, plan/:id | ✔ |
| Exercise database & machine info (§8/§9) | exercises, exercise/:id | ✔ |
| Workout experience (§10) | session/:sessionId (+ summary) | ✔ |
| Set tracking (§11) | session/:sessionId set screen | ✔ |
| Progress tracking (§12) | progress, pr/:id | ✔ |
| Workout history (§13) | history, day/:date, session/:id/review | ✔ |
| Calendar/schedule (§14) | calendar, day/:date | ✔ |
| Dashboard/home (§15) | home | ✔ |
| Substitution (§16) | session set screen modal + exercise/:id | ✔ |
| Customization (§17) | session (add set/skip), calendar (reschedule), settings | ✔ |
| Notifications (§18) | settings scaffold (no UI beyond prefs in v1) | ⬜ future |

---

## 4. Cross-cutting UI states (implement for every list/detail screen)

| State | Spec |
|-------|------|
| Loading | Skeleton/linear indicator; never blocks the shell for > ~1.5 s (cache-first) |
| Empty | Human message + 1 suggested action (see flow empty-states) |
| Error | Inline retry + cached fallback; never a blank screen |
| Offline / syncing | Banner "Offline — changes sync when connected"; buffered writes queue (§ Flow 0 conventions) |
| Unauthorized (401) | Global redirect to `/auth/login`, preserving intended destination |

---

## 5. Design rules locked for frontend (summary)

- 4-tab persistent bottom nav; active session hides the shell.
- Route names above are stable identifiers for the Flutter router (SIW-6 §22).
- Deep links: exercise detail and home are the only required-deep-linkable routes in v1.
- Tablet/web (responsive per §22): bottom nav → left rail at ≥ 840 dp; flows unchanged.
- Every route is typed with its data payload (id/date) so navigation arguments cannot
  be ambiguous (Frontend Lead acceptance: "no ambiguous states").

---

## 6. v1 IA acceptance (for QA)

- [ ] 4 tabs render correctly with no dead ends.
- [ ] No route reachable only from a dead-end state (all screens have exit + back).
- [ ] Session screen suppresses all notification/NAV chrome.
- [ ] History reachable ≤ 3 taps from any tab path.
- [ ] Onboarding, once finished, never re-offers itself (resume guard via `UserProfile`).