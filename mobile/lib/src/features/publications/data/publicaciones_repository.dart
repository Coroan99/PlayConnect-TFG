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
}
