"""
App configuration for gym_api.
"""
from django.apps import AppConfig


class GymApiConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'gym_api'
    verbose_name = 'Gym Planner API'

    def ready(self):
        # Import signals to ensure they are registered when the app is ready
        try:
            from . import signals  # noqa: F401
        except Exception:
            # Avoid failing app startup if signals have issues; log in real projects
            pass
