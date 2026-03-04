from django.contrib import admin

from .models import Transaction


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ("id", "user_id", "type", "category", "amount", "created_at")
    list_filter = ("type", "category")
