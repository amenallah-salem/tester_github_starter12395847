"""
SMS delivery abstraction for phone/OTP sign-in.

Production sends via Twilio's plain HTTPS REST API (no SDK needed — it's
just HTTP Basic Auth + a POST, and `requests` is already a dependency).
Development can simulate delivery instead — see get_sms_provider().
"""
import logging

import requests
from django.conf import settings

logger = logging.getLogger(__name__)


class SmsDeliveryError(Exception):
    """Raised when an SMS could not be sent. Never carries provider
    credentials or the message body — only a safe-to-log summary."""


class SmsProvider:
    def send(self, phone_number: str, message: str) -> None:
        raise NotImplementedError


class TwilioSmsProvider(SmsProvider):
    """Sends via Twilio's Messages REST API. Never logs the message body
    (which contains the OTP code) or the account credentials."""

    API_URL = 'https://api.twilio.com/2010-04-01/Accounts/{sid}/Messages.json'

    def send(self, phone_number: str, message: str) -> None:
        if not (settings.TWILIO_ACCOUNT_SID and settings.TWILIO_AUTH_TOKEN and settings.TWILIO_FROM_NUMBER):
            raise SmsDeliveryError('SMS provider is not configured.')
        response = requests.post(
            self.API_URL.format(sid=settings.TWILIO_ACCOUNT_SID),
            auth=(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN),
            data={
                'From': settings.TWILIO_FROM_NUMBER,
                'To': phone_number,
                'Body': message,
            },
            timeout=10,
        )
        if response.status_code >= 300:
            logger.error('SMS delivery failed for %s (status %s)', _mask(phone_number), response.status_code)
            raise SmsDeliveryError('SMS provider rejected the message.')


class DevSmsProvider(SmsProvider):
    """Never sends a real SMS. Used only when SAFE_DEV_OTP_AUTH_PASS and
    DEBUG are both set — see get_sms_provider()."""

    def send(self, phone_number: str, message: str) -> None:
        logger.info('[DEV OTP] SMS delivery simulated for %s', _mask(phone_number))


def _mask(phone_number: str) -> str:
    """+34612345678 -> +346*******78 — enough to eyeball in logs, not enough
    to identify the full number."""
    if len(phone_number) <= 6:
        return '*' * len(phone_number)
    return phone_number[:4] + '*' * (len(phone_number) - 6) + phone_number[-2:]


def get_sms_provider() -> SmsProvider:
    """DevSmsProvider only if BOTH DEBUG and SAFE_DEV_OTP_AUTH_PASS are set —
    defense in depth beyond the production startup guard (env_guards.py),
    which already refuses to boot with SAFE_DEV_OTP_AUTH_PASS in production."""
    if settings.DEBUG and settings.SAFE_DEV_OTP_AUTH_PASS:
        return DevSmsProvider()
    return TwilioSmsProvider()
