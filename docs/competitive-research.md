# Competitive Research — AI Gym Assistant / Personal Training SaaS

**Deliverable for [SIW-7](/#SIW-7) · feeds SIW-6 (Project Master Instruction, §1, §23, §34-Phase 0)** and the Product Manager (T-03) requirements baseline.

- **Author:** Product Analyst (siwar_corp)
- **Date:** 2026-08-29
- **Scope:** Positioning, core features, monetization, standout UX patterns, and gaps for the leading gym/training apps, benchmarked in 2026.
- **Method:** Public product/App Store listings, official sites, and independent 2026 reviews. Observations only; no copyrighted media or branding is reproduced (see [Sources](#sources) for links).
- **Pricing caveat:** Figures are standard US list prices observed August 2026 and change frequently by region/promotion. Always verify in-app.

All evidence is linked in [Sources](#sources). Feature-level has-or-has-not ratings live in [feature-inventory.md](feature-inventory.md).

---

## 1. Executive summary

The 2026 gym-app market splits into **four archetypes**:

1. **Minimalist loggers** — Strong, RepCount, FitNotes, Simple Workout Log. Fast set entry is the entire product; progressive-overload data is the value.
2. **Freemium social/gamified loggers** — Hevy (social feed), Strive (anti-paywall, privacy-first), IronStreak (Duolingo-style streaks/XP). Compete on free-tier generosity and retention mechanics.
3. **Adaptive/AI workout generators** — Fitbod (ML workout generation), JEFIT Adaptive Plan + AI Progressive Overload (v17), Alpha Progression (RIR-based progression engine), Hevy Trainer (algorithmic programming). Compete on "open app → workout appears".
4. **Coaching platforms** — Caliber (human coaches + free self-coaching tier), Coach-side products (Hevy Coach, JEFIT Coach), TrainHeroic. Compete on accountability and programming expertise.

### Key market takeaways

- **Logging speed is the #1 differentiator.** Every serious tracker optimises "log a set in a few seconds" with pre-filled last-session weight/reps, a numeric keypad, and a rest timer. ("Get out of your way between sets" — [RepCount, 2026](https://www.repcountapp.com/articles/best-workout-tracker-android).)
- **Free tiers are the battleground.** Generous free tiers (Hevy, RepCount, Strive, IronStreak, Caliber, Boostcamp) drive adoption; premium locks analytics, unlimited routines, social extras, and advanced set types. Strong/JEFIT/Fitbod gate more basics.
- **"AI" is now table stakes for differentiation, but mostly algorithmic.** Fitbod and Hevy Trainer generate *programs in advance*; conversational coaching is only just emerging (PRPath Atlas, SensAI-class LLM coaches). Few apps adapt *mid-session*.
- **Retention/gamification and habits are a real wedge.** Streaks, XP, achievements (IronStreak), social accountability (Hevy), and workout-finish/moderation reminders (Strive) all target the 90-day churn problem.
- **Progress/analytics are increasingly paywalled but expected.** Charts, PRs across rep ranges, e1RM, volume, muscle heat maps differentiate tiers.
- **Privacy-first and no-account models are emerging** (Strive, IronStreak): local-only storage as a marketing claim against the bigger data-collecting apps.
- **PT/coach economics are a separate monetisation lane** (Hevy Coach, JEFIT Coach, Caliber Premium at ~$200/mo) — relevant to a Personal-Training SaaS ambition.

---

## 2. Benchmark app deep-dives

### 2.1 Strong (strong.app)

- **Positioning:** The minimalist, battle-tested workout logger ("Everything you need. Nothing you don't."), ~5M users since 2014; frequently featured by Apple/CNET. iPhone-first historical reputation, now cross-platform iOS + Android + Apple Watch/Wear OS.
- **Core features:** Fast set logging with pre-filled previous performance; custom routines (3 free), supersets, warm-up calculator, plate calculator, rest timers (customisable), RPE, notes + progress pictures, body measurements with Apple Health, CSV/data export (Email/Notes sharing), advanced charts, muscle heat map, workout scheduling, Siri Shortcuts and 3rd-party integrations, dark mode.
- **Monetisation:** Free (unlimited workouts, capped at 3 custom routines) → Pro $4.99/mo or $29.99/yr. Historically the cheapest serious paid tier; no lifetime SKU on current listings.
- **Standout UX:** Extremely low-friction set entry; excellent rest-timer UX with notifications; watch app rebuilt (v6.2, March 2026).
- **Gaps:** No AI coaching/programme generation; no nutrition; no social; web version still unshipped (as of mid-2026); free-tier routine cap of 3 is the smallest of the loggers; slow feature cadence per community feedback.

### 2.2 Hevy (hevyapp.com)

- **Positioning:** "The #1 free workout tracker", ~10–14M users, the strongest free tier *and* the strongest social layer: public profiles, follow, likes/comments, community feed, workout sharing. Cross-platform: iOS, Android, Apple Watch, Wear OS, and web.
- **Core features:** Unlimited logging; routine builder with folders; 3-month graph history (free); exercise library with GIF/video demos; personal records; volume tracking; body measurements; rest timer; custom exercises (7 free); social feed; **Hevy Trainer** (Feb 2026) algorithmic programme generator + auto weight progression; **Hevy GPT** optional ChatGPT workflow; Hevy Coach (separate PT product).
- **Monetisation:** Free (4 routines, 7 custom exercises, 3-month history cap) → Pro $2.99/mo, $23.99/yr, or $74.99 lifetime (secondary $3.99/mo SKU exists). Hevy Coach for trainers ~$9.99/mo. No ads in free tier (per ICON review).
- **Standout UX:** Fast logging; "copy from previous set"/keyboard ergonomics; generous, genuinely usable free tier that acts as the top of the funnel; community accountability layer.
- **Gaps:** Beginner guidance is thin (logger, not a coach); analytics depth paywalled; no nutrition/wearable-recovery integration; Hevy Trainer is algorithmic, not conversational/adaptive mid-workout.

### 2.3 Fitbod (fitbod.me)

- **Positioning:** The benchmark adaptive/AI workout generator, premium-priced. Creates daily workouts from goals, fitness level, history, muscle-recovery state, and available equipment. 1,000+ exercise library.
- **Core features:** AI-generated workouts; muscle-recovery map (avoids re-training tired groups); equipment-aware programming across multiple gym profiles (commercial gym → garage → hotel); progressive overload (auto bumps weight/reps/sets); equipment-aware exercise substitution; plate calculator; rest timer; warm-up sets; supersets; set logging; personal records; weekly analytics; Apple Watch app; Apple Health sync; offline.
- **Monetisation:** No permanent free tier — 7-day trial / ~3 free workouts, then $15.99/mo or $95.99/yr (2026 pricing; legacy $12.99/$79.99 for existing subscribers). Annual ≈ $8/mo effective. Reviewed as "coach prices".
- **Standout UX:** The muscle-recovery map and equipment-aware substitution are category-best; polishing of the "open the app and a workout is ready" pattern.
- **Gaps:** Pre-plans the session but does not adapt set-by-set; no explanation of "why" (no conversational coaching); no HRV/sleep/readiness inputs; injury/exclusion filter is the most-requested missing feature; premium price with a thin free allowance; no periodization depth for advanced lifters.

### 2.4 RepCount (repcountapp.com, Siper Apps AB, Sweden)

- **Positioning:** The lean, fast, native logger built by a solo lifter since 2013; 2M+ downloads; Apple "Apps We Love"; positioning emphasises unlimited free basics and 4.8–4.9★ ratings. Native Swift (iOS) + Kotlin (Android), Health Connect sync.
- **Core features:** Unlimited free workouts, routines, and custom exercises with no ads; pre-filled last-session values; single-page workout layout (no drilling in/out per exercise); history accessible mid-workout; rest timer; supersets/drop sets; PRs tracked across *every rep range* (not just 1RM); measurements; Apple Health/Health Connect.
- **Monetisation:** Free (complete logger) → Premium $29.99/yr ($3.99–4.99/mo) for charts/statistics (e1RM trends, volume, heaviest weight), supersets/drop sets.
- **Standout UX:** One-screen workout view; ultra-fast numeric entry; "show me what I did last time" is core, not premium.
- **Gaps:** No web app; no social/community; no coaching or programme generation; analytics not visual-first in free tier; single-developer scale/velocity.

### 2.5 JEFIT (jefit.com)

- **Positioning:** The data-heavy, community-grounded platform; 10M+ users; famous for the largest exercise library (1,400+ exercises with instructions/animations) and a community training-plan marketplace. Web + iOS + Android.
- **Core features:** Massive exercise database with video demos; routine builder + plan marketplace/templates; detailed logging and analytics (volume, consistency, 1RM, body-part measurements); rest timer; smartwatch (Wear OS/Apple Watch) logging; body measurement logging; Strava/Apple Health sync; add-ons/audio cues; Iron Points gamification (redeem for Elite); Apple Watch trial.
- **Monetisation:** Free (ad-supported, feature gates; stats beyond ~14 days gated) → Elite $12.99/mo or $69.99/yr (intro-offers bespoke); Coach tiers $14.99–24.99+ for up to 5/10 clients.
- **2026 direction:** v17 (April 2026) added **Adaptive Plan**, **AI Progressive Overload**, and an **NSPI score** — an algorithmic programming layer over the old template library.
- **Standout UX:** Exercise database depth (guidance + animations) is the moat; cross-device sync (plan on web, log on phone).
- **Gaps:** Interface feels cluttered/dense vs modern loggers; free tier gates broad features behind ads and short analytics windows; overcomplex for beginners who just want to log.

### 2.6 Strive (strive-workout.com, solo dev "Artur")

- **Positioning:** "The workout tracker that doesn't paywall the basics" — the anti-SaaS freemium logger. Unlimited routines, full history, advanced charts, no ads, "free forever"; privacy-first with on-device/local data; used in 100+ countries, 1M+ workouts logged, 4.9★.
- **Core features:** Fast 2-second set logging; all set types (warm-up, dropset, myo-reps…); unlimited routines free; advanced charts free; personalised dashboard/heatmap; bodyweight & measurements tracking; workout sharing/export free; workout plans & day scheduling (Pro); RIR/RPE and effective-reps analytics (Pro); Apple Health + Health Connect sync (Pro); themes + theme creator (Pro); home-screen widgets (Pro); workout-finish reminder; offline; custom exercise library.
- **Monetisation:** Free (complete tracker forever) → Pro (RIR/RPE, effective reps, Health sync, plans/schedules, themes, widgets) at local-currency in-app pricing (approx. $2–4/mo class). No ads, no data selling.
- **Standout UX:** Honours "basics are free" positioning at a level that pressures incumbents; custom input keyboard with copy/increment/decrement; privacy-first + fully offline.
- **Gaps:** Local-only data = no automatic cloud sync across devices; small team velocity on AI/programme generation; iPhone/iOS showcase with Android slightly newer.

### 2.7 IronStreak (ironstreak.com)

- **Positioning:** "Duolingo for the Gym" — iOS-only, gamified strength tracker. Retention/gamification is the product: streaks, XP, 20 levels (Newbie→Olympian), 50 achievements across 5 categories with trophy tiers. No account, no analytics, all data on-device.
- **Core features:** Workout logging (91-exercise library across 6 muscle groups); streak + streak freeze; XP multipliers; e1RM tracking + PR trends; achievements; Live Activity/Dynamic Island; renamed mid-session workouts; form cues; custom exercises.
- **Monetisation:** Free (full tracking) → Pro $3.99/mo (7-day trial) for unlimited routines + full history. No account, no cloud.
- **Standout UX:** Gamification mechanics (freeze days, loss-aversion streak, variable rewards) aimed directly at the 90-day churn problem; zero-friction sign-up (no account).
- **Gaps:** iOS-only; small exercise library (91); no plans/programmes or PT layer; local-only data; Pro gates routine count + history in a maximal way for a "free-first" brand.

### 2.8 Caliber (caliberstrong.com)

- **Positioning:** The science/coaching platform: free self-coaching strength app + optional certified human-coach tiers. "Average Caliber member achieves at least a 20% improvement to body composition within 3 months"; TrustPilot 4.9 (880+ reviews). Men's Journal "best free workout app of 2026" per FitCraft comparison.
- **Core features:** Free tier: full workout logging, 600+ exercise library with demo videos, progressive overload auto-suggestion, **Strength Score** and **Strength Balance** metrics (progress vs. potential and left/right, push/pull balance), strength goals, no ads. Plus tier: group coaching/community (~$20/mo). Premium: certified human coach + nutrition coach — personalised programme, weekly check-ins, form-video reviews, in-app messaging (≈$50–$300+/mo; ~$199/mo typical).
- **Monetisation:** Freemium (free tracking/library) → Plus ≈$20/mo → Premium human coaching ≈$50–300+/mo. App-store subscriptions ("Caliber Supporter", £3/mo) as a small-gratitude tier.
- **Standout UX:** The Strength Score/Balance metrics make progress legible and coach-accountable; strong free tier for self-guided lifters; premium lanes for coaching.
- **Gaps:** No fully automated AI coaching at app-tier prices on the strength side; premium human coaching is expensive (coach prices); wearable/recovery integration mostly absent (Apple Watch app is a requested feature).

### 2.9 Other materially relevant apps (2026)

| App | Relevance | Notes |
| --- | --- | --- |
| **Boostcamp** (boostcamp.app) | Program library | 100+ science-based/community programmes (nSuns, GZCLP, PPL…) integrated with logging; generous free tier; RPE/RIR + advanced features premium. |
| **Alpha Progression** (alphaprogression.com) | Progression engine | RIR-based auto advancement of weight/reps/sets; analytics; ~$9.99/mo pro. |
| **FitNotes** | Free Android logger | Completely free, no ads — but dated UI, no cloud sync, no premium revenue = slow updates. |
| **StrengthLog** | Coach-written programs | All-in-one programs + log; premium $12.99/mo / $109/yr (expensive outlier). |
| **Gymshark Training** | Free guided plans | 100% free iOS app; brand-led guided plans/videos; weak analytics; iOS-only. |
| **PRPath / Atlas** | Conversational AI | LLM chat coach + nutrition/fasting; 8.99/mo or 39.99/yr; signals the new "explain WHY" AI lane. |
| **Freeletics** | AI journeys | 12–16 week coach "journeys", points/leaderboards, bodyweight+HW focus; $12.99/mo class. |
| **Future** | Human coaching | $199/mo human-coach product — the high-end benchmark Caliber targets. |
| **TrainHeroic** | Coach platform | Coach-side programming/team/track tools; the B2B/PT benchmark. |

---

## 3. Cross-app pattern synthesis (what "modern gym app" means in 2026)

These patterns inform [feature-inventory.md](feature-inventory.md) priorities.

1. **Fast logging loop** — pre-filled last-session data, numeric keypad, one-screen workout, inline history, rest timer. Non-negotiable core.
2. **Exercise discovery with rich guidance** — searchable/filterable library (muscle, equipment, difficulty, movement type), instructions + images/video/animation, alternative exercises. Depth here (JEFIT, Fitbod) is a differentiator.
3. **Programme plans, data-driven** — plans are backend/coach-authored templates (never hardcoded), with defined days, exercises, sets/reps/rest/progression rules; advanced lanes add algorithmic (Fitbod/Hevy Trainer/JEFIT v17) progression.
4. **Progress analytics** — charts for weight/volume/e1RM/PRs; body measurements; consistency/streaks; muscle heat maps; "Strength Score"-style composite legibility (Caliber) is a rising differentiator.
5. **History that is inspectable** — full workout replay (date, duration, sets, weights, volume, notes) and export (CSV/JSON) for data ownership.
6. **Calendar/schedule + reminders** — planned vs completed vs missed visibility; workout reminders/finish reminders; notifications are retention-critical.
7. **Retention mechanics** — streaks, XP/levels, achievements, social feed, share cards. Directly target the 90-day churn problem that dominates the market.
8. **Customization within guardrails** — custom exercises, routine editing, exercise substitution (equipment-aware), themes, units (kg/lb), but never arbitrary edits that break plan logic.
9. **Offline-first + privacy posture** — on-device operation, no forced account, clear data policy, export; privacy is emerging as a competitive wedge.
10. **Progressive monetisation without breaking the core** — generous free core; premium sells depth (analytics, unlimited routines, advanced set types, coaching, social extras), not access to meaningful tracking.

---

## 4. Competitive gaps / white space (opportunities for our product)

| # | Gap observed across the market | Opportunity |
| --- | --- | --- |
| G1 | **No injury/exclusion filter in most generators** (Fitbod's most-requested missing feature; Hevy/Strong don't coach beginners). | Onboarding captures "exercises to avoid/limitations" (SIW-6 §6) → power substitutions and plan generation. True MVP differentiator. |
| G2 | **Adaptive programming rarely adapts mid-session** and rarely explains "why" (Fitbod pre-plans; Hevy Trainer algorithmic). | Progressive "coach-like" guidance with transparent rationale; set-by-set RIR/RPE feedback surface. |
| G3 | **Recovery/wearable signals rarely inform programming** (sleep/HRV absent in Fitbod/Hevy; only emerging LLM coaches use them). | Roadmap: wearable-lite inputs (rest-between-sets, perceived fatigue) into load recommendations. |
| G4 | **Free tiers cap routines/customs/history** (the industry's standard pain). | Differentiate with unlimited basics or clearly bounded-but-fair caps; journal honesty about gating. |
| G5 | **No-account/privacy-first is under-served** (only Strive, IronStreak). | Since our spec requires accounts (SIW-6 §5), offer explicit export + transparency and offline-capable logging as a half-way privacy posture. |
| G6 | **Machine/equipment education is thin** (SIW-6 §9 "what machine is this, how to set up") — most libraries show exercise but not machine setup/adjustment. | Original equipment/machine pages (setup, adjustment, mistakes) is a clear white space. |
| G7 | **Missed-workout and consistency recovery flows are shallow** — reminders exist, but "get back on plan" rescheduling is rare. | Calendar (SIW-6 §14) + reschedule/recovery nudges as a retention differentiator. |
| G8 | **Small, solo, or niche apps dominate "care"** (RepCount, Strive, IronStreak); big platforms feel generic. | A focused, honest personal-training assistant position: accountability + consistency + guidance. |

---

## 5. Monetisation benchmarks (for pricing strategy, T-03 to refine)

| App | Free tier | Paid | Pace |
| --- | --- | --- | --- |
| Strong | Unlimited workouts; 3 routines | $4.99/mo · $29.99/yr | Subscription |
| Hevy | Unlimited logging; 4 routines, 7 customs, 3-mo history | $2.99/mo · $23.99/yr · $74.99 lifetime | Subscription / lifetime |
| Fitbod | ~3 workouts / 7-day trial only | $15.99/mo · $95.99/yr | Subscription |
| RepCount | Complete logger, unlimited basics | $29.99/yr (≈$3.99/mo) | Subscription |
| JEFIT | Ad-supported, gated | $12.99/mo · $69.99/yr · Coach tiers | Subscription |
| Strive | Complete tracker forever | Pro: RIR/RPE, health sync, plans, themes (≈$2–4/mo class) | Subscription |
| IronStreak | Full tracking | $3.99/mo (unlimited routines/history) | Subscription |
| Caliber | Full tracking + library | Plus ≈$20/mo · Premium ≈$50–300+/mo (human coach) | Freemium → coaching |
| Boostcamp | Most popular programs free | Premium: all programs, RPE/RIR, no ads | Freemium |
| StrengthLog | Capable free | $12.99/mo · $109/yr | Freemium |

**Implication basket:** $3–12/mo is the competitive band for pure logging; $15–20/mo for AI generation; $50–300/mo for human coaching. Our AI Gym Assistant can land in the "generator + coach-lite" band (~$10–15/mo) with a genuinely useful free tier (unlimited logging, bounded extras) as a funnel.

---

## 6. Sources

Primary product/marketing pages (accessed 2026-08):
- Strong: https://www.strong.app/ · App Store listing: https://apps.apple.com/ca/app/strong-workout-tracker-gym-log/id464254577
- Hevy: https://www.hevyapp.com/ · features: https://www.hevyapp.com/features/ · Sensortower (pricing/SKUs): https://app.sensortower.com/overview/1458862350?country=US
- Fitbod: https://fitbod.me/ · App Store listing: https://apps.apple.com/is/app/fitbod-workout-gym-planner/id1041517543
- RepCount: https://www.repcountapp.com/ · Android guide: https://www.repcountapp.com/articles/best-workout-tracker-android · iPhone guide: https://www.repcountapp.com/articles/best-workout-tracker-iphone · free-tier guide: https://www.repcountapp.com/articles/best-free-workout-tracker-iphone
- JEFIT: https://www.jefit.com/ · Elite plans: https://www.jefit.com/elite · App Store listing (SKUs + features): https://apps.apple.com/gb/app/jefit-gym-workout-planner/id449810000
- Strive: https://strive-workout.com/ · App Store listing: https://apps.apple.com/us/app/gym-log-strive/id6449553638
- IronStreak: https://ironstreak.com/ · pricing: https://ironstreak.com/pricing · features: https://ironstreak.com/features
- Caliber: https://www.caliberstrong.com/ · App Store: https://apps.apple.com/gb/app/caliber-strength-training/id1482405410

Independent 2026 reviews/comparisons used for verification (accessed 2026-08):
- Strong App Review 2026 (PRPath): https://prpath.app/blog/strong-app-review-2026.html
- Hevy Review 2026 — Pricing & Free vs Pro (SensAI): https://www.sensai.fit/blog/hevy-review-2026
- Hevy Review 2026 (ICON): https://iconpolls.com/blogs/hevy-review-2026-app-profile-login-coach-free-cost-pro-user-experience-frequently-asked-questions
- Fitbod Review 2026 (SensAI): https://www.sensai.fit/blog/fitbod-review-2026
- Fitbod App Review 2026 (Autonomous): https://www.autonomous.ai/ourblog/fitbod-app-review
- Fitbod Review: Features, Pricing, Pros and Cons in 2026 (Lasta): https://lasta.app/blog/fitbod-review/
- JEFIT review/features (ToolsInfo): https://sports.toolsinfo.com/tool/jefit
- Strive best-workout-log-apps roundup: https://strive-workout.com/2026/04/05/best-workout-log-apps/
- IronStreak "Best Workout Tracker Apps for the Gym (2026)": https://ironstreak.com/blog/best-workout-tracker-2026
- IronStreak "Best Gamified Workout Apps in 2026": https://ironstreak.com/blog/best-gamified-workout-apps
- Caliber App Review After 21 Days of Testing (Garage Gym Reviews): https://www.garagegymreviews.com/caliber-app-review
- Caliber (2026): Online Coaching with Real Trainers — Features, Pricing, Limits (Cora): https://www.corahealth.app/compare/caliber
- Fitness App Subscription Pricing Comparison 2026 (FitCraft): https://getfitcraft.com/compare/fitness-app-subscription-pricing-comparison-2026
- Hevy Pricing 2026 (PulseSignal): https://getpulsesignal.com/pricing/hevy
- Free Workout Tracker App picks & reviews 2026 (Strive blog): https://strive-workout.com/2026/01/15/free-workout-tracker-app

**Compliance note:** This report contains observations, summaries, and links only. No logos, screenshots, branding assets, or other copyrighted media from the benchmarked apps are reproduced in this repository.