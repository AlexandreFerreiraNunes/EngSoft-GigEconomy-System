from __future__ import annotations

import random
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta
from decimal import Decimal

from django.core.management.base import BaseCommand
from django.db import transaction
from django.db.models import Sum
from django.utils import timezone

from common.constants import EXPENSE_CATEGORIES, INCOME_CATEGORIES
from goals.models import Goal
from transactions.models import Transaction
from users.models import User


def _month_start(ref: date) -> date:
    return ref.replace(day=1)


def _add_months(ref: date, months: int) -> date:
    """Add months to a date, clamping day to month length."""

    year = ref.year + (ref.month - 1 + months) // 12
    month = (ref.month - 1 + months) % 12 + 1
    # Clamp day
    day = min(ref.day, _days_in_month(year, month))
    return date(year, month, day)


def _days_in_month(year: int, month: int) -> int:
    if month == 12:
        next_month = date(year + 1, 1, 1)
    else:
        next_month = date(year, month + 1, 1)
    return (next_month - timedelta(days=1)).day


def _month_window(ref: date) -> tuple[date, date]:
    start = _month_start(ref)
    next_month = _add_months(start, 1)
    return start, next_month


def _aware_dt(d: date, rng: random.Random) -> datetime:
    # Random time during the day (UTC by default in this project)
    dt = datetime.combine(d, time(rng.randint(0, 23), rng.randint(0, 59), rng.randint(0, 59)))
    tz = timezone.get_current_timezone()
    return timezone.make_aware(dt, tz)


def _decimal_amount(rng: random.Random, low: str, high: str) -> Decimal:
    # Generate 2-decimal monetary values.
    low_cents = int(Decimal(low) * 100)
    high_cents = int(Decimal(high) * 100)
    cents = rng.randint(low_cents, high_cents)
    return (Decimal(cents) / Decimal(100)).quantize(Decimal("0.01"))


def _create_tx_with_created_at(
    *,
    user: User,
    tx_type: str,
    category: str,
    amount: Decimal,
    note: str | None,
    created_at: datetime,
) -> Transaction:
    tx = Transaction.objects.create(
        user=user,
        type=tx_type,
        category=category,
        amount=amount,
        note=note,
    )
    # `auto_now_add=True` overwrites during create, so adjust after.
    Transaction.objects.filter(pk=tx.pk).update(created_at=created_at)
    tx.created_at = created_at
    return tx


def _create_goal_with_created_at(
    *,
    user: User,
    amount: Decimal,
    is_active: bool,
    created_at: datetime,
) -> Goal:
    goal = Goal.objects.create(user=user, amount=amount, is_active=is_active)
    Goal.objects.filter(pk=goal.pk).update(created_at=created_at)
    goal.created_at = created_at
    return goal


@dataclass(frozen=True)
class SeedUserSpec:
    key: str
    email: str
    name: str
    password: str
    scenario: str


SEED_USERS: list[SeedUserSpec] = [
    SeedUserSpec(
        key="joao_motorista",
        email="seed.joao_motorista@example.com",
        name="joao_motorista",
        password="seedpass123",
        scenario="Meta ativa e renda do mês atual >= meta (dashboard goal_reached=true)",
    ),
    SeedUserSpec(
        key="maria_entregadora",
        email="seed.maria_entregadora@example.com",
        name="maria_entregadora",
        password="seedpass123",
        scenario="Meta ativa e renda do mês atual < meta (dashboard daily_needed > 0)",
    ),
    SeedUserSpec(
        key="pedro_motorista",
        email="seed.pedro_motorista@example.com",
        name="pedro_motorista",
        password="seedpass123",
        scenario="Sem meta ativa (endpoints /goals/current e /dashboard/* retornam 404)",
    ),
    SeedUserSpec(
        key="ana_entregadora",
        email="seed.ana_entregadora@example.com",
        name="ana_entregadora",
        password="seedpass123",
        scenario="Meta ativa = 0 (dashboard percent_of_goal=0 por proteção)",
    ),
]


