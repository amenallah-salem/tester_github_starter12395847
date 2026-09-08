# WELLAURA GitHub Workflow Skill

Use for branches, commits, pull requests, CI, and release workflows.

## Before Commit
```bash
git status --short
git diff --stat
git diff
```
Check for secrets and unrelated files.

## Commits
Prefer focused imperative commits such as:
`fix: persist authentication session`

Do not mix feature work, unrelated formatting, generated files, and broad refactors.

## CI
Inspect `.github/workflows/ci.yml` and release workflows before changing CI. Do not invent workflow behavior.

## Release
Android release changes are release-sensitive. Inspect `android-release.yml`, required secrets, signing configuration, and build commands before modifying. Never print signing keys or credentials.

## Push
Only push when explicitly requested or when the autonomous workflow explicitly authorizes it. Never force-push by default.
