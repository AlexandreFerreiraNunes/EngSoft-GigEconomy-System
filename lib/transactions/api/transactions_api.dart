import '../../core/api_client.dart';

class TransactionsApi {
  static Future<({bool ok, String message})> create({
    required String type,
    required String category,
    required double amount,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'type': type,
      'category': category,
      'amount': amount.toStringAsFixed(2),
    };
    if (note != null && note.trim().isNotEmpty) {
      body['note'] = note.trim();
    }
    final resp = await ApiClient.post('/transactions', body: body);
    if (resp.ok) return (ok: true, message: type == 'income' ? 'Ganho registrado!' : 'Gasto registrado!');
    return (ok: false, message: resp.errorMessage);
  }

  static Future<({bool ok, List<Map<String, dynamic>> items, bool hasMore})> list({
    String? type,
    String? category,
    String? startDate,
    String? endDate,
    int page = 1,
  }) async {
    final params = <String>[];
    if (type != null) params.add('type=$type');
    if (category != null) params.add('category=$category');
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');
    params.add('page=$page');
    final query = params.join('&');
    final resp = await ApiClient.get('/transactions?$query');

    if (resp.ok) {
      if (resp.data is Map) {
        final results = resp.data['results'];
        final items = (results is List)
            ? results.map((e) => Map<String, dynamic>.from(e)).toList()
            : <Map<String, dynamic>>[];
        final hasMore = resp.data['next'] != null;
        return (ok: true, items: items, hasMore: hasMore);
      }
      if (resp.data is List) {
        final items = (resp.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
        return (ok: true, items: items, hasMore: false);
      }
    }
    return (ok: false, items: <Map<String, dynamic>>[], hasMore: false);
  }

  static Future<({bool ok, String message})> update(int id, {
    String? category,
    double? amount,
    String? note,
  }) async {
    final body = <String, dynamic>{};
    if (category != null) body['category'] = category;
    if (amount != null) body['amount'] = amount.toStringAsFixed(2);
    if (note != null) body['note'] = note;
    final resp = await ApiClient.put('/transactions/$id', body: body);
    if (resp.ok) return (ok: true, message: 'Atualizado!');
    return (ok: false, message: resp.errorMessage);
  }

  static Future<({bool ok, String message})> delete(int id) async {
    final resp = await ApiClient.delete('/transactions/$id');
    if (resp.ok) return (ok: true, message: 'Excluído!');
    return (ok: false, message: resp.errorMessage);
  }
}
