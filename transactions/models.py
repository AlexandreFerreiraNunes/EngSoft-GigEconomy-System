from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models

from common.constants import EXPENSE_CATEGORIES, INCOME_CATEGORIES, TRANSACTION_TYPES


class Transaction(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="transactions")
    type = models.CharField(max_length=10, choices=TRANSACTION_TYPES)
    category = models.CharField(max_length=50)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    note = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def clean(self):
        super().clean()
        if self.type == "income" and self.category not in INCOME_CATEGORIES:
            raise ValidationError({"category": "Invalid category for income"})
        if self.type == "expense" and self.category not in EXPENSE_CATEGORIES:
            raise ValidationError({"category": "Invalid category for expense"})

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)

    def __str__(self) -> str:
        return f"{self.user_id} {self.type} {self.amount}"
