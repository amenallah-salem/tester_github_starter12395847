from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.db import transaction

from gym_api.models import Exercise, Plan, PlanDay, PlanDayExercise

DEMO_USERNAME = 'wellaura_demo'

# weekday: 0=Monday ... 6=Sunday (see PlanDay.weekday)
MON, TUE, WED, THU, FRI, SAT, SUN = range(7)

# Each program: name, description, {weekday: [exercise names, in order]}
PROGRAMS = [
    (
        'Push / Pull / Legs',
        '3-day split: Push (chest/shoulders/triceps), Pull (back/biceps), Legs.',
        {
            MON: ['Barbell Bench Press', 'Barbell Overhead Press', 'Triceps Pushdown', 'Dumbbell Lateral Raise'],
            WED: ['Pull-up', 'Bent Over Barbell Row', 'Barbell Curl', 'Dumbbell Rear Delt Fly'],
            FRI: ['Barbell Back Squat', 'Romanian Deadlift', 'Leg Press', 'Standing Calf Raise'],
        },
    ),
    (
        'Upper / Lower Split',
        '4-day split alternating upper body and lower body sessions.',
        {
            MON: ['Barbell Bench Press', 'Bent Over Barbell Row', 'Barbell Overhead Press', 'Barbell Curl'],
            TUE: ['Barbell Back Squat', 'Romanian Deadlift', 'Leg Extension', 'Standing Calf Raise'],
            THU: ['Incline Dumbbell Press', 'Lat Pulldown', 'Triceps Pushdown', 'Dumbbell Hammer Curl'],
            FRI: ['Barbell Hip Thrust', 'Lying Leg Curl', 'Walking Lunge', 'Seated Calf Raise'],
        },
    ),
    (
        'Full Body Beginner (3-day)',
        'Beginner-friendly full body routine performed three times a week.',
        {
            MON: ['Barbell Back Squat', 'Barbell Bench Press', 'Seated Cable Row', 'Front Plank'],
            WED: ['Romanian Deadlift', 'Incline Dumbbell Press', 'Lat Pulldown', 'Front Plank'],
            FRI: ['Barbell Back Squat', 'Barbell Overhead Press', 'Seated Cable Row', 'Russian Twist'],
        },
    ),
    (
        '5-Day Hypertrophy',
        'Five-day muscle-group split for hypertrophy-focused training.',
        {
            MON: ['Barbell Bench Press', 'Incline Dumbbell Press', 'Cable Chest Fly', 'Chest Dip'],
            TUE: ['Deadlift', 'Bent Over Barbell Row', 'Lat Pulldown', 'Seated Cable Row'],
            WED: ['Barbell Overhead Press', 'Dumbbell Lateral Raise', 'Dumbbell Rear Delt Fly', 'Arnold Press'],
            THU: ['Barbell Back Squat', 'Romanian Deadlift', 'Leg Press', 'Leg Extension', 'Standing Calf Raise'],
            FRI: ['Barbell Curl', 'Dumbbell Hammer Curl', 'Triceps Pushdown', 'Lying Triceps Extension'],
        },
    ),
    (
        'Push / Pull',
        'Two-day push/pull split, great as an accessory to a main program.',
        {
            MON: ['Barbell Bench Press', 'Barbell Overhead Press', 'Triceps Pushdown'],
            THU: ['Pull-up', 'Bent Over Barbell Row', 'Barbell Curl'],
        },
    ),
    (
        'Beginner Strength (3-day)',
        'Compound-lift focused strength program for beginners.',
        {
            MON: ['Barbell Back Squat', 'Barbell Bench Press', 'Bent Over Barbell Row'],
            WED: ['Deadlift', 'Barbell Overhead Press', 'Pull-up'],
            FRI: ['Barbell Back Squat', 'Barbell Bench Press', 'Bent Over Barbell Row'],
        },
    ),
    (
        'Home Workout (bodyweight)',
        'Equipment-free full body sessions suitable for home training.',
        {
            MON: ['Push-up', 'Glute Bridge', 'Front Plank', 'Russian Twist'],
            WED: ['Burpee', 'Walking Lunge', 'Side Plank', 'Jump Rope'],
            FRI: ['Push-up', 'Glute Bridge', 'Hanging Knee Raise', 'Jump Rope'],
        },
    ),
]


class Command(BaseCommand):
    help = 'Seed example workout plans/programs using the exercise library (idempotent).'

    def handle(self, *args, **options):
        User = get_user_model()
        demo_user, _ = User.objects.get_or_create(
            username=DEMO_USERNAME,
            defaults={'email': 'demo@wellaura.local', 'first_name': 'Wellaura', 'last_name': 'Demo'},
        )
        if not demo_user.has_usable_password():
            demo_user.set_unusable_password()
            demo_user.save(update_fields=['password'])

        exercises_by_name = {
            exercise.name: exercise
            for exercise in Exercise.objects.filter(is_library=True)
        }

        plans_created = 0
        days_written = 0
        assignments_written = 0

        for name, description, schedule in PROGRAMS:
            missing = [
                exercise_name
                for exercise_names in schedule.values()
                for exercise_name in exercise_names
                if exercise_name not in exercises_by_name
            ]
            if missing:
                self.stdout.write(self.style.WARNING(
                    f'Skipping plan "{name}": missing library exercises {sorted(set(missing))}. '
                    'Run `seed_exercises` first.'
                ))
                continue

            with transaction.atomic():
                plan, was_created = Plan.objects.get_or_create(
                    user=demo_user, name=name,
                    defaults={'description': description, 'is_active': True},
                )
                if not was_created and plan.description != description:
                    plan.description = description
                    plan.save(update_fields=['description'])
                if was_created:
                    plans_created += 1

                for weekday, exercise_names in schedule.items():
                    day, _ = PlanDay.objects.get_or_create(plan=plan, weekday=weekday)
                    days_written += 1
                    # Recreate this day's assignments so re-running the seed
                    # stays in sync with PROGRAMS without ever duplicating rows.
                    PlanDayExercise.objects.filter(plan_day=day).delete()
                    PlanDayExercise.objects.bulk_create([
                        PlanDayExercise(
                            plan_day=day,
                            exercise=exercises_by_name[exercise_name],
                            order=order,
                        )
                        for order, exercise_name in enumerate(exercise_names)
                    ])
                    assignments_written += len(exercise_names)

        self.stdout.write(self.style.SUCCESS(
            f'Workout plans seeded (plans_created={plans_created}, '
            f'days_written={days_written}, assignments_written={assignments_written}).'
        ))
