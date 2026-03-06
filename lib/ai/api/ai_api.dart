import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';

/// Derives AI-like insights from the data returned by /dashboard/summary.
/// The backend does NOT expose /ai/* endpoints, so every computation
/// happens client-side using the summary payload.
class AiApi {
  /// Cached summary so we only hit the network once per refresh cycle.
  static Map<String, dynamic>? _cachedSummary;

  /// Fetches dashboard summary and caches it for the other methods.
  static Future<Map<String, dynamic>?> _fetchSummary() async {
    debugPrint('[AiApi] _fetchSummary — calling /dashboard/summary');
    final resp = await ApiClient.get('/dashboard/summary');
    debugPrint('[AiApi] _fetchSummary — status: ${resp.statusCode}');
    if (resp.ok && resp.data is Map) {
      _cachedSummary = Map<String, dynamic>.from(resp.data);
      return _cachedSummary;
    }
    debugPrint('[AiApi] _fetchSummary FAILED');
    _cachedSummary = null;
    return null;
  }

  /// Call this before reading the individual insight methods so they
  /// all operate on the same snapshot.
  static Future<void> refreshData() async {
    await _fetchSummary();
  }

  // ─── helpers ──────────────────────────────────────────────────

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static List<Map<String, dynamic>> _parseList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  // ─── 1. FORECAST ─────────────────────────────────────────────

  /// Returns a map with:
  ///   predicted_total  – estimated income at end of month
  ///   will_reach_goal  – whether the user is on track
  static Future<Map<String, dynamic>?> forecast() async {
    final data = _cachedSummary ?? await _fetchSummary();
    if (data == null) return null;

    final totalIncome = _toDouble(data['total_income_month']);
    final goalAmount = _toDouble(data['goal_amount']);
    final daysRemaining = (data['days_remaining'] is int)
        ? data['days_remaining'] as int
        : int.tryParse(data['days_remaining']?.toString() ?? '') ?? 0;

    // Reference date tells us the current day in the billing month.
    final refDateStr = data['reference_date']?.toString() ?? '';
    DateTime refDate;
    try {
      refDate = DateTime.parse(refDateStr);
    } catch (_) {
      refDate = DateTime.now();
    }

    final dayOfMonth = refDate.day;

    // Simple linear projection: daily average × total days in month.
    final dailyAverage = dayOfMonth > 0 ? totalIncome / dayOfMonth : 0.0;
    final totalDays = dayOfMonth + daysRemaining;
    final predictedTotal = dailyAverage * totalDays;

    final willReach = predictedTotal >= goalAmount;

    debugPrint('[AiApi] forecast — predicted: $predictedTotal, willReach: $willReach');

    return {
      'predicted_total': predictedTotal,
      'will_reach_goal': willReach,
      'daily_average': dailyAverage,
      'total_days': totalDays,
    };
  }

  // ─── 2. BEST DAYS ────────────────────────────────────────────

  /// Aggregates daily_income_last_30_days by weekday and returns
  /// a sorted list of { day: "Monday", average: 123.45 }.
  static Future<List<Map<String, dynamic>>> bestDays() async {
    final data = _cachedSummary ?? await _fetchSummary();
    if (data == null) return [];

    final daily = _parseList(data['daily_income_last_30_days']);
    if (daily.isEmpty) return [];

    // Aggregate by weekday (1=Monday … 7=Sunday in DateTime).
    final Map<int, List<double>> byWeekday = {};
    for (final entry in daily) {
      final dateStr = entry['date']?.toString() ?? '';
      final total = _toDouble(entry['total']);
      try {
        final dt = DateTime.parse(dateStr);
        byWeekday.putIfAbsent(dt.weekday, () => []).add(total);
      } catch (_) {
        // skip malformed dates
      }
    }

    const weekdayNames = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };

