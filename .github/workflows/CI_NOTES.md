# CI pipeline

Five workflows, each scoped to one concern:

| Workflow | Triggers | What it does |
|---|---|---|
| `ci.yml` | pull_request → main | Original PR check: Flutter analyze + test. Kept as-is; overlaps with `frontend-ci.yml` below. |
| `frontend-ci.yml` | pull_request, push → main | Flutter analyze + test (`flutter test`) — same checks as `ci.yml`, also run on push to main. |
| `backend-ci.yml` | pull_request, push → main | Django tests (`manage.py test gym_api`) against SQLite (`DJANGO_TESTING=1`) — no service container needed. |
| `docker-build.yml` | pull_request, push → main | `./docker.dev.sh build` — builds the backend + frontend dev Docker images and fails if either build fails. Does not start the stack or need any secrets (`.env.dev` is checked into the repo). |
| `android-release.yml` | push → main | Re-runs Flutter analyze + test, then builds/tags/publishes the Android APK+AAB and an unsigned iOS archive. See "Android releases" / "iOS releases" below — unchanged. |

`frontend-ci.yml`/`backend-ci.yml`/`docker-build.yml` are new, independent
workflows (not merged into `ci.yml` or `android-release.yml`) so each concern
fails/passes on its own and is easy to read in the Actions tab. Some overlap
with `ci.yml` (which still runs Flutter analyze+test on PRs) and with
`android-release.yml` (which still re-runs Flutter analyze+test before
building) is intentional — nothing was removed from either.

## Backend tests

`backend-ci.yml` installs `backend/requirements.txt` under Python 3.13
(matching `backend/Dockerfile`'s base image) and runs
`manage.py test gym_api --noinput` with `DJANGO_TESTING=1`, which flips
`backend/gym_project/settings.py`'s `DATABASES` block to SQLite instead of
Postgres. `manage.py test` builds and migrates its own throwaway test
database regardless of engine, so no separate migration step or Postgres
service container is needed. This does not exercise any Postgres-specific
behavior — if that ever needs coverage, switch this job to a
`services: postgres:` container and drop `DJANGO_TESTING`.

## Docker build verification

`docker-build.yml` runs the exact same command documented in `CLAUDE.md`
(`./docker.dev.sh build`), which validates the Compose config for
`docker-compose.backend.dev.yml` + `docker-compose.frontend.dev.yml` and then
builds both images. It only proves the images build — it does not start
Postgres, run migrations, or health-check the backend/frontend (that's what
`./docker.dev.sh up` does locally). Production compose files
(`docker-compose.*.prod.yml`) are intentionally not built in CI since they
expect production secrets/config that don't exist here.

## Android releases

`android-release.yml` runs automatically for every push to `main`. It runs the
Flutter analyzer and tests, generates Drift sources, builds both Android
artifacts, then creates a tag and GitHub Release only after both builds succeed.
The release workflow is serialized with Actions concurrency so rapid pushes are
published in order.

The first release uses the semantic version in `frontend/pubspec.yaml`
(`0.1.0+1` in this repository). Each later release increments the patch
component and uses `configured versionCode + number of existing semantic
release tags`. Tags are annotated as `vMAJOR.MINOR.PATCH` and point at the
pushed commit that produced the artifacts.

Release signing is optional until production credentials are available. To
enable it, configure these GitHub Actions secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Without them, Gradle uses its local debug key so CI remains buildable, but that
APK/AAB must not be distributed as a production-signed application.

## iOS releases

A second job, `ios`, runs after `release` succeeds (same workflow, `needs: release`,
`runs-on: macos-latest`) and uploads an iOS archive to the same GitHub Release
as the Android APK/AAB.

No Apple Distribution certificate or provisioning profile is configured yet,
so this job builds with `flutter build ios --release --no-codesign` and zips
the resulting `Runner.app` as `gym_app-<version>-ios-unsigned.zip`. This
confirms the iOS build compiles for that commit and gives you a QA artifact,
but **it is not signed** — it cannot be installed on a device or submitted to
TestFlight/the App Store.

To upgrade this to a real, installable `.ipa`:
1. Add these GitHub Actions secrets (mirroring the Android keystore pattern):
   - `IOS_DISTRIBUTION_CERTIFICATE_BASE64` (a `.p12` export of your Apple
     Distribution certificate) and `IOS_CERTIFICATE_PASSWORD`
   - `IOS_PROVISIONING_PROFILE_BASE64` (the `.mobileprovision` for this app id)
   - `IOS_TEAM_ID` (your Apple Developer Team ID)
2. Replace the `--no-codesign` build with importing the certificate/profile
   into a temporary keychain, then `flutter build ipa --export-options-plist=...`
   to produce a signed `.ipa`.
3. Upload the `.ipa` instead of the unsigned zip.

Ask before doing this — it requires real Apple Developer Program credentials.
