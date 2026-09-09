"""
Django admin configuration for gym_api models.

Uses django-unfold for the visual theme (see UNFOLD in settings.py); the
ModelAdmin/TabularInline base classes below come from `unfold.admin` rather
than the stock `django.contrib.admin` so every registered model picks up the
theme automatically.
"""
from django.contrib import admin
from django.contrib.auth.admin import GroupAdmin as BaseGroupAdmin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import Group, User
from django.utils.html import format_html
from unfold.admin import ModelAdmin, TabularInline

from .models import (
    Profile, Plan, PlanDay, PlanDayExercise, Exercise, WorkoutSession,
    ProgressMetric, BodyWeightEntry, FavoriteExercise, Subscription,
    Swipe, Match, GymBroMessage,
)


# ---------------------------------------------------------------------------
# People
# ---------------------------------------------------------------------------

# django.contrib.auth registers User/Group with its own UserAdmin/GroupAdmin,
# which subclass the *stock* django.contrib.admin.ModelAdmin rather than
# unfold's. Unfold's changelist template renders each bulk action's "Run"
# button with `x-show="action"`, which only becomes true once the action
# <select> updates an Alpine `x-model="action"` binding — a binding only
# unfold.admin.ModelAdmin's ActionForm widget sets. Without it (the stock
# admin's default ActionForm), the Run button never appears, so bulk actions
# (e.g. "Delete selected users") are otherwise impossible to submit. Re-
# registering under unfold.admin.ModelAdmin (mixed in ahead of the stock
# UserAdmin/GroupAdmin so its ActionForm wins) fixes this while keeping all
# of Django's normal user/group admin behavior (password change, permissions
# widgets, etc.).
admin.site.unregister(User)
admin.site.unregister(Group)


@admin.register(User)
class UserAdmin(ModelAdmin, BaseUserAdmin):
    pass


@admin.register(Group)
class GroupAdmin(ModelAdmin, BaseGroupAdmin):
    pass


@admin.register(Profile)
class ProfileAdmin(ModelAdmin):
    list_display = ['display_name_or_username', 'user', 'experience_level', 'onboarding_completed', 'created_at']
    list_filter = ['onboarding_completed', 'experience_level']
    search_fields = ['user__username', 'user__email', 'display_name']
    autocomplete_fields = ['user']
    readonly_fields = ['id', 'created_at', 'updated_at']

    @admin.display(description='Name')
    def display_name_or_username(self, obj):
        return obj.display_name or obj.user.username


@admin.register(Subscription)
class SubscriptionAdmin(ModelAdmin):
    list_display = ['user', 'plan_name', 'status', 'current_period_start', 'current_period_end']
    list_filter = ['status', 'plan_name']
    search_fields = ['user__username']
    autocomplete_fields = ['user']
    readonly_fields = ['id', 'created_at', 'updated_at']


# ---------------------------------------------------------------------------
# Exercise library — the main "content" model, so this gets the most care:
# media previews, autocomplete pickers for the self-referential relations,
# and fieldsets grouped the way a content editor actually thinks about an
# exercise rather than in raw model-field order.
# ---------------------------------------------------------------------------

def _media_preview(url, kind):
    if not url:
        return '—'
    if kind == 'image':
        return format_html('<img src="{}" style="max-height:120px;max-width:160px;border-radius:6px;object-fit:cover;" />', url)
    if kind == 'video':
        return format_html(
            '<video src="{}" controls style="max-height:160px;max-width:240px;border-radius:6px;"></video>', url,
        )
    return '—'


