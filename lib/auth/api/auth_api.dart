import '../../core/api_client.dart';
import '../../core/auth_storage.dart';

class AuthApi {
  static Future<({bool ok, String message})> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
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
    if (resp.ok) {
      return (ok: true, message: 'Cadastro realizado!');
    }
    return (ok: false, message: resp.errorMessage);
  }

  static Future<({bool ok, String message})> login({
    required String email,
    required String password,
  }) async {
    final resp = await ApiClient.post(
      '/auth/login',
      body: {'email': email, 'password': password},
      auth: false,
    );
    if (resp.ok && resp.data is Map) {
      final access = resp.data['access']?.toString() ?? '';
      final refresh = resp.data['refresh']?.toString() ?? '';
      if (access.isNotEmpty) {
        await AuthStorage.saveTokens(access: access, refresh: refresh);
        return (ok: true, message: 'Login realizado!');
      }
    }
    return (ok: false, message: resp.errorMessage);
  }
}
