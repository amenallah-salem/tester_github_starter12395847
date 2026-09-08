# Claude starter kit for this repo — setup

This zip mirrors your repo's root layout. Drop it in as-is, nothing to edit.

## Install (30 seconds)
1. Unzip this into the **root of your repo** (same level as `README.md`).
   It only adds these paths, nothing existing is touched or overwritten:
   ```
   CLAUDE.md
   docs/app-idea.md
   .claude/skills/add-backend-endpoint/SKILL.md
   .claude/skills/add-flutter-feature/SKILL.md
   .claude/skills/plan-contract-change/SKILL.md
   .claude/skills/wire-stub-feature/SKILL.md
   ```
2. Commit and push — your teammates get the same setup automatically the
   next time they pull, no per-person configuration.
3. That's it. No config, no environment variables, no editing required.

## What each file does
- **`CLAUDE.md`** — auto-read by Claude Code at the start of every session
  in this repo. Explains the codebase structure and conventions.
- **`docs/app-idea.md`** — the product vision doc: what the app is, what's
  real vs. mockup right now, and the constraints to respect. Share this link
  with teammates too — it's meant to be read by humans, not just Claude.
- **`.claude/skills/*`** — four skills Claude Code picks up automatically
  when relevant, no need to invoke them by name:
  - `add-backend-endpoint` — adding/changing a Django/DRF model or endpoint
  - `add-flutter-feature` — adding a new screen/feature to the Flutter app
  - `plan-contract-change` — changing the AI-generated plan's data shape
  - `wire-stub-feature` — turning a mockup feature (Coach, Biomechanics,
    Gym Bro matching, Recovery) into a real one

## Using it day-to-day
Open a terminal in the repo and run:
```bash
claude
```
Then just describe what you want in plain language, e.g.:
- *"Add a rest-day flag to Plan"* → picks up `add-backend-endpoint`
- *"Add a new screen showing weekly volume"* → picks up `add-flutter-feature`
- *"The AI plan needs a difficulty rating per exercise"* → picks up `plan-contract-change`
- *"Let's make Gym Bro matching actually work"* → picks up `wire-stub-feature`

You don't need to name the skill or the file — Claude Code matches your
request to the right one on its own. If it ever seems to be improvising
instead of following these conventions, just say "check CLAUDE.md" or "use
the relevant skill" to nudge it back.

## Keeping it useful
These docs will go stale if the app changes and nobody updates them. The
low-effort habit that keeps this pain-free long-term: whenever a "mockup"
feature becomes real, or the AI plan contract changes, ask Claude to update
`docs/app-idea.md`'s status table as part of that same change (the
`wire-stub-feature` and `plan-contract-change` skills both say to do this
already — you just need to not skip it).