@admin.register(Exercise)
class ExerciseAdmin(ModelAdmin):
    list_display = [
        'thumbnail', 'name', 'body_part', 'difficulty', 'exercise_type',
        'is_library', 'has_video', 'user',
    ]
    list_display_links = ['thumbnail', 'name']
    list_filter = ['body_part', 'difficulty', 'exercise_type', 'movement_pattern', 'is_library', 'is_timed']
    search_fields = ['name', 'aliases', 'body_part', 'primary_muscles', 'secondary_muscles', 'equipment']
    autocomplete_fields = ['plan', 'user', 'alternatives', 'progression_exercises', 'regression_exercises']
    readonly_fields = ['id', 'created_at', 'image_preview', 'video_preview', 'animation_preview']
    list_per_page = 25

    fieldsets = (
        ('General', {
            'fields': ('name', 'aliases', 'body_part', 'difficulty', 'exercise_type', 'is_timed', 'is_library'),
        }),
        ('Muscles & equipment', {
            'fields': ('primary_muscles', 'secondary_muscles', 'equipment', 'movement_pattern'),
        }),
        ('Instructions', {
            'fields': ('description', 'instructions', 'setup', 'execution', 'breathing', 'common_mistakes'),
        }),
        ('Related exercises', {
            'description': 'Shown to users as "easier" / "harder" / "swap for" options on the exercise detail screen.',
            'fields': ('alternatives', 'progression_exercises', 'regression_exercises'),
        }),
        ('Image', {
            'fields': ('image', 'image_preview'),
        }),
        ('Video', {
            'description': (
                'Upload a file for content you host yourself, or paste an external link '
                '(e.g. YouTube). If both are set, the uploaded file is what the app shows.'
            ),
            'fields': ('video', 'video_url', 'video_preview'),
        }),
        ('Looping form animation', {
            'fields': ('animation', 'animation_url', 'animation_preview'),
        }),
        ('Plan assignment (only for a user-specific, non-library exercise)', {
            'classes': ('collapse',),
            'fields': ('plan', 'user', 'target_sets', 'target_reps', 'target_weight_kg', 'order'),
        }),
        ('Metadata', {
            'classes': ('collapse',),
            'fields': ('id', 'created_at'),
        }),
    )

    @admin.display(description='')
    def thumbnail(self, obj):
        if obj.image:
            return format_html('<img src="{}" style="height:40px;width:40px;border-radius:6px;object-fit:cover;" />', obj.image.url)
        return format_html('<span style="opacity:.4;">—</span>')

    @admin.display(description='Video', boolean=True)
    def has_video(self, obj):
        return bool(obj.video or obj.video_url)

    @admin.display(description='Image preview')
    def image_preview(self, obj):
        return _media_preview(obj.image.url if obj.image else '', 'image')

    @admin.display(description='Video preview')
    def video_preview(self, obj):
        url = obj.video.url if obj.video else (obj.video_url or '')
        return _media_preview(url, 'video')

    @admin.display(description='Animation preview')
    def animation_preview(self, obj):
        url = obj.animation.url if obj.animation else (obj.animation_url or '')
        # Animations are typically short mp4/webm loops or gifs — a video
        # tag renders both reasonably; fall back to an image tag for a
        # plain image/gif URL that a <video> tag can't play.
        if url.lower().endswith(('.gif', '.png', '.jpg', '.jpeg', '.webp')):
            return _media_preview(url, 'image')
        return _media_preview(url, 'video')


# ---------------------------------------------------------------------------
# Plans — weekly schedule editing. PlanDay is edited on its own admin page
# (with its exercise assignments inline) rather than nested two levels deep,
# since Django admin doesn't support inline-within-inline.
# ---------------------------------------------------------------------------

class PlanDayInline(TabularInline):
    model = PlanDay
    extra = 0
    fields = ['weekday']
    show_change_link = True


@admin.register(Plan)
class PlanAdmin(ModelAdmin):
    list_display = ['name', 'user', 'is_active', 'exercise_count', 'created_at']
    list_filter = ['is_active']
    search_fields = ['name', 'user__username']
    autocomplete_fields = ['user']
    readonly_fields = ['id', 'created_at', 'updated_at']
    inlines = [PlanDayInline]

    @admin.display(description='Exercises')
    def exercise_count(self, obj):
        return obj.exercises.count()


class PlanDayExerciseInline(TabularInline):
    model = PlanDayExercise
    extra = 1
    autocomplete_fields = ['exercise']
    fields = ['exercise', 'order']


