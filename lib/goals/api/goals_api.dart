import '../../core/api_client.dart';

class GoalsApi {
  static Future<Map<String, dynamic>?> getCurrent() async {
    final resp = await ApiClient.get('/goals/current');
    if (resp.ok && resp.data is Map) {
      return Map<String, dynamic>.from(resp.data);
    }
    return null;
  }

  static Future<({bool ok, String message})> create(double amount) async {
    final resp = await ApiClient.post('/goals', body: {
      'amount': amount.toStringAsFixed(2),
    });
    if (resp.ok) return (ok: true, message: 'Meta definida!');
    return (ok: false, message: resp.errorMessage);
  }

  static Future<({bool ok, String message})> update(int id, double amount) async {
    final resp = await ApiClient.put('/goals/$id', body: {
      'amount': amount.toStringAsFixed(2),
    });
    if (resp.ok) return (ok: true, message: 'Meta atualizada!');
    return (ok: false, message: resp.errorMessage);
  }
}
