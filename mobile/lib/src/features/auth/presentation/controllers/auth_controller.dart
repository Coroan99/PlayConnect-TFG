import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/auth_repository.dart';
import '../../domain/usuario.dart';

enum AuthStatus { unauthenticated, loading, authenticated, failure }

class AuthState {
  const AuthState({required this.status, this.usuario, this.errorMessage});

  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.authenticated(Usuario usuario)
    : this(status: AuthStatus.authenticated, usuario: usuario);

  const AuthState.failure(String message)
    : this(status: AuthStatus.failure, errorMessage: message);

  final AuthStatus status;
  final Usuario? usuario;
  final String? errorMessage;

  bool get isAuthenticated {
    return status == AuthStatus.authenticated && usuario != null;
  }

  bool get isLoading {
    return status == AuthStatus.loading;
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState.unauthenticated();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthState.loading();

    try {
      final usuario = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);

      state = AuthState.authenticated(usuario);
    } catch (error) {
      state = AuthState.failure(_errorMessage(error));
    }
  }

  Future<void> register({
    required String nombre,
    required String email,
    required String password,
    required String tipo,
  }) async {
    state = const AuthState.loading();

    try {
      final usuario = await ref
          .read(authRepositoryProvider)
          .register(
            nombre: nombre,
            email: email,
            password: password,
            tipo: tipo,
          );

      state = AuthState.authenticated(usuario);
    } catch (error) {
      state = AuthState.failure(_errorMessage(error));
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState.unauthenticated();
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'Se produjo un error inesperado.';
  }
}
