"""
Simple smoke tests for the gym_api app.
Run with: python manage.py test gym_api
"""
from django.contrib.auth.models import User
from django.db import IntegrityError, transaction
from django.test import TestCase, override_settings
from django.utils import timezone
from rest_framework.test import APITestCase
from rest_framework import status
from django.core.files.uploadedfile import SimpleUploadedFile
from unittest import mock
from .models import (
    Profile, Plan, Exercise, WorkoutSession, ProgressMetric, Subscription,
    FavoriteExercise, Swipe, Match, GymBroMessage, MeditationSession, Feedback,
    ProgressPhoto, SocialAccount, OTPVerification,
    AIConversationFolder, AIConversation, AIMessage,
)
from gym_project.env_guards import check_production_safety
from .ai.openrouter import OpenRouterError, OpenRouterTimeout, StreamChunk
from .ai.titles import title_from_message


class ModelTests(TestCase):
    def test_profile_str(self):
        user = User.objects.create_user('testuser', 'test@example.com', 'pass1234')
        profile = Profile.objects.create(user=user, display_name='Test User')
        self.assertEqual(str(profile), 'Test User')

    def test_profile_completed_gym_bro_profile_requires_bio_and_goals(self):
        user = User.objects.create_user('gbuser', 'gb@example.com', 'gbpass123')
        profile = Profile.objects.create(user=user)
        self.assertFalse(profile.has_completed_gym_bro_profile())
        profile.bio = 'I love squats.'
        self.assertFalse(profile.has_completed_gym_bro_profile())
        profile.training_goals = ['strength']
        self.assertTrue(profile.has_completed_gym_bro_profile())

    def test_plan_str(self):
        user = User.objects.create_user('planuser', 'plan@example.com', 'pass1234')
        plan = Plan.objects.create(user=user, name='Push Day')
        self.assertEqual(str(plan), 'Push Day')

    def test_exercise_str(self):
        user = User.objects.create_user('exuser', 'ex@example.com', 'pass1234')
        exercise = Exercise.objects.create(user=user, name='Bench Press')
        self.assertEqual(str(exercise), 'Bench Press')


