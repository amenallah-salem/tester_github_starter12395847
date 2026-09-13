# CI pipeline

Pull requests run the analyzer and Flutter tests through `ci.yml`.
Pushes to `main` run the same checks in `android-release.yml`, then build and
publish the Android APK and AAB, followed by an unsigned iOS archive (see
"iOS releases" below).
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
