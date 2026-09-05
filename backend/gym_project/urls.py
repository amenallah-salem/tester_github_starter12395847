"""
Gym project URL configuration.
"""
from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/', include('gym_api.urls')),
]

# Serve media files in development
from django.conf import settings as _settings
from django.conf.urls.static import static as _static
if _settings.DEBUG:
    urlpatterns += _static(_settings.MEDIA_URL, document_root=_settings.MEDIA_ROOT)
