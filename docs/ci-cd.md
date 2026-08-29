# CI/CD Architecture

Applies to: **SIW-6 §27 (CI/CD), §28 (Android build), §29 (iOS build), §30 (releases)**, implemented
by DevOps Lead in **T-11 / T-34 / T-35 / T-36**.

Decision record: `docs/adr/0001-ci-tooling-and-signing.md` (this doc is the "how"; the ADR is the "why").

## 1. Overview

- **Platform:** GitHub Actions (repo already on GitHub; `ubuntu-latest` for backend/lint/Android,
  `macos-14` for iOS).
- **Environments:** GitHub **Environments** (`staging`, `production`) gate deploy/release jobs and
  hold per-environment secrets.
- **Version trigger:** SemVer tag `vX.Y.Z` (or `workflow_dispatch` with a version input) for
  releases; every PR runs the full check suite.

```
PR / push to main
        │
        ▼
┌─────────────────── ci.yml ───────────────────┐
│ checkout → setup → lint → backend tests →    │
│ flutter analyze/test → security scans →      │
│ PR build validation (debug apk)              │
└──────────────────────────────────────────────┘
        │ (merge to main / tag vX.Y.Z)
        ▼
┌─────────────── release.yml ──────────────────┐
│ backend release build → Android apk+aab →    │
│ iOS archive (macOS runner) → TestFlight      │
│ → GitHub Release (artifacts + changelog)     │
└──────────────────────────────────────────────┘
```

## 2. Pipeline: `ci.yml` (every pull request + push to main)

| Stage                    | Command / tool                          | Failure = blocked PR        |
| ------------------------ | --------------------------------------- | --------------------------- |
| 1. Checkout              | `actions/checkout@v4`                    |                             |
| 2. Setup                 | `actions/setup-python@v5` (3.12), `subosito/flutter-action` (stable), `actions/setup-java@v4` (JDK 17), Postgres service container | |
| 3. Lint                  | backend `ruff check .` + `black --check`; flutter `flutter analyze` + `dart format --set-exit-if-changed` | ✓ |
| 4. Backend tests         | `pip install -r requirements/dev.txt && pytest` (against Postgres service container) | ✓ |
| 5. Flutter tests         | `flutter pub get && flutter test`        | ✓ |
| 6. Build validation      | `flutter build apk --debug --flavor development` (PR); a full `--release` build on main | ✓ (release on main) |
| 7. Security scans        | `pip-audit` (Python deps), `osv-scanner`/`Dependabot` (Dart + Python), `bandit` (Python static), `gitleaks` (secrets), `trivy` on backend image, `codeql` (nightly) | advisory/non-blocking flags |
| 8. Artifacts             | `actions/upload-artifact@v4` on main: test reports, debug/release APK | main only |

- Concurrency: cancel superseded runs per branch (`concurrency: group: ci-${{ github.ref }}`).
- Required status checks protect `main` once CI lands (branch protection).
- A single CI job matrix keeps boot time low; split only when runtimes differ (Python vs Flutter).

## 3. Pipeline: `release.yml` (tag `vX.Y.Z` or manual dispatch)

```
trigger: push tag vX.Y.Z  |  workflow_dispatch (input version)
  1. meta: read version from tag/pubspec, enforce SemVer
  2. backend: build + push image (tagged vX.Y.Z) — owner T-11
  3. android: flutter build apk + appbundle (release, signing per §5)
  4. ios: macos runner → flutter build ios --release (no-codesign archive) → fastlane gym
     + sign with match (§6) → fastlane pilot/altool → TestFlight
  5. github release: notes/changelog + apk/aab + backend version + migration notes
  6. docs: attach generated changelog; record test status
```

- **Staging release:** build from `main` → push to staging env + TestFlight **internal**
  distribution. **Production release:** promote the tested staging tag or cut a new tag by
  approval gate (environment protection rules) → TestFlight **external** / App Store submission.

## 4. Versioning (SIW-6 §30)

- **Scheme:** SemVer `MAJOR.MINOR.PATCH` (optionally `-beta.N` pre-releases for TestFlight).
- **Sources of truth:**
  - Flutter app: `version:` in `pubspec.yaml`.
  - Backend: `version` in `pyproject.toml` (`__version__`), image tags use the same number.
  - Release tag `vX.Y.Z` must match the app version on release jobs (CI asserts equality).
- **Changelog:** generated from conventional-commit PR titles (`MAJOR.MINOR.PATCH` bump rules);
  stored in `CHANGELOG.md` and embedded in the GitHub Release body.
- **Reproducible releases:** tag = immutable commit; workflow pins exact toolchain versions
  (Flutter channel/hash, Python, JDK), lockfiles committed (`pubspec.lock`, `requirements*.txt` /
  `uv.lock`).
- **DB migrations:** backend image carries migrations; release notes list
  `migrate` commands + required data migrations (owner: T-11/T-34).

## 5. Android signing (app signing approach)

- Keystore **never committed**. Generated or provided externally, stored **base64 in GitHub
  secrets** on the `production`/`staging` GitHub Environment.
