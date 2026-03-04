from datetime import date, timedelta


def month_window(ref: date):
    start = ref.replace(day=1)
    if start.month == 12:
        next_month = start.replace(year=start.year + 1, month=1)
    else:
        next_month = start.replace(month=start.month + 1)
    return start, next_month


def days_remaining_in_month(ref: date) -> int:
    _, next_month = month_window(ref)
    last_day = next_month - timedelta(days=1)
    days_remaining = (last_day - ref).days
    return max(days_remaining, 1)
