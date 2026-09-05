"""Management command to generate images for exercises that lack one."""
from django.core.management.base import BaseCommand
from gym_api.models import Exercise


class Command(BaseCommand):
    help = 'Generate images for exercises that do not have an image.'

    def handle(self, *args, **options):
        count = 0
        for ex in Exercise.objects.filter(image__isnull=True):
            # Trigger save to cause post_save signal to generate image
            ex.save()
            count += 1
            self.stdout.write(self.style.SUCCESS(f'Generated image for {ex.id}'))
        self.stdout.write(self.style.SUCCESS(f'Done: {count} generated'))
