import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/usuario.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ProfileState {
  const ProfileState({required this.isSaving, this.errorMessage});

  const ProfileState.initial() : this(isSaving: false);

  final bool isSaving;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  ProfileState copyWith({
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);

class ProfileController extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    return const ProfileState.initial();
  }

  Future<Usuario?> saveCity({
    required String usuarioId,
    String? ciudad,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final usuario = await ref
          .read(authRepositoryProvider)
          .updateUsuarioCity(usuarioId: usuarioId, ciudad: ciudad);

      ref.read(authControllerProvider.notifier).setAuthenticatedUser(usuario);
      state = state.copyWith(isSaving: false, clearError: true);

      return usuario;
    } catch (error) {
      final message = _errorMessage(error);
      state = state.copyWith(isSaving: false, errorMessage: message);
      return null;
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'No se pudo actualizar la ciudad.';
  }
}
