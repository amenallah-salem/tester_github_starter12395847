# Hello World

A minimal "Hello, World" HTML app for **siwar_corp** — the seed repo for the Siware (Siwar) AI Gym Assistant / Personal Training SaaS product.

Open `index.html` in any browser, or serve the folder with any static file server.

## Project status

This monorepo will evolve into the full **AI Gym Assistant** stack per the [SIW-6](https://github.com/amenallah-salem/tester_github_starter12395847) project master instruction:
Flutter (Android/iOS/Web), Django + DRF backend (Docker/PostgreSQL), GitHub Actions CI/CD, versioned REST API, and docs.

## Product documentation (Phase 0 — Research & Product Definition)

- [Competitive Research Report](docs/competitive-research.md) — 2026 benchmarks of Strong, Hevy, Fitbod, RepCount, JEFIT, Strive, IronStreak, Caliber and related apps: positioning, features, monetization, UX patterns, gaps.
- [Feature Inventory](docs/feature-inventory.md) — full feature matrix mapped 1:1 to SIW-6 spec sections (accounts → data model), with MVP vs Future priority and rationale.

More docs (architecture, backend, frontend, API, database, testing, CI/CD, deployment) land here as the project phases complete.

## Repository layout

```
index.html          # current placeholder app
README.md           # this file
docs/               # phase-0 product & research docs
```

## CI

Every pull request runs a documentation check via GitHub Actions (`.github/workflows/docs.yml`).