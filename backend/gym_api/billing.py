# billing.py — subscription / Stripe stub for gym_api
# Billing / subscription stub — integrate Stripe/PayPal for real monetization
from rest_framework import serializers, viewsets
class SubscriptionSerializer(serializers.ModelSerializer):
    class Meta: model = __import__('gym_project.settings').models.Subscription if False else None; fields = '__all__'
class SubscriptionViewSet(viewsets.ModelViewSet):
    serializer_class = SubscriptionSerializer
    queryset = []  # hook up user subscription model when ready
