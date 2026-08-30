# Contributing

Welcome! This repo (siwar_corp's AI Gym Assistant) is a monorepo. This guide defines the repository conventions every contributor should follow. CI quality gates are enforced in later CI tasks (see `docs/ci-cd.md`); for now the guards here are convention-only so scaffolding phases can land.

## Branch naming

Use a short, scoped, hyphenated branch name from `main`, prefixing with the primary area:

| Area | Prefix | Example |
|---|---|---|
| Architecture / repo | `arch/` | `arch/t-04-monorepo-scaffold` |
| Backend | `backend/` | `backend/accounts-auth` |
| Frontend (Flutter) | `fe/` | `fe/workout-screen` |
| DevOps / CI | `devops/` | `devops/ci-foundation` |
| Docs | `docs/` | `docs/api-contract` |
| Bugfix | `fix/` | `fix/login-refresh` |

Avoid long-lived branches; branch off `main`, keep the branch small and reviewable, and open a pull request early.

## Commit messages

- Imperative mood, concise subject line (≤ 72 chars), body explaining the *why* when useful.
- Reference the ticket when applicable, e.g. `T-04 scaffold monorepo structure`.
- Each commit is signed off / co-authored as required by team policy.

Example:

```
T-04 scaffold monorepo structure

Add backend/, app/, docs/, and .github/ scaffolding with placeholder
READMEs so later phases can build incrementally.
Co-Authored-By: Paperclip <noreply@paperclip.ing>
```

## Pull requests

- Open PRs against `main`.
- Use the pull-request template (`.github/pull_request_template.md`); fill in summary, changes, testing, and evidence.
- Link the related ticket (e.g. `SIW-10`) in the PR body.
- Keep PRs focused; split large changes into separate PRs.
- A PR is mergeable when changes are reviewed and (once CI lands) all checks pass.

## Code & structure conventions

- Follow the layout in the root `README.md` and `docs/architecture.md`.
- Backend: Django apps live under `backend/apps/`; keep each domain app focused.
- App: Flutter features live under `app/lib/features/`; shared code in `core/`, `config/`, `models/`, `services/`, `repositories/`, `state/`.
- Never commit secrets, tokens, `.env` files, or build artifacts (see `.gitignore`).
- Empty directories carry a placeholder `README.md` so the structure survives git.

## Quality gates

Per the project plan, a task is "done" only when: implementation complete, tests pass, docs updated, evidence captured, PR opened, and CI passes. CI enforcement is added in the CI foundation task; until then reviewers check these manually.
