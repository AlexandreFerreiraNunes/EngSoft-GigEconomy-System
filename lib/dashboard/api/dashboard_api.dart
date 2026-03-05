import '../../core/api_client.dart';

class DashboardApi {
  static Future<Map<String, dynamic>?> getMobile() async {
    final resp = await ApiClient.get('/dashboard/mobile');
    if (resp.ok && resp.data is Map) {
      return Map<String, dynamic>.from(resp.data);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getSummary() async {
    final resp = await ApiClient.get('/dashboard/summary');
    if (resp.ok && resp.data is Map) {
      return Map<String, dynamic>.from(resp.data);
    }
    return null;
  }
}
