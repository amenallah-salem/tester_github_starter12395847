# CI pipeline

One workflow, `pipeline.yml`, staged as a single job graph instead of several
independent workflows. Two fast checks run in parallel; nothing later starts
until both are green; release only happens on push to main, and only after
everything else has passed.

```text
pull_request or push to main
        │
        ├── backend-tests  ───┐
        │                     ├──► docker-build ──► pipeline-status
        └── frontend-tests ───┘                            │
                                                (push to main only)
                                                             │
                                                             ▼
                                                          android
                                                             │
                                                             ▼
                                                            ios
```

| Job | Runs on | Depends on | What it does |
|---|---|---|---|
| `backend-tests` | every PR + push | — | `manage.py test gym_api` against SQLite (`DJANGO_TESTING=1`) |
| `frontend-tests` | every PR + push | — | `flutter analyze` + `flutter test` |
| `docker-build` | every PR + push | both tests jobs | `./docker.dev.sh build` — builds the backend + frontend dev images |
| `pipeline-status` | every PR + push | all three above | Aggregate gate — the one check to require in branch protection |
| `android` | push to main only | `pipeline-status` | Builds/tags/publishes the Android APK + AAB |
| `ios` | push to main only | `android` | Builds and publishes an unsigned iOS archive to the same release |

## Why one workflow instead of several

GitHub Actions jobs within a single workflow file can declare `needs:`,
which is what actually creates a staged, step-by-step pipeline — separate
workflow files can only be chained via `workflow_run`, which is harder to
reason about (no shared job outputs, awkward PR status checks) and wasn't a
better fit here. `backend-tests` and `frontend-tests` have no `needs:` on
each other, so Actions runs them in parallel automatically; everything else
is a real dependency (packaging only matters if the code is good; a release
only matters if packaging works).

The former `android-release.yml` release job used to re-run
`flutter analyze`/`flutter test` itself. That's removed here — `android`
depends (transitively, through `pipeline-status`) on `frontend-tests` having
already passed in the same run, so re-running it would only have burned
extra CI minutes for a result already known.

## Branch protection

Set **`Pipeline status`** as the required status check in the repo's branch
protection rules — not the three jobs it aggregates. If a job is renamed or a
new required check is added later, only `pipeline-status`'s `needs:` list
changes; branch protection settings never need to be touched.

## Concurrency

```yaml
concurrency:
  group: pipeline-${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}
```

- On a pull request, the group key is the PR number: a new push to the same
  PR cancels the previous, still-running check (fast feedback, no wasted
  minutes).
- On push to main, the group key is the ref: `cancel-in-progress` is `false`,
  so a release in progress is never killed mid-flight, and two rapid pushes
  to main queue and run one after another rather than racing each other's
  tag/release creation.

## Permissions

The workflow defaults to `permissions: contents: read`. Only `android` and
`ios` — the two jobs that push a git tag and create/upload a GitHub Release —
escalate to `contents: write` on themselves. Every other job stays read-only.

## Backend tests

Installs `backend/requirements.txt` under Python 3.13 (matching
`backend/Dockerfile`'s base image) and runs `manage.py test gym_api --noinput`
with `DJANGO_TESTING=1`, which flips `backend/gym_project/settings.py`'s
`DATABASES` block to SQLite instead of Postgres. `manage.py test` builds and
migrates its own throwaway test database regardless of engine, so no separate
migration step or Postgres service container is needed. This does not
exercise any Postgres-specific behavior — if that ever needs coverage, switch
this job to a `services: postgres:` container and drop `DJANGO_TESTING`.

## Docker build verification

Runs the exact same command documented in `CLAUDE.md` (`./docker.dev.sh
build`), which validates the Compose config for
`docker-compose.backend.dev.yml` + `docker-compose.frontend.dev.yml` and then
builds both images. It only proves the images build — it does not start
Postgres, run migrations, or health-check the backend/frontend (that's what
`./docker.dev.sh up` does locally). Production compose files
(`docker-compose.*.prod.yml`) are intentionally not built in CI since they
expect production secrets/config that don't exist here.

## Android releases

The `android` job runs automatically for every push to `main`, after
`pipeline-status` passes. It builds both Android artifacts, then creates a
tag and GitHub Release only after both builds succeed.

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

The `ios` job runs after `android` succeeds (`needs: android`,
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