@admin.register(PlanDay)
class PlanDayAdmin(ModelAdmin):
    list_display = ['plan', 'weekday_label', 'assignment_count']
    list_filter = ['weekday']
    search_fields = ['plan__name']
    autocomplete_fields = ['plan']
    inlines = [PlanDayExerciseInline]

    WEEKDAY_LABELS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

    @admin.display(description='Weekday')
    def weekday_label(self, obj):
        return self.WEEKDAY_LABELS[obj.weekday] if 0 <= obj.weekday <= 6 else obj.weekday

    @admin.display(description='Exercises')
    def assignment_count(self, obj):
        return obj.assignments.count()


# ---------------------------------------------------------------------------
# Activity / progress — mostly app-generated, so admin access here is for
# support/debugging rather than day-to-day content entry: kept read-only-ish
# (no manual "add" workflow expected) but fully searchable/filterable.
# ---------------------------------------------------------------------------

@admin.register(WorkoutSession)
class WorkoutSessionAdmin(ModelAdmin):
    list_display = ['name_or_default', 'user', 'plan', 'started_at', 'finished_at']
    list_filter = ['started_at', 'finished_at']
    search_fields = ['name', 'user__username']
    autocomplete_fields = ['user', 'plan']
    readonly_fields = ['id', 'started_at']

    @admin.display(description='Session')
    def name_or_default(self, obj):
        return obj.name or f'Session {obj.id}'


@admin.register(ProgressMetric)
class ProgressMetricAdmin(ModelAdmin):
    list_display = ['exercise', 'session', 'set_number', 'reps', 'weight_kg', 'duration_seconds', 'logged_at']
    list_filter = ['logged_at']
    search_fields = ['session__name', 'exercise__name']
    autocomplete_fields = ['session', 'exercise']
    readonly_fields = ['id', 'logged_at']


@admin.register(BodyWeightEntry)
class BodyWeightEntryAdmin(ModelAdmin):
    list_display = ['user', 'weight_kg', 'logged_at']
    list_filter = ['logged_at']
    search_fields = ['user__username']
    autocomplete_fields = ['user']
    readonly_fields = ['id', 'logged_at']


@admin.register(FavoriteExercise)
class FavoriteExerciseAdmin(ModelAdmin):
    list_display = ['user', 'exercise']
    search_fields = ['user__username', 'exercise__name']
    autocomplete_fields = ['user', 'exercise']


# ---------------------------------------------------------------------------
# Gym Bro (social matching) — separate domain from training; only shares
# Profile/User. Kept here mainly for moderation/support lookups.
# ---------------------------------------------------------------------------

@admin.register(Swipe)
class SwipeAdmin(ModelAdmin):
    list_display = ['from_user', 'direction', 'to_user', 'created_at']
    list_filter = ['direction']
    search_fields = ['from_user__username', 'to_user__username']
    autocomplete_fields = ['from_user', 'to_user']
    readonly_fields = ['id', 'created_at', 'updated_at']


class GymBroMessageInline(TabularInline):
    model = GymBroMessage
    extra = 0
    fields = ['sender', 'text', 'created_at']
    readonly_fields = ['created_at']
    autocomplete_fields = ['sender']


@admin.register(Match)
class MatchAdmin(ModelAdmin):
    list_display = ['user_low', 'user_high', 'message_count', 'created_at']
    search_fields = ['user_low__username', 'user_high__username']
    autocomplete_fields = ['user_low', 'user_high']
    readonly_fields = ['id', 'created_at']
    inlines = [GymBroMessageInline]

    @admin.display(description='Messages')
    def message_count(self, obj):
        return obj.messages.count()


@admin.register(GymBroMessage)
class GymBroMessageAdmin(ModelAdmin):
    list_display = ['sender', 'match', 'text_preview', 'created_at']
    search_fields = ['sender__username', 'text']
    autocomplete_fields = ['match', 'sender']
    readonly_fields = ['id', 'created_at']

    @admin.display(description='Message')
    def text_preview(self, obj):
        return obj.text if len(obj.text) <= 60 else obj.text[:57] + '…'
