import '../../core/api_client.dart';

class AiApi {
  static Future<Map<String, dynamic>?> forecast() async {
    final resp = await ApiClient.get('/ai/forecast');
    if (resp.ok && resp.data is Map) {
      return Map<String, dynamic>.from(resp.data);
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> bestDays() async {
    final resp = await ApiClient.get('/ai/best-days');
    if (resp.ok && resp.data is List) {
      return (resp.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> bestHours() async {
    final resp = await ApiClient.get('/ai/best-hours');
    if (resp.ok && resp.data is List) {
      return (resp.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  static Future<List<String>> suggestions() async {
    final resp = await ApiClient.get('/ai/suggestions');
    if (resp.ok && resp.data is List) {
      return (resp.data as List).map((e) => e.toString()).toList();
    }
    if (resp.ok && resp.data is Map && resp.data['message'] != null) {
      return [resp.data['message'].toString()];
    }
    return [];
  }
}
