from pathlib import Path
import os
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.getenv('DJANGO_SECRET_KEY', 'dev-secret-key-change-in-production')
DEBUG = os.getenv('DJANGO_DEBUG', 'True').lower() in ('1', 'true', 'yes')
ALLOWED_HOSTS = [host.strip() for host in os.getenv(
    'DJANGO_ALLOWED_HOSTS', 'localhost,127.0.0.1,0.0.0.0'
).split(',') if host.strip()]

# Stripe Payment Link for the Premium waitlist/pre-order flow. No gateway
# integration exists yet — this is just a hosted checkout URL the app opens
# in a browser. Set in .env.dev / .env.prod; see SubscriptionSerializer.
STRIPE_PAYMENT_LINK_URL = os.getenv('STRIPE_PAYMENT_LINK_URL', '')

# Social sign-in (Google / Apple). GOOGLE_OAUTH_CLIENT_IDS is comma-separated
# because Google issues a distinct OAuth client id per platform (Android,
# iOS, Web) and an id_token's `aud` claim will be whichever one issued it —
# the backend must accept any of them. APPLE_BUNDLE_ID is the audience
# expected in Apple identity tokens (native iOS Sign in with Apple only).
GOOGLE_OAUTH_CLIENT_IDS = [
    cid.strip() for cid in os.getenv('GOOGLE_OAUTH_CLIENT_IDS', '').split(',') if cid.strip()
]
APPLE_BUNDLE_ID = os.getenv('APPLE_BUNDLE_ID', '')

# Phone/OTP sign-in (Twilio SMS). TWILIO_* are empty by default so the app
# still runs without them configured (phone auth just can't send real SMS).
TWILIO_ACCOUNT_SID = os.getenv('TWILIO_ACCOUNT_SID', '')
TWILIO_AUTH_TOKEN = os.getenv('TWILIO_AUTH_TOKEN', '')
TWILIO_FROM_NUMBER = os.getenv('TWILIO_FROM_NUMBER', '')

OTP_EXPIRY_MINUTES = 5
OTP_MAX_ATTEMPTS = 5
OTP_RESEND_COOLDOWN_SECONDS = 60
DEV_OTP_CODE = '123456'

# DEVELOPMENT / TESTING ONLY — NEVER CONFIGURE THIS IN PRODUCTION.
# When set (and DEBUG is True), phone OTP requests use a fixed, documented
# code (DEV_OTP_CODE) and simulate SMS delivery instead of calling Twilio —
# see gym_api/sms.py:get_sms_provider(). Verification itself is unchanged;
# see check_production_safety() below for the production refusal.
SAFE_DEV_OTP_AUTH_PASS = os.getenv('SAFE_DEV_OTP_AUTH_PASS', '')

# AI chat (OpenRouter). Server-side only — never exposed to the client.
# Defaults to the free-tier model; do not silently fall back to a paid one.
OPENROUTER_API_KEY = os.getenv('OPENROUTER_API_KEY', '')
OPENROUTER_BASE_URL = os.getenv('OPENROUTER_BASE_URL', 'https://openrouter.ai/api/v1')
OPENROUTER_MODEL = os.getenv('OPENROUTER_MODEL', 'openrouter/free')

# Usage guardrails for the AI chat feature (see gym_api/ai/limits.py).
AI_CHAT_MAX_MESSAGE_LENGTH = 4000
AI_CHAT_DAILY_MESSAGE_LIMIT = 100
AI_CHAT_CONTEXT_MESSAGE_COUNT = 20

INSTALLED_APPS = [
    # Must be listed before django.contrib.admin so it can override the
    # built-in admin templates/static assets.
    'unfold',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Third-party
    'rest_framework',
    'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',
    'drf_spectacular',
    # Project apps
    'gym_api',
]

