import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/juego_catalogo.dart';

class JuegosApi {
  const JuegosApi(this._client);

  final ApiClient _client;

  Future<List<JuegoCatalogo>> fetchJuegos({String? search}) async {
    final response = await _client.get(
      'juegos',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final items = _asJsonList(response.data);

    return items.map(JuegoCatalogo.fromJson).toList();
  }

  Future<JuegoCatalogo> fetchJuegoByBarcode(String codigoBarras) async {
    final response = await _client.get('juegos/barcode/$codigoBarras');
    return JuegoCatalogo.fromJson(_asJsonMap(response.data));
  }

  Future<JuegoCatalogo> createJuego({
    required String nombre,
    required JuegoTipo tipo,
    String? codigoBarras,
    String? imagenUrl,
    String? plataforma,
    int? jugadoresMin,
    int? jugadoresMax,
    int? duracionMinutos,
  }) async {
    final response = await _client.post(
      'juegos',
      data: {
        'nombre': nombre,
        'tipo_juego': tipo.apiValue,
        'codigo_barras': codigoBarras,
        'imagen_url': imagenUrl,
        'plataforma': plataforma,
        'jugadores_min': jugadoresMin,
        'jugadores_max': jugadoresMax,
        'duracion_minutos': duracionMinutos,
      },
    );

    return JuegoCatalogo.fromJson(_asJsonMap(response.data));
  }

  List<Map<String, Object?>> _asJsonList(Object? payload) {
    if (payload is! List) {
      throw const ApiException('La API devolvio una lista inesperada.');
    }

    return payload.map(_asJsonMap).toList();
  }

  Map<String, Object?> _asJsonMap(Object? payload) {
    if (payload is Map<String, Object?>) {
      return payload;
    }

    if (payload is Map) {
      return Map<String, Object?>.from(payload);
    }

    throw const ApiException('La API devolvio un juego inesperado.');
  }
}
