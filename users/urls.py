from django.urls import path

from .views import LoginView, RegisterView, UserMeView


urlpatterns = [
    path("auth/register", RegisterView.as_view(), name="auth-register"),
    path("auth/login", LoginView.as_view(), name="auth-login"),
    path("users/me", UserMeView.as_view(), name="users-me"),
]
