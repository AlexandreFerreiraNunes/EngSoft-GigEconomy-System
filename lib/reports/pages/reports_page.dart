import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../api/reports_api.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<Map<String, dynamic>> _daily = [];
  List<Map<String, dynamic>> _byCategory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final summary = await ReportsApi.getSummary();
    if (!mounted) return;
    setState(() {
      _daily = summary.dailyIncome;
      _byCategory = summary.byCategory;
      _loading = false;
    });
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Ganhos por dia (últimos 30 dias)'),
              _buildDailyChart(),
              const SizedBox(height: 24),
              _sectionTitle('Gastos por categoria (mês atual)'),
              _buildCategoryChart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTextPrimary)),
    );
  }

  Widget _buildDailyChart() {
    if (_daily.isEmpty) return _emptyState('Sem dados de ganhos');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _daily.map((e) => _toDouble(e['total'])).reduce((a, b) => a > b ? a : b) * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = _daily[groupIndex];
                    return BarTooltipItem(
                      '${formatShortDate(item['date'] ?? '')}\n${formatCurrency(rod.toY)}',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= _daily.length) return const SizedBox();
                      if (_daily.length > 15 && i % 5 != 0) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          formatShortDate(_daily[i]['date'] ?? ''),
                          style: const TextStyle(fontSize: 9, color: kTextSecondary),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              barGroups: _daily.asMap().entries.map((e) {
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                    toY: _toDouble(e.value['total']),
                    color: kIncomeGreen,
                    width: _daily.length > 20 ? 6 : 12,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChart() {
    if (_byCategory.isEmpty) return _emptyState('Sem gastos no mês');
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFFFFB347),
      const Color(0xFF6C63FF),
      const Color(0xFF00D09E),
      const Color(0xFFE056A0),
      const Color(0xFF4FC3F7),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: PieChart(
                PieChartData(
                  sections: _byCategory.asMap().entries.map((e) {
                    return PieChartSectionData(
                      value: _toDouble(e.value['total']),
                      color: colors[e.key % colors.length],
                      radius: 28,
                      showTitle: false,
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _byCategory.asMap().entries.map((e) {
                  final pct = _toDouble(e.value['percent']);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.value['category'] ?? '', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                        Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text(msg, style: const TextStyle(color: kTextSecondary))),
      ),
    );
  }
}
