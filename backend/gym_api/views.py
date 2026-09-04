"""
REST views for the Gym Planner API.
"""
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView
from django.db.models import F, Sum

from .models import Profile, Plan, Exercise, WorkoutSession, ProgressMetric, Subscription
from .serializers import (
    ProfileSerializer,
    PlanSerializer,
    PlanListSerializer,
    ExerciseSerializer,
    WorkoutSessionSerializer,
    WorkoutSessionListSerializer,
    ProgressMetricSerializer,
    RegisterSerializer,
    SubscriptionSerializer,
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

    @action(detail=True, methods=['post'], url_path='log-metric')
    def log_metric(self, request, pk=None):
        session = self.get_object()
        exercise_name = str(request.data.get('exercise_name', '')).strip()
        if not exercise_name:
            return Response({'exercise_name': 'This field is required.'},
                            status=status.HTTP_400_BAD_REQUEST)
        exercise, _ = Exercise.objects.get_or_create(
            user=request.user,
            name=exercise_name,
            plan=session.plan,
            defaults={'description': 'Logged from a completed workout.'},
        )
        payload = {
            'session': session.id,
            'exercise': exercise.id,
            'set_number': request.data.get('set_number', 1),
            'reps': request.data.get('reps', 0),
            'weight_kg': request.data.get('weight_kg'),
            'duration_seconds': request.data.get('duration_seconds'),
        }
        serializer = ProgressMetricSerializer(data=payload, context={'request': request})
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)


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

    @action(detail=False, methods=['get'], url_path='summary')
    def summary(self, request):
        """Return derived lifting insights for the authenticated user."""
        metrics = list(self.get_queryset().filter(weight_kg__isnull=False))
        volume = ProgressMetric.objects.filter(
            session__user=request.user,
            weight_kg__isnull=False,
        ).aggregate(total=Sum(F('weight_kg') * F('reps')))['total'] or 0
        best_by_exercise = {}
        volume_by_day = {}
        estimated_one_rep_max = 0
        for metric in metrics:
            weight = float(metric.weight_kg)
            best_by_exercise[metric.exercise_id] = max(
                best_by_exercise.get(metric.exercise_id, 0),
                weight,
            )
            estimated_one_rep_max = max(
                estimated_one_rep_max,
                weight * (1 + metric.reps / 30),
            )
            day = metric.logged_at.date().isoformat()
            volume_by_day[day] = volume_by_day.get(day, 0) + weight * metric.reps
        return Response({
            'total_volume_kg': float(volume),
            'estimated_one_rep_max_kg': round(estimated_one_rep_max, 2),
            'personal_records': len(best_by_exercise),
            'volume_by_day': [
                {'date': day, 'volume_kg': round(value, 2)}
                for day, value in sorted(volume_by_day.items())
            ],
            'trend': 'up' if len(volume_by_day) > 1 and
            list(volume_by_day.values())[-1] >= list(volume_by_day.values())[0]
            else 'steady',
        })


class SubscriptionViewSet(viewsets.ModelViewSet):
    """Expose only the authenticated user's subscription."""
    serializer_class = SubscriptionSerializer
    permission_classes = [permissions.IsAuthenticated]
    http_method_names = ['get', 'post', 'patch', 'head', 'options']

    def get_queryset(self):
        return Subscription.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=False, methods=['get', 'patch'], url_path='subscription')
    def current(self, request):
        subscription, _ = Subscription.objects.get_or_create(user=request.user)
        serializer = self.get_serializer(subscription, data=request.data or None,
                                         partial=True) if request.method == 'PATCH' else self.get_serializer(subscription)
        if request.method == 'PATCH':
            serializer.is_valid(raise_exception=True)
            serializer.save()
        return Response(serializer.data)
