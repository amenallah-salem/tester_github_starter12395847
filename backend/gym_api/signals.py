"""
Signals for gym_api: generate or update exercise images when exercises are created.
"""
from io import BytesIO
from pathlib import Path
from django.conf import settings
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.core.files.base import ContentFile
from PIL import Image, ImageDraw, ImageFont

from .models import Exercise


def _find_base_image():
    # Prefer asserts/example.png if present; fall back to any image in asserts; otherwise None
    repo_root = Path(settings.BASE_DIR)
    asserts_dir = repo_root / 'asserts'
    if asserts_dir.exists():
        example = asserts_dir / 'example.png'
        if example.exists():
            return example
        # find first image file
        for p in asserts_dir.iterdir():
            if p.suffix.lower() in ['.png', '.jpg', '.jpeg', '.webp', '.gif']:
                return p
    return None


def _generate_image_for_exercise(name: str, size=(800, 600)) -> bytes:
    """Return PNG bytes for an exercise illustration with overlayed name."""
    base = _find_base_image()
    if base:
        with Image.open(base).convert('RGBA') as im:
            im = im.resize(size)
            canvas = Image.new('RGBA', size)
            canvas.paste(im, (0, 0))
    else:
        # Create simple background
        canvas = Image.new('RGBA', size, (30, 30, 30, 255))
    draw = ImageDraw.Draw(canvas)
    # Try to load a truetype font; fall back to default
    try:
        font_path = str(Path(settings.BASE_DIR) / 'frontend' / 'assets' / 'fonts' / 'Inter-Regular.ttf')
        font = ImageFont.truetype(font_path, 40)
    except Exception:
        font = ImageFont.load_default()
    # Draw a semi-transparent rectangle for better text contrast
    rect_h = 80
    draw.rectangle([(0, size[1] - rect_h), (size[0], size[1])], fill=(0, 0, 0, 180))
    text = name
    w, h = draw.textsize(text, font=font)
    x = 20
    y = size[1] - rect_h + (rect_h - h) // 2
    draw.text((x, y), text, font=font, fill=(255, 255, 255, 255))
    # Save to bytes
    out = BytesIO()
    canvas.convert('RGB').save(out, format='PNG')
    return out.getvalue()


@receiver(post_save, sender=Exercise)
def ensure_exercise_image(sender, instance: Exercise, created, **kwargs):
    # If exercise has no image, generate one and attach it
    if instance.image:
        return
    try:
        img_bytes = _generate_image_for_exercise(instance.name)
        filename = f"{instance.id}.png"
        instance.image.save(filename, ContentFile(img_bytes), save=False)
        # Save only the image field to avoid changing other timestamps
        instance.save(update_fields=['image'])
    except Exception:
        # In production, log exception. Avoid raising to not break upstream flows.
        pass
