# Generated migration: add onboarding and locale fields to Profile
from django.db import migrations, models

class Migration(migrations.Migration):

    dependencies = [
        ('gym_api', '0002_exercise_image'),
    ]

    operations = [
        migrations.AddField(
            model_name='profile',
            name='onboarding_completed',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='profile',
            name='onboarding_completed_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='profile',
            name='locale',
            field=models.CharField(blank=True, max_length=20),
        ),
        migrations.AddField(
            model_name='profile',
            name='country',
            field=models.CharField(blank=True, max_length=4),
        ),
    ]
