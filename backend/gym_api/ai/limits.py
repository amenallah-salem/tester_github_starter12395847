"""
Simple, extensible usage guardrails for the AI chat feature.

There is no subscription/entitlement gating elsewhere in the project for
per-feature limits (Subscription only tracks plan_name/status), so this
implements a plain per-user daily message cap rather than inventing a
subscription tier system. Kept as a single call site
(check_can_send_message) so a real entitlement system can replace the body
later without touching callers.
"""
from django.conf import settings
from django.utils import timezone


class MessageTooLong(Exception):
    pass


class DailyLimitExceeded(Exception):
    pass


def check_message_length(content):
    if len(content) > settings.AI_CHAT_MAX_MESSAGE_LENGTH:
        raise MessageTooLong(
            f'Message exceeds the {settings.AI_CHAT_MAX_MESSAGE_LENGTH} character limit.'
        )


def check_daily_limit(user):
    from .. import models  # local import avoids a circular import at module load

    since = timezone.now() - timezone.timedelta(days=1)
    sent_today = models.AIMessage.objects.filter(
        conversation__folder__user=user,
        role=models.AIMessage.ROLE_USER,
        created_at__gte=since,
    ).count()
    if sent_today >= settings.AI_CHAT_DAILY_MESSAGE_LIMIT:
        raise DailyLimitExceeded(
            f'Daily limit of {settings.AI_CHAT_DAILY_MESSAGE_LIMIT} AI messages reached.'
        )


def check_can_send_message(user, content):
    check_message_length(content)
    check_daily_limit(user)
