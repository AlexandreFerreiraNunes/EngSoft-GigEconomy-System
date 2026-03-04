from django.db import transaction
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Goal
from .serializers import GoalCreateSerializer, GoalSerializer


class GoalCurrentView(APIView):
    def get(self, request):
        goal = Goal.objects.filter(user=request.user, is_active=True).first()
        if not goal:
            return Response({"detail": "No active goal"}, status=status.HTTP_404_NOT_FOUND)
        return Response(GoalSerializer(goal).data)


class GoalCreateView(generics.CreateAPIView):
    serializer_class = GoalCreateSerializer


class GoalUpdateView(APIView):
    def put(self, request, pk: int):
        goal = Goal.objects.filter(pk=pk, user=request.user).first()
        if not goal:
            return Response({"detail": "Not found"}, status=status.HTTP_404_NOT_FOUND)

        serializer = GoalSerializer(goal, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)

        with transaction.atomic():
            Goal.objects.filter(user=request.user, is_active=True).exclude(pk=goal.pk).update(is_active=False)
            serializer.save()
            if not goal.is_active:
                goal.is_active = True
                goal.save(update_fields=["is_active"])

        return Response(GoalSerializer(goal).data)
