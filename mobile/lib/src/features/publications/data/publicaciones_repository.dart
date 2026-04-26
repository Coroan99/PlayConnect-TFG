import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/publicacion.dart';
import 'publicaciones_api.dart';

final publicacionesApiProvider = Provider<PublicacionesApi>((ref) {
  return PublicacionesApi(ref.watch(apiClientProvider));
});

final publicacionesRepositoryProvider = Provider<PublicacionesRepository>((
  ref,
) {
  return PublicacionesRepository(ref.watch(publicacionesApiProvider));
});

class PublicacionesRepository {
  const PublicacionesRepository(this._api);

  final PublicacionesApi _api;

  Future<List<Publicacion>> getPublicaciones() {
    return _api.fetchPublicaciones();
  }

  Future<Publicacion> getPublicacionById(String publicacionId) {
    return _api.fetchPublicacionById(publicacionId);
  }

  Future<void> registrarInteres({
    required String usuarioId,
    required String publicacionId,
  }) {
    return _api.createInteres(
      usuarioId: usuarioId,
      publicacionId: publicacionId,
    );
  }

  Future<Publicacion> createPublicacion({
    required String inventarioId,
    required String descripcion,
  }) {
    return _api.createPublicacion(
      inventarioId: inventarioId,
      descripcion: descripcion,
    );
  }

  Future<Publicacion> updatePublicacion({
    required String publicacionId,
    required String inventarioId,
    required String descripcion,
  }) {
    return _api.updatePublicacion(
      publicacionId: publicacionId,
      inventarioId: inventarioId,
      descripcion: descripcion,
    );
  }
}
