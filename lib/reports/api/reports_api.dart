import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';

class ReportsSummary {
  final List<Map<String, dynamic>> dailyIncome;
  final List<Map<String, dynamic>> byCategory;

  const ReportsSummary({required this.dailyIncome, required this.byCategory});
}

class ReportsApi {
  /// Fetches both report datasets from /dashboard/summary in a single call.
  static Future<ReportsSummary> getSummary() async {
    debugPrint('[ReportsApi] getSummary() called');
    final resp = await ApiClient.get('/dashboard/summary');
    debugPrint('[ReportsApi] getSummary() response — ok: ${resp.ok}, status: ${resp.statusCode}, dataType: ${resp.data.runtimeType}');
    debugPrint('[ReportsApi] getSummary() data: ${resp.data}');
    if (resp.ok && resp.data is Map) {
      final map = resp.data as Map;

      List<Map<String, dynamic>> parseList(dynamic raw) {
        if (raw is List) {
          return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      }

      final dailyIncome = parseList(map['daily_income_last_30_days']);
      final byCategory = parseList(map['expenses_by_category_month']);

      debugPrint('[ReportsApi] dailyIncome total: ${dailyIncome.length} itens');
      for (final item in dailyIncome) {
        debugPrint('[ReportsApi]   dailyIncome item: $item');
      }
      if (dailyIncome.isNotEmpty) {
        final mostRecent = dailyIncome.reduce((a, b) {
          final da = a['date'] as String? ?? '';
          final db = b['date'] as String? ?? '';
          return da.compareTo(db) >= 0 ? a : b;
        });
        debugPrint('[ReportsApi] dailyIncome MAIS RECENTE: $mostRecent');
      }

      debugPrint('[ReportsApi] byCategory total: ${byCategory.length} itens');
      for (final item in byCategory) {
        debugPrint('[ReportsApi]   byCategory item: $item');
      }

      return ReportsSummary(
        dailyIncome: dailyIncome,
        byCategory: byCategory,
      );
    }
    return const ReportsSummary(dailyIncome: [], byCategory: []);
  }
}
