# WELLAURA Database Skill

Use for PostgreSQL, Django models, migrations, and persistence changes.

## Safety
Never reset the database to fix an application bug, delete migration history casually, drop user data without an explicit migration strategy, or hard-code credentials.

## Before Schema Changes
1. inspect current model and migrations
2. inspect query/serializer usage
3. consider existing rows
4. choose a compatible migration strategy
5. generate the migration
6. inspect the generated migration
7. apply it in development
8. run affected tests

## Data Ownership
User-specific records must be filtered by authenticated user/ownership. Treat workouts, goals, profiles, favorites, and related records as private unless explicitly designed otherwise.

## Seed Data
Inspect existing fixtures and management commands before creating new seed mechanisms. Reuse existing exercise seeding where applicable.
