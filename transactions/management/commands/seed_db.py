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

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _month_start(ref: date) -> date:
    return ref.replace(day=1)


def _add_months(ref: date, months: int) -> date:
    year = ref.year + (ref.month - 1 + months) // 12
    month = (ref.month - 1 + months) % 12 + 1
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


def _aware_dt(d: date, hour: int, minute: int, second: int = 0) -> datetime:
    dt = datetime.combine(d, time(hour, minute, second))
    tz = timezone.get_current_timezone()
    return timezone.make_aware(dt, tz)


def _dec(value: float) -> Decimal:
    return Decimal(str(round(value, 2)))


def _create_tx(*, user, tx_type, category, amount, note, created_at) -> Transaction:
    tx = Transaction.objects.create(
        user=user, type=tx_type, category=category, amount=amount, note=note,
    )
    Transaction.objects.filter(pk=tx.pk).update(created_at=created_at)
    tx.created_at = created_at
    return tx


def _create_goal(*, user, amount, is_active, created_at) -> Goal:
    goal = Goal.objects.create(user=user, amount=amount, is_active=is_active)
    Goal.objects.filter(pk=goal.pk).update(created_at=created_at)
    goal.created_at = created_at
    return goal


# ---------------------------------------------------------------------------
# Realistic patterns
# ---------------------------------------------------------------------------

# Income ranges per platform (min, max) in BRL
PLATFORM_INCOME = {
    "Uber":      (18.0, 85.0),
    "99":        (15.0, 70.0),
    "iFood":     (8.0, 38.0),
    "Rappi":     (10.0, 42.0),
    "Loggi":     (25.0, 95.0),
    "Freelance": (50.0, 300.0),
    "Outros":    (20.0, 150.0),
}

# Weight for how often each platform shows up (motorista vs entregador)
MOTORISTA_WEIGHTS = {
    "Uber": 40, "99": 30, "iFood": 5, "Rappi": 5,
    "Loggi": 10, "Freelance": 5, "Outros": 5,
}
ENTREGADOR_WEIGHTS = {
    "Uber": 5, "99": 5, "iFood": 35, "Rappi": 30,
    "Loggi": 15, "Freelance": 5, "Outros": 5,
}

INCOME_NOTES = {
    "Uber":      ["Corrida Centro-Aeroporto", "Corrida curta", "Corrida longa",
                   "Uber X", "Uber Comfort", "Viagem noturna", None, None],
    "99":        ["Corrida 99Pop", "Corrida 99Comfort", "Corrida curta",
                   None, None, None],
    "iFood":     ["Entrega restaurante", "Entrega dupla", "Entrega expressa",
                   "Pedido grande", None, None],
    "Rappi":     ["Entrega Rappi", "Entrega dupla", "Pedido mercado",
                   None, None],
    "Loggi":     ["Entrega pacote", "Entrega documento", "Rota múltipla",
                   None, None],
    "Freelance": ["Serviço de frete", "Mudança pequena", "Entrega especial",
                   None],
    "Outros":    ["Gorjeta", "Bônus semanal", "Indicação", None, None],
}

# Expense patterns: min/max (BRL), freq range per month, realistic notes
EXPENSE_PATTERNS = {
    "Combustível": {
        "min": 50.0, "max": 220.0, "freq": (6, 10),
        "notes": ["Gasolina", "Etanol", "Abastecimento completo",
                  "Gasolina aditivada", None],
    },
    "Alimentação": {
        "min": 12.0, "max": 55.0, "freq": (12, 22),
        "notes": ["Almoço", "Marmita", "Lanche rápido",
                  "Café + pão de queijo", "Jantar", "Água + salgado", None],
    },
    "Manutenção do veículo": {
        "min": 80.0, "max": 450.0, "freq": (1, 3),
        "notes": ["Troca de óleo", "Pneu novo", "Revisão",
                  "Pastilha de freio", "Alinhamento + balanceamento",
                  "Filtro de ar"],
    },
    "Aluguel / Moradia": {
        "min": 700.0, "max": 1200.0, "freq": (1, 1),
        "notes": ["Aluguel", "Aluguel + condomínio"],
    },
    "Saúde": {
        "min": 25.0, "max": 180.0, "freq": (0, 2),
        "notes": ["Farmácia", "Consulta médica", "Exame", "Remédio"],
    },
    "Outros": {
        "min": 15.0, "max": 120.0, "freq": (1, 4),
        "notes": ["Recarga celular", "Conta de internet", "Conta de luz",
                  "Seguro veicular", "Lavagem carro", None],
    },
}


# ---------------------------------------------------------------------------
# Seed user specifications
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class SeedUserSpec:
    key: str
    email: str
    name: str
    password: str
    scenario: str
    profile: str  # "motorista" or "entregador"


