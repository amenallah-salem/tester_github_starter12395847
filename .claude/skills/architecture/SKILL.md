# WELLAURA Architecture Skill

Use before significant structural changes, cross-cutting features, or refactors.

## Principles
- prefer the current architecture when it works
- optimize for clarity and maintainability
- minimize coupling
- avoid premature abstraction
- avoid unnecessary microservices
- avoid competing patterns

## Decision Process
1. understand current boundaries
2. identify actual architectural pressure
3. consider the smallest change
4. compare alternatives briefly
5. choose the repository-consistent option
6. document important trade-offs

## Flutter
Respect existing separation between UI, state/providers, repositories/data, routing, and local persistence.

## Django
Respect existing separation between routing, views, serializers, models, and business logic.

## Cross-Platform Contract
Backend response shapes are contracts. When changing them, update all consumers and tests rather than silently changing one side.

## Refactoring
A refactor must have a concrete benefit. Do not mix broad cleanup into an unrelated feature unless necessary for correctness.
