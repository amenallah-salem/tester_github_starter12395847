"""
REST serializers for the Gym Planner API.
"""
from django.contrib.auth.models import User
from rest_framework import serializers
from .models import Profile, Plan, Exercise, WorkoutSession, ProgressMetric


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'first_name', 'last_name']
    def create(self, validated):
        return User.objects.create_user(**validated)

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
        read_only_fields = ['id', 'created_at']


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
    class Meta:
        model = ProgressMetric
        fields = [
            'id', 'session', 'exercise', 'set_number',
            'reps', 'weight_kg', 'duration_seconds', 'logged_at',
        ]
        read_only_fields = ['id', 'logged_at']


class WorkoutSessionSerializer(serializers.ModelSerializer):
    metrics = ProgressMetricSerializer(many=True, read_only=True)
    user = UserSerializer(read_only=True)

    class Meta:
        model = WorkoutSession
        fields = [
            'id', 'user', 'plan', 'name',
            'started_at', 'finished_at', 'notes', 'metrics',
        ]
        read_only_fields = ['id', 'started_at']


class WorkoutSessionListSerializer(serializers.ModelSerializer):
    metric_count = serializers.IntegerField(source='metrics.count', read_only=True)

    class Meta:
        model = WorkoutSession
        fields = [
            'id', 'plan', 'name', 'started_at',
            'finished_at', 'metric_count',
        ]
        read_only_fields = ['id', 'started_at']
