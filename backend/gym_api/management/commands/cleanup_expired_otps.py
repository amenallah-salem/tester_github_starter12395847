from django.core.management.base import BaseCommand
from django.utils import timezone

from gym_api.models import OTPVerification

# Rows are kept briefly after they stop being usable (expired or used) in
# case of abuse investigation, then deleted. No scheduler exists in this
# project (no Celery/cron) — run this via host cron, e.g. daily:
#   docker compose --env-file .env.dev -f docker-compose.backend.dev.yml \
#     exec backend python manage.py cleanup_expired_otps
RETENTION = timezone.timedelta(hours=24)


class Command(BaseCommand):
    help = 'Delete expired/used phone OTP verification records older than 24h.'

    def handle(self, *args, **options):
        cutoff = timezone.now() - RETENTION
        deleted, _ = OTPVerification.objects.filter(
            created_at__lt=cutoff,
        ).exclude(
            used=False, expires_at__gte=timezone.now(),
        ).delete()
        self.stdout.write(self.style.SUCCESS(f'Deleted {deleted} expired/used OTP record(s).'))
