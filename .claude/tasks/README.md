# WELLAURA Claude Task Queue

Use this directory for autonomous development tasks.

Recommended format:

```markdown
## TASK-001 — Persist login session
Status: TODO
Priority: P0

### Acceptance Criteria
- Existing authenticated users remain signed in after app restart.
- Logout clears local session state.
- Expired/invalid sessions are handled safely.

### Validation
- Flutter targeted auth tests
- Backend auth tests if API behavior changes
- Manual/reproducible restart flow
```

Claude should complete one task at a time, validate it, then move to the next.
