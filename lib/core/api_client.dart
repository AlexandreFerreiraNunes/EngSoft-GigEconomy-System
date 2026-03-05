import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'auth_storage.dart';

class ApiClient {
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await AuthStorage.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<ApiResponse> get(String path, {bool auth = true}) async {
    try {
      final resp = await http.get(
        Uri.parse('$kBaseUrl$path'),
        headers: await _headers(auth: auth),
      );
      return ApiResponse(resp.statusCode, _decode(resp.bodyBytes));
    } catch (e, st) {
      dev.log('GET $path falhou: $e', stackTrace: st);
      return ApiResponse(0, {'error': 'Sem conexão com o servidor'});
    }
  }

  static Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('$kBaseUrl$path'),
        headers: await _headers(auth: auth),
        body: body != null ? jsonEncode(body) : null,
      );
      return ApiResponse(resp.statusCode, _decode(resp.bodyBytes));
    } catch (e, st) {
      dev.log('POST $path falhou: $e', stackTrace: st);
      return ApiResponse(0, {'error': 'Sem conexão com o servidor'});
    }
  }

  static Future<ApiResponse> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    try {
      final resp = await http.put(
        Uri.parse('$kBaseUrl$path'),
        headers: await _headers(auth: auth),
        body: body != null ? jsonEncode(body) : null,
      );
      return ApiResponse(resp.statusCode, _decode(resp.bodyBytes));
    } catch (e, st) {
      dev.log('PUT $path falhou: $e', stackTrace: st);
      return ApiResponse(0, {'error': 'Sem conexão com o servidor'});
    }
  }

  static Future<ApiResponse> delete(String path, {bool auth = true}) async {
    try {
      final resp = await http.delete(
        Uri.parse('$kBaseUrl$path'),
        headers: await _headers(auth: auth),
      );
      return ApiResponse(resp.statusCode, _decode(resp.bodyBytes));
    } catch (e, st) {
      dev.log('DELETE $path falhou: $e', stackTrace: st);
      return ApiResponse(0, {'error': 'Sem conexão com o servidor'});
    }
  }

  static dynamic _decode(List<int> bodyBytes) {
    try {
      final s = utf8.decode(bodyBytes);
      return jsonDecode(s);
    } catch (_) {
      // Fallback: try latin1 (ISO-8859-1) if server returned that encoding
      try {
        final s2 = latin1.decode(bodyBytes);
        return jsonDecode(s2);
      } catch (_) {
        // Last resort: decode as UTF-8 allowing malformed sequences
        try {
          final s3 = utf8.decode(bodyBytes, allowMalformed: true);
          return jsonDecode(s3);
        } catch (_) {
          return {'raw': String.fromCharCodes(bodyBytes)};
        }
      }
    }
  }
}

class ApiResponse {
  final int statusCode;
  final dynamic data;

  ApiResponse(this.statusCode, this.data);

  bool get ok => statusCode >= 200 && statusCode < 300;

  String get errorMessage {
    if (data is Map) {
      return (data['detail'] ?? data['error'] ?? data['message'] ?? 'Algo deu errado').toString();
    }
    return 'Algo deu errado';
  }
}
