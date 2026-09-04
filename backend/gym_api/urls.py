"""
URL routing for the gym_api app.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from .views import (
    ProfileViewSet,
    PlanViewSet,
    ExerciseViewSet,
    WorkoutSessionViewSet,
    ProgressMetricViewSet,
    RegisterView,
)

router = DefaultRouter()
router.register(r'profiles', ProfileViewSet, basename='profile')
router.register(r'plans', PlanViewSet, basename='plan')
router.register(r'exercises', ExerciseViewSet, basename='exercise')
router.register(r'sessions', WorkoutSessionViewSet, basename='session')
router.register(r'metrics', ProgressMetricViewSet, basename='metric')

urlpatterns = [
    # JWT auth endpoints
    path('auth/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/register/', RegisterView.as_view(), name='register'),
    # Router URLs
    path('', include(router.urls)),
]
