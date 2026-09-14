"""
Phone/OTP core logic: normalization, generation, hashing, and verification.

Kept separate from views.py since this is the security-sensitive part of
phone auth and benefits from being small and easy to review/test in
isolation. Hashing reuses Django's own password hasher (PBKDF2) rather than
adding a new dependency; generation uses `secrets` (CSPRNG) in production.

Verification is a single code path for both development and production —
the only place they differ is which code get_sms_provider()/generate_otp_code()
produce and whether a real SMS is sent. There is no separate "dev
verification" branch, by design.
"""
import secrets

import phonenumbers
from django.conf import settings
from django.contrib.auth.hashers import check_password, make_password
from django.utils import timezone

from .models import OTPVerification
from .sms import DevSmsProvider, SmsDeliveryError, get_sms_provider


class OtpCooldownActive(Exception):
    def __init__(self, retry_after_seconds: int):
        self.retry_after_seconds = retry_after_seconds
        super().__init__(f'Please wait {retry_after_seconds}s before requesting another code.')


class OtpNotFound(Exception):
    pass


class OtpExpired(Exception):
    pass


class OtpInvalid(Exception):
    pass


class OtpMaxAttemptsExceeded(Exception):
    pass


def normalize_phone_number(raw: str) -> str:
    """Parse/validate/normalize to E.164. Raises ValueError on anything
    invalid or unparseable. This is the backend-authoritative check — the
    frontend's phone field is a UX convenience, not the source of truth."""
    try:
        parsed = phonenumbers.parse(raw, None)
    except phonenumbers.NumberParseException as exc:
        raise ValueError('Enter a valid phone number, including country code.') from exc
    if not phonenumbers.is_valid_number(parsed):
        raise ValueError('Enter a valid phone number, including country code.')
    return phonenumbers.format_number(parsed, phonenumbers.PhoneNumberFormat.E164)


def generate_otp_code() -> str:
    if isinstance(get_sms_provider(), DevSmsProvider):
        return settings.DEV_OTP_CODE
    return f'{secrets.randbelow(1_000_000):06d}'


def create_otp(phone_number: str) -> OTPVerification:
    """Enforces the per-phone-number resend cooldown, then creates and
    "sends" a new OTP. Raises OtpCooldownActive if too soon, or
    SmsDeliveryError if sending fails (the OTP row is not created in that
    case, so a real resend attempt is possible without waiting)."""
    cooldown_cutoff = timezone.now() - timezone.timedelta(seconds=settings.OTP_RESEND_COOLDOWN_SECONDS)
    recent = (
        OTPVerification.objects.filter(phone_number=phone_number, used=False)
        .order_by('-created_at')
        .first()
    )
    if recent is not None and recent.created_at > cooldown_cutoff:
        retry_after = int((recent.created_at - cooldown_cutoff).total_seconds())
        raise OtpCooldownActive(retry_after_seconds=max(retry_after, 1))

    code = generate_otp_code()
    otp = OTPVerification.objects.create(
        phone_number=phone_number,
        otp_hash=make_password(code),
        expires_at=timezone.now() + timezone.timedelta(minutes=settings.OTP_EXPIRY_MINUTES),
    )
    try:
        get_sms_provider().send(phone_number, f'Your WELLAURA verification code is {code}.')
    except SmsDeliveryError:
        otp.delete()
        raise
    return otp


def verify_otp(phone_number: str, code: str) -> None:
    """Raises OtpNotFound / OtpExpired / OtpMaxAttemptsExceeded / OtpInvalid
    on failure. Returns None (no exception) on success, after marking the
    OTP used so it can never be checked again."""
    otp = (
        OTPVerification.objects.filter(phone_number=phone_number, used=False)
        .order_by('-created_at')
        .first()
    )
    if otp is None:
        raise OtpNotFound('No pending verification code for this phone number. Request a new one.')
    if otp.attempts >= settings.OTP_MAX_ATTEMPTS:
        otp.used = True
        otp.save(update_fields=['used'])
        raise OtpMaxAttemptsExceeded('Too many incorrect attempts. Request a new code.')
    if otp.expires_at < timezone.now():
        raise OtpExpired('This code has expired. Request a new one.')

    if not check_password(code, otp.otp_hash):
        otp.attempts += 1
        if otp.attempts >= settings.OTP_MAX_ATTEMPTS:
            otp.used = True
            otp.save(update_fields=['attempts', 'used'])
            raise OtpMaxAttemptsExceeded('Too many incorrect attempts. Request a new code.')
        otp.save(update_fields=['attempts'])
        raise OtpInvalid('Incorrect code.')

    otp.used = True
    otp.save(update_fields=['used'])
