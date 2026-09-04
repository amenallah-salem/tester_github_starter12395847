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

    def test_exercise_crud(self):
        resp = self.client.post('/api/exercises/', {'name': 'Deadlift', 'target_sets': 4, 'target_reps': 6})
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)

    def test_session_crud(self):
        resp = self.client.post('/api/sessions/', {'name': 'Morning Workout'})
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)

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
