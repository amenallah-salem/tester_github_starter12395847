"""
App configuration for gym_api.
"""
from django.apps import AppConfig


class GymApiConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'gym_api'
    verbose_name = 'Gym Planner API'
