"""
Gym project URL configuration.
"""
from django.contrib import admin
from django.urls import path, include, re_path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
from django.conf import settings
from django.conf.urls.static import static
from django.views.static import serve as serve_static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/', include('gym_api.urls')),
]

if settings.DEBUG:
    # `runserver` already serves STATIC_URL itself via django.contrib.staticfiles
    # when DEBUG is on, so only MEDIA needs the helper here.
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
else:
    # There's no whitenoise/CDN/S3 in this stack — gunicorn is the only thing
    # that can serve collected static assets (admin/Unfold CSS+JS) and
    # uploaded media (exercise images/videos) in production, so serve both
    # explicitly here. nginx (frontend/nginx.conf) blind-proxies /static/ and
    # /media/ to this backend the same way it already does for /api/. This is
    # fine at this project's scale; move to a CDN/object storage if upload
    # volume or traffic ever makes gunicorn-served media a bottleneck.
    urlpatterns += [
        re_path(r'^static/(?P<path>.*)$', serve_static, {'document_root': settings.STATIC_ROOT}),
        re_path(r'^media/(?P<path>.*)$', serve_static, {'document_root': settings.MEDIA_ROOT}),
    ]
