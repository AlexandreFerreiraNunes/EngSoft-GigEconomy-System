import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../dashboard/pages/dashboard_page.dart';
import '../../transactions/pages/history_page.dart';
import '../../reports/pages/reports_page.dart';
import '../../ai/pages/suggestions_page.dart';
import '../../settings/pages/settings_page.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _index = 0;

  final _dashKey = GlobalKey<DashboardPageState>();
  final _historyKey = GlobalKey<HistoryPageState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardPage(
        key: _dashKey,
        onTransactionAdded: () => _historyKey.currentState?.loadData(),
      ),
      HistoryPage(key: _historyKey),
      const ReportsPage(),
      const SuggestionsPage(),
      const SettingsPage(),
    ];
  }

  void _onTap(int i) {
    if (i == _index) {
      if (i == 0) _dashKey.currentState?.loadData();
      if (i == 1) _historyKey.currentState?.loadData();
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, 'Início'),
                _navItem(1, Icons.receipt_long, 'Histórico'),
                _navItem(2, Icons.bar_chart, 'Relatórios'),
                _navItem(3, Icons.psychology, 'IA'),
                _navItem(4, Icons.settings, 'Config'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _index == index;
    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? kPrimary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: active ? kPrimary : kTextSecondary),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? kPrimary : kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
