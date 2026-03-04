from django.contrib import admin

from .models import Goal


@admin.register(Goal)
class GoalAdmin(admin.ModelAdmin):
    list_display = ("id", "user_id", "amount", "is_active", "created_at")
    list_filter = ("is_active",)
