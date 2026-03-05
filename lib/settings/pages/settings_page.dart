import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../goals/api/goals_api.dart';
import '../../goals/pages/goal_page.dart';
import '../../auth/pages/splash_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _goal;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiClient.get('/users/me'),
      GoalsApi.getCurrent(),
    ]);
    if (!mounted) return;
    final userResp = results[0] as ApiResponse;
    setState(() {
      _user = userResp.ok && userResp.data is Map ? Map<String, dynamic>.from(userResp.data) : null;
      _goal = results[1] as Map<String, dynamic>?;
      _loading = false;
    });
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _user?['name'] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar nome'),
        content: TextFormField(
          controller: ctrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Seu nome'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final resp = await ApiClient.put('/users/me', body: {'name': result});
      if (!mounted) return;
      if (resp.ok) {
        showSnack(context, 'Nome atualizado!');
        await _load();
      } else {
        showSnack(context, 'Erro ao atualizar', error: true);
      }
    }
  }

  Future<void> _editGoal() async {
    final goalAmount = _toDouble(_goal?['amount']);
    final goalId = _goal?['id'] as int?;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GoalPage(currentAmount: goalAmount, goalId: goalId),
      ),
    );
    if (result == true) await _load();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthStorage.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashPage()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = _user?['name'] ?? 'Usuário';
    final email = _user?['email'] ?? '';
    final goalAmount = _toDouble(_goal?['amount']);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: kPrimary.withOpacity(0.12),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: kPrimary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          Text(email, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _settingsTile(
              icon: Icons.person_outline,
              title: 'Editar nome',
              subtitle: name,
              onTap: _editName,
            ),
            _settingsTile(
              icon: Icons.flag_outlined,
              title: 'Meta mensal',
              subtitle: goalAmount > 0 ? formatCurrency(goalAmount) : 'Não definida',
              onTap: _editGoal,
            ),
            const SizedBox(height: 16),
            _settingsTile(
              icon: Icons.logout,
              title: 'Sair da conta',
              subtitle: 'Desconectar',
              onTap: _logout,
              danger: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: (danger ? kDanger : kPrimary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: danger ? kDanger : kPrimary, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: danger ? kDanger : kTextPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: kTextSecondary)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
