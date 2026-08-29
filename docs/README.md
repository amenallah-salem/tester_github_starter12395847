# Architecture Documents

Central index for the AI Gym Assistant architecture docs (SIW-6 Phase 1 — Architecture).

> Docs here are cross-referenced between owners. Tick marks indicate content authored/owned; the
> authoritative copy lives in the linked file.

## Auth, Environments, CI/CD (T-08 — CTO)

| Document                 | Contents                                                              |
| ------------------------ | --------------------------------------------------------------------- |
| [`auth-strategy.md`](auth-strategy.md) | JWT access/refresh flows, token lifecycle, session persistence, refresh-on-401 single-flight, security notes |
| [`environments.md`](environments.md) | SIW-6 §4 env matrix, `--dart-define` + flavors, Django `DJANGO_ENV`/`ALLOWED_HOSTS`/`CORS`, local-LAN dev playbook |
| [`ci-cd.md`](ci-cd.md)   | GitHub Actions pipeline stages, artifacts, iOS signing, releases, versioning |
| [`adr/0001-ci-tooling-and-build-signing.md`](adr/0001-ci-tooling-and-build-signing.md) | Decision: CI tooling + Android/iOS build/sign approach |
| [`adr/0002-environment-and-configuration.md`](adr/0002-environment-and-configuration.md) | Decision: `--dart-define` + flavors + `DJANGO_ENV` mechanism |

## Product & UX (T-01..T-03 — Marketing/PM)

| Document                 | Status      |
| ------------------------ | ----------- |
| `competitive-research.md`, `feature-inventory.md` (T-01) | in progress |
| `personas.md`, `ux-flows.md`, `information-architecture.md` (T-02) | in progress |
| `prd.md` (T-03)          | in progress |

## Backend (T-05, T-07 — Backend Lead)

| Document                 | Status      |
| ------------------------ | ----------- |
| `backend-architecture.md`, `data-model.md` (T-05) | in progress |
| `api-contract-v1.yaml`, `api.md` (T-07)           | in progress |

## Frontend (T-06 — Frontend Lead)

| Document                 | Status      |
| ------------------------ | ----------- |
| `flutter-architecture.md` (T-06) | in progress |

## Implementation handoff

- Auth flows → backend T-09/T-13, frontend T-10/T-15 (see `auth-strategy.md` §6).
- Env config → backend T-09 / T-11, frontend T-10/T-15 (see `environments.md` §5).
- CI/CD → DevOps T-11 / T-34 / T-35 / T-36 (see `ci-cd.md` §10).