SEED_USERS: list[SeedUserSpec] = [
    SeedUserSpec(
        key="joao_motorista",
        email="joao_motorista@example.com",
        name="João Silva",
        password="seedpass123",
        scenario="Meta ativa e renda >= meta (goal_reached=true)",
        profile="motorista",
    ),
    SeedUserSpec(
        key="maria_entregadora",
        email="maria_entregadora@example.com",
        name="Maria Santos",
        password="seedpass123",
        scenario="Meta ativa e renda < meta (daily_needed > 0)",
        profile="entregador",
    ),
    SeedUserSpec(
        key="pedro_motorista",
        email="pedro_motorista@example.com",
        name="Pedro Oliveira",
        password="seedpass123",
        scenario="Sem meta ativa (goals/current e dashboard retornam 404)",
        profile="motorista",
    ),
    SeedUserSpec(
        key="ana_entregadora",
        email="ana_entregadora@example.com",
        name="Ana Costa",
        password="seedpass123",
        scenario="Meta ativa = 0 (proteção de divisão por zero)",
        profile="entregador",
    ),
]


# ---------------------------------------------------------------------------
# Command
# ---------------------------------------------------------------------------

class Command(BaseCommand):
    help = "Populate db.sqlite3 with ~N months of realistic seed data."

    def add_arguments(self, parser):
        parser.add_argument("--months", type=int, default=6)
        parser.add_argument("--seed", type=int, default=20260306)
        parser.add_argument("--clear", action="store_true")

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

        month_starts: list[date] = []
        cursor = start_month
        while cursor <= _month_start(today):
            month_starts.append(cursor)
            cursor = _add_months(cursor, 1)

        with transaction.atomic():
            if clear:
                seed_emails = [
                    "joao_motorista@example.com",
                    "maria_entregadora@example.com",
                    "pedro_motorista@example.com",
                    "ana_entregadora@example.com",
                ]
                deleted, _ = User.objects.filter(
                    email__in=seed_emails
                ).delete()
                self.stdout.write(self.style.WARNING(
                    f"Cleared seed data ({deleted} objects)."
                ))

            users = self._ensure_users()
            spec_map = {s.key: s for s in SEED_USERS}
            self._ensure_goals(users, rng, today)
            stats = self._seed_all_transactions(
                users, spec_map, rng, month_starts, today,
            )

        self.stdout.write(self.style.SUCCESS("Seed completo."))
        self.stdout.write(
            f"Período: {start_month.isoformat()} → {today.isoformat()}"
        )
        for spec in SEED_USERS:
            self.stdout.write(
                f"  {spec.email} | senha: {spec.password} | {spec.scenario}"
            )
        self.stdout.write(
            f"Transações: {stats['total']} "
            f"(income={stats['income']}, expense={stats['expense']})"
        )

    # -----------------------------------------------------------------------
    # Users
    # -----------------------------------------------------------------------

    def _ensure_users(self) -> dict[str, User]:
        users: dict[str, User] = {}
        for spec in SEED_USERS:
            user = User.objects.filter(email__iexact=spec.email).first()
            if not user:
                user = User.objects.create_user(
                    email=spec.email, name=spec.name, password=spec.password,
                )
            users[spec.key] = user
        return users

    # -----------------------------------------------------------------------
    # Goals
    # -----------------------------------------------------------------------

    def _ensure_goals(
        self, users: dict[str, User], rng: random.Random, today: date,
    ) -> None:
        for u in users.values():
            Goal.objects.filter(user=u).delete()

        # João: old inactive goal + current active R$4.500 (will be reached)
        _create_goal(
            user=users["joao_motorista"], amount=_dec(5000),
            is_active=False,
            created_at=_aware_dt(
                _add_months(today, -3).replace(day=1), 9, 0,
            ),
        )
        _create_goal(
            user=users["joao_motorista"], amount=_dec(4500),
            is_active=True,
            created_at=_aware_dt(
                _add_months(today, -1).replace(day=15), 10, 30,
            ),
        )

        # Maria: active R$8.000 (will NOT be reached)
        _create_goal(
            user=users["maria_entregadora"], amount=_dec(8000),
            is_active=True,
            created_at=_aware_dt(
                _add_months(today, -2).replace(day=1), 8, 0,
            ),
        )

        # Pedro: inactive goal only → /goals/current returns 404
        _create_goal(
            user=users["pedro_motorista"], amount=_dec(6000),
            is_active=False,
            created_at=_aware_dt(
                _add_months(today, -4).replace(day=10), 11, 0,
            ),
        )

        # Ana: active goal = R$0 → division-by-zero guard
        _create_goal(
            user=users["ana_entregadora"], amount=_dec(0),
            is_active=True,
            created_at=_aware_dt(
                _add_months(today, -1).replace(day=1), 7, 0,
            ),
        )

    # -----------------------------------------------------------------------
    # Transactions
    # -----------------------------------------------------------------------

    def _seed_all_transactions(self, users, spec_map, rng, month_starts, today):
        for u in users.values():
            Transaction.objects.filter(user=u).delete()

        stats = {"total": 0, "income": 0, "expense": 0}

        for key, user in users.items():
            profile = spec_map[key].profile
            for month_start in month_starts:
                month_end = _add_months(month_start, 1)
                all_days = [
                    month_start + timedelta(days=i)
                    for i in range((month_end - month_start).days)
                ]
                # NEVER generate future dates
                days = [d for d in all_days if d <= today]
                if not days:
                    continue

                self._seed_month_realistic(rng, user, profile, days, stats)

        # Guarantee dashboard scenarios for current month
        self._guarantee_goal_reached(users["joao_motorista"], rng, today)
        self._guarantee_goal_not_reached(users["maria_entregadora"])
        self._guarantee_expense_categories(
            users["joao_motorista"], rng, today,
        )
        self._guarantee_expense_categories(
            users["maria_entregadora"], rng, today,
        )

        return stats

    def _seed_month_realistic(self, rng, user, profile, days, stats):
        """Generate realistic daily transactions for one month."""

        weights = (
            MOTORISTA_WEIGHTS if profile == "motorista"
            else ENTREGADOR_WEIGHTS
        )
        platforms = list(weights.keys())
        platform_weights = [weights[p] for p in platforms]

        # Pick work days (~70‒85% of available days)
        num_work_days = max(1, int(len(days) * rng.uniform(0.70, 0.85)))
        work_days = sorted(
            rng.sample(days, min(num_work_days, len(days)))
        )

        # --- INCOME: multiple rides/deliveries per work day ---
        for d in work_days:
            if profile == "motorista":
                num_rides = rng.randint(3, 8)
            else:
                num_rides = rng.randint(4, 12)

            start_hour = rng.randint(6, 9)
            for ride_i in range(num_rides):
                hour = min(23, start_hour + ride_i * rng.randint(1, 3))
                minute = rng.randint(0, 59)

                platform = rng.choices(
                    platforms, weights=platform_weights, k=1,
                )[0]
                low, high = PLATFORM_INCOME[platform]
                amount = _dec(rng.uniform(low, high))
                note = rng.choice(INCOME_NOTES[platform])

                _create_tx(
                    user=user, tx_type="income", category=platform,
                    amount=amount, note=note,
                    created_at=_aware_dt(d, hour, minute),
                )
                stats["total"] += 1
                stats["income"] += 1

        # --- EXPENSES: category-based frequency ---
        for category, pattern in EXPENSE_PATTERNS.items():
            freq_min, freq_max = pattern["freq"]
            count = rng.randint(freq_min, freq_max)

            # Scale down for partial months
            if len(days) < 25:
                count = max(0, int(count * len(days) / 30))

            for _ in range(count):
                d = rng.choice(days)
                hour = rng.randint(7, 21)
                minute = rng.randint(0, 59)

                low, high = pattern["min"], pattern["max"]
                amount = _dec(rng.uniform(low, high))
                note = rng.choice(pattern["notes"])

                _create_tx(
                    user=user, tx_type="expense", category=category,
                    amount=amount, note=note,
                    created_at=_aware_dt(d, hour, minute),
                )
                stats["total"] += 1
                stats["expense"] += 1

    # -----------------------------------------------------------------------
    # Dashboard guarantees
    # -----------------------------------------------------------------------

    def _guarantee_goal_reached(self, user, rng, today):
        """Ensure João's current-month income >= his active goal."""
        goal = Goal.objects.filter(user=user, is_active=True).first()
        if not goal:
            return
        start, end = _month_window(today)
        total = (
            Transaction.objects.filter(
                user=user, type="income",
                created_at__date__gte=start, created_at__date__lt=end,
            ).aggregate(s=Sum("amount"))["s"]
            or Decimal("0")
        )
        if total >= goal.amount:
            return

        missing = goal.amount - total + _dec(rng.uniform(50, 200))
        _create_tx(
            user=user, tx_type="income", category="Uber",
            amount=missing.quantize(Decimal("0.01")),
            note="Bônus semanal",
            created_at=_aware_dt(
                today, rng.randint(14, 18), rng.randint(0, 59),
            ),
        )

    def _guarantee_goal_not_reached(self, user):
        """Ensure Maria's current-month income < her active goal."""
        goal = Goal.objects.filter(user=user, is_active=True).first()
        if not goal:
            return
        start, end = _month_window(timezone.now().date())
        total = (
            Transaction.objects.filter(
                user=user, type="income",
                created_at__date__gte=start, created_at__date__lt=end,
            ).aggregate(s=Sum("amount"))["s"]
            or Decimal("0")
        )
        if total < goal.amount:
            return
        new_goal = (total + Decimal("3000")).quantize(Decimal("0.01"))
        Goal.objects.filter(pk=goal.pk).update(amount=new_goal)

    def _guarantee_expense_categories(self, user, rng, today):
        """Ensure every expense category exists in the current month."""
        start, end = _month_window(today)
        present = set(
            Transaction.objects.filter(
                user=user, type="expense",
                created_at__date__gte=start, created_at__date__lt=end,
            ).values_list("category", flat=True)
        )
        for cat in EXPENSE_CATEGORIES:
            if cat in present:
                continue
            pattern = EXPENSE_PATTERNS[cat]
            _create_tx(
                user=user, tx_type="expense", category=cat,
                amount=_dec(rng.uniform(pattern["min"], pattern["max"])),
                note=rng.choice(pattern["notes"]),
                created_at=_aware_dt(
                    today, rng.randint(8, 20), rng.randint(0, 59),
                ),
            )
