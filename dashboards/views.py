from datetime import timedelta
from decimal import Decimal

from django.db.models import Sum
from django.utils import timezone
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from goals.models import Goal
from transactions.models import Transaction

from .serializers import (
    DailyTargetSerializer,
    DashboardMobileSerializer,
    DashboardSummarySerializer,
)
from .utils import days_remaining_in_month, month_window


def _to_decimal(value) -> Decimal:
    return value if isinstance(value, Decimal) else Decimal(value or 0)


class DashboardMobileView(APIView):
    def get(self, request):
        goal = Goal.objects.filter(user=request.user, is_active=True).first()
        if not goal:
            return Response({"detail": "No active goal"}, status=status.HTTP_404_NOT_FOUND)

        today = timezone.now().date()
        start, next_month = month_window(today)
        total_income_month = (
            Transaction.objects.filter(
                user=request.user,
                type="income",
                created_at__date__gte=start,
                created_at__date__lt=next_month,
            ).aggregate(total=Sum("amount"))["total"]
            or Decimal("0")
        )

        goal_amount = goal.amount
        percent = float((total_income_month / goal_amount) * 100) if goal_amount > 0 else 0.0
        remaining_days = days_remaining_in_month(today)
        remaining = goal_amount - total_income_month
        goal_reached = remaining <= 0
        daily_needed = Decimal("0") if goal_reached else (remaining / Decimal(remaining_days))

        payload = {
            "goal_amount": goal_amount,
            "total_income_month": total_income_month,
            "percent_of_goal": max(0.0, percent),
            "daily_needed": daily_needed.quantize(Decimal("0.01")),
            "goal_reached": goal_reached,
            "days_remaining": remaining_days,
            "reference_date": today,
        }
        return Response(DashboardMobileSerializer(payload).data)


class DashboardSummaryView(APIView):
    def get(self, request):
        goal = Goal.objects.filter(user=request.user, is_active=True).first()
        if not goal:
            return Response({"detail": "No active goal"}, status=status.HTTP_404_NOT_FOUND)

        today = timezone.now().date()
        start, next_month = month_window(today)

        month_qs = Transaction.objects.filter(
            user=request.user,
            created_at__date__gte=start,
            created_at__date__lt=next_month,
        )
        total_income_month = month_qs.filter(type="income").aggregate(total=Sum("amount"))["total"] or Decimal("0")
        total_expense_month = month_qs.filter(type="expense").aggregate(total=Sum("amount"))["total"] or Decimal("0")
        balance_month = total_income_month - total_expense_month

        goal_amount = goal.amount
        percent = float((total_income_month / goal_amount) * 100) if goal_amount > 0 else 0.0
        remaining_days = days_remaining_in_month(today)
        remaining = goal_amount - total_income_month
        goal_reached = remaining <= 0
        daily_needed = Decimal("0") if goal_reached else (remaining / Decimal(remaining_days))

        last_10 = Transaction.objects.filter(user=request.user).order_by("-created_at")[:10]

        thirty_days_ago = today - timedelta(days=29)
        daily_income_qs = (
            Transaction.objects.filter(
                user=request.user,
                type="income",
                created_at__date__gte=thirty_days_ago,
                created_at__date__lte=today,
            )
            .values("created_at__date")
            .annotate(total=Sum("amount"))
            .order_by("created_at__date")
        )
        daily_income_last_30_days = [
            {"date": row["created_at__date"].isoformat(), "total": str(row["total"])}
            for row in daily_income_qs
        ]

        expenses_by_category = (
            month_qs.filter(type="expense")
            .values("category")
            .annotate(total=Sum("amount"))
            .order_by("category")
        )
        expenses_by_category_month = []
        total_exp = _to_decimal(total_expense_month)
        for row in expenses_by_category:
            cat_total = _to_decimal(row["total"])
            pct = float((cat_total / total_exp) * 100) if total_exp > 0 else 0.0
            expenses_by_category_month.append(
                {"category": row["category"], "total": str(cat_total), "percent": pct}
            )

        payload = {
            "goal_amount": goal_amount,
            "total_income_month": total_income_month,
            "total_expense_month": total_expense_month,
            "balance_month": balance_month,
            "percent_of_goal": max(0.0, percent),
            "daily_needed": daily_needed.quantize(Decimal("0.01")),
            "goal_reached": goal_reached,
            "days_remaining": remaining_days,
            "reference_date": today,
            "last_10_transactions": last_10,
            "daily_income_last_30_days": daily_income_last_30_days,
            "expenses_by_category_month": expenses_by_category_month,
        }
        return Response(DashboardSummarySerializer(payload).data)


class DailyTargetView(APIView):
    """Quanto o usuário precisa faturar por dia para bater a meta,
    considerando receitas E despesas (balanço líquido)."""

    def get(self, request):
        goal = Goal.objects.filter(user=request.user, is_active=True).first()
        if not goal:
            return Response(
                {"detail": "No active goal"},
                status=status.HTTP_404_NOT_FOUND,
            )

        today = timezone.now().date()
        start, next_month = month_window(today)

        month_qs = Transaction.objects.filter(
            user=request.user,
            created_at__date__gte=start,
            created_at__date__lt=next_month,
        )
        total_income = (
            month_qs.filter(type="income")
            .aggregate(total=Sum("amount"))["total"]
            or Decimal("0")
        )
        total_expense = (
            month_qs.filter(type="expense")
            .aggregate(total=Sum("amount"))["total"]
            or Decimal("0")
        )
        balance = total_income - total_expense
        remaining = goal.amount - balance
        goal_reached = remaining <= 0
        remaining_days = days_remaining_in_month(today)
        daily_needed = (
            Decimal("0") if goal_reached
            else (remaining / Decimal(remaining_days)).quantize(Decimal("0.01"))
        )

        payload = {
            "goal_amount": goal.amount,
            "total_income_month": total_income,
            "total_expense_month": total_expense,
            "balance_month": balance,
            "remaining": max(remaining, Decimal("0")),
            "days_remaining": remaining_days,
            "daily_needed": daily_needed,
            "goal_reached": goal_reached,
            "reference_date": today,
        }
        return Response(DailyTargetSerializer(payload).data)
