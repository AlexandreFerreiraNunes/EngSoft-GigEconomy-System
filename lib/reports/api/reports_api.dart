import '../../core/api_client.dart';

class ReportsSummary {
  final List<Map<String, dynamic>> dailyIncome;
  final List<Map<String, dynamic>> byCategory;

  const ReportsSummary({required this.dailyIncome, required this.byCategory});
}

class ReportsApi {
  /// Fetches both report datasets from /dashboard/summary in a single call.
  static Future<ReportsSummary> getSummary() async {
    final resp = await ApiClient.get('/dashboard/summary');
    if (resp.ok && resp.data is Map) {
      final map = resp.data as Map;

      List<Map<String, dynamic>> parseList(dynamic raw) {
        if (raw is List) {
          return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      }

      return ReportsSummary(
        dailyIncome: parseList(map['daily_income_last_30_days']),
        byCategory: parseList(map['expenses_by_category_month']),
      );
    }
    return const ReportsSummary(dailyIncome: [], byCategory: []);
  }
}
