import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/auth_repository.dart';
import '../../domain/usuario.dart';

enum AuthStatus {
  checkingSession,
  unauthenticated,
  loading,
  authenticated,
  failure,
}

class AuthState {
  const AuthState({required this.status, this.usuario, this.errorMessage});

  const AuthState.checkingSession() : this(status: AuthStatus.checkingSession);

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

  bool get isCheckingSession {
    return status == AuthStatus.checkingSession;
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_restoreSession);
    return const AuthState.checkingSession();
  }

  Future<void> _restoreSession() async {
    try {
      final usuario = await ref.read(authRepositoryProvider).restoreSession();

      state = usuario == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(usuario);
    } catch (_) {
      await ref.read(authRepositoryProvider).logout();
      state = const AuthState.unauthenticated();
    }
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
    String? ciudad,
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
            ciudad: ciudad,
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

  void setAuthenticatedUser(Usuario usuario) {
    if (!state.isAuthenticated) {
      return;
    }

    state = AuthState.authenticated(usuario);
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'Se produjo un error inesperado.';
  }
}
