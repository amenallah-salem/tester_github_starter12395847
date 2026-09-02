# CI Pipeline Note (T-17 follow-up) — HONEST LIMITATIONS

What this does:
- `.github/workflows/flutter-mobile-ci.yml`: triggers on push/PR + tags (`v*`).
- Test step runs `flutter test` (graceful if no tests exist).
- Android job (`ubuntu-latest`): builds release APK with `flutter build apk --release`, versions from git tag (`vX.Y.Z`) + `git rev-list --count HEAD` as build number.
- iOS job (`macos-latest`): builds release archive with `flutter build ios --release --no-codesign`, updates `Info.plist` and `pubspec.yaml` version from same tag.
- Artifacts uploaded (retention 90d); `tag-release` job creates GitHub release from artifacts when build triggered by `v*` tag.

WHAT IS NOT REAL / BLOCKED:
- This is a YAML file only; `flutter` binary / `macos-latest` / Android SDK / code-signing certs / `secrets.GITHUB_TOKEN` are NOT present in this environment — full execution is NOT verified here.
- No `tests/` folder exists in `frontend/` — the `flutter test || echo` guard is required.
- iOS code-signing (`--no-codesign`) skips signing; actual App Store / TestFlight distribution requires Apple Developer cert + provisioning profile (not included).
- Android APK is release unsigned; Play Store / internal sharing requires keystore (`key.properties` + `jks`) — reference only, not included.
- The `yq` dependency was removed in favor of Python `re.sub` to avoid extra package installs.
