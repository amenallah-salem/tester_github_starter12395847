"""
REST serializers for the Gym Planner API.
"""
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from .models import (
    Profile, Plan, Exercise, PlanDay, PlanDayExercise,
    WorkoutSession, ProgressMetric, BodyWeightEntry, FavoriteExercise, Subscription,
    Swipe, Match, GymBroMessage,
)


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
        fields = [
            'id', 'user', 'display_name', 'created_at', 'updated_at',
            'onboarding_completed', 'onboarding_completed_at', 'locale', 'country',
            'bio', 'training_goals', 'experience_level', 'availability', 'location',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def validate_training_goals(self, value):
        if value in (None, ''):
            return []
        if not isinstance(value, list):
            raise serializers.ValidationError('training_goals must be a list.')
        valid_goals = {choice for choice, _ in Profile.GOAL_CHOICES}
        invalid = [goal for goal in value if goal not in valid_goals]
        if invalid:
            raise serializers.ValidationError(f'Invalid goal(s): {invalid}')
        return value


class SwipeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Swipe
        fields = ['id', 'to_user', 'direction', 'created_at']
        read_only_fields = ['id', 'created_at']

    def validate_to_user(self, value):
        request_user = self.context['request'].user
        if value.id == request_user.id:
            raise serializers.ValidationError("You can't swipe on your own profile.")
        return value

    def validate_direction(self, value):
        if value not in (Swipe.LIKE, Swipe.PASS):
            raise serializers.ValidationError('direction must be "like" or "pass".')
        return value


class GymBroMessageSerializer(serializers.ModelSerializer):
    sender = UserSerializer(read_only=True)

    class Meta:
        model = GymBroMessage
        fields = ['id', 'match', 'sender', 'text', 'created_at']
        read_only_fields = ['id', 'match', 'sender', 'created_at']

    def validate_text(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError('Message text cannot be empty.')
        return value


class MatchSerializer(serializers.ModelSerializer):
    """A Gym Bro match, including the *other* participant's profile."""
    profile = serializers.SerializerMethodField()

    class Meta:
        model = Match
        fields = ['id', 'profile', 'created_at']

    def get_profile(self, obj):
        request_user = self.context['request'].user
        other = obj.other_user(request_user)
        profile, _ = Profile.objects.get_or_create(user=other)
        return ProfileSerializer(profile, context=self.context).data


class ExerciseMinimalSerializer(serializers.ModelSerializer):
    """Compact exercise shape for nesting inside another exercise's relations."""

    class Meta:
        model = Exercise
        fields = ['id', 'name', 'body_part', 'difficulty', 'equipment', 'primary_muscles']


class ExerciseSerializer(serializers.ModelSerializer):
    image = serializers.ImageField(read_only=True)
    alternatives_detail = ExerciseMinimalSerializer(source='alternatives', many=True, read_only=True)
    progression_exercises_detail = ExerciseMinimalSerializer(
        source='progression_exercises', many=True, read_only=True,
    )
    regression_exercises_detail = ExerciseMinimalSerializer(
        source='regression_exercises', many=True, read_only=True,
    )

    class Meta:
        model = Exercise
        fields = [
            'id', 'plan', 'user', 'name', 'description', 'aliases', 'body_part',
            'primary_muscles', 'secondary_muscles', 'equipment',
            'movement_pattern', 'exercise_type', 'difficulty', 'is_timed',
            'instructions', 'setup', 'execution', 'breathing', 'common_mistakes',
            'alternatives', 'progression_exercises', 'regression_exercises',
            'alternatives_detail', 'progression_exercises_detail', 'regression_exercises_detail',
            'video_url', 'animation_url', 'image',
            'target_sets', 'target_reps', 'target_weight_kg',
            'order', 'is_library', 'created_at',
        ]
        read_only_fields = ['id', 'user', 'created_at']
        extra_kwargs = {
            'plan': {'required': False, 'allow_null': True},
            'aliases': {'required': False},
            'primary_muscles': {'required': False},
            'secondary_muscles': {'required': False},
            'equipment': {'required': False},
            'alternatives': {'required': False},
            'progression_exercises': {'required': False},
            'regression_exercises': {'required': False},
            'video_url': {'required': False, 'allow_null': True},
            'animation_url': {'required': False, 'allow_null': True},
            'image': {'required': False, 'allow_null': True},
        }


    def validate_plan(self, plan):
        user = self.context['request'].user
        if plan is not None and plan.user_id != user.id:
            raise serializers.ValidationError('You can only use your own plans.')
        return plan

    def validate(self, attrs):
        # If marking as library, user should be None (admin-managed)
        is_library = attrs.get('is_library', getattr(self.instance, 'is_library', False))
        user = attrs.get('user', getattr(self.instance, 'user', None))
        if is_library and user is not None:
            raise serializers.ValidationError({'user': 'Library exercises should not be tied to a user.'})
        return attrs


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


class PlanDayExerciseSerializer(serializers.ModelSerializer):
    exercise_name = serializers.CharField(source='exercise.name', read_only=True)

    class Meta:
        model = PlanDayExercise
        fields = ['exercise', 'exercise_name', 'order']


class PlanDaySerializer(serializers.ModelSerializer):
    assignments = PlanDayExerciseSerializer(many=True, read_only=True)

    class Meta:
        model = PlanDay
        fields = ['weekday', 'assignments']


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
        # allow library exercises (exercise.user may be None)
        if exercise and exercise.user_id is not None and exercise.user_id != user.id:
            raise serializers.ValidationError({'exercise': 'This exercise does not belong to you.'})
        if session and exercise and exercise.plan_id and session.plan_id != exercise.plan_id:
            raise serializers.ValidationError({'exercise': 'The exercise must belong to the session plan.'})
        return attrs


class BodyWeightEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = BodyWeightEntry
        fields = ['id', 'weight_kg', 'logged_at']
        read_only_fields = ['id', 'logged_at']


class FavoriteExerciseSerializer(serializers.ModelSerializer):
    exercise_name = serializers.CharField(source='exercise.name', read_only=True)

    class Meta:
        model = FavoriteExercise
        fields = ['id', 'exercise', 'exercise_name']
        read_only_fields = ['id']

    def validate_exercise(self, exercise):
        user = self.context['request'].user
        if exercise.user_id not in (None, user.id) and not exercise.is_library:
            raise serializers.ValidationError('You can only favorite library or your own exercises.')
        return exercise


class WorkoutSessionSerializer(serializers.ModelSerializer):
    metrics = ProgressMetricSerializer(many=True, read_only=True)
    user = UserSerializer(read_only=True)
    duration_seconds = serializers.SerializerMethodField()
    total_volume_kg = serializers.SerializerMethodField()

    class Meta:
        model = WorkoutSession
        fields = [
            'id', 'user', 'plan', 'name',
            'scheduled_for', 'started_at', 'finished_at', 'notes', 'metrics',
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
            'scheduled_for', 'finished_at', 'metric_count', 'exercise_names',
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
