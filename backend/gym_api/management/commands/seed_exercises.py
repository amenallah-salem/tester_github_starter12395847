import re

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand

from gym_api.models import Exercise

MEDIA_BASE = 'https://example.com/wellaura/exercises'


def _slug(name):
    return re.sub(r'[^a-z0-9]+', '-', name.lower()).strip('-')


# Each entry: (name, body_part, primary_muscles, secondary_muscles, equipment,
#              movement_pattern, exercise_type, difficulty, sets, reps, instructions)
EXERCISES = [
    # Chest
    ('Barbell Bench Press', 'Chest', ['Chest'], ['Triceps', 'Shoulders'], ['Barbell', 'Bench'],
     'Horizontal Push', 'Compound', 'Intermediate', 4, 8,
     'Lie on a flat bench, lower the bar to mid-chest, then press up to lockout.'),
    ('Incline Dumbbell Press', 'Chest', ['Chest'], ['Shoulders', 'Triceps'], ['Dumbbell', 'Bench'],
     'Horizontal Push', 'Compound', 'Intermediate', 4, 10,
     'On an incline bench, press dumbbells up and slightly inward, then lower under control.'),
    ('Push-up', 'Chest', ['Chest'], ['Triceps', 'Shoulders', 'Abdominals'], ['Bodyweight'],
     'Horizontal Push', 'Bodyweight', 'Beginner', 3, 15,
     'Keep a straight body line, lower chest to the floor, and press back up.'),
    ('Cable Chest Fly', 'Chest', ['Chest'], ['Shoulders'], ['Cable Machine'],
     'Isolation', 'Isolation', 'Beginner', 3, 12,
     'With a slight elbow bend, bring the handles together in front of the chest and return slowly.'),
    ('Chest Dip', 'Chest', ['Chest'], ['Triceps', 'Shoulders'], ['Dip Bars'],
     'Horizontal Push', 'Bodyweight', 'Advanced', 3, 10,
     'Lean forward and lower until a stretch is felt in the chest, then press back up.'),

    # Back
    ('Deadlift', 'Back', ['Lower Back'], ['Hamstrings', 'Glutes', 'Traps'], ['Barbell'],
     'Hinge', 'Compound', 'Advanced', 4, 5,
     'Hinge at the hips, keep the bar close to the shins, and stand up tall while keeping a neutral spine.'),
    ('Pull-up', 'Back', ['Back'], ['Biceps', 'Forearms'], ['Pull-up Bar'],
     'Vertical Pull', 'Bodyweight', 'Advanced', 4, 8,
     'Hang from the bar and pull your chin above it, then lower with control.'),
    ('Lat Pulldown', 'Back', ['Back'], ['Biceps'], ['Cable Machine'],
     'Vertical Pull', 'Compound', 'Beginner', 4, 10,
     'Pull the bar down to upper chest while keeping the torso upright, then control the return.'),
    ('Bent Over Barbell Row', 'Back', ['Back'], ['Biceps', 'Traps'], ['Barbell'],
     'Horizontal Pull', 'Compound', 'Intermediate', 4, 8,
     'Hinge forward, row the bar to your lower ribs, and squeeze the shoulder blades together.'),
    ('Seated Cable Row', 'Back', ['Back'], ['Biceps'], ['Cable Machine'],
     'Horizontal Pull', 'Compound', 'Beginner', 3, 12,
     'Pull the handle to your torso while keeping your back straight, then extend arms fully.'),

    # Shoulders
    ('Barbell Overhead Press', 'Shoulders', ['Shoulders'], ['Triceps'], ['Barbell'],
     'Vertical Push', 'Compound', 'Intermediate', 4, 8,
     'Press the bar overhead from shoulder height until arms are locked out, then lower with control.'),
    ('Dumbbell Lateral Raise', 'Shoulders', ['Shoulders'], [], ['Dumbbell'],
     'Isolation', 'Isolation', 'Beginner', 3, 15,
     'Raise dumbbells out to the sides to shoulder height, keeping a slight elbow bend.'),
    ('Dumbbell Rear Delt Fly', 'Shoulders', ['Shoulders'], ['Back'], ['Dumbbell'],
     'Isolation', 'Isolation', 'Beginner', 3, 15,
     'Hinge forward and raise dumbbells out to the sides, squeezing the rear delts.'),
    ('Arnold Press', 'Shoulders', ['Shoulders'], ['Triceps'], ['Dumbbell'],
     'Vertical Push', 'Compound', 'Intermediate', 3, 10,
     'Press dumbbells overhead while rotating the palms outward through the motion.'),

    # Biceps
    ('Barbell Curl', 'Biceps', ['Biceps'], ['Forearms'], ['Barbell'],
     'Isolation', 'Isolation', 'Beginner', 3, 12,
     'Curl the bar up while keeping elbows pinned to your sides, then lower slowly.'),
    ('Dumbbell Hammer Curl', 'Biceps', ['Biceps'], ['Forearms'], ['Dumbbell'],
     'Isolation', 'Isolation', 'Beginner', 3, 12,
     'Curl dumbbells with a neutral grip, keeping elbows stationary.'),
    ('Incline Dumbbell Curl', 'Biceps', ['Biceps'], [], ['Dumbbell', 'Bench'],
     'Isolation', 'Isolation', 'Intermediate', 3, 12,
     'Seated on an incline bench with arms hanging, curl the dumbbells up with control.'),

    # Triceps
    ('Triceps Pushdown', 'Triceps', ['Triceps'], [], ['Cable Machine'],
     'Isolation', 'Isolation', 'Beginner', 3, 12,
     'Push the cable attachment down until arms are extended, keeping elbows tucked.'),
    ('Lying Triceps Extension', 'Triceps', ['Triceps'], [], ['Barbell', 'Bench'],
     'Isolation', 'Isolation', 'Intermediate', 3, 10,
     'Lower the bar toward the forehead by bending only the elbows, then extend back up.'),
    ('Bench Dip', 'Triceps', ['Triceps'], ['Shoulders'], ['Bench'],
     'Isolation', 'Bodyweight', 'Beginner', 3, 15,
     'Lower your body by bending the elbows, then press back up using the triceps.'),

    # Forearms
    ('Barbell Wrist Curl', 'Forearms', ['Forearms'], [], ['Barbell'],
     'Isolation', 'Isolation', 'Beginner', 3, 15,
     'Rest forearms on your thighs and curl the bar up using only the wrists.'),
    ('Farmer\'s Carry', 'Forearms', ['Forearms'], ['Traps', 'Abdominals'], ['Dumbbell'],
     'Other', 'Compound', 'Beginner', 3, 30,
     'Carry heavy dumbbells at your sides for a set distance or time while keeping posture tall.'),

    # Quadriceps
    ('Barbell Back Squat', 'Quadriceps', ['Quadriceps'], ['Glutes', 'Hamstrings'], ['Barbell', 'Squat Rack'],
     'Squat', 'Compound', 'Intermediate', 4, 8,
     'Squat down until thighs are parallel to the floor, then drive up through the heels.'),
    ('Leg Press', 'Quadriceps', ['Quadriceps'], ['Glutes'], ['Machine'],
     'Squat', 'Compound', 'Beginner', 4, 12,
     'Press the platform away by extending the knees and hips, then return under control.'),
    ('Walking Lunge', 'Quadriceps', ['Quadriceps'], ['Glutes', 'Hamstrings'], ['Dumbbell'],
     'Lunge', 'Compound', 'Intermediate', 3, 12,
     'Step forward into a lunge, lower the back knee toward the floor, then push off to the next step.'),
    ('Leg Extension', 'Quadriceps', ['Quadriceps'], [], ['Machine'],
     'Isolation', 'Isolation', 'Beginner', 3, 15,
     'Extend the knees against resistance until legs are straight, then lower slowly.'),

    # Hamstrings
    ('Romanian Deadlift', 'Hamstrings', ['Hamstrings'], ['Glutes', 'Lower Back'], ['Barbell'],
     'Hinge', 'Compound', 'Intermediate', 4, 10,
     'Hinge at the hips with a slight knee bend, lowering the bar along the legs, then return to standing.'),
    ('Lying Leg Curl', 'Hamstrings', ['Hamstrings'], [], ['Machine'],
     'Isolation', 'Isolation', 'Beginner', 3, 12,
     'Curl the pad toward your glutes by bending the knees, then lower with control.'),
    ('Glute-Ham Raise', 'Hamstrings', ['Hamstrings'], ['Glutes'], ['GHD Machine'],
     'Isolation', 'Bodyweight', 'Advanced', 3, 10,
     'Lower the torso forward under control and curl back up using the hamstrings.'),

    # Glutes
    ('Barbell Hip Thrust', 'Glutes', ['Glutes'], ['Hamstrings'], ['Barbell', 'Bench'],
     'Hinge', 'Compound', 'Intermediate', 4, 10,
     'With shoulders on a bench, drive the hips up until the body forms a straight line, then lower.'),
    ('Glute Bridge', 'Glutes', ['Glutes'], ['Hamstrings'], ['Bodyweight'],
     'Hinge', 'Bodyweight', 'Beginner', 3, 15,
     'Lie on your back and drive the hips upward by squeezing the glutes, then lower slowly.'),
    ('Cable Kickback', 'Glutes', ['Glutes'], ['Hamstrings'], ['Cable Machine'],
     'Isolation', 'Isolation', 'Beginner', 3, 15,
     'Kick one leg back against cable resistance while keeping the torso stable.'),

    # Calves
    ('Standing Calf Raise', 'Calves', ['Calves'], [], ['Machine'],
     'Isolation', 'Isolation', 'Beginner', 4, 15,
     'Rise onto the toes as high as possible, then lower the heels below the platform.'),
    ('Seated Calf Raise', 'Calves', ['Calves'], [], ['Machine'],
     'Isolation', 'Isolation', 'Beginner', 4, 15,
     'With knees bent, raise the heels by extending the ankles, then lower slowly.'),

    # Abdominals
    ('Front Plank', 'Abdominals', ['Abdominals'], ['Lower Back'], ['Bodyweight'],
     'Core Stabilization', 'Bodyweight', 'Beginner', 3, 45,
     'Hold a straight body line supported on forearms and toes, bracing the core.'),
    ('Hanging Leg Raise', 'Abdominals', ['Abdominals'], ['Hip Flexors'], ['Pull-up Bar'],
     'Core Stabilization', 'Bodyweight', 'Advanced', 3, 12,
     'Hang from the bar and raise the legs to hip height or higher, then lower with control.'),
    ('Cable Crunch', 'Abdominals', ['Abdominals'], [], ['Cable Machine'],
     'Isolation', 'Isolation', 'Intermediate', 3, 15,
     'Kneel below the cable and crunch down by flexing the spine, then return slowly.'),

    # Obliques
    ('Russian Twist', 'Obliques', ['Obliques'], ['Abdominals'], ['Bodyweight'],
     'Rotation', 'Bodyweight', 'Beginner', 3, 20,
     'Seated with feet lifted, rotate the torso side to side while keeping the core braced.'),
    ('Side Plank', 'Obliques', ['Obliques'], ['Abdominals'], ['Bodyweight'],
     'Core Stabilization', 'Bodyweight', 'Beginner', 3, 30,
     'Support the body on one forearm and the side of a foot, keeping the hips lifted.'),
    ('Cable Woodchopper', 'Obliques', ['Obliques'], ['Abdominals'], ['Cable Machine'],
     'Rotation', 'Isolation', 'Intermediate', 3, 12,
     'Rotate the torso to pull the cable diagonally across the body, then return under control.'),

    # Lower Back
    ('Back Extension', 'Lower Back', ['Lower Back'], ['Glutes', 'Hamstrings'], ['Hyperextension Bench'],
     'Hinge', 'Bodyweight', 'Beginner', 3, 15,
     'Lower the torso forward at the hips, then raise back to a straight line using the lower back and glutes.'),
    ('Good Morning', 'Lower Back', ['Lower Back'], ['Hamstrings', 'Glutes'], ['Barbell'],
     'Hinge', 'Compound', 'Advanced', 3, 10,
     'With the bar on your back, hinge forward at the hips while keeping a flat back, then return to standing.'),

    # Hip Flexors
    ('Hanging Knee Raise', 'Hip Flexors', ['Hip Flexors'], ['Abdominals'], ['Pull-up Bar'],
     'Core Stabilization', 'Bodyweight', 'Intermediate', 3, 15,
     'Hang from the bar and raise the knees toward the chest, then lower under control.'),
    ('Cable Hip Flexion', 'Hip Flexors', ['Hip Flexors'], [], ['Cable Machine'],
     'Isolation', 'Isolation', 'Beginner', 3, 15,
     'With an ankle cuff attached, raise the leg forward against resistance, then return slowly.'),

    # Adductors
    ('Cable Hip Adduction', 'Adductors', ['Adductors'], [], ['Cable Machine'],
     'Isolation', 'Isolation', 'Beginner', 3, 15,
     'Pull the leg inward across the body against cable resistance, then return with control.'),
    ('Sumo Squat', 'Adductors', ['Adductors'], ['Quadriceps', 'Glutes'], ['Dumbbell'],
     'Squat', 'Compound', 'Beginner', 3, 12,
     'With a wide stance and toes turned out, squat down while keeping the torso upright.'),

    # Abductors
    ('Cable Hip Abduction', 'Abductors', ['Abductors'], ['Glutes'], ['Cable Machine'],
     'Isolation', 'Isolation', 'Beginner', 3, 15,
     'Move the leg outward away from the body against cable resistance, then return slowly.'),
    ('Lateral Band Walk', 'Abductors', ['Abductors'], ['Glutes'], ['Resistance Band'],
     'Other', 'Bodyweight', 'Beginner', 3, 20,
     'With a band above the knees, take controlled steps sideways while keeping tension on the band.'),

    # Traps
    ('Barbell Shrug', 'Traps', ['Traps'], ['Forearms'], ['Barbell'],
     'Isolation', 'Isolation', 'Beginner', 4, 12,
     'Elevate the shoulders straight up toward the ears, then lower under control.'),
    ('Dumbbell Farmer Shrug', 'Traps', ['Traps'], ['Forearms'], ['Dumbbell'],
     'Isolation', 'Isolation', 'Beginner', 3, 15,
     'Holding heavy dumbbells at your sides, shrug the shoulders upward and squeeze.'),

    # Neck
    ('Neck Flexion', 'Neck', ['Neck'], [], ['Plate'],
     'Isolation', 'Isolation', 'Beginner', 3, 15,
     'Lying face up with a plate on the forehead, curl the chin toward the chest.'),
    ('Neck Extension', 'Neck', ['Neck'], [], ['Plate'],
     'Isolation', 'Isolation', 'Beginner', 3, 15,
     'Lying face down with a plate held to the back of the head, extend the neck upward.'),

    # Full Body
    ('Burpee', 'Full Body', ['Full Body'], ['Chest', 'Quadriceps', 'Abdominals'], ['Bodyweight'],
     'Other', 'Bodyweight', 'Intermediate', 3, 15,
     'Drop into a squat, kick back into a plank, perform a push-up, jump feet in, then jump up.'),
    ('Kettlebell Swing', 'Full Body', ['Full Body'], ['Glutes', 'Hamstrings', 'Back'], ['Kettlebell'],
     'Hinge', 'Compound', 'Intermediate', 4, 15,
     'Hinge at the hips and swing the kettlebell to chest height using hip drive, not the arms.'),
    ('Clean and Press', 'Full Body', ['Full Body'], ['Shoulders', 'Quadriceps', 'Back'], ['Barbell'],
     'Other', 'Compound', 'Advanced', 4, 5,
     'Explosively pull the bar to the shoulders, then press it overhead in one fluid motion.'),

    # Cardio
    ('Treadmill Running', 'Cardio', ['Full Body'], [], ['Treadmill'],
     'Other', 'Cardio', 'Beginner', 1, 20,
     'Maintain a steady running pace for the target duration, adjusting incline and speed as needed.'),
    ('Stationary Cycling', 'Cardio', ['Quadriceps', 'Hamstrings'], [], ['Stationary Bike'],
     'Other', 'Cardio', 'Beginner', 1, 20,
     'Pedal at a steady, moderate-to-high intensity for the target duration.'),
    ('Rowing Machine', 'Cardio', ['Back', 'Hamstrings'], ['Biceps'], ['Rowing Machine'],
     'Other', 'Cardio', 'Intermediate', 1, 15,
     'Drive with the legs, lean back slightly, then pull the handle to the torso in one smooth motion.'),
    ('Jump Rope', 'Cardio', ['Calves'], ['Full Body'], ['Jump Rope'],
     'Other', 'Cardio', 'Beginner', 3, 60,
     'Jump rope at a steady rhythm, keeping jumps low and using the wrists to turn the rope.'),
]


