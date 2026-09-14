"""
REST views for the Gym Planner API.
"""
import json
import uuid
from datetime import timedelta

from rest_framework import viewsets, permissions, status, mixins, generics
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView
from django.conf import settings
from django.contrib.auth.models import User
from django.db import IntegrityError, connections, models, transaction
from django.db.models import F, Max, Sum, Q
from django.db.models.functions import TruncWeek
from django.db.utils import OperationalError
from django.http import StreamingHttpResponse
from django.shortcuts import get_object_or_404
from django.utils import timezone

from .models import (
    Profile, Plan, Exercise, PlanDay, PlanDayExercise,
    WorkoutSession, ProgressMetric, BodyWeightEntry, FavoriteExercise, Subscription,
    Swipe, Match, GymBroMessage, MeditationSession, Feedback, ProgressPhoto,
    SocialAccount, AIConversationFolder, AIConversation, AIMessage,
)
from .serializers import (
    ProfileSerializer,
    PlanSerializer,
    PlanListSerializer,
    ExerciseSerializer,
    WorkoutSessionSerializer,
    WorkoutSessionListSerializer,
    ProgressMetricSerializer,
    RegisterSerializer,
    SubscriptionSerializer,
    PlanDaySerializer,
    BodyWeightEntrySerializer,
    FavoriteExerciseSerializer,
    SwipeSerializer,
    MatchSerializer,
    GymBroMessageSerializer,
    MeditationSessionSerializer,
    FeedbackSerializer,
    ProgressPhotoSerializer,
    GoogleAuthSerializer,
    AppleAuthSerializer,
    PhoneOTPRequestSerializer,
    PhoneOTPVerifySerializer,
    AIConversationFolderSerializer,
    AIConversationSerializer,
    AIMessageSerializer,
    AISendMessageSerializer,
)
from . import otp as otp_service
from .sms import SmsDeliveryError
from .ai import limits as ai_limits
from .ai.context import build_messages as ai_build_messages
from .ai.openrouter import (
    OpenRouterAuthError,
    OpenRouterError,
    OpenRouterRateLimited,
    OpenRouterService,
    OpenRouterTimeout,
)
from .ai.freellmapi import (
    FreellmapiAuthError,
    FreellmapiError,
    FreellmapiRateLimited,
    FreellmapiService,
    FreellmapiTimeout,
)
from .ai.titles import title_from_message

AI_SERVICE_ERRORS = (
    OpenRouterAuthError, OpenRouterRateLimited, OpenRouterTimeout, OpenRouterError,
    FreellmapiAuthError, FreellmapiRateLimited, FreellmapiTimeout, FreellmapiError,
)