    final result = byWeekday.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return {'day': weekdayNames[e.key] ?? '', 'average': avg};
    }).toList();

    // Sort descending by average.
    result.sort((a, b) =>
        _toDouble(b['average']).compareTo(_toDouble(a['average'])));

    debugPrint('[AiApi] bestDays — ${result.length} weekdays computed');
    return result;
  }

  // ─── 3. BEST HOURS ───────────────────────────────────────────
  // The API does not provide hourly data, so we return an empty list.
  static Future<List<Map<String, dynamic>>> bestHours() async {
    debugPrint('[AiApi] bestHours — not available (no hourly data from API)');
    return [];
  }

  // ─── 4. SUGGESTIONS ─────────────────────────────────────────

  /// Generates plain-text suggestions based on the summary data.
  static Future<List<String>> suggestions() async {
    final data = _cachedSummary ?? await _fetchSummary();
    if (data == null) return ['Não foi possível obter dados. Tente novamente.'];

    final totalIncome = _toDouble(data['total_income_month']);
    final totalExpense = _toDouble(data['total_expense_month']);
    final goalAmount = _toDouble(data['goal_amount']);
    final percentOfGoal = _toDouble(data['percent_of_goal']);
    final dailyNeeded = _toDouble(data['daily_needed']);
    final goalReached = data['goal_reached'] == true;
    final daysRemaining = (data['days_remaining'] is int)
        ? data['days_remaining'] as int
        : int.tryParse(data['days_remaining']?.toString() ?? '') ?? 0;

    final balance = totalIncome - totalExpense;
    final expenseRatio =
        totalIncome > 0 ? (totalExpense / totalIncome * 100) : 0.0;

    final tips = <String>[];

    // --- Goal status tips ---
    if (goalReached) {
      tips.add(
          '🎉 Parabéns! Você já atingiu sua meta de R\$ ${goalAmount.toStringAsFixed(2)} este mês!');
    } else if (percentOfGoal >= 80) {
      tips.add(
          '🔥 Você está quase lá! Faltam apenas ${(100 - percentOfGoal).toStringAsFixed(0)}% para bater a meta.');
    } else if (percentOfGoal >= 50) {
      tips.add(
          '💪 Bom progresso! Você já atingiu ${percentOfGoal.toStringAsFixed(0)}% da meta. Continue assim!');
    } else if (percentOfGoal > 0) {
      tips.add(
          '📈 Você atingiu ${percentOfGoal.toStringAsFixed(0)}% da meta. Foque em ganhar R\$ ${dailyNeeded.toStringAsFixed(2)} por dia para alcançar o objetivo.');
    } else {
      tips.add(
          '🚀 Comece a registrar seus ganhos para acompanhar o progresso da meta!');
    }

    // --- Daily pacing tip ---
    if (!goalReached && daysRemaining > 0 && dailyNeeded > 0) {
      tips.add(
          '📅 Faltam $daysRemaining dias. Tente ganhar pelo menos R\$ ${dailyNeeded.toStringAsFixed(2)} por dia.');
    }

    // --- Expense ratio tips ---
    if (totalIncome > 0 && totalExpense > 0) {
      if (expenseRatio > 60) {
        tips.add(
            '⚠️ Seus gastos representam ${expenseRatio.toStringAsFixed(0)}% dos ganhos. Tente reduzir as despesas para sobrar mais.');
      } else if (expenseRatio > 40) {
        tips.add(
            '💡 Seus gastos estão em ${expenseRatio.toStringAsFixed(0)}% dos ganhos. Fique de olho para manter o equilíbrio.');
      } else {
        tips.add(
            '✅ Ótimo controle! Seus gastos são apenas ${expenseRatio.toStringAsFixed(0)}% dos ganhos.');
      }
    }

    // --- Expense category tips ---
    final byCategory = _parseList(data['expenses_by_category_month']);
    if (byCategory.isNotEmpty) {
      // Find the highest expense category.
      byCategory.sort((a, b) =>
          _toDouble(b['total']).compareTo(_toDouble(a['total'])));
      final top = byCategory.first;
      final catName = top['category']?.toString() ?? '';
      final catPct = _toDouble(top['percent']);
      if (catPct > 40) {
        tips.add(
            '🔍 "$catName" representa ${catPct.toStringAsFixed(0)}% dos seus gastos. Considere reduzir nessa categoria.');
      }
    }

    // --- Best days tip ---
    final daily = _parseList(data['daily_income_last_30_days']);
    if (daily.length >= 7) {
      // Find highest earning day.
      final sorted = List<Map<String, dynamic>>.from(daily)
        ..sort((a, b) =>
            _toDouble(b['total']).compareTo(_toDouble(a['total'])));
      final bestDay = sorted.first;
      final bestDateStr = bestDay['date']?.toString() ?? '';
      final bestVal = _toDouble(bestDay['total']);
      if (bestVal > 0) {
        final dayNames = {
          1: 'segunda-feira',
          2: 'terça-feira',
          3: 'quarta-feira',
          4: 'quinta-feira',
          5: 'sexta-feira',
          6: 'sábado',
          7: 'domingo',
        };
        try {
          final dt = DateTime.parse(bestDateStr);
          final dayName = dayNames[dt.weekday] ?? '';
          tips.add(
              '📊 Seu melhor dia recente foi $dayName com R\$ ${bestVal.toStringAsFixed(2)}. Tente replicar!');
        } catch (_) {}
      }
    }

    // --- Balance tip ---
    if (balance > 0 && !goalReached) {
      tips.add(
          '💰 Seu saldo líquido no mês é R\$ ${balance.toStringAsFixed(2)}. Continue equilibrando ganhos e gastos!');
    }

    debugPrint('[AiApi] suggestions — generated ${tips.length} tips');
    return tips;
  }
}
