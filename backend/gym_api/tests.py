"""
Simple smoke tests for the gym_api app.
Run with: python manage.py test gym_api
"""
from django.contrib.auth.models import User
from django.test import TestCase
from rest_framework.test import APITestCase
from rest_framework import status
from .models import Profile, Plan, Exercise, WorkoutSession, ProgressMetric, Subscription


class ModelTests(TestCase):
    def test_profile_str(self):
        user = User.objects.create_user('testuser', 'test@example.com', 'pass1234')
        profile = Profile.objects.create(user=user, display_name='Test User')
        self.assertEqual(str(profile), 'Test User')

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
        self.assertEqual([item['name'] for item in resp.data['results']], ['Bench Press'])

    def test_library_exercises_return_empty_results_for_unknown_filter(self):
        Exercise.objects.create(
            name='Bench Press',
            body_part='Chest',
            is_library=True,
        )

        resp = self.client.get('/api/library/exercises/?body_part=Legs')

        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['results'], [])

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

    def test_session_log_metric_requires_exercise_name(self):
        session = WorkoutSession.objects.create(user=self.user, name='Leg Day')

        resp = self.client.post(
            f'/api/sessions/{session.id}/log-metric/',
            {'set_number': 1, 'reps': 8},
        )

        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('exercise_name', resp.data)

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

    def test_related_objects_must_belong_to_current_user(self):
        other_plan = Plan.objects.create(user=self.other_user, name='Private plan')
        resp = self.client.post('/api/exercises/', {'name': 'Leaked', 'plan': str(other_plan.id)})
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

        other_session = WorkoutSession.objects.create(user=self.other_user)
        resp = self.client.post('/api/metrics/', {
            'session': str(other_session.id), 'reps': 1,
        })
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_current_subscription_is_private_and_updatable(self):
        resp = self.client.get('/api/billing/subscription/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['plan_name'], 'free')
        self.assertEqual(Subscription.objects.filter(user=self.user).count(), 1)

        resp = self.client.patch('/api/billing/subscription/', {'plan_name': 'pro'})
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['plan_name'], 'pro')
        self.assertEqual(resp.data['user'], self.user.id)
        self.assertNotIn('provider_customer_id', resp.data)

    def test_unauthenticated_rejected(self):
        self.client.force_authenticate(user=None)
        resp = self.client.get('/api/plans/')
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