# Per-movement-pattern coaching cues, used because the seed data doesn't
# hand-author bespoke breathing/mistake copy for every one of the ~59 rows.
_PATTERN_COACHING = {
    'Horizontal Push': (
        'Exhale forcefully as you press away; inhale on the way back.',
        ['Flaring the elbows out to 90 degrees', 'Letting the shoulders round forward at the bottom'],
    ),
    'Vertical Push': (
        'Exhale as you press overhead; inhale as you lower.',
        ['Arching the lower back to gain range of motion', 'Flaring the elbows instead of pressing straight up'],
    ),
    'Horizontal Pull': (
        'Exhale as you pull, inhale as you extend back out.',
        ['Using momentum instead of the target muscles', 'Shrugging the shoulders up toward the ears'],
    ),
    'Vertical Pull': (
        'Exhale as you pull, inhale as you return to the start.',
        ['Using momentum to swing the weight up', 'Not controlling the lowering (eccentric) phase'],
    ),
    'Hinge': (
        'Inhale as you hinge down, exhale as you drive the hips through.',
        ['Rounding the lower back instead of hinging at the hips', 'Letting the bar or weight drift away from the body'],
    ),
    'Squat': (
        'Inhale as you descend, exhale as you drive up.',
        ['Letting the knees cave inward', 'Losing a neutral spine at the bottom of the movement'],
    ),
    'Lunge': (
        'Inhale as you step and lower, exhale as you push back up.',
        ['Letting the front knee travel far past the toes', 'Losing balance from a narrow foot placement'],
    ),
    'Isolation': (
        'Exhale on the contraction, inhale on the release.',
        ['Using momentum instead of a slow, controlled tempo', 'Recruiting larger muscle groups to cheat the weight up'],
    ),
    'Core Stabilization': (
        'Breathe steadily throughout; never hold your breath.',
        ['Letting the hips sag or pike out of a straight line', 'Rushing the hold instead of keeping steady tension'],
    ),
    'Rotation': (
        'Exhale as you rotate, inhale as you return to center.',
        ['Rotating from the lower back instead of the torso', 'Using momentum instead of controlled rotation'],
    ),
    'Other': (
        'Keep your breathing steady and matched to the effort of the movement.',
        ['Sacrificing form for speed or extra load', 'Losing core tension partway through the set'],
    ),
}

