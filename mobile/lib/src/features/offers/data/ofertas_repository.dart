import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/oferta.dart';
import 'ofertas_api.dart';

final ofertasApiProvider = Provider<OfertasApi>((ref) {
  return OfertasApi(ref.watch(apiClientProvider));
});

final ofertasRepositoryProvider = Provider<OfertasRepository>((ref) {
  return OfertasRepository(ref.watch(ofertasApiProvider));
});

class OfertasRepository {
  const OfertasRepository(this._api);

  final OfertasApi _api;

  Future<List<Oferta>> getOfertasByPublicacion(String publicacionId) {
    return _api.fetchOfertasByPublicacion(publicacionId);
  }

  Future<Oferta> createOferta({
    required String usuarioId,
    required String publicacionId,
    required double precioOfrecido,
    String? mensaje,
  }) {
    return _api.createOferta(
      usuarioId: usuarioId,
      publicacionId: publicacionId,
      precioOfrecido: precioOfrecido,
      mensaje: mensaje,
    );
  }

  Future<Oferta> updateOfertaEstado({
    required String ofertaId,
    required OfertaEstado estado,
  }) {
    return _api.updateOfertaEstado(ofertaId: ofertaId, estado: estado);
  }
}
