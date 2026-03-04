from django.urls import path

from .views import DashboardMobileView, DashboardSummaryView


urlpatterns = [
    path("dashboard/mobile", DashboardMobileView.as_view(), name="dashboard-mobile"),
    path("dashboard/summary", DashboardSummaryView.as_view(), name="dashboard-summary"),
]
