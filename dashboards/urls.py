from django.urls import path

from .views import DailyTargetView, DashboardMobileView, DashboardSummaryView


urlpatterns = [
    path("dashboard/mobile", DashboardMobileView.as_view(), name="dashboard-mobile"),
    path("dashboard/summary", DashboardSummaryView.as_view(), name="dashboard-summary"),
    path("dashboard/daily-target", DailyTargetView.as_view(), name="dashboard-daily-target"),
]
