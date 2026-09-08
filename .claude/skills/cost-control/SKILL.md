# WELLAURA Cost Control Skill

Optimize Claude Code usage without sacrificing correctness.

## Token-Efficient Investigation
Prefer:
```text
exact symbol/error search
-> relevant file
-> relevant surrounding code
-> referenced dependency
```
over repository-wide reading.

## Avoid Waste
Do not scan `.git`, build outputs, caches, dependency directories, generated files, or large assets. Do not repeatedly read unchanged files. Do not run full suites after every one-line change. Do not rebuild all Docker images for a source-only change unless required. Do not make speculative edits.

## Test Escalation
1. syntax/static check
2. targeted test
3. affected suite
4. integration/full suite only when justified

## Docker Efficiency
Prefer commands against the affected service. Avoid `--build` when an image rebuild is unnecessary. Use `--no-cache` only when cache corruption/staleness is demonstrated.

## Context Efficiency
At the start of a task establish objective, relevant files, constraints, and validation command. Then stay focused and do not reopen unchanged files.

## Reasoning Efficiency
Reserve deep reasoning for architecture, difficult root-cause analysis, security, and complex cross-layer changes. Simple edits should remain simple.
