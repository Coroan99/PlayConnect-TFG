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

  Future<Publicacion> fetchPublicacionById(String publicacionId) async {
    final response = await _client.get('publicaciones/$publicacionId');
    final publicacion = Publicacion.fromJson(_asJsonMap(response.data));
    final juegoResponse = await _client.get('juegos/${publicacion.juego.id}');
    final juego = PublicacionJuego.fromJson(_asJsonMap(juegoResponse.data));

    return publicacion.copyWith(
      juego: publicacion.juego.copyWith(
        codigoBarras: juego.codigoBarras,
        imagenUrl: juego.imagenUrl,
        plataforma: juego.plataforma,
        jugadoresMin: juego.jugadoresMin,
        jugadoresMax: juego.jugadoresMax,
        duracionMinutos: juego.duracionMinutos,
        descripcion: juego.descripcion,
      ),
    );
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

  Future<Publicacion> createPublicacion({
    required String inventarioId,
    required String descripcion,
  }) async {
    final response = await _client.post(
      'publicaciones',
      data: {'inventario_id': inventarioId, 'descripcion': descripcion},
    );

    return Publicacion.fromJson(_asJsonMap(response.data));
  }

  Future<Publicacion> updatePublicacion({
    required String publicacionId,
    required String inventarioId,
    required String descripcion,
  }) async {
    final response = await _client.put(
      'publicaciones/$publicacionId',
      data: {'inventario_id': inventarioId, 'descripcion': descripcion},
    );

    return Publicacion.fromJson(_asJsonMap(response.data));
  }

  Map<String, Object?> _asJsonMap(Object? payload) {
    if (payload is Map<String, Object?>) {
      return payload;
    }

    if (payload is Map) {
      return Map<String, Object?>.from(payload);
    }

    throw const ApiException('La API devolvio una publicacion inesperada.');
  }

  List<Map<String, Object?>> _asJsonList(Object? payload) {
    if (payload is! List) {
      throw const ApiException('La API devolvio una lista inesperada.');
    }

    return payload.map((item) {
      return _asJsonMap(item);
    }).toList();
  }
}
