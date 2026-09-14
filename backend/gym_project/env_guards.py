"""
Startup safety checks for production configuration.

Factored out of settings.py so these checks can be unit-tested directly
against arbitrary env combinations, since module-level settings code itself
can't be re-imported with different inputs inside a single test run.
"""


def check_production_safety(env, debug, secret_key):
    """Raise RuntimeError if `env` (a mapping, e.g. os.environ) describes an
    unsafe production configuration. Called from settings.py at import time.

    Fails loudly rather than silently serving debug pages, a known default
    secret key, or a development-only auth bypass in anything explicitly
    marked as production.
    """
    if env.get('DJANGO_ENV', '').lower() != 'production':
        return

    if debug:
        raise RuntimeError(
            'DJANGO_ENV=production but DJANGO_DEBUG is not False — refusing to start.'
        )
    if secret_key == 'dev-secret-key-change-in-production':
        raise RuntimeError(
            'DJANGO_ENV=production but DJANGO_SECRET_KEY is unset/default — refusing to start.'
        )
    if env.get('SAFE_DEV_OTP_AUTH_PASS', ''):
        raise RuntimeError(
            'SAFE_DEV_OTP_AUTH_PASS cannot be configured in production. '
            'Remove this development-only variable before starting the production environment.'
        )
