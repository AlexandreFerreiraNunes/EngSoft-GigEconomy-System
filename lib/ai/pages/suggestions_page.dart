import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../api/ai_api.dart';

class SuggestionsPage extends StatefulWidget {
  const SuggestionsPage({super.key});

  @override
  State<SuggestionsPage> createState() => _SuggestionsPageState();
}

class _SuggestionsPageState extends State<SuggestionsPage> {
  Map<String, dynamic>? _forecast;
  List<Map<String, dynamic>> _bestDays = [];
  List<Map<String, dynamic>> _bestHours = [];
  List<String> _suggestions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      AiApi.forecast(),
      AiApi.bestDays(),
      AiApi.bestHours(),
      AiApi.suggestions(),
    ]);
    if (!mounted) return;
    setState(() {
      _forecast = results[0] as Map<String, dynamic>?;
      _bestDays = results[1] as List<Map<String, dynamic>>;
      _bestHours = results[2] as List<Map<String, dynamic>>;
      _suggestions = results[3] as List<String>;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sugestões da IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
            tooltip: 'Atualizar sugestões',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_forecast != null) _buildForecastCard(),
                    if (_suggestions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildSuggestionsSection(),
                    ],
                    if (_bestDays.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildBestDaysCard(),
                    ],
                    if (_bestHours.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildBestHoursCard(),
                    ],
                    if (_forecast == null && _suggestions.isEmpty && _bestDays.isEmpty && _bestHours.isEmpty)
                      _buildEmptyState(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildForecastCard() {
    final predicted = _toDouble(_forecast?['predicted_total']);
    final willReach = _forecast?['will_reach_goal'] == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (willReach ? kSuccess : kWarning).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    willReach ? Icons.trending_up : Icons.trending_flat,
                    color: willReach ? kSuccess : kWarning,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Previsão do mês', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      Text(
                        willReach ? 'Você vai bater a meta! 🎉' : 'Pode não atingir a meta',
                        style: TextStyle(color: willReach ? kSuccess : kWarning, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                formatCurrency(predicted),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary),
              ),
            ),
            const Center(
              child: Text('valor previsto ao final do mês', style: TextStyle(fontSize: 13, color: kTextSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        ..._suggestions.map((s) => Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lightbulb_outline, color: kPrimary, size: 20),
                ),
                title: Text(s, style: const TextStyle(fontSize: 14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            )),
      ],
    );
  }

  Widget _buildBestDaysCard() {
    final dayNames = {
      'Monday': 'Segunda',
      'Tuesday': 'Terça',
      'Wednesday': 'Quarta',
      'Thursday': 'Quinta',
      'Friday': 'Sexta',
      'Saturday': 'Sábado',
      'Sunday': 'Domingo',
      '0': 'Segunda',
      '1': 'Terça',
      '2': 'Quarta',
      '3': 'Quinta',
      '4': 'Sexta',
      '5': 'Sábado',
      '6': 'Domingo',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today, color: kPrimary, size: 20),
                SizedBox(width: 8),
                Text('Melhores dias', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            ..._bestDays.take(5).map((d) {
              final name = dayNames[d['day']?.toString()] ?? d['day']?.toString() ?? '';
              final avg = _toDouble(d['average'] ?? d['avg']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
                    Text(formatCurrency(avg), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kIncomeGreen)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBestHoursCard() {
    final periodNames = {
      'morning': '☀️ Manhã (6h-12h)',
      'afternoon': '🌤 Tarde (12h-18h)',
      'evening': '🌙 Noite (18h-00h)',
      'night': '🌑 Madrugada (00h-6h)',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.access_time, color: kPrimary, size: 20),
                SizedBox(width: 8),
                Text('Melhores horários', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            ..._bestHours.map((h) {
              final period = periodNames[h['period']?.toString()] ?? h['period']?.toString() ?? '';
              final avg = _toDouble(h['average'] ?? h['avg']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(period, style: const TextStyle(fontSize: 14))),
                    Text(formatCurrency(avg), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kIncomeGreen)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.psychology, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Registre mais dias para receber\nsugestões personalizadas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSecondary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
