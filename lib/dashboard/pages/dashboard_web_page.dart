import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../api/dashboard_api.dart';
import '../../transactions/pages/add_transaction_page.dart';

class DashboardWebPage extends StatefulWidget {
  final VoidCallback? onTransactionAdded;
  final VoidCallback? onNavigateToHistory;

  const DashboardWebPage({
    super.key,
    this.onTransactionAdded,
    this.onNavigateToHistory,
  });

  @override
  State<DashboardWebPage> createState() => DashboardWebPageState();
}

class DashboardWebPageState extends State<DashboardWebPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => _loading = true);
    final data = await DashboardApi.getSummary();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: kTextSecondary),
            const SizedBox(height: 16),
            const Text('Não foi possível carregar os dados',
                style: TextStyle(fontSize: 16, color: kTextSecondary)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final goal = _num(_data!['goal_amount']);
    final earned = _num(_data!['balance_month']);
    final dailyNeeded = _num(_data!['daily_needed']);
    final goalReached = _data!['goal_reached'] == true;
    final daysRemaining = (_data!['days_remaining'] as num?)?.toInt() ?? 0;
    final percent = goal > 0 ? (earned / goal).clamp(0.0, 1.0) : 0.0;

    final aiMap = _data!['ai_forecast'] as Map<String, dynamic>?;
    final aiPredicted = _num(aiMap?['predicted_income']);
    final aiWillReach = aiMap?['will_reach_goal'] == true;

    final earnings = (_data!['earnings_last_30_days'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final categories = (_data!['expenses_by_category'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final transactions = (_data!['recent_transactions'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageHeader(
                onRefresh: loadData,
                onAddIncome: () => _openAddTransaction(context, 'income'),
                onAddExpense: () => _openAddTransaction(context, 'expense'),
              ),
              const SizedBox(height: 32),
              _KpiRow(
                goal: goal,
                earned: earned,
                percent: percent,
                dailyNeeded: dailyNeeded,
                goalReached: goalReached,
                daysRemaining: daysRemaining,
                aiPredicted: aiPredicted,
                aiWillReach: aiWillReach,
              ),
              const SizedBox(height: 28),
              _ChartsRow(
                earningsData: earnings,
                categoriesData: categories,
              ),
              const SizedBox(height: 28),
              _TransactionsTable(
                transactions: transactions,
                onViewAll: widget.onNavigateToHistory,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddTransaction(BuildContext ctx, String type) async {
    final result = await Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => AddTransactionPage(type: type)),
    );
    if (result == true) {
      await loadData();
      widget.onTransactionAdded?.call();
    }
  }
}

// ─── Page Header ─────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;

  const _PageHeader({
    required this.onRefresh,
    required this.onAddIncome,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthYear = DateFormat('MMMM yyyy', 'pt_BR').format(now);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontSize: 30, letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(
              _capitalize(monthYear),
              style: const TextStyle(fontSize: 15, color: kTextSecondary),
            ),
          ],
        ),
        const Spacer(),
        IconButton.outlined(
          tooltip: 'Atualizar',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 12),
        _ActionButton(
          label: 'Registrar ganho',
          icon: Icons.add_rounded,
          color: kIncomeGreen,
          onTap: onAddIncome,
        ),
        const SizedBox(width: 10),
        _ActionButton(
          label: 'Registrar gasto',
          icon: Icons.remove_rounded,
          color: kExpenseRed,
          onTap: onAddExpense,
        ),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── KPI Cards Row ────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final double goal;
  final double earned;
  final double percent;
  final double dailyNeeded;
  final bool goalReached;
  final int daysRemaining;
  final double aiPredicted;
  final bool aiWillReach;

  const _KpiRow({
    required this.goal,
    required this.earned,
    required this.percent,
    required this.dailyNeeded,
    required this.goalReached,
    required this.daysRemaining,
    required this.aiPredicted,
    required this.aiWillReach,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 900 ? 4 : 2;
        final gutter = 20.0;
        final cardW =
            (constraints.maxWidth - gutter * (cols - 1)) / cols;

        final cards = [
          _GoalCard(
            goal: goal,
            earned: earned,
            percent: percent,
            daysRemaining: daysRemaining,
          ),
          _KpiCard(
            label: 'Saldo do mês',
            value: formatCurrency(earned),
            icon: Icons.account_balance_wallet_rounded,
            color: earned >= 0 ? kIncomeGreen : kExpenseRed,
            subtitle:
                earned >= 0 ? 'Resultado positivo' : 'Resultado negativo',
          ),
          _KpiCard(
            label: goalReached ? 'Meta diária' : 'Necessário hoje',
            value: goalReached ? '—' : formatCurrency(dailyNeeded),
            icon: goalReached
                ? Icons.check_circle_rounded
                : Icons.trending_up_rounded,
            color: goalReached ? kSuccess : kPrimary,
            subtitle:
                goalReached ? 'Meta já atingida! 🎉' : 'para bater a meta',
          ),
          _AiForecastCard(
            predicted: aiPredicted,
            willReach: aiWillReach,
            goal: goal,
          ),
        ];

        return Wrap(
          spacing: gutter,
          runSpacing: gutter,
          children: [
            for (final card in cards)
              SizedBox(width: cardW, child: card),
          ],
        );
      },
    );
  }
}

class _GoalCard extends StatelessWidget {
  final double goal;
  final double earned;
  final double percent;
  final int daysRemaining;

  const _GoalCard({
    required this.goal,
    required this.earned,
    required this.percent,
    required this.daysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final color = progressColor(percent);
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.flag_rounded, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              const Text('Meta do mês',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: kTextSecondary)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${(percent * 100).toStringAsFixed(0)}%',
            style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -1),
          ),
          const SizedBox(height: 2),
          Text('atingido da meta',
              style:
                  const TextStyle(fontSize: 13, color: kTextSecondary)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat('Ganho', formatCurrency(earned), kIncomeGreen),
              _MiniStat('Meta', formatCurrency(goal), kPrimary),
              _MiniStat('Faltam', '$daysRemaining dias', kTextSecondary),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: kTextSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kTextSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.8),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 13, color: kTextSecondary)),
          ],
        ],
      ),
    );
  }
}

