# CI pipeline

Pull requests run the analyzer and Flutter tests through `ci.yml`.
Pushes to `main` run the same checks in `android-release.yml`, then build and
publish the Android APK and AAB.
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