# Admin theme (django-unfold). Kept minimal/functional rather than
# heavily branded — see backend/gym_api/admin.py for the actual
# ModelAdmin configuration this skins.
UNFOLD = {
    'SITE_TITLE': 'WELLAURA Admin',
    'SITE_HEADER': 'WELLAURA',
    'SITE_SYMBOL': 'fitness_center',
    'SHOW_HISTORY': True,
    'SHOW_VIEW_ON_SITE': True,
    'SIDEBAR': {
        'show_search': True,
        'navigation': [
            {
                'title': 'Content',
                'items': [
                    {
                        'title': 'Exercise library',
                        'icon': 'exercise',
                        'link': '/admin/gym_api/exercise/',
                    },
                    {
                        'title': 'Plans',
                        'icon': 'calendar_month',
                        'link': '/admin/gym_api/plan/',
                    },
                ],
            },
            {
                'title': 'People',
                'items': [
                    {
                        'title': 'Users',
                        'icon': 'person',
                        'link': '/admin/auth/user/',
                    },
                    {
                        'title': 'Profiles',
                        'icon': 'badge',
                        'link': '/admin/gym_api/profile/',
                    },
                ],
            },
            {
                'title': 'Activity',
                'items': [
                    {
                        'title': 'Workout sessions',
                        'icon': 'exercise',
                        'link': '/admin/gym_api/workoutsession/',
                    },
                    {
                        'title': 'Progress metrics',
                        'icon': 'monitoring',
                        'link': '/admin/gym_api/progressmetric/',
                    },
                    {
                        'title': 'Body weight log',
                        'icon': 'monitor_weight',
                        'link': '/admin/gym_api/bodyweightentry/',
                    },
                    {
                        'title': 'Progress photos',
                        'icon': 'photo_camera',
                        'link': '/admin/gym_api/progressphoto/',
                    },
                    {
                        'title': 'Meditation sessions',
                        'icon': 'self_improvement',
                        'link': '/admin/gym_api/meditationsession/',
                    },
                ],
            },
            {
                'title': 'Support',
                'items': [
                    {
                        'title': 'Feedback',
                        'icon': 'feedback',
                        'link': '/admin/gym_api/feedback/',
                    },
                    {
                        'title': 'Subscriptions',
                        'icon': 'workspace_premium',
                        'link': '/admin/gym_api/subscription/',
                    },
                ],
            },
        ],
    },
}

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

ROOT_URLCONF = 'gym_project.urls'
WSGI_APPLICATION = 'gym_project.wsgi.application'

# Support both naming conventions: DB_HOST (local) and POSTGRES_HOST (root compose)
DB_HOST = os.getenv('DB_HOST') or os.getenv('POSTGRES_HOST') or 'localhost'

if os.getenv('DB_ENGINE') == 'sqlite' or os.getenv('DJANGO_TESTING') == '1':
    DATABASES = {'default': {'ENGINE': 'django.db.backends.sqlite3',
                             'NAME': BASE_DIR / 'db.sqlite3'}}
else:
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': os.getenv('POSTGRES_DB', 'gym_db'),
            'USER': os.getenv('POSTGRES_USER', 'postgres'),
            'PASSWORD': os.getenv('POSTGRES_PASSWORD', 'postgres'),
            'HOST': DB_HOST,
            'PORT': os.getenv('DB_PORT') or os.getenv('POSTGRES_PORT') or '5432',
            'CONN_MAX_AGE': int(os.getenv('DB_CONN_MAX_AGE', '60')),
        }
    }

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

# Media (user/uploaded/generated) files
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

REST_FRAMEWORK = {
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 10,
    'DEFAULT_THROTTLE_CLASSES': (
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle',
    ),
    'DEFAULT_THROTTLE_RATES': {
        # Anonymous requests hit only register/login/refresh — keep this
        # tight to blunt credential-stuffing/brute force on launch day.
        'anon': '20/min',
        'user': '300/min',
        # Per-IP cap on SMS-sending requests, independent of the per-phone-
        # number cooldown enforced in gym_api/otp.py — see PhoneOTPRequestView.
        'otp_request': '5/min',
        # Per-user cap on AI chat sends, independent of the daily message
        # cap enforced in gym_api/ai/limits.py — see AISendMessageStreamView.
        'ai_chat': '20/min',
    },
}

SPECTACULAR_SETTINGS = {
    'TITLE': 'Gym Planner API',
    'DESCRIPTION': 'API for gym plans, exercises, workouts, and progress tracking.',
    'VERSION': '1.0.0',
    'SERVE_INCLUDE_SCHEMA': False,
    'SECURITY': [{'BearerAuth': []}],
    'COMPONENTS': {
        'securitySchemes': {
            'BearerAuth': {
                'type': 'http',
                'scheme': 'bearer',
                'bearerFormat': 'JWT',
            },
        },
    },
}

# JWT settings (rest_framework_simplejwt)
from datetime import timedelta
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    # Long-lived so a persistent login survives browser/app restarts; rotation
    # + blacklisting below keeps re-use of an old refresh token from working.
    'REFRESH_TOKEN_LIFETIME': timedelta(days=30),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'VERIFYING_KEY': None,
    'AUTH_HEADER_TYPES': ('Bearer',),
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
}

# Fail loudly rather than silently serving debug pages / a known secret key
# (or a development-only auth bypass) in anything that isn't explicitly a
# local dev run. See env_guards.py for the actual checks (kept separately
# importable so they're unit-testable against arbitrary env combinations).
from .env_guards import check_production_safety
check_production_safety(os.environ, DEBUG, SECRET_KEY)

# Security defaults are enabled in production and remain opt-in for local HTTP.
if not DEBUG:
    SECURE_SSL_REDIRECT = os.getenv('DJANGO_SECURE_SSL_REDIRECT', '1') == '1'
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_HSTS_SECONDS = int(os.getenv('DJANGO_HSTS_SECONDS', '31536000'))
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
