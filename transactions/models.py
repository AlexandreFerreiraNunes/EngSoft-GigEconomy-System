from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models
from django.utils.translation import gettext_lazy as _

from common.constants import EXPENSE_CATEGORIES, INCOME_CATEGORIES, TRANSACTION_TYPES


class Transaction(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="transactions",
        verbose_name=_("usuário"),
    )
    type = models.CharField(_("tipo"), max_length=10, choices=TRANSACTION_TYPES)
    category = models.CharField(_("categoria"), max_length=50)
    amount = models.DecimalField(_("valor"), max_digits=10, decimal_places=2)
    note = models.CharField(_("observação"), max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(_("criado em"), auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = _("transação")
        verbose_name_plural = _("transações")

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
