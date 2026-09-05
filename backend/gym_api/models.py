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
    """An exercise definition that can belong to a plan."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    plan = models.ForeignKey(Plan, on_delete=models.CASCADE, related_name='exercises', null=True, blank=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='exercises')
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    # Image illustrating the exercise (auto-generated if not provided)
    image = models.ImageField(upload_to='exercises/', null=True, blank=True)
    target_sets = models.PositiveIntegerField(default=3, validators=[MinValueValidator(1)])
    target_reps = models.PositiveIntegerField(default=10, validators=[MinValueValidator(1)])
    target_weight_kg = models.DecimalField(
        max_digits=6, decimal_places=2, null=True, blank=True,
        validators=[MinValueValidator(0)]
    )
    order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'exercises'
        ordering = ['plan', 'order', 'created_at']

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