class HealthCheckView(APIView):
    """
    Lightweight, unauthenticated readiness probe for use by Docker/CI startup
    scripts and orchestrators. Unlike the DRF router root ("/api/"), this view
    does not require authentication (the router root inherits the project's
    default IsAuthenticated permission, so it returns 401 even when Django and
    the database are perfectly healthy).

    Returns 200 with {"status": "ok"} once Django can reach the database, or
    503 with {"status": "error"} if the database connection is not usable.
    """
    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    def get(self, request):
        try:
            connections['default'].ensure_connection()
        except OperationalError as exc:
            return Response(
                {'status': 'error', 'detail': str(exc)},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        return Response({'status': 'ok'}, status=status.HTTP_200_OK)


def _provision_new_user(user):
    """Shared post-creation setup for a brand-new User, regardless of signup
    path (email/password RegisterView or social auth). Idempotent: safe to
    call again for an already-provisioned user (e.g. a returning social user
    being linked for the first time) without duplicating their starter plan.
    """
    Profile.objects.get_or_create(user=user)
    if not Plan.objects.filter(user=user).exists():
        starter_plan = Plan.objects.create(
            user=user,
            name='Starter Week',
            description='A simple full-body routine to get started.',
        )
        starter_exercises = list(
            Exercise.objects.filter(is_library=True).order_by('created_at')[:3]
        )
        if starter_exercises:
            starter_day = PlanDay.objects.create(plan=starter_plan, weekday=0)
            PlanDayExercise.objects.bulk_create([
                PlanDayExercise(
                    plan_day=starter_day,
                    exercise=exercise,
                    order=order,
                )
                for order, exercise in enumerate(starter_exercises)
            ])


def _issue_tokens_response(user, status_code):
    from rest_framework_simplejwt.tokens import RefreshToken
    refresh = RefreshToken.for_user(user)
    return Response({
        'user': {'id': user.id, 'username': user.username, 'email': user.email},
        'access': str(refresh.access_token),
        'refresh': str(refresh),
    }, status=status_code)


def verify_google_id_token(token):
    """Verify a Google id_token server-side. Returns the verified claims
    dict (sub, email, email_verified, given_name, family_name, ...).
    Raises ValueError if the token is invalid, expired, or issued for an
    audience not in settings.GOOGLE_OAUTH_CLIENT_IDS.
    """
    from google.oauth2 import id_token as google_id_token
    from google.auth.transport import requests as google_requests
    from django.conf import settings

    idinfo = google_id_token.verify_oauth2_token(token, google_requests.Request())
    if not settings.GOOGLE_OAUTH_CLIENT_IDS or idinfo.get('aud') not in settings.GOOGLE_OAUTH_CLIENT_IDS:
        raise ValueError('Unrecognized audience')
    return idinfo


def verify_apple_identity_token(token):
    """Verify an Apple identity_token server-side (native iOS Sign in with
    Apple). Returns the verified claims dict (sub, email, ...). Raises
    ValueError if the token is invalid, expired, or fails signature/audience/
    issuer checks.
    """
    import jwt
    from jwt import PyJWKClient
    from django.conf import settings

    if not settings.APPLE_BUNDLE_ID:
        raise ValueError('Apple sign-in is not configured')
    try:
        jwk_client = PyJWKClient('https://appleid.apple.com/auth/keys')
        signing_key = jwk_client.get_signing_key_from_jwt(token)
        payload = jwt.decode(
            token,
            signing_key.key,
            algorithms=['RS256'],
            audience=settings.APPLE_BUNDLE_ID,
            issuer='https://appleid.apple.com',
        )
    except jwt.PyJWTError as exc:
        raise ValueError(str(exc)) from exc
    return payload


def find_or_create_social_user(provider, subject, email, email_verified, first_name='', last_name=''):
    """Resolve a verified provider identity to a Django User.

    1. An existing SocialAccount(provider, subject) -> that user (returning
       social user).
    2. No SocialAccount match, but the provider asserts a verified email that
       matches an existing User.email -> auto-link a new SocialAccount to
       that existing user (no password confirmation; the provider has
       already proven ownership of the email).
    3. Otherwise -> create a brand-new User (unusable password), provision it
       like a normal signup, and link a new SocialAccount.

    Raises ValueError if the email is unverified and there is no existing
    SocialAccount to match against — we can neither safely link nor safely
    dedupe on an email we don't trust.

    Returns (user, created: bool).
    """
    existing = SocialAccount.objects.filter(provider=provider, provider_user_id=subject).first()
    if existing is not None:
        return existing.user, False

    if not email_verified:
        raise ValueError('Email could not be verified by the provider.')

    user = User.objects.filter(email=email).first() if email else None
    if user is not None:
        SocialAccount.objects.create(provider=provider, provider_user_id=subject, user=user, email=email)
        _provision_new_user(user)
        return user, False

    username = _unique_username_for_social_signup(provider, subject, email)
    user = User.objects.create_user(
        username=username,
        email=email or '',
        password=None,
        first_name=first_name or '',
        last_name=last_name or '',
    )
    SocialAccount.objects.create(provider=provider, provider_user_id=subject, user=user, email=email)
    _provision_new_user(user)
    return user, True


def _unique_username_for_social_signup(provider, subject, email):
    import re
    base = (email.split('@')[0] if email else f'{provider}_{subject[:12]}')
    base = re.sub(r'[^A-Za-z0-9_.@+-]', '', base) or f'{provider}user'
    candidate = base
    suffix = 1
    while User.objects.filter(username=candidate).exists():
        suffix += 1
        candidate = f'{base}{suffix}'
    return candidate


class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]
    def post(self, request):
        s = RegisterSerializer(data=request.data)
        if s.is_valid():
            user = s.save()
            _provision_new_user(user)
            return _issue_tokens_response(user, status.HTTP_201_CREATED)
        return Response(s.errors, status=status.HTTP_400_BAD_REQUEST)


