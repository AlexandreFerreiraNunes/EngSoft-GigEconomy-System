from django.contrib.auth.base_user import AbstractBaseUser, BaseUserManager
from django.contrib.auth.models import PermissionsMixin
from django.db import models
from django.utils.translation import gettext_lazy as _


class UserManager(BaseUserManager):
    use_in_migrations = True

    def create_user(self, email: str, password: str | None = None, **extra_fields):
        if not email:
            raise ValueError("Email is required")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.full_clean()
        user.save(using=self._db)
        return user

    def create_superuser(self, email: str, password: str | None = None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("is_active", True)
        return self.create_user(email=email, password=password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    name = models.CharField(_("nome"), max_length=100)
    email = models.EmailField(_("e-mail"), max_length=150, unique=True)
    profile_photo_url = models.URLField(_("URL da foto de perfil"), max_length=500, blank=True, null=True)
    created_at = models.DateTimeField(_("criado em"), auto_now_add=True)

    is_active = models.BooleanField(_("ativo"), default=True)
    is_staff = models.BooleanField(_("equipe"), default=False)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS: list[str] = ["name"]

    class Meta:
        verbose_name = _("usuário")
        verbose_name_plural = _("usuários")

    def __str__(self) -> str:
        return self.email
