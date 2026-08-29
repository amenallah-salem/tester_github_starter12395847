# ADR 0001 — CI tooling and build/sign approach

- **Status:** Accepted
- **Date:** 2026-08-29
- **Owner:** CTO (with DevOps Lead)
- **Relates to:** SIW-6 §27–§30; `docs/ci-cd.md`

## Context

We must ship production Android (APK + AAB) and iOS (TestFlight-ready) builds, run lint/tests on
every PR, scan for security issues, and publish reproducible versioned releases. The project
lives on GitHub, uses Python/Django and Flutter/Dart, has no existing CI, and has no credentials
committed to the repo.

## Decision

1. **CI platform: GitHub Actions.**
   - Repo is already on GitHub — zero new infrastructure, native branch protection integration.
   - Linux (`ubuntu-latest`) runners cover backend/lint/Flutter/Android; macOS (`macos-14`)
     runners are required for iOS builds and are natively available.
   - Alternatives (CircleCI, GitLab CI, Buildkite, Jenkins, local runners) add cost/ops and/or
     lack GitHub-native status-check/release flow; rejected for MVP.
2. **Lint/format:** `ruff` (Python, fast, ruff-format replaces black) + `flutter analyze` and
   `dart format --set-exit-if-changed`; `pre-commit` locally mirrors CI gates.
3. **Tests:** `pytest` + `pytest-django` (against a Postgres service container in CI) for the
   backend; `flutter test` for the Flutter app.
4. **Android signing:** upload the release `.jks` keystore as **base64 GitHub Environment
   secrets** (`ANDROID_KEYSTORE_BASE64`, passwords/alias). Secrets are base64-embedded at build
   time; the keystore is never in the repo. This has zero external cost and works entirely on
   GitHub-hosted runners.
   - Rationale vs alternatives: Play App Signing (store-upload) is used for Play distribution
     later; "encrypted keystore in match-style repo" adds a private-repo dependency with no
     benefit on the Android side.
5. **iOS signing: `fastlane match`** (encrypted certs/provisioning profiles in a separate private
   repo), with a secrets-based p12/profile fallback if the match repo is deferred. Keys/API
   credentials for TestFlight upload come from App Store Connect **API keys** stored as GitHub
   secrets (`.p8` + issuer/key id). Nothing Apple-related is committed to the app repo.
   - iOS distribution stays **dormant but documented** until an Apple Developer account and ASC
     credentials are provisioned; a `--no-codesign` archive keeps CI green meanwhile.
6. **Release/build artifacts:** `actions/upload-artifact` for run outputs + **GitHub Releases**
   for versioned artifacts (APK, AAB, iOS ipa/archive, checksums, changelog, backend image
   reference). Backend image published to GHCR.
7. **Versioning:** SemVer `vX.Y.Z` tags; version must match `pubspec.yaml` and
   `pyproject.toml`; conventional-commit changelog in the release body.
8. **Security scanning:** `gitleaks` (secrets), `pip-audit` + `dependabot` (deps), `codeql`
   (static), `trivy` (container), `bandit` (Python static).

## Consequences

- **Positive:** lowest-friction path to a fully automated, reproducible pipeline; free hosting;
  standard tooling a DevOps Lead can run without custom infra.
- **Negative/risks:** macOS minutes cost money; iOS distribution is gated on Apple account +
  credentials; GitHub-hosted Android keystore secrets require careful rotation; match introduces
  one extra private repo dependency.
- **Rollback:** pipeline is purely additive — disabling workflows or switching to another CI
  provider does not affect the application.