class Command(BaseCommand):
    help = "Populate db.sqlite3 with ~N months of seed data for all API scenarios."

    def add_arguments(self, parser):
        parser.add_argument(
            "--months",
            type=int,
            default=6,
            help="How many months of data to generate (including current month). Default: 6",
        )
        parser.add_argument(
            "--seed",
            type=int,
            default=20260305,
            help="Random seed for deterministic generation. Default: 20260305",
        )
        parser.add_argument(
            "--clear",
            action="store_true",
            help="Delete previously seeded users (email starting with 'seed.') and their data before seeding.",
        )

    def handle(self, *args, **options):
        months: int = options["months"]
        seed: int = options["seed"]
        clear: bool = options["clear"]

        if months < 1:
            self.stderr.write(self.style.ERROR("--months must be >= 1"))
            return

        rng = random.Random(seed)
        today = timezone.now().date()
        start_month = _month_start(_add_months(today, -(months - 1)))
        end_month = _month_start(today)
        month_starts: list[date] = []
        cursor = start_month
        while cursor <= end_month:
            month_starts.append(cursor)
            cursor = _add_months(cursor, 1)

        with transaction.atomic():
            if clear:
                deleted, _ = User.objects.filter(email__startswith="seed.").delete()
                self.stdout.write(self.style.WARNING(f"Cleared previous seed data (deleted objects: {deleted})."))

            users = self._ensure_users()
            self._ensure_goals(users, rng, today)
            tx_counts = self._seed_transactions(users, rng, month_starts, today)

        self.stdout.write(self.style.SUCCESS("Seed complete."))
        self.stdout.write(f"Months: {months} (from {start_month.isoformat()} to {today.isoformat()})")
        for spec in SEED_USERS:
            self.stdout.write(
                f"User: {spec.email} | password: {spec.password} | key: {spec.key} | scenario: {spec.scenario}"
            )
        self.stdout.write(
            f"Transactions created: {tx_counts['created']} (income={tx_counts['income']}, expense={tx_counts['expense']})"
        )

    def _ensure_users(self) -> dict[str, User]:
        users: dict[str, User] = {}
        for spec in SEED_USERS:
            user = User.objects.filter(email__iexact=spec.email).first()
            if not user:
                user = User.objects.create_user(email=spec.email, name=spec.name, password=spec.password)
            users[spec.key] = user
        return users

    def _ensure_goals(self, users: dict[str, User], rng: random.Random, today: date) -> None:
        # Ensure different goal scenarios.
        reached_user = users["joao_motorista"]
        not_reached_user = users["maria_entregadora"]
        no_goal_user = users["pedro_motorista"]
        zero_goal_user = users["ana_entregadora"]

        # Wipe existing goals for seed users (just to keep deterministic outcomes)
        Goal.objects.filter(user__in=[reached_user, not_reached_user, no_goal_user, zero_goal_user]).delete()

        now_dt = timezone.now()
        # Give them some history of goal changes
        two_months_ago = _add_months(today, -2)
        _create_goal_with_created_at(
            user=reached_user,
            amount=Decimal("2500.00"),
            is_active=False,
            created_at=_aware_dt(two_months_ago.replace(day=1), rng),
        )
        _create_goal_with_created_at(
            user=reached_user,
            amount=Decimal("3000.00"),
            is_active=True,
            created_at=now_dt,
        )

        _create_goal_with_created_at(
            user=not_reached_user,
            amount=Decimal("4000.00"),
            is_active=True,
            created_at=now_dt,
        )

        # No active goal: create an inactive goal (tests /goals/current 404)
        _create_goal_with_created_at(
            user=no_goal_user,
            amount=Decimal("3500.00"),
            is_active=False,
            created_at=now_dt,
        )

        _create_goal_with_created_at(
            user=zero_goal_user,
            amount=Decimal("0.00"),
            is_active=True,
            created_at=now_dt,
        )

    def _seed_transactions(
        self,
        users: dict[str, User],
        rng: random.Random,
        month_starts: list[date],
        today: date,
    ) -> dict[str, int]:
        seed_users = list(users.values())
        Transaction.objects.filter(user__in=seed_users).delete()

        created = 0
        income_created = 0
        expense_created = 0

        # Base patterns per user
        reached_user = users["joao_motorista"]
        not_reached_user = users["maria_entregadora"]
        no_goal_user = users["pedro_motorista"]
        zero_goal_user = users["ana_entregadora"]

        for month_start in month_starts:
            month_end = _add_months(month_start, 1)
            days = (month_end - month_start).days
            month_days = [month_start + timedelta(days=i) for i in range(days)]
            # Never generate transactions with future dates
            month_days = [d for d in month_days if d <= today]
            if not month_days:
                continue

            # Reached/not reached: always have activity
            created, income_created, expense_created = self._seed_month(
                rng,
                user=reached_user,
                month_days=month_days,
                income_count=rng.randint(18, 28),
                expense_count=rng.randint(10, 20),
                created=created,
                income_created=income_created,
                expense_created=expense_created,
            )
            created, income_created, expense_created = self._seed_month(
                rng,
                user=not_reached_user,
                month_days=month_days,
                income_count=rng.randint(10, 18),
                expense_count=rng.randint(8, 16),
                created=created,
                income_created=income_created,
                expense_created=expense_created,
            )

            # No-goal user: sparse activity (still useful for transactions endpoints)
            created, income_created, expense_created = self._seed_month(
                rng,
                user=no_goal_user,
                month_days=month_days,
                income_count=rng.randint(2, 6),
                expense_count=rng.randint(2, 6),
                created=created,
                income_created=income_created,
                expense_created=expense_created,
            )

            # Zero-goal user: include one empty month to test 0-results filters
            if month_start == month_starts[0]:
                continue
            created, income_created, expense_created = self._seed_month(
                rng,
                user=zero_goal_user,
                month_days=month_days,
                income_count=rng.randint(6, 12),
                expense_count=rng.randint(6, 12),
                created=created,
                income_created=income_created,
                expense_created=expense_created,
            )

        # Guarantee dashboard scenarios for current month
        current_month_start, next_month = _month_window(today)
        self._force_goal_reached_current_month(reached_user, rng, current_month_start, next_month)
        self._force_goal_not_reached_current_month(not_reached_user, rng, current_month_start, next_month)
        self._ensure_current_month_expense_categories(reached_user, rng, current_month_start, next_month)
        self._ensure_current_month_expense_categories(not_reached_user, rng, current_month_start, next_month)

        return {"created": created, "income": income_created, "expense": expense_created}

    def _seed_month(
        self,
        rng: random.Random,
        *,
        user: User,
        month_days: list[date],
        income_count: int,
        expense_count: int,
        created: int,
        income_created: int,
        expense_created: int,
    ) -> tuple[int, int, int]:
        # --- Notas realistas por categoria de receita ---
        income_notes: dict[str, list[str | None]] = {
            "Uber": [None, "Corrida centro", "Corrida aeroporto", "Viagem longa", "Corrida noturna", "UberX"],
            "99": [None, "Corrida rápida", "Corrida pop", "Viagem bairro", "Corrida noturna"],
            "iFood": [None, "Entrega almoço", "Entrega jantar", "Pedido grande", "Entrega rápida", "2 entregas"],
            "Rappi": [None, "Entrega mercado", "Entrega farmácia", "Entrega restaurante", "Pedido duplo"],
            "Loggi": [None, "Pacote centro", "Entrega documento", "Pacote grande", "Rota fixa"],
            "Freelance": [None, "Frete particular", "Mudança pequena", "Serviço avulso"],
            "Outros": [None, "Gorjeta", "Bônus semanal", "Indicação"],
        }
        # --- Notas realistas por categoria de despesa ---
        expense_notes: dict[str, list[str | None]] = {
            "Combustível": [None, "Gasolina", "Etanol", "Abastecimento completo", "Posto Shell", "Posto BR"],
            "Alimentação": [None, "Almoço", "Lanche rápido", "Marmita", "Café da manhã", "Jantar"],
            "Manutenção do veículo": [None, "Troca de óleo", "Pneu furado", "Revisão", "Pastilha de freio", "Lavagem"],
            "Aluguel / Moradia": [None, "Aluguel", "Conta de luz", "Conta de água", "Internet", "Condomínio"],
            "Saúde": [None, "Farmácia", "Consulta médica", "Exame", "Remédio"],
            "Outros": [None, "Recarga celular", "Seguro veículo", "Multa", "Estacionamento"],
        }
        # --- Faixas de valor realistas por categoria de receita (max R$120) ---
        income_ranges: dict[str, tuple[str, str]] = {
            "Uber": ("18.00", "120.00"),
            "99": ("15.00", "95.00"),
            "iFood": ("12.00", "85.00"),
            "Rappi": ("10.00", "75.00"),
            "Loggi": ("15.00", "90.00"),
            "Freelance": ("25.00", "120.00"),
            "Outros": ("5.00", "60.00"),
        }
        # --- Faixas de valor realistas por categoria de despesa (max R$120) ---
        expense_ranges: dict[str, tuple[str, str]] = {
            "Combustível": ("30.00", "120.00"),
            "Alimentação": ("8.00", "35.00"),
            "Manutenção do veículo": ("25.00", "120.00"),
            "Aluguel / Moradia": ("80.00", "120.00"),
            "Saúde": ("15.00", "95.00"),
            "Outros": ("5.00", "60.00"),
        }

        for _ in range(income_count):
            d = rng.choice(month_days)
            category = rng.choice(INCOME_CATEGORIES)
            low, high = income_ranges.get(category, ("15.00", "120.00"))
            note = rng.choice(income_notes.get(category, [None]))
            _create_tx_with_created_at(
                user=user,
                tx_type="income",
                category=category,
                amount=_decimal_amount(rng, low, high),
                note=note,
                created_at=_aware_dt(d, rng),
            )
            created += 1
            income_created += 1

        for _ in range(expense_count):
            d = rng.choice(month_days)
            category = rng.choice(EXPENSE_CATEGORIES)
            low, high = expense_ranges.get(category, ("10.00", "120.00"))
            note = rng.choice(expense_notes.get(category, [None]))
            _create_tx_with_created_at(
                user=user,
                tx_type="expense",
                category=category,
                amount=_decimal_amount(rng, low, high),
                note=note,
                created_at=_aware_dt(d, rng),
            )
            created += 1
            expense_created += 1
        return created, income_created, expense_created

    def _force_goal_reached_current_month(
        self,
        user: User,
        rng: random.Random,
        start: date,
        next_month: date,
    ) -> None:
        goal = Goal.objects.filter(user=user, is_active=True).first()
        if not goal:
            return
        total_income = (
            Transaction.objects.filter(
                user=user,
                type="income",
                created_at__date__gte=start,
                created_at__date__lt=next_month,
            ).aggregate(s=Sum("amount"))["s"]
            or Decimal("0")
        )

        if total_income >= goal.amount:
            return

        # Add multiple small incomes (max R$120 each) to cover the gap.
        today = timezone.now().date()
        missing = (goal.amount - total_income) + Decimal("50.00")
        while missing > Decimal("0"):
            chunk = min(missing, _decimal_amount(rng, "60.00", "120.00"))
            _create_tx_with_created_at(
                user=user,
                tx_type="income",
                category=rng.choice(INCOME_CATEGORIES),
                amount=chunk.quantize(Decimal("0.01")),
                note=rng.choice(["Corrida longa", "Viagem aeroporto", "Entrega grande", "Bônus"]),
                created_at=_aware_dt(today, rng),
            )
            missing -= chunk

    def _force_goal_not_reached_current_month(
        self,
        user: User,
        rng: random.Random,
        start: date,
        next_month: date,
    ) -> None:
        goal = Goal.objects.filter(user=user, is_active=True).first()
        if not goal:
            return

        total_income = (
            Transaction.objects.filter(
                user=user,
                type="income",
                created_at__date__gte=start,
                created_at__date__lt=next_month,
            ).aggregate(s=Sum("amount"))["s"]
            or Decimal("0")
        )

        # Ensure total_income < goal.amount. If not, increase goal slightly.
        if total_income >= goal.amount:
            new_goal = (total_income + Decimal("800.00")).quantize(Decimal("0.01"))
            Goal.objects.filter(pk=goal.pk).update(amount=new_goal)
            goal.amount = new_goal

    def _ensure_current_month_expense_categories(
        self,
        user: User,
        rng: random.Random,
        start: date,
        next_month: date,
    ) -> None:
        present = set(
            Transaction.objects.filter(
                user=user,
                type="expense",
                created_at__date__gte=start,
                created_at__date__lt=next_month,
            ).values_list("category", flat=True)
        )
        missing = [c for c in EXPENSE_CATEGORIES if c not in present]
        if not missing:
            return

        today = timezone.now().date()
        for cat in missing:
            _create_tx_with_created_at(
                user=user,
                tx_type="expense",
                category=cat,
                amount=_decimal_amount(rng, "15.00", "85.00"),
                note="Ajuste seed: cobrir categoria",
                created_at=_aware_dt(today, rng),
            )
