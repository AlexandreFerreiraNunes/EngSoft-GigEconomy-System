from datetime import date

from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Transaction
from .serializers import TransactionCreateSerializer, TransactionListSerializer, TransactionUpdateSerializer


class TransactionListView(generics.ListCreateAPIView):
    def get_serializer_class(self):
        if self.request.method == "POST":
            return TransactionCreateSerializer
        return TransactionListSerializer

    def get_queryset(self):
        qs = Transaction.objects.filter(user=self.request.user).order_by("-created_at")
        tx_type = self.request.query_params.get("type")
        category = self.request.query_params.get("category")
        start_date = self.request.query_params.get("start_date")
        end_date = self.request.query_params.get("end_date")

        if tx_type in {"income", "expense"}:
            qs = qs.filter(type=tx_type)
        if category:
            qs = qs.filter(category=category)

        def parse_iso_date(value: str | None) -> date | None:
            if not value:
                return None
            try:
                return date.fromisoformat(value)
            except ValueError:
                return None

        start = parse_iso_date(start_date)
        end = parse_iso_date(end_date)
        if start:
            qs = qs.filter(created_at__date__gte=start)
        if end:
            qs = qs.filter(created_at__date__lte=end)
        return qs


class TransactionDetailView(APIView):
    def put(self, request, pk: int):
        tx = Transaction.objects.filter(pk=pk, user=request.user).first()
        if not tx:
            return Response({"detail": "Not found"}, status=status.HTTP_404_NOT_FOUND)
        serializer = TransactionUpdateSerializer(tx, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(TransactionListSerializer(tx).data)

    def delete(self, request, pk: int):
        tx = Transaction.objects.filter(pk=pk, user=request.user).first()
        if not tx:
            return Response({"detail": "Not found"}, status=status.HTTP_404_NOT_FOUND)
        tx.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
