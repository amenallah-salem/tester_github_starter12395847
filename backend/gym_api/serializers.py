"""
REST serializers for the Gym Planner API.
"""
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from .models import Profile, Plan, Exercise, WorkoutSession, ProgressMetric, Subscription


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    email = serializers.EmailField(required=False, allow_blank=True)
    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'first_name', 'last_name']
    def create(self, validated):
        return User.objects.create_user(**validated)

    def validate_password(self, password):
        validate_password(password)
        return password

class UserSerializer(serializers.ModelSerializer):
    """Lightweight User serializer for nested representations."""
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']
        read_only_fields = ['id']


class ProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = Profile
        fields = ['id', 'user', 'display_name', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class ExerciseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Exercise
        fields = [
            'id', 'plan', 'user', 'name', 'description',
            'target_sets', 'target_reps', 'target_weight_kg',
            'order', 'created_at',
        ]
        read_only_fields = ['id', 'user', 'created_at']

    def validate_plan(self, plan):
        user = self.context['request'].user
        if plan is not None and plan.user_id != user.id:
            raise serializers.ValidationError('You can only use your own plans.')
        return plan


class ExerciseNestedSerializer(serializers.ModelSerializer):
    """Exercise with its progress metrics nested."""
    metrics = serializers.SerializerMethodField()

    class Meta:
        model = Exercise
        fields = [
            'id', 'name', 'description',
            'target_sets', 'target_reps', 'target_weight_kg',
            'order', 'metrics',
        ]

    def get_metrics(self, obj):
        metrics = getattr(obj, '_prefetched_metrics', obj.metrics.all())
        return ProgressMetricSerializer(metrics, many=True).data


class PlanSerializer(serializers.ModelSerializer):
    exercises = ExerciseSerializer(many=True, read_only=True)
    user = UserSerializer(read_only=True)

    class Meta:
        model = Plan
        fields = [
            'id', 'user', 'name', 'description',
            'is_active', 'exercises',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class PlanListSerializer(serializers.ModelSerializer):
    """Plan without nested exercises (list view)."""
    exercise_count = serializers.IntegerField(source='exercises.count', read_only=True)

    class Meta:
        model = Plan
        fields = [
            'id', 'name', 'description', 'is_active',
            'exercise_count', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class ProgressMetricSerializer(serializers.ModelSerializer):
    exercise_name = serializers.CharField(source='exercise.name', read_only=True)

    class Meta:
        model = ProgressMetric
        fields = [
            'id', 'session', 'exercise', 'set_number',
            'reps', 'weight_kg', 'duration_seconds', 'logged_at', 'exercise_name',
        ]
        read_only_fields = ['id', 'logged_at']

    def validate(self, attrs):
        user = self.context['request'].user
        session = attrs.get('session', getattr(self.instance, 'session', None))
        exercise = attrs.get('exercise', getattr(self.instance, 'exercise', None))
        if session and session.user_id != user.id:
            raise serializers.ValidationError({'session': 'This session does not belong to you.'})
        if exercise and exercise.user_id != user.id:
            raise serializers.ValidationError({'exercise': 'This exercise does not belong to you.'})
        if session and exercise and exercise.plan_id and session.plan_id != exercise.plan_id:
            raise serializers.ValidationError({'exercise': 'The exercise must belong to the session plan.'})
        return attrs


class WorkoutSessionSerializer(serializers.ModelSerializer):
    metrics = ProgressMetricSerializer(many=True, read_only=True)
    user = UserSerializer(read_only=True)
    duration_seconds = serializers.SerializerMethodField()
    total_volume_kg = serializers.SerializerMethodField()

    class Meta:
        model = WorkoutSession
        fields = [
            'id', 'user', 'plan', 'name',
            'started_at', 'finished_at', 'notes', 'metrics',
            'duration_seconds', 'total_volume_kg',
        ]
        read_only_fields = ['id', 'started_at']

    def get_duration_seconds(self, obj):
        if not obj.finished_at:
            return None
        return max(0, int((obj.finished_at - obj.started_at).total_seconds()))

    def get_total_volume_kg(self, obj):
        return float(sum(
            (metric.weight_kg or 0) * metric.reps
            for metric in obj.metrics.all()
        ))

    def validate_plan(self, plan):
        if plan is not None and plan.user_id != self.context['request'].user.id:
            raise serializers.ValidationError('You can only use your own plans.')
        return plan


class WorkoutSessionListSerializer(serializers.ModelSerializer):
    metric_count = serializers.IntegerField(source='metrics.count', read_only=True)
    exercise_names = serializers.SerializerMethodField()
    duration_seconds = serializers.SerializerMethodField()
    total_volume_kg = serializers.SerializerMethodField()

    class Meta:
        model = WorkoutSession
        fields = [
            'id', 'plan', 'name', 'started_at',
            'finished_at', 'metric_count', 'exercise_names',
            'duration_seconds', 'total_volume_kg',
        ]
        read_only_fields = ['id', 'started_at']

    def get_exercise_names(self, obj):
        return list(obj.metrics.values_list('exercise__name', flat=True).distinct())

    def get_duration_seconds(self, obj):
        end = obj.finished_at
        if not end:
            return None
        return max(0, int((end - obj.started_at).total_seconds()))

    def get_total_volume_kg(self, obj):
        return float(sum(
            (metric.weight_kg or 0) * metric.reps
            for metric in obj.metrics.all()
        ))


class SubscriptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Subscription
        fields = [
            'id', 'user', 'plan_name', 'status', 'current_period_start',
            'current_period_end', 'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'user', 'status', 'current_period_start',
            'current_period_end', 'created_at', 'updated_at',
        ]
