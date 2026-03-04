from django.urls import path

from .views import TransactionDetailView, TransactionListView


urlpatterns = [
    path("transactions", TransactionListView.as_view(), name="transactions-list-create"),
    path("transactions/<int:pk>", TransactionDetailView.as_view(), name="transactions-detail"),
]
