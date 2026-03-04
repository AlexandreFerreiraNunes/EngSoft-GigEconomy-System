from django.urls import path

from .views import GoalCreateView, GoalCurrentView, GoalUpdateView


urlpatterns = [
    path("goals/current", GoalCurrentView.as_view(), name="goals-current"),
    path("goals", GoalCreateView.as_view(), name="goals-create"),
    path("goals/<int:pk>", GoalUpdateView.as_view(), name="goals-update"),
]