class _AiForecastCard extends StatelessWidget {
  final double predicted;
  final bool willReach;
  final double goal;

  const _AiForecastCard({
    required this.predicted,
    required this.willReach,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final color = willReach ? kSuccess : kWarning;
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.psychology_rounded,
                    size: 18, color: kPrimary),
              ),
              const SizedBox(width: 10),
              const Text('Previsão IA',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: kTextSecondary)),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            formatCurrency(predicted),
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
                letterSpacing: -0.8),
          ),
          const SizedBox(height: 4),
          const Text('previsão ao final do mês',
              style: TextStyle(fontSize: 13, color: kTextSecondary)),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  willReach
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 5),
                Text(
                  willReach ? 'Vai bater a meta' : 'Abaixo da meta',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Charts Row ───────────────────────────────────────────────────────────────

class _ChartsRow extends StatelessWidget {
  final List<Map<String, dynamic>> earningsData;
  final List<Map<String, dynamic>> categoriesData;

  const _ChartsRow({
    required this.earningsData,
    required this.categoriesData,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth > 750;
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _EarningsChart(data: earningsData)),
            const SizedBox(width: 20),
            Expanded(flex: 2, child: _ExpensesDonut(data: categoriesData)),
          ],
        );
      }
      return Column(
        children: [
          _EarningsChart(data: earningsData),
          const SizedBox(height: 20),
          _ExpensesDonut(data: categoriesData),
        ],
      );
    });
  }
}

