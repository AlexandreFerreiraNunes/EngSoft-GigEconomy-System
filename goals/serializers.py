from django.db import transaction
from rest_framework import serializers

from .models import Goal


class GoalSerializer(serializers.ModelSerializer):
    class Meta:
        model = Goal
        fields = ["id", "amount", "created_at", "is_active"]
        read_only_fields = ["id", "created_at", "is_active"]


class GoalCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Goal
        fields = ["id", "amount", "created_at", "is_active"]
        read_only_fields = ["id", "created_at", "is_active"]

    def create(self, validated_data):
        user = self.context["request"].user
        with transaction.atomic():
            Goal.objects.filter(user=user, is_active=True).update(is_active=False)
            goal = Goal.objects.create(user=user, is_active=True, **validated_data)
        return goal
