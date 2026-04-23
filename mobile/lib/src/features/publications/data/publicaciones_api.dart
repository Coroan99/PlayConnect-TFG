import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/publicacion.dart';

class PublicacionesApi {
  const PublicacionesApi(this._client);

  final ApiClient _client;

  Future<List<Publicacion>> fetchPublicaciones() async {
    final response = await _client.get('publicaciones');
    final items = _asJsonList(response.data);

    return items.map(Publicacion.fromJson).toList();
  }

  Future<void> createInteres({
    required String usuarioId,
    required String publicacionId,
  }) async {
    await _client.post(
      'intereses',
      data: {'usuario_id': usuarioId, 'publicacion_id': publicacionId},
    );
  }

  List<Map<String, Object?>> _asJsonList(Object? payload) {
    if (payload is! List) {
      throw const ApiException('La API devolvio una lista inesperada.');
    }

    return payload.map((item) {
      if (item is Map<String, Object?>) {
        return item;
      }

      if (item is Map) {
        return Map<String, Object?>.from(item);
      }

      throw const ApiException('La API devolvio una publicacion inesperada.');
    }).toList();
  }
}