# Well-known alternate names; most exercises simply have no common alias.
_ALIASES = {
    'Push-up': ['Press-up'],
    'Barbell Back Squat': ['Back Squat'],
    "Farmer's Carry": ["Farmer's Walk"],
    'Front Plank': ['Plank'],
}

# Hold/duration-based movements (their "reps" value in EXERCISES is really seconds).
_TIMED_EXERCISES = {
    'Front Plank', 'Side Plank', "Farmer's Carry",
    'Treadmill Running', 'Stationary Cycling', 'Rowing Machine', 'Jump Rope',
}

_DIFFICULTY_RANK = {'Beginner': 0, 'Intermediate': 1, 'Advanced': 2}


class Command(BaseCommand):
    help = 'Seed the exercise library with a starter set of exercises (idempotent).'

    def handle(self, *args, **options):
        User = get_user_model()
        admin_user = User.objects.filter(is_superuser=True).order_by('id').first()
        if not admin_user:
            self.stdout.write(self.style.WARNING(
                'No superuser found; create one or run again after creating a superuser.'
            ))

        created = 0
        updated = 0
        by_name = {}
        for (name, body_part, primary_muscles, secondary_muscles, equipment,
             movement_pattern, exercise_type, difficulty, sets, reps, instructions) in EXERCISES:
            slug = _slug(name)
            breathing, common_mistakes = _PATTERN_COACHING.get(
                movement_pattern, _PATTERN_COACHING['Other'],
            )
            equipment_text = ' and '.join(equipment) if equipment else 'just your bodyweight'
            defaults = {
                'body_part': body_part,
                'primary_muscles': primary_muscles,
                'secondary_muscles': secondary_muscles,
                'equipment': equipment,
                'movement_pattern': movement_pattern,
                'exercise_type': exercise_type,
                'difficulty': difficulty,
                'target_sets': sets,
                'target_reps': reps,
                'instructions': instructions,
                'description': instructions,
                'setup': f'Set up with {equipment_text}; brace your core and find a neutral spine before you start.',
                'execution': instructions,
                'breathing': breathing,
                'common_mistakes': common_mistakes,
                'aliases': _ALIASES.get(name, []),
                'is_timed': name in _TIMED_EXERCISES,
                'video_url': f'{MEDIA_BASE}/{slug}.mp4',
                'animation_url': f'{MEDIA_BASE}/{slug}.jpg',
                'user': admin_user,
            }
            obj, was_created = Exercise.objects.update_or_create(
                name=name, is_library=True, defaults=defaults,
            )
            by_name[name] = obj
            if was_created:
                created += 1
            else:
                updated += 1

        # Second pass: derive alternatives/progressions/regressions from
        # same-body-part groups, ordered by difficulty.
        groups = {}
        for (name, body_part, *_rest) in EXERCISES:
            groups.setdefault(body_part, []).append(name)
        for names in groups.values():
            ordered = sorted(names, key=lambda n: _DIFFICULTY_RANK[by_name[n].difficulty])
            for index, name in enumerate(ordered):
                obj = by_name[name]
                regression = by_name[ordered[index - 1]] if index > 0 else None
                progression = by_name[ordered[index + 1]] if index < len(ordered) - 1 else None
                excluded = {name}
                if regression:
                    excluded.add(regression.name)
                if progression:
                    excluded.add(progression.name)
                alternatives = [
                    by_name[other] for other in ordered if other not in excluded
                ][:2]
                obj.regression_exercises.set([regression] if regression else [])
                obj.progression_exercises.set([progression] if progression else [])
                obj.alternatives.set(alternatives)

        self.stdout.write(self.style.SUCCESS(
            f'Exercise library seeded (created={created}, updated={updated}, total={len(EXERCISES)}).'
        ))
