"""
REST views for the Gym Planner API.
"""
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import Profile, Plan, Exercise, WorkoutSession, ProgressMetric
from .serializers import (
    ProfileSerializer,
    PlanSerializer,
    PlanListSerializer,
    ExerciseSerializer,
    WorkoutSessionSerializer,
    WorkoutSessionListSerializer,
    ProgressMetricSerializer,
    RegisterSerializer,
)


class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]
    def post(self, request):
        s = RegisterSerializer(data=request.data)
        if s.is_valid():
            user = s.save()
            Profile.objects.get_or_create(user=user)
            from rest_framework_simplejwt.tokens import RefreshToken
            refresh = RefreshToken.for_user(user)
            return Response({
                'user': {'id': user.id, 'username': user.username, 'email': user.email},
                'access': str(refresh.access_token),
                'refresh': str(refresh),
            }, status=status.HTTP_201_CREATED)
        return Response(s.errors, status=status.HTTP_400_BAD_REQUEST)


class IsOwnerOrReadOnly(permissions.BasePermission):
    """Allow owners to edit; everyone can read."""
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.user == request.user


class ProfileViewSet(viewsets.ModelViewSet):
    """ViewSet for the current user's profile."""
    serializer_class = ProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Profile.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=False, methods=['get'])
    def me(self, request):
        """GET /profiles/me – return the current user's profile."""
        profile, _ = Profile.objects.get_or_create(user=request.user)
        serializer = self.get_serializer(profile)
        return Response(serializer.data)


class PlanViewSet(viewsets.ModelViewSet):
    """ViewSet for training plans."""
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrReadOnly]

    def get_serializer_class(self):
        if self.action == 'list':
            return PlanListSerializer
        return PlanSerializer

    def get_queryset(self):
        return Plan.objects.filter(user=self.request.user).prefetch_related('exercises')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class ExerciseViewSet(viewsets.ModelViewSet):
    """ViewSet for exercises."""
    serializer_class = ExerciseSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrReadOnly]

    def get_queryset(self):
        qs = Exercise.objects.filter(user=self.request.user)
        plan_id = self.request.query_params.get('plan')
        if plan_id:
            qs = qs.filter(plan_id=plan_id)
        return qs.select_related('plan')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class WorkoutSessionViewSet(viewsets.ModelViewSet):
    """ViewSet for workout sessions."""
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrReadOnly]

    def get_serializer_class(self):
        if self.action == 'list':
            return WorkoutSessionListSerializer
        return WorkoutSessionSerializer

    def get_queryset(self):
        qs = WorkoutSession.objects.filter(user=self.request.user)
        plan_id = self.request.query_params.get('plan')
        if plan_id:
            qs = qs.filter(plan_id=plan_id)
        return qs.prefetch_related('metrics', 'metrics__exercise')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class ProgressMetricViewSet(viewsets.ModelViewSet):
    """ViewSet for progress metrics."""
    serializer_class = ProgressMetricSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrReadOnly]

    def get_queryset(self):
        return ProgressMetric.objects.filter(
            session__user=self.request.user
        ).select_related('session', 'exercise')

    def perform_create(self, serializer):
        serializer.save()
