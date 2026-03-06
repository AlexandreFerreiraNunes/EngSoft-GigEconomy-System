from django.urls import path

from .views import BestDaysView, BestHoursView, SuggestionsView

urlpatterns = [
    path("ai/best-days", BestDaysView.as_view(), name="ai-best-days"),
    path("ai/suggestions", SuggestionsView.as_view(), name="ai-suggestions"),
    path("ai/best-hours", BestHoursView.as_view(), name="ai-best-hours"),
]
