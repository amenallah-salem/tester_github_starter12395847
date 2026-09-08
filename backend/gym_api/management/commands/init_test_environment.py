"""
JSON-driven development/test environment initializer.

This command contains NO test data itself. Every user, exercise, plan,
plan/user assignment and workout history record it creates comes from a
single JSON file (by default `asserts/inputs_dev_env/json_file.json` at the
repo root). See `asserts/inputs_dev_env/README.md` for the full JSON schema
and how to extend it.

Flow:
    asserts/inputs_dev_env/json_file.json
                    -> scripts/init_test_environment.sh
                    -> this command
                    -> database

The command is idempotent: JSON objects carry stable string ids (e.g.
"alex_strength", "push_pull_legs") that are resolved to real database rows
by natural keys (username, exercise name, "user + plan name", etc.) rather
than by database-generated primary keys, so re-running it updates/reuses
existing rows instead of duplicating them.

Validation runs fully before any database write. If the JSON is invalid,
every problem is reported and the command exits without touching the
database (see `--check-only` to validate without importing).
"""
import json
from decimal import Decimal
from pathlib import Path

from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.files import File
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils.dateparse import parse_date, parse_datetime

from gym_api.models import (
    BodyWeightEntry, Exercise, FavoriteExercise, Plan, PlanDay,
    PlanDayExercise, Profile, ProgressMetric, WorkoutSession,
)

DEFAULT_JSON_CANDIDATES = [
    Path('/asserts/inputs_dev_env/json_file.json'),  # docker dev container mount
    Path(settings.BASE_DIR).parent / 'asserts' / 'inputs_dev_env' / 'json_file.json',  # host/local run
]
DEFAULT_AVATAR_DIR_CANDIDATES = [
    Path('/asserts/avatars'),
    Path(settings.BASE_DIR).parent / 'asserts' / 'avatars',
]

REQUIRED_TOP_LEVEL_LIST_KEYS = ['users', 'exercises', 'plans', 'user_plans', 'workout_history']


class ValidationErrors(list):
    """A list of human-readable error strings, each prefixed with its JSON path."""

    def add(self, path, message):
        self.append(f'{path}: {message}')


def _first_existing(candidates):
    for candidate in candidates:
        if candidate.exists():
            return candidate
    return None


def _is_dict(value):
    return isinstance(value, dict)


def _is_list(value):
    return isinstance(value, list)


def _is_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _is_nonneg_int(value):
    return isinstance(value, int) and not isinstance(value, bool) and value >= 0


