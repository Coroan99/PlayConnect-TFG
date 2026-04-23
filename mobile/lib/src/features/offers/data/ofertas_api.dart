import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/oferta.dart';

class OfertasApi {
  const OfertasApi(this._client);

  final ApiClient _client;

  Future<List<Oferta>> fetchOfertasByPublicacion(String publicacionId) async {
    final response = await _client.get('publicaciones/$publicacionId/ofertas');
    final items = _asJsonList(response.data);

    return items.map(Oferta.fromJson).toList();
  }

  Future<Oferta> createOferta({
    required String usuarioId,
    required String publicacionId,
    required double precioOfrecido,
    String? mensaje,
  }) async {
    final response = await _client.post(
      'ofertas',
      data: {
        'usuario_id': usuarioId,
        'publicacion_id': publicacionId,
        'precio_ofrecido': precioOfrecido.toStringAsFixed(2),
        'mensaje': mensaje,
      },
    );

    return Oferta.fromJson(_asJsonMap(response.data));
  }

  Future<Oferta> updateOfertaEstado({
    required String ofertaId,
    required OfertaEstado estado,
  }) async {
    final response = await _client.patch(
      'ofertas/$ofertaId',
      data: {'estado': estado.apiValue},
    );

    return Oferta.fromJson(_asJsonMap(response.data));
  }

  List<Map<String, Object?>> _asJsonList(Object? payload) {
    if (payload is! List) {
      throw const ApiException('La API devolvio una lista inesperada.');
    }

    return payload.map((item) => _asJsonMap(item)).toList();
  }

  Map<String, Object?> _asJsonMap(Object? payload) {
    if (payload is Map<String, Object?>) {
      return payload;
    }

    if (payload is Map) {
      return Map<String, Object?>.from(payload);
    }

    throw const ApiException('La API devolvio una oferta inesperada.');
  }
}
