from rest_framework import serializers

from transactions.serializers import TransactionListSerializer


class DashboardMobileSerializer(serializers.Serializer):
    goal_amount = serializers.DecimalField(max_digits=10, decimal_places=2)
    total_income_month = serializers.DecimalField(max_digits=10, decimal_places=2)
    percent_of_goal = serializers.FloatField()
    daily_needed = serializers.DecimalField(max_digits=10, decimal_places=2)
    goal_reached = serializers.BooleanField()
    days_remaining = serializers.IntegerField()
    reference_date = serializers.DateField()


class DashboardSummarySerializer(serializers.Serializer):
    goal_amount = serializers.DecimalField(max_digits=10, decimal_places=2)
    total_income_month = serializers.DecimalField(max_digits=10, decimal_places=2)
    total_expense_month = serializers.DecimalField(max_digits=10, decimal_places=2)
    balance_month = serializers.DecimalField(max_digits=10, decimal_places=2)
    percent_of_goal = serializers.FloatField()
    daily_needed = serializers.DecimalField(max_digits=10, decimal_places=2)
    goal_reached = serializers.BooleanField()
    days_remaining = serializers.IntegerField()
    reference_date = serializers.DateField()
    last_10_transactions = TransactionListSerializer(many=True)
    daily_income_last_30_days = serializers.ListField(child=serializers.DictField())
    expenses_by_category_month = serializers.ListField(child=serializers.DictField())
