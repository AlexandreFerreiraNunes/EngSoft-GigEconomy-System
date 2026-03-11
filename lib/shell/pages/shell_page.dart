import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../dashboard/pages/dashboard_page.dart';
import '../../dashboard/pages/dashboard_web_page.dart';
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

  final _dashMobileKey = GlobalKey<DashboardPageState>();
  final _dashWebKey = GlobalKey<DashboardWebPageState>();
  final _historyKey = GlobalKey<HistoryPageState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      if (kIsWeb)
        DashboardWebPage(
          key: _dashWebKey,
          onTransactionAdded: () => _historyKey.currentState?.loadData(),
          onNavigateToHistory: () => _onTap(1),
        )
      else
        DashboardPage(
          key: _dashMobileKey,
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
      if (i == 0) {
        if (kIsWeb) {
          _dashWebKey.currentState?.loadData();
        } else {
          _dashMobileKey.currentState?.loadData();
        }
      }
      if (i == 1) _historyKey.currentState?.loadData();
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _buildWebLayout();
    return _buildMobileLayout();
  }

  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Row(
        children: [
          _WebSidebar(
            currentIndex: _index,
            onTap: _onTap,
          ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
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

}

// ─── Web Sidebar ──────────────────────────────────────────────────────────────

class _WebSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _WebSidebar({
    required this.currentIndex,
    required this.onTap,
  });

  static const _destinations = [
    (icon: Icons.home_rounded, label: 'Início'),
    (icon: Icons.receipt_long_rounded, label: 'Histórico'),
    (icon: Icons.bar_chart_rounded, label: 'Relatórios'),
    (icon: Icons.psychology_rounded, label: 'IA'),
    (icon: Icons.settings_rounded, label: 'Config'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFEEEEF3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimary, kPrimaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'GigFinance',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                for (var i = 0; i < _destinations.length; i++)
                  _SidebarItem(
                    icon: _destinations[i].icon,
                    label: _destinations[i].label,
                    active: currentIndex == i,
                    onTap: () => onTap(i),
                  ),
              ],
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('v1.0.2',
                style: TextStyle(fontSize: 11, color: kTextSecondary)),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: active ? kPrimary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: active ? kPrimary : kTextSecondary),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? kPrimary : kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

extension on _ShellPageState {
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