class GoogleAuthView(APIView):
    """POST /auth/google/ – exchange a verified Google id_token for the
    application's normal JWT session, creating or linking the account as
    needed. See find_or_create_social_user for the resolution rules."""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        s = GoogleAuthSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        try:
            idinfo = verify_google_id_token(s.validated_data['id_token'])
        except ValueError:
            return Response({'detail': 'Invalid Google token.'}, status=status.HTTP_401_UNAUTHORIZED)
        try:
            user, created = find_or_create_social_user(
                provider='google',
                subject=idinfo['sub'],
                email=idinfo.get('email', ''),
                email_verified=bool(idinfo.get('email_verified')),
                first_name=idinfo.get('given_name', ''),
                last_name=idinfo.get('family_name', ''),
            )
        except ValueError as exc:
            return Response({'detail': str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        return _issue_tokens_response(user, status.HTTP_201_CREATED if created else status.HTTP_200_OK)


class AppleAuthView(APIView):
    """POST /auth/apple/ – exchange a verified Apple identity_token for the
    application's normal JWT session (native iOS Sign in with Apple only).
    Apple only sends first_name/last_name on the user's very first
    authorization; they are optional here and their absence on later
    sign-ins is expected, not an error."""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        s = AppleAuthSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        try:
            claims = verify_apple_identity_token(s.validated_data['identity_token'])
        except ValueError:
            return Response({'detail': 'Invalid Apple token.'}, status=status.HTTP_401_UNAUTHORIZED)
        try:
            user, created = find_or_create_social_user(
                provider='apple',
                subject=claims['sub'],
                email=claims.get('email', ''),
                email_verified=True,
                first_name=s.validated_data.get('first_name', ''),
                last_name=s.validated_data.get('last_name', ''),
            )
        except ValueError as exc:
            return Response({'detail': str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        return _issue_tokens_response(user, status.HTTP_201_CREATED if created else status.HTTP_200_OK)


def _unique_username_for_phone_signup(phone_number):
    import re
    digits = re.sub(r'\D', '', phone_number)
    base = f'phone_{digits}'
    candidate = base
    suffix = 1
    while User.objects.filter(username=candidate).exists():
        suffix += 1
        candidate = f'{base}{suffix}'
    return candidate


def find_or_create_phone_user(phone_number):
    """Resolve a verified phone number to a Django User.

    Only matches against Profile.phone_number set by a PRIOR phone
    verification — this deliberately does not attempt to link to an existing
    email/Google/Apple account, since none of those flows collect a verified
    phone number to match against (see docs/authentication.md's "Account
    linking" note for the accepted limitation this implies).

    Returns (user, created: bool).
    """
    existing = Profile.objects.filter(phone_number=phone_number).select_related('user').first()
    if existing is not None:
        return existing.user, False

    username = _unique_username_for_phone_signup(phone_number)
    user = User.objects.create_user(username=username, password=None)
    _provision_new_user(user)
    try:
        with transaction.atomic():
            Profile.objects.filter(user=user).update(phone_number=phone_number)
    except IntegrityError:
        # Lost a race with a simultaneous first-verification of the same
        # number: someone else's Profile now owns it, so use that account
        # instead of leaving this freshly-created user phoneless/orphaned.
        user.delete()
        existing = Profile.objects.filter(phone_number=phone_number).select_related('user').first()
        return existing.user, False
    return user, True


class PhoneOTPRequestView(APIView):
    """POST /auth/phone/request-otp/ – send (or simulate, in dev) an SMS
    verification code. Does not authenticate anyone by itself."""
    permission_classes = [permissions.AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'otp_request'

    def post(self, request):
        s = PhoneOTPRequestSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        try:
            phone = otp_service.normalize_phone_number(s.validated_data['phone_number'])
        except ValueError as exc:
            return Response({'detail': str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        try:
            otp_service.create_otp(phone)
        except otp_service.OtpCooldownActive as exc:
            return Response(
                {'detail': str(exc), 'retry_after_seconds': exc.retry_after_seconds},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
        except SmsDeliveryError:
            return Response(
                {'detail': 'Could not send the verification code. Please try again shortly.'},
                status=status.HTTP_502_BAD_GATEWAY,
            )
        return Response({
            'message': 'Verification code sent.',
            'resend_after_seconds': settings.OTP_RESEND_COOLDOWN_SECONDS,
        }, status=status.HTTP_200_OK)


class PhoneOTPVerifyView(APIView):
    """POST /auth/phone/verify-otp/ – verify the code and sign the user in,
    creating an account on first verification of a phone number."""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        s = PhoneOTPVerifySerializer(data=request.data)
        s.is_valid(raise_exception=True)
        try:
            phone = otp_service.normalize_phone_number(s.validated_data['phone_number'])
        except ValueError as exc:
            return Response({'detail': str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        try:
            otp_service.verify_otp(phone, s.validated_data['code'])
        except otp_service.OtpMaxAttemptsExceeded as exc:
            return Response({'detail': str(exc)}, status=status.HTTP_429_TOO_MANY_REQUESTS)
        except (otp_service.OtpNotFound, otp_service.OtpExpired, otp_service.OtpInvalid) as exc:
            return Response({'detail': str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        user, created = find_or_create_phone_user(phone)
        return _issue_tokens_response(user, status.HTTP_201_CREATED if created else status.HTTP_200_OK)


class LogoutView(APIView):
    """POST /auth/logout/ – blacklist the given refresh token.

    JWT access tokens can't be revoked (they're just verified signatures), so
    logout invalidates the *refresh* token server-side: once blacklisted it
    can never be exchanged for a new access token again, which is the JWT
    equivalent of Django's session-based `logout()` clearing session data.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        refresh = request.data.get('refresh')
        if not refresh:
            return Response({'refresh': 'This field is required.'},
                             status=status.HTTP_400_BAD_REQUEST)
        from rest_framework_simplejwt.exceptions import TokenError
        from rest_framework_simplejwt.tokens import RefreshToken
        try:
            RefreshToken(refresh).blacklist()
        except TokenError:
            # Already invalid/expired/blacklisted – logout is still a success
            # from the client's point of view (the credential is unusable).
            pass
        return Response(status=status.HTTP_205_RESET_CONTENT)


class IsOwnerOrReadOnly(permissions.BasePermission):
    """Allow owners to edit; everyone can read."""
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.user == request.user


class ProfileViewSet(viewsets.ModelViewSet):
    """ViewSet for the current user's profile."""
    serializer_class = ProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Profile.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=False, methods=['get'])
    def me(self, request):
        """GET /profiles/me – return the current user's profile."""
        profile, _ = Profile.objects.get_or_create(user=request.user)
        serializer = self.get_serializer(profile)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='discover')
    def discover(self, request):
        """GET /profiles/discover – Gym Bro candidates (GB-2).

        Excludes the requester, anyone already swiped on, and profiles that
        haven't finished the Gym Bro fields (see Profile.has_completed_gym_bro_profile).
        """
        user = request.user
        already_swiped_ids = Swipe.objects.filter(from_user=user).values_list('to_user_id', flat=True)
        candidates = (
            Profile.objects
            .exclude(user=user)
            .exclude(user_id__in=already_swiped_ids)
            .select_related('user')
            .order_by('-created_at')
        )
        completed = [p for p in candidates if p.has_completed_gym_bro_profile()][:50]
        serializer = self.get_serializer(completed, many=True)
        return Response(serializer.data)


class SwipeViewSet(mixins.CreateModelMixin, viewsets.GenericViewSet):
    """POST /swipes/ – record a like/pass and detect mutual matches (GB-3)."""
    serializer_class = SwipeSerializer
    permission_classes = [permissions.IsAuthenticated]
    queryset = Swipe.objects.none()

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        to_user = serializer.validated_data['to_user']
        direction = serializer.validated_data['direction']

        with transaction.atomic():
            swipe, _ = Swipe.objects.update_or_create(
                from_user=request.user,
                to_user=to_user,
                defaults={'direction': direction},
            )
            match = None
            if direction == Swipe.LIKE:
                mutual = Swipe.objects.filter(
                    from_user=to_user, to_user=request.user, direction=Swipe.LIKE,
                ).exists()
                if mutual:
                    low_id, high_id = Match.ordered_pair(request.user.id, to_user.id)
                    match, _ = Match.objects.get_or_create(
                        user_low_id=low_id, user_high_id=high_id,
                    )

        data = SwipeSerializer(swipe, context={'request': request}).data
        data['matched'] = match is not None
        data['match_id'] = str(match.id) if match else None
        return Response(data, status=status.HTTP_201_CREATED)


class MatchViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    """List/retrieve Gym Bro matches and their chat messages (GB-4)."""
    serializer_class = MatchSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return Match.objects.filter(Q(user_low=user) | Q(user_high=user))

    def get_object(self):
        # Deliberately look up against the *unfiltered* Match table so an
        # unauthorized user gets 403 (not part of the match) rather than 404
        # (which would leak whether the match id even exists).
        match = get_object_or_404(Match, pk=self.kwargs['pk'])
        if not match.has_participant(self.request.user):
            raise PermissionDenied('You are not part of this match.')
        return match

    @action(detail=True, methods=['get', 'post'], url_path='messages')
    def messages(self, request, pk=None):
        match = self.get_object()
        if request.method == 'GET':
            qs = match.messages.select_related('sender').all()
            return Response(GymBroMessageSerializer(qs, many=True).data)

        serializer = GymBroMessageSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        message = serializer.save(match=match, sender=request.user)
        return Response(
            GymBroMessageSerializer(message).data, status=status.HTTP_201_CREATED,
        )


class PlanViewSet(viewsets.ModelViewSet):
    """ViewSet for training plans."""
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrReadOnly]

    def get_serializer_class(self):
        if self.action == 'list':
            return PlanListSerializer
        return PlanSerializer

    def get_queryset(self):
        return Plan.objects.filter(user=self.request.user).prefetch_related('exercises')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['get', 'put'], url_path='week')
    def week(self, request, pk=None):
        plan = self.get_object()
        if request.method == 'GET':
            days = plan.days.prefetch_related(
                'assignments__exercise',
            )
            return Response({
                'plan': str(plan.id),
                'days': PlanDaySerializer(days, many=True).data,
            })

        raw_days = request.data.get('days')
        if not isinstance(raw_days, list):
            return Response(
                {'days': 'Expected a list of weekday assignments.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        weekdays = [item.get('weekday') for item in raw_days if isinstance(item, dict)]
        if len(raw_days) != 7 or sorted(weekdays) != list(range(7)):
            return Response(
                {'days': 'Exactly one assignment is required for each weekday 0 through 6.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        assignments = []
        for item in raw_days:
            exercise_ids = item.get('exercise_ids')
            if not isinstance(exercise_ids, list) or not all(
                isinstance(exercise_id, str) for exercise_id in exercise_ids
            ):
                return Response(
                    {'days': 'Each weekday must include an exercise_ids list.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            if len(exercise_ids) != len(set(exercise_ids)):
                return Response(
                    {'days': 'An exercise can only appear once per weekday.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            exercises = list(Exercise.objects.filter(
                id__in=exercise_ids,
            ).filter(
                models.Q(user=request.user) | models.Q(is_library=True, user__isnull=True),
            ))
            if len(exercises) != len(set(exercise_ids)):
                return Response(
                    {'days': 'Each exercise must belong to you or the exercise library.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            exercises_by_id = {str(exercise.id): exercise for exercise in exercises}
            assignments.append((item['weekday'], [
                exercises_by_id[exercise_id] for exercise_id in exercise_ids
            ]))

        with transaction.atomic():
            PlanDay.objects.filter(plan=plan).delete()
            for weekday, exercises in assignments:
                day = PlanDay.objects.create(plan=plan, weekday=weekday)
                PlanDayExercise.objects.bulk_create([
                    PlanDayExercise(plan_day=day, exercise=exercise, order=order)
                    for order, exercise in enumerate(exercises)
                ])
        days = plan.days.prefetch_related('assignments__exercise')
        return Response({
            'plan': str(plan.id),
            'days': PlanDaySerializer(days, many=True).data,
        })


class ExerciseViewSet(viewsets.ModelViewSet):
    """ViewSet for user exercises (per-user, plan-attached)."""
    serializer_class = ExerciseSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrReadOnly]

    def get_queryset(self):
        # return exercises belonging to the authenticated user
        qs = Exercise.objects.filter(user=self.request.user, is_library=False)
        plan_id = self.request.query_params.get('plan')
        if plan_id:
            qs = qs.filter(plan_id=plan_id)
        return qs.select_related('plan')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user, is_library=False)


class ExerciseLookupView(APIView):
    """GET /exercises/lookup/<uuid:pk>/ — look up any exercise the requesting
    user is allowed to see (their own, or a library exercise) regardless of
    which viewset originally created it.

    A workout plan's assigned exercises can be either per-user rows
    (ExerciseViewSet) or shared library rows (LibraryExerciseViewSet), and the
    workout runner doesn't know which at swap-time — this is the one place
    that looks up either kind by id so exercise substitution (surfacing
    `alternatives_detail`) works regardless of origin.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        exercise = get_object_or_404(
            Exercise.objects.filter(
                models.Q(user=request.user) | models.Q(is_library=True),
            ),
            pk=pk,
        )
        return Response(ExerciseSerializer(exercise, context={'request': request}).data)


class LibraryExerciseViewSet(viewsets.ModelViewSet):
    """ViewSet for global admin-managed exercise library.

    Read-only access is public (AllowAny) so the frontend can fetch the library without
    authentication. Write actions (create/update/destroy) require admin privileges and
    an authenticated user (token).
    """
    serializer_class = ExerciseSerializer
    permission_classes = [permissions.AllowAny]
    pagination_class = None

    def get_permissions(self):
        # Allow anyone to perform safe methods (list, retrieve).
        # Require admin for write operations.
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [permissions.IsAuthenticated(), permissions.IsAdminUser()]
        return [permissions.AllowAny()]

    def get_queryset(self):
        qs = Exercise.objects.filter(is_library=True)
        # support filters for body_part, difficulty, equipment, movement_pattern, exercise_type
        params = self.request.query_params
        body_part = params.get('body_part')
        difficulty = params.get('difficulty')
        equipment = params.get('equipment')
        movement_pattern = params.get('movement_pattern')
        exercise_type = params.get('exercise_type')
        search = params.get('search')
        if body_part:
            qs = qs.filter(body_part__iexact=body_part)
        if difficulty:
            qs = qs.filter(difficulty__iexact=difficulty)
        if movement_pattern:
            qs = qs.filter(movement_pattern__iexact=movement_pattern)
        if exercise_type:
            qs = qs.filter(exercise_type__iexact=exercise_type)
        if equipment:
            qs = qs.filter(equipment__contains=[equipment])
        if search:
            qs = qs.filter(name__icontains=search) | qs.filter(aliases__icontains=search)
        return qs.prefetch_related('alternatives', 'progression_exercises', 'regression_exercises')

    def perform_create(self, serializer):
        # ensure created library exercises are marked as library and not tied to a user
        serializer.save(user=None, is_library=True)


class WorkoutSessionViewSet(viewsets.ModelViewSet):
    """ViewSet for workout sessions."""
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrReadOnly]

    def get_serializer_class(self):
        if self.action == 'list':
            return WorkoutSessionListSerializer
        return WorkoutSessionSerializer

    def get_queryset(self):
        qs = WorkoutSession.objects.filter(user=self.request.user)
        plan_id = self.request.query_params.get('plan')
        if plan_id:
            qs = qs.filter(plan_id=plan_id)
        return qs.prefetch_related('metrics', 'metrics__exercise')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['post'], url_path='log-metric')
    def log_metric(self, request, pk=None):
        session = self.get_object()
        exercise_name = str(request.data.get('exercise_name', '')).strip()
        if not exercise_name:
            return Response({'exercise_name': 'This field is required.'},
                            status=status.HTTP_400_BAD_REQUEST)
        exercise, _ = Exercise.objects.get_or_create(
            user=request.user,
            name=exercise_name,
            plan=session.plan,
            defaults={'description': 'Logged from a completed workout.'},
        )
        payload = {
            'session': session.id,
            'exercise': exercise.id,
            'set_number': request.data.get('set_number', 1),
            'reps': request.data.get('reps', 0),
            'weight_kg': request.data.get('weight_kg'),
            'duration_seconds': request.data.get('duration_seconds'),
            'rpe': request.data.get('rpe'),
        }
        serializer = ProgressMetricSerializer(data=payload, context={'request': request})
        serializer.is_valid(raise_exception=True)
        # A PR is strictly heavier than the user's best-ever set for this exercise.
        best_weight = ProgressMetric.objects.filter(
            session__user=request.user,
            exercise=exercise,
            weight_kg__isnull=False,
        ).aggregate(max_weight=Max('weight_kg'))['max_weight']
        serializer.save()
        data = serializer.data
        data['is_new_personal_record'] = (
            payload['weight_kg'] is not None
            and (best_weight is None or float(payload['weight_kg']) > float(best_weight))
        )
        return Response(data, status=status.HTTP_201_CREATED)


class ProgressMetricViewSet(viewsets.ModelViewSet):
    """ViewSet for progress metrics."""
    serializer_class = ProgressMetricSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrReadOnly]

    def get_queryset(self):
        return ProgressMetric.objects.filter(
            session__user=self.request.user
        ).select_related('session', 'exercise')

    def perform_create(self, serializer):
        serializer.save()

    @action(detail=False, methods=['get'], url_path='last-for-exercise')
    def last_for_exercise(self, request):
        exercise_id = request.query_params.get('exercise')
        if not exercise_id:
            return Response(
                {'exercise': 'This query parameter is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            uuid.UUID(str(exercise_id))
        except ValueError:
            # Locally-generated sample plans use non-UUID exercise keys
            # (e.g. "goblet_squat") that never have a matching metric.
            return Response({'result': None}, status=status.HTTP_200_OK)
        metric = self.get_queryset().filter(
            exercise_id=exercise_id,
        ).order_by('-logged_at').first()
        if metric is None:
            return Response({'result': None}, status=status.HTTP_200_OK)
        return Response({
            'result': ProgressMetricSerializer(
                metric,
                context={'request': request},
            ).data,
        })

    @action(detail=False, methods=['get'], url_path='summary')
    def summary(self, request):
        """Return derived lifting insights for the authenticated user."""
        metrics = list(self.get_queryset().filter(weight_kg__isnull=False))
        volume = ProgressMetric.objects.filter(
            session__user=request.user,
            weight_kg__isnull=False,
        ).aggregate(total=Sum(F('weight_kg') * F('reps')))['total'] or 0
        best_by_exercise = {}
        volume_by_day = {}
        estimated_one_rep_max = 0
        for metric in metrics:
            weight = float(metric.weight_kg)
            best_by_exercise[metric.exercise_id] = max(
                best_by_exercise.get(metric.exercise_id, 0),
                weight,
            )
            estimated_one_rep_max = max(
                estimated_one_rep_max,
                weight * (1 + metric.reps / 30),
            )
            day = metric.logged_at.date().isoformat()
            volume_by_day[day] = volume_by_day.get(day, 0) + weight * metric.reps
        workout_count_by_week = list(
            WorkoutSession.objects.filter(user=request.user)
            .annotate(week=TruncWeek('started_at'))
            .values('week')
            .annotate(workout_count=models.Count('id'))
            .order_by('week')
        )
        rpe_values = list(
            self.get_queryset()
            .filter(rpe__isnull=False)
            .values_list('rpe', flat=True)
        )
        average_rpe = (
            round(float(sum(rpe_values)) / len(rpe_values), 1) if rpe_values else None
        )
        return Response({
            'total_volume_kg': float(volume),
            'estimated_one_rep_max_kg': round(estimated_one_rep_max, 2),
            'personal_records': len(best_by_exercise),
            'average_rpe': average_rpe,
            'volume_by_day': [
                {'date': day, 'volume_kg': round(value, 2)}
                for day, value in sorted(volume_by_day.items())
            ],
            'workout_count_by_week': [
                {
                    'week': item['week'].date().isoformat(),
                    'workout_count': item['workout_count'],
                }
                for item in workout_count_by_week
            ],
            'trend': 'up' if len(volume_by_day) > 1 and
            list(volume_by_day.values())[-1] >= list(volume_by_day.values())[0]
            else 'steady',
        })


class BodyWeightEntryViewSet(viewsets.ModelViewSet):
    serializer_class = BodyWeightEntrySerializer
    permission_classes = [permissions.IsAuthenticated]
    http_method_names = ['get', 'post', 'head', 'options']

    def get_queryset(self):
        return BodyWeightEntry.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class FavoriteExerciseViewSet(viewsets.ModelViewSet):
    serializer_class = FavoriteExerciseSerializer
    permission_classes = [permissions.IsAuthenticated]
    http_method_names = ['get', 'post', 'delete', 'head', 'options']

    def get_queryset(self):
        return FavoriteExercise.objects.filter(user=self.request.user).select_related('exercise')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class MeditationSessionViewSet(viewsets.ModelViewSet):
    """ViewSet for logged meditation/mindfulness sessions."""
    serializer_class = MeditationSessionSerializer
    permission_classes = [permissions.IsAuthenticated]
    http_method_names = ['get', 'post', 'head', 'options']

    def get_queryset(self):
        return MeditationSession.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=False, methods=['get'], url_path='summary')
    def summary(self, request):
        """Return total minutes, session count, and the current daily streak."""
        sessions = self.get_queryset()
        total_minutes = sessions.aggregate(total=Sum('duration_minutes'))['total'] or 0
        session_count = sessions.count()

        completed_days = sorted(
            {s.completed_at.date() for s in sessions.only('completed_at')},
            reverse=True,
        )
        streak = 0
        expected_day = timezone.localdate()
        for day in completed_days:
            if day != expected_day:
                break
            streak += 1
            expected_day -= timedelta(days=1)

        return Response({
            'total_minutes': total_minutes,
            'session_count': session_count,
            'streak_days': streak,
        })


class FeedbackViewSet(mixins.CreateModelMixin, viewsets.GenericViewSet):
    """'Help us improve' submissions. Write-only from the app — review and
    management happens exclusively in the Django admin panel."""
    serializer_class = FeedbackSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Feedback.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class ProgressPhotoViewSet(viewsets.ModelViewSet):
    """User-submitted progress photos. Strictly private: get_queryset scopes
    every action to the requesting user, so no other user (including a Gym
    Bro match) can ever list, retrieve, or delete someone else's photos."""
    serializer_class = ProgressPhotoSerializer
    permission_classes = [permissions.IsAuthenticated]
    http_method_names = ['get', 'post', 'delete', 'head', 'options']

    def get_queryset(self):
        return ProgressPhoto.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class SubscriptionViewSet(viewsets.ModelViewSet):
    """Expose only the authenticated user's subscription.

    There is no payment gateway wired up yet, so `plan_name`/`status` are
    read-only over the API (see SubscriptionSerializer) — they can only be
    changed by real billing logic (a future Stripe webhook handler) or by
    staff in the admin. The only client-triggerable action today is
    `join_waitlist`, which records intent, not a purchase.
    """
    serializer_class = SubscriptionSerializer
    permission_classes = [permissions.IsAuthenticated]
    http_method_names = ['get', 'post', 'head', 'options']

    def get_queryset(self):
        return Subscription.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=False, methods=['get'], url_path='subscription')
    def current(self, request):
        subscription, _ = Subscription.objects.get_or_create(user=request.user)
        return Response(self.get_serializer(subscription).data)

    @action(detail=False, methods=['post'], url_path='subscription/waitlist')
    def join_waitlist(self, request):
        subscription, _ = Subscription.objects.get_or_create(user=request.user)
        if subscription.plan_name == 'free':
            subscription.status = 'waitlisted'
            subscription.save(update_fields=['status', 'updated_at'])
        return Response(self.get_serializer(subscription).data)


def _get_or_create_ai_folder(user):
    folder, _ = AIConversationFolder.objects.get_or_create(user=user)
    return folder


class AIFolderView(APIView):
    """GET /ai/folder/ — get-or-create the caller's single 'AI Discussions'
    folder. Safe to call repeatedly; never creates more than one per user
    (enforced by the OneToOneField)."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        folder = _get_or_create_ai_folder(request.user)
        return Response(AIConversationFolderSerializer(folder).data)


class AIConversationViewSet(viewsets.ModelViewSet):
    """CRUD for the caller's own AI conversations. get_queryset scopes every
    action to the requesting user's folder, so no other user can ever list,
    retrieve, rename, or delete someone else's conversation (see
    test_ai_conversation_ownership in tests.py)."""
    serializer_class = AIConversationSerializer
    permission_classes = [permissions.IsAuthenticated]
    http_method_names = ['get', 'post', 'patch', 'delete', 'head', 'options']

    def get_queryset(self):
        return AIConversation.objects.filter(folder__user=self.request.user)

    def perform_create(self, serializer):
        folder = _get_or_create_ai_folder(self.request.user)
        serializer.save(folder=folder, model=get_ai_service().model)


class AIMessagePagination(PageNumberPagination):
    page_size = 50
    max_page_size = 100


class AIMessageListView(generics.ListAPIView):
    """GET /ai/conversations/<uuid:pk>/messages/ — the persisted messages
    for one conversation, oldest first. 404s (not 403s) on a conversation
    the caller doesn't own, so ownership never leaks via response code."""
    serializer_class = AIMessageSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = AIMessagePagination

    def get_queryset(self):
        conversation = get_object_or_404(
            AIConversation, pk=self.kwargs['pk'], folder__user=self.request.user
        )
        return conversation.messages.all()


class AISendMessageStreamView(APIView):
    """POST /ai/conversations/<uuid:pk>/stream/ — persist the user's message,
    then stream the assistant's reply back as Server-Sent Events while
    accumulating and persisting it.

    The client can only ever supply free-text `content` (AISendMessageSerializer);
    role and the system prompt are entirely backend-controlled (ai/context.py).
    """
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'ai_chat'

    @staticmethod
    def _sse(event, data):
        return f'event: {event}\ndata: {json.dumps(data)}\n\n'

    def post(self, request, pk):
        conversation = get_object_or_404(
            AIConversation, pk=pk, folder__user=request.user
        )

        serializer = AISendMessageSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        content = serializer.validated_data['content']

        try:
            ai_limits.check_can_send_message(request.user, content)
        except ai_limits.MessageTooLong as exc:
            return Response({'detail': str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        except ai_limits.DailyLimitExceeded as exc:
            return Response({'detail': str(exc)}, status=status.HTTP_429_TOO_MANY_REQUESTS)

        is_first_message = not conversation.messages.exists()
        user_message = AIMessage.objects.create(
            conversation=conversation,
            role=AIMessage.ROLE_USER,
            content=content,
            status=AIMessage.STATUS_COMPLETED,
        )
        conversation.last_message_at = user_message.created_at
        update_fields = ['last_message_at']
        if is_first_message:
            conversation.title = title_from_message(content)
            update_fields.append('title')
        conversation.save(update_fields=update_fields)

        upstream_messages = ai_build_messages(conversation)
        service = get_ai_service()
        assistant_message = AIMessage.objects.create(
            conversation=conversation,
            role=AIMessage.ROLE_ASSISTANT,
            content='',
            status=AIMessage.STATUS_PENDING,
            model=service.model,
        )

        def event_stream():
            accumulated = ''
            finish_reason = None
            usage = None
            try:
                for chunk in service.stream_chat_completion(upstream_messages):
                    if chunk.delta_text:
                        accumulated += chunk.delta_text
                        yield self._sse('delta', {'text': chunk.delta_text})
                    if chunk.finish_reason:
                        finish_reason = chunk.finish_reason
                    if chunk.usage:
                        usage = chunk.usage
            except AI_SERVICE_ERRORS as exc:
                assistant_message.status = AIMessage.STATUS_FAILED
                assistant_message.content = accumulated
                assistant_message.save(update_fields=['status', 'content'])
                yield self._sse('error', {'detail': 'The assistant is temporarily unavailable. Please try again.'})
                return

            assistant_message.status = AIMessage.STATUS_COMPLETED
            assistant_message.content = accumulated
            assistant_message.finish_reason = finish_reason or ''
            if usage:
                assistant_message.input_tokens = usage.get('prompt_tokens')
                assistant_message.output_tokens = usage.get('completion_tokens')
            assistant_message.save(update_fields=[
                'status', 'content', 'finish_reason', 'input_tokens', 'output_tokens',
            ])
            conversation.last_message_at = timezone.now()
            conversation.save(update_fields=['last_message_at'])
            yield self._sse('done', {'message_id': str(assistant_message.id)})

        response = StreamingHttpResponse(event_stream(), content_type='text/event-stream')
        response['Cache-Control'] = 'no-cache'
        response['X-Accel-Buffering'] = 'no'
        return response


def get_ai_service():
    """Indirection point so tests can monkeypatch/replace the service with
    a fake without touching AISendMessageStreamView itself. Picks the
    provider from settings.AI_PROVIDER (see gym_project/settings.py)."""
    if settings.AI_PROVIDER == 'freellmapi':
        return FreellmapiService()
    return OpenRouterService()
