# AI Gym Assistant

A SaaS personal-training application for **siwar_corp**: account, fitness profile,
objectives, training plans, exercise library, workout execution, set tracking,
progress, history, and calendar. A real production-quality product (Flutter +
Django REST Framework, Docker, CI/CD, Android/iOS builds), not a prototype.

> This README is a bootstrap placeholder. The authoritative product definition is
> the [Product Requirements Document](docs/prd.md) — the acceptance basis for all
> phases. See the [docs index](docs/index.md) for the full documentation set.

## Product

- **Frontend:** Flutter + Dart (Android, iOS, Web where practical)
- **Backend:** Django + Django REST Framework, PostgreSQL, Docker
- **Configuration:** environment-specific API base URL via Flutter flavors
  (`development` / `staging` / `production`); never hardcoded
- **Content:** all plans/exercises are backend-driven and admin-editable; no
  hardcoded content in the Flutter app

## Why it exists

The starting `index.html` hello-world is the GitHub bootstrap. The project is
being built out per the [PRD](docs/prd.md) (Phase 0: research + product
definition), then backend, Flutter app, CI/CD, builds, and release docs.