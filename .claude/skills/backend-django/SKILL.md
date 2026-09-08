# WELLAURA Django Backend Skill

Use for Django/Django REST Framework work.

## Architecture First
Before adding code, inspect:
- `backend/gym_api/models.py`
- `serializers.py`
- `views.py`
- `urls.py`
- settings
- migrations
- `tests.py`

Follow existing patterns instead of inventing a new architecture.

## Models
- Reuse existing relationships.
- Add constraints/indexes when justified.
- Consider nullability and existing rows before changing fields.
- Never destroy data to make a migration pass.

## API
For an endpoint verify:
- route
- HTTP method
- authentication
- permissions
- serializer validation
- queryset ownership/filtering
- response shape
- error behavior

Never expose another users