class _EarningsChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _EarningsChart({required this.data});

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final bars = <BarChartGroupData>[];
    double maxY = 0;

    for (var i = 0; i < data.length; i++) {
      final amount = _num(data[i]['amount']);
      if (amount > maxY) maxY = amount;
      bars.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: amount,
            gradient: LinearGradient(
              colors: [kPrimary.withOpacity(0.7), kPrimary],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: data.length > 20 ? 8 : 14,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ));
    }

    maxY = maxY == 0 ? 100 : (maxY * 1.25).ceilToDouble();

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ChartTitle(
            title: 'Ganhos — últimos 30 dias',
            subtitle: 'Valores em R\$',
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: data.isEmpty
                ? _EmptyChart(message: 'Sem ganhos registrados')
                : BarChart(
                    BarChartData(
                      maxY: maxY,
                      barGroups: bars,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 56,
                            getTitlesWidget: (v, _) => Text(
                              _formatYAxis(v),
                              style: const TextStyle(
                                  fontSize: 11, color: kTextSecondary),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= data.length) {
                                return const SizedBox.shrink();
                              }
                              if (i % 5 != 0) return const SizedBox.shrink();
                              final date =
                                  data[i]['date']?.toString() ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _formatXDate(date),
                                  style: const TextStyle(
                                      fontSize: 11, color: kTextSecondary),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          tooltipRoundedRadius: 8,
                          tooltipBgColor: kPrimaryDark,
                          getTooltipItem: (group, _, rod, __) {
                            final date =
                                data[group.x]['date']?.toString() ?? '';
                            return BarTooltipItem(
                              '${_formatXDate(date)}\n',
                              const TextStyle(
                                  color: Colors.white70, fontSize: 11),
                              children: [
                                TextSpan(
                                  text: formatCurrency(rod.toY),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatYAxis(double v) {
    if (v >= 1000) return 'R\$${(v / 1000).toStringAsFixed(0)}k';
    return 'R\$${v.toStringAsFixed(0)}';
  }

  String _formatXDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd/MM', 'pt_BR').format(dt);
    } catch (_) {
      return iso;
    }
  }
}

class _ExpensesDonut extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  const _ExpensesDonut({required this.data});

  @override
  State<_ExpensesDonut> createState() => _ExpensesDonutState();
}

class _ExpensesDonutState extends State<_ExpensesDonut> {
  int? _touched;

  static const _palette = [
    kPrimary,
    kAccent,
    kWarning,
    kExpenseRed,
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFF06B6D4),
  ];

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ChartTitle(
            title: 'Gastos por categoria',
            subtitle: 'Mês atual',
          ),
          const SizedBox(height: 24),
          widget.data.isEmpty
              ? const SizedBox(
                  height: 220,
                  child: Center(
                    child: _EmptyChart(message: 'Sem gastos registrados'),
                  ),
                )
              : Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 54,
                          sectionsSpace: 2,
                          sections: [
                            for (var i = 0; i < widget.data.length; i++)
                              PieChartSectionData(
                                value: _num(widget.data[i]['amount']),
                                color: _palette[i % _palette.length],
                                radius: _touched == i ? 64 : 54,
                                title: _touched == i
                                    ? '${_num(widget.data[i]['percent']).toStringAsFixed(0)}%'
                                    : '',
                                titleStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              final idx = response
                                  ?.touchedSection?.touchedSectionIndex;
                              setState(() {
                                _touched = (event.isInterestedForInteractions)
                                    ? idx
                                    : null;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < widget.data.length; i++)
                          _LegendItem(
                            color: _palette[i % _palette.length],
                            label: widget.data[i]['category']?.toString() ?? '',
                            amount: formatCurrency(
                                _num(widget.data[i]['amount'])),
                          ),
                      ],
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String amount;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text('$label · $amount',
            style: const TextStyle(fontSize: 12, color: kTextSecondary)),
      ],
    );
  }
}

// ─── Recent Transactions ──────────────────────────────────────────────────────

class _TransactionsTable extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final VoidCallback? onViewAll;

  const _TransactionsTable({
    required this.transactions,
    this.onViewAll,
  });

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Últimos lançamentos',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary)),
                  SizedBox(height: 2),
                  Text('10 registros mais recentes',
                      style:
                          TextStyle(fontSize: 13, color: kTextSecondary)),
                ],
              ),
              const Spacer(),
              if (onViewAll != null)
                TextButton.icon(
                  onPressed: onViewAll,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Ver histórico'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Nenhum lançamento encontrado',
                    style: TextStyle(color: kTextSecondary)),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFEEEEF3)),
                    ),
                  ),
                  children: const [
                    _TableHeader('Data / Hora'),
                    _TableHeader('Tipo'),
                    _TableHeader('Categoria'),
                    _TableHeader('Valor'),
                  ],
                ),
                for (final tx in transactions)
                  TableRow(
                    children: [
                      _TableCell(
                          formatDate(tx['created_at']?.toString() ?? '')),
                      _TypeBadgeCell(
                          tx['type']?.toString() ?? 'income'),
                      _TableCell(
                          tx['category']?.toString() ?? '—'),
                      _AmountCell(
                        amount: _num(tx['amount']),
                        isExpense:
                            tx['type']?.toString() == 'expense',
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kTextSecondary,
              letterSpacing: 0.3)),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  const _TableCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text,
          style:
              const TextStyle(fontSize: 13, color: kTextPrimary)),
    );
  }
}

class _TypeBadgeCell extends StatelessWidget {
  final String type;
  const _TypeBadgeCell(this.type);

  @override
  Widget build(BuildContext context) {
    final isIncome = type == 'income';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: (isIncome ? kIncomeGreen : kExpenseRed).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          isIncome ? 'Ganho' : 'Gasto',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isIncome ? kIncomeGreen : kExpenseRed,
          ),
        ),
      ),
    );
  }
}

class _AmountCell extends StatelessWidget {
  final double amount;
  final bool isExpense;
  const _AmountCell({required this.amount, required this.isExpense});

  @override
  Widget build(BuildContext context) {
    final color = isExpense ? kExpenseRed : kIncomeGreen;
    final sign = isExpense ? '−' : '+';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        '$sign ${formatCurrency(amount)}',
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color),
      ),
    );
  }
}

// ─── Shared Utilities ─────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ChartTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _ChartTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kTextPrimary)),
        const SizedBox(height: 2),
        Text(subtitle,
            style:
                const TextStyle(fontSize: 12, color: kTextSecondary)),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;
  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 40,
              color: kTextSecondary.withOpacity(0.4)),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(
                  fontSize: 13, color: kTextSecondary)),
        ],
      ),
    );
  }
}
