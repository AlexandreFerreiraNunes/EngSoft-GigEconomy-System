from rest_framework import serializers

from common.constants import EXPENSE_CATEGORIES, INCOME_CATEGORIES
from .models import Transaction


class TransactionCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = ["id", "type", "category", "amount", "note", "created_at"]
        read_only_fields = ["id", "created_at"]

    def validate(self, attrs):
        tx_type = attrs.get("type")
        category = attrs.get("category")
        if tx_type == "income" and category not in INCOME_CATEGORIES:
            raise serializers.ValidationError({"category": "Invalid category for income"})
        if tx_type == "expense" and category not in EXPENSE_CATEGORIES:
            raise serializers.ValidationError({"category": "Invalid category for expense"})
        return attrs

    def create(self, validated_data):
        user = self.context["request"].user
        return Transaction.objects.create(user=user, **validated_data)


class TransactionUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = ["id", "category", "amount", "note", "created_at", "type"]
        read_only_fields = ["id", "created_at", "type"]

    def validate_category(self, value: str) -> str:
        tx: Transaction = self.instance
        if tx.type == "income" and value not in INCOME_CATEGORIES:
            raise serializers.ValidationError("Invalid category for income")
        if tx.type == "expense" and value not in EXPENSE_CATEGORIES:
            raise serializers.ValidationError("Invalid category for expense")
        return value


class TransactionListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = ["id", "type", "category", "amount", "note", "created_at"]
