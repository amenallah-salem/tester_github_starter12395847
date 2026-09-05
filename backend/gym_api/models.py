"""
Models for the Gym Planner API.

Profile  – extends Django's built-in User (OneToOne)
Plan     – a named routine belonging to a user
Exercise – an exercise definition, optionally tied to a plan
WorkoutSession  – a concrete instance of a user doing a plan
ProgressMetric  – logged metrics (weight, reps, etc.) per session
"""
import uuid
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator
from django.db import models


class Profile(models.Model):
    """Extended user profile."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    display_name = models.CharField(max_length=100, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'profiles'
        ordering = ['-created_at']

    def __str__(self):
        return self.display_name or self.user.username


class Subscription(models.Model):
    """The current billing state for a user.

    Payment-provider webhooks can update the provider fields without exposing
    them as writable API fields.
    """
    STATUS_CHOICES = [
        ('trialing', 'Trialing'),
        ('active', 'Active'),
        ('past_due', 'Past due'),
        ('canceled', 'Canceled'),
        ('unpaid', 'Unpaid'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='subscription')
    plan_name = models.CharField(max_length=50, default='free')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    current_period_start = models.DateTimeField(null=True, blank=True)
    current_period_end = models.DateTimeField(null=True, blank=True)
    provider_customer_id = models.CharField(max_length=255, blank=True)
    provider_subscription_id = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'subscriptions'

    def __str__(self):
        return f"{self.user.username} – {self.plan_name}"


class Plan(models.Model):
    """A training plan / routine."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='plans')
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'plans'
        ordering = ['-created_at']

    def __str__(self):
        return self.name


class Exercise(models.Model):
    """An exercise definition that can belong to a plan or be a library entry.

    This model was extended to support the Exercise Library. Existing fields
    are preserved. The `user` field is now nullable so library exercises can
    be represented with `is_library=True` and `user=None` (created/managed
    in Django Admin by staff users).
    """
    BODY_PART_CHOICES = [
        ('Chest', 'Chest'),
        ('Back', 'Back'),
        ('Shoulders', 'Shoulders'),
        ('Arms', 'Arms'),
        ('Legs', 'Legs'),
        ('Core', 'Core'),
        ('Other', 'Other'),
    ]
    MOVEMENT_PATTERN_CHOICES = [
        ('Horizontal Push', 'Horizontal Push'),
        ('Vertical Push', 'Vertical Push'),
        ('Horizontal Pull', 'Horizontal Pull'),
        ('Vertical Pull', 'Vertical Pull'),
        ('Squat', 'Squat'),
        ('Lunge', 'Lunge'),
        ('Hinge', 'Hinge'),
        ('Isolation', 'Isolation'),
        ('Core Stabilization', 'Core Stabilization'),
        ('Rotation', 'Rotation'),
        ('Other', 'Other'),
    ]
    EXERCISE_TYPE_CHOICES = [
        ('Compound', 'Compound'),
        ('Isolation', 'Isolation'),
        ('Bodyweight', 'Bodyweight'),
        ('Machine', 'Machine'),
        ('Cardio', 'Cardio'),
        ('Mobility', 'Mobility'),
        ('Other', 'Other'),
    ]
    DIFFICULTY_CHOICES = [
        ('Beginner', 'Beginner'),
        ('Intermediate', 'Intermediate'),
        ('Advanced', 'Advanced'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    plan = models.ForeignKey(Plan, on_delete=models.CASCADE, related_name='exercises', null=True, blank=True)
    # allow user to be null for library/global exercises
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='exercises', null=True, blank=True)
    name = models.CharField(max_length=200)
    aliases = models.JSONField(blank=True, null=True, default=list)
    body_part = models.CharField(max_length=50, choices=BODY_PART_CHOICES, blank=True)
    primary_muscles = models.JSONField(blank=True, null=True, default=list)
    secondary_muscles = models.JSONField(blank=True, null=True, default=list)
    equipment = models.JSONField(blank=True, null=True, default=list)
    movement_pattern = models.CharField(max_length=50, choices=MOVEMENT_PATTERN_CHOICES, blank=True)
    exercise_type = models.CharField(max_length=50, choices=EXERCISE_TYPE_CHOICES, blank=True)
    difficulty = models.CharField(max_length=20, choices=DIFFICULTY_CHOICES, blank=True)

    instructions = models.TextField(blank=True)
    setup = models.TextField(blank=True)
    execution = models.TextField(blank=True)
    breathing = models.TextField(blank=True)
    common_mistakes = models.JSONField(blank=True, null=True, default=list)

    alternatives = models.ManyToManyField('self', blank=True, symmetrical=False, related_name='alternative_for')
    progression_exercises = models.ManyToManyField('self', blank=True, symmetrical=False, related_name='progression_for')
    regression_exercises = models.ManyToManyField('self', blank=True, symmetrical=False, related_name='regression_for')

    video_url = models.URLField(blank=True, null=True)
    animation_url = models.URLField(blank=True, null=True)
    image = models.ImageField(upload_to='exercises/', blank=True, null=True)

    # Preserve original targets for per-user plan exercises
    target_sets = models.PositiveIntegerField(default=3, validators=[MinValueValidator(1)])
    target_reps = models.PositiveIntegerField(default=10, validators=[MinValueValidator(1)])
    target_weight_kg = models.DecimalField(
        max_digits=6, decimal_places=2, null=True, blank=True,
        validators=[MinValueValidator(0)]
    )

    order = models.PositiveIntegerField(default=0)
    is_library = models.BooleanField(default=False, help_text='True when this exercise is part of the global library')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'exercises'
        ordering = ['plan', 'order', 'created_at']
        indexes = [
            models.Index(fields=['name']),
            models.Index(fields=['body_part']),
            models.Index(fields=['movement_pattern']),
            models.Index(fields=['difficulty']),
        ]
        constraints = [
            models.UniqueConstraint(fields=['name', 'plan', 'user'], name='unique_exercise_per_owner')
        ]

    def __str__(self):
        return self.name


class WorkoutSession(models.Model):
    """A concrete workout session instance."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='workout_sessions')
    plan = models.ForeignKey(Plan, on_delete=models.SET_NULL, null=True, blank=True, related_name='sessions')
    name = models.CharField(max_length=200, blank=True)
    started_at = models.DateTimeField(auto_now_add=True)
    finished_at = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(blank=True)

    class Meta:
        db_table = 'workout_sessions'
        ordering = ['-started_at']
        verbose_name = 'Workout Session'
        verbose_name_plural = 'Workout Sessions'

    def __str__(self):
        label = self.name or f"Session {self.id}"
        return f"{label} – {self.user.username}"


class ProgressMetric(models.Model):
    """Logged metric for a workout session (weight, reps, etc.)."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    session = models.ForeignKey(WorkoutSession, on_delete=models.CASCADE, related_name='metrics')
    exercise = models.ForeignKey(Exercise, on_delete=models.SET_NULL, null=True, related_name='metrics')
    set_number = models.PositiveIntegerField(default=1, validators=[MinValueValidator(1)])
    reps = models.PositiveIntegerField(default=0, validators=[MinValueValidator(0)])
    weight_kg = models.DecimalField(
        max_digits=6, decimal_places=2, null=True, blank=True,
        validators=[MinValueValidator(0)]
    )
    duration_seconds = models.PositiveIntegerField(null=True, blank=True)
    logged_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'progress_metrics'
        ordering = ['session', 'exercise', 'set_number']
        verbose_name = 'Progress Metric'
        verbose_name_plural = 'Progress Metrics'

    def __str__(self):
        return f"{self.exercise.name if self.exercise else '?'} – Set {self.set_number}"
