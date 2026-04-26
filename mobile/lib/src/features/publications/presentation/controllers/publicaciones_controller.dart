import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/publicaciones_repository.dart';
import '../../domain/publicacion.dart';

class PublicacionesState {
  const PublicacionesState({
    required this.publicaciones,
    required this.isLoading,
    required this.interestedPublicationIds,
    required this.processingInterestIds,
    this.errorMessage,
  });

  const PublicacionesState.initial()
    : this(
        publicaciones: const [],
        isLoading: true,
        interestedPublicationIds: const {},
        processingInterestIds: const {},
      );

  final List<Publicacion> publicaciones;
  final bool isLoading;
  final String? errorMessage;
  final Set<String> interestedPublicationIds;
  final Set<String> processingInterestIds;

  bool get hasError => errorMessage != null;
  bool get isEmpty => publicaciones.isEmpty;

  PublicacionesState copyWith({
    List<Publicacion>? publicaciones,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    Set<String>? interestedPublicationIds,
    Set<String>? processingInterestIds,
  }) {
    return PublicacionesState(
      publicaciones: publicaciones ?? this.publicaciones,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      interestedPublicationIds:
          interestedPublicationIds ?? this.interestedPublicationIds,
      processingInterestIds:
          processingInterestIds ?? this.processingInterestIds,
    );
  }
}

final publicacionesControllerProvider =
    NotifierProvider<PublicacionesController, PublicacionesState>(
      PublicacionesController.new,
    );

class PublicacionesController extends Notifier<PublicacionesState> {
  @override
  PublicacionesState build() {
    Future.microtask(loadPublicaciones);
    return const PublicacionesState.initial();
  }

  Future<void> loadPublicaciones() async {
    _debugLog(
      'PublicacionesController.loadPublicaciones -> loading=true, anteriores=${state.publicaciones.length}',
    );
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final publicaciones = await ref
          .read(publicacionesRepositoryProvider)
          .getPublicaciones();

      _debugLog(
        'PublicacionesController.loadPublicaciones -> loading=false, publicaciones=${publicaciones.length}',
      );
      state = state.copyWith(
        publicaciones: publicaciones,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      final message = _errorMessage(error);
      _debugLog(
        'PublicacionesController.loadPublicaciones -> loading=false, error=$message',
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: message,
      );
    }
  }

  Future<void> refresh() {
    return loadPublicaciones();
  }

  Future<String?> registrarInteres({
    required String usuarioId,
    required String publicacionId,
  }) async {
    if (state.processingInterestIds.contains(publicacionId) ||
        state.interestedPublicationIds.contains(publicacionId)) {
      return null;
    }

    state = state.copyWith(
      processingInterestIds: {...state.processingInterestIds, publicacionId},
    );

    try {
      await ref
          .read(publicacionesRepositoryProvider)
          .registrarInteres(usuarioId: usuarioId, publicacionId: publicacionId);

      state = state.copyWith(
        interestedPublicationIds: {
          ...state.interestedPublicationIds,
          publicacionId,
        },
        processingInterestIds: state.processingInterestIds
            .where((id) => id != publicacionId)
            .toSet(),
      );

      return null;
    } catch (error) {
      state = state.copyWith(
        processingInterestIds: state.processingInterestIds
            .where((id) => id != publicacionId)
            .toSet(),
      );

      return _errorMessage(error);
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'No se pudo completar la operacion.';
  }

  void _debugLog(String message) {
    assert(() {
      debugPrint(message);
      return true;
    }());
  }
}
