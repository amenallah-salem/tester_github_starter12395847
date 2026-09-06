"""
REST views for the Gym Planner API.
"""
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView
from django.db import connections, models, transaction
from django.db.models import F, Sum
from django.db.models.functions import TruncWeek
from django.db.utils import OperationalError

from .models import (
    Profile, Plan, Exercise, PlanDay, PlanDayExercise,
    WorkoutSession, ProgressMetric, BodyWeightEntry, Subscription,
)
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
    PlanDaySerializer,
    BodyWeightEntrySerializer,
)


class HealthCheckView(APIView):
    """
    Lightweight, unauthenticated readiness probe for use by Docker/CI startup
    scripts and orchestrators. Unlike the DRF router root ("/api/"), this view
    does not require authentication (the router root inherits the project's
    default IsAuthenticated permission, so it returns 401 even when Django and
    the database are perfectly healthy).

    Returns 200 with {"status": "ok"} once Django can reach the database, or
    503 with {"status": "error"} if the database connection is not usable.
    """
    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    def get(self, request):
        try:
            connections['default'].ensure_connection()
        except OperationalError as exc:
            return Response(
                {'status': 'error', 'detail': str(exc)},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        return Response({'status': 'ok'}, status=status.HTTP_200_OK)


class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]
    def post(self, request):
        s = RegisterSerializer(data=request.data)
        if s.is_valid():
            user = s.save()
            Profile.objects.get_or_create(user=user)
            starter_plan = Plan.objects.create(
                user=user,
                name='Starter Week',
                description='A simple full-body routine to get started.',
            )
            starter_exercises = list(
                Exercise.objects.filter(is_library=True).order_by('created_at')[:3]
            )
            if starter_exercises:
                starter_day = PlanDay.objects.create(plan=starter_plan, weekday=0)
                PlanDayExercise.objects.bulk_create([
                    PlanDayExercise(
                        plan_day=starter_day,
                        exercise=exercise,
                        order=order,
                    )
                    for order, exercise in enumerate(starter_exercises)
                ])
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

    @action(detail=True, methods=['get', 'put'], url_path='week')
    def week(self, request, pk=None):
        plan = self.get_object()
        if request.method == 'GET':
            days = plan.days.prefetch_related(
                'assignments__exercise',
            )
            return Response({
                'plan': str(plan.id),
                'days': PlanDaySerializer(days, many=True).data,
            })

        raw_days = request.data.get('days')
        if not isinstance(raw_days, list):
            return Response(
                {'days': 'Expected a list of weekday assignments.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        weekdays = [item.get('weekday') for item in raw_days if isinstance(item, dict)]
        if len(raw_days) != 7 or sorted(weekdays) != list(range(7)):
            return Response(
                {'days': 'Exactly one assignment is required for each weekday 0 through 6.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        assignments = []
        for item in raw_days:
            exercise_ids = item.get('exercise_ids')
            if not isinstance(exercise_ids, list) or not all(
                isinstance(exercise_id, str) for exercise_id in exercise_ids
            ):
                return Response(
                    {'days': 'Each weekday must include an exercise_ids list.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            if len(exercise_ids) != len(set(exercise_ids)):
                return Response(
                    {'days': 'An exercise can only appear once per weekday.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            exercises = list(Exercise.objects.filter(
                id__in=exercise_ids,
            ).filter(
                models.Q(user=request.user) | models.Q(is_library=True, user__isnull=True),
            ))
            if len(exercises) != len(set(exercise_ids)):
                return Response(
                    {'days': 'Each exercise must belong to you or the exercise library.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            exercises_by_id = {str(exercise.id): exercise for exercise in exercises}
            assignments.append((item['weekday'], [
                exercises_by_id[exercise_id] for exercise_id in exercise_ids
            ]))

        with transaction.atomic():
            PlanDay.objects.filter(plan=plan).delete()
            for weekday, exercises in assignments:
                day = PlanDay.objects.create(plan=plan, weekday=weekday)
                PlanDayExercise.objects.bulk_create([
                    PlanDayExercise(plan_day=day, exercise=exercise, order=order)
                    for order, exercise in enumerate(exercises)
                ])
        days = plan.days.prefetch_related('assignments__exercise')
        return Response({
            'plan': str(plan.id),
            'days': PlanDaySerializer(days, many=True).data,
        })


class ExerciseViewSet(viewsets.ModelViewSet):
    """ViewSet for user exercises (per-user, plan-attached)."""
    serializer_class = ExerciseSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrReadOnly]

    def get_queryset(self):
        # return exercises belonging to the authenticated user
        qs = Exercise.objects.filter(user=self.request.user, is_library=False)
        plan_id = self.request.query_params.get('plan')
        if plan_id:
            qs = qs.filter(plan_id=plan_id)
        return qs.select_related('plan')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user, is_library=False)


class LibraryExerciseViewSet(viewsets.ModelViewSet):
    """ViewSet for global admin-managed exercise library.

    Read-only access is public (AllowAny) so the frontend can fetch the library without
    authentication. Write actions (create/update/destroy) require admin privileges and
    an authenticated user (token).
    """
    serializer_class = ExerciseSerializer
    permission_classes = [permissions.AllowAny]

    def get_permissions(self):
        # Allow anyone to perform safe methods (list, retrieve).
        # Require admin for write operations.
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [permissions.IsAuthenticated(), permissions.IsAdminUser()]
        return [permissions.AllowAny()]

    def get_queryset(self):
        qs = Exercise.objects.filter(is_library=True)
        # support filters for body_part, difficulty, equipment, movement_pattern, exercise_type
        params = self.request.query_params
        body_part = params.get('body_part')
        difficulty = params.get('difficulty')
        equipment = params.get('equipment')
        movement_pattern = params.get('movement_pattern')
        exercise_type = params.get('exercise_type')
        search = params.get('search')
        if body_part:
            qs = qs.filter(body_part__iexact=body_part)
        if difficulty:
            qs = qs.filter(difficulty__iexact=difficulty)
        if movement_pattern:
            qs = qs.filter(movement_pattern__iexact=movement_pattern)
        if exercise_type:
            qs = qs.filter(exercise_type__iexact=exercise_type)
        if equipment:
            qs = qs.filter(equipment__contains=[equipment])
        if search:
            qs = qs.filter(name__icontains=search) | qs.filter(aliases__icontains=search)
        return qs.prefetch_related('alternatives', 'progression_exercises', 'regression_exercises')

    def perform_create(self, serializer):
        # ensure created library exercises are marked as library and not tied to a user
        serializer.save(user=None, is_library=True)


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

    @action(detail=False, methods=['get'], url_path='last-for-exercise')
    def last_for_exercise(self, request):
        exercise_id = request.query_params.get('exercise')
        if not exercise_id:
            return Response(
                {'exercise': 'This query parameter is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        metric = self.get_queryset().filter(
            exercise_id=exercise_id,
        ).order_by('-logged_at').first()
        if metric is None:
            return Response({'result': None}, status=status.HTTP_200_OK)
        return Response({
            'result': ProgressMetricSerializer(
                metric,
                context={'request': request},
            ).data,
        })

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
        workout_count_by_week = list(
            WorkoutSession.objects.filter(user=request.user)
            .annotate(week=TruncWeek('started_at'))
            .values('week')
            .annotate(workout_count=models.Count('id'))
            .order_by('week')
        )
        return Response({
            'total_volume_kg': float(volume),
            'estimated_one_rep_max_kg': round(estimated_one_rep_max, 2),
            'personal_records': len(best_by_exercise),
            'volume_by_day': [
                {'date': day, 'volume_kg': round(value, 2)}
                for day, value in sorted(volume_by_day.items())
            ],
            'workout_count_by_week': [
                {
                    'week': item['week'].date().isoformat(),
                    'workout_count': item['workout_count'],
                }
                for item in workout_count_by_week
            ],
            'trend': 'up' if len(volume_by_day) > 1 and
            list(volume_by_day.values())[-1] >= list(volume_by_day.values())[0]
            else 'steady',
        })


class BodyWeightEntryViewSet(viewsets.ModelViewSet):
    serializer_class = BodyWeightEntrySerializer
    permission_classes = [permissions.IsAuthenticated]
    http_method_names = ['get', 'post', 'head', 'options']

    def get_queryset(self):
        return BodyWeightEntry.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


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