class APITests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user('apiuser', 'api@example.com', 'apipass123')
        self.other_user = User.objects.create_user('other', 'other@example.com', 'otherpass123')
        self.client.force_authenticate(user=self.user)

    def test_profile_me(self):
        resp = self.client.get('/api/profiles/me/')
        self.assertIn(resp.status_code, (200, 201))

    def test_profile_can_be_patched_with_gym_bro_fields(self):
        resp = self.client.get('/api/profiles/me/')
        profile_id = resp.data['id']

        resp = self.client.patch(f'/api/profiles/{profile_id}/', {
            'bio': 'Looking for a squat partner.',
            'training_goals': ['strength', 'cardio'],
            'experience_level': 'intermediate',
            'availability': 'Weekday evenings',
            'location': 'Austin, TX',
        }, format='json')

        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['bio'], 'Looking for a squat partner.')
        self.assertEqual(resp.data['training_goals'], ['strength', 'cardio'])
        self.assertEqual(resp.data['experience_level'], 'intermediate')
        self.assertEqual(resp.data['location'], 'Austin, TX')

    def test_profile_rejects_invalid_training_goal(self):
        resp = self.client.get('/api/profiles/me/')
        profile_id = resp.data['id']

        resp = self.client.patch(f'/api/profiles/{profile_id}/', {
            'training_goals': ['not_a_real_goal'],
        }, format='json')

        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('training_goals', resp.data)

    def test_favorites_are_user_scoped_and_reject_foreign_exercises(self):
        library = Exercise.objects.create(name='Library Press', is_library=True)
        own = Exercise.objects.create(user=self.user, name='Own Press')
        foreign = Exercise.objects.create(user=self.other_user, name='Other Press')

        response = self.client.post('/api/favorites/', {'exercise': str(library.id)}, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        response = self.client.post('/api/favorites/', {'exercise': str(own.id)}, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        response = self.client.post('/api/favorites/', {'exercise': str(foreign.id)}, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

        response = self.client.get('/api/favorites/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 2)

    def test_plan_crud(self):
        # Create
        resp = self.client.post('/api/plans/', {'name': 'Pull Day', 'description': 'Back & biceps'})
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        plan_id = resp.data['id']
        # Read
        resp = self.client.get(f'/api/plans/{plan_id}/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        # List
        resp = self.client.get('/api/plans/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        # Delete
        resp = self.client.delete(f'/api/plans/{plan_id}/')
        self.assertEqual(resp.status_code, status.HTTP_204_NO_CONTENT)

    def test_plan_week_can_be_read_and_replaced(self):
        plan = Plan.objects.create(user=self.user, name='Weekly Plan')
        exercises = [
            Exercise.objects.create(
                user=self.user,
                name=f'Exercise {index}',
                plan=plan,
            )
            for index in range(2)
        ]
        payload = {
            'days': [
                {
                    'weekday': weekday,
                    'exercise_ids': [str(exercises[weekday % 2].id)]
                    if weekday in (0, 2, 4)
                    else [],
                }
                for weekday in range(7)
            ],
        }

        resp = self.client.put(f'/api/plans/{plan.id}/week/', payload, format='json')

        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp.data['days']), 7)
        self.assertEqual(
            str(resp.data['days'][0]['assignments'][0]['exercise']),
            str(exercises[0].id),
        )
        self.assertEqual(resp.data['days'][1]['assignments'], [])

        resp = self.client.get(f'/api/plans/{plan.id}/week/')

        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['days'][4]['assignments'][0]['order'], 0)

    def test_plan_week_rejects_incomplete_or_foreign_assignments(self):
        plan = Plan.objects.create(user=self.user, name='Weekly Plan')
        other_exercise = Exercise.objects.create(
            user=self.other_user,
            name='Private Exercise',
        )

        resp = self.client.put(
            f'/api/plans/{plan.id}/week/',
            {'days': [{'weekday': 0, 'exercise_ids': [str(other_exercise.id)]}] * 7},
            format='json',
        )

        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('days', resp.data)

    def test_exercise_crud(self):
        resp = self.client.post('/api/exercises/', {'name': 'Deadlift', 'target_sets': 4, 'target_reps': 6})
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)

    def test_library_exercises_support_search_and_body_part_filter(self):
        Exercise.objects.create(
            name='Bench Press',
            body_part='Chest',
            is_library=True,
        )
        Exercise.objects.create(
            name='Barbell Row',
            body_part='Back',
            is_library=True,
        )

        resp = self.client.get('/api/library/exercises/?search=bench&body_part=Chest')

        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual([item['name'] for item in resp.data], ['Bench Press'])

    def test_library_exercises_return_empty_results_for_unknown_filter(self):
        Exercise.objects.create(
            name='Bench Press',
            body_part='Chest',
            is_library=True,
        )

        resp = self.client.get('/api/library/exercises/?body_part=Legs')

        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data, [])

    def test_session_crud(self):
        resp = self.client.post('/api/sessions/', {'name': 'Morning Workout'})
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)

    def test_session_can_be_scheduled_for_another_day(self):
        resp = self.client.post(
            '/api/sessions/',
            {'name': 'Rescheduled Workout', 'scheduled_for': '2026-09-10'},
        )

        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp.data['scheduled_for'], '2026-09-10')

    def test_metric_crud(self):
        # Create session first
        sess_resp = self.client.post('/api/sessions/', {'name': 'Leg Day'})
        session_id = sess_resp.data['id']
        resp = self.client.post('/api/metrics/', {
            'session': session_id,
            'set_number': 1,
            'reps': 10,
            'weight_kg': 60.0,
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)

    def test_session_log_metric_creates_a_set(self):
        session = WorkoutSession.objects.create(user=self.user, name='Leg Day')

        resp = self.client.post(
            f'/api/sessions/{session.id}/log-metric/',
            {
                'exercise_name': 'Squat',
                'set_number': 1,
                'reps': 8,
                'weight_kg': 80,
            },
        )

        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(session.metrics.count(), 1)
        self.assertEqual(resp.data['reps'], 8)
        self.assertTrue(resp.data['is_new_personal_record'])

        resp = self.client.post(
            f'/api/sessions/{session.id}/log-metric/',
            {'exercise_name': 'Squat', 'set_number': 2, 'reps': 8, 'weight_kg': 70},
        )
        self.assertFalse(resp.data['is_new_personal_record'])

    def test_session_log_metric_requires_exercise_name(self):
        session = WorkoutSession.objects.create(user=self.user, name='Leg Day')

        resp = self.client.post(
            f'/api/sessions/{session.id}/log-metric/',
            {'set_number': 1, 'reps': 8},
        )

        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('exercise_name', resp.data)

    def test_session_log_metric_accepts_duration(self):
        session = WorkoutSession.objects.create(user=self.user, name='Core')
        resp = self.client.post(
            f'/api/sessions/{session.id}/log-metric/',
            {
                'exercise_name': 'Plank',
                'set_number': 1,
                'reps': 0,
                'duration_seconds': 45,
            },
        )
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp.data['duration_seconds'], 45)

    def test_metric_summary_is_scoped_and_derived(self):
        session = WorkoutSession.objects.create(user=self.user, name='Strength')
        exercise = Exercise.objects.create(user=self.user, name='Squat')
        ProgressMetric.objects.create(
            session=session, exercise=exercise, reps=10, weight_kg=60
        )
        ProgressMetric.objects.create(
            session=session, exercise=exercise, reps=5, weight_kg=80
        )
        resp = self.client.get('/api/metrics/summary/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['total_volume_kg'], 1000.0)
        self.assertEqual(resp.data['estimated_one_rep_max_kg'], 93.33)
        self.assertEqual(resp.data['personal_records'], 1)
        self.assertEqual(resp.data['workout_count_by_week'][0]['workout_count'], 1)

    def test_last_metric_for_exercise_returns_latest_user_set(self):
        session = WorkoutSession.objects.create(user=self.user, name='Strength')
        exercise = Exercise.objects.create(user=self.user, name='Squat')
        ProgressMetric.objects.create(
            session=session, exercise=exercise, reps=5, weight_kg=60
        )
        latest = ProgressMetric.objects.create(
            session=session, exercise=exercise, reps=3, weight_kg=80
        )

        resp = self.client.get(
            f'/api/metrics/last-for-exercise/?exercise={exercise.id}'
        )

        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['result']['id'], str(latest.id))
        self.assertEqual(float(resp.data['result']['weight_kg']), 80.0)

    def test_last_metric_for_exercise_requires_an_exercise(self):
        resp = self.client.get('/api/metrics/last-for-exercise/')

        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('exercise', resp.data)

    def test_body_weight_can_be_logged_and_listed_for_current_user(self):
        resp = self.client.post('/api/body-weight/', {'weight_kg': '82.50'})

        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp.data['weight_kg'], '82.50')

        resp = self.client.get('/api/body-weight/')

        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp.data['results']), 1)

    def test_body_weight_rejects_negative_values(self):
        resp = self.client.post('/api/body-weight/', {'weight_kg': '-1'})

        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('weight_kg', resp.data)

    def test_meditation_session_can_be_logged_and_listed_for_current_user(self):
        resp = self.client.post('/api/meditation-sessions/', {
            'category': 'focus', 'duration_minutes': 10,
        })

        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp.data['category'], 'focus')
        self.assertEqual(resp.data['duration_minutes'], 10)

        resp = self.client.get('/api/meditation-sessions/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp.data['results']), 1)

    def test_meditation_session_rejects_invalid_category(self):
        resp = self.client.post('/api/meditation-sessions/', {
            'category': 'not-a-real-category', 'duration_minutes': 10,
        })
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('category', resp.data)

    def test_meditation_summary_is_scoped_and_derived(self):
        MeditationSession.objects.create(user=self.other_user, category='sleep', duration_minutes=99)
        self.client.post('/api/meditation-sessions/', {'category': 'sleep', 'duration_minutes': 5})
        self.client.post('/api/meditation-sessions/', {'category': 'focus', 'duration_minutes': 15})

        resp = self.client.get('/api/meditation-sessions/summary/')

        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['total_minutes'], 20)
        self.assertEqual(resp.data['session_count'], 2)
        self.assertEqual(resp.data['streak_days'], 1)

    def test_related_objects_must_belong_to_current_user(self):
        other_plan = Plan.objects.create(user=self.other_user, name='Private plan')
        resp = self.client.post('/api/exercises/', {'name': 'Leaked', 'plan': str(other_plan.id)})
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

        other_session = WorkoutSession.objects.create(user=self.other_user)
        resp = self.client.post('/api/metrics/', {
            'session': str(other_session.id), 'reps': 1,
        })
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_current_subscription_is_private_and_read_only(self):
        resp = self.client.get('/api/billing/subscription/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['plan_name'], 'free')
        self.assertEqual(resp.data['user'], self.user.id)
        self.assertNotIn('provider_customer_id', resp.data)
        self.assertEqual(Subscription.objects.filter(user=self.user).count(), 1)

        # No payment gateway is wired up: a client must not be able to grant
        # itself a paid plan by PATCHing plan_name directly.
        resp = self.client.patch('/api/billing/subscription/', {'plan_name': 'pro'})
        self.assertEqual(resp.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)
        self.assertEqual(Subscription.objects.get(user=self.user).plan_name, 'free')

    def test_join_waitlist_records_intent_without_granting_premium(self):
        resp = self.client.post('/api/billing/subscription/waitlist/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['plan_name'], 'free')
        self.assertEqual(resp.data['status'], 'waitlisted')
        self.assertEqual(Subscription.objects.get(user=self.user).status, 'waitlisted')

    def test_unauthenticated_rejected(self):
        self.client.force_authenticate(user=None)
        resp = self.client.get('/api/plans/')
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_feedback_can_be_submitted_with_attachment(self):
        image = SimpleUploadedFile(
            'screenshot.png',
            # 1x1 transparent PNG
            b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01'
            b'\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01'
            b'\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82',
            content_type='image/png',
        )
        resp = self.client.post('/api/feedback/', {
            'category': 'bug', 'message': 'The rest timer freezes on iOS.', 'attachment': image,
        }, format='multipart')

        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp.data['category'], 'bug')
        feedback = Feedback.objects.get(id=resp.data['id'])
        self.assertEqual(feedback.user, self.user)
        self.assertTrue(feedback.attachment)

    def test_feedback_requires_nonempty_message(self):
        resp = self.client.post('/api/feedback/', {'category': 'suggestion', 'message': '   '})
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('message', resp.data)

    def test_feedback_is_not_listable_from_the_app(self):
        # Submissions are reviewed exclusively in the Django admin panel, so
        # the API only exposes creation, not listing/retrieval.
        Feedback.objects.create(user=self.user, category='other', message='Mine')
        resp = self.client.get('/api/feedback/')
        self.assertEqual(resp.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)

    def test_feedback_rejected_when_unauthenticated(self):
        self.client.force_authenticate(user=None)
        resp = self.client.post('/api/feedback/', {'category': 'bug', 'message': 'x'})
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_exercise_lookup_returns_own_and_library_exercises_with_alternatives(self):
        alt = Exercise.objects.create(name='Bodyweight Squat', is_library=True)
        library_ex = Exercise.objects.create(name='Goblet Squat', is_library=True)
        library_ex.alternatives.add(alt)
        own_ex = Exercise.objects.create(user=self.user, name='My Curl')

        resp = self.client.get(f'/api/exercises/lookup/{library_ex.id}/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(
            [a['name'] for a in resp.data['alternatives_detail']], ['Bodyweight Squat'],
        )

        resp = self.client.get(f'/api/exercises/lookup/{own_ex.id}/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['name'], 'My Curl')

    def test_exercise_lookup_rejects_another_users_private_exercise(self):
        foreign_ex = Exercise.objects.create(user=self.other_user, name='Not yours')
        resp = self.client.get(f'/api/exercises/lookup/{foreign_ex.id}/')
        self.assertEqual(resp.status_code, status.HTTP_404_NOT_FOUND)

    def test_log_metric_accepts_optional_rpe_within_range(self):
        session = WorkoutSession.objects.create(user=self.user, name='Strength')
        resp = self.client.post(
            f'/api/sessions/{session.id}/log-metric/',
            {'exercise_name': 'Squat', 'set_number': 1, 'reps': 5, 'weight_kg': 100, 'rpe': '8.5'},
        )
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp.data['rpe'], '8.5')

    def test_progress_metric_rejects_rpe_outside_valid_range(self):
        session = WorkoutSession.objects.create(user=self.user, name='Strength')
        exercise = Exercise.objects.create(user=self.user, name='Squat')
        resp = self.client.post('/api/metrics/', {
            'session': str(session.id), 'exercise': str(exercise.id), 'reps': 5, 'rpe': '11',
        })
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('rpe', resp.data)

    def test_metric_summary_includes_average_rpe_when_present(self):
        session = WorkoutSession.objects.create(user=self.user, name='Strength')
        exercise = Exercise.objects.create(user=self.user, name='Squat')
        ProgressMetric.objects.create(session=session, exercise=exercise, reps=5, weight_kg=60, rpe='7')
        ProgressMetric.objects.create(session=session, exercise=exercise, reps=5, weight_kg=60, rpe='9')
        ProgressMetric.objects.create(session=session, exercise=exercise, reps=5, weight_kg=60)

        resp = self.client.get('/api/metrics/summary/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['average_rpe'], 8.0)

    def test_metric_summary_average_rpe_is_none_without_any_rpe_logged(self):
        session = WorkoutSession.objects.create(user=self.user, name='Strength')
        exercise = Exercise.objects.create(user=self.user, name='Squat')
        ProgressMetric.objects.create(session=session, exercise=exercise, reps=5, weight_kg=60)

        resp = self.client.get('/api/metrics/summary/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIsNone(resp.data['average_rpe'])

    def test_session_detail_is_owner_scoped(self):
        own_session = WorkoutSession.objects.create(user=self.user, name='Mine')
        resp = self.client.get(f'/api/sessions/{own_session.id}/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)

        foreign_session = WorkoutSession.objects.create(user=self.other_user, name='Not mine')
        resp = self.client.get(f'/api/sessions/{foreign_session.id}/')
        self.assertEqual(resp.status_code, status.HTTP_404_NOT_FOUND)

    def test_progress_photo_can_be_uploaded_listed_and_deleted(self):
        image = SimpleUploadedFile(
            'progress.png',
            b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01'
            b'\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01'
            b'\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82',
            content_type='image/png',
        )
        resp = self.client.post('/api/progress-photos/', {'image': image}, format='multipart')
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        photo_id = resp.data['id']

        resp = self.client.get('/api/progress-photos/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp.data['results']), 1)

        resp = self.client.delete(f'/api/progress-photos/{photo_id}/')
        self.assertEqual(resp.status_code, status.HTTP_204_NO_CONTENT)
        resp = self.client.get('/api/progress-photos/')
        self.assertEqual(len(resp.data['results']), 0)

    def test_progress_photos_are_never_visible_to_another_user(self):
        ProgressPhoto.objects.create(user=self.other_user, image=SimpleUploadedFile(
            'other.png',
            b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01'
            b'\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01'
            b'\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82',
            content_type='image/png',
        ))
        resp = self.client.get('/api/progress-photos/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp.data['results']), 0)

    def test_progress_photos_rejected_when_unauthenticated(self):
        self.client.force_authenticate(user=None)
        resp = self.client.get('/api/progress-photos/')
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_registration_returns_field_specific_validation_errors(self):
        resp = self.client.post('/api/auth/register/', {
            'username': 'apiuser',
            'email': 'not-an-email',
            'password': '123',
        })
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('username', resp.data)
        self.assertIn('email', resp.data)
        self.assertIn('password', resp.data)


class AuthenticationTests(APITestCase):
    """Login persistence: token issuance, refresh, logout invalidation."""

    def setUp(self):
        self.user = User.objects.create_user('authuser', 'auth@example.com', 'authpass123')

    def test_login_issues_access_and_refresh_tokens(self):
        resp = self.client.post('/api/auth/token/', {
            'username': 'authuser', 'password': 'authpass123',
        })
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIn('access', resp.data)
        self.assertIn('refresh', resp.data)

    def test_login_rejects_wrong_password(self):
        resp = self.client.post('/api/auth/token/', {
            'username': 'authuser', 'password': 'wrong-password',
        })
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_access_token_authenticates_requests(self):
        tokens = self.client.post('/api/auth/token/', {
            'username': 'authuser', 'password': 'authpass123',
        }).data
        resp = self.client.get(
            '/api/profiles/me/',
            HTTP_AUTHORIZATION=f'Bearer {tokens["access"]}',
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)

    def test_refresh_token_issues_a_new_access_token(self):
        tokens = self.client.post('/api/auth/token/', {
            'username': 'authuser', 'password': 'authpass123',
        }).data
        resp = self.client.post('/api/auth/token/refresh/', {
            'refresh': tokens['refresh'],
        })
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIn('access', resp.data)

    def test_logout_blacklists_refresh_token(self):
        tokens = self.client.post('/api/auth/token/', {
            'username': 'authuser', 'password': 'authpass123',
        }).data
        resp = self.client.post(
            '/api/auth/logout/',
            {'refresh': tokens['refresh']},
            HTTP_AUTHORIZATION=f'Bearer {tokens["access"]}',
        )
        self.assertEqual(resp.status_code, status.HTTP_205_RESET_CONTENT)

        # The blacklisted refresh token can no longer mint new access tokens.
        resp = self.client.post('/api/auth/token/refresh/', {
            'refresh': tokens['refresh'],
        })
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_logout_requires_authentication(self):
        resp = self.client.post('/api/auth/logout/', {'refresh': 'whatever'})
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_invalid_access_token_is_rejected(self):
        resp = self.client.get(
            '/api/profiles/me/',
            HTTP_AUTHORIZATION='Bearer not-a-real-token',
        )
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)


class SocialAuthTests(APITestCase):
    """Google/Apple sign-in: token verification is mocked at the function
    boundary (gym_api.views.verify_*_token) so these tests never hit real
    Google/Apple servers."""

    def test_google_auth_creates_new_user(self):
        claims = {
            'sub': 'g-123', 'email': 'newgoogle@example.com',
            'email_verified': True, 'given_name': 'New', 'family_name': 'Goog',
        }
        with mock.patch('gym_api.views.verify_google_id_token', return_value=claims):
            resp = self.client.post('/api/auth/google/', {'id_token': 'whatever'})
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertIn('access', resp.data)
        account = SocialAccount.objects.get(provider='google', provider_user_id='g-123')
        self.assertEqual(account.user.email, 'newgoogle@example.com')
        self.assertTrue(Profile.objects.filter(user=account.user).exists())
        self.assertTrue(Plan.objects.filter(user=account.user).exists())

    def test_google_auth_returning_user_logs_in(self):
        user = User.objects.create_user('googuser', 'existing-social@example.com')
        SocialAccount.objects.create(provider='google', provider_user_id='g-999', user=user, email=user.email)
        claims = {'sub': 'g-999', 'email': user.email, 'email_verified': True}
        with mock.patch('gym_api.views.verify_google_id_token', return_value=claims):
            resp = self.client.post('/api/auth/google/', {'id_token': 'whatever'})
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(SocialAccount.objects.filter(provider='google', provider_user_id='g-999').count(), 1)
        self.assertEqual(Plan.objects.filter(user=user).count(), 0)

    def test_google_auth_links_to_existing_verified_email_user(self):
        user = User.objects.create_user('emailuser', 'shared@example.com', 'somepass123')
        claims = {'sub': 'g-link-1', 'email': 'shared@example.com', 'email_verified': True}
        with mock.patch('gym_api.views.verify_google_id_token', return_value=claims):
            resp = self.client.post('/api/auth/google/', {'id_token': 'whatever'})
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(User.objects.filter(email='shared@example.com').count(), 1)
        account = SocialAccount.objects.get(provider='google', provider_user_id='g-link-1')
        self.assertEqual(account.user_id, user.id)

    def test_google_auth_rejects_unverified_email_auto_link(self):
        User.objects.create_user('emailuser2', 'unverified@example.com', 'somepass123')
        claims = {'sub': 'g-link-2', 'email': 'unverified@example.com', 'email_verified': False}
        with mock.patch('gym_api.views.verify_google_id_token', return_value=claims):
            resp = self.client.post('/api/auth/google/', {'id_token': 'whatever'})
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(SocialAccount.objects.filter(provider='google', provider_user_id='g-link-2').exists())

    def test_google_auth_invalid_token_rejected(self):
        with mock.patch('gym_api.views.verify_google_id_token', side_effect=ValueError('bad token')):
            resp = self.client.post('/api/auth/google/', {'id_token': 'whatever'})
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_apple_auth_creates_new_user(self):
        claims = {'sub': 'a-123', 'email': 'newapple@example.com'}
        with mock.patch('gym_api.views.verify_apple_identity_token', return_value=claims):
            resp = self.client.post('/api/auth/apple/', {
                'identity_token': 'whatever', 'first_name': 'Ann', 'last_name': 'Apple',
            })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        account = SocialAccount.objects.get(provider='apple', provider_user_id='a-123')
        self.assertEqual(account.user.first_name, 'Ann')
        self.assertEqual(account.user.last_name, 'Apple')
        self.assertTrue(Profile.objects.filter(user=account.user).exists())

    def test_apple_auth_returning_user_logs_in(self):
        user = User.objects.create_user('appleuser', 'apple-existing@example.com')
        SocialAccount.objects.create(provider='apple', provider_user_id='a-999', user=user, email=user.email)
        claims = {'sub': 'a-999', 'email': user.email}
        with mock.patch('gym_api.views.verify_apple_identity_token', return_value=claims):
            resp = self.client.post('/api/auth/apple/', {'identity_token': 'whatever'})
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(SocialAccount.objects.filter(provider='apple', provider_user_id='a-999').count(), 1)

    def test_apple_auth_invalid_token_rejected(self):
        with mock.patch('gym_api.views.verify_apple_identity_token', side_effect=ValueError('bad token')):
            resp = self.client.post('/api/auth/apple/', {'identity_token': 'whatever'})
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)


class PhoneAuthTests(APITestCase):
    """Phone/OTP sign-in: real SMS delivery is always mocked (TwilioSmsProvider.send)
    so these tests never hit the network, whether or not dev mode is active."""

    PHONE = '+34612345678'

    def setUp(self):
        # ScopedRateThrottle state lives in Django's cache, not the test DB,
        # so it isn't rolled back between tests by the transaction wrapper —
        # clear it explicitly so each test starts with a fresh throttle window.
        from django.core.cache import cache
        cache.clear()

    def _request_otp(self, phone=None):
        return self.client.post('/api/auth/phone/request-otp/', {'phone_number': phone or self.PHONE})

    def _verify_otp(self, code, phone=None):
        return self.client.post('/api/auth/phone/verify-otp/', {'phone_number': phone or self.PHONE, 'code': code})

    def _request_and_capture_code(self, phone=None):
        """Requests an OTP and extracts the real generated code from the
        (mocked) SMS message body, the way the real user would read it off
        their phone — avoids reaching into OTPVerification internals."""
        with mock.patch('gym_api.sms.TwilioSmsProvider.send') as send:
            resp = self._request_otp(phone=phone)
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        message = send.call_args.args[1]
        code = ''.join(ch for ch in message if ch.isdigit())[-6:]
        return code

    def test_request_otp_rejects_invalid_phone_number(self):
        with mock.patch('gym_api.sms.TwilioSmsProvider.send') as send:
            resp = self._request_otp(phone='not-a-phone-number')
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        send.assert_not_called()

    def test_request_otp_sends_random_code_in_normal_mode(self):
        with mock.patch('gym_api.sms.TwilioSmsProvider.send') as send:
            resp = self._request_otp()
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIn('resend_after_seconds', resp.data)
        send.assert_called_once()
        message = send.call_args.args[1]
        self.assertNotIn('123456', message)

    @override_settings(SAFE_DEV_OTP_AUTH_PASS='test-dev-secret', DEBUG=True)
    def test_request_otp_uses_dev_code_and_skips_real_sms_in_dev_mode(self):
        with mock.patch('gym_api.sms.TwilioSmsProvider.send') as send:
            resp = self._request_otp()
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        send.assert_not_called()
        with mock.patch('gym_api.sms.TwilioSmsProvider.send') as send2:
            verify_resp = self._verify_otp('123456')
        self.assertEqual(verify_resp.status_code, status.HTTP_201_CREATED)
        send2.assert_not_called()

    def test_verify_otp_creates_new_user_and_provisions_them(self):
        code = self._request_and_capture_code()
        resp = self._verify_otp(code)
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertIn('access', resp.data)
        profile = Profile.objects.get(phone_number=self.PHONE)
        self.assertTrue(Plan.objects.filter(user=profile.user).exists())

    def test_verify_otp_returning_user_logs_in_without_duplicate(self):
        first_code = self._request_and_capture_code()
        first = self._verify_otp(first_code)
        self.assertEqual(first.status_code, status.HTTP_201_CREATED)

        second_code = self._request_and_capture_code()
        second = self._verify_otp(second_code)
        self.assertEqual(second.status_code, status.HTTP_200_OK)
        self.assertEqual(Profile.objects.filter(phone_number=self.PHONE).count(), 1)

    def test_verify_otp_rejects_wrong_code_and_tracks_attempts(self):
        self._request_and_capture_code()
        resp = self._verify_otp('000000')
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        otp = OTPVerification.objects.latest('created_at')
        self.assertEqual(otp.attempts, 1)
        self.assertFalse(otp.used)

    def test_verify_otp_rejects_expired_code(self):
        code = self._request_and_capture_code()
        otp = OTPVerification.objects.latest('created_at')
        otp.expires_at = timezone.now() - timezone.timedelta(seconds=1)
        otp.save(update_fields=['expires_at'])
        resp = self._verify_otp(code)
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_verify_otp_cannot_be_reused(self):
        code = self._request_and_capture_code()
        first = self._verify_otp(code)
        self.assertEqual(first.status_code, status.HTTP_201_CREATED)
        second = self._verify_otp(code)
        self.assertEqual(second.status_code, status.HTTP_400_BAD_REQUEST)

    def test_verify_otp_invalidates_after_max_attempts(self):
        self._request_and_capture_code()
        for _ in range(5):
            resp = self._verify_otp('000000')
        self.assertEqual(resp.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        otp = OTPVerification.objects.latest('created_at')
        self.assertTrue(otp.used)

    def test_resend_cooldown_blocks_immediate_second_request(self):
        with mock.patch('gym_api.sms.TwilioSmsProvider.send'):
            first = self._request_otp()
            second = self._request_otp()
        self.assertEqual(first.status_code, status.HTTP_200_OK)
        self.assertEqual(second.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        self.assertIn('retry_after_seconds', second.data)


class EnvGuardsTests(TestCase):
    """Production startup safety, tested directly against the extracted
    check_production_safety() rather than by re-importing settings.py."""

    def test_production_with_dev_otp_pass_refuses_to_start(self):
        with self.assertRaises(RuntimeError):
            check_production_safety(
                {'DJANGO_ENV': 'production', 'SAFE_DEV_OTP_AUTH_PASS': 'oops'},
                debug=False,
                secret_key='a-real-secret',
            )

    def test_production_without_dev_otp_pass_is_valid(self):
        check_production_safety(
            {'DJANGO_ENV': 'production'}, debug=False, secret_key='a-real-secret',
        )

    def test_production_with_debug_true_still_refuses(self):
        with self.assertRaises(RuntimeError):
            check_production_safety(
                {'DJANGO_ENV': 'production'}, debug=True, secret_key='a-real-secret',
            )

    def test_development_may_set_dev_otp_pass(self):
        check_production_safety(
            {'SAFE_DEV_OTP_AUTH_PASS': 'fine-in-dev'}, debug=True, secret_key='dev-secret-key-change-in-production',
        )


class GymBroTests(APITestCase):
    def setUp(self):
        self.user_a = User.objects.create_user('bro_a', 'a@example.com', 'pass12345')
        self.user_b = User.objects.create_user('bro_b', 'b@example.com', 'pass12345')
        self.user_c = User.objects.create_user('bro_c', 'c@example.com', 'pass12345')
        for user, bio in ((self.user_a, 'A bio'), (self.user_b, 'B bio'), (self.user_c, 'C bio')):
            Profile.objects.create(user=user, bio=bio, training_goals=['strength'])

    def _login(self, user):
        self.client.force_authenticate(user=user)

    def test_discover_excludes_self_and_incomplete_profiles(self):
        incomplete_user = User.objects.create_user('incomplete', 'inc@example.com', 'pass12345')
        Profile.objects.create(user=incomplete_user)  # no bio/goals
        self._login(self.user_a)
        resp = self.client.get('/api/profiles/discover/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        usernames = {row['user']['username'] for row in resp.data}
        self.assertNotIn('bro_a', usernames)
        self.assertNotIn('incomplete', usernames)
        self.assertIn('bro_b', usernames)

    def test_discover_excludes_already_swiped(self):
        self._login(self.user_a)
        self.client.post('/api/swipes/', {'to_user': self.user_b.id, 'direction': 'pass'}, format='json')
        resp = self.client.get('/api/profiles/discover/')
        usernames = {row['user']['username'] for row in resp.data}
        self.assertNotIn('bro_b', usernames)
        self.assertIn('bro_c', usernames)

    def test_swipe_cannot_target_self(self):
        self._login(self.user_a)
        resp = self.client.post('/api/swipes/', {'to_user': self.user_a.id, 'direction': 'like'}, format='json')
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_one_sided_like_does_not_match(self):
        self._login(self.user_a)
        resp = self.client.post('/api/swipes/', {'to_user': self.user_b.id, 'direction': 'like'}, format='json')
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertFalse(resp.data['matched'])
        self.assertEqual(Match.objects.count(), 0)

    def test_mutual_like_creates_match(self):
        self._login(self.user_a)
        self.client.post('/api/swipes/', {'to_user': self.user_b.id, 'direction': 'like'}, format='json')
        self._login(self.user_b)
        resp = self.client.post('/api/swipes/', {'to_user': self.user_a.id, 'direction': 'like'}, format='json')
        self.assertTrue(resp.data['matched'])
        self.assertEqual(Match.objects.count(), 1)

        # Re-swiping the same pair must not create a duplicate match.
        resp2 = self.client.post('/api/swipes/', {'to_user': self.user_a.id, 'direction': 'like'}, format='json')
        self.assertTrue(resp2.data['matched'])
        self.assertEqual(Match.objects.count(), 1)

    def test_swipe_is_idempotent_per_pair(self):
        self._login(self.user_a)
        self.client.post('/api/swipes/', {'to_user': self.user_b.id, 'direction': 'like'}, format='json')
        self.client.post('/api/swipes/', {'to_user': self.user_b.id, 'direction': 'pass'}, format='json')
        self.assertEqual(Swipe.objects.filter(from_user=self.user_a, to_user=self.user_b).count(), 1)
        swipe = Swipe.objects.get(from_user=self.user_a, to_user=self.user_b)
        self.assertEqual(swipe.direction, 'pass')

    def test_matches_list_shows_other_users_profile(self):
        self._login(self.user_a)
        self.client.post('/api/swipes/', {'to_user': self.user_b.id, 'direction': 'like'}, format='json')
        self._login(self.user_b)
        self.client.post('/api/swipes/', {'to_user': self.user_a.id, 'direction': 'like'}, format='json')

        resp = self.client.get('/api/gym-bro/matches/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp.data['results']), 1)
        self.assertEqual(resp.data['results'][0]['profile']['user']['username'], 'bro_a')

    def test_chat_send_and_list_messages(self):
        self._login(self.user_a)
        self.client.post('/api/swipes/', {'to_user': self.user_b.id, 'direction': 'like'}, format='json')
        self._login(self.user_b)
        match_resp = self.client.post('/api/swipes/', {'to_user': self.user_a.id, 'direction': 'like'}, format='json')
        match_id = match_resp.data['match_id']

        resp = self.client.post(f'/api/gym-bro/matches/{match_id}/messages/', {'text': 'Hey!'}, format='json')
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)

        self._login(self.user_a)
        resp = self.client.get(f'/api/gym-bro/matches/{match_id}/messages/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp.data), 1)
        self.assertEqual(resp.data[0]['text'], 'Hey!')

    def test_chat_rejects_unauthorized_user(self):
        self._login(self.user_a)
        self.client.post('/api/swipes/', {'to_user': self.user_b.id, 'direction': 'like'}, format='json')
        self._login(self.user_b)
        match_resp = self.client.post('/api/swipes/', {'to_user': self.user_a.id, 'direction': 'like'}, format='json')
        match_id = match_resp.data['match_id']

        self._login(self.user_c)
        resp = self.client.get(f'/api/gym-bro/matches/{match_id}/messages/')
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)
        resp = self.client.post(f'/api/gym-bro/matches/{match_id}/messages/', {'text': 'hi'}, format='json')
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_empty_message_rejected(self):
        self._login(self.user_a)
        self.client.post('/api/swipes/', {'to_user': self.user_b.id, 'direction': 'like'}, format='json')
        self._login(self.user_b)
        match_resp = self.client.post('/api/swipes/', {'to_user': self.user_a.id, 'direction': 'like'}, format='json')
        match_id = match_resp.data['match_id']

        resp = self.client.post(f'/api/gym-bro/matches/{match_id}/messages/', {'text': '   '}, format='json')
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)


class FakeOpenRouterService:
    """Test double for OpenRouterService — never touches the network."""

    def __init__(self, chunks=None, error=None):
        self._chunks = chunks if chunks is not None else [
            StreamChunk(delta_text='Hello '),
            StreamChunk(delta_text='there!', finish_reason='stop', usage={'prompt_tokens': 5, 'completion_tokens': 2}),
        ]
        self._error = error

    def stream_chat_completion(self, messages):
        if self._error:
            raise self._error
        for chunk in self._chunks:
            yield chunk


def _consume_stream(response):
    return b''.join(response.streaming_content).decode('utf-8')


class AIChatTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user('aiuser', 'ai@example.com', 'aipass123')
        self.other_user = User.objects.create_user('aiother', 'aiother@example.com', 'aiother123')

    # --- Auth -------------------------------------------------------
    def test_unauthenticated_access_rejected(self):
        for resp in (
            self.client.get('/api/ai/folder/'),
            self.client.get('/api/ai/conversations/'),
            self.client.post('/api/ai/conversations/', {}, format='json'),
        ):
            self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)

    # --- Folder -------------------------------------------------------
    def test_folder_created_automatically_and_reused(self):
        self.client.force_authenticate(user=self.user)
        resp1 = self.client.get('/api/ai/folder/')
        self.assertEqual(resp1.status_code, 200)
        self.assertEqual(resp1.data['name'], 'AI Discussions')
        resp2 = self.client.get('/api/ai/folder/')
        self.assertEqual(resp1.data['id'], resp2.data['id'])
        self.assertEqual(AIConversationFolder.objects.filter(user=self.user).count(), 1)

    def test_only_one_folder_per_user_enforced_at_db_level(self):
        AIConversationFolder.objects.create(user=self.user)
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                AIConversationFolder.objects.create(user=self.user)

    # --- Conversations --------------------------------------------------
    def test_conversation_crud_and_ownership(self):
        self.client.force_authenticate(user=self.user)
        create = self.client.post('/api/ai/conversations/', {}, format='json')
        self.assertEqual(create.status_code, 201)
        conv_id = create.data['id']
        self.assertEqual(create.data['title'], 'New Chat')

        listed = self.client.get('/api/ai/conversations/')
        self.assertEqual(listed.status_code, 200)

        retrieved = self.client.get(f'/api/ai/conversations/{conv_id}/')
        self.assertEqual(retrieved.status_code, 200)

        renamed = self.client.patch(f'/api/ai/conversations/{conv_id}/', {'title': 'Push day plan'}, format='json')
        self.assertEqual(renamed.status_code, 200)
        self.assertEqual(renamed.data['title'], 'Push day plan')

        deleted = self.client.delete(f'/api/ai/conversations/{conv_id}/')
        self.assertEqual(deleted.status_code, 204)
        self.assertFalse(AIConversation.objects.filter(id=conv_id).exists())

    def test_user_cannot_access_another_users_conversation(self):
        self.client.force_authenticate(user=self.user)
        conv_id = self.client.post('/api/ai/conversations/', {}, format='json').data['id']

        self.client.force_authenticate(user=self.other_user)
        self.assertEqual(self.client.get(f'/api/ai/conversations/{conv_id}/').status_code, 404)
        self.assertEqual(
            self.client.patch(f'/api/ai/conversations/{conv_id}/', {'title': 'hijacked'}, format='json').status_code,
            404,
        )
        self.assertEqual(self.client.delete(f'/api/ai/conversations/{conv_id}/').status_code, 404)
        self.assertEqual(self.client.get(f'/api/ai/conversations/{conv_id}/messages/').status_code, 404)
        self.assertEqual(
            self.client.post(f'/api/ai/conversations/{conv_id}/stream/', {'content': 'hi'}, format='json').status_code,
            404,
        )
        # Original conversation must be untouched.
        conv = AIConversation.objects.get(id=conv_id)
        self.assertNotEqual(conv.title, 'hijacked')

    # --- Messages / streaming --------------------------------------------
    def _make_conversation(self):
        folder = AIConversationFolder.objects.create(user=self.user)
        return AIConversation.objects.create(folder=folder)

    def test_send_message_persists_user_and_assistant_messages(self):
        self.client.force_authenticate(user=self.user)
        conversation = self._make_conversation()

        with mock.patch('gym_api.views.get_openrouter_service', return_value=FakeOpenRouterService()):
            resp = self.client.post(
                f'/api/ai/conversations/{conversation.id}/stream/', {'content': 'How should I train legs?'}, format='json'
            )
        self.assertEqual(resp.status_code, 200)
        body = _consume_stream(resp)
        self.assertIn('Hello ', body)
        self.assertIn('there!', body)
        self.assertIn('event: done', body)

        messages = list(conversation.messages.order_by('created_at'))
        self.assertEqual(len(messages), 2)
        self.assertEqual(messages[0].role, AIMessage.ROLE_USER)
        self.assertEqual(messages[0].content, 'How should I train legs?')
        self.assertEqual(messages[1].role, AIMessage.ROLE_ASSISTANT)
        self.assertEqual(messages[1].content, 'Hello there!')
        self.assertEqual(messages[1].status, AIMessage.STATUS_COMPLETED)
        self.assertEqual(messages[1].input_tokens, 5)
        self.assertEqual(messages[1].output_tokens, 2)

        conversation.refresh_from_db()
        self.assertEqual(conversation.title, title_from_message('How should I train legs?'))

    def test_message_list_ordering(self):
        self.client.force_authenticate(user=self.user)
        conversation = self._make_conversation()
        with mock.patch('gym_api.views.get_openrouter_service', return_value=FakeOpenRouterService()):
            self.client.post(f'/api/ai/conversations/{conversation.id}/stream/', {'content': 'first'}, format='json')

        resp = self.client.get(f'/api/ai/conversations/{conversation.id}/messages/')
        self.assertEqual(resp.status_code, 200)
        roles = [m['role'] for m in resp.data['results']]
        self.assertEqual(roles, ['user', 'assistant'])

    def test_client_cannot_inject_role_or_extra_fields(self):
        self.client.force_authenticate(user=self.user)
        conversation = self._make_conversation()
        with mock.patch('gym_api.views.get_openrouter_service', return_value=FakeOpenRouterService()):
            self.client.post(
                f'/api/ai/conversations/{conversation.id}/stream/',
                {'content': 'hi', 'role': 'system'},
                format='json',
            )
        user_message = conversation.messages.filter(role=AIMessage.ROLE_USER).first()
        self.assertIsNotNone(user_message)
        self.assertEqual(user_message.role, AIMessage.ROLE_USER)

    def test_streaming_upstream_error_marks_message_failed_and_preserves_user_message(self):
        self.client.force_authenticate(user=self.user)
        conversation = self._make_conversation()
        with mock.patch(
            'gym_api.views.get_openrouter_service',
            return_value=FakeOpenRouterService(error=OpenRouterError('boom')),
        ):
            resp = self.client.post(
                f'/api/ai/conversations/{conversation.id}/stream/', {'content': 'hello'}, format='json'
            )
        body = _consume_stream(resp)
        self.assertIn('event: error', body)

        messages = list(conversation.messages.order_by('created_at'))
        self.assertEqual(messages[0].role, AIMessage.ROLE_USER)
        self.assertEqual(messages[0].content, 'hello')
        self.assertEqual(messages[1].status, AIMessage.STATUS_FAILED)

    def test_streaming_timeout_marks_message_failed(self):
        self.client.force_authenticate(user=self.user)
        conversation = self._make_conversation()
        with mock.patch(
            'gym_api.views.get_openrouter_service',
            return_value=FakeOpenRouterService(error=OpenRouterTimeout('timed out')),
        ):
            resp = self.client.post(
                f'/api/ai/conversations/{conversation.id}/stream/', {'content': 'hello'}, format='json'
            )
        _consume_stream(resp)
        assistant_message = conversation.messages.filter(role=AIMessage.ROLE_ASSISTANT).first()
        self.assertEqual(assistant_message.status, AIMessage.STATUS_FAILED)

    def test_empty_message_rejected(self):
        self.client.force_authenticate(user=self.user)
        conversation = self._make_conversation()
        resp = self.client.post(f'/api/ai/conversations/{conversation.id}/stream/', {'content': '   '}, format='json')
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    @override_settings(AI_CHAT_MAX_MESSAGE_LENGTH=10)
    def test_oversized_message_rejected(self):
        self.client.force_authenticate(user=self.user)
        conversation = self._make_conversation()
        resp = self.client.post(
            f'/api/ai/conversations/{conversation.id}/stream/',
            {'content': 'this message is way too long'},
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(conversation.messages.exists())

    @override_settings(AI_CHAT_DAILY_MESSAGE_LIMIT=1)
    def test_daily_message_limit_enforced(self):
        self.client.force_authenticate(user=self.user)
        conversation = self._make_conversation()
        with mock.patch('gym_api.views.get_openrouter_service', return_value=FakeOpenRouterService()):
            first = self.client.post(
                f'/api/ai/conversations/{conversation.id}/stream/', {'content': 'one'}, format='json'
            )
            _consume_stream(first)
            second = self.client.post(
                f'/api/ai/conversations/{conversation.id}/stream/', {'content': 'two'}, format='json'
            )
        self.assertEqual(second.status_code, status.HTTP_429_TOO_MANY_REQUESTS)

    def test_title_generated_from_first_message_only(self):
        self.client.force_authenticate(user=self.user)
        conversation = self._make_conversation()
        with mock.patch('gym_api.views.get_openrouter_service', return_value=FakeOpenRouterService()):
            self.client.post(
                f'/api/ai/conversations/{conversation.id}/stream/',
                {'content': 'How should I structure my push workout?'},
                format='json',
            )
            conversation.refresh_from_db()
            first_title = conversation.title
            self.client.post(
                f'/api/ai/conversations/{conversation.id}/stream/', {'content': 'a follow up question'}, format='json'
            )
        conversation.refresh_from_db()
        self.assertEqual(conversation.title, first_title)
        self.assertNotEqual(conversation.title, 'New Chat')
