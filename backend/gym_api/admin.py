"""
Django admin configuration for gym_api models.
"""
from django.contrib import admin
from .models import Profile, Plan, Exercise, WorkoutSession, ProgressMetric


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'display_name', 'created_at']
    search_fields = ['user__username', 'display_name']
    readonly_fields = ['id', 'created_at', 'updated_at']


@admin.register(Plan)
class PlanAdmin(admin.ModelAdmin):
    list_display = ['id', 'name', 'user', 'is_active', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'user__username']
    readonly_fields = ['id', 'created_at', 'updated_at']


@admin.register(Exercise)
class ExerciseAdmin(admin.ModelAdmin):
    list_display = ['id', 'name', 'plan', 'user', 'target_sets', 'target_reps', 'order']
    list_filter = ['created_at']
    search_fields = ['name', 'user__username']
    readonly_fields = ['id', 'created_at']


@admin.register(WorkoutSession)
class WorkoutSessionAdmin(admin.ModelAdmin):
    list_display = ['id', 'name', 'user', 'plan', 'started_at', 'finished_at']
    list_filter = ['started_at', 'finished_at']
    search_fields = ['name', 'user__username']
    readonly_fields = ['id', 'started_at']


@admin.register(ProgressMetric)
class ProgressMetricAdmin(admin.ModelAdmin):
    list_display = ['id', 'session', 'exercise', 'set_number', 'reps', 'weight_kg', 'logged_at']
    list_filter = ['logged_at']
    search_fields = ['session__name', 'exercise__name']
    readonly_fields = ['id', 'logged_at']
