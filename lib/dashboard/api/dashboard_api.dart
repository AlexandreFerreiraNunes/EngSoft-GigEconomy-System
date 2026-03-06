import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';

class DashboardApi {
  static Future<Map<String, dynamic>?> getDailyTarget() async {
    debugPrint('[DashboardApi] GET /dashboard/daily-target — chamando...');
    final resp = await ApiClient.get('/dashboard/daily-target');
    debugPrint('[DashboardApi] GET /dashboard/daily-target — status: ${resp.statusCode}');
    debugPrint('[DashboardApi] GET /dashboard/daily-target — body: ${resp.data}');
    if (resp.ok && resp.data is Map) {
      final map = Map<String, dynamic>.from(resp.data);
      debugPrint('[DashboardApi] getDailyTarget parsed: $map');
      debugPrint('[DashboardApi]   goal_amount      = ${map['goal_amount']}');
      debugPrint('[DashboardApi]   balance_month    = ${map['balance_month']}');
      debugPrint('[DashboardApi]   daily_needed     = ${map['daily_needed']}');
      debugPrint('[DashboardApi]   goal_reached     = ${map['goal_reached']}');
      debugPrint('[DashboardApi]   days_remaining   = ${map['days_remaining']}');
      return map;
    }
    debugPrint('[DashboardApi] getDailyTarget FALHOU — resp.ok=${resp.ok}, data type=${resp.data.runtimeType}');
    return null;
  }

  static Future<Map<String, dynamic>?> getMobile() async {
    debugPrint('[DashboardApi] GET /dashboard/mobile — chamando...');
    final resp = await ApiClient.get('/dashboard/mobile');
    debugPrint('[DashboardApi] GET /dashboard/mobile — status: ${resp.statusCode}');
    debugPrint('[DashboardApi] GET /dashboard/mobile — body: ${resp.data}');
    if (resp.ok && resp.data is Map) {
      final map = Map<String, dynamic>.from(resp.data);
      debugPrint('[DashboardApi] getMobile parsed: $map');
      // Backend sometimes returns "total_income_month" instead of "total_earned".
      // Normalize to `total_earned` so UI code can always use the same key.
      if (map.containsKey('total_income_month') && !map.containsKey('total_earned')) {
        map['total_earned'] = map['total_income_month'];
        debugPrint('[DashboardApi] Normalized total_income_month -> total_earned');
      }
      debugPrint('[DashboardApi]   total_earned = ${map['total_earned']} (${map['total_earned']?.runtimeType})');
      debugPrint('[DashboardApi]   goal_amount  = ${map['goal_amount']} (${map['goal_amount'].runtimeType})');
      debugPrint('[DashboardApi]   daily_needed = ${map['daily_needed']} (${map['daily_needed'].runtimeType})');
      debugPrint('[DashboardApi]   goal_reached = ${map['goal_reached']} (${map['goal_reached'].runtimeType})');
      return map;
    }
    debugPrint('[DashboardApi] getMobile FALHOU — resp.ok=${resp.ok}, data type=${resp.data.runtimeType}');
    return null;
  }

  static Future<Map<String, dynamic>?> getSummary() async {
    debugPrint('[DashboardApi] GET /dashboard/summary — chamando...');
    final resp = await ApiClient.get('/dashboard/summary');
    debugPrint('[DashboardApi] GET /dashboard/summary — status: ${resp.statusCode}');
    debugPrint('[DashboardApi] GET /dashboard/summary — body: ${resp.data}');
    if (resp.ok && resp.data is Map) {
      return Map<String, dynamic>.from(resp.data);
    }
    debugPrint('[DashboardApi] getSummary FALHOU — resp.ok=${resp.ok}');
    return null;
  }
}
