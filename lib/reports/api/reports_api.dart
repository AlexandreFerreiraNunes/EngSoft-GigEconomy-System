import '../../core/api_client.dart';

class ReportsApi {
  static Future<List<Map<String, dynamic>>> dailyIncome() async {
    final resp = await ApiClient.get('/reports/daily-income');
    if (resp.ok && resp.data is List) {
      return (resp.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> byCategory() async {
    final resp = await ApiClient.get('/reports/by-category');
    if (resp.ok && resp.data is List) {
      return (resp.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> monthly() async {
    final resp = await ApiClient.get('/reports/monthly');
    if (resp.ok && resp.data is List) {
      return (resp.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }
}
