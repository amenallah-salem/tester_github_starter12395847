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
        'Push Pull Legs',
        (
            'Classic 3-way body-part split (push, pull, legs) run twice per week '
            '(6 training days, Thursday rest) so every muscle group is trained '
            'roughly every 3-4 days -- the frequency research links to the best '
            'hypertrophy outcomes for this split. See docs/workout-plans.md for sources.'
        ),
        {
            # Push: chest, front/lateral delts, triceps
            MON: ['Barbell Bench Press', 'Incline Dumbbell Press', 'Barbell Overhead Press',
                  'Dumbbell Lateral Raise', 'Triceps Pushdown', 'Lying Triceps Extension'],
            # Pull: lats, upper back, traps, rear delts, biceps
            TUE: ['Pull-up', 'Bent Over Barbell Row', 'Seated Cable Row',
                  'Dumbbell Rear Delt Fly', 'Barbell Curl', 'Dumbbell Hammer Curl'],
            # Legs: quads, hamstrings, glutes, calves
            WED: ['Barbell Back Squat', 'Romanian Deadlift', 'Walking Lunge',
                  'Leg Extension', 'Lying Leg Curl', 'Standing Calf Raise'],
            # THU: rest
            FRI: ['Barbell Bench Press', 'Incline Dumbbell Press', 'Barbell Overhead Press',
                  'Dumbbell Lateral Raise', 'Triceps Pushdown', 'Lying Triceps Extension'],
            SAT: ['Pull-up', 'Bent Over Barbell Row', 'Seated Cable Row',
                  'Dumbbell Rear Delt Fly', 'Barbell Curl', 'Dumbbell Hammer Curl'],
            SUN: ['Barbell Back Squat', 'Romanian Deadlift', 'Walking Lunge',
                  'Leg Extension', 'Lying Leg Curl', 'Standing Calf Raise'],
        },
    ),
    (
        'Full Body',
        (
            'Three full-body sessions per week (Mon/Wed/Fri), each covering every '
            'major movement pattern -- squat, hinge, horizontal/vertical push, '
            'horizontal/vertical pull, plus arms and core -- with varied exercise '
            'selection across A/B/C so the same muscles are trained through '
            'different angles. See docs/workout-plans.md for sources.'
        ),
        {
            MON: ['Barbell Back Squat', 'Romanian Deadlift', 'Barbell Bench Press',
                  'Barbell Overhead Press', 'Bent Over Barbell Row', 'Lat Pulldown',
                  'Barbell Curl', 'Front Plank'],
            WED: ['Leg Press', 'Barbell Hip Thrust', 'Incline Dumbbell Press',
                  'Arnold Press', 'Seated Cable Row', 'Pull-up',
                  'Triceps Pushdown', 'Cable Crunch'],
            FRI: ['Walking Lunge', 'Glute Bridge', 'Push-up',
                  'Barbell Overhead Press', 'Bent Over Barbell Row', 'Lat Pulldown',
                  'Dumbbell Hammer Curl', 'Hanging Leg Raise'],
        },
    ),
    (
        'Upper Lower',
        (
            '4-day upper/lower split (Mon/Tue, Thu/Fri, weekend rest) hitting '
            'each muscle group twice a week -- the frequency research ties to '
            'reliable hypertrophy -- with a different exercise selection on the '
            'B days to vary angles and equipment. See docs/workout-plans.md for sources.'
        ),
        {
            MON: ['Barbell Bench Press', 'Lat Pulldown', 'Seated Cable Row',
                  'Barbell Overhead Press', 'Barbell Curl', 'Triceps Pushdown'],
            TUE: ['Barbell Back Squat', 'Romanian Deadlift', 'Walking Lunge',
                  'Lying Leg Curl', 'Standing Calf Raise'],
            # WED: rest
            THU: ['Incline Dumbbell Press', 'Pull-up', 'Bent Over Barbell Row',
                  'Dumbbell Lateral Raise', 'Dumbbell Hammer Curl', 'Lying Triceps Extension'],
            FRI: ['Leg Press', 'Romanian Deadlift', 'Walking Lunge',
                  'Leg Extension', 'Lying Leg Curl', 'Seated Calf Raise'],
            # SAT/SUN: rest
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

# Plans that were superseded by a more research-aligned, correctly named
# version above. Only ever removed for the seed-owned demo user, never for a
# real user's data.
SUPERSEDED_PLAN_NAMES = ['Push / Pull / Legs', 'Upper / Lower Split']


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

        superseded_qs = Plan.objects.filter(user=demo_user, name__in=SUPERSEDED_PLAN_NAMES)
        removed = superseded_qs.count()
        superseded_qs.delete()
        if removed:
            self.stdout.write(self.style.WARNING(
                f'Removed {removed} superseded demo plan(s) (renamed to their new equivalents).'
            ))

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
