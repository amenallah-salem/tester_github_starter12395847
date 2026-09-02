"""
Simple smoke tests for the gym_api app.
Run with: python manage.py test gym_api
"""
from django.contrib.auth.models import User
from django.test import TestCase
from rest_framework.test import APITestCase
from rest_framework import status
from .models import Profile, Plan, Exercise, WorkoutSession, ProgressMetric


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

    def test_unauthenticated_rejected(self):
        self.client.force_authenticate(user=None)
        resp = self.client.get('/api/plans/')
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)
