Copilot Guide — Repository onboarding and skill usage

This document explains how GitHub Copilot (and cloud agents) should operate within this repository, plus guidance for contributors to get consistent results.

Files created for agent automation
- copilot-skills.yml: /home/amen/Desktop/tester_github_starter12395847.worktrees/github-copilot-skill-guidance/copilot-skills.yml
- copilot-setup-steps.yml: /home/amen/Desktop/tester_github_starter12395847.worktrees/github-copilot-skill-guidance/copilot-setup-steps.yml

Goals
- Make it easy for Copilot and cloud agents to perform repository tasks (create PRs, run tests, fix CI, create commits) in a clear, auditable way.
- Provide a predictable environment and entry points for contributors and automation.

How to ask Copilot to take actions
- Use explicit hint strings in comments or PR descriptions to request actions. Examples (these are processed by agents that read commit messages or PR bodies):
  - "@copilot:create-pr" — create a pull request for the current branch
  - "@copilot:fix-ci" — investigate and attempt to fix CI failures
  - "@copilot:run-tests" — run the test suite and report failures

Commit and PR conventions
- Commit messages created by agents should follow the repository style. When an agent creates a commit, include the following trailer unless you explicitly opt out:
  Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

- PR template expectations: include a Test Plan, Related Issues, and How to Test section. Agents creating PRs will try to populate these fields but maintainers should review them.

Skill usage and scope
- Agents should prefer small, surgical edits limited to files relevant to the task.
- Avoid repository-wide refactors unless explicitly requested and approved.
- When fixing CI or tests, prefer minimal, well-tested changes that preserve intent.

Feature development workflow
- When asked to implement a task or feature, implement it as fully and professionally as possible. This includes writing necessary code, tests, and documentation.
- Start the application locally on the project's development port and perform interactive user-experience testing in the running app (open the app in a browser, exercise the new flows, and verify behavior).
- Run the project's smoke and test suites and ensure no regressions. If regressions are discovered, fix them or document a clear follow-up plan in the PR.
- Respect the app's design and visual language: prefer existing components and styling, and produce polished, attractive UI that fits the product. For significant visual changes include screenshots or short recordings in the PR and request a design review when appropriate.
- Document how to run the app, test the feature, and any special environment requirements in the PR description so reviewers can validate the UX changes.

Tool tracking and skills upkeep
- Whenever a tool, library, CLI, service, or workflow is used that is not yet described in copilot-skills.yml, add or update a skill entry documenting:
  - purpose and brief description of the tool
  - sample commands or usage patterns used in this repository
  - required permissions or external integrations
  - examples and when the tool should (or should not) be used
- If adding or updating a skill affects security, external services, credentials, or repo permissions, open a draft PR and notify maintainers for review rather than merging automatically.
- Keep skill entries concise, actionable, and repository-specific so future agents and contributors can discover and re-use them.
- When correcting an existing skill, include a short changelog note in the skill's description and the PR body explaining why the change was made.

Onboarding / Local dev (quick)
1. Clone the repo and switch to main:
   git checkout main
2. Follow the repository-specific install steps (see copilot-setup-steps.yml) to install runtimes and dependencies.
3. Run the fast test suite to ensure integrity:
   - npm test (or) pytest -q

Run commands (UI Run button suggestions)
- "Start dev server" -> npm run dev
- "Run tests" -> npm test
(These are registered by copilot-setup-steps.yml when appropriate.)

When to call maintainers
- If an agent detects a security-sensitive change or a change touching authentication/authorization, notify maintainers and create a draft PR rather than merging automatically.
- If tests require secrets or access to external services, escalate to maintainers rather than proceeding automatically.

Troubleshooting
- If a Copilot action doesn't do what you expect, capture the session feedback and file a short issue with steps to reproduce. Use the 'act-on-feedback' skill to request corrections.

Maintainer notes
- Update copilot-skills.yml when new project-level automation patterns are introduced.
- Keep copilot-setup-steps.yml minimal and focused on fast startup. Pin explicit versions for runtimes if the project relies on them.

Where to edit these files
- Edit /home/amen/Desktop/tester_github_starter12395847.worktrees/github-copilot-skill-guidance/copilot-skills.yml to add or adjust skills and repository policies.
- Edit /home/amen/Desktop/tester_github_starter12395847.worktrees/github-copilot-skill-guidance/copilot-setup-steps.yml to tune environment setup and run commands.

If you'd like, next steps:
- Commit these files to a new branch and open a draft PR titled "chore: add Copilot skills and setup guidance" so team can review and iterate. (Recommended)
- Or modify the contents to match your repository's exact test/run commands and CI flows.

---
Repository assistant: an AI assistant using Copilot CLI runtime in VS Code
