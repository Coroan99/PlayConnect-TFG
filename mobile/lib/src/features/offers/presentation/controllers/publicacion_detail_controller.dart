import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../publications/data/publicaciones_repository.dart';
import '../../../publications/domain/publicacion.dart';
import '../../data/ofertas_repository.dart';
import '../../domain/oferta.dart';

const _notSet = Object();

class PublicacionDetailState {
  const PublicacionDetailState({
    required this.isLoading,
    required this.isSubmittingOferta,
    required this.updatingOfferIds,
    this.publicacionId,
    this.publicacion,
    this.ofertas = const [],
    this.errorMessage,
  });

  const PublicacionDetailState.initial()
    : this(
        isLoading: false,
        isSubmittingOferta: false,
        updatingOfferIds: const {},
      );

  final String? publicacionId;
  final Publicacion? publicacion;
  final List<Oferta> ofertas;
  final bool isLoading;
  final bool isSubmittingOferta;
  final Set<String> updatingOfferIds;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  PublicacionDetailState copyWith({
    Object? publicacionId = _notSet,
    Object? publicacion = _notSet,
    List<Oferta>? ofertas,
    bool? isLoading,
    bool? isSubmittingOferta,
    Set<String>? updatingOfferIds,
    String? errorMessage,
    bool clearError = false,
    bool clearOfertas = false,
  }) {
    return PublicacionDetailState(
      publicacionId: identical(publicacionId, _notSet)
          ? this.publicacionId
          : publicacionId as String?,
      publicacion: identical(publicacion, _notSet)
          ? this.publicacion
          : publicacion as Publicacion?,
      ofertas: clearOfertas ? const [] : ofertas ?? this.ofertas,
      isLoading: isLoading ?? this.isLoading,
      isSubmittingOferta: isSubmittingOferta ?? this.isSubmittingOferta,
      updatingOfferIds: updatingOfferIds ?? this.updatingOfferIds,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final publicacionDetailControllerProvider =
    NotifierProvider<PublicacionDetailController, PublicacionDetailState>(
      PublicacionDetailController.new,
    );

class PublicacionDetailController extends Notifier<PublicacionDetailState> {
  @override
  PublicacionDetailState build() {
    return const PublicacionDetailState.initial();
  }

  Future<void> load(String publicacionId) async {
    final shouldResetContent = state.publicacionId != publicacionId;

    state = state.copyWith(
      publicacionId: publicacionId,
      publicacion: shouldResetContent ? null : _notSet,
      isLoading: true,
      clearError: true,
      clearOfertas: shouldResetContent,
    );

    try {
      final publicacionesRepository = ref.read(publicacionesRepositoryProvider);
      final ofertasRepository = ref.read(ofertasRepositoryProvider);

      final results = await Future.wait([
        publicacionesRepository.getPublicacionById(publicacionId),
        ofertasRepository.getOfertasByPublicacion(publicacionId),
      ]);

      state = state.copyWith(
        publicacionId: publicacionId,
        publicacion: results[0] as Publicacion,
        ofertas: results[1] as List<Oferta>,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        publicacionId: publicacionId,
        isLoading: false,
        errorMessage: _errorMessage(error),
      );
    }
  }

  Future<void> refresh() async {
    final currentPublicacionId = state.publicacionId;

    if (currentPublicacionId == null || currentPublicacionId.isEmpty) {
      return;
    }

    await load(currentPublicacionId);
  }

  Future<String?> enviarOferta({
    required String usuarioId,
    required String publicacionId,
    required double precioOfrecido,
    String? mensaje,
  }) async {
    state = state.copyWith(isSubmittingOferta: true, clearError: true);

    try {
      final oferta = await ref
          .read(ofertasRepositoryProvider)
          .createOferta(
            usuarioId: usuarioId,
            publicacionId: publicacionId,
            precioOfrecido: precioOfrecido,
            mensaje: mensaje,
          );

      state = state.copyWith(
        isSubmittingOferta: false,
        ofertas: [oferta, ...state.ofertas],
      );

      return null;
    } catch (error) {
      state = state.copyWith(isSubmittingOferta: false);
      return _errorMessage(error);
    }
  }

  Future<String?> actualizarEstadoOferta({
    required String ofertaId,
    required OfertaEstado estado,
  }) async {
    state = state.copyWith(
      updatingOfferIds: {...state.updatingOfferIds, ofertaId},
    );

    try {
      final updatedOferta = await ref
          .read(ofertasRepositoryProvider)
          .updateOfertaEstado(ofertaId: ofertaId, estado: estado);

      final updatedOfertas = state.ofertas.map((oferta) {
        if (oferta.id == updatedOferta.id) {
          return updatedOferta;
        }

        if (estado == OfertaEstado.aceptada &&
            updatedOferta.publicacion.id == oferta.publicacion.id &&
            oferta.estado == OfertaEstado.pendiente) {
          return Oferta(
            id: oferta.id,
            precioOfrecido: oferta.precioOfrecido,
            mensaje: oferta.mensaje,
            estado: OfertaEstado.rechazada,
            createdAt: oferta.createdAt,
            updatedAt: oferta.updatedAt,
            usuario: oferta.usuario,
            publicacion: oferta.publicacion,
          );
        }

        return oferta;
      }).toList();

      state = state.copyWith(
        ofertas: updatedOfertas,
        updatingOfferIds: state.updatingOfferIds
            .where((id) => id != ofertaId)
            .toSet(),
      );

      return null;
    } catch (error) {
      state = state.copyWith(
        updatingOfferIds: state.updatingOfferIds
            .where((id) => id != ofertaId)
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
}
