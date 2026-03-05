import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../api/dashboard_api.dart';
import '../../transactions/pages/add_transaction_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => _loading = true);
    final data = await DashboardApi.getMobile();
    if (!mounted) return;
    setState(() {
      _data = data;
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

    final goal = _toDouble(_data?['goal_amount']);
    final earned = _toDouble(_data?['total_earned']);
    final dailyNeeded = _toDouble(_data?['daily_needed']);
    final goalReached = _data?['goal_reached'] == true;
    final percent = goal > 0 ? (earned / goal).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Olá! 👋', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('Acompanhe seu progresso', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                _buildProgressCard(context, percent, earned, goal, goalReached),
                const SizedBox(height: 16),
                _buildDailyCard(context, dailyNeeded, goalReached),
                const SizedBox(height: 24),
                _buildActionButton(
                  context,
                  icon: Icons.add_circle,
                  label: 'Registrar Ganho',
                  color: kIncomeGreen,
                  onTap: () => _openAddTransaction(context, 'income'),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context,
                  icon: Icons.remove_circle,
                  label: 'Registrar Gasto',
                  color: kExpenseRed,
                  onTap: () => _openAddTransaction(context, 'expense'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext ctx, double percent, double earned, double goal, bool reached) {
    final color = progressColor(percent);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 12,
                      backgroundColor: color.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(percent * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: color),
                      ),
                      const Text('da meta', style: TextStyle(fontSize: 13, color: kTextSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _miniStat('Ganho', formatCurrency(earned), kIncomeGreen),
                Container(width: 1, height: 36, color: Colors.grey.shade200),
                _miniStat('Meta', formatCurrency(goal), kPrimary),
              ],
            ),
            if (reached) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: kSuccess.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.celebration, color: kSuccess, size: 20),
                    SizedBox(width: 8),
                    Text('Parabéns! Meta batida! 🎉', style: TextStyle(color: kSuccess, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: kTextSecondary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _buildDailyCard(BuildContext ctx, double daily, bool reached) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              reached ? Icons.check_circle : Icons.trending_up,
              size: 36,
              color: reached ? kSuccess : kPrimary,
            ),
            const SizedBox(height: 12),
            Text(
              reached ? 'Você já atingiu a meta!' : 'Precisa ganhar hoje',
              style: const TextStyle(fontSize: 14, color: kTextSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              reached ? '🎉' : formatCurrency(daily),
              style: TextStyle(
                fontSize: reached ? 32 : 28,
                fontWeight: FontWeight.w700,
                color: reached ? kSuccess : kTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext ctx, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
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
    if (result == true) await loadData();
  }
}
