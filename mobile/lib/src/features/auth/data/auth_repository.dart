import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/session_storage.dart';
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

  Future<Usuario> login({
    required String email,
    required String password,
  }) async {
    final session = await _api.login(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final token = session.token;
    if (token != null && token.isNotEmpty) {
      await _storage.saveAuthToken(token);
    }

    return session.usuario;
  }

  Future<Usuario> register({
    required String nombre,
    required String email,
    required String password,
    required String tipo,
  }) async {
    final session = await _api.register(
      nombre: nombre.trim(),
      email: email.trim().toLowerCase(),
      password: password,
      tipo: tipo,
    );

    final token = session.token;
    if (token != null && token.isNotEmpty) {
      await _storage.saveAuthToken(token);
    }

    return session.usuario;
  }

  Future<void> logout() {
    return _storage.clear();
  }
}
