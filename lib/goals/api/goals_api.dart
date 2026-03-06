import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';

class GoalsApi {
  static Future<Map<String, dynamic>?> getCurrent() async {
    debugPrint('[GoalsApi] getCurrent() called');
    final resp = await ApiClient.get('/goals/current');
    debugPrint('[GoalsApi] getCurrent() response — ok: ${resp.ok}, status: ${resp.statusCode}, data: ${resp.data}');
    if (resp.ok && resp.data is Map) {
      return Map<String, dynamic>.from(resp.data);
    }
    return null;
  }

  static Future<({bool ok, String message})> create(double amount) async {
    debugPrint('[GoalsApi] create() called — amount: ${amount.toStringAsFixed(2)}');
    final resp = await ApiClient.post('/goals', body: {
      'amount': amount.toStringAsFixed(2),
    });
    debugPrint('[GoalsApi] create() response — ok: ${resp.ok}, status: ${resp.statusCode}, data: ${resp.data}');
    if (resp.ok) return (ok: true, message: 'Meta definida!');
    return (ok: false, message: resp.errorMessage);
  }

  static Future<({bool ok, String message})> update(int id, double amount) async {
    debugPrint('[GoalsApi] update() called — id: $id amount: ${amount.toStringAsFixed(2)}');
    final resp = await ApiClient.put('/goals/$id', body: {
      'amount': amount.toStringAsFixed(2),
    });
    debugPrint('[GoalsApi] update() response — ok: ${resp.ok}, status: ${resp.statusCode}, data: ${resp.data}');
    if (resp.ok) return (ok: true, message: 'Meta atualizada!');
    return (ok: false, message: resp.errorMessage);
  }
}