- Secrets required:

  | Secret                        | Purpose                                    |
  | ----------------------------- | ------------------------------------------ |
  | `ANDROID_KEYSTORE_BASE64`     | the `.jks` keystore, base64-encoded         |
  | `ANDROID_KEYSTORE_PASSWORD`   | keystore password                          |
  | `ANDROID_KEY_ALIAS`           | key alias                                  |
  | `ANDROID_KEY_PASSWORD`        | key password                               |

- Workflow: decode `ANDROID_KEYSTORE_BASE64` → write to `$RUNNER_TEMP` (never repo) → configure
  `key.properties`-free signing via env in `android/app/build.gradle`.
- Artifacts: **APK** (`flutter build apk --release`) for direct distribution and **AAB**
  (`flutter build appbundle --release`) for Play Store (`fastlane supply` in a later task).

## 6. iOS signing & TestFlight (certificates, no creds in repo)

- **Approach: `fastlane match`** (see ADR `0001`). Certs + provisioning profiles live in a
  **separate private match repo / encrypted storage**, never in the app repo.
- Alternative (if match repo is deferred): p12 + provisioning profiles as base64 **secrets**,
  imported on the runner via `security import`. Both avoid committing profiles/certs.
- **Runner:** `macos-14` (or newer) — required for iOS toolchain; signed iOS builds **require** an
  Apple Developer account ($99/yr) + App Store Connect API access. CI documents that iOS
  distribution is **dormant until those credentials exist**.
- Secrets required:

  | Secret                        | Purpose                                  |
  | ----------------------------- | ---------------------------------------- |
  | `MATCH_GIT_URL` / match store  | encrypted cert repo (match approach)     |
  | `MATCH_PASSWORD`              | match encryption passphrase              |
  | `APP_STORE_CONNECT_API_KEY_ID` | ASC API key id (.p8) — pilot upload     |
  | `APP_STORE_CONNECT_API_ISSUER_ID` | ASC API issuer id                      |
  | `APP_STORE_CONNECT_API_KEY`    | `.p8` file content (base64)              |

- Flow: `flutter build ios --release --flavor <env> --no-codesign` → `fastlane gym`
  (`export_method: app-store`) with `match` signing → `fastlane pilot` uploads to TestFlight.
- **Dev-only CI fallback:** unsigned `.xcarchive` (no codesign) can be built and uploaded as an
  artifact for inspection until signing credentials exist — this satisfies "iOS build available".

## 7. Environment mapping in CI

| Build        | `--flavor`          | `--dart-define=API_BASE_URL`                    | Signing env |
| ------------ | ------------------- | ----------------------------------------------- | ----------- |
| PR check     | `development`       | dev value (or dummy for tests)                  | none/debug  |
| Main build   | `development`       | dev value                                       | debug       |
| Staging      | `staging`           | `https://staging-api.example.com/api/v1`        | ad-hoc/dist |
| Production   | `production`        | `https://api.example.com/api/v1`                | app-store   |

- Same pattern for backend: `DJANGO_ENV` + env-file per job; secrets via GitHub Environments.

## 8. Security scanning summary (SIW-6 §27 "security checks")

- **Secrets in code:** `gitleaks` on every push/PR (blocking).
- **Dependency vulns:** `pip-audit` (Python), `dependabot` (Python + Dart) configured and PRs
  auto-merged only for patch-level, tests-green.
- **Code scanning:** GitHub `codeql` (nightly + on PR for changed languages).
- **Container:** `trivy` filesystem/image scan on backend image in release pipeline.
- **Artifact hygiene:** release artifacts signed/checksummed; `gh release upload` includes
  `.sha256` files.

## 9. Artifact publishing targets (single source of truth table)

| Artifact            | Where                                   | When                |
| ------------------- | --------------------------------------- | ------------------- |
| Test reports        | `actions/upload-artifact`               | every CI run        |
| Debug/release APK   | workflow artifact + GitHub Release      | mains + tags        |
| AAB                 | workflow artifact + GitHub Release      | tags / Play upload  |
| iOS `.xcarchive`/ipa| workflow artifact + TestFlight          | tags + staging      |
| Backend image       | container registry (GHCR)               | tags + main         |

## 10. What the DevOps Lead implements from this doc

- **T-11** — CI foundation: `ci.yml` stages 1–6 (lint, backend tests, flutter tests, build
  validation) + branch protection + `concurrency`.
- **T-34** — full CI/CD: security scans §8, artifact upload §9, GitHub Environments, release
  workflow §3, versioning §4, backend image push.
- **T-35** — Android signing §5 + APK/AAB release artifact + Play-ready bundle.
- **T-36** — iOS: macOS runner, match/env-secrets setup §6, `flutter build ios` +
  TestFlight pilot upload + signed archive on tag.
- **T-09** — backend Docker/env: `DJANGO_ENV` settings split, Dockerfile, compose, health
  endpoint used by CI stage 4.

Acceptance: a tag `vX.Y.Z` produces (1) green full test suite, (2) signed APK + AAB on the
GitHub Release, (3) iOS archive + TestFlight upload where Apple credentials exist, (4) backend
image push + migration notes in release body.