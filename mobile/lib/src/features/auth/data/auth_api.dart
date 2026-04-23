import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/auth_session.dart';
import '../domain/usuario.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      'auth/login',
      data: {'email': email, 'password': password},
    );

    final payload = _asJsonMap(response.data);
    final userPayload = payload['usuario'] ?? payload['user'] ?? payload;
    final token =
        payload['token'] as String? ?? payload['accessToken'] as String?;

    return AuthSession(
      usuario: Usuario.fromJson(_asJsonMap(userPayload)),
      token: token,
    );
  }

  Future<AuthSession> register({
    required String nombre,
    required String email,
    required String password,
    required String tipo,
  }) async {
    final response = await _client.post(
      'usuarios',
      data: {
        'nombre': nombre,
        'email': email,
        'password': password,
        'tipo': tipo,
      },
    );

    return AuthSession(usuario: Usuario.fromJson(_asJsonMap(response.data)));
  }

  Map<String, Object?> _asJsonMap(Object? payload) {
    if (payload is Map<String, Object?>) {
      return payload;
    }

    if (payload is Map) {
      return Map<String, Object?>.from(payload);
    }

    throw const ApiException('La API devolvio datos de usuario inesperados.');
  }
}
