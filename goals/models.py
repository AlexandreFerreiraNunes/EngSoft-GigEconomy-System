from django.conf import settings
from django.db import models
from django.utils.translation import gettext_lazy as _


class Goal(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="goals",
        verbose_name=_("usuário"),
    )
    amount = models.DecimalField(_("valor"), max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(_("criado em"), auto_now_add=True)
    is_active = models.BooleanField(_("ativa"), default=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = _("meta")
        verbose_name_plural = _("metas")

    def __str__(self) -> str:
        return f"{self.user_id} - {self.amount} ({'active' if self.is_active else 'inactive'})"
