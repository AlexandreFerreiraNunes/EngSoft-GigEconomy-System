import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../api/dashboard_api.dart';
import '../../transactions/pages/add_transaction_page.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback? onTransactionAdded;

  const DashboardPage({super.key, this.onTransactionAdded});

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
    debugPrint('[Dashboard] loadData() chamando DashboardApi.getDailyTarget()...');
    final data = await DashboardApi.getDailyTarget();
    debugPrint('[Dashboard] loadData() data recebida: $data');
    if (data != null) {
      debugPrint('[Dashboard] balance_month  = ${data['balance_month']}');
      debugPrint('[Dashboard] goal_amount    = ${data['goal_amount']}');
      debugPrint('[Dashboard] daily_needed   = ${data['daily_needed']}');
      debugPrint('[Dashboard] goal_reached   = ${data['goal_reached']}');
      debugPrint('[Dashboard] days_remaining = ${data['days_remaining']}');
    } else {
      debugPrint('[Dashboard] loadData() — API retornou null!');
    }
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
    final earned = _toDouble(_data?['balance_month']);
    final dailyNeeded = _toDouble(_data?['daily_needed']);
    final goalReached = _data?['goal_reached'] == true;
    final percent = goal > 0 ? (earned / goal).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final w = constraints.maxWidth;
            // Scale the circular indicator based on available height
            final ringSize = (h * 0.22).clamp(80.0, 160.0);
            final ringStroke = (ringSize * 0.075).clamp(6.0, 12.0);
            final percentFont = (ringSize * 0.22).clamp(18.0, 36.0);
            final btnHeight = (h * 0.065).clamp(40.0, 56.0);
            final hPad = (w * 0.05).clamp(12.0, 24.0);

            return RefreshIndicator(
              onRefresh: loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: h),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad, vertical: h * 0.02),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Olá! 👋',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontSize: (h * 0.035).clamp(18.0, 28.0),
                                )),
                        SizedBox(height: h * 0.005),
                        Text('Acompanhe seu progresso',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: (h * 0.02).clamp(12.0, 16.0),
                                )),
                        SizedBox(height: h * 0.025),
                        _buildProgressCard(context, percent, earned, goal, goalReached, ringSize, ringStroke, percentFont),
                        SizedBox(height: h * 0.015),
                        _buildDailyCard(context, dailyNeeded, goalReached, h),
                        SizedBox(height: h * 0.025),
                        _buildActionButton(
                          context,
                          icon: Icons.add_circle,
                          label: 'Registrar Ganho',
                          color: kIncomeGreen,
                          height: btnHeight,
                          onTap: () => _openAddTransaction(context, 'income'),
                        ),
                        SizedBox(height: h * 0.012),
                        _buildActionButton(
                          context,
                          icon: Icons.remove_circle,
                          label: 'Registrar Gasto',
                          color: kExpenseRed,
                          height: btnHeight,
                          onTap: () => _openAddTransaction(context, 'expense'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext ctx,
    double percent,
    double earned,
    double goal,
    bool reached,
    double ringSize,
    double ringStroke,
    double percentFont,
  ) {
    final color = progressColor(percent);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(ringSize * 0.12),
        child: Column(
          children: [
            SizedBox(
              width: ringSize,
              height: ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: ringSize,
                    height: ringSize,
                    child: CircularProgressIndicator(
                      value: percent,
                      strokeWidth: ringStroke,
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
                        style: TextStyle(fontSize: percentFont, fontWeight: FontWeight.w700, color: color),
                      ),
                      Text('da meta', style: TextStyle(fontSize: percentFont * 0.38, color: kTextSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: ringSize * 0.12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _miniStat('Saldo', formatCurrency(earned), kIncomeGreen, percentFont * 0.45),
                Container(width: 1, height: ringSize * 0.22, color: Colors.grey.shade200),
                _miniStat('Meta', formatCurrency(goal), kPrimary, percentFont * 0.45),
              ],
            ),
            if (reached) ...[
              SizedBox(height: ringSize * 0.1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kSuccess.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.celebration, color: kSuccess, size: percentFont * 0.55),
                    const SizedBox(width: 6),
                    Text('Parabéns! Meta batida! 🎉',
                        style: TextStyle(
                          color: kSuccess,
                          fontWeight: FontWeight.w600,
                          fontSize: percentFont * 0.4,
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color, double fontSize) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: fontSize * 0.85, color: kTextSecondary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _buildDailyCard(BuildContext ctx, double daily, bool reached, double screenH) {
    final iconSize = (screenH * 0.04).clamp(24.0, 36.0);
    final valueFont = (screenH * 0.035).clamp(18.0, 28.0);
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: screenH * 0.018, horizontal: 20),
        child: Column(
          children: [
            Icon(
              reached ? Icons.check_circle : Icons.trending_up,
              size: iconSize,
              color: reached ? kSuccess : kPrimary,
            ),
            SizedBox(height: screenH * 0.01),
            Text(
              reached ? 'Você já atingiu a meta!' : 'Precisa ganhar hoje',
              style: TextStyle(fontSize: valueFont * 0.52, color: kTextSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              reached ? '🎉' : formatCurrency(daily),
              style: TextStyle(
                fontSize: valueFont,
                fontWeight: FontWeight.w700,
                color: reached ? kSuccess : kTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required Color color,
    required double height,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: height,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: height * 0.45),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: height * 0.32,
                    fontWeight: FontWeight.w600,
                  )),
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
