import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/session_storage.dart';
import '../domain/auth_session.dart';
import '../domain/usuario.dart';
import 'auth_api.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(authApiProvider),
    storage: ref.watch(sessionStorageProvider),
  );
});

class AuthRepository {
  const AuthRepository({required AuthApi api, required SessionStorage storage})
    : _api = api,
      _storage = storage;

  final AuthApi _api;
  final SessionStorage _storage;

  Future<Usuario?> restoreSession() async {
    final token = _storage.getAuthToken();
    final userPayload = _storage.getAuthUser();

    if (token == null ||
        token.isEmpty ||
        userPayload == null ||
        _isExpiredJwt(token)) {
      await _storage.clear();
      return null;
    }

    return Usuario.fromJson(userPayload);
  }

  Future<Usuario> login({
    required String email,
    required String password,
  }) async {
    final session = await _api.login(
      email: email.trim().toLowerCase(),
      password: password,
    );

    await _saveSession(session);

    return session.usuario;
  }

  Future<Usuario> register({
    required String nombre,
    required String email,
    required String password,
    required String tipo,
  }) async {
    await _api.register(
      nombre: nombre.trim(),
      email: email.trim().toLowerCase(),
      password: password,
      tipo: tipo,
    );

    return login(email: email, password: password);
  }

  Future<void> logout() {
    return _storage.clear();
  }

  Future<void> _saveSession(AuthSession session) async {
    final token = session.token;

    if (token == null || token.isEmpty) {
      throw const ApiException('La API no devolvio un token de autenticacion.');
    }

    await _storage.saveSession(token: token, usuario: session.usuario.toJson());
  }

  bool _isExpiredJwt(String token) {
    final parts = token.split('.');

    if (parts.length != 3) {
      return true;
    }

    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload);

      if (claims is! Map || claims['exp'] is! num) {
        return true;
      }

      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        (claims['exp'] as num).toInt() * 1000,
      );

      return DateTime.now().isAfter(expiresAt);
    } on FormatException {
      return true;
    }
  }
}
