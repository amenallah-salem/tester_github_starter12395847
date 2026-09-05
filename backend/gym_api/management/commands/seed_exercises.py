from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from gym_api.models import Exercise

EXERCISES = {
    'Chest': [
        'Bench Press', 'Incline Bench Press', 'Dumbbell Bench Press', 'Lever Chest Press',
        'Lever Seated Fly', 'Cable Standing Fly', 'Push-up', 'Chest Dip', 'Lying Hammer Press',
        'Lever Lying Chest Press'
    ],
    'Back': [
        'Bent Over Row', 'One Arm Bent-over Row', 'Straight Back Seated Row', 'Bar Lateral Pulldown',
        'Low Seated Row', 'Pulldown', 'Lever Front Pulldown', 'Lever Lateral Pulldown',
        'Lever One Arm Low Row', 'Cable One Arm Twisting Seated Row'
    ],
    'Shoulders': [
        'Lateral Raise', 'Dumbbell Lateral Raise', 'Barbell Standing Military Press', 'Seated Shoulder Press',
        'Dumbbell Front Raise', 'Dumbbell Rear Delt Fly', 'Cable One Arm Lateral Raise'
    ],
    'Arms': [
        'Barbell Curl', 'Hammer Curl', 'Alternate Biceps Curl', 'Dumbbell Incline Curl',
        'Triceps Pushdown', 'Overhead Triceps Extension', 'Lying Triceps Extension', 'Triceps Dip',
        'One Arm Side Triceps Pushdown'
    ],
    'Legs': [
        'Full Squat', 'Bulgarian Split Squat', 'Reverse Lunge', 'Lever Leg Extension',
        'Lever Seated Leg Curl', 'Lever Lying Leg Curl', 'Standing Calf Raise', 'Lever Seated Calf Raise',
        'Sled Hack Squat'
    ],
    'Core': [
        'Front Plank', 'Side Plank', 'Cable Kneeling Crunch', 'Lying Leg Raise', 'Reverse Crunch',
        'Hanging Leg Raise', 'Weighted Russian Twist'
    ]
}

class Command(BaseCommand):
    help = 'Seed the exercise library (idempotent).'

    def handle(self, *args, **options):
        User = get_user_model()
        admin_user = User.objects.filter(is_superuser=True).first()
        if not admin_user:
            self.stdout.write(self.style.WARNING('No superuser found; create one or run again after creating a superuser.'))
            admin_user = None

        created = 0
        for body_part, names in EXERCISES.items():
            for name in names:
                obj, was_created = Exercise.objects.get_or_create(
                    name=name,
                    is_library=True,
                    defaults={
                        'body_part': body_part,
                        'aliases': [],
                        'primary_muscles': [],
                        'secondary_muscles': [],
                        'equipment': [],
                        'movement_pattern': '',
                        'exercise_type': '',
                        'difficulty': '',
                        'instructions': '',
                        'setup': '',
                        'execution': '',
                        'breathing': '',
                        'common_mistakes': [],
                        'video_url': None,
                        'animation_url': None,
                        'user': admin_user,
                    }
                )
                if was_created:
                    created += 1
        self.stdout.write(self.style.SUCCESS(f'Exercise library seeded (created={created}).'))
