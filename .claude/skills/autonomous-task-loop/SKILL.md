# WELLAURA Autonomous Task Loop Skill

Use when asked to work through a backlog or execute a multi-step development task autonomously.

## Loop
For each task:
1. select one task
2. read relevant context/skills
3. investigate
4. define acceptance criteria
5. implement
6. test
7. debug failures
8. validate
9. review diff
10. mark task complete
11. move to the next task only after the current task is validated

## Scope Control
Never silently expand a task. Implement a discovered dependency only when necessary for the current task; otherwise record it as a follow-up.

## Failure Handling
If validation fails, investigate, fix the root cause, and rerun validation. Do not mark a task complete with known failures unless explicitly instructed.

## Git
Keep commits focused if commits are requested/authorized. Do not force-push.

## Reporting
At the end of each task record completed change, validation performed, remaining issue, and next task.
