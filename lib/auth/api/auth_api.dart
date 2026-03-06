import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';

class AuthApi {
  static Future<({bool ok, String message})> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    debugPrint('[AuthApi] register() called — name: $name, email: $email');
    final resp = await ApiClient.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirm': passwordConfirm,
      },
      auth: false,
    );
    debugPrint('[AuthApi] register() response — ok: ${resp.ok}, status: ${resp.statusCode}');
    debugPrint('[AuthApi] register() data: ${resp.data}');
    if (resp.ok) {
      debugPrint('[AuthApi] register() success');
      return (ok: true, message: 'Cadastro realizado!');
    }
    debugPrint('[AuthApi] register() error: ${resp.errorMessage}');
    return (ok: false, message: resp.errorMessage);
  }

  static Future<({bool ok, String message})> login({
    required String email,
    required String password,
  }) async {
    debugPrint('[AuthApi] login() called — email: $email');
    final resp = await ApiClient.post(
      '/auth/login',
      body: {'email': email, 'password': password},
      auth: false,
    );
    debugPrint('[AuthApi] login() response — ok: ${resp.ok}, status: ${resp.statusCode}');
    debugPrint('[AuthApi] login() data: ${resp.data}');
    if (resp.ok && resp.data is Map) {
      final access = resp.data['access']?.toString() ?? '';
      final refresh = resp.data['refresh']?.toString() ?? '';
      debugPrint('[AuthApi] login() access token present: ${access.isNotEmpty}, refresh token present: ${refresh.isNotEmpty}');
      if (access.isNotEmpty) {
        await AuthStorage.saveTokens(access: access, refresh: refresh);
        debugPrint('[AuthApi] login() tokens saved successfully');
        return (ok: true, message: 'Login realizado!');
      }
      debugPrint('[AuthApi] login() access token is empty — login failed');
    } else {
      debugPrint('[AuthApi] login() error: ${resp.errorMessage}');
    }
    return (ok: false, message: resp.errorMessage);
  }
}
