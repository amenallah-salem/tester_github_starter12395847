# WELLAURA Feature Development Skill

Use for new features and meaningful enhancements.

## Workflow
1. Restate the requirement internally as acceptance criteria.
2. Investigate existing implementation.
3. Identify impacted layers.
4. Plan the smallest implementation.
5. Implement one coherent slice at a time.
6. Run targeted tests.
7. Integrate the next layer.
8. Run broader validation.
9. Review diff.
10. Update docs if needed.

## Acceptance Criteria
Every feature should have observable behavior. Prefer criteria such as:
- given/when/then behavior
- API request/response expectations
- persistence expectations
- loading/error/empty states
- authentication/authorization expectations
- offline behavior when applicable

## Change Discipline
- Reuse existing widgets, providers, repositories, serializers, models, and utilities.
- Do not add a package when existing dependencies already solve the problem.
- Do not refactor unrelated code.
- Keep changes reversible and focused.
- Preserve backward compatibility unless the task explicitly requires a breaking change.

## Full-Stack Features
When a feature crosses frontend/backend:
1. define the data contract
2. implement backend persistence/API
3. test API behavior
4. connect Flutter repository/state
5. implement UI states
6. validate end-to-end behavior

Do not fake successful backend integration with hard-coded frontend data unless explicitly requested as a prototype.

