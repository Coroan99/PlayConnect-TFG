import 'usuario.dart';

class AuthSession {
  const AuthSession({required this.usuario, this.token});

  final Usuario usuario;
  final String? token;
}