class Command(BaseCommand):
    help = (
        'Initialize the development/test environment from a single JSON file '
        '(default: asserts/inputs_dev_env/json_file.json). Idempotent — safe to '
        're-run. Validates the file completely before writing anything.'
    )

    def add_arguments(self, parser):
        parser.add_argument(
            '--file', dest='file_path', default=None,
            help='Path to the input JSON file (default: auto-detected asserts/inputs_dev_env/json_file.json).',
        )
        parser.add_argument(
            '--check-only', action='store_true', dest='check_only',
            help='Validate the JSON file and report problems without writing to the database.',
        )

    # ------------------------------------------------------------------
    # Entry point
    # ------------------------------------------------------------------
    def handle(self, *args, **options):
        json_path = self._resolve_json_path(options['file_path'])
        avatar_dir = _first_existing(DEFAULT_AVATAR_DIR_CANDIDATES)

        data = self._load_json(json_path)

        errors = self._validate(data, avatar_dir)
        if errors:
            self.stderr.write(self.style.ERROR(
                f'Found {len(errors)} problem(s) in {json_path}. No changes were made.'
            ))
            for error in errors:
                self.stderr.write(self.style.ERROR(f'  - {error}'))
            raise CommandError('Aborting: input JSON failed validation.')

        self.stdout.write(self.style.SUCCESS(f'Validated {json_path} — no problems found.'))

        if options['check_only']:
            self.stdout.write('Check-only mode: skipping import.')
            return

        with transaction.atomic():
            summary = self._apply(data, avatar_dir)

        self.stdout.write(self.style.SUCCESS(
            'Test environment initialized: '
            f"users={summary['users']}, exercises={summary['exercises']}, "
            f"plans_assigned={summary['plans_assigned']}, "
            f"sessions={summary['sessions']}, sets={summary['sets']}."
        ))

    # ------------------------------------------------------------------
    # Loading
    # ------------------------------------------------------------------
    def _resolve_json_path(self, explicit_path):
        if explicit_path:
            path = Path(explicit_path)
            if not path.exists():
                raise CommandError(f'--file {path} does not exist.')
            return path
        found = _first_existing(DEFAULT_JSON_CANDIDATES)
        if not found:
            searched = '\n  - '.join(str(c) for c in DEFAULT_JSON_CANDIDATES)
            raise CommandError(
                'Could not find the input JSON file. Looked in:\n  - ' + searched +
                '\nPass --file to specify a path explicitly.'
            )
        return found

    def _load_json(self, path):
        try:
            raw = path.read_text(encoding='utf-8')
        except OSError as exc:
            raise CommandError(f'Could not read {path}: {exc}') from exc
        try:
            return json.loads(raw)
        except json.JSONDecodeError as exc:
            raise CommandError(f'{path} is not valid JSON: {exc}') from exc

    # ------------------------------------------------------------------
    # Validation (pure — no database access other than choice constants)
    # ------------------------------------------------------------------
    def _validate(self, data, avatar_dir):
        errors = ValidationErrors()

        if not _is_dict(data):
            errors.add('$', 'root of the JSON file must be an object')
            return errors

        for key in REQUIRED_TOP_LEVEL_LIST_KEYS:
            if key in data and not _is_list(data[key]):
                errors.add(f'${key}', 'must be a list')

        users = data.get('users') or []
        exercises = data.get('exercises') or []
        plans = data.get('plans') or []
        user_plans = data.get('user_plans') or []
        workout_history = data.get('workout_history') or []

        user_ids, usernames = self._validate_users(users, avatar_dir, errors)
        exercise_ids = self._validate_exercises(exercises, errors)
        self._validate_favorite_exercise_refs(users, exercise_ids, errors)
        plan_ids = self._validate_plans(plans, exercise_ids, errors)
        assigned_pairs = self._validate_user_plans(user_plans, user_ids, plan_ids, errors)
        self._validate_workout_history(workout_history, user_ids, plan_ids, exercise_ids, assigned_pairs, errors)

        return errors

    def _validate_users(self, users, avatar_dir, errors):
        user_ids = set()
        usernames = set()
        goal_choices = {choice for choice, _ in Profile.GOAL_CHOICES}
        experience_choices = {choice for choice, _ in Profile.EXPERIENCE_CHOICES}

        for index, user in enumerate(users):
            path = f'users[{index}]'
            if not _is_dict(user):
                errors.add(path, 'must be an object')
                continue

            uid = user.get('id')
            username = user.get('username')
            if not uid or not isinstance(uid, str):
                errors.add(f'{path}.id', "missing or invalid required field 'id' (non-empty string)")
            elif uid in user_ids:
                errors.add(f'{path}.id', f'duplicate user id "{uid}"')
            else:
                user_ids.add(uid)

            if not username or not isinstance(username, str):
                errors.add(f'{path}.username', "missing or invalid required field 'username' (non-empty string)")
            elif username in usernames:
                errors.add(f'{path}.username', f'duplicate username "{username}"')
            else:
                usernames.add(username)

            for bool_field in ('is_staff', 'is_superuser'):
                if bool_field in user and not isinstance(user[bool_field], bool):
                    errors.add(f'{path}.{bool_field}', 'must be a boolean')

            profile = user.get('profile')
            if profile is not None:
                if not _is_dict(profile):
                    errors.add(f'{path}.profile', 'must be an object')
                else:
                    pprefix = f'{path}.profile'
                    if 'experience_level' in profile and profile['experience_level'] not in ('', None) \
                            and profile['experience_level'] not in experience_choices:
                        errors.add(f'{pprefix}.experience_level', f'invalid value {profile["experience_level"]!r}')
                    goals = profile.get('training_goals')
                    if goals is not None:
                        if not _is_list(goals):
                            errors.add(f'{pprefix}.training_goals', 'must be a list')
                        else:
                            invalid = [g for g in goals if g not in goal_choices]
                            if invalid:
                                errors.add(f'{pprefix}.training_goals', f'invalid goal(s) {invalid}')
                    if 'onboarding_completed' in profile and not isinstance(profile['onboarding_completed'], bool):
                        errors.add(f'{pprefix}.onboarding_completed', 'must be a boolean')
                    avatar = profile.get('avatar')
                    if avatar is not None:
                        if not isinstance(avatar, str) or not avatar:
                            errors.add(f'{pprefix}.avatar', 'must be a non-empty filename string')
                        elif avatar_dir is None:
                            errors.add(f'{pprefix}.avatar', 'avatar directory (asserts/avatars) could not be located')
                        elif not (avatar_dir / avatar).exists():
                            errors.add(f'{pprefix}.avatar', f'file "{avatar}" not found in {avatar_dir}')

            body_weight_log = user.get('body_weight_log')
            if body_weight_log is not None:
                if not _is_list(body_weight_log):
                    errors.add(f'{path}.body_weight_log', 'must be a list')
                else:
                    for bwi, entry in enumerate(body_weight_log):
                        bpath = f'{path}.body_weight_log[{bwi}]'
                        if not _is_dict(entry):
                            errors.add(bpath, 'must be an object')
                            continue
                        if not _is_number(entry.get('weight_kg')) or entry.get('weight_kg') < 0:
                            errors.add(f'{bpath}.weight_kg', 'must be a non-negative number')
                        logged_at = entry.get('logged_at')
                        if not logged_at or parse_datetime(str(logged_at)) is None:
                            errors.add(f'{bpath}.logged_at', f'invalid ISO datetime {logged_at!r}')

            favorites = user.get('favorite_exercises')
            if favorites is not None and not _is_list(favorites):
                errors.add(f'{path}.favorite_exercises', 'must be a list')

        return user_ids, usernames

    def _validate_favorite_exercise_refs(self, users, exercise_ids, errors):
        for index, user in enumerate(users):
            if not _is_dict(user):
                continue
            favorites = user.get('favorite_exercises')
            if not _is_list(favorites):
                continue
            for findex, exercise_jid in enumerate(favorites):
                if exercise_jid not in exercise_ids:
                    errors.add(
                        f'users[{index}].favorite_exercises[{findex}]',
                        f'references unknown exercise id {exercise_jid!r}',
                    )

    def _validate_exercises(self, exercises, errors):
        exercise_ids = set()
        body_parts = {choice for choice, _ in Exercise.BODY_PART_CHOICES}
        patterns = {choice for choice, _ in Exercise.MOVEMENT_PATTERN_CHOICES}
        types = {choice for choice, _ in Exercise.EXERCISE_TYPE_CHOICES}
        difficulties = {choice for choice, _ in Exercise.DIFFICULTY_CHOICES}

        for index, exercise in enumerate(exercises):
            path = f'exercises[{index}]'
            if not _is_dict(exercise):
                errors.add(path, 'must be an object')
                continue

            eid = exercise.get('id')
            name = exercise.get('name')
            if not eid or not isinstance(eid, str):
                errors.add(f'{path}.id', "missing or invalid required field 'id' (non-empty string)")
            elif eid in exercise_ids:
                errors.add(f'{path}.id', f'duplicate exercise id "{eid}"')
            else:
                exercise_ids.add(eid)

            if not name or not isinstance(name, str):
                errors.add(f'{path}.name', "missing or invalid required field 'name' (non-empty string)")

            for field, choices in (
                ('body_part', body_parts), ('movement_pattern', patterns),
                ('exercise_type', types), ('difficulty', difficulties),
            ):
                value = exercise.get(field)
                if value not in (None, '') and value not in choices:
                    errors.add(f'{path}.{field}', f'invalid value {value!r}')

            for int_field in ('target_sets', 'target_reps'):
                value = exercise.get(int_field)
                if value is not None and not (isinstance(value, int) and not isinstance(value, bool) and value >= 1):
                    errors.add(f'{path}.{int_field}', 'must be an integer >= 1')

            weight = exercise.get('target_weight_kg')
            if weight is not None and not (_is_number(weight) and weight >= 0):
                errors.add(f'{path}.target_weight_kg', 'must be a non-negative number or null')

            for bool_field in ('is_timed', 'is_library'):
                if bool_field in exercise and not isinstance(exercise[bool_field], bool):
                    errors.add(f'{path}.{bool_field}', 'must be a boolean')

        return exercise_ids

    def _validate_plans(self, plans, exercise_ids, errors):
        plan_ids = set()

        for index, plan in enumerate(plans):
            path = f'plans[{index}]'
            if not _is_dict(plan):
                errors.add(path, 'must be an object')
                continue

            pid = plan.get('id')
            name = plan.get('name')
            if not pid or not isinstance(pid, str):
                errors.add(f'{path}.id', "missing or invalid required field 'id' (non-empty string)")
            elif pid in plan_ids:
                errors.add(f'{path}.id', f'duplicate plan id "{pid}"')
            else:
                plan_ids.add(pid)

            if not name or not isinstance(name, str):
                errors.add(f'{path}.name', "missing or invalid required field 'name' (non-empty string)")

            days = plan.get('days', [])
            if not _is_list(days):
                errors.add(f'{path}.days', 'must be a list')
                continue

            seen_weekdays = set()
            for dindex, day in enumerate(days):
                dpath = f'{path}.days[{dindex}]'
                if not _is_dict(day):
                    errors.add(dpath, 'must be an object')
                    continue
                weekday = day.get('weekday')
                if not (isinstance(weekday, int) and not isinstance(weekday, bool) and 0 <= weekday <= 6):
                    errors.add(f'{dpath}.weekday', 'must be an integer 0-6 (0=Monday ... 6=Sunday)')
                elif weekday in seen_weekdays:
                    errors.add(f'{dpath}.weekday', f'duplicate weekday {weekday} within plan "{pid}"')
                else:
                    seen_weekdays.add(weekday)

                day_exercises = day.get('exercises', [])
                if not _is_list(day_exercises):
                    errors.add(f'{dpath}.exercises', 'must be a list')
                    continue
                seen_in_day = set()
                for eindex, ex_id in enumerate(day_exercises):
                    epath = f'{dpath}.exercises[{eindex}]'
                    if ex_id in seen_in_day:
                        errors.add(epath, f'duplicate exercise reference "{ex_id}" within the same day')
                    seen_in_day.add(ex_id)
                    if ex_id not in exercise_ids:
                        errors.add(epath, f'references unknown exercise id "{ex_id}"')

        return plan_ids

    def _validate_user_plans(self, user_plans, user_ids, plan_ids, errors):
        seen_pairs = set()
        for index, entry in enumerate(user_plans):
            path = f'user_plans[{index}]'
            if not _is_dict(entry):
                errors.add(path, 'must be an object')
                continue
            uid = entry.get('user_id')
            pid = entry.get('plan_id')
            if not uid or uid not in user_ids:
                errors.add(f'{path}.user_id', f'references unknown user id {uid!r}')
            if not pid or pid not in plan_ids:
                errors.add(f'{path}.plan_id', f'references unknown plan id {pid!r}')
            pair = (uid, pid)
            if pair in seen_pairs:
                errors.add(path, f'duplicate user_plans entry for (user_id={uid!r}, plan_id={pid!r})')
            seen_pairs.add(pair)
        return seen_pairs

    def _validate_workout_history(self, workout_history, user_ids, plan_ids, exercise_ids, assigned_pairs, errors):
        seen_sessions = set()
        for index, entry in enumerate(workout_history):
            path = f'workout_history[{index}]'
            if not _is_dict(entry):
                errors.add(path, 'must be an object')
                continue

            uid = entry.get('user_id')
            name = entry.get('name')
            if not uid or uid not in user_ids:
                errors.add(f'{path}.user_id', f'references unknown user id {uid!r}')
            if not name or not isinstance(name, str):
                errors.add(f'{path}.name', "missing or invalid required field 'name' (non-empty string)")

            pid = entry.get('plan_id')
            if pid is not None:
                if pid not in plan_ids:
                    errors.add(f'{path}.plan_id', f'references unknown plan id {pid!r}')
                elif (uid, pid) not in assigned_pairs:
                    errors.add(
                        f'{path}.plan_id',
                        f'user {uid!r} is not assigned plan {pid!r} in user_plans',
                    )

            scheduled_for = entry.get('scheduled_for')
            if scheduled_for is not None and parse_date(str(scheduled_for)) is None:
                errors.add(f'{path}.scheduled_for', f'invalid ISO date {scheduled_for!r}')

            started_at = entry.get('started_at')
            started_dt = None
            if started_at is not None:
                started_dt = parse_datetime(str(started_at))
                if started_dt is None:
                    errors.add(f'{path}.started_at', f'invalid ISO datetime {started_at!r}')

            finished_at = entry.get('finished_at')
            finished_dt = None
            if finished_at is not None:
                finished_dt = parse_datetime(str(finished_at))
                if finished_dt is None:
                    errors.add(f'{path}.finished_at', f'invalid ISO datetime {finished_at!r}')

            if started_dt and finished_dt and finished_dt < started_dt:
                errors.add(f'{path}.finished_at', 'must not be earlier than started_at')

            session_key = (uid, name, scheduled_for)
            if session_key in seen_sessions:
                errors.add(path, f'duplicate workout_history entry for (user_id={uid!r}, name={name!r}, scheduled_for={scheduled_for!r})')
            seen_sessions.add(session_key)

            exercises = entry.get('exercises', [])
            if not _is_list(exercises):
                errors.add(f'{path}.exercises', 'must be a list')
                continue
            for eindex, exercise_entry in enumerate(exercises):
                epath = f'{path}.exercises[{eindex}]'
                if not _is_dict(exercise_entry):
                    errors.add(epath, 'must be an object')
                    continue
                ex_id = exercise_entry.get('exercise_id')
                if not ex_id or ex_id not in exercise_ids:
                    errors.add(f'{epath}.exercise_id', f'references unknown exercise id {ex_id!r}')

                sets = exercise_entry.get('sets', [])
                if not _is_list(sets):
                    errors.add(f'{epath}.sets', 'must be a list')
                    continue
                seen_set_numbers = set()
                for sindex, set_entry in enumerate(sets):
                    spath = f'{epath}.sets[{sindex}]'
                    if not _is_dict(set_entry):
                        errors.add(spath, 'must be an object')
                        continue
                    set_number = set_entry.get('set_number')
                    if not (isinstance(set_number, int) and not isinstance(set_number, bool) and set_number >= 1):
                        errors.add(f'{spath}.set_number', 'must be an integer >= 1')
                    elif set_number in seen_set_numbers:
                        errors.add(f'{spath}.set_number', f'duplicate set_number {set_number} for this exercise')
                    else:
                        seen_set_numbers.add(set_number)

                    reps = set_entry.get('reps', 0)
                    if not _is_nonneg_int(reps):
                        errors.add(f'{spath}.reps', 'must be a non-negative integer')

                    weight_kg = set_entry.get('weight_kg')
                    if weight_kg is not None and not (_is_number(weight_kg) and weight_kg >= 0):
                        errors.add(f'{spath}.weight_kg', 'must be a non-negative number or null')

                    duration = set_entry.get('duration_seconds')
                    if duration is not None and not _is_nonneg_int(duration):
                        errors.add(f'{spath}.duration_seconds', 'must be a non-negative integer or null')

    # ------------------------------------------------------------------
    # Import (only reached once validation is clean)
    # ------------------------------------------------------------------
    def _apply(self, data, avatar_dir):
        User = get_user_model()

        users_json = data.get('users') or []
        exercises_json = data.get('exercises') or []
        plans_json = {p['id']: p for p in (data.get('plans') or [])}
        user_plans_json = data.get('user_plans') or []
        workout_history_json = data.get('workout_history') or []

        exercises_by_jid = self._apply_exercises(exercises_json)
        users_by_jid = self._apply_users(users_json, exercises_by_jid, avatar_dir, User)
        plans_assigned = self._apply_user_plans(user_plans_json, plans_json, users_by_jid, exercises_by_jid)
        sessions, sets_written = self._apply_workout_history(
            workout_history_json, users_by_jid, plans_json, exercises_by_jid,
        )

        return {
            'users': len(users_by_jid),
            'exercises': len(exercises_by_jid),
            'plans_assigned': plans_assigned,
            'sessions': sessions,
            'sets': sets_written,
        }

    def _apply_exercises(self, exercises_json):
        exercises_by_jid = {}
        for exercise in exercises_json:
            defaults = {
                'body_part': exercise.get('body_part', ''),
                'primary_muscles': exercise.get('primary_muscles', []),
                'secondary_muscles': exercise.get('secondary_muscles', []),
                'equipment': exercise.get('equipment', []),
                'movement_pattern': exercise.get('movement_pattern', ''),
                'exercise_type': exercise.get('exercise_type', ''),
                'difficulty': exercise.get('difficulty', ''),
                'is_timed': exercise.get('is_timed', False),
                'target_sets': exercise.get('target_sets', 3),
                'target_reps': exercise.get('target_reps', 10),
                'target_weight_kg': exercise.get('target_weight_kg'),
                'instructions': exercise.get('instructions', ''),
                'description': exercise.get('description', exercise.get('instructions', '')),
                'setup': exercise.get('setup', ''),
                'execution': exercise.get('execution', ''),
                'breathing': exercise.get('breathing', ''),
                'common_mistakes': exercise.get('common_mistakes', []),
                'aliases': exercise.get('aliases', []),
                'user': None,
            }
            obj, _ = Exercise.objects.update_or_create(
                name=exercise['name'], is_library=exercise.get('is_library', True),
                defaults=defaults,
            )
            exercises_by_jid[exercise['id']] = obj
        return exercises_by_jid

    def _apply_users(self, users_json, exercises_by_jid, avatar_dir, User):
        users_by_jid = {}
        for user_json in users_json:
            user, created = User.objects.get_or_create(
                username=user_json['username'],
                defaults={
                    'email': user_json.get('email', ''),
                    'first_name': user_json.get('first_name', ''),
                    'last_name': user_json.get('last_name', ''),
                    'is_staff': user_json.get('is_staff', False),
                    'is_superuser': user_json.get('is_superuser', False),
                },
            )
            if not created:
                user.email = user_json.get('email', user.email)
                user.first_name = user_json.get('first_name', user.first_name)
                user.last_name = user_json.get('last_name', user.last_name)
                user.is_staff = user_json.get('is_staff', user.is_staff)
                user.is_superuser = user_json.get('is_superuser', user.is_superuser)
            password = user_json.get('password')
            if password:
                user.set_password(password)
            elif created:
                user.set_unusable_password()
            user.save()

            profile, _ = Profile.objects.get_or_create(user=user)
            profile_json = user_json.get('profile') or {}
            profile.display_name = profile_json.get('display_name', profile.display_name)
            profile.bio = profile_json.get('bio', profile.bio)
            if 'training_goals' in profile_json:
                profile.training_goals = profile_json['training_goals']
            profile.experience_level = profile_json.get('experience_level', profile.experience_level)
            profile.availability = profile_json.get('availability', profile.availability)
            profile.location = profile_json.get('location', profile.location)
            if 'onboarding_completed' in profile_json:
                profile.onboarding_completed = profile_json['onboarding_completed']

            avatar_name = profile_json.get('avatar')
            if avatar_name and avatar_dir:
                current_name = Path(profile.avatar.name).name if profile.avatar else None
                if current_name != avatar_name:
                    avatar_path = avatar_dir / avatar_name
                    with avatar_path.open('rb') as fh:
                        profile.avatar.save(avatar_name, File(fh), save=False)

            profile.save()

            for exercise_jid in user_json.get('favorite_exercises') or []:
                exercise = exercises_by_jid.get(exercise_jid)
                if exercise:
                    FavoriteExercise.objects.get_or_create(user=user, exercise=exercise)

            for entry in user_json.get('body_weight_log') or []:
                logged_at = parse_datetime(str(entry['logged_at']))
                weight_kg = Decimal(str(entry['weight_kg']))
                if not BodyWeightEntry.objects.filter(
                    user=user, weight_kg=weight_kg, logged_at=logged_at,
                ).exists():
                    bw_entry = BodyWeightEntry.objects.create(user=user, weight_kg=weight_kg)
                    BodyWeightEntry.objects.filter(pk=bw_entry.pk).update(logged_at=logged_at)

            users_by_jid[user_json['id']] = user
        return users_by_jid

    def _apply_user_plans(self, user_plans_json, plans_json, users_by_jid, exercises_by_jid):
        assigned = 0
        for entry in user_plans_json:
            user = users_by_jid[entry['user_id']]
            template = plans_json[entry['plan_id']]

            plan_obj, created = Plan.objects.get_or_create(
                user=user, name=template['name'],
                defaults={
                    'description': template.get('description', ''),
                    'is_active': template.get('is_active', True),
                },
            )
            if not created:
                plan_obj.description = template.get('description', plan_obj.description)
                plan_obj.is_active = template.get('is_active', plan_obj.is_active)
                plan_obj.save(update_fields=['description', 'is_active'])

            for day in template.get('days', []):
                plan_day, _ = PlanDay.objects.get_or_create(plan=plan_obj, weekday=day['weekday'])
                PlanDayExercise.objects.filter(plan_day=plan_day).delete()
                PlanDayExercise.objects.bulk_create([
                    PlanDayExercise(
                        plan_day=plan_day,
                        exercise=exercises_by_jid[exercise_jid],
                        order=order,
                    )
                    for order, exercise_jid in enumerate(day.get('exercises', []))
                ])
            assigned += 1
        return assigned

    def _apply_workout_history(self, workout_history_json, users_by_jid, plans_json, exercises_by_jid):
        sessions_written = 0
        sets_written = 0

        for entry in workout_history_json:
            user = users_by_jid[entry['user_id']]
            scheduled_for = parse_date(str(entry['scheduled_for'])) if entry.get('scheduled_for') else None
            started_dt = parse_datetime(str(entry['started_at'])) if entry.get('started_at') else None
            finished_dt = parse_datetime(str(entry['finished_at'])) if entry.get('finished_at') else None

            plan_obj = None
            if entry.get('plan_id'):
                template = plans_json[entry['plan_id']]
                plan_obj = Plan.objects.filter(user=user, name=template['name']).first()

            session, created = WorkoutSession.objects.get_or_create(
                user=user, name=entry['name'], scheduled_for=scheduled_for,
                defaults={'plan': plan_obj, 'notes': entry.get('notes', '')},
            )
            if not created:
                session.plan = plan_obj
                session.notes = entry.get('notes', session.notes)
            session.finished_at = finished_dt
            session.save(update_fields=['plan', 'notes', 'finished_at'])
            if started_dt:
                WorkoutSession.objects.filter(pk=session.pk).update(started_at=started_dt)
                session.refresh_from_db(fields=['started_at'])

            ProgressMetric.objects.filter(session=session).delete()
            metrics = []
            for exercise_entry in entry.get('exercises', []):
                exercise = exercises_by_jid[exercise_entry['exercise_id']]
                for set_entry in exercise_entry.get('sets', []):
                    weight_kg = set_entry.get('weight_kg')
                    metrics.append(ProgressMetric(
                        session=session,
                        exercise=exercise,
                        set_number=set_entry['set_number'],
                        reps=set_entry.get('reps', 0),
                        weight_kg=Decimal(str(weight_kg)) if weight_kg is not None else None,
                        duration_seconds=set_entry.get('duration_seconds'),
                    ))
            ProgressMetric.objects.bulk_create(metrics)
            if session.started_at:
                ProgressMetric.objects.filter(session=session).update(logged_at=session.started_at)

            sessions_written += 1
            sets_written += len(metrics)

        return sessions_written, sets_written
