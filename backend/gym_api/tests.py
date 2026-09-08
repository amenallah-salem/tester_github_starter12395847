"""
Simple smoke tests for the gym_api app.
Run with: python manage.py test gym_api
"""
from django.contrib.auth.models import User
from django.test import TestCase
from rest_framework.test import APITestCase
from rest_framework import status
from .models import (
    Profile, Plan, Exercise, WorkoutSession, ProgressMetric, Subscription,
    FavoriteExercise, Swipe, Match, GymBroMessage,
)


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
