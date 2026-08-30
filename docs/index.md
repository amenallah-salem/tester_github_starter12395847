# Documentation Index — AI Gym Assistant

Central index for siwar_corp's product + engineering documentation for the AI Gym
Assistant (Flutter + Django). Built per [SIW-6](/SIW/issues/SIW-6) §31 (`docs/`),
currently landing PHASE 0 research & product-definition artifacts.

## Product & UX (PHASE 0)

| Doc | Purpose | Source |
|-----|---------|--------|
| [Personas](personas.md) | 5 user personas mapped to training objectives, experience levels, devices, friction points | SIW-8 / T-02 |
| [UX flows](ux-flows.md) | Primary flows as implementable step lists with minimal-tap mid-workout rules (references SIW-6 §5–§17) | SIW-8 / T-02 |
| [Information architecture](information-architecture.md) | Navigation model, route table, screen inventory, cross-cutting states | SIW-8 / T-02 |

## Upstream authority & related research

- **Project master instruction:** [SIW-6](/SIW/issues/SIW-6) — source of every section
  reference (§5–§39) used by the docs above.
- **Competitive research & feature inventory:** `competitive-research.md` +
  `feature-inventory.md` (T-01, SIW-7).
- **Product Requirements Document:** `prd.md` (T-03, SIW-9; depends on T-01 + T-02).

## Planned docs tree (landing in later phases)

Per [SIW-6](/SIW/issues/SIW-6) §31 — `architecture.md`, `development.md`,
`backend.md`, `frontend.md`, `api.md`, `database.md`, `testing.md`, `deployment.md`,
`ci-cd.md`, `releases.md`, `troubleshooting.md`. Each phase links its deliverables
here as they land.

## Terminology

The single source of truth for nouns (`TrainingPlan`, `Workout`, `WorkoutExercise`,
`WorkoutSet`, `WorkoutSession`, `Exercise`, `ExerciseAlternative`, …) is
[SIW-6](/SIW/issues/SIW-6) §20; every doc above uses it consistently.

## How to update this index

When a document is added, moved, or renamed, update this file in the same commit so
the index never goes stale.