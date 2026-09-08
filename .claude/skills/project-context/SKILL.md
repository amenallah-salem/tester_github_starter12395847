# WELLAURA Project Context Skill

Use this skill whenever you need to understand the repository before coding.

## Goal
Build a compact mental model without scanning the whole repository.

## Procedure
1. Start at repository root.
2. Inspect only top-level files/directories relevant to the request.
3. Read `CLAUDE.md` first.
4. For backend work inspect `backend/README.md`, Django settings/URLs, models, serializers, views, tests, and relevant migrations.
5. For Flutter work inspect `frontend/pubspec.yaml`, routing, providers/state, repositories/API client, models, and the affected feature.
6. For infrastructure inspect Dockerfiles, compose files, shell scripts, and CI workflows.
7. Search for the feature name/symbol before opening unrelated files.
8. Record important findings mentally and avoid rereading unchanged files.

## Do Not
- scan `build/`, caches, `.git/`, dependency/vendor directories, or generated artifacts
- read every file just to "understand the project"
- infer architecture from filenames when source code can confirm it
- create duplicate abstractions when an existing one can be reused

## Output
Before a non-trivial implementation, be able to answer:
- where the feature lives
- how data flows
- which files must change
- which tests validate it
- how to run the affected